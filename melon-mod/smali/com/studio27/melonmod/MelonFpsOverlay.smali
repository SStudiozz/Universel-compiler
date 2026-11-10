.class public Lcom/studio27/melonmod/MelonFpsOverlay;
.super Ljava/lang/Object;
.source "MelonFpsOverlay.java"

.field private static overlay:Landroid/widget/LinearLayout;
.field private static fpsText:Landroid/widget/TextView;
.field private static enabled:Z
.field private static frames:I
.field private static lastNs:J
.field private static handler:Landroid/os/Handler;

.method private constructor <init>()V
    .registers 1
    invoke-direct {p0}, Ljava/lang/Object;-><init>()V
    return-void
.end method

.method public static install(Landroid/app/Activity;)V
    .registers 8
    if-eqz p0, :done

    # Already installed?
    sget-object v0, Lcom/studio27/melonmod/MelonFpsOverlay;->overlay:Landroid/widget/LinearLayout;
    if-nez v0, :done

    new-instance v0, Landroid/widget/LinearLayout;
    invoke-direct {v0, p0}, Landroid/widget/LinearLayout;-><init>(Landroid/content/Context;)V
    sput-object v0, Lcom/studio27/melonmod/MelonFpsOverlay;->overlay:Landroid/widget/LinearLayout;
    const/4 v1, 0x1
    invoke-virtual {v0, v1}, Landroid/widget/LinearLayout;->setOrientation(I)V
    const/high16 v1, -0x78000000
    invoke-virtual {v0, v1}, Landroid/widget/LinearLayout;->setBackgroundColor(I)V
    const/16 v1, 0x10
    const/16 v2, 0xc
    invoke-virtual {v0, v1, v2, v1, v2}, Landroid/widget/LinearLayout;->setPadding(IIII)V
    # Make sure overlay draws on top
    const/high16 v1, 0x41200000
    invoke-virtual {v0, v1}, Landroid/widget/LinearLayout;->setElevation(F)V

    new-instance v1, Landroid/widget/CheckBox;
    invoke-direct {v1, p0}, Landroid/widget/CheckBox;-><init>(Landroid/content/Context;)V
    const-string v2, "FPS"
    invoke-virtual {v1, v2}, Landroid/widget/CheckBox;->setText(Ljava/lang/CharSequence;)V
    const/4 v2, -0x1
    invoke-virtual {v1, v2}, Landroid/widget/CheckBox;->setTextColor(I)V
    const/4 v2, 0x0
    invoke-virtual {v1, v2}, Landroid/widget/CheckBox;->setChecked(Z)V
    # Bigger hit target
    const/high16 v2, 0x41800000
    invoke-virtual {v1, v2}, Landroid/widget/CheckBox;->setTextSize(F)V
    new-instance v3, Lcom/studio27/melonmod/MelonFpsOverlay$1;
    invoke-direct {v3}, Lcom/studio27/melonmod/MelonFpsOverlay$1;-><init>()V
    invoke-virtual {v1, v3}, Landroid/widget/CheckBox;->setOnCheckedChangeListener(Landroid/widget/CompoundButton$OnCheckedChangeListener;)V
    invoke-virtual {v0, v1}, Landroid/widget/LinearLayout;->addView(Landroid/view/View;)V

    new-instance v1, Landroid/widget/TextView;
    invoke-direct {v1, p0}, Landroid/widget/TextView;-><init>(Landroid/content/Context;)V
    sput-object v1, Lcom/studio27/melonmod/MelonFpsOverlay;->fpsText:Landroid/widget/TextView;
    const-string v3, "0 FPS"
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
    const/16 v3, 0x20
    iput v3, v1, Landroid/widget/FrameLayout$LayoutParams;->leftMargin:I
    const/16 v3, 0x60
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

    new-instance v0, Landroid/os/Handler;
    invoke-static {}, Landroid/os/Looper;->getMainLooper()Landroid/os/Looper;
    move-result-object v1
    invoke-direct {v0, v1}, Landroid/os/Handler;-><init>(Landroid/os/Looper;)V
    sput-object v0, Lcom/studio27/melonmod/MelonFpsOverlay;->handler:Landroid/os/Handler;
    invoke-static {}, Ljava/lang/System;->nanoTime()J
    move-result-wide v0
    sput-wide v0, Lcom/studio27/melonmod/MelonFpsOverlay;->lastNs:J
    const/4 v0, 0x0
    sput v0, Lcom/studio27/melonmod/MelonFpsOverlay;->frames:I
    invoke-static {}, Lcom/studio27/melonmod/MelonFpsOverlay;->tick()V
    goto :done

    :catch_0
    move-exception v0
    # Clear so next attempt can retry
    const/4 v1, 0x0
    sput-object v1, Lcom/studio27/melonmod/MelonFpsOverlay;->overlay:Landroid/widget/LinearLayout;

    :done
    return-void
.end method

.method private static tick()V
    .registers 9
    sget-object v0, Lcom/studio27/melonmod/MelonFpsOverlay;->handler:Landroid/os/Handler;
    if-eqz v0, :done

    sget v1, Lcom/studio27/melonmod/MelonFpsOverlay;->frames:I
    add-int/lit8 v1, v1, 0x1
    sput v1, Lcom/studio27/melonmod/MelonFpsOverlay;->frames:I

    invoke-static {}, Ljava/lang/System;->nanoTime()J
    move-result-wide v2
    sget-wide v4, Lcom/studio27/melonmod/MelonFpsOverlay;->lastNs:J
    sub-long v4, v2, v4
    const-wide/32 v6, 0x1dcd6500
    cmp-long v6, v4, v6
    if-gez v6, :schedule

    long-to-float v4, v4
    const v5, 0x4e6e6b28
    div-float/2addr v4, v5
    int-to-float v1, v1
    div-float/2addr v1, v4
    float-to-int v1, v1
    const/4 v4, 0x0
    sput v4, Lcom/studio27/melonmod/MelonFpsOverlay;->frames:I
    sput-wide v2, Lcom/studio27/melonmod/MelonFpsOverlay;->lastNs:J

    sget-boolean v2, Lcom/studio27/melonmod/MelonFpsOverlay;->enabled:Z
    if-eqz v2, :schedule
    sget-object v2, Lcom/studio27/melonmod/MelonFpsOverlay;->fpsText:Landroid/widget/TextView;
    if-eqz v2, :schedule
    new-instance v3, Ljava/lang/StringBuilder;
    invoke-direct {v3}, Ljava/lang/StringBuilder;-><init>()V
    invoke-virtual {v3, v1}, Ljava/lang/StringBuilder;->append(I)Ljava/lang/StringBuilder;
    const-string v1, " FPS"
    invoke-virtual {v3, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v1
    invoke-virtual {v2, v1}, Landroid/widget/TextView;->setText(Ljava/lang/CharSequence;)V

    :schedule
    new-instance v1, Lcom/studio27/melonmod/MelonFpsOverlay$2;
    invoke-direct {v1}, Lcom/studio27/melonmod/MelonFpsOverlay$2;-><init>()V
    const-wide/16 v2, 0x10
    invoke-virtual {v0, v1, v2, v3}, Landroid/os/Handler;->postDelayed(Ljava/lang/Runnable;J)Z

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
    goto :done
    :hide
    const/16 v1, 0x8
    invoke-virtual {v0, v1}, Landroid/widget/TextView;->setVisibility(I)V
    :done
    return-void
.end method

.method static synthetic access$tick()V
    .registers 0
    invoke-static {}, Lcom/studio27/melonmod/MelonFpsOverlay;->tick()V
    return-void
.end method
