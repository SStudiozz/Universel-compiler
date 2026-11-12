/*
 * libmelonres.so
 * - Resolution: ResizeBuffers
 * - Limbs: set_breakForce / set_breakTorque * 1.3125
 * Absolute LDR+BR hooks (works across .so mapping distance).
 */
#define _GNU_SOURCE
#include <jni.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/mman.h>
#include <android/log.h>

#define LOG_TAG "MelonRes"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

#define RESIZE_BUFFERS_OFF   0x43C5904u
#define SET_BREAK_FORCE_OFF  0x4448A24u
#define SET_BREAK_TORQUE_OFF 0x4448A70u

typedef void (*ResizeBuffers_fn)(float, float);

static ResizeBuffers_fn g_resize = NULL;
static uintptr_t g_il2cpp_file_off_base = 0;
static int g_mapped = 0;

static int resolve_il2cpp_map(void) {
    if (g_mapped)
        return 1;
    FILE *f = fopen("/proc/self/maps", "r");
    if (!f)
        return 0;
    char line[768];
    while (fgets(line, sizeof(line), f)) {
        if (!strstr(line, "libil2cpp.so"))
            continue;
        if (!strstr(line, "r-x"))
            continue;
        unsigned long start = 0, end = 0, offset = 0;
        if (sscanf(line, "%lx-%lx %*s %lx", &start, &end, &offset) != 3)
            continue;
        if (SET_BREAK_FORCE_OFF >= offset &&
            SET_BREAK_FORCE_OFF < offset + (end - start)) {
            g_il2cpp_file_off_base = (uintptr_t)start - (uintptr_t)offset;
            g_mapped = 1;
            LOGI("il2cpp r-x %lx-%lx base=%lx", start, end,
                 (unsigned long)g_il2cpp_file_off_base);
            break;
        }
        if (!g_mapped) {
            g_il2cpp_file_off_base = (uintptr_t)start - (uintptr_t)offset;
            g_mapped = 1;
        }
    }
    fclose(f);
    return g_mapped;
}

static void *addr_from_file_off(uint32_t file_off) {
    if (!resolve_il2cpp_map())
        return NULL;
    return (void *)(g_il2cpp_file_off_base + file_off);
}

static int make_writable(void *addr, size_t len) {
    uintptr_t page = (uintptr_t)addr & ~0xFFFul;
    uintptr_t end = ((uintptr_t)addr + len + 0xFFF) & ~0xFFFul;
    return mprotect((void *)page, end - page, PROT_READ | PROT_WRITE | PROT_EXEC) == 0;
}

static ResizeBuffers_fn resolve_resize(void) {
    if (g_resize)
        return g_resize;
    g_resize = (ResizeBuffers_fn)addr_from_file_off(RESIZE_BUFFERS_OFF);
    if (g_resize)
        LOGI("ResizeBuffers @ %p", (void *)g_resize);
    else
        LOGE("ResizeBuffers resolve failed");
    return g_resize;
}

JNIEXPORT void JNICALL
Java_com_studio27_melonmod_MelonResOverlay_nativeApply(JNIEnv *env, jclass clazz, jfloat scale) {
    (void)env;
    (void)clazz;
    if (scale < 0.01f) scale = 0.01f;
    if (scale > 1.0f) scale = 1.0f;
    ResizeBuffers_fn fn = resolve_resize();
    if (!fn) {
        LOGE("nativeApply: no ResizeBuffers");
        return;
    }
    LOGI("nativeApply scale=%.3f", (double)scale);
    fn(scale, scale);
    LOGI("nativeApply done");
}

/* 16-byte abs jump at target + trampoline with *1.3125 on s0 */
static uint8_t g_tramp_force[64] __attribute__((aligned(16)));
static uint8_t g_tramp_torque[64] __attribute__((aligned(16)));

static void install_mul_hook(uint32_t file_off, uint8_t *tramp, const char *name) {
    void *target = addr_from_file_off(file_off);
    if (!target) {
        LOGE("%s: resolve failed", name);
        return;
    }
    uint32_t *t = (uint32_t *)target;
    /* steal 16 bytes (4 insns) */
    uint32_t s0 = t[0], s1 = t[1], s2 = t[2], s3 = t[3];
    void *resume = (void *)(t + 4);

    /* trampoline */
    uint32_t *tp = (uint32_t *)tramp;
    int i = 0;
    /* fmov s1, #1.3125 */
    tp[i++] = (0x1E27D001u & ~0x001FE000u & ~0x1Fu) | 1u | (0x75u << 13);
    /* fmul s0, s0, s1 */
    tp[i++] = 0x1E210800u;
    tp[i++] = s0;
    tp[i++] = s1;
    tp[i++] = s2;
    tp[i++] = s3;
    /* ldr x16, #8 ; br x16 ; .quad resume */
    tp[i++] = 0x58000050u; /* ldr x16, #8 */
    tp[i++] = 0xD61F0200u; /* br x16 */
    memcpy(&tp[i], &resume, 8);

    if (!make_writable(tramp, 64)) {
        LOGE("%s: tramp mprotect failed", name);
        return;
    }
    if (!make_writable(target, 16)) {
        LOGE("%s: target mprotect failed", name);
        return;
    }
    /* at target: ldr x16, #8 ; br x16 ; .quad tramp */
    t[0] = 0x58000050u;
    t[1] = 0xD61F0200u;
    memcpy(&t[2], &tramp, 8);

    __builtin___clear_cache((char *)target, (char *)target + 16);
    __builtin___clear_cache((char *)tramp, (char *)tramp + 64);
    LOGI("%s hooked @ %p tramp %p (*1.3125)", name, target, tramp);
}

static void install_limb_hooks(void) {
    if (!resolve_il2cpp_map()) {
        LOGE("limb hooks: no il2cpp map");
        return;
    }
    install_mul_hook(SET_BREAK_FORCE_OFF, g_tramp_force, "set_breakForce");
    install_mul_hook(SET_BREAK_TORQUE_OFF, g_tramp_torque, "set_breakTorque");
}

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved) {
    (void)vm;
    (void)reserved;
    LOGI("libmelonres loaded");
    install_limb_hooks();
    return JNI_VERSION_1_6;
}
