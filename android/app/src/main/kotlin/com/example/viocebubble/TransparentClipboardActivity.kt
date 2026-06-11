package com.example.viocebubble

import android.app.Activity
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.os.Bundle

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
                    // Fail silently to prevent background overlay crash
                }
            }
            // Close with no exit animation
            overridePendingTransition(0, 0)
            finish()
        }
    }
}
