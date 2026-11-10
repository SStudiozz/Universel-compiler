.class public Lcom/studio27/melonmod/MelonDocumentsProvider;
.super Landroid/provider/DocumentsProvider;
.source "MelonDocumentsProvider.java"

.field private static final ROOT_ID:Ljava/lang/String; = "root"

.field private mRoot:Ljava/io/File;


.method public constructor <init>()V
    .registers 1
    invoke-direct {p0}, Landroid/provider/DocumentsProvider;-><init>()V
    return-void
.end method


.method private addFileRow(Landroid/database/MatrixCursor;Ljava/lang/String;Ljava/io/File;)V
    .registers 8
    invoke-virtual {p1}, Landroid/database/MatrixCursor;->newRow()Landroid/database/MatrixCursor$RowBuilder;
    move-result-object v0
    invoke-virtual {v0, p2}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;
    invoke-virtual {p3}, Ljava/io/File;->isDirectory()Z
    move-result v1
    if-eqz v1, :cond_0
    const-string v1, "vnd.android.document/directory"
    goto :goto_0
    :cond_0
    const-string v1, "application/octet-stream"
    :goto_0
    invoke-virtual {v0, v1}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;
    invoke-virtual {p3}, Ljava/io/File;->getName()Ljava/lang/String;
    move-result-object v1
    invoke-virtual {v0, v1}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;
    invoke-virtual {p3}, Ljava/io/File;->lastModified()J
    move-result-wide v2
    invoke-static {v2, v3}, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
    move-result-object v1
    invoke-virtual {v0, v1}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;
    invoke-virtual {p3}, Ljava/io/File;->isDirectory()Z
    move-result v1
    if-eqz v1, :cond_1
    const/16 v1, 0x16
    goto :goto_1
    :cond_1
    const/4 v1, 0x6
    :goto_1
    invoke-static {v1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
    move-result-object v1
    invoke-virtual {v0, v1}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;
    invoke-virtual {p3}, Ljava/io/File;->isFile()Z
    move-result v1
    if-eqz v1, :cond_2
    invoke-virtual {p3}, Ljava/io/File;->length()J
    move-result-wide v2
    goto :goto_2
    :cond_2
    const-wide/16 v2, 0x0
    :goto_2
    invoke-static {v2, v3}, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
    move-result-object v1
    invoke-virtual {v0, v1}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;
    return-void
.end method


.method private colsDefault()[Ljava/lang/String;
    .registers 4
    const/4 v0, 0x6
    new-array v0, v0, [Ljava/lang/String;
    const/4 v1, 0x0
    const-string v2, "document_id"
    aput-object v2, v0, v1
    const/4 v1, 0x1
    const-string v2, "mime_type"
    aput-object v2, v0, v1
    const/4 v1, 0x2
    const-string v2, "display_name"
    aput-object v2, v0, v1
    const/4 v1, 0x3
    const-string v2, "last_modified"
    aput-object v2, v0, v1
    const/4 v1, 0x4
    const-string v2, "flags"
    aput-object v2, v0, v1
    const/4 v1, 0x5
    const-string v2, "_size"
    aput-object v2, v0, v1
    return-object v0
.end method


.method private resolveDocId(Ljava/lang/String;)Ljava/io/File;
    .registers 5
    if-eqz p1, :cond_null
    const-string v0, "root"
    invoke-virtual {v0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-eqz v0, :cond_rel
    iget-object v0, p0, Lcom/studio27/melonmod/MelonDocumentsProvider;->mRoot:Ljava/io/File;
    return-object v0
    :cond_rel
    const-string v0, "root/"
    invoke-virtual {p1, v0}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
    move-result v0
    if-nez v0, :cond_null
    const/4 v0, 0x5
    invoke-virtual {p1, v0}, Ljava/lang/String;->substring(I)Ljava/lang/String;
    move-result-object v0
    new-instance v1, Ljava/io/File;
    iget-object v2, p0, Lcom/studio27/melonmod/MelonDocumentsProvider;->mRoot:Ljava/io/File;
    invoke-direct {v1, v2, v0}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V
    :try_start_0
    invoke-virtual {v1}, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;
    move-result-object v0
    iget-object v2, p0, Lcom/studio27/melonmod/MelonDocumentsProvider;->mRoot:Ljava/io/File;
    invoke-virtual {v2}, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;
    move-result-object v2
    invoke-virtual {v0, v2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result p1
    if-eqz p1, :cond_pref
    return-object v1
    :cond_pref
    new-instance p1, Ljava/lang/StringBuilder;
    invoke-direct {p1}, Ljava/lang/StringBuilder;-><init>()V
    invoke-virtual {p1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    sget-object v2, Ljava/io/File;->separator:Ljava/lang/String;
    invoke-virtual {p1, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object p1
    invoke-virtual {v0, p1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
    move-result p1
    if-eqz p1, :cond_null
    return-object v1
    :try_end_0
    .catch Ljava/io/IOException; {:try_start_0 .. :try_end_0} :catch_0
    :catch_0
    move-exception p1
    :cond_null
    const/4 p1, 0x0
    return-object p1
.end method


.method public onCreate()Z
    .registers 3
    invoke-virtual {p0}, Lcom/studio27/melonmod/MelonDocumentsProvider;->getContext()Landroid/content/Context;
    move-result-object v0
    if-nez v0, :cond_fail
    const/4 v1, 0x0
    invoke-virtual {v0, v1}, Landroid/content/Context;->getExternalFilesDir(Ljava/lang/String;)Ljava/io/File;
    move-result-object v1
    if-nez v1, :cond_set
    invoke-virtual {v0}, Landroid/content/Context;->getFilesDir()Ljava/io/File;
    move-result-object v1
    :cond_set
    if-nez v1, :cond_fail
    iput-object v1, p0, Lcom/studio27/melonmod/MelonDocumentsProvider;->mRoot:Ljava/io/File;
    invoke-virtual {v1}, Ljava/io/File;->exists()Z
    move-result v0
    if-nez v0, :cond_ok
    invoke-virtual {v1}, Ljava/io/File;->mkdirs()Z
    :cond_ok
    const/4 v0, 0x1
    return v0
    :cond_fail
    const/4 v0, 0x0
    return v0
.end method


.method public openDocument(Ljava/lang/String;Ljava/lang/String;Landroid/os/CancellationSignal;)Landroid/os/ParcelFileDescriptor;
    .registers 6
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/FileNotFoundException;
        }
    .end annotation
    invoke-direct {p0, p1}, Lcom/studio27/melonmod/MelonDocumentsProvider;->resolveDocId(Ljava/lang/String;)Ljava/io/File;
    move-result-object v0
    if-nez v0, :cond_open
    new-instance v1, Ljava/io/FileNotFoundException;
    invoke-direct {v1, p1}, Ljava/io/FileNotFoundException;-><init>(Ljava/lang/String;)V
    throw v1
    :cond_open
    if-nez p2, :cond_modes
    const-string p2, "r"
    :cond_modes
    const-string v1, "rw"
    invoke-virtual {p2, v1}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-eqz v1, :cond_rw
    const/high16 v1, 0x38000000
    goto :goto_mode
    :cond_rw
    const-string v1, "w"
    invoke-virtual {p2, v1}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-eqz v1, :cond_r
    const/high16 v1, 0x2c000000
    goto :goto_mode
    :cond_r
    const/high16 v1, 0x10000000
    :goto_mode
    invoke-static {v0, v1}, Landroid/os/ParcelFileDescriptor;->open(Ljava/io/File;I)Landroid/os/ParcelFileDescriptor;
    move-result-object v1
    return-object v1
.end method


.method public queryChildDocuments(Ljava/lang/String;[Ljava/lang/String;Ljava/lang/String;)Landroid/database/Cursor;
    .registers 12
    invoke-direct {p0}, Lcom/studio27/melonmod/MelonDocumentsProvider;->colsDefault()[Ljava/lang/String;
    move-result-object v0
    new-instance v1, Landroid/database/MatrixCursor;
    invoke-direct {v1, v0}, Landroid/database/MatrixCursor;-><init>([Ljava/lang/String;)V
    invoke-direct {p0, p1}, Lcom/studio27/melonmod/MelonDocumentsProvider;->resolveDocId(Ljava/lang/String;)Ljava/io/File;
    move-result-object v2
    if-nez v2, :cond_end
    invoke-virtual {v2}, Ljava/io/File;->isDirectory()Z
    move-result v3
    if-eqz v3, :cond_end
    invoke-virtual {v2}, Ljava/io/File;->listFiles()[Ljava/io/File;
    move-result-object v3
    if-eqz v3, :cond_end
    array-length v4, v3
    const/4 v5, 0x0
    :cond_loop
    if-ge v5, v4, :cond_end
    aget-object v6, v3, v5
    new-instance v7, Ljava/lang/StringBuilder;
    invoke-direct {v7}, Ljava/lang/StringBuilder;-><init>()V
    invoke-virtual {v7, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v0, "/"
    invoke-virtual {v7, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v6}, Ljava/io/File;->getName()Ljava/lang/String;
    move-result-object v0
    invoke-virtual {v7, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v7}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v7
    invoke-direct {p0, v1, v7, v6}, Lcom/studio27/melonmod/MelonDocumentsProvider;->addFileRow(Landroid/database/MatrixCursor;Ljava/lang/String;Ljava/io/File;)V
    add-int/lit8 v5, v5, 0x1
    goto :cond_loop
    :cond_end
    return-object v1
.end method


.method public queryDocument(Ljava/lang/String;[Ljava/lang/String;)Landroid/database/Cursor;
    .registers 6
    invoke-direct {p0}, Lcom/studio27/melonmod/MelonDocumentsProvider;->colsDefault()[Ljava/lang/String;
    move-result-object v0
    new-instance v1, Landroid/database/MatrixCursor;
    invoke-direct {v1, v0}, Landroid/database/MatrixCursor;-><init>([Ljava/lang/String;)V
    invoke-direct {p0, p1}, Lcom/studio27/melonmod/MelonDocumentsProvider;->resolveDocId(Ljava/lang/String;)Ljava/io/File;
    move-result-object v2
    if-eqz v2, :cond_ret
    invoke-direct {p0, v1, p1, v2}, Lcom/studio27/melonmod/MelonDocumentsProvider;->addFileRow(Landroid/database/MatrixCursor;Ljava/lang/String;Ljava/io/File;)V
    :cond_ret
    return-object v1
.end method


.method public queryRoots([Ljava/lang/String;)Landroid/database/Cursor;
    .registers 6
    new-instance v0, Landroid/database/MatrixCursor;
    const/4 v1, 0x5
    new-array v1, v1, [Ljava/lang/String;
    const/4 v2, 0x0
    const-string v3, "root_id"
    aput-object v3, v1, v2
    const/4 v2, 0x1
    const-string v3, "flags"
    aput-object v3, v1, v2
    const/4 v2, 0x2
    const-string v3, "title"
    aput-object v3, v1, v2
    const/4 v2, 0x3
    const-string v3, "document_id"
    aput-object v3, v1, v2
    const/4 v2, 0x4
    const-string v3, "mime_types"
    aput-object v3, v1, v2
    invoke-direct {v0, v1}, Landroid/database/MatrixCursor;-><init>([Ljava/lang/String;)V
    invoke-virtual {v0}, Landroid/database/MatrixCursor;->newRow()Landroid/database/MatrixCursor$RowBuilder;
    move-result-object v1
    const-string v2, "root"
    invoke-virtual {v1, v2}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;
    const/16 v3, 0x13
    invoke-static {v3}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
    move-result-object v3
    invoke-virtual {v1, v3}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;
    const-string v3, "Melon Playground"
    invoke-virtual {v1, v3}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;
    invoke-virtual {v1, v2}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;
    const-string v3, "*/*"
    invoke-virtual {v1, v3}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;
    return-object v0
.end method
