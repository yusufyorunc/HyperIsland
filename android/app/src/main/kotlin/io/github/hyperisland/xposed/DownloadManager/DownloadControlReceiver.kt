package io.github.hyperisland.xposed.DownloadManager

import android.app.DownloadManager
import android.content.BroadcastReceiver
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.database.Cursor
import android.util.Log
import androidx.core.net.toUri

class DownloadControlReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "HyperIsland[DownloadControlReceiver]"
        const val ACTION_CONTROL = "io.github.hyperisland.DOWNLOAD_CONTROL"
        const val EXTRA_ACTION = "action"
        const val EXTRA_DOWNLOAD_ID = "downloadId"
        const val EXTRA_FILE_NAME = "fileName"
        const val EXTRA_PACKAGE_NAME = "packageName"

        const val ACTION_PAUSE = "pause"
        const val ACTION_RESUME = "resume"
        const val ACTION_CANCEL = "cancel"

        private val DOWNLOADS_URI = "content://downloads/my_downloads".toUri()
        private val DOWNLOADS_URI_ALL = "content://downloads/all_downloads".toUri()
        private val PROVIDER_URIS = listOf(DOWNLOADS_URI_ALL, DOWNLOADS_URI)
    }

    override fun onReceive(context: Context?, intent: Intent?) {
        if (context == null || intent == null) return

        val intentAction = intent.action
        if (intentAction != null && intentAction != ACTION_CONTROL) {
            Log.w(TAG, "unexpected broadcast action=$intentAction expected=$ACTION_CONTROL")
        }

        val action = intent.getStringExtra(EXTRA_ACTION) ?: return
        val downloadId = intent.getLongExtra(EXTRA_DOWNLOAD_ID, -1L)
        val fileName = intent.getStringExtra(EXTRA_FILE_NAME) ?: "未知文件"
        val packageName = intent.getStringExtra(EXTRA_PACKAGE_NAME) ?: ""

        Log.d(
            TAG,
            "onReceive action=$action downloadId=$downloadId file=$fileName pkg=$packageName"
        )

        when (action) {
            ACTION_PAUSE -> handlePause(context, downloadId, fileName)
            ACTION_RESUME -> handleResume(context, downloadId, fileName)
            ACTION_CANCEL -> handleCancel(context, downloadId, fileName)
        }
    }

    private fun handlePause(context: Context, downloadId: Long, fileName: String) {
        try {
            if (downloadId > 0) {
                pauseDownloadViaReflection(context, downloadId)
            } else {
                pauseDownloadViaProvider(context, fileName)
            }
            Log.d(TAG, "pause sent for: $fileName")
        } catch (e: Exception) {
            Log.e(TAG, "pause error: ${e.message}")
        }
    }

    private fun handleResume(context: Context, downloadId: Long, fileName: String) {
        try {
            if (downloadId > 0) {
                resumeDownloadViaReflection(context, downloadId)
            } else {
                resumeDownloadViaProvider(context, fileName)
            }
            Log.d(TAG, "resume sent for: $fileName")
        } catch (e: Exception) {
            Log.e(TAG, "resume error: ${e.message}")
        }
    }

    private fun handleCancel(context: Context, downloadId: Long, fileName: String) {
        try {
            if (downloadId > 0) {
                val downloadManager =
                    context.getSystemService(Context.DOWNLOAD_SERVICE) as? DownloadManager
                downloadManager?.remove(downloadId)
                Log.d(TAG, "cancelled via DownloadManager: $downloadId")
            } else {
                cancelDownloadViaProvider(context, fileName)
            }
            Log.d(TAG, "cancel sent for: $fileName")
        } catch (e: Exception) {
            Log.e(TAG, "cancel error: ${e.message}")
        }
    }

    private fun pauseDownloadViaReflection(context: Context, downloadId: Long) {
        try {
            val downloadManager =
                context.getSystemService(Context.DOWNLOAD_SERVICE) as? DownloadManager
            val pauseMethod =
                downloadManager?.javaClass?.getDeclaredMethod("pause", Long::class.java)
            pauseMethod?.isAccessible = true
            pauseMethod?.invoke(downloadManager, downloadId)
            Log.d(TAG, "paused via reflection: $downloadId")
        } catch (e: Exception) {
            Log.e(TAG, "reflection pause failed: ${e.message}")
            pauseDownloadViaProvider(context, downloadId.toString())
        }
    }

    private fun resumeDownloadViaReflection(context: Context, downloadId: Long) {
        try {
            val downloadManager =
                context.getSystemService(Context.DOWNLOAD_SERVICE) as? DownloadManager
            val resumeMethod =
                downloadManager?.javaClass?.getDeclaredMethod("resume", Long::class.java)
            resumeMethod?.isAccessible = true
            resumeMethod?.invoke(downloadManager, downloadId)
            Log.d(TAG, "resumed via reflection: $downloadId")
        } catch (e: Exception) {
            Log.e(TAG, "reflection resume failed: ${e.message}")
            resumeDownloadViaProvider(context, downloadId.toString())
        }
    }

    private fun queryByIdOrTitle(
        context: Context,
        identifier: String,
        uri: android.net.Uri,
    ): Cursor? {
        return if (identifier.isNotEmpty() && identifier.toLongOrNull() != null) {
            context.contentResolver.query(
                uri,
                arrayOf("_id", "status"),
                "_id = ?",
                arrayOf(identifier),
                null
            )
        } else {
            context.contentResolver.query(
                uri,
                arrayOf("_id", "status"),
                "title LIKE ?",
                arrayOf("%$identifier%"),
                null
            )
        }
    }

    private fun pauseDownloadViaProvider(context: Context, identifier: String) {
        for (uri in PROVIDER_URIS) {
            try {
                val query = queryByIdOrTitle(context, identifier, uri)
                query?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val id = cursor.getLong(cursor.getColumnIndexOrThrow("_id"))
                        val values = ContentValues().apply {
                            put("status", DownloadManager.STATUS_PAUSED)
                            put("control", 1)
                        }
                        val updated = context.contentResolver.update(
                            uri.buildUpon().appendPath(id.toString()).build(),
                            values, null, null
                        )
                        if (updated > 0) {
                            Log.d(TAG, "paused via provider: $id (updated=$updated)")
                            return
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "provider pause failed (uri=$uri): ${e.message}")
            }
        }
    }

    private fun resumeDownloadViaProvider(context: Context, identifier: String) {
        for (uri in PROVIDER_URIS) {
            try {
                val query = queryByIdOrTitle(context, identifier, uri)
                query?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        val id = cursor.getLong(cursor.getColumnIndexOrThrow("_id"))
                        val values = ContentValues().apply {
                            put("status", DownloadManager.STATUS_RUNNING)
                            put("control", 0)
                        }
                        val updated = context.contentResolver.update(
                            uri.buildUpon().appendPath(id.toString()).build(),
                            values, null, null
                        )
                        if (updated > 0) {
                            Log.d(TAG, "resumed via provider: $id (updated=$updated)")
                            return
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "provider resume failed (uri=$uri): ${e.message}")
            }
        }
    }

    private fun cancelDownloadViaProvider(context: Context, fileName: String) {
        for (uri in PROVIDER_URIS) {
            try {
                val query = context.contentResolver.query(
                    uri, arrayOf("_id"), "title LIKE ?", arrayOf("%$fileName%"), null
                )
                query?.use { cursor ->
                    while (cursor.moveToNext()) {
                        val id = cursor.getLong(cursor.getColumnIndexOrThrow("_id"))
                        val deleted = context.contentResolver.delete(
                            uri.buildUpon().appendPath(id.toString()).build(), null, null
                        )
                        Log.d(TAG, "cancelled via provider: $id (deleted=$deleted)")
                    }
                }
                return
            } catch (e: Exception) {
                Log.e(TAG, "provider cancel failed (uri=$uri): ${e.message}")
            }
        }
    }
}
