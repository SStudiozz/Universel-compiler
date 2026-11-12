.class public Lcom/studio27/melonmod/MelonResOverlay;
.super Ljava/lang/Object;
.source "MelonResOverlay.java"

.field private static overlay:Landroid/widget/LinearLayout;
.field private static label:Landroid/widget/TextView;
.field private static seek:Landroid/widget/SeekBar;
.field private static prefs:Landroid/content/SharedPreferences;
.field private static scale:F

.method private constructor <init>()V
    .registers 1
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    return-void
.end method

.method public static install(Landroid/app/Activity;)V
    .registers 10
    if-eqz p0, :done
    sget-object v0, Lcom/studio27/melonmod/MelonResOverlay;->overlay:Landroid/widget/LinearLayout;
    if-nez v0, :done

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
    const/16 v2, 0x32
    invoke-virtual {v1, v2}, Landroid/widget/SeekBar;->setMax(I)V
    sget v2, Lcom/studio27/melonmod/MelonResOverlay;->scale:F
    const/high16 v3, 0x42c80000
    mul-float/2addr v2, v3
    const/high16 v3, 0x42480000
    sub-float/2addr v2, v3
    float-to-int v2, v2
    if-gez v2, :clip_hi
    const/4 v2, 0x0
    :clip_hi
    const/16 v3, 0x32
    if-le v2, v3, :set_prog
    const/16 v2, 0x32
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
    int-to-float v0, p0
    const/high16 v1, 0x42c80000
    div-float/2addr v0, v1
    const/high16 v1, 0x3f000000
    add-float/2addr v0, v1
    sput v0, Lcom/studio27/melonmod/MelonResOverlay;->scale:F
    invoke-static {}, Lcom/studio27/melonmod/MelonResOverlay;->updateLabel()V
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
