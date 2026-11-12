/*
 * libmelonres
 * - Resolution: ResizeBuffers + URP SetRenderScale
 * - Limbs: set_breakForce / set_breakTorque * 1.30
 *   (restore-call-rehook: ADRP-safe, no il2cpp cave overwrite)
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

#define OFF_RESIZE_BUFFERS   0x43C5904u
#define OFF_SET_RENDER_SCALE 0x41B9584u
#define OFF_SET_BREAK_FORCE  0x4448A24u
#define OFF_SET_BREAK_TORQUE 0x4448A70u
#define LIMB_MUL 1.30f

typedef void (*ResizeBuffers_fn)(float, float);
typedef void (*SetRenderScale_fn)(float);
typedef void (*BreakSet_fn)(void *thiz, float value);

static uintptr_t g_rx_start;
static uintptr_t g_rx_file_off;
static int g_maps_ok;
static int g_hooks_ok;
static uint32_t g_saved_force[4];
static uint32_t g_saved_torque[4];

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
        if (OFF_SET_BREAK_FORCE < offset) continue;
        if (OFF_SET_BREAK_FORCE - offset >= (end - start)) continue;
        g_rx_start = (uintptr_t)start;
        g_rx_file_off = (uintptr_t)offset;
        g_maps_ok = 1;
        LOGI("il2cpp RX %lx-%lx off=%lx", start, end, offset);
        break;
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

JNIEXPORT void JNICALL
Java_com_studio27_melonmod_MelonResOverlay_nativeApply(JNIEnv *env, jclass clazz, jfloat scale) {
    (void)env; (void)clazz;
    if (scale < 0.01f) scale = 0.01f;
    if (scale > 1.0f) scale = 1.0f;

    ResizeBuffers_fn rb = (ResizeBuffers_fn)at_off(OFF_RESIZE_BUFFERS);
    SetRenderScale_fn srs = (SetRenderScale_fn)at_off(OFF_SET_RENDER_SCALE);
    LOGI("nativeApply %.3f rb=%p srs=%p", (double)scale, (void *)rb, (void *)srs);

    if (rb) { rb(scale, scale); LOGI("ResizeBuffers ok"); }
    if (srs) { srs(scale); LOGI("SetRenderScale ok"); }
}

static void call_orig(unsigned file_off, uint32_t *saved, void *hook, void *thiz, float value) {
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
    call_orig(OFF_SET_BREAK_FORCE, g_saved_force, (void *)hooked_force, thiz, value * LIMB_MUL);
}
static void hooked_torque(void *thiz, float value) {
    call_orig(OFF_SET_BREAK_TORQUE, g_saved_torque, (void *)hooked_torque, thiz, value * LIMB_MUL);
}

static void install_limb_hooks(void) {
    if (g_hooks_ok) return;
    void *f = at_off(OFF_SET_BREAK_FORCE);
    void *q = at_off(OFF_SET_BREAK_TORQUE);
    if (!f || !q) {
        LOGE("limb resolve failed f=%p q=%p", f, q);
        return;
    }
    memcpy(g_saved_force, f, 16);
    memcpy(g_saved_torque, q, 16);
    if (mprotect_rwx(f, 16) || mprotect_rwx(q, 16)) {
        LOGE("limb mprotect failed");
        return;
    }
    write_abs_jump((uint32_t *)f, (void *)hooked_force);
    write_abs_jump((uint32_t *)q, (void *)hooked_torque);
    __builtin___clear_cache((char *)f, (char *)f + 16);
    __builtin___clear_cache((char *)q, (char *)q + 16);
    g_hooks_ok = 1;
    LOGI("limb hooks *%.2f installed", (double)LIMB_MUL);
}

JNIEXPORT void JNICALL
Java_com_studio27_melonmod_MelonResOverlay_nativeInitLimbs(JNIEnv *env, jclass clazz) {
    (void)env; (void)clazz;
    install_limb_hooks();
}

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved) {
    (void)vm; (void)reserved;
    LOGI("libmelonres loaded");
    install_limb_hooks();
    return JNI_VERSION_1_6;
}
