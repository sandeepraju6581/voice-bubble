package com.example.viocebubble

import android.app.Activity
import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.net.Uri
import android.os.Bundle
import androidx.core.content.FileProvider
import java.io.File

class TransparentClipboardActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // No visual UI content, transparent theme is configured in manifest
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) {
            val textToCopy = intent.getStringExtra("text")
            if (textToCopy != null) {
                try {
                    val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                    val clip = ClipData.newPlainText("voicebubble_copy", textToCopy)
                    clipboard.setPrimaryClip(clip)
                } catch (e: Exception) {
                    android.util.Log.e("VoiceBubble", "Error copying text to clipboard", e)
                }
            }

            val filesToCopy = intent.getStringArrayListExtra("files")
            if (filesToCopy != null) {
                try {
                    val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                    val mimeTypes = HashSet<String>()
                    val items = ArrayList<ClipData.Item>()
                    val authority = "$packageName.fileprovider"

                    for (path in filesToCopy) {
                        val file = File(path)
                        if (file.exists()) {
                            val uri = FileProvider.getUriForFile(this, authority, file)
                            val mime = contentResolver.getType(uri) ?: "image/jpeg"
                            mimeTypes.add(mime)
                            // Set only the Uri to avoid pasting the filename text
                            items.add(ClipData.Item(uri))
                        }
                    }

                    if (items.isNotEmpty()) {
                        val clipDescription = ClipDescription("Images", mimeTypes.toTypedArray())
                        val clip = ClipData(clipDescription, items[0])
                        for (i in 1 until items.size) {
                            clip.addItem(items[i])
                        }
                        clipboard.setPrimaryClip(clip)
                    }
                } catch (e: Exception) {
                    android.util.Log.e("VoiceBubble", "Error copying files to clipboard", e)
                }
            }

            // Close with no exit animation
            overridePendingTransition(0, 0)
            finish()
        }
    }
}
