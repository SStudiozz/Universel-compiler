.class Lcom/studio27/melonmod/MelonResOverlay$3;
.super Ljava/lang/Object;
.source "MelonResOverlay.java"
.implements Ljava/lang/Runnable;

.field private final synthetic val$open:Z

.method constructor <init>(Z)V
    .registers 2
    iput-boolean p1, p0, Lcom/studio27/melonmod/MelonResOverlay$3;->val$open:Z
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    return-void
.end method

.method public run()V
    .registers 2
    iget-boolean v0, p0, Lcom/studio27/melonmod/MelonResOverlay$3;->val$open:Z
    invoke-static {v0}, Lcom/studio27/melonmod/MelonResOverlay;->applySettingsVisibility(Z)V
    return-void
.end method
