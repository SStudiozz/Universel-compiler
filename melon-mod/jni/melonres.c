/*
 * libmelonres — apply Unity ScalableBufferManager.ResizeBuffers once via JNI.
 */
#include <jni.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <android/log.h>

#define LOG_TAG "MelonRes"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

/* File offset of ResizeBuffers in libil2cpp.so (verified against binary) */
#define RESIZE_BUFFERS_FILE_OFF 0x43C6904u

typedef void (*ResizeBuffers_fn)(float, float);

static ResizeBuffers_fn resolve_resize(void) {
    static ResizeBuffers_fn cached = NULL;
    static int tried = 0;
    if (tried) return cached;
    tried = 1;

    FILE *f = fopen("/proc/self/maps", "r");
    if (!f) {
        LOGE("maps open failed");
        return NULL;
    }

    char line[512];
    while (fgets(line, sizeof(line), f)) {
        if (!strstr(line, "libil2cpp.so")) continue;
        if (!strstr(line, "r-x")) continue;

        unsigned long start = 0, offset = 0;
        if (sscanf(line, "%lx-%*x %*s %lx", &start, &offset) != 2)
            continue;

        /* Only the mapping that contains our function file offset */
        if (RESIZE_BUFFERS_FILE_OFF < offset)
            continue;

        uintptr_t addr = (uintptr_t)start + (RESIZE_BUFFERS_FILE_OFF - (uintptr_t)offset);
        cached = (ResizeBuffers_fn)addr;
        LOGI("ResizeBuffers @ %p (start=%lx off=%lx)", (void *)addr, start, offset);
        break;
    }
    fclose(f);

    if (!cached)
        LOGE("resolve ResizeBuffers failed");
    return cached;
}

JNIEXPORT void JNICALL
Java_com_studio27_melonmod_MelonResOverlay_nativeApply(JNIEnv *env, jclass clazz, jfloat scale) {
    (void)env;
    (void)clazz;

    if (scale < 0.01f) scale = 0.01f;
    if (scale > 1.0f) scale = 1.0f;

    ResizeBuffers_fn fn = resolve_resize();
    if (!fn) return;

    LOGI("nativeApply %.3f", scale);
    fn(scale, scale);
}

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved) {
    (void)vm;
    (void)reserved;
    LOGI("libmelonres loaded");
    return JNI_VERSION_1_6;
}
