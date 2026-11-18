/*
 * libmelonres
 * - Resolution (CRTD tier / surface handled in Java)
 * - Limb strength: base 1.3x; giants (lossyScale >= 1.2) get 3x vs normal
 */
#include <jni.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <sys/mman.h>
#include <android/log.h>
#include <math.h>

#define LOG_TAG "MelonRes"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

#define OFF_RESIZE_BUFFERS    0x43C5904u
#define OFF_SET_RENDER_SCALE  0x41B9584u
#define OFF_CRTD_SCALE_SAVE   0x42C085Cu
#define OFF_SET_BREAK_FORCE   0x4448A24u
#define OFF_SET_BREAK_TORQUE  0x4448A70u
#define OFF_UISCALER_UPDATE    0x2067B40u
#define OFF_GET_TRANSFORM     0x43E87B8u
#define OFF_GET_LOSSY_SCALE   0x43F659Cu  /* get_lossyScale_Injected */

#define LIMB_MUL 1.30f
#define GIANT_SCALE_THRESHOLD 1.20f
#define GIANT_STRENGTH 3.00f

#define INSN_MOV_V8_V0   0x4EA01C08u
#define INSN_FMOV_S8_25  0x1E2A1008u
#define INSN_FMOV_S8_50  0x1E2E1008u
#define INSN_FMOV_S8_75  0x1E2F1008u

typedef void (*ResizeBuffers_fn)(float, float);
typedef void (*SetRenderScale_fn)(float);
typedef void (*BreakSet_fn)(void *thiz, float value);
typedef void (*Update_fn)(void *thiz, void *methodInfo);
typedef void *(*GetTransform_fn)(void *component);
typedef void (*GetLossyScale_fn)(void *transform, float *out_xyz);

float g_melon_scale = 0.5f;
static volatile int g_dirty = 1;

static uintptr_t g_rx_start;
static uintptr_t g_rx_file_off;
static int g_maps_ok;
static int g_limb_hooks;
static int g_update_hook;
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
        if (OFF_SET_BREAK_FORCE >= offset &&
            OFF_SET_BREAK_FORCE < offset + (end - start)) {
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

/* Average body scale from joint's transform; 1.0 if unavailable */
static float joint_body_scale(void *joint) {
    GetTransform_fn get_tr = (GetTransform_fn)at_off(OFF_GET_TRANSFORM);
    GetLossyScale_fn get_ls = (GetLossyScale_fn)at_off(OFF_GET_LOSSY_SCALE);
    if (!get_tr || !get_ls || !joint) return 1.0f;
    void *tr = get_tr(joint);
    if (!tr) return 1.0f;
    float v[4] = {1.0f, 1.0f, 1.0f, 0.0f};
    get_ls(tr, v);
    float sx = v[0] < 0.0f ? -v[0] : v[0];
    float sy = v[1] < 0.0f ? -v[1] : v[1];
    float s = sx > sy ? sx : sy;
    if (s < 0.25f) s = 0.25f;
    if (s > 20.0f) s = 20.0f;
    return s;
}

/*
 * Normal size (<=1.2): LIMB_MUL only (1.3x)
 * Giants (>=1.2): 3x stronger than normal, scaled further with size
 *   at 1.2 -> 3.0x extra, at 2.4 -> 6.0x extra, etc.
 */
static float limb_strength_mul(void *joint) {
    float s = joint_body_scale(joint);
    float mul = LIMB_MUL;
    if (s >= GIANT_SCALE_THRESHOLD) {
        mul *= GIANT_STRENGTH * (s / GIANT_SCALE_THRESHOLD);
    }
    return mul;
}

static void patch_crtd_tier(float scale) {
    void *target = at_off(OFF_CRTD_SCALE_SAVE);
    if (!target) return;
    if (mprotect_rwx(target, 8) != 0) return;
    uint32_t insn;
    if (scale >= 0.99f) insn = INSN_MOV_V8_V0;
    else if (scale >= 0.70f) insn = INSN_FMOV_S8_75;
    else if (scale >= 0.40f) insn = INSN_FMOV_S8_50;
    else insn = INSN_FMOV_S8_25;
    *(uint32_t *)target = insn;
    __builtin___clear_cache((char *)target, (char *)target + 4);
}

static void apply_scale_now(void) {
    float s = g_melon_scale;
    if (s < 0.05f) s = 0.05f;
    if (s > 1.0f) s = 1.0f;
    patch_crtd_tier(s);
    ResizeBuffers_fn rb = (ResizeBuffers_fn)at_off(OFF_RESIZE_BUFFERS);
    SetRenderScale_fn srs = (SetRenderScale_fn)at_off(OFF_SET_RENDER_SCALE);
    if (rb) rb(s, s);
    if (srs) srs(s);
}

JNIEXPORT void JNICALL
Java_com_studio27_melonmod_MelonResOverlay_nativeApply(JNIEnv *env, jclass clazz, jfloat scale) {
    (void)env; (void)clazz;
    if (scale < 0.05f) scale = 0.05f;
    if (scale > 1.0f) scale = 1.0f;
    g_melon_scale = scale;
    g_dirty = 1;
    patch_crtd_tier(scale);
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
    if (!u) return;
    memcpy(g_saved_update, u, 16);
    if (mprotect_rwx(u, 16) != 0) return;
    write_abs_jump((uint32_t *)u, (void *)hooked_update);
    __builtin___clear_cache((char *)u, (char *)u + 16);
    g_update_hook = 1;
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
    float mul = limb_strength_mul(thiz);
    call_orig_break(OFF_SET_BREAK_FORCE, g_saved_force, (void *)hooked_force, thiz, value * mul);
}
static void hooked_torque(void *thiz, float value) {
    float mul = limb_strength_mul(thiz);
    call_orig_break(OFF_SET_BREAK_TORQUE, g_saved_torque, (void *)hooked_torque, thiz, value * mul);
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
    LOGI("limb hooks: base=%.2f giant=%.1fx when scale>=%.2f", (double)LIMB_MUL, (double)GIANT_STRENGTH, (double)GIANT_SCALE_THRESHOLD);
}

JNIEXPORT void JNICALL
Java_com_studio27_melonmod_MelonResOverlay_nativeInitLimbs(JNIEnv *env, jclass clazz) {
    (void)env; (void)clazz;
    patch_crtd_tier(g_melon_scale);
    install_limb_hooks();
    install_update_hook();
}

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved) {
    (void)vm; (void)reserved;
    LOGI("libmelonres giants 3x limb strength");
    patch_crtd_tier(g_melon_scale);
    install_limb_hooks();
    install_update_hook();
    return JNI_VERSION_1_6;
}
