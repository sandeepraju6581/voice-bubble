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
            val rootNode = service.rootInActiveWindow ?: return false
            val focusedNode = findFocusedNode(rootNode) ?: return false

            // Copy text to clipboard to prepare for paste
            val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
            clipboard.setPrimaryClip(ClipData.newPlainText("voicebubble_inject", text))

            // Try pasting to insert at cursor position
            val pasteSuccess = focusedNode.performAction(AccessibilityNodeInfo.ACTION_PASTE)
            if (pasteSuccess) {
                return true
            }

            // Fallback: Replace/Set Text if paste action is not supported by the field
            val existingText = focusedNode.text?.toString() ?: ""
            val newText = if (existingText.isEmpty()) text else "$existingText $text"
            val arguments = Bundle().apply {
                putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, newText)
            }
            return focusedNode.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, arguments)
        }

        private fun findFocusedNode(node: AccessibilityNodeInfo?): AccessibilityNodeInfo? {
            if (node == null) return null
            if (node.isFocused && node.isEditable) {
                return node
            }
            for (i in 0 until node.childCount) {
                val child = node.getChild(i) ?: continue
                val focused = findFocusedNode(child)
                if (focused != null) return focused
            }
            return null
        }
    }
}
