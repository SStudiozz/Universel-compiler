.class public Lcom/studio27/melonmod/MelonDocumentsProvider;
.super Landroid/provider/DocumentsProvider;
.source "MelonDocumentsProvider.java"

.field private mExt:Ljava/io/File;
.field private mInt:Ljava/io/File;
.field private mPkg:Ljava/io/File;


.method public constructor <init>()V
    .registers 1
    invoke-direct {p0}, Landroid/provider/DocumentsProvider;-><init>()V
    return-void
.end method


.method public onCreate()Z
    .registers 4
    invoke-virtual {p0}, Lcom/studio27/melonmod/MelonDocumentsProvider;->getContext()Landroid/content/Context;
    move-result-object v0
    if-eqz v0, :fail
    const/4 v1, 0x0
    invoke-virtual {v0, v1}, Landroid/content/Context;->getExternalFilesDir(Ljava/lang/String;)Ljava/io/File;
    move-result-object v1
    iput-object v1, p0, Lcom/studio27/melonmod/MelonDocumentsProvider;->mExt:Ljava/io/File;
    if-eqz v1, :no_pkg
    invoke-virtual {v1}, Ljava/io/File;->getParentFile()Ljava/io/File;
    move-result-object v2
    iput-object v2, p0, Lcom/studio27/melonmod/MelonDocumentsProvider;->mPkg:Ljava/io/File;
    invoke-virtual {v1}, Ljava/io/File;->exists()Z
    move-result v2
    if-nez v2, :no_pkg
    invoke-virtual {v1}, Ljava/io/File;->mkdirs()Z
    :no_pkg
    invoke-virtual {v0}, Landroid/content/Context;->getFilesDir()Ljava/io/File;
    move-result-object v1
    iput-object v1, p0, Lcom/studio27/melonmod/MelonDocumentsProvider;->mInt:Ljava/io/File;
    if-eqz v1, :ok
    invoke-virtual {v1}, Ljava/io/File;->exists()Z
    move-result v0
    if-nez v0, :ok
    invoke-virtual {v1}, Ljava/io/File;->mkdirs()Z
    :ok
    const/4 v0, 0x1
    return v0
    :fail
    const/4 v0, 0x0
    return v0
.end method


.method private rootFile(Ljava/lang/String;)Ljava/io/File;
    .registers 4
    if-eqz p1, :null
    const-string v0, "ext"
    invoke-virtual {v0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-nez v0, :ext
    const-string v0, "int"
    invoke-virtual {v0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-nez v0, :int
    const-string v0, "pkg"
    invoke-virtual {v0, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-nez v0, :pkg
    :null
    const/4 v0, 0x0
    return-object v0
    :ext
    iget-object v0, p0, Lcom/studio27/melonmod/MelonDocumentsProvider;->mExt:Ljava/io/File;
    return-object v0
    :int
    iget-object v0, p0, Lcom/studio27/melonmod/MelonDocumentsProvider;->mInt:Ljava/io/File;
    return-object v0
    :pkg
    iget-object v0, p0, Lcom/studio27/melonmod/MelonDocumentsProvider;->mPkg:Ljava/io/File;
    return-object v0
.end method


.method private resolveDocId(Ljava/lang/String;)Ljava/io/File;
    .registers 6
    if-eqz p1, :null
    const-string v0, "/"
    invoke-virtual {p1, v0}, Ljava/lang/String;->indexOf(Ljava/lang/String;)I
    move-result v0
    if-gez v0, :has_slash
    invoke-direct {p0, p1}, Lcom/studio27/melonmod/MelonDocumentsProvider;->rootFile(Ljava/lang/String;)Ljava/io/File;
    move-result-object v0
    return-object v0
    :has_slash
    const/4 v1, 0x0
    invoke-virtual {p1, v1, v0}, Ljava/lang/String;->substring(II)Ljava/lang/String;
    move-result-object v1
    add-int/lit8 v0, v0, 0x1
    invoke-virtual {p1, v0}, Ljava/lang/String;->substring(I)Ljava/lang/String;
    move-result-object v0
    invoke-direct {p0, v1}, Lcom/studio27/melonmod/MelonDocumentsProvider;->rootFile(Ljava/lang/String;)Ljava/io/File;
    move-result-object v1
    if-eqz v1, :null
    new-instance v2, Ljava/io/File;
    invoke-direct {v2, v1, v0}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V
    :try_start_0
    invoke-virtual {v2}, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;
    move-result-object v0
    invoke-virtual {v1}, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;
    move-result-object v1
    invoke-virtual {v0, v1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result p1
    if-nez p1, :ok
    new-instance p1, Ljava/lang/StringBuilder;
    invoke-direct {p1}, Ljava/lang/StringBuilder;-><init>()V
    invoke-virtual {p1, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v1, "/"
    invoke-virtual {p1, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object p1
    invoke-virtual {v0, p1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
    move-result p1
    if-eqz p1, :null
    :ok
    return-object v2
    :try_end_0
    .catch Ljava/lang/Exception; {:try_start_0 .. :try_end_0} :catch_0
    :catch_0
    move-exception p1
    :null
    const/4 p1, 0x0
    return-object p1
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


.method private addFileRow(Landroid/database/MatrixCursor;Ljava/lang/String;Ljava/io/File;)V
    .registers 8
    if-eqz p3, :done
    invoke-virtual {p1}, Landroid/database/MatrixCursor;->newRow()Landroid/database/MatrixCursor$RowBuilder;
    move-result-object v0
    invoke-virtual {v0, p2}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;
    invoke-virtual {p3}, Ljava/io/File;->isDirectory()Z
    move-result v1
    if-eqz v1, :fm
    const-string v1, "vnd.android.document/directory"
    goto :am
    :fm
    const-string v1, "application/octet-stream"
    :am
    invoke-virtual {v0, v1}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;
    invoke-virtual {p3}, Ljava/io/File;->getName()Ljava/lang/String;
    move-result-object v1
    if-nez v1, :nn
    const-string v1, ""
    :nn
    invoke-virtual {v0, v1}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;
    invoke-virtual {p3}, Ljava/io/File;->lastModified()J
    move-result-wide v2
    invoke-static {v2, v3}, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
    move-result-object v1
    invoke-virtual {v0, v1}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;
    invoke-virtual {p3}, Ljava/io/File;->isDirectory()Z
    move-result v1
    if-eqz v1, :ff
    const/16 v1, 0x16
    goto :af
    :ff
    const/4 v1, 0x6
    :af
    invoke-static {v1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
    move-result-object v1
    invoke-virtual {v0, v1}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;
    invoke-virtual {p3}, Ljava/io/File;->isFile()Z
    move-result v1
    if-eqz v1, :zs
    invoke-virtual {p3}, Ljava/io/File;->length()J
    move-result-wide v2
    goto :as
    :zs
    const-wide/16 v2, 0x0
    :as
    invoke-static {v2, v3}, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
    move-result-object v1
    invoke-virtual {v0, v1}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;
    :done
    return-void
.end method


.method private addRootRow(Landroid/database/MatrixCursor;Ljava/lang/String;Ljava/lang/String;Ljava/io/File;)V
    .registers 7
    if-eqz p4, :done
    invoke-virtual {p1}, Landroid/database/MatrixCursor;->newRow()Landroid/database/MatrixCursor$RowBuilder;
    move-result-object v0
    invoke-virtual {v0, p2}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;
    const/16 v1, 0x13
    invoke-static {v1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
    move-result-object v1
    invoke-virtual {v0, v1}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;
    invoke-virtual {v0, p3}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;
    invoke-virtual {v0, p2}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;
    const-string v1, "*/*"
    invoke-virtual {v0, v1}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;
    :done
    return-void
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
    const-string v1, "pkg"
    const-string v2, "Melon App Data"
    iget-object v3, p0, Lcom/studio27/melonmod/MelonDocumentsProvider;->mPkg:Ljava/io/File;
    invoke-direct {p0, v0, v1, v2, v3}, Lcom/studio27/melonmod/MelonDocumentsProvider;->addRootRow(Landroid/database/MatrixCursor;Ljava/lang/String;Ljava/lang/String;Ljava/io/File;)V
    const-string v1, "ext"
    const-string v2, "Melon Files (Saves/Mods)"
    iget-object v3, p0, Lcom/studio27/melonmod/MelonDocumentsProvider;->mExt:Ljava/io/File;
    invoke-direct {p0, v0, v1, v2, v3}, Lcom/studio27/melonmod/MelonDocumentsProvider;->addRootRow(Landroid/database/MatrixCursor;Ljava/lang/String;Ljava/lang/String;Ljava/io/File;)V
    const-string v1, "int"
    const-string v2, "Melon Internal"
    iget-object v3, p0, Lcom/studio27/melonmod/MelonDocumentsProvider;->mInt:Ljava/io/File;
    invoke-direct {p0, v0, v1, v2, v3}, Lcom/studio27/melonmod/MelonDocumentsProvider;->addRootRow(Landroid/database/MatrixCursor;Ljava/lang/String;Ljava/lang/String;Ljava/io/File;)V
    return-object v0
.end method


.method public queryDocument(Ljava/lang/String;[Ljava/lang/String;)Landroid/database/Cursor;
    .registers 6
    invoke-direct {p0}, Lcom/studio27/melonmod/MelonDocumentsProvider;->colsDefault()[Ljava/lang/String;
    move-result-object v0
    new-instance v1, Landroid/database/MatrixCursor;
    invoke-direct {v1, v0}, Landroid/database/MatrixCursor;-><init>([Ljava/lang/String;)V
    invoke-direct {p0, p1}, Lcom/studio27/melonmod/MelonDocumentsProvider;->resolveDocId(Ljava/lang/String;)Ljava/io/File;
    move-result-object v2
    if-eqz v2, :done
    invoke-direct {p0, v1, p1, v2}, Lcom/studio27/melonmod/MelonDocumentsProvider;->addFileRow(Landroid/database/MatrixCursor;Ljava/lang/String;Ljava/io/File;)V
    :done
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
    if-eqz v2, :done
    invoke-virtual {v2}, Ljava/io/File;->isDirectory()Z
    move-result v3
    if-nez v3, :done
    invoke-virtual {v2}, Ljava/io/File;->listFiles()[Ljava/io/File;
    move-result-object v3
    if-eqz v3, :done
    array-length v4, v3
    const/4 v5, 0x0
    :loop
    if-ge v5, v4, :done
    aget-object v6, v3, v5
    if-eqz v6, :next
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
    :next
    add-int/lit8 v5, v5, 0x1
    goto :loop
    :done
    return-object v1
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
    if-nez v0, :open
    new-instance v1, Ljava/io/FileNotFoundException;
    invoke-direct {v1, p1}, Ljava/io/FileNotFoundException;-><init>(Ljava/lang/String;)V
    throw v1
    :open
    if-nez p2, :modes
    const-string p2, "r"
    :modes
    const-string v1, "rw"
    invoke-virtual {p2, v1}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-eqz v1, :tw
    const/high16 v1, 0x38000000
    goto :do
    :tw
    const-string v1, "w"
    invoke-virtual {p2, v1}, Ljava/lang/String;->contains(Ljava/lang/CharSequence;)Z
    move-result v1
    if-eqz v1, :ro
    const/high16 v1, 0x2c000000
    goto :do
    :ro
    const/high16 v1, 0x10000000
    :do
    invoke-static {v0, v1}, Landroid/os/ParcelFileDescriptor;->open(Ljava/io/File;I)Landroid/os/ParcelFileDescriptor;
    move-result-object v1
    return-object v1
.end method


.method public getDocumentType(Ljava/lang/String;)Ljava/lang/String;
    .registers 4
    invoke-direct {p0, p1}, Lcom/studio27/melonmod/MelonDocumentsProvider;->resolveDocId(Ljava/lang/String;)Ljava/io/File;
    move-result-object v0
    if-eqz v0, :unk
    invoke-virtual {v0}, Ljava/io/File;->isDirectory()Z
    move-result v1
    if-eqz v1, :file
    const-string v1, "vnd.android.document/directory"
    return-object v1
    :file
    const-string v1, "application/octet-stream"
    return-object v1
    :unk
    const-string v1, "application/octet-stream"
    return-object v1
.end method


.method public isChildDocument(Ljava/lang/String;Ljava/lang/String;)Z
    .registers 5
    if-eqz p1, :no
    if-eqz p2, :no
    invoke-virtual {p2, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-nez v0, :yes
    new-instance v0, Ljava/lang/StringBuilder;
    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V
    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v1, "/"
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v0
    invoke-virtual {p2, v0}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
    move-result v0
    return v0
    :yes
    const/4 v0, 0x1
    return v0
    :no
    const/4 v0, 0x0
    return v0
.end method
