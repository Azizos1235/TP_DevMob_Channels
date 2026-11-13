package tn.isetbizerte.tp3_channels

import android.content.Context
import android.media.AudioAttributes
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class Vibreur(context: Context) : MethodChannel.MethodCallHandler {

    private val vibrator: Vibrator =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            context.getSystemService(VibratorManager::class.java).defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Vibrator::class.java)
        }

    // Motif = [pause, vibration, pause, vibration, ...] en millisecondes
    private val motifs = mapOf(
        "court" to longArrayOf(0, 300),
        "long" to longArrayOf(0, 1000),
        "sos" to longArrayOf(0, 100, 100, 100, 100, 100, 300, 400, 100, 400, 100, 400,
            300, 100, 100, 100, 100, 100),
        "disco" to longArrayOf(0, 100, 50, 100, 50, 300, 50, 100, 50, 300)
    )

    private val attributs = AudioAttributes.Builder()
        .setUsage(AudioAttributes.USAGE_ALARM)
        .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
        .build()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "vibrer" -> {
                val nom = call.argument<String>("motif")
                val motif = motifs[nom]
                if (motif == null) {
                    result.error("MOTIF_INCONNU", "Motif « $nom » inconnu. Choix : ${motifs.keys}", null)
                    return
                }
                if (!vibrator.hasVibrator()) {
                    result.error("PAS_DE_VIBREUR", "Cet appareil ne peut pas vibrer", null)
                    return
                }
                try {
                    val effet = VibrationEffect.createWaveform(motif, -1)
                    @Suppress("DEPRECATION")
                    vibrator.vibrate(effet, attributs)
                    result.success(null)
                } catch (e: SecurityException) {
                    result.error("PERMISSION", "Permission VIBRATE manquante", null)
                }
            }
            else -> result.notImplemented()
        }
    }
}