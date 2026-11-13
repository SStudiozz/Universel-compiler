.class public Lcom/studio27/melonmod/MelonResOverlay;
.super Ljava/lang/Object;
.source "MelonResOverlay.java"

.field private static overlay:Landroid/widget/LinearLayout;
.field private static label:Landroid/widget/TextView;
.field private static seek:Landroid/widget/SeekBar;
.field private static prefs:Landroid/content/SharedPreferences;
.field private static scale:F
.field private static appCtx:Landroid/content/Context;
.field private static activity:Landroid/app/Activity;
.field private static libLoaded:Z
.field private static baseW:I
.field private static baseH:I

.method private constructor <init>()V
    .registers 1
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    return-void
.end method

.method public static native nativeApply(F)V
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

.method public static applySurfaceScale()V
    .registers 9
    sget-object v0, Lcom/studio27/melonmod/MelonResOverlay;->activity:Landroid/app/Activity;
    if-eqz v0, :done
    :try_start_0
    const v1, 0x1020002
    invoke-virtual {v0, v1}, Landroid/app/Activity;->findViewById(I)Landroid/view/View;
    move-result-object v0
    check-cast v0, Landroid/view/ViewGroup;
    if-eqz v0, :done
    invoke-static {v0}, Lcom/studio27/melonmod/MelonResOverlay;->findSurfaceView(Landroid/view/View;)Landroid/view/SurfaceView;
    move-result-object v1
    if-eqz v1, :done
    invoke-virtual {v1}, Landroid/view/SurfaceView;->getWidth()I
    move-result v2
    invoke-virtual {v1}, Landroid/view/SurfaceView;->getHeight()I
    move-result v3
    if-lez v2, :done
    if-lez v3, :done
    # Capture native layout size once (never shrink base)
    sget v4, Lcom/studio27/melonmod/MelonResOverlay;->baseW:I
    if-lez v4, :have_base
    sput v2, Lcom/studio27/melonmod/MelonResOverlay;->baseW:I
    sput v3, Lcom/studio27/melonmod/MelonResOverlay;->baseH:I
    :have_base
    sget v2, Lcom/studio27/melonmod/MelonResOverlay;->baseW:I
    sget v3, Lcom/studio27/melonmod/MelonResOverlay;->baseH:I
    invoke-virtual {v1}, Landroid/view/SurfaceView;->getHolder()Landroid/view/SurfaceHolder;
    move-result-object v4
    sget v5, Lcom/studio27/melonmod/MelonResOverlay;->scale:F
    const v6, 0x3f7d70a4
    cmpl-float v6, v5, v6
    if-ltz v6, :do_fixed
    # 100%: back to full layout size
    invoke-interface {v4}, Landroid/view/SurfaceHolder;->setSizeFromLayout()V
    goto :done
    :do_fixed
    # Reset then apply new size so Android accepts changes
    invoke-interface {v4}, Landroid/view/SurfaceHolder;->setSizeFromLayout()V
    int-to-float v6, v2
    mul-float/2addr v6, v5
    float-to-int v6, v6
    int-to-float v7, v3
    mul-float/2addr v7, v5
    float-to-int v7, v7
    const/16 v8, 0x40
    if-ge v6, v8, :okw
    const/16 v6, 0x40
    :okw
    if-ge v7, v8, :okh
    const/16 v7, 0x40
    :okh
    invoke-interface {v4, v6, v7}, Landroid/view/SurfaceHolder;->setFixedSize(II)V
    :try_end_0
    .catch Ljava/lang/Throwable; {:try_start_0 .. :try_end_0} :catch_0
    goto :done
    :catch_0
    move-exception v0
    :done
    return-void
.end method

.method private static findSurfaceView(Landroid/view/View;)Landroid/view/SurfaceView;
    .registers 5
    if-eqz p0, :none
    instance-of v0, p0, Landroid/view/SurfaceView;
    if-eqz v0, :not_sv
    check-cast p0, Landroid/view/SurfaceView;
    return-object p0
    :not_sv
    instance-of v0, p0, Landroid/view/ViewGroup;
    if-eqz v0, :none
    check-cast p0, Landroid/view/ViewGroup;
    invoke-virtual {p0}, Landroid/view/ViewGroup;->getChildCount()I
    move-result v0
    const/4 v1, 0x0
    :loop
    if-ge v1, v0, :none
    invoke-virtual {p0, v1}, Landroid/view/ViewGroup;->getChildAt(I)Landroid/view/View;
    move-result-object v2
    invoke-static {v2}, Lcom/studio27/melonmod/MelonResOverlay;->findSurfaceView(Landroid/view/View;)Landroid/view/SurfaceView;
    move-result-object v2
    if-eqz v2, :next
    return-object v2
    :next
    add-int/lit8 v1, v1, 0x1
    goto :loop
    :none
    const/4 v0, 0x0
    return-object v0
.end method

.method public static applyNow()V
    .registers 1
    invoke-static {}, Lcom/studio27/melonmod/MelonResOverlay;->ensureLib()V
    sget-boolean v0, Lcom/studio27/melonmod/MelonResOverlay;->libLoaded:Z
    if-eqz v0, :surface
    sget v0, Lcom/studio27/melonmod/MelonResOverlay;->scale:F
    invoke-static {v0}, Lcom/studio27/melonmod/MelonResOverlay;->nativeApply(F)V
    :surface
    invoke-static {}, Lcom/studio27/melonmod/MelonResOverlay;->applySurfaceScale()V
    return-void
.end method

.method public static install(Landroid/app/Activity;)V
    .registers 10
    if-eqz p0, :done
    sget-object v0, Lcom/studio27/melonmod/MelonResOverlay;->overlay:Landroid/widget/LinearLayout;
    if-nez v0, :done

    sput-object p0, Lcom/studio27/melonmod/MelonResOverlay;->activity:Landroid/app/Activity;
    const/4 v0, 0x0
    sput v0, Lcom/studio27/melonmod/MelonResOverlay;->baseW:I
    sput v0, Lcom/studio27/melonmod/MelonResOverlay;->baseH:I

    invoke-virtual {p0}, Landroid/app/Activity;->getApplicationContext()Landroid/content/Context;
    move-result-object v0
    sput-object v0, Lcom/studio27/melonmod/MelonResOverlay;->appCtx:Landroid/content/Context;

    const-string v0, "melon_mod_prefs"
    const/4 v1, 0x0
    invoke-virtual {p0, v0, v1}, Landroid/app/Activity;->getSharedPreferences(Ljava/lang/String;I)Landroid/content/SharedPreferences;
    move-result-object v0
    sput-object v0, Lcom/studio27/melonmod/MelonResOverlay;->prefs:Landroid/content/SharedPreferences;
    const-string v1, "res_scale"
    const/high16 v2, 0x3f800000
    invoke-interface {v0, v1, v2}, Landroid/content/SharedPreferences;->getFloat(Ljava/lang/String;F)F
    move-result v0
    sput v0, Lcom/studio27/melonmod/MelonResOverlay;->scale:F
    invoke-static {}, Lcom/studio27/melonmod/MelonResOverlay;->writeScaleFile()V
    invoke-static {}, Lcom/studio27/melonmod/MelonResOverlay;->ensureLib()V

    new-instance v0, Landroid/os/Handler;
    invoke-static {}, Landroid/os/Looper;->getMainLooper()Landroid/os/Looper;
    move-result-object v1
    invoke-direct {v0, v1}, Landroid/os/Handler;-><init>(Landroid/os/Looper;)V
    new-instance v1, Lcom/studio27/melonmod/MelonResOverlay$2;
    invoke-direct {v1}, Lcom/studio27/melonmod/MelonResOverlay$2;-><init>()V
    const-wide/16 v2, 0x7d0
    invoke-virtual {v0, v1, v2, v3}, Landroid/os/Handler;->postDelayed(Ljava/lang/Runnable;J)Z
    new-instance v1, Lcom/studio27/melonmod/MelonResOverlay$2;
    invoke-direct {v1}, Lcom/studio27/melonmod/MelonResOverlay$2;-><init>()V
    const-wide/16 v2, 0xfa0
    invoke-virtual {v0, v1, v2, v3}, Landroid/os/Handler;->postDelayed(Ljava/lang/Runnable;J)Z
    new-instance v1, Lcom/studio27/melonmod/MelonResOverlay$2;
    invoke-direct {v1}, Lcom/studio27/melonmod/MelonResOverlay$2;-><init>()V
    const-wide/16 v2, 0x1770
    invoke-virtual {v0, v1, v2, v3}, Landroid/os/Handler;->postDelayed(Ljava/lang/Runnable;J)Z

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
    invoke-static {}, Lcom/studio27/melonmod/MelonResOverlay;->updateLabel()V
    invoke-virtual {v0, v1}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    new-instance v1, Landroid/widget/SeekBar;
    invoke-direct {v1, p0}, Landroid/widget/SeekBar;-><init>(Landroid/content/Context;)V
    sput-object v1, Lcom/studio27/melonmod/MelonResOverlay;->seek:Landroid/widget/SeekBar;
    const/16 v2, 0x64
    invoke-virtual {v1, v2}, Landroid/widget/SeekBar;->setMax(I)V
    sget v2, Lcom/studio27/melonmod/MelonResOverlay;->scale:F
    const/high16 v3, 0x42c80000
    mul-float/2addr v2, v3
    float-to-int v2, v2
    if-lez v2, :pmin
    const/4 v2, 0x1
    :pmin
    const/16 v3, 0x64
    if-le v2, v3, :set_prog
    const/16 v2, 0x64
    :set_prog
    invoke-virtual {v1, v2}, Landroid/widget/SeekBar;->setProgress(I)V
    new-instance v2, Lcom/studio27/melonmod/MelonResOverlay$1;
    invoke-direct {v2}, Lcom/studio27/melonmod/MelonResOverlay$1;-><init>()V
    invoke-virtual {v1, v2}, Landroid/widget/SeekBar;->setOnSeekBarChangeListener(Landroid/widget/SeekBar$OnSeekBarChangeListener;)V
    new-instance v2, Landroid/widget/LinearLayout$LayoutParams;
    const/4 v3, -0x1
    const/4 v4, -0x2
    invoke-direct {v2, v3, v4}, Landroid/widget/LinearLayout$LayoutParams;-><init>(II)V
    const/16 v3, 0xc8
    iput v3, v2, Landroid/widget/LinearLayout$LayoutParams;->width:I
    invoke-virtual {v0, v1, v2}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V

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

.method public static writeScaleFile()V
    .registers 5
    sget-object v0, Lcom/studio27/melonmod/MelonResOverlay;->appCtx:Landroid/content/Context;
    if-eqz v0, :done
    :try_start_0
    invoke-virtual {v0}, Landroid/content/Context;->getFilesDir()Ljava/io/File;
    move-result-object v0
    new-instance v1, Ljava/io/File;
    const-string v2, "melon_rscale"
    invoke-direct {v1, v0, v2}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V
    new-instance v0, Ljava/io/FileOutputStream;
    invoke-direct {v0, v1}, Ljava/io/FileOutputStream;-><init>(Ljava/io/File;)V
    new-instance v1, Ljava/io/DataOutputStream;
    invoke-direct {v1, v0}, Ljava/io/DataOutputStream;-><init>(Ljava/io/OutputStream;)V
    sget v2, Lcom/studio27/melonmod/MelonResOverlay;->scale:F
    invoke-virtual {v1, v2}, Ljava/io/DataOutputStream;->writeFloat(F)V
    invoke-virtual {v1}, Ljava/io/DataOutputStream;->flush()V
    invoke-virtual {v1}, Ljava/io/DataOutputStream;->close()V
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0
    goto :done
    :catch_0
    move-exception v0
    :done
    return-void
.end method

.method public static updateLabel()V
    .registers 4
    sget-object v0, Lcom/studio27/melonmod/MelonResOverlay;->label:Landroid/widget/TextView;
    if-eqz v0, :done
    sget v1, Lcom/studio27/melonmod/MelonResOverlay;->scale:F
    const/high16 v2, 0x42c80000
    mul-float/2addr v1, v2
    float-to-int v1, v1
    new-instance v2, Ljava/lang/StringBuilder;
    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V
    const-string v3, "Res "
    invoke-virtual {v2, v3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v2, v1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
    const-string v1, "%"
    invoke-virtual {v2, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v1
    invoke-virtual {v0, v1}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
    :done
    return-void
.end method

.method public static setScaleFromProgress(I)V
    .registers 4
    if-lez p0, :one
    const/4 p0, 0x1
    :one
    const/16 v0, 0x64
    if-le p0, v0, :ok
    const/16 p0, 0x64
    :ok
    int-to-float v0, p0
    const/high16 v1, 0x42c80000
    div-float/2addr v0, v1
    sput v0, Lcom/studio27/melonmod/MelonResOverlay;->scale:F
    invoke-static {}, Lcom/studio27/melonmod/MelonResOverlay;->updateLabel()V
    invoke-static {}, Lcom/studio27/melonmod/MelonResOverlay;->writeScaleFile()V
    sget-object v1, Lcom/studio27/melonmod/MelonResOverlay;->prefs:Landroid/content/SharedPreferences;
    if-eqz v1, :apply
    invoke-interface {v1}, Landroid/content/SharedPreferences;->edit()Landroid/content/SharedPreferences$Editor;
    move-result-object v1
    const-string v2, "res_scale"
    invoke-interface {v1, v2, v0}, Landroid/content/SharedPreferences$Editor;->putFloat(Ljava/lang/String;F)Landroid/content/SharedPreferences$Editor;
    invoke-interface {v1}, Landroid/content/SharedPreferences$Editor;->apply()V
    :apply
    invoke-static {}, Lcom/studio27/melonmod/MelonResOverlay;->applyNow()V
    return-void
.end method

.method public static getScale()F
    .registers 1
    sget v0, Lcom/studio27/melonmod/MelonResOverlay;->scale:F
    return v0
.end method
