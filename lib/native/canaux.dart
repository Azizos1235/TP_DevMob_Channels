import 'package:flutter/services.dart';

class CanauxNatifs {
  // Les noms doivent être identiques à ceux de MainActivity.kt
  static const _infos = MethodChannel('appareil/infos');
  static const _vibreur = MethodChannel('appareil/vibrer');
  static const _torche = MethodChannel('appareil/torche');
  static const _lumiere = EventChannel('capteur/lumiere');
  static const _proximite = EventChannel('capteur/proximite');
  static const _permission = MethodChannel('audio/permission');
  static const _niveau = EventChannel('audio/niveau');

  static Future<Map<String, dynamic>> lireInfos() async {
    final r = await _infos.invokeMapMethod<String, dynamic>('lire');
    return r ?? {};
  }

  static Future<void> vibrer(String motif) =>
      _vibreur.invokeMethod('vibrer', {'motif': motif});

  // Exercice 2 : lampe torche (true = allumée, false = éteinte)
  static Future<void> allumerTorche(bool etat) =>
      _torche.invokeMethod('allumer', {'etat': etat});

  static Stream<double> lumiere() =>
      _lumiere.receiveBroadcastStream().map((e) => (e as num).toDouble());

  static Stream<bool> proximite() =>
      _proximite.receiveBroadcastStream().map((e) => e as bool);

  static Future<bool> demanderMicro() async =>
      (await _permission.invokeMethod<bool>('demander')) ?? false;

  static Stream<double> niveauSonore() =>
      _niveau.receiveBroadcastStream().map((e) => (e as num).toDouble());
}