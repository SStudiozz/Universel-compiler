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

.method public static native nativeSetDisplaySize(II)V
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

# ALWAYS from DisplayMetrics — never from surface (fixed size poisons getWidth)
.method public static refreshBaseFromDisplay()V
    .registers 4
    sget-object v0, Lcom/studio27/melonmod/MelonResOverlay;->activity:Landroid/app/Activity;
    if-eqz v0, :done
    :try_start_0
    invoke-virtual {v0}, Landroid/app/Activity;->getResources()Landroid/content/res/Resources;
    move-result-object v0
    invoke-virtual {v0}, Landroid/content/res/Resources;->getDisplayMetrics()Landroid/util/DisplayMetrics;
    move-result-object v0
    iget v1, v0, Landroid/util/DisplayMetrics;->widthPixels:I
    iget v2, v0, Landroid/util/DisplayMetrics;->heightPixels:I
    if-lez v1, :done
    if-lez v2, :done
    sput v1, Lcom/studio27/melonmod/MelonResOverlay;->baseW:I
    sput v2, Lcom/studio27/melonmod/MelonResOverlay;->baseH:I
    sget-boolean v3, Lcom/studio27/melonmod/MelonResOverlay;->libLoaded:Z
    if-eqz v3, :done
    invoke-static {v1, v2}, Lcom/studio27/melonmod/MelonResOverlay;->nativeSetDisplaySize(II)V
    :try_end_0
    .catch Ljava/lang/Throwable; {:try_start_0 .. :try_end_0} :catch_0
    goto :done
    :catch_0
    move-exception v0
    :done
    return-void
.end method

.method public static applyOneSurface(Landroid/view/SurfaceView;)V
    .registers 8
    if-eqz p0, :done
    :try_start_0
    sget v0, Lcom/studio27/melonmod/MelonResOverlay;->baseW:I
    sget v1, Lcom/studio27/melonmod/MelonResOverlay;->baseH:I
    if-lez v0, :done
    if-lez v1, :done
    invoke-virtual {p0}, Landroid/view/SurfaceView;->getHolder()Landroid/view/SurfaceHolder;
    move-result-object v2
    sget v3, Lcom/studio27/melonmod/MelonResOverlay;->scale:F
    const v4, 0x3f7d70a4
    cmpl-float v4, v3, v4
    if-ltz v4, :fixed
    # 100% — full reset so we never stay stuck low
    invoke-interface {v2}, Landroid/view/SurfaceHolder;->setSizeFromLayout()V
    goto :done
    :fixed
    int-to-float v4, v0
    mul-float/2addr v4, v3
    float-to-int v4, v4
    int-to-float v5, v1
    mul-float/2addr v5, v3
    float-to-int v5, v5
    const/16 v6, 0x40
    if-ge v4, v6, :okw
    const/16 v4, 0x40
    :okw
    if-ge v5, v6, :okh
    const/16 v5, 0x40
    :okh
    # setSizeFromLayout first so Android accepts a new fixed size
    invoke-interface {v2}, Landroid/view/SurfaceHolder;->setSizeFromLayout()V
    invoke-interface {v2, v4, v5}, Landroid/view/SurfaceHolder;->setFixedSize(II)V
    :try_end_0
    .catch Ljava/lang/Throwable; {:try_start_0 .. :try_end_0} :catch_0
    goto :done
    :catch_0
    move-exception v0
    :done
    return-void
.end method

.method public static applyAllSurfaces(Landroid/view/View;)V
    .registers 4
    if-eqz p0, :done
    instance-of v0, p0, Landroid/view/SurfaceView;
    if-eqz v0, :not_sv
    check-cast p0, Landroid/view/SurfaceView;
    invoke-static {p0}, Lcom/studio27/melonmod/MelonResOverlay;->applyOneSurface(Landroid/view/SurfaceView;)V
    return-void
    :not_sv
    instance-of v0, p0, Landroid/view/ViewGroup;
    if-eqz v0, :done
    check-cast p0, Landroid/view/ViewGroup;
    invoke-virtual {p0}, Landroid/view/ViewGroup;->getChildCount()I
    move-result v0
    const/4 v1, 0x0
    :loop
    if-ge v1, v0, :done
    invoke-virtual {p0, v1}, Landroid/view/ViewGroup;->getChildAt(I)Landroid/view/View;
    move-result-object v2
    invoke-static {v2}, Lcom/studio27/melonmod/MelonResOverlay;->applyAllSurfaces(Landroid/view/View;)V
    add-int/lit8 v1, v1, 0x1
    goto :loop
    :done
    return-void
.end method

.method public static applySurfaceScale()V
    .registers 2
    sget-object v0, Lcom/studio27/melonmod/MelonResOverlay;->activity:Landroid/app/Activity;
    if-eqz v0, :done
    :try_start_0
    invoke-static {}, Lcom/studio27/melonmod/MelonResOverlay;->refreshBaseFromDisplay()V
    invoke-virtual {v0}, Landroid/app/Activity;->getWindow()Landroid/view/Window;
    move-result-object v1
    invoke-virtual {v1}, Landroid/view/Window;->getDecorView()Landroid/view/View;
    move-result-object v1
    invoke-static {v1}, Lcom/studio27/melonmod/MelonResOverlay;->applyAllSurfaces(Landroid/view/View;)V
    const v1, 0x1020002
    invoke-virtual {v0, v1}, Landroid/app/Activity;->findViewById(I)Landroid/view/View;
    move-result-object v1
    if-eqz v1, :done
    invoke-static {v1}, Lcom/studio27/melonmod/MelonResOverlay;->applyAllSurfaces(Landroid/view/View;)V
    :try_end_0
    .catch Ljava/lang/Throwable; {:try_start_0 .. :try_end_0} :catch_0
    goto :done
    :catch_0
    move-exception v0
    :done
    return-void
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
    # Clamp stored value
    const v1, 0x3d4ccccd
    cmpg-float v2, v0, v1
    if-gez v2, :hi
    const/high16 v0, 0x3f000000
    :hi
    const/high16 v1, 0x3f800000
    cmpl-float v2, v0, v1
    if-lez v2, :okscale
    const/high16 v0, 0x3f800000
    :okscale
    sput v0, Lcom/studio27/melonmod/MelonResOverlay;->scale:F

    invoke-static {}, Lcom/studio27/melonmod/MelonResOverlay;->writeScaleFile()V
    invoke-static {}, Lcom/studio27/melonmod/MelonResOverlay;->ensureLib()V
    invoke-static {}, Lcom/studio27/melonmod/MelonResOverlay;->refreshBaseFromDisplay()V

    new-instance v0, Landroid/os/Handler;
    invoke-static {}, Landroid/os/Looper;->getMainLooper()Landroid/os/Looper;
    move-result-object v1
    invoke-direct {v0, v1}, Landroid/os/Handler;-><init>(Landroid/os/Looper;)V
    # Delayed apply only — surface ready after Unity boots
    new-instance v1, Lcom/studio27/melonmod/MelonResOverlay$2;
    invoke-direct {v1}, Lcom/studio27/melonmod/MelonResOverlay$2;-><init>()V
    const-wide/16 v2, 0x5dc
    invoke-virtual {v0, v1, v2, v3}, Landroid/os/Handler;->postDelayed(Ljava/lang/Runnable;J)Z
    new-instance v1, Lcom/studio27/melonmod/MelonResOverlay$2;
    invoke-direct {v1}, Lcom/studio27/melonmod/MelonResOverlay$2;-><init>()V
    const-wide/16 v2, 0xfa0
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
    if-eqz v1, :done
    invoke-interface {v1}, Landroid/content/SharedPreferences;->edit()Landroid/content/SharedPreferences$Editor;
    move-result-object v1
    const-string v2, "res_scale"
    invoke-interface {v1, v2, v0}, Landroid/content/SharedPreferences$Editor;->putFloat(Ljava/lang/String;F)Landroid/content/SharedPreferences$Editor;
    invoke-interface {v1}, Landroid/content/SharedPreferences$Editor;->apply()V
    :done
    return-void
.end method

.method public static getScale()F
    .registers 1
    sget v0, Lcom/studio27/melonmod/MelonResOverlay;->scale:F
    return v0
.end method
