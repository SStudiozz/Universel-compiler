/*
 * libmelonres — ScalableBufferManager.ResizeBuffers via JNI (once per call).
 * Uses Il2CppDumper Offset (file offset), NOT RVA.
 */
#include <jni.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <android/log.h>

#define LOG_TAG "MelonRes"
#define LOGI(...) __android_log_print(ANDROID_LOG_INFO, LOG_TAG, __VA_ARGS__)
#define LOGE(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)

/* dump.cs: Offset: 0x43C5904  RVA: 0x43C6904 — use FILE OFFSET */
#define RESIZE_BUFFERS_FILE_OFF 0x43C5904u

typedef void (*ResizeBuffers_fn)(float, float);

static ResizeBuffers_fn resolve_resize(void) {
    static ResizeBuffers_fn cached = NULL;
    static int tried = 0;
    if (tried)
        return cached;
    tried = 1;

    FILE *f = fopen("/proc/self/maps", "r");
    if (!f) {
        LOGE("maps open failed");
        return NULL;
    }

    char line[768];
    while (fgets(line, sizeof(line), f)) {
        if (!strstr(line, "libil2cpp.so"))
            continue;
        if (!strstr(line, "r-x"))
            continue;

        unsigned long start = 0, end = 0, offset = 0;
        if (sscanf(line, "%lx-%lx %*s %lx", &start, &end, &offset) != 3)
            continue;

        if (RESIZE_BUFFERS_FILE_OFF < offset)
            continue;
        if (end <= start)
            continue;
        unsigned long map_span = end - start;
        if (RESIZE_BUFFERS_FILE_OFF - offset >= map_span)
            continue;

        uintptr_t addr = (uintptr_t)start + (RESIZE_BUFFERS_FILE_OFF - (uintptr_t)offset);
        cached = (ResizeBuffers_fn)addr;
        LOGI("ResizeBuffers @ %p (map %lx-%lx file_off %lx)",
             (void *)addr, start, end, offset);
        break;
    }
    fclose(f);

    if (!cached)
        LOGE("resolve ResizeBuffers failed — check maps");
    return cached;
}

JNIEXPORT void JNICALL
Java_com_studio27_melonmod_MelonResOverlay_nativeApply(JNIEnv *env, jclass clazz, jfloat scale) {
    (void)env;
    (void)clazz;

    if (scale < 0.01f)
        scale = 0.01f;
    if (scale > 1.0f)
        scale = 1.0f;

    ResizeBuffers_fn fn = resolve_resize();
    if (!fn) {
        LOGE("nativeApply: no fn");
        return;
    }

    LOGI("nativeApply scale=%.3f", (double)scale);
    fn(scale, scale);
    LOGI("nativeApply done");
}

JNIEXPORT jint JNICALL JNI_OnLoad(JavaVM *vm, void *reserved) {
    (void)vm;
    (void)reserved;
    LOGI("libmelonres loaded (file_off=0x%X)", RESIZE_BUFFERS_FILE_OFF);
    return JNI_VERSION_1_6;
}
