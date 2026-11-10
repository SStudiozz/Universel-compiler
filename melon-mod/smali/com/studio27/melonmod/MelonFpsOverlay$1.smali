.class Lcom/studio27/melonmod/MelonFpsOverlay$1;
.super Ljava/lang/Object;
.source "MelonFpsOverlay.java"
.implements Landroid/widget/CompoundButton$OnCheckedChangeListener;

.method constructor <init>()V
    .registers 1
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    return-void
.end method

.method public onCheckedChanged(Landroid/widget/CompoundButton;Z)V
    .registers 3
    invoke-static {p2}, Lcom/studio27/melonmod/MelonFpsOverlay;->access$setEnabled(Z)V
    return-void
.end method
