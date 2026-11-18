.class public Lcom/studio27/melonmod/MelonResOverlay;
.super Ljava/lang/Object;
.source "MelonResOverlay.java"

.field private static overlay:Landroid/widget/LinearLayout;
.field private static label:Landroid/widget/TextView;
.field private static activity:Landroid/app/Activity;
.field private static libLoaded:Z

.method private constructor <init>()V
    .registers 1
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    return-void
.end method

.method public static native nativeInitLimbs()V
.end method

.method public static ensureLib()V
    .registers 1
    sget-boolean v0, Lcom/studio27/melonmod/MelonResOverlay;->libLoaded:Z
    if-eqz v0, :done
    :try_start_0
    const-string v0, "melonres"
    invoke-static {v0}, Ljava/lang/System;->loadLibrary(Ljava/lang/String;)V
    invoke-static {}, Lcom/studio27/melonmod/MelonResOverlay;->nativeInitLimbs()V
    const/4 v0, 0x1
    sput-boolean v0, Lcom/studio27/melonmod/MelonResOverlay;->libLoaded:Z
    :try_end_0
    .catch Ljava/lang/Throwable; {:try_start_0 .. :try_end_0} :catch_0
    goto :done
    :catch_0
    move-exception v0
    const/4 v0, 0x0
    sput-boolean v0, Lcom/studio27/melonmod/MelonResOverlay;->libLoaded:Z
    :done
    return-void
.end method

# DIAGNOSTIC: no surface touch, no setFixedSize, no Screen hooks
.method public static applySurfaceScale()V
    .registers 0
    return-void
.end method

.method public static applyNow()V
    .registers 0
    return-void
.end method

.method public static install(Landroid/app/Activity;)V
    .registers 8
    if-eqz p0, :done
    sget-object v0, Lcom/studio27/melonmod/MelonResOverlay;->overlay:Landroid/widget/LinearLayout;
    if-nez v0, :done

    sput-object p0, Lcom/studio27/melonmod/MelonResOverlay;->activity:Landroid/app/Activity;
    # Load native ONLY for limb/giant hooks — no res
    invoke-static {}, Lcom/studio27/melonmod/MelonResOverlay;->ensureLib()V

    new-instance v0, Landroid/widget/LinearLayout;
    invoke-direct {v0, p0}, Landroid/widget/LinearLayout;-><init>(Landroid/content/Context;)V
    sput-object v0, Lcom/studio27/melonmod/MelonResOverlay;->overlay:Landroid/widget/LinearLayout;
    const/4 v1, 0x1
    invoke-virtual {v0, v1}, Landroid/widget/LinearLayout;->setOrientation(I)V
    const/high16 v1, -0x78000000
    invoke-virtual {v0, v1}, Landroid/widget/LinearLayout;->setBackgroundColor(I)V
    const/16 v1, 0x8
    const/4 v2, 0x4
    invoke-virtual {v0, v1, v2, v1, v2}, Landroid/widget/LinearLayout;->setPadding(IIII)V

    new-instance v1, Landroid/widget/TextView;
    invoke-direct {v1, p0}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V
    sput-object v1, Lcom/studio27/melonmod/MelonResOverlay;->label:Landroid/widget/TextView;
    const/4 v2, -0x1
    invoke-virtual {v1, v2}, Landroid/widget/TextView;->setTextColor(I)V
    const/high16 v2, 0x41400000
    invoke-virtual {v1, v2}, Landroid/widget/TextView;->setTextSize(F)V
    const-string v2, "Res OFF (diag)"
    invoke-virtual {v1, v2}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
    invoke-virtual {v0, v1}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    new-instance v1, Landroid/widget/FrameLayout$LayoutParams;
    const/4 v2, -0x2
    invoke-direct {v1, v2, v2}, Landroid/widget/FrameLayout$LayoutParams;-><init>(II)V
    const/16 v2, 0x35
    iput v2, v1, Landroid/widget/FrameLayout$LayoutParams;->gravity:I
    const/16 v2, 0x8
    iput v2, v1, Landroid/widget/FrameLayout$LayoutParams;->topMargin:I
    iput v2, v1, Landroid/widget/FrameLayout$LayoutParams;->rightMargin:I

    :try_start_0
    invoke-virtual {p0}, Landroid/app/Activity;->getWindow()Landroid/view/Window;
    move-result-object v2
    invoke-virtual {v2}, Landroid/view/Window;->getDecorView()Landroid/view/View;
    move-result-object v2
    check-cast v2, Landroid/view/ViewGroup;
    invoke-virtual {v2, v0, v1}, Landroid/view/ViewGroup;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0
    goto :done
    :catch_0
    move-exception v0
    const/4 v1, 0x0
    sput-object v1, Lcom/studio27/melonmod/MelonResOverlay;->overlay:Landroid/widget/LinearLayout;
    :done
    return-void
.end method
