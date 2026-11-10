.class Lcom/studio27/melonmod/MelonFpsOverlay$2;
.super Ljava/lang/Object;
.source "MelonFpsOverlay.java"
.implements Ljava/lang/Runnable;

.method constructor <init>()V
    .registers 1
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    return-void
.end method

.method public run()V
    .registers 1
    invoke-static {}, Lcom/studio27/melonmod/MelonFpsOverlay;->access$tick()V
    return-void
.end method
