.class Lcom/studio27/melonmod/MelonResOverlay$2;
.super Ljava/lang/Object;
.source "MelonResOverlay.java"
.implements Landroid/view/View$OnClickListener;

.method constructor <init>()V
    .registers 1
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    return-void
.end method

.method public onClick(Landroid/view/View;)V
    .registers 2
    invoke-static {}, Lcom/studio27/melonmod/MelonResOverlay;->togglePanel()V
    return-void
.end method
