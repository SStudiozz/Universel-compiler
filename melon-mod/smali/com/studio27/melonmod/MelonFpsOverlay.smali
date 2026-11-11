.class public Lcom/studio27/melonmod/MelonFpsOverlay;
.super Ljava/lang/Object;
.source "MelonFpsOverlay.java"

.field private static overlay:Landroid/widget/LinearLayout;
.field private static fpsText:Landroid/widget/TextView;
.field private static enabled:Z
.field private static frames:I
.field private static lastNs:J
.field private static choreographer:Landroid/view/Choreographer;
.field private static frameCallback:Landroid/view/Choreographer$FrameCallback;

.method private constructor <init>()V
    .registers 1
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    return-void
.end method

.method public static install(Landroid/app/Activity;)V
    .registers 8
    if-eqz p0, :done

    sget-object v0, Lcom/studio27/melonmod/MelonFpsOverlay;->overlay:Landroid/widget/LinearLayout;
    if-nez v0, :done

    new-instance v0, Landroid/widget/LinearLayout;
    invoke-direct {v0, p0}, Landroid/widget/LinearLayout;-><init>(Landroid/content/Context;)V
    sput-object v0, Lcom/studio27/melonmod/MelonFpsOverlay;->overlay:Landroid/widget/LinearLayout;
    const/4 v1, 0x1
    invoke-virtual {v0, v1}, Landroid/widget/LinearLayout;->setOrientation(I)V
    const/high16 v1, -0x78000000
    invoke-virtual {v0, v1}, Landroid/widget/LinearLayout;->setBackgroundColor(I)V
    const/16 v1, 0xc
    const/16 v2, 0x8
    invoke-virtual {v0, v1, v2, v1, v2}, Landroid/widget/LinearLayout;->setPadding(IIII)V
    const/high16 v1, 0x41200000
    invoke-virtual {v0, v1}, Landroid/widget/LinearLayout;->setElevation(F)V

    new-instance v1, Landroid/widget/CheckBox;
    invoke-direct {v1, p0}, Landroid/widget/CheckBox;-><init>(Landroid/content/Context;)V
    const-string v2, "Show FPS"
    invoke-virtual {v1, v2}, Landroid/widget/CheckBox;->setText(Ljava/lang/CharSequence;)V
    const/4 v2, -0x1
    invoke-virtual {v1, v2}, Landroid/widget/CheckBox;->setTextColor(I)V
    const/4 v2, 0x0
    invoke-virtual {v1, v2}, Landroid/widget/CheckBox;->setChecked(Z)V
    const/high16 v2, 0x41600000
    invoke-virtual {v1, v2}, Landroid/widget/CheckBox;->setTextSize(F)V
    new-instance v3, Lcom/studio27/melonmod/MelonFpsOverlay$1;
    invoke-direct {v3}, Lcom/studio27/melonmod/MelonFpsOverlay$1;-><init>()V
    invoke-virtual {v1, v3}, Landroid/widget/CheckBox;->setOnCheckedChangeListener(Landroid/widget/CompoundButton$OnCheckedChangeListener;)V
    invoke-virtual {v0, v1}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    new-instance v1, Landroid/widget/TextView;
    invoke-direct {v1, p0}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V
    sput-object v1, Lcom/studio27/melonmod/MelonFpsOverlay;->fpsText:Landroid/widget/TextView;
    const-string v3, ""
    invoke-virtual {v1, v3}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V
    const/4 v3, -0x1
    invoke-virtual {v1, v3}, Landroid/widget/TextView;->setTextColor(I)V
    const/high16 v3, 0x41800000
    invoke-virtual {v1, v3}, Landroid/widget/TextView;->setTextSize(F)V
    const/16 v3, 0x8
    invoke-virtual {v1, v3}, Landroid/widget/TextView;->setVisibility(I)V
    invoke-virtual {v0, v1}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    new-instance v1, Landroid/widget/FrameLayout$LayoutParams;
    const/4 v3, -0x2
    invoke-direct {v1, v3, v3}, Landroid/widget/FrameLayout$LayoutParams;-><init>(II)V
    const/16 v3, 0x33
    iput v3, v1, Landroid/widget/FrameLayout$LayoutParams;->gravity:I
    const/16 v3, 0x10
    iput v3, v1, Landroid/widget/FrameLayout$LayoutParams;->leftMargin:I
    const/16 v3, 0x18
    iput v3, v1, Landroid/widget/FrameLayout$LayoutParams;->topMargin:I

    :try_start_0
    invoke-virtual {p0}, Landroid/app/Activity;->getWindow()Landroid/view/Window;
    move-result-object v3
    invoke-virtual {v3}, Landroid/view/Window;->getDecorView()Landroid/view/View;
    move-result-object v3
    check-cast v3, Landroid/view/ViewGroup;
    invoke-virtual {v3, v0, v1}, Landroid/view/ViewGroup;->addView(Landroid/view/View;Landroid/view/ViewGroup$LayoutParams;)V
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0

    const/4 v0, 0x0
    sput v0, Lcom/studio27/melonmod/MelonFpsOverlay;->frames:I
    invoke-static {}, Ljava/lang/System;->nanoTime()J
    move-result-wide v0
    sput-wide v0, Lcom/studio27/melonmod/MelonFpsOverlay;->lastNs:J

    invoke-static {}, Landroid/view/Choreographer;->getInstance()Landroid/view/Choreographer;
    move-result-object v0
    sput-object v0, Lcom/studio27/melonmod/MelonFpsOverlay;->choreographer:Landroid/view/Choreographer;
    new-instance v1, Lcom/studio27/melonmod/MelonFpsOverlay$2;
    invoke-direct {v1}, Lcom/studio27/melonmod/MelonFpsOverlay$2;-><init>()V
    sput-object v1, Lcom/studio27/melonmod/MelonFpsOverlay;->frameCallback:Landroid/view/Choreographer$FrameCallback;
    invoke-virtual {v0, v1}, Landroid/view/Choreographer;->postFrameCallback(Landroid/view/Choreographer$FrameCallback;)V
    goto :done

    :catch_0
    move-exception v0
    const/4 v1, 0x0
    sput-object v1, Lcom/studio27/melonmod/MelonFpsOverlay;->overlay:Landroid/widget/LinearLayout;

    :done
    return-void
.end method

.method public static onFrame()V
    .registers 9
    sget v0, Lcom/studio27/melonmod/MelonFpsOverlay;->frames:I
    add-int/lit8 v0, v0, 0x1
    sput v0, Lcom/studio27/melonmod/MelonFpsOverlay;->frames:I

    invoke-static {}, Ljava/lang/System;->nanoTime()J
    move-result-wide v1
    sget-wide v3, Lcom/studio27/melonmod/MelonFpsOverlay;->lastNs:J
    sub-long v3, v1, v3
    const-wide/32 v5, 0x1dcd6500
    cmp-long v7, v3, v5
    if-ltz v7, :reschedule

    long-to-float v3, v3
    const v4, 0x4e6e6b28
    div-float v3, v4, v3
    int-to-float v0, v0
    mul-float/2addr v0, v3
    float-to-int v0, v0
    if-ltz v0, :zero
    const/16 v3, 0x3e8
    if-le v0, v3, :show
    const/16 v0, 0x3e8
    goto :show
    :zero
    const/4 v0, 0x0

    :show
    const/4 v3, 0x0
    sput v3, Lcom/studio27/melonmod/MelonFpsOverlay;->frames:I
    sput-wide v1, Lcom/studio27/melonmod/MelonFpsOverlay;->lastNs:J

    sget-boolean v1, Lcom/studio27/melonmod/MelonFpsOverlay;->enabled:Z
    if-eqz v1, :reschedule
    sget-object v1, Lcom/studio27/melonmod/MelonFpsOverlay;->fpsText:Landroid/widget/TextView;
    if-eqz v1, :reschedule
    new-instance v2, Ljava/lang/StringBuilder;
    invoke-direct {v2}, Ljava/lang/StringBuilder;-><init>()V
    invoke-virtual {v2, v0}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
    const-string v0, " FPS"
    invoke-virtual {v2, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v2}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v0
    invoke-virtual {v1, v0}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    :reschedule
    sget-object v0, Lcom/studio27/melonmod/MelonFpsOverlay;->choreographer:Landroid/view/Choreographer;
    if-eqz v0, :done
    sget-object v1, Lcom/studio27/melonmod/MelonFpsOverlay;->frameCallback:Landroid/view/Choreographer$FrameCallback;
    if-eqz v1, :done
    invoke-virtual {v0, v1}, Landroid/view/Choreographer;->postFrameCallback(Landroid/view/Choreographer$FrameCallback;)V

    :done
    return-void
.end method

.method static synthetic access$setEnabled(Z)V
    .registers 3
    sput-boolean p0, Lcom/studio27/melonmod/MelonFpsOverlay;->enabled:Z
    sget-object v0, Lcom/studio27/melonmod/MelonFpsOverlay;->fpsText:Landroid/widget/TextView;
    if-eqz v0, :done
    if-eqz p0, :hide
    const/4 v1, 0x0
    invoke-virtual {v0, v1}, Landroid/widget/TextView;->setVisibility(I)V
    const/4 v1, 0x0
    sput v1, Lcom/studio27/melonmod/MelonFpsOverlay;->frames:I
    invoke-static {}, Ljava/lang/System;->nanoTime()J
    move-result-wide v1
    sput-wide v1, Lcom/studio27/melonmod/MelonFpsOverlay;->lastNs:J
    goto :done
    :hide
    const/16 v1, 0x8
    invoke-virtual {v0, v1}, Landroid/widget/TextView;->setVisibility(I)V
    :done
    return-void
.end method
