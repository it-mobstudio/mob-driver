package com.madoverbuildings.mobileapp

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.provider.ContactsContract
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result

class MainActivity: FlutterActivity() {
    private val contactPickerChannel = "m_o_b_demand_side/contact_picker"
    private val pickPhoneContactRequestCode = 7301
    private var pendingContactResult: Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            contactPickerChannel
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickPhoneContact" -> pickPhoneContact(result)
                else -> result.notImplemented()
            }
        }
    }

    private fun pickPhoneContact(result: Result) {
        if (pendingContactResult != null) {
            result.error("IN_PROGRESS", "Contact picker is already open.", null)
            return
        }

        val intent = Intent(
            Intent.ACTION_PICK,
            ContactsContract.CommonDataKinds.Phone.CONTENT_URI
        )
        pendingContactResult = result
        try {
            startActivityForResult(intent, pickPhoneContactRequestCode)
        } catch (_: ActivityNotFoundException) {
            pendingContactResult = null
            result.error("UNAVAILABLE", "No contacts app is available.", null)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode == pickPhoneContactRequestCode) {
            val result = pendingContactResult
            pendingContactResult = null
            if (result == null) return

            if (resultCode != Activity.RESULT_OK || data?.data == null) {
                result.error("CANCELLED", "Contact selection cancelled.", null)
                return
            }

            val uri = data.data
            if (uri == null) {
                result.error("UNAVAILABLE", "No contact was selected.", null)
                return
            }

            contentResolver.query(
                uri,
                arrayOf(
                    ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME,
                    ContactsContract.CommonDataKinds.Phone.NUMBER
                ),
                null,
                null,
                null
            )?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val nameIndex = cursor.getColumnIndex(
                        ContactsContract.CommonDataKinds.Phone.DISPLAY_NAME
                    )
                    val phoneIndex = cursor.getColumnIndex(
                        ContactsContract.CommonDataKinds.Phone.NUMBER
                    )
                    result.success(
                        mapOf(
                            "name" to if (nameIndex >= 0) {
                                cursor.getString(nameIndex) ?: ""
                            } else {
                                ""
                            },
                            "phone" to if (phoneIndex >= 0) {
                                cursor.getString(phoneIndex) ?: ""
                            } else {
                                ""
                            }
                        )
                    )
                } else {
                    result.error("UNAVAILABLE", "Unable to read selected contact.", null)
                }
            } ?: result.error("UNAVAILABLE", "Unable to read selected contact.", null)
            return
        }

        super.onActivityResult(requestCode, resultCode, data)
    }
}
