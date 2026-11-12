.class Lcom/studio27/melonmod/MelonResOverlay$1;
.super Ljava/lang/Object;
.source "MelonResOverlay.java"
.implements Landroid/widget/SeekBar$OnSeekBarChangeListener;

.method constructor <init>()V
    .registers 1
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    return-void
.end method

.method public onProgressChanged(Landroid/widget/SeekBar;IZ)V
    .registers 4
    invoke-static {p2}, Lcom/studio27/melonmod/MelonResOverlay;->setScaleFromProgress(I)V
    return-void
.end method

.method public onStartTrackingTouch(Landroid/widget/SeekBar;)V
    .registers 1
    return-void
.end method

.method public onStopTrackingTouch(Landroid/widget/SeekBar;)V
    .registers 1
    return-void
.end method
