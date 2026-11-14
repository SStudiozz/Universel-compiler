/*
 * libmelonres
 * Resolution: patch URP get_renderScale + ScalableBuffer getters to return g_scale.
 * Also ResizeBuffers/SetRenderScale on Unity thread via UIScaler.Update.
 * Limbs: breakForce/Torque * 1.30.
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
#define OFF_GET_RENDER_SCALE     0x425CAD8u  /* ldr s0,[x0,#0x60]; ret — 8 bytes */
#define OFF_GET_WIDTH_SCALE      0x43C58B4u
#define OFF_GET_HEIGHT_SCALE     0x43C58DCu
#define OFF_SET_BREAK_FORCE      0x4448A24u
#define OFF_SET_BREAK_TORQUE     0x4448A70u
#define OFF_UISCALER_UPDATE       0x2067B40u
#define LIMB_MUL 1.30f

typedef void (*ResizeBuffers_fn)(float, float);
typedef void (*SetRenderScale_fn)(float);
typedef void (*BreakSet_fn)(void *thiz, float value);
typedef void (*Update_fn)(void *thiz, void *methodInfo);

/* Exposed so ADRP+LDR from il2cpp can load it */
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

/* ADRP Xd, dest@PAGE */
static uint32_t enc_adrp(int rd, uint64_t pc, uint64_t dest) {
    uint64_t pc_page = pc & ~0xFFFULL;
    uint64_t dest_page = dest & ~0xFFFULL;
    int64_t imm = (int64_t)((dest_page - pc_page) >> 12);
    uint32_t immlo = (uint32_t)(imm & 3);
    uint32_t immhi = (uint32_t)((imm >> 2) & 0x7FFFF);
    return 0x90000000u | (immlo << 29) | (immhi << 5) | (uint32_t)rd;
}

/* LDR St, [Xn, #pgoff]  (32-bit float, unsigned offset) */
static uint32_t enc_ldr_s(int rt, int rn, uint32_t pgoff) {
    uint32_t imm12 = pgoff >> 2;
    return 0xBD400000u | (imm12 << 10) | ((uint32_t)rn << 5) | (uint32_t)rt;
}

/*
 * Patch get_renderScale (8-byte function) into:
 *   ADRP X8, g_melon_scale@PAGE
 *   LDR  S0, [X8, g_melon_scale@OFF]
 *   RET
 * 12 bytes — overwrites set_renderScale entry with RET (game set becomes no-op).
 */
static int patch_get_render_scale(void) {
    void *target = at_off(OFF_GET_RENDER_SCALE);
    if (!target) return -1;
    uint64_t pc = (uint64_t)(uintptr_t)target;
    uint64_t dest = (uint64_t)(uintptr_t)&g_melon_scale;
    int64_t page_delta = (int64_t)((dest & ~0xFFFULL) - (pc & ~0xFFFULL));
    /* ADRP range ±4GB */
    if (page_delta < -(1LL << 32) || page_delta >= (1LL << 32)) {
        LOGE("g_melon_scale too far for ADRP");
        return -1;
    }
    if (mprotect_rwx(target, 16) != 0) return -1;
    uint32_t *t = (uint32_t *)target;
    t[0] = enc_adrp(8, pc, dest);
    t[1] = enc_ldr_s(0, 8, (uint32_t)(dest & 0xFFFu));
    t[2] = 0xD65F03C0u; /* RET — also becomes set_renderScale entry */
    __builtin___clear_cache((char *)target, (char *)target + 12);
    LOGI("get_renderScale -> g_melon_scale @ %p", (void *)&g_melon_scale);
    return 0;
}

/* Float getters that only return g_melon_scale */
static float hooked_width_scale(void) { return g_melon_scale; }
static float hooked_height_scale(void) { return g_melon_scale; }

static void install_scale_hooks(void) {
    if (g_scale_hooks) return;
    if (patch_get_render_scale() != 0)
        LOGE("get_renderScale patch failed");

    void *w = at_off(OFF_GET_WIDTH_SCALE);
    void *h = at_off(OFF_GET_HEIGHT_SCALE);
    if (w && mprotect_rwx(w, 16) == 0) {
        write_abs_jump((uint32_t *)w, (void *)hooked_width_scale);
        __builtin___clear_cache((char *)w, (char *)w + 16);
        LOGI("get_widthScaleFactor hooked");
    }
    if (h && mprotect_rwx(h, 16) == 0) {
        write_abs_jump((uint32_t *)h, (void *)hooked_height_scale);
        __builtin___clear_cache((char *)h, (char *)h + 16);
        LOGI("get_heightScaleFactor hooked");
    }
    g_scale_hooks = 1;
}

static void apply_scale_now(void) {
    float s = g_melon_scale;
    if (s < 0.01f) s = 0.01f;
    if (s > 1.0f) s = 1.0f;
    ResizeBuffers_fn rb = (ResizeBuffers_fn)at_off(OFF_RESIZE_BUFFERS);
    SetRenderScale_fn srs = (SetRenderScale_fn)at_off(OFF_SET_RENDER_SCALE);
    if (rb) { rb(s, s); LOGI("ResizeBuffers(%.3f)", (double)s); }
    if (srs) { srs(s); LOGI("SetRenderScale(%.3f)", (double)s); }
}

JNIEXPORT void JNICALL
Java_com_studio27_melonmod_MelonResOverlay_nativeApply(JNIEnv *env, jclass clazz, jfloat scale) {
    (void)env; (void)clazz;
    if (scale < 0.01f) scale = 0.01f;
    if (scale > 1.0f) scale = 1.0f;
    g_melon_scale = scale;
    g_dirty = 1;
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
    if (g_dirty) {
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
