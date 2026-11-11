.class Lcom/studio27/melonmod/MelonFpsOverlay$2;
.super Ljava/lang/Object;
.source "MelonFpsOverlay.java"
.implements Landroid/view/Choreographer$FrameCallback;

.method constructor <init>()V
    .registers 1
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    return-void
.end method

.method public doFrame(J)V
    .registers 3
    invoke-static {}, Lcom/studio27/melonmod/MelonFpsOverlay;->onFrame()V
    return-void
.end method
