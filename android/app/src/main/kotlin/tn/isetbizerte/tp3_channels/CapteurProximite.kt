package tn.isetbizerte.tp3_channels

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import io.flutter.plugin.common.EventChannel

class CapteurProximite(context: Context) : EventChannel.StreamHandler {

    private val gestionnaire =
        context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val capteur: Sensor? = gestionnaire.getDefaultSensor(Sensor.TYPE_PROXIMITY)
    private var ecouteur: SensorEventListener? = null

    // Dart commence à écouter le flux
    override fun onListen(arguments: Any?, events: EventChannel.EventSink) {
        if (capteur == null) {
            events.error("PAS_DE_CAPTEUR", "Cet appareil n'a pas de capteur de proximité", null)
            return
        }

        ecouteur = object : SensorEventListener {
            override fun onSensorChanged(event: SensorEvent) {
                // Proche si la distance mesurée est inférieure à la portée maximale
                val proche = event.values[0] < capteur.maximumRange
                events.success(proche)
            }

            override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}
        }
        gestionnaire.registerListener(ecouteur, capteur, SensorManager.SENSOR_DELAY_NORMAL)
    }

    // Dart arrête d'écouter : on libère le capteur (économie de batterie)
    override fun onCancel(arguments: Any?) {
        ecouteur?.let { gestionnaire.unregisterListener(it) }
        ecouteur = null
    }
}