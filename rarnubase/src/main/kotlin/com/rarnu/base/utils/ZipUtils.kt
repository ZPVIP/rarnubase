package com.rarnu.base.utils

import org.apache.commons.compress.archivers.zip.Zip64Mode
import org.apache.commons.compress.archivers.zip.ZipArchiveEntry
import org.apache.commons.compress.archivers.zip.ZipArchiveInputStream
import org.apache.commons.compress.archivers.zip.ZipArchiveOutputStream
import org.apache.commons.io.IOUtils
import java.io.*
import kotlin.concurrent.thread

class ZipUtils {

    var zipPath = ""
    var srcPath = ""
    var destPath = ""
    internal var _success: () -> Unit = {}
    internal var _error: (String?) -> Unit = { _ -> }

    fun success(onSuccess: () -> Unit) {
        _success = onSuccess
    }

    fun error(onError: (String?) -> Unit) {
        _error = onError
    }
}

fun zipAsync(init: ZipUtils.() -> Unit) = thread { zip(init) }

fun zip(init: ZipUtils.() -> Unit) {
    val z = ZipUtils()
    z.init()
    try {
        ZipOperations.zip(z.zipPath, z.srcPath)
        z._success()
    } catch (e: Exception) {
        z._error(e.message)
    }
}

fun unzipAsync(init: ZipUtils.() -> Unit) = thread { unzip(init) }

fun unzip(init: ZipUtils.() -> Unit) {
    val z = ZipUtils()
    z.init()
    try {
        ZipOperations.unzip(z.zipPath, z.destPath)
        z._success()
    } catch (e: Exception) {
        z._error(e.message)
    }
}

private object ZipOperations {
    fun getFiles(dir: String): MutableList<String> {
        val lstFile = arrayListOf<String>()
        val file = File(dir)
        val files = file.listFiles()
        files.filter { it.name != ".tmp" }.forEach {
            if (it.isDirectory) {
                lstFile.add(it.absolutePath)
                lstFile.addAll(getFiles(it.absolutePath))
            } else {
                lstFile.add(it.absolutePath)
            }
        }
        return lstFile
    }

    fun getFilePathName(dir: String, path: String): String = path.replace(dir + File.separator, "").replace("\\", "/")

    @Throws(Exception::class)
    fun compressFiles(files: Array<String>?, zipPath: String, dir: String) {
        if (files == null || files.isEmpty()) {
            return
        }
        val zipFile = File(zipPath)
        val zaos = ZipArchiveOutputStream(zipFile)
        zaos.setUseZip64(Zip64Mode.AsNeeded)
        for (f in files) {
            val file = File(f)
            val name = getFilePathName(dir, f)
            val zipEntry = ZipArchiveEntry(file, name)
            zaos.putArchiveEntry(zipEntry)
            if (file.isDirectory) continue
            val bis = BufferedInputStream(FileInputStream(file))

            IOUtils.copy(bis, zaos)
            zaos.closeArchiveEntry()
            bis.close()
        }
        zaos.close()
    }

    @Throws(Exception::class)
    fun zip(zipPath: String, dir: String) {
        val paths = getFiles(dir)
        compressFiles(paths.toTypedArray(), zipPath, dir)
    }

    @Throws(Exception::class)
    fun unzip(zipPath: String, saveDir: String) {
        var saveFileDir = saveDir
        if (!saveFileDir.endsWith("\\") && !saveFileDir.endsWith("/")) {
            saveFileDir += File.separator
        }
        val dir = File(saveFileDir)
        if (!dir.exists()) {
            dir.mkdirs()
        }
        val file = File(zipPath)
        if (file.exists()) {
            val fis = FileInputStream(file)
            val zais = ZipArchiveInputStream(fis)
            while (true) {
                val archiveEntry = zais.nextEntry ?: break
                val entryFileName = archiveEntry.name
                val entryFilePath = saveFileDir + entryFileName
                val entryFile = File(entryFilePath)
                if (entryFileName.endsWith(File.separator)) {
                    entryFile.mkdirs()
                } else {
                    val bos = BufferedOutputStream(FileOutputStream(entryFile))
                    IOUtils.copy(zais, bos)
                    bos.close()
                }
            }

            fis.close()
            zais.close()
        }
    }
}
