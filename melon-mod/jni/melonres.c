/*
 * libmelonres
 * arm64: res tiers + limbs + SettingsController open/close -> Res UI
 * armv7: JNI stubs only
 */
#include <jni.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <unistd.h>
#include <android/log.h>

#if defined(__aarch64__)
#include <sys/mman.h>
#endif

#define LOG_TAG "MelonRes"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

static JavaVM *g_vm;

#if defined(__aarch64__)

#define OFF_RESIZE_BUFFERS    0x43C5904u
#define OFF_SET_RENDER_SCALE  0x41B9584u
#define OFF_CRTD_SCALE        0x42C085Cu
#define OFF_SET_BREAK_FORCE   0x4448A24u
#define OFF_SET_BREAK_TORQUE  0x4448A70u
#define OFF_GET_TRANSFORM     0x43E87B8u
#define OFF_GET_LOSSY_SCALE   0x43F659Cu
/* SettingsController — event-driven, no frame polling */
#define OFF_SETTINGS_START    0x222A284u
#define OFF_SETTINGS_ONDESTROY 0x222AD88u
#define OFF_SETTINGS_INITUI   0x222A588u

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
typedef void (*VoidThis_fn)(void *thiz);
typedef void *(*GetTransform_fn)(void *component);
typedef void (*GetLossyScale_fn)(void *transform, float *out_xyz);

static float g_scale = 1.0f;
static uintptr_t g_rx_start;
static uintptr_t g_rx_file_off;
static int g_maps_ok;
static int g_limb_hooks;
static int g_settings_hooks;
static uint32_t g_saved_force[4];
static uint32_t g_saved_torque[4];
static uint32_t g_saved_start[4];
static uint32_t g_saved_destroy[4];
static uint32_t g_saved_initui[4];

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
        if (OFF_SETTINGS_START >= offset && OFF_SETTINGS_START < offset + (end - start)) {
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

/* One-shot JNI: Settings open/close — no timers, no frame loops */
static void notify_settings_open(int open) {
    if (!g_vm) return;
    JNIEnv *env = NULL;
    int need_detach = 0;
    int rc = (*g_vm)->GetEnv(g_vm, (void **)&env, JNI_VERSION_1_6);
    if (rc == JNI_EDETACHED) {
        if ((*g_vm)->AttachCurrentThread(g_vm, &env, NULL) != 0) return;
        need_detach = 1;
    } else if (rc != JNI_OK) return;
    jclass cls = (*env)->FindClass(env, "com/studio27/melonmod/MelonResOverlay");
    if (cls) {
        jmethodID mid = (*env)->GetStaticMethodID(env, cls, "setSettingsOpen", "(Z)V");
        if (mid) (*env)->CallStaticVoidMethod(env, cls, mid, open ? JNI_TRUE : JNI_FALSE);
        (*env)->DeleteLocalRef(env, cls);
    }
    if (need_detach) (*g_vm)->DetachCurrentThread(g_vm);
}

static void call_orig_void(unsigned file_off, uint32_t *saved, void *hook, void *thiz) {
    void *target = at_off(file_off);
    if (!target) return;
    uint32_t *t = (uint32_t *)target;
    if (mprotect_rwx(target, 16) != 0) return;
    memcpy(t, saved, 16);
    __builtin___clear_cache((char *)t, (char *)t + 16);
    ((VoidThis_fn)target)(thiz);
    write_abs_jump(t, hook);
    __builtin___clear_cache((char *)t, (char *)t + 16);
}

static void hooked_settings_start(void *thiz) {
    call_orig_void(OFF_SETTINGS_START, g_saved_start, (void *)hooked_settings_start, thiz);
    notify_settings_open(1);
    LOGI("SettingsController.Start -> Res show");
}
static void hooked_settings_initui(void *thiz) {
    call_orig_void(OFF_SETTINGS_INITUI, g_saved_initui, (void *)hooked_settings_initui, thiz);
    notify_settings_open(1);
    LOGI("SettingsController.InitializeUI -> Res show");
}
static void hooked_settings_destroy(void *thiz) {
    notify_settings_open(0);
    LOGI("SettingsController.OnDestroy -> Res hide");
    call_orig_void(OFF_SETTINGS_ONDESTROY, g_saved_destroy, (void *)hooked_settings_destroy, thiz);
}

static void install_settings_hooks(void) {
    if (g_settings_hooks) return;
    void *s = at_off(OFF_SETTINGS_START);
    void *d = at_off(OFF_SETTINGS_ONDESTROY);
    void *i = at_off(OFF_SETTINGS_INITUI);
    if (!s || !d || !i) { LOGE("settings resolve failed"); return; }
    memcpy(g_saved_start, s, 16);
    memcpy(g_saved_destroy, d, 16);
    memcpy(g_saved_initui, i, 16);
    if (mprotect_rwx(s, 16) || mprotect_rwx(d, 16) || mprotect_rwx(i, 16)) {
        LOGE("settings mprotect failed"); return;
    }
    write_abs_jump((uint32_t *)s, (void *)hooked_settings_start);
    write_abs_jump((uint32_t *)d, (void *)hooked_settings_destroy);
    write_abs_jump((uint32_t *)i, (void *)hooked_settings_initui);
    __builtin___clear_cache((char *)s, (char *)s + 16);
    __builtin___clear_cache((char *)d, (char *)d + 16);
    __builtin___clear_cache((char *)i, (char *)i + 16);
    g_settings_hooks = 1;
    LOGI("SettingsController hooks installed (event-driven)");
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
}

#endif /* __aarch64__ */

JNIEXPORT void JNICALL
Java_com_studio27_melonmod_MelonResOverlay_nativeApply(JNIEnv *env, jclass clazz, jfloat scale) {
    (void)env; (void)clazz;
#if defined(__aarch64__)
    apply_native_scale(scale);
#else
    (void)scale;
#endif
}

JNIEXPORT void JNICALL
Java_com_studio27_melonmod_MelonResOverlay_nativeInitLimbs(JNIEnv *env, jclass clazz) {
    (void)env; (void)clazz;
#if defined(__aarch64__)
    install_limb_hooks();
    install_settings_hooks();
    patch_crtd(1.0f);
#else
    LOGI("armv7 stub");
#endif
}

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved) {
    (void)reserved;
    g_vm = vm;
#if defined(__aarch64__)
    LOGI("libmelonres arm64 + settings hooks");
    install_limb_hooks();
    install_settings_hooks();
#else
    LOGI("libmelonres armv7 stub");
#endif
    return JNI_VERSION_1_6;
}
