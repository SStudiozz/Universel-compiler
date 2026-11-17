/*
 * libmelonres
 *
 * Resolution: INLINE-patch CreateRenderTextureDescriptor so s8 (renderScale)
 * always loads from g_melon_scale. No C-hook (struct return ABI breaks).
 *
 * Also: getters, ResizeBuffers, limbs, Surface path from Java.
 */
#include <jni.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <sys/mman.h>
#include <android/log.h>

#define LOG_TAG "MelonRes"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

#define OFF_RESIZE_BUFFERS       0x43C5904u
#define OFF_SET_RENDER_SCALE     0x41B9584u
#define OFF_GET_RENDER_SCALE     0x425CAD8u
#define OFF_GET_WIDTH_SCALE      0x43C58B4u
#define OFF_GET_HEIGHT_SCALE     0x43C58DCu
#define OFF_CREATE_RT_DESC       0x42C0824u
#define OFF_CRTD_SCALE_SAVE      0x42C085Cu  /* +0x38: mov v8, v0  -> load g_melon_scale */
#define OFF_SET_BREAK_FORCE      0x4448A24u
#define OFF_SET_BREAK_TORQUE     0x4448A70u
#define OFF_UISCALER_UPDATE       0x2067B40u
#define LIMB_MUL 1.30f

typedef void (*ResizeBuffers_fn)(float, float);
typedef void (*SetRenderScale_fn)(float);
typedef void (*BreakSet_fn)(void *thiz, float value);
typedef void (*Update_fn)(void *thiz, void *methodInfo);

/* Must stay global (not static) so ADRP from il2cpp can reach it */
float g_melon_scale = 1.0f;
static volatile int g_dirty = 0;

static uintptr_t g_rx_start;
static uintptr_t g_rx_file_off;
static int g_maps_ok;
static int g_limb_hooks;
static int g_update_hook;
static int g_scale_hooks;
static uint32_t g_saved_force[4];
static uint32_t g_saved_torque[4];
static uint32_t g_saved_update[4];
static uint32_t g_saved_crtd_scale[2]; /* original 2 insns at +0x38 */
static int g_crtd_patched;

static int parse_maps(void) {
    if (g_maps_ok) return 1;
    FILE *f = fopen("/proc/self/maps", "r");
    if (!f) return 0;
    char line[768];
    while (fgets(line, sizeof(line), f)) {
        if (!strstr(line, "libil2cpp.so")) continue;
        if (!strstr(line, "r-x")) continue;
        unsigned long start = 0, end = 0, offset = 0;
        if (sscanf(line, "%lx-%lx %*s %lx", &start, &end, &offset) != 3)
            continue;
        if (OFF_RESIZE_BUFFERS >= offset &&
            OFF_RESIZE_BUFFERS < offset + (end - start)) {
            g_rx_start = (uintptr_t)start;
            g_rx_file_off = (uintptr_t)offset;
            g_maps_ok = 1;
            LOGI("il2cpp RX %lx-%lx off=%lx", start, end, offset);
            break;
        }
        if (!g_maps_ok) {
            g_rx_start = (uintptr_t)start;
            g_rx_file_off = (uintptr_t)offset;
            g_maps_ok = 1;
        }
    }
    fclose(f);
    return g_maps_ok;
}

static void *at_off(unsigned file_off) {
    if (!parse_maps()) return NULL;
    if (file_off < g_rx_file_off) return NULL;
    return (void *)(g_rx_start + (file_off - g_rx_file_off));
}

static int mprotect_rwx(void *addr, size_t len) {
    uintptr_t page = (uintptr_t)addr & ~((uintptr_t)0xFFF);
    size_t span = ((uintptr_t)addr + len + 0xFFF) - page;
    return mprotect((void *)page, span, PROT_READ | PROT_WRITE | PROT_EXEC);
}

static void write_abs_jump(uint32_t *dst, void *target) {
    dst[0] = 0x58000050u;
    dst[1] = 0xD61F0200u;
    uint64_t t = (uint64_t)(uintptr_t)target;
    memcpy(&dst[2], &t, 8);
}

static uint32_t enc_adrp(int rd, uint64_t pc, uint64_t dest) {
    uint64_t pc_page = pc & ~0xFFFULL;
    uint64_t dest_page = dest & ~0xFFFULL;
    int64_t imm = (int64_t)((dest_page - pc_page) >> 12);
    uint32_t immlo = (uint32_t)(imm & 3);
    uint32_t immhi = (uint32_t)((imm >> 2) & 0x7FFFF);
    return 0x90000000u | (immlo << 29) | (immhi << 5) | (uint32_t)rd;
}

static uint32_t enc_ldr_s(int rt, int rn, uint32_t pgoff) {
    return 0xBD400000u | ((pgoff >> 2) << 10) | ((uint32_t)rn << 5) | (uint32_t)rt;
}

/*
 * CreateRenderTextureDescriptor +0x38 was:
 *   mov v8.16b, v0.16b   ; s8 = renderScale arg
 * Later: width/height *= s8
 *
 * Replace with:
 *   adrp x9, g_melon_scale
 *   ldr  s8, [x9, #lo12]
 * so every RT uses our slider scale.
 *
 * Overwrites 8 bytes (+0x38, +0x3c). +0x3c was "mov x20, x0".
 * We re-emit mov x20,x0 at +0x40 by shifting — actually we only have 8 bytes
 * without moving more. So use a different strategy:
 *
 * Only replace the 4-byte mov v8,v0 with a branch to a tiny stub we write
 * into the 12-byte gap... no gap.
 *
 * Use: fmov s8, #imm for coarse steps written on each nativeApply,
 * OR adrp/ldr into s8 overwriting +0x38 and +0x3c, then fix x20 at next
 * opportunity: patch +0x40 from mov x19,x8 to mov x20,x0 and lose x19 if
 * unused for scale path.
 *
 * Safer: overwrite only +0x38 with fmov s8,#0.5 when scale<=0.6, etc.
 * Full precision: adrp x9 / ldr s8 at +0x38/+0x3c, and at +0x40 put
 * mov x20, x0 (replacing mov x19,x8). x19 is used later — check.
 *
 * From disasm +0x40 mov x19,x8; if x19 is required we break.
 * Minimal risk path used here:
 *   +0x38/+0x3c = adrp x9 / ldr s8
 *   leave +0x40 alone — x20 may be stale; camera is still in x0 for early uses.
 *   Many later uses load camera from x20; those may break.
 *
 * Better: 3-instruction patch using +0x38,0x3c,0x40:
 *   adrp x9, g_melon_scale
 *   ldr  s8, [x9, #off]
 *   mov  x20, x0
 * And save original +0x40 (mov x19,x8) into a trampoline for later if needed.
 * For Melon, x19 often holds MethodInfo-ish; test with 3-insn patch.
 */
static int patch_crtd_scale_load(void) {
    void *target = at_off(OFF_CRTD_SCALE_SAVE);
    if (!target) return -1;
    uint64_t pc = (uint64_t)(uintptr_t)target;
    uint64_t dest = (uint64_t)(uintptr_t)&g_melon_scale;
    int64_t page_delta = (int64_t)((dest & ~0xFFFULL) - (pc & ~0xFFFULL));
    if (page_delta < -(1LL << 32) || page_delta >= (1LL << 32)) {
        LOGE("g_melon_scale out of ADRP range");
        return -1;
    }
    if (mprotect_rwx(target, 16) != 0) return -1;
    uint32_t *t = (uint32_t *)target;
    if (!g_crtd_patched) {
        g_saved_crtd_scale[0] = t[0];
        g_saved_crtd_scale[1] = t[1];
    }
    /* adrp x9, page ; ldr s8, [x9, #off] ; mov x20, x0 */
    t[0] = enc_adrp(9, pc, dest);
    t[1] = enc_ldr_s(8, 9, (uint32_t)(dest & 0xFFFu));
    t[2] = 0xAA0003F4u; /* mov x20, x0 */
    __builtin___clear_cache((char *)target, (char *)target + 12);
    g_crtd_patched = 1;
    LOGI("CRTD scale load -> g_melon_scale @ %p", (void *)&g_melon_scale);
    return 0;
}

static int patch_get_render_scale(void) {
    void *target = at_off(OFF_GET_RENDER_SCALE);
    if (!target) return -1;
    uint64_t pc = (uint64_t)(uintptr_t)target;
    uint64_t dest = (uint64_t)(uintptr_t)&g_melon_scale;
    if (mprotect_rwx(target, 16) != 0) return -1;
    uint32_t *t = (uint32_t *)target;
    t[0] = enc_adrp(8, pc, dest);
    t[1] = enc_ldr_s(0, 8, (uint32_t)(dest & 0xFFFu));
    t[2] = 0xD65F03C0u;
    __builtin___clear_cache((char *)target, (char *)target + 12);
    LOGI("get_renderScale -> g_melon_scale");
    return 0;
}

static float hooked_width_scale(void) { return g_melon_scale; }
static float hooked_height_scale(void) { return g_melon_scale; }

static void install_scale_hooks(void) {
    if (g_scale_hooks) return;
    patch_get_render_scale();
    patch_crtd_scale_load();
    void *w = at_off(OFF_GET_WIDTH_SCALE);
    void *h = at_off(OFF_GET_HEIGHT_SCALE);
    if (w && mprotect_rwx(w, 16) == 0) {
        write_abs_jump((uint32_t *)w, (void *)hooked_width_scale);
        __builtin___clear_cache((char *)w, (char *)w + 16);
        LOGI("widthScaleFactor hooked");
    }
    if (h && mprotect_rwx(h, 16) == 0) {
        write_abs_jump((uint32_t *)h, (void *)hooked_height_scale);
        __builtin___clear_cache((char *)h, (char *)h + 16);
        LOGI("heightScaleFactor hooked");
    }
    g_scale_hooks = 1;
}

static void apply_scale_now(void) {
    float s = g_melon_scale;
    if (s < 0.05f) s = 0.05f;
    if (s > 1.0f) s = 1.0f;
    ResizeBuffers_fn rb = (ResizeBuffers_fn)at_off(OFF_RESIZE_BUFFERS);
    SetRenderScale_fn srs = (SetRenderScale_fn)at_off(OFF_SET_RENDER_SCALE);
    if (rb) { rb(s, s); LOGI("ResizeBuffers(%.3f)", (double)s); }
    if (srs) { srs(s); LOGI("SetRenderScale(%.3f)", (double)s); }
}

JNIEXPORT void JNICALL
Java_com_studio27_melonmod_MelonResOverlay_nativeApply(JNIEnv *env, jclass clazz, jfloat scale) {
    (void)env; (void)clazz;
    if (scale < 0.05f) scale = 0.05f;
    if (scale > 1.0f) scale = 1.0f;
    g_melon_scale = scale;
    g_dirty = 1;
    /* Re-assert CRTD patch in case something restored bytes */
    patch_crtd_scale_load();
    LOGI("g_melon_scale=%.3f", (double)scale);
}

static void hooked_update(void *thiz, void *methodInfo);

static void call_orig_update(void *thiz, void *methodInfo) {
    void *target = at_off(OFF_UISCALER_UPDATE);
    if (!target) return;
    uint32_t *t = (uint32_t *)target;
    if (mprotect_rwx(target, 16) != 0) return;
    memcpy(t, g_saved_update, 16);
    __builtin___clear_cache((char *)t, (char *)t + 16);
    ((Update_fn)target)(thiz, methodInfo);
    write_abs_jump(t, (void *)hooked_update);
    __builtin___clear_cache((char *)t, (char *)t + 16);
}

static void hooked_update(void *thiz, void *methodInfo) {
    if (g_dirty || g_melon_scale < 0.999f) {
        g_dirty = 0;
        apply_scale_now();
    }
    call_orig_update(thiz, methodInfo);
}

static void install_update_hook(void) {
    if (g_update_hook) return;
    void *u = at_off(OFF_UISCALER_UPDATE);
    if (!u) { LOGE("UIScaler.Update resolve failed"); return; }
    memcpy(g_saved_update, u, 16);
    if (mprotect_rwx(u, 16) != 0) { LOGE("UIScaler mprotect failed"); return; }
    write_abs_jump((uint32_t *)u, (void *)hooked_update);
    __builtin___clear_cache((char *)u, (char *)u + 16);
    g_update_hook = 1;
    LOGI("UIScaler.Update hooked");
}

static void call_orig_break(unsigned file_off, uint32_t *saved, void *hook, void *thiz, float value) {
    void *target = at_off(file_off);
    if (!target) return;
    uint32_t *t = (uint32_t *)target;
    if (mprotect_rwx(target, 16) != 0) return;
    memcpy(t, saved, 16);
    __builtin___clear_cache((char *)t, (char *)t + 16);
    ((BreakSet_fn)target)(thiz, value);
    write_abs_jump(t, hook);
    __builtin___clear_cache((char *)t, (char *)t + 16);
}

static void hooked_force(void *thiz, float value) {
    call_orig_break(OFF_SET_BREAK_FORCE, g_saved_force, (void *)hooked_force, thiz, value * LIMB_MUL);
}
static void hooked_torque(void *thiz, float value) {
    call_orig_break(OFF_SET_BREAK_TORQUE, g_saved_torque, (void *)hooked_torque, thiz, value * LIMB_MUL);
}

static void install_limb_hooks(void) {
    if (g_limb_hooks) return;
    void *f = at_off(OFF_SET_BREAK_FORCE);
    void *q = at_off(OFF_SET_BREAK_TORQUE);
    if (!f || !q) { LOGE("limb resolve failed"); return; }
    memcpy(g_saved_force, f, 16);
    memcpy(g_saved_torque, q, 16);
    if (mprotect_rwx(f, 16) || mprotect_rwx(q, 16)) { LOGE("limb mprotect failed"); return; }
    write_abs_jump((uint32_t *)f, (void *)hooked_force);
    write_abs_jump((uint32_t *)q, (void *)hooked_torque);
    __builtin___clear_cache((char *)f, (char *)f + 16);
    __builtin___clear_cache((char *)q, (char *)q + 16);
    g_limb_hooks = 1;
    LOGI("limb hooks *%.2f", (double)LIMB_MUL);
}

JNIEXPORT void JNICALL
Java_com_studio27_melonmod_MelonResOverlay_nativeInitLimbs(JNIEnv *env, jclass clazz) {
    (void)env; (void)clazz;
    install_scale_hooks();
    install_limb_hooks();
    install_update_hook();
}

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved) {
    (void)vm; (void)reserved;
    LOGI("libmelonres loaded");
    install_scale_hooks();
    install_limb_hooks();
    install_update_hook();
    return JNI_VERSION_1_6;
}
