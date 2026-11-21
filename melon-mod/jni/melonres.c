/*
 * libmelonres — HAYMAKER resolution
 * 1) Rewrite CreateRenderTextureDescriptor+0x38 (fmov s8 tier)
 * 2) Call ScalableBufferManager.ResizeBuffers
 * 3) Call UniversalRenderPipeline.SetRenderScale
 * 4) Giant limb strength (unchanged)
 * Surface setFixedSize is handled in Java.
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

#define OFF_RESIZE_BUFFERS    0x43C5904u
#define OFF_SET_RENDER_SCALE  0x41B9584u
#define OFF_CRTD_SCALE        0x42C085Cu  /* CreateRTDesc +0x38 */
#define OFF_SET_BREAK_FORCE   0x4448A24u
#define OFF_SET_BREAK_TORQUE  0x4448A70u
#define OFF_GET_TRANSFORM     0x43E87B8u
#define OFF_GET_LOSSY_SCALE   0x43F659Cu

#define LIMB_MUL 1.30f
#define GIANT_SCALE_THRESHOLD 1.20f
#define GIANT_STRENGTH 3.00f

/* ARM64 encodings for s8 */
#define INSN_MOV_V8_V0   0x4EA01C08u  /* 100% — copy engine scale */
#define INSN_FMOV_S8_25  0x1E2A1008u  /* #0.25 */
#define INSN_FMOV_S8_50  0x1E2E1008u  /* #0.50 */
#define INSN_FMOV_S8_75  0x1E2F1008u  /* #0.75 */

typedef void (*ResizeBuffers_fn)(float, float);
typedef void (*SetRenderScale_fn)(float);
typedef void (*BreakSet_fn)(void *thiz, float value);
typedef void *(*GetTransform_fn)(void *component);
typedef void (*GetLossyScale_fn)(void *transform, float *out_xyz);

static float g_scale = 1.0f;
static uintptr_t g_rx_start;
static uintptr_t g_rx_file_off;
static int g_maps_ok;
static int g_limb_hooks;
static uint32_t g_saved_force[4];
static uint32_t g_saved_torque[4];
static uint32_t g_orig_crtd = INSN_MOV_V8_V0;
static int g_crtd_saved;

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
        if (OFF_CRTD_SCALE >= offset && OFF_CRTD_SCALE < offset + (end - start)) {
            g_rx_start = (uintptr_t)start;
            g_rx_file_off = (uintptr_t)offset;
            g_maps_ok = 1;
            LOGI("il2cpp RX %lx off=%lx", start, offset);
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

static void patch_crtd(float scale) {
    void *p = at_off(OFF_CRTD_SCALE);
    if (!p) { LOGE("CRTD null"); return; }
    if (mprotect_rwx(p, 8) != 0) { LOGE("CRTD mprotect"); return; }
    if (!g_crtd_saved) {
        g_orig_crtd = *(uint32_t *)p;
        g_crtd_saved = 1;
    }
    uint32_t insn;
    if (scale >= 0.99f) insn = INSN_MOV_V8_V0;       /* restore original path */
    else if (scale >= 0.70f) insn = INSN_FMOV_S8_75;
    else if (scale >= 0.40f) insn = INSN_FMOV_S8_50;
    else insn = INSN_FMOV_S8_25;
    *(uint32_t *)p = insn;
    __builtin___clear_cache((char *)p, (char *)p + 4);
    LOGI("CRTD insn=%08x scale=%.2f", insn, (double)scale);
}

static void apply_native_scale(float scale) {
    if (scale < 0.05f) scale = 0.05f;
    if (scale > 1.0f) scale = 1.0f;
    g_scale = scale;
    patch_crtd(scale);
    ResizeBuffers_fn rb = (ResizeBuffers_fn)at_off(OFF_RESIZE_BUFFERS);
    SetRenderScale_fn srs = (SetRenderScale_fn)at_off(OFF_SET_RENDER_SCALE);
    if (rb) {
        rb(scale, scale);
        LOGI("ResizeBuffers(%.2f)", (double)scale);
    } else LOGE("ResizeBuffers null");
    if (srs) {
        srs(scale);
        LOGI("SetRenderScale(%.2f)", (double)scale);
    } else LOGE("SetRenderScale null");
}

JNIEXPORT void JNICALL
Java_com_studio27_melonmod_MelonResOverlay_nativeApply(JNIEnv *env, jclass clazz, jfloat scale) {
    (void)env; (void)clazz;
    LOGI("nativeApply %.3f", (double)scale);
    apply_native_scale(scale);
}

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

static float limb_strength_mul(void *joint) {
    float s = joint_body_scale(joint);
    float mul = LIMB_MUL;
    if (s >= GIANT_SCALE_THRESHOLD)
        mul *= GIANT_STRENGTH * (s / GIANT_SCALE_THRESHOLD);
    return mul;
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
    call_orig_break(OFF_SET_BREAK_FORCE, g_saved_force, (void *)hooked_force, thiz, value * limb_strength_mul(thiz));
}
static void hooked_torque(void *thiz, float value) {
    call_orig_break(OFF_SET_BREAK_TORQUE, g_saved_torque, (void *)hooked_torque, thiz, value * limb_strength_mul(thiz));
}

static void install_limb_hooks(void) {
    if (g_limb_hooks) return;
    void *f = at_off(OFF_SET_BREAK_FORCE);
    void *q = at_off(OFF_SET_BREAK_TORQUE);
    if (!f || !q) return;
    memcpy(g_saved_force, f, 16);
    memcpy(g_saved_torque, q, 16);
    if (mprotect_rwx(f, 16) || mprotect_rwx(q, 16)) return;
    write_abs_jump((uint32_t *)f, (void *)hooked_force);
    write_abs_jump((uint32_t *)q, (void *)hooked_torque);
    __builtin___clear_cache((char *)f, (char *)f + 16);
    __builtin___clear_cache((char *)q, (char *)q + 16);
    g_limb_hooks = 1;
    LOGI("limb hooks ok");
}

JNIEXPORT void JNICALL
Java_com_studio27_melonmod_MelonResOverlay_nativeInitLimbs(JNIEnv *env, jclass clazz) {
    (void)env; (void)clazz;
    install_limb_hooks();
    /* leave CRTD at 100% until user moves slider */
    patch_crtd(1.0f);
}

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved) {
    (void)vm; (void)reserved;
    LOGI("libmelonres HAYMAKER");
    install_limb_hooks();
    return JNI_VERSION_1_6;
}
