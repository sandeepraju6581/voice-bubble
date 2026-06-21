package com.example.viocebubble

import android.accessibilityservice.AccessibilityService
import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.os.Bundle
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo

class VoiceBubbleAccessibilityService : AccessibilityService() {

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        // Not used, but must be overridden
    }

    override fun onInterrupt() {
        // Not used, but must be overridden
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
    }

    override fun onUnbind(intent: android.content.Intent?): Boolean {
        instance = null
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }

    companion object {
        var instance: VoiceBubbleAccessibilityService? = null

        fun injectText(context: Context, text: String): Boolean {
            val service = instance ?: return false
            
            var focusedNode: AccessibilityNodeInfo? = null

            // Strategy 1: Search focused node across all windows using findFocus
            try {
                focusedNode = service.findFocus(AccessibilityNodeInfo.FOCUS_INPUT)
            } catch (e: Exception) {
                android.util.Log.e("VoiceBubbleAccessibility", "findFocus failed: ${e.message}")
            }

            // Strategy 2: If findFocus fails, search the root node of the active window
            if (focusedNode == null) {
                try {
                    focusedNode = findFocusedNode(service.rootInActiveWindow)
                } catch (e: Exception) {
                    android.util.Log.e("VoiceBubbleAccessibility", "rootInActiveWindow lookup failed: ${e.message}")
                }
            }

            // Strategy 3: Search all interactive windows
            if (focusedNode == null) {
                try {
                    val windows = service.windows
                    if (windows != null) {
                        for (window in windows) {
                            val windowRoot = window.root ?: continue
                            focusedNode = findFocusedNode(windowRoot)
                            if (focusedNode != null) {
                                break
                            }
                        }
                    }
                } catch (e: Exception) {
                    android.util.Log.e("VoiceBubbleAccessibility", "windows iteration failed: ${e.message}")
                }
            }

            if (focusedNode == null) {
                android.util.Log.w("VoiceBubbleAccessibility", "No focused editable node found")
                return false
            }

            // Copy text to clipboard to prepare for paste
            val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            clipboard.setPrimaryClip(ClipData.newPlainText("voicebubble_inject", text))

            // Try pasting to insert at cursor position
            val pasteSuccess = focusedNode.performAction(AccessibilityNodeInfo.ACTION_PASTE)
            if (pasteSuccess) {
                focusedNode.recycle()
                return true
            }

            // Fallback: Replace/Set Text if paste action is not supported by the field
            val existingText = focusedNode.text?.toString() ?: ""
            val newText = if (existingText.isEmpty()) text else "$existingText $text"
            val arguments = Bundle().apply {
                putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, newText)
            }
            val setSuccess = focusedNode.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, arguments)
            focusedNode.recycle()
            return setSuccess
        }

        private fun findFocusedNode(node: AccessibilityNodeInfo?): AccessibilityNodeInfo? {
            if (node == null) return null
            if (node.isFocused && node.isEditable) {
                return node
            }
            for (i in 0 until node.childCount) {
                val child = node.getChild(i) ?: continue
                val focused = findFocusedNode(child)
                if (focused != null) {
                    return focused
                }
                child.recycle()
            }
            return null
        }
    }
}
