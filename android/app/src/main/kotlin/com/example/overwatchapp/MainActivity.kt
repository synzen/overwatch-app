package com.synzen.overwatch

import android.Manifest
import android.app.Activity
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothHeadset
import android.bluetooth.BluetoothManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.media.AudioDeviceInfo
import android.media.AudioManager
import android.os.BatteryManager
import android.os.Build
import android.os.Build.VERSION
import android.os.Build.VERSION_CODES
import androidx.activity.result.ActivityResultCallback
import androidx.activity.result.contract.ActivityResultContract
import androidx.activity.result.contract.ActivityResultContracts
import androidx.core.app.ActivityCompat
import androidx.core.app.ComponentActivity
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import com.example.overwatchapp.LocationPermission
import io.flutter.embedding.android.FlutterFragmentActivity
import org.json.JSONObject

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL = "com.synzen.overwatch"
    private val CHANNEL_ID = "transit-arrivals"

    fun <I, O> Activity.registerForActivityResult(
        contract: ActivityResultContract<I, O>,
        callback: ActivityResultCallback<O>
    ) = (this as androidx.activity.ComponentActivity).registerForActivityResult(contract, callback)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "sendNotification") {
//                val title = call.argument<String>("title")
//                val description = call.argument<String>("description")
//
//                if (title.isNullOrBlank() || description.isNullOrBlank()) {
//                    result.error("", "Missing title or description", null)
//
//                    return@setMethodCallHandler
//                }
//
//                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU && ActivityCompat.checkSelfPermission(this@MainActivity, Manifest.permission.POST_NOTIFICATIONS) != PackageManager.PERMISSION_GRANTED) {
//                    ActivityCompat.requestPermissions(this,  arrayOf(Manifest.permission.POST_NOTIFICATIONS), 0)
//                    result.error("", "Missing permissions", null)
//
//                    return@setMethodCallHandler
//                }
//
//                val intent = PendingIntent.getActivity(this, 0, Intent().apply {
//                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TASK
//                }, PendingIntent.FLAG_IMMUTABLE)
//                val notification = NotificationCompat.Builder(this, CHANNEL_ID)
//                    .setSmallIcon(R.drawable.launch_background)
//                    .setContentTitle(title)
//                    .setContentText(description)
//                    .setPriority(NotificationCompat.PRIORITY_DEFAULT)
//                    .setContentIntent(intent)
//                    .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
//                    .setAutoCancel(false)
//
//
//                NotificationManagerCompat.from(this).notify(123, notification.build())


//                val request = registerForActivityResult(ActivityResultContracts.RequestMultiplePermissions()) {
//                        permissions ->
//                    val accessFineLocation = permissions[Manifest.permission.ACCESS_FINE_LOCATION]
//                    val accessCoarseLocation = permissions[Manifest.permission.ACCESS_COARSE_LOCATION]
//
//                    if (accessFineLocation == true) {
//                        println("Fine location granted")
//                    } else if (accessCoarseLocation == true) {
//                        println("Coarse location granted")
//                    } else {
//                        println("No perm granted")
//                    }
//                }
//
//                request.launch(arrayOf(
//                    Manifest.permission.ACCESS_FINE_LOCATION
//                ))
            } else if (call.method == "initialize") {
                try {
                    this.createNotificationChannel()
//                    startActivityForResult()
                } catch (err: Error) {
                    result.error("", "Failed to create notification channel: ${err.message}", null)
                }
                result.success(1);
            } else if (call.method == "checkHeadphones") {
                try {
                    val map = hashMapOf<String, Any>()
                    map["pluggedIn"] = areHeadphonesPluggedIn();

                    result.success(map);
                } catch (err: Error) {
                    result.error("", "Failed to check headphones state: ${err.message}", null);
                }
            } else  {
                result.notImplemented()
            }
        }
    }

    private fun createNotificationChannel() {
        // Create the NotificationChannel, but only on API 26+ because
        // the NotificationChannel class is not in the Support Library.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val importance = NotificationManager.IMPORTANCE_HIGH
            val channel = NotificationChannel(CHANNEL_ID, "Alerts", importance).apply {
                description = "Alerting for transit arrivals"
            }
            channel.enableVibration(true)
            // Register the channel with the system.
            val notificationManager: NotificationManager =
                getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun areHeadphonesPluggedIn(): Boolean {
        // min sdk: 21
        val manager = getSystemService(Context.AUDIO_SERVICE) as AudioManager;

        if (Build.VERSION.SDK_INT >= 23) {
            val devices = manager.getDevices(AudioManager.GET_DEVICES_INPUTS);

            val isConnected = devices.any { d ->
                val isUsbHeadset = Build.VERSION.SDK_INT >= 26 && d.type == AudioDeviceInfo.TYPE_USB_HEADSET
                val isBleHeadset = Build.VERSION.SDK_INT >= 31 && d.type == AudioDeviceInfo.TYPE_BLE_HEADSET
                val isHearingAid = Build.VERSION.SDK_INT >= 28 && d.type == AudioDeviceInfo.TYPE_HEARING_AID
                val isWiredHeadset =d.type == AudioDeviceInfo.TYPE_WIRED_HEADSET;
                val isWiredHeadphones = d.type == AudioDeviceInfo.TYPE_WIRED_HEADPHONES;
                val isBluetoothSco = d.type == AudioDeviceInfo.TYPE_BLUETOOTH_SCO;
                val isBluetoothA2dp = d.type == AudioDeviceInfo.TYPE_BLUETOOTH_A2DP;

                val isBluetooth = isBluetoothSco || isBluetoothA2dp || isBleHeadset

                if (isBluetooth && !isBluetoothConnected()) {
                    return@any false
                }


                return@any isWiredHeadset || isWiredHeadphones || isBluetoothSco || isBluetoothA2dp || isUsbHeadset || isBleHeadset || isHearingAid
            }

            return isConnected
        }

        return false;
    }

    private fun isBluetoothConnected(): Boolean {
        if (Build.VERSION.SDK_INT >= 31 && ActivityCompat.checkSelfPermission(
                this@MainActivity,
                Manifest.permission.BLUETOOTH_CONNECT
            ) != PackageManager.PERMISSION_GRANTED) {

                ActivityCompat.requestPermissions(
                    this,
                    arrayOf(Manifest.permission.BLUETOOTH_CONNECT),
                    0
                )
                println("bluetooth connect permission check - denied")

                return false

        } else if (ActivityCompat.checkSelfPermission(
            this@MainActivity,
            Manifest.permission.BLUETOOTH
        ) != PackageManager.PERMISSION_GRANTED) {
            ActivityCompat.requestPermissions(
                this,
                arrayOf(Manifest.permission.BLUETOOTH),
                0
            )
            println("bluetooth permission check - denied")

            return false
        }

        val bluetoothAdapter = (getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager).adapter;
        return bluetoothAdapter.isEnabled && bluetoothAdapter.getProfileConnectionState(BluetoothHeadset.HEADSET) == BluetoothAdapter.STATE_CONNECTED
    }
}
