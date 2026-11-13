package tn.isetbizerte.tp3_channels

import android.content.Context
import android.hardware.camera2.CameraAccessException
import android.hardware.camera2.CameraCharacteristics
import android.hardware.camera2.CameraManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class Torche(context: Context) : MethodChannel.MethodCallHandler {

    private val gestionnaire =
        context.getSystemService(Context.CAMERA_SERVICE) as CameraManager

    // Identifiant de la première caméra qui possède un flash (null si aucune)
    private val idCameraAvecFlash: String? = try {
        gestionnaire.cameraIdList.firstOrNull { id ->
            gestionnaire.getCameraCharacteristics(id)
                .get(CameraCharacteristics.FLASH_INFO_AVAILABLE) == true
        }
    } catch (e: CameraAccessException) {
        null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "allumer" -> {
                val etat = call.argument<Boolean>("etat")       // paramètre envoyé par Dart
                if (etat == null) {
                    result.error("ARGUMENT", "Le paramètre « etat » (booléen) est manquant", null)
                    return
                }
                if (idCameraAvecFlash == null) {
                    result.error("PAS_DE_FLASH", "Cet appareil n'a pas de flash", null)
                    return
                }
                try {
                    gestionnaire.setTorchMode(idCameraAvecFlash, etat)
                    result.success(null)
                } catch (e: CameraAccessException) {
                    result.error("CAMERA_INDISPONIBLE", "Caméra inaccessible : ${e.message}", null)
                } catch (e: IllegalArgumentException) {
                    result.error("PAS_DE_FLASH", "Identifiant de caméra invalide : ${e.message}", null)
                }
            }
            else -> result.notImplemented()
        }
    }
}