.class public Lcom/studio27/melonmod/MelonDocumentsProvider;
.super Landroid/provider/DocumentsProvider;
.source "MelonDocumentsProvider.java"

.field private mRoot:Ljava/io/File;


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
    if-eqz v1, :fail
    iput-object v1, p0, Lcom/studio27/melonmod/MelonDocumentsProvider;->mRoot:Ljava/io/File;
    invoke-virtual {v1}, Ljava/io/File;->exists()Z
    move-result v0
    if-nez v0, :check_dir
    invoke-virtual {v1}, Ljava/io/File;->mkdirs()Z
    :check_dir
    invoke-virtual {v1}, Ljava/io/File;->isDirectory()Z
    move-result v0
    if-eqz v0, :fail
    new-instance v0, Ljava/io/File;
    const-string v2, "Mods"
    invoke-direct {v0, v1, v2}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V
    invoke-virtual {v0}, Ljava/io/File;->exists()Z
    move-result v2
    if-nez v2, :ok
    invoke-virtual {v0}, Ljava/io/File;->mkdirs()Z
    :ok
    const/4 v0, 0x1
    return v0
    :fail
    const/4 v0, 0x0
    return v0
.end method


.method private resolveDocId(Ljava/lang/String;)Ljava/io/File;
    .registers 5
    if-eqz p1, :null
    iget-object v0, p0, Lcom/studio27/melonmod/MelonDocumentsProvider;->mRoot:Ljava/io/File;
    if-eqz v0, :null
    const-string v1, "root"
    invoke-virtual {v1, p1}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-nez v1, :root
    const-string v1, "root/"
    invoke-virtual {p1, v1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
    move-result v1
    if-eqz v1, :null
    const/4 v1, 0x5
    invoke-virtual {p1, v1}, Ljava/lang/String;->substring(I)Ljava/lang/String;
    move-result-object v1
    new-instance v2, Ljava/io/File;
    invoke-direct {v2, v0, v1}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V
    :try_start_0
    invoke-virtual {v2}, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;
    move-result-object v1
    invoke-virtual {v0}, Ljava/io/File;->getCanonicalPath()Ljava/lang/String;
    move-result-object v0
    invoke-virtual {v1, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result p1
    if-nez p1, :ok
    new-instance p1, Ljava/lang/StringBuilder;
    invoke-direct {p1}, Ljava/lang/StringBuilder;-><init>()V
    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v0, "/"
    invoke-virtual {p1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {p1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object p1
    invoke-virtual {v1, p1}, Ljava/lang/String;->startsWith(Ljava/lang/String;)Z
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
    :root
    return-object v0
.end method


.method private colsDefault()[Ljava/lang/String;
    .registers 4
    const/4 v0, 0x6
    new-array v0, v0, [Ljava/lang/String;
    const/4 v1, 0x0
    const-string v2, "document_id"
    aput-object v2, v0, v1
    const/4 v1, 0x1
    const-string v2, "_display_name"
    aput-object v2, v0, v1
    const/4 v1, 0x2
    const-string v2, "mime_type"
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
    invoke-virtual {p3}, Ljava/io/File;->getName()Ljava/lang/String;
    move-result-object v1
    if-eqz v1, :empty_name
    invoke-virtual {v1}, Ljava/lang/String;->length()I
    move-result v2
    if-eqz v2, :empty_name
    goto :have_name
    :empty_name
    const-string v1, "(unnamed)"
    :have_name
    invoke-virtual {v0, v1}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;
    invoke-virtual {p3}, Ljava/io/File;->isDirectory()Z
    move-result v1
    if-eqz v1, :file_mime
    const-string v1, "vnd.android.document/directory"
    goto :add_mime
    :file_mime
    const-string v1, "application/octet-stream"
    :add_mime
    invoke-virtual {v0, v1}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;
    invoke-virtual {p3}, Ljava/io/File;->lastModified()J
    move-result-wide v2
    invoke-static {v2, v3}, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
    move-result-object v1
    invoke-virtual {v0, v1}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;
    invoke-virtual {p3}, Ljava/io/File;->isDirectory()Z
    move-result v1
    if-eqz v1, :file_flags
    const/16 v1, 0x14e
    goto :add_flags
    :file_flags
    const/16 v1, 0x146
    :add_flags
    invoke-static {v1}, Ljava/lang/Integer;->valueOf(I)Ljava/lang/Integer;
    move-result-object v1
    invoke-virtual {v0, v1}, Landroid/database/MatrixCursor$RowBuilder;->add(Ljava/lang/Object;)Landroid/database/MatrixCursor$RowBuilder;
    invoke-virtual {p3}, Ljava/io/File;->isFile()Z
    move-result v1
    if-eqz v1, :zero_size
    invoke-virtual {p3}, Ljava/io/File;->length()J
    move-result-wide v2
    goto :add_size
    :zero_size
    const-wide/16 v2, 0x0
    :add_size
    invoke-static {v2, v3}, Ljava/lang/Long;->valueOf(J)Ljava/lang/Long;
    move-result-object v1
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
    iget-object v1, p0, Lcom/studio27/melonmod/MelonDocumentsProvider;->mRoot:Ljava/io/File;
    if-eqz v1, :done
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
    :done
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
    if-eqz v3, :done
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


.method public createDocument(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    .registers 7
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/FileNotFoundException;
        }
    .end annotation
    invoke-direct {p0, p1}, Lcom/studio27/melonmod/MelonDocumentsProvider;->resolveDocId(Ljava/lang/String;)Ljava/io/File;
    move-result-object v0
    if-nez v0, :ok_parent
    new-instance v1, Ljava/io/FileNotFoundException;
    const-string v2, "parent"
    invoke-direct {v1, v2}, Ljava/io/FileNotFoundException;-><init>(Ljava/lang/String;)V
    throw v1
    :ok_parent
    if-nez p3, :has_name
    const-string p3, "New file"
    :has_name
    new-instance v1, Ljava/io/File;
    invoke-direct {v1, v0, p3}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V
    const-string v0, "vnd.android.document/directory"
    invoke-virtual {v0, p2}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-eqz v0, :make_file
    invoke-virtual {v1}, Ljava/io/File;->mkdir()Z
    move-result v0
    if-nez v0, :made
    new-instance v0, Ljava/io/FileNotFoundException;
    const-string v2, "mkdir failed"
    invoke-direct {v0, v2}, Ljava/io/FileNotFoundException;-><init>(Ljava/lang/String;)V
    throw v0
    :make_file
    invoke-virtual {v1}, Ljava/io/File;->createNewFile()Z
    move-result v0
    if-nez v0, :made
    invoke-virtual {v1}, Ljava/io/File;->exists()Z
    move-result v0
    if-nez v0, :made
    new-instance v0, Ljava/io/FileNotFoundException;
    const-string v2, "create failed"
    invoke-direct {v0, v2}, Ljava/io/FileNotFoundException;-><init>(Ljava/lang/String;)V
    throw v0
    :made
    new-instance v0, Ljava/lang/StringBuilder;
    invoke-direct {v0}, Ljava/lang/StringBuilder;-><init>()V
    invoke-virtual {v0, p1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v2, "/"
    invoke-virtual {v0, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v1}, Ljava/io/File;->getName()Ljava/lang/String;
    move-result-object v1
    invoke-virtual {v0, v1}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v0}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v0
    return-object v0
.end method


.method public deleteDocument(Ljava/lang/String;)V
    .registers 4
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/FileNotFoundException;
        }
    .end annotation
    invoke-direct {p0, p1}, Lcom/studio27/melonmod/MelonDocumentsProvider;->resolveDocId(Ljava/lang/String;)Ljava/io/File;
    move-result-object v0
    if-nez v0, :ok
    new-instance v1, Ljava/io/FileNotFoundException;
    invoke-direct {v1, p1}, Ljava/io/FileNotFoundException;-><init>(Ljava/lang/String;)V
    throw v1
    :ok
    iget-object v1, p0, Lcom/studio27/melonmod/MelonDocumentsProvider;->mRoot:Ljava/io/File;
    invoke-virtual {v0, v1}, Ljava/io/File;->equals(Ljava/lang/Object;)Z
    move-result v1
    if-eqz v1, :del
    new-instance v1, Ljava/io/FileNotFoundException;
    const-string v0, "cannot delete root"
    invoke-direct {v1, v0}, Ljava/io/FileNotFoundException;-><init>(Ljava/lang/String;)V
    throw v1
    :del
    invoke-direct {p0, v0}, Lcom/studio27/melonmod/MelonDocumentsProvider;->deleteRecursive(Ljava/io/File;)Z
    move-result v0
    if-nez v0, :done
    new-instance v0, Ljava/io/FileNotFoundException;
    const-string v1, "delete failed"
    invoke-direct {v0, v1}, Ljava/io/FileNotFoundException;-><init>(Ljava/lang/String;)V
    throw v0
    :done
    return-void
.end method


.method private deleteRecursive(Ljava/io/File;)Z
    .registers 7
    if-eqz p1, :no
    invoke-virtual {p1}, Ljava/io/File;->isDirectory()Z
    move-result v0
    if-eqz v0, :file
    invoke-virtual {p1}, Ljava/io/File;->listFiles()[Ljava/io/File;
    move-result-object v0
    if-eqz v0, :file
    array-length v1, v0
    const/4 v2, 0x0
    :loop
    if-ge v2, v1, :file
    aget-object v3, v0, v2
    invoke-direct {p0, v3}, Lcom/studio27/melonmod/MelonDocumentsProvider;->deleteRecursive(Ljava/io/File;)Z
    add-int/lit8 v2, v2, 0x1
    goto :loop
    :file
    invoke-virtual {p1}, Ljava/io/File;->delete()Z
    move-result v0
    return v0
    :no
    const/4 v0, 0x0
    return v0
.end method


.method public renameDocument(Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    .registers 7
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/FileNotFoundException;
        }
    .end annotation
    invoke-direct {p0, p1}, Lcom/studio27/melonmod/MelonDocumentsProvider;->resolveDocId(Ljava/lang/String;)Ljava/io/File;
    move-result-object v0
    if-nez v0, :ok
    new-instance v1, Ljava/io/FileNotFoundException;
    invoke-direct {v1, p1}, Ljava/io/FileNotFoundException;-><init>(Ljava/lang/String;)V
    throw v1
    :ok
    if-nez p2, :has
    new-instance v1, Ljava/io/FileNotFoundException;
    const-string v2, "empty name"
    invoke-direct {v1, v2}, Ljava/io/FileNotFoundException;-><init>(Ljava/lang/String;)V
    throw v1
    :has
    new-instance v1, Ljava/io/File;
    invoke-virtual {v0}, Ljava/io/File;->getParentFile()Ljava/io/File;
    move-result-object v2
    invoke-direct {v1, v2, p2}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V
    invoke-virtual {v0, v1}, Ljava/io/File;->renameTo(Ljava/io/File;)Z
    move-result v2
    if-nez v2, :renamed
    new-instance v2, Ljava/io/FileNotFoundException;
    const-string v3, "rename failed"
    invoke-direct {v2, v3}, Ljava/io/FileNotFoundException;-><init>(Ljava/lang/String;)V
    throw v2
    :renamed
    const-string v2, "/"
    invoke-virtual {p1, v2}, Ljava/lang/String;->lastIndexOf(Ljava/lang/String;)I
    move-result v2
    if-gez v2, :no_slash
    const/4 v3, 0x0
    invoke-virtual {p1, v3, v2}, Ljava/lang/String;->substring(II)Ljava/lang/String;
    move-result-object v2
    new-instance v3, Ljava/lang/StringBuilder;
    invoke-direct {v3}, Ljava/lang/StringBuilder;-><init>()V
    invoke-virtual {v3, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v2, "/"
    invoke-virtual {v3, v2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v3, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v3}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v2
    return-object v2
    :no_slash
    return-object p2
.end method


.method public moveDocument(Ljava/lang/String;Ljava/lang/String;Ljava/lang/String;)Ljava/lang/String;
    .registers 7
    .annotation system Ldalvik/annotation/Throws;
        value = {
            Ljava/io/FileNotFoundException;
        }
    .end annotation
    invoke-direct {p0, p1}, Lcom/studio27/melonmod/MelonDocumentsProvider;->resolveDocId(Ljava/lang/String;)Ljava/io/File;
    move-result-object v0
    invoke-direct {p0, p3}, Lcom/studio27/melonmod/MelonDocumentsProvider;->resolveDocId(Ljava/lang/String;)Ljava/io/File;
    move-result-object v1
    if-nez v0, :ok1
    new-instance v2, Ljava/io/FileNotFoundException;
    invoke-direct {v2, p1}, Ljava/io/FileNotFoundException;-><init>(Ljava/lang/String;)V
    throw v2
    :ok1
    if-nez v1, :ok2
    new-instance v2, Ljava/io/FileNotFoundException;
    invoke-direct {v2, p3}, Ljava/io/FileNotFoundException;-><init>(Ljava/lang/String;)V
    throw v2
    :ok2
    new-instance v2, Ljava/io/File;
    invoke-virtual {v0}, Ljava/io/File;->getName()Ljava/lang/String;
    move-result-object p2
    invoke-direct {v2, v1, p2}, Ljava/io/File;-><init>(Ljava/io/File;Ljava/lang/String;)V
    invoke-virtual {v0, v2}, Ljava/io/File;->renameTo(Ljava/io/File;)Z
    move-result v1
    if-nez v1, :moved
    new-instance v1, Ljava/io/FileNotFoundException;
    const-string v2, "move failed"
    invoke-direct {v1, v2}, Ljava/io/FileNotFoundException;-><init>(Ljava/lang/String;)V
    throw v1
    :moved
    new-instance v1, Ljava/lang/StringBuilder;
    invoke-direct {v1}, Ljava/lang/StringBuilder;-><init>()V
    invoke-virtual {v1, p3}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    const-string v0, "/"
    invoke-virtual {v1, v0}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v1, p2}, Ljava/lang/StringBuilder;->append(Ljava/lang/String;)Ljava/lang/StringBuilder;
    invoke-virtual {v1}, Ljava/lang/StringBuilder;->toString()Ljava/lang/String;
    move-result-object v0
    return-object v0
.end method
