/*
 * libmelonres
 * - Settings-only Res UI + 60 FPS lock
 * - Cheap giant tiers (cached)
 * - Fast trampolines (no hot mprotect)
 */
#include <jni.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <stdlib.h>
#include <android/log.h>

#if defined(__aarch64__)
#include <sys/mman.h>
#endif

#define LOG_TAG "MelonRes"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

static JavaVM *g_vm;
static jclass g_overlay_class;
static jmethodID g_set_settings_open;

#if defined(__aarch64__)

#define OFF_RESIZE_BUFFERS      0x43C5904u
#define OFF_SET_RENDER_SCALE    0x41B9584u
#define OFF_CRTD_SCALE          0x42C085Cu
#define OFF_SET_BREAK_FORCE     0x4448A24u
#define OFF_SET_BREAK_TORQUE    0x4448A70u
#define OFF_GET_TRANSFORM       0x43E87B8u
#define OFF_GET_LOSSY_SCALE     0x43F659Cu
#define OFF_SETTINGS_START      0x2229284u
#define OFF_SETTINGS_ONDESTROY  0x2229D88u
#define OFF_SETTINGS_INITUI     0x2229588u
#define OFF_APPLY_FRAME_RATE    0x222ADE0u
#define OFF_SET_TARGET_FPS      0x43B7674u

#define BASE_LIMB_MUL 1.30f
#define TALL_SCALE    1.25f
#define HUGE_SCALE    2.00f
#define TALL_MUL      3.00f
#define HUGE_MUL      5.00f

#define INSN_MOV_V8_V0   0x4EA01C08u
#define INSN_FMOV_S8_25  0x1E2A1008u
#define INSN_FMOV_S8_50  0x1E2E1008u
#define INSN_FMOV_S8_75  0x1E2F1008u

#define MUL_CACHE_N 32

typedef void (*ResizeBuffers_fn)(float, float);
typedef void (*SetRenderScale_fn)(float);
typedef void (*BreakSet_fn)(void *thiz, float value);
typedef void (*VoidThis_fn)(void *thiz);
typedef void (*VoidFn)(void);
typedef void (*SetTargetFps_fn)(int value);
typedef void *(*GetTransform_fn)(void *component);
typedef void (*GetLossyScale_fn)(void *transform, float *out_xyz);

static float g_scale = 1.0f;
static int g_lock60;
static uintptr_t g_rx_start;
static uintptr_t g_rx_file_off;
static int g_maps_ok;
static int g_limb_hooks;
static int g_settings_hooks;
static int g_fps_hooks;

static GetTransform_fn g_get_tr;
static GetLossyScale_fn g_get_ls;
static SetTargetFps_fn g_set_fps;

static uint32_t *g_tramp_force;
static uint32_t *g_tramp_torque;
static uint32_t *g_tramp_start;
static uint32_t *g_tramp_destroy;
static uint32_t *g_tramp_initui;
static uint32_t *g_tramp_fps;

static void *g_mul_key[MUL_CACHE_N];
static float g_mul_val[MUL_CACHE_N];
static int g_mul_clock;

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
        if (OFF_SETTINGS_START >= offset &&
            OFF_SETTINGS_START < offset + (end - start)) {
            g_rx_start = (uintptr_t)start;
            g_rx_file_off = (uintptr_t)offset;
            g_maps_ok = 1;
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

static uint32_t *make_trampoline(void *func) {
    uint32_t *tr = (uint32_t *)mmap(NULL, 4096,
        PROT_READ | PROT_WRITE | PROT_EXEC,
        MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    if (tr == MAP_FAILED) return NULL;
    memcpy(tr, func, 16);
    write_abs_jump(tr + 4, (char *)func + 16);
    __builtin___clear_cache((char *)tr, (char *)tr + 32);
    return tr;
}

static void apply_target_fps(void) {
    if (!g_set_fps) g_set_fps = (SetTargetFps_fn)at_off(OFF_SET_TARGET_FPS);
    if (!g_set_fps) return;
    if (g_lock60) {
        g_set_fps(60);
        LOGI("targetFrameRate=60");
    }
}

static void notify_settings_open(int open) {
    if (!g_vm || !g_overlay_class || !g_set_settings_open) return;
    JNIEnv *env = NULL;
    int need_detach = 0;
    int rc = (*g_vm)->GetEnv(g_vm, (void **)&env, JNI_VERSION_1_6);
    if (rc == JNI_EDETACHED) {
        if ((*g_vm)->AttachCurrentThread(g_vm, &env, NULL) != 0) return;
        need_detach = 1;
    } else if (rc != JNI_OK) return;
    (*env)->CallStaticVoidMethod(env, g_overlay_class, g_set_settings_open,
                                 open ? JNI_TRUE : JNI_FALSE);
    if ((*env)->ExceptionCheck(env)) (*env)->ExceptionClear(env);
    if (need_detach) (*g_vm)->DetachCurrentThread(g_vm);
}

static void cache_jni(JNIEnv *env) {
    if (g_overlay_class) return;
    jclass local = (*env)->FindClass(env, "com/studio27/melonmod/MelonResOverlay");
    if (!local) {
        if ((*env)->ExceptionCheck(env)) (*env)->ExceptionClear(env);
        return;
    }
    g_overlay_class = (jclass)(*env)->NewGlobalRef(env, local);
    (*env)->DeleteLocalRef(env, local);
    g_set_settings_open = (*env)->GetStaticMethodID(env, g_overlay_class,
                            "setSettingsOpen", "(Z)V");
}

static void hooked_settings_start(void *thiz) {
    if (g_tramp_start) ((VoidThis_fn)g_tramp_start)(thiz);
    notify_settings_open(1);
}
static void hooked_settings_initui(void *thiz) {
    if (g_tramp_initui) ((VoidThis_fn)g_tramp_initui)(thiz);
    notify_settings_open(1);
}
static void hooked_settings_destroy(void *thiz) {
    notify_settings_open(0);
    if (g_tramp_destroy) ((VoidThis_fn)g_tramp_destroy)(thiz);
}

static void hooked_apply_fps(void) {
    if (g_tramp_fps) ((VoidFn)g_tramp_fps)();
    apply_target_fps();
}

static void install_settings_hooks(void) {
    if (g_settings_hooks) return;
    void *s = at_off(OFF_SETTINGS_START);
    void *d = at_off(OFF_SETTINGS_ONDESTROY);
    void *i = at_off(OFF_SETTINGS_INITUI);
    if (!s || !d || !i) return;
    g_tramp_start = make_trampoline(s);
    g_tramp_destroy = make_trampoline(d);
    g_tramp_initui = make_trampoline(i);
    if (!g_tramp_start || !g_tramp_destroy || !g_tramp_initui) return;
    if (mprotect_rwx(s, 16) || mprotect_rwx(d, 16) || mprotect_rwx(i, 16)) return;
    write_abs_jump((uint32_t *)s, (void *)hooked_settings_start);
    write_abs_jump((uint32_t *)d, (void *)hooked_settings_destroy);
    write_abs_jump((uint32_t *)i, (void *)hooked_settings_initui);
    __builtin___clear_cache((char *)s, (char *)s + 16);
    __builtin___clear_cache((char *)d, (char *)d + 16);
    __builtin___clear_cache((char *)i, (char *)i + 16);
    g_settings_hooks = 1;
}

static void install_fps_hooks(void) {
    if (g_fps_hooks) return;
    void *f = at_off(OFF_APPLY_FRAME_RATE);
    g_set_fps = (SetTargetFps_fn)at_off(OFF_SET_TARGET_FPS);
    if (!f || !g_set_fps) { LOGE("fps resolve fail"); return; }
    g_tramp_fps = make_trampoline(f);
    if (!g_tramp_fps) return;
    if (mprotect_rwx(f, 16)) return;
    write_abs_jump((uint32_t *)f, (void *)hooked_apply_fps);
    __builtin___clear_cache((char *)f, (char *)f + 16);
    g_fps_hooks = 1;
    LOGI("ApplyFrameRateSettings hooked");
    apply_target_fps();
}

static void patch_crtd(float scale) {
    void *p = at_off(OFF_CRTD_SCALE);
    if (!p) return;
    if (mprotect_rwx(p, 8) != 0) return;
    uint32_t insn;
    if (scale >= 0.99f) insn = INSN_MOV_V8_V0;
    else if (scale >= 0.70f) insn = INSN_FMOV_S8_75;
    else if (scale >= 0.40f) insn = INSN_FMOV_S8_50;
    else insn = INSN_FMOV_S8_25;
    *(uint32_t *)p = insn;
    __builtin___clear_cache((char *)p, (char *)p + 4);
}

static void apply_native_scale(float scale) {
    if (scale < 0.05f) scale = 0.05f;
    if (scale > 1.0f) scale = 1.0f;
    g_scale = scale;
    patch_crtd(scale);
    ResizeBuffers_fn rb = (ResizeBuffers_fn)at_off(OFF_RESIZE_BUFFERS);
    SetRenderScale_fn srs = (SetRenderScale_fn)at_off(OFF_SET_RENDER_SCALE);
    if (rb) rb(scale, scale);
    if (srs) srs(scale);
}

static float compute_mul_from_scale(float s) {
    if (s >= HUGE_SCALE) return HUGE_MUL;
    if (s >= TALL_SCALE) return TALL_MUL;
    return BASE_LIMB_MUL;
}

static float sample_joint_scale(void *joint) {
    if (!g_get_tr || !g_get_ls || !joint) return 1.0f;
    void *tr = g_get_tr(joint);
    if (!tr) return 1.0f;
    float v[4] = {1.0f, 1.0f, 1.0f, 0.0f};
    g_get_ls(tr, v);
    float sx = v[0] < 0.0f ? -v[0] : v[0];
    float sy = v[1] < 0.0f ? -v[1] : v[1];
    float s = sx > sy ? sx : sy;
    if (s < 0.25f) s = 0.25f;
    if (s > 20.0f) s = 20.0f;
    return s;
}

static float limb_strength_mul(void *joint) {
    if (!joint) return BASE_LIMB_MUL;
    int slot = (int)(((uintptr_t)joint >> 4) & (MUL_CACHE_N - 1));
    if (g_mul_key[slot] == joint)
        return g_mul_val[slot];
    float mul = compute_mul_from_scale(sample_joint_scale(joint));
    g_mul_key[slot] = joint;
    g_mul_val[slot] = mul;
    g_mul_clock++;
    return mul;
}

static void hooked_force(void *thiz, float value) {
    if (g_tramp_force)
        ((BreakSet_fn)g_tramp_force)(thiz, value * limb_strength_mul(thiz));
}
static void hooked_torque(void *thiz, float value) {
    if (g_tramp_torque)
        ((BreakSet_fn)g_tramp_torque)(thiz, value * limb_strength_mul(thiz));
}

static void install_limb_hooks(void) {
    if (g_limb_hooks) return;
    void *f = at_off(OFF_SET_BREAK_FORCE);
    void *q = at_off(OFF_SET_BREAK_TORQUE);
    if (!f || !q) return;
    g_get_tr = (GetTransform_fn)at_off(OFF_GET_TRANSFORM);
    g_get_ls = (GetLossyScale_fn)at_off(OFF_GET_LOSSY_SCALE);
    g_tramp_force = make_trampoline(f);
    g_tramp_torque = make_trampoline(q);
    if (!g_tramp_force || !g_tramp_torque) return;
    if (mprotect_rwx(f, 16) || mprotect_rwx(q, 16)) return;
    write_abs_jump((uint32_t *)f, (void *)hooked_force);
    write_abs_jump((uint32_t *)q, (void *)hooked_torque);
    __builtin___clear_cache((char *)f, (char *)f + 16);
    __builtin___clear_cache((char *)q, (char *)q + 16);
    memset(g_mul_key, 0, sizeof(g_mul_key));
    g_limb_hooks = 1;
}

#endif /* __aarch64__ */

JNIEXPORT void JNICALL
Java_com_studio27_melonmod_MelonResOverlay_nativeApply(JNIEnv *env, jclass clazz, jfloat scale) {
    (void)clazz;
#if defined(__aarch64__)
    cache_jni(env);
    apply_native_scale(scale);
#else
    (void)env; (void)scale;
#endif
}

JNIEXPORT void JNICALL
Java_com_studio27_melonmod_MelonResOverlay_nativeSetLock60(JNIEnv *env, jclass clazz, jboolean on) {
    (void)env; (void)clazz;
#if defined(__aarch64__)
    g_lock60 = on ? 1 : 0;
    apply_target_fps();
    if (!on && g_set_fps) {
        /* yield to game default after unlock; ApplyFrameRateSettings will fix 30 mode */
        g_set_fps(-1);
        LOGI("targetFrameRate=-1 (unlocked)");
    }
#else
    (void)on;
#endif
}

JNIEXPORT void JNICALL
Java_com_studio27_melonmod_MelonResOverlay_nativeInitLimbs(JNIEnv *env, jclass clazz) {
    (void)clazz;
#if defined(__aarch64__)
    cache_jni(env);
    install_limb_hooks();
    install_settings_hooks();
    install_fps_hooks();
    patch_crtd(1.0f);
#else
    (void)env;
#endif
}

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved) {
    (void)reserved;
    g_vm = vm;
#if defined(__aarch64__)
    LOGI("libmelonres fps60+cache");
#else
    LOGI("libmelonres armv7 stub");
#endif
    return JNI_VERSION_1_6;
}
