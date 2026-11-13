import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'native/canaux.dart';

void main() => runApp(const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PageCanaux(),
    ));

class PageCanaux extends StatefulWidget {
  const PageCanaux({super.key});

  @override
  State<PageCanaux> createState() => _PageCanauxState();
}

class _PageCanauxState extends State<PageCanaux> {
  // ───────── Étape 1 : infos appareil ─────────
  String _infos = 'Appuyez sur le bouton';

  Future<void> _lireInfos() async {
    final i = await CanauxNatifs.lireInfos();
    setState(() => _infos =
        '${i['marque']} ${i['modele']}\nAndroid ${i['version']} (API ${i['sdk']})');
  }

  // ───────── Étape 2 : vibration ─────────
  Future<void> _vibrer(String motif) async {
    try {
      await CanauxNatifs.vibrer(motif);
      _message('Vibration « $motif »');
    } on PlatformException catch (e) {
      _message('Erreur ${e.code} : ${e.message}');
    }
  }

  // ───────── Exercice 2 : lampe torche ─────────
  bool _torcheAllumee = false;

  Future<void> _basculerTorche(bool etat) async {
    try {
      await CanauxNatifs.allumerTorche(etat);
      setState(() => _torcheAllumee = etat);
    } on PlatformException catch (e) {
      // Le Switch reste dans son état précédent
      _message('Erreur ${e.code} : ${e.message}');
    }
  }

  // ───────── Étape 3 : capteur de lumière ─────────
  double? _lux;
  StreamSubscription<double>? _abonnementLumiere;

  void _basculerLumiere() {
    if (_abonnementLumiere == null) {
      _abonnementLumiere = CanauxNatifs.lumiere().listen(
        (lux) => setState(() => _lux = lux),
        onError: (e) => _message('Capteur : ${(e as PlatformException).message}'),
      );
    } else {
      _abonnementLumiere!.cancel();
      _abonnementLumiere = null;
    }
    setState(() {});
  }

  // ───────── Étape 4 : niveau sonore ─────────
  double? _db;
  StreamSubscription<double>? _abonnementAudio;

  Future<void> _basculerMicro() async {
    if (_abonnementAudio != null) {
      await _abonnementAudio!.cancel();
      setState(() => _abonnementAudio = null);
      return;
    }
    final accordee = await CanauxNatifs.demanderMicro();
    if (!accordee) {
      _message('Permission micro refusée');
      return;
    }
    setState(() {
      _abonnementAudio = CanauxNatifs.niveauSonore().listen(
        (db) => setState(() => _db = db),
        onError: (e) => _message('Micro : ${(e as PlatformException).message}'),
      );
    });
  }

  // ───────── Exercice 1 : capteur de proximité ─────────
  bool? _proche;
  StreamSubscription<bool>? _abonnementProximite;

  void _basculerProximite() {
    if (_abonnementProximite == null) {
      _abonnementProximite = CanauxNatifs.proximite().listen(
        (proche) => setState(() => _proche = proche),
        onError: (e) {
          if (e is PlatformException) {
            _message('Proximité : ${e.message}');
          } else {
            _message('Proximité : $e');
          }
        },
      );
    } else {
      _abonnementProximite!.cancel();
      _abonnementProximite = null;
      _proche = null;
    }
    setState(() {});
  }

  // ───────── Nettoyage ─────────
  @override
  void dispose() {
    _abonnementLumiere?.cancel();
    _abonnementAudio?.cancel();
    _abonnementProximite?.cancel();
    // Éteint la torche si on quitte la page alors qu'elle est allumée
    if (_torcheAllumee) {
      CanauxNatifs.allumerTorche(false).catchError((_) {});
    }
    super.dispose();
  }

  // ───────── Utilitaires UI ─────────
  void _message(String texte) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(texte)));

  Widget _carte(String titre, List<Widget> contenu) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titre, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              ...contenu,
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('TP 3 – Platform Channels')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _carte('1. Infos appareil (MethodChannel)', [
            Text(_infos),
            const SizedBox(height: 8),
            FilledButton(onPressed: _lireInfos, child: const Text('Lire')),
          ]),
          _carte('2. Vibration (arguments + erreurs)', [
            Wrap(spacing: 8, children: [
              for (final m in ['court', 'long', 'sos', 'disco'])
                OutlinedButton(onPressed: () => _vibrer(m), child: Text(m)),
            ]),
          ]),
          _carte('3. Capteur de lumière (EventChannel)', [
            Text(_lux == null ? '—' : '${_lux!.toStringAsFixed(0)} lux',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _basculerLumiere,
              child: Text(_abonnementLumiere == null ? 'Démarrer' : 'Arrêter'),
            ),
          ]),
          _carte('4. Niveau sonore (permission + coroutine)', [
            Text(_db == null ? '—' : '${_db!.toStringAsFixed(1)} dBFS',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            LinearProgressIndicator(
                value: (((_db ?? -90) + 90) / 90).clamp(0.0, 1.0)),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _basculerMicro,
              child: Text(_abonnementAudio == null ? 'Écouter' : 'Arrêter'),
            ),
          ]),
          _carte('5. Capteur de proximité (EventChannel)', [
            Row(
              children: [
                Icon(
                  _proche == true ? Icons.pets : Icons.panorama_fish_eye,
                  color: _proche == true ? Colors.green : Colors.grey,
                  size: 36,
                ),
                const SizedBox(width: 12),
                Text(
                  _proche == null ? '—' : (_proche! ? 'Proche' : 'Loin'),
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _basculerProximite,
              child: Text(_abonnementProximite == null ? 'Démarrer' : 'Arrêter'),
            ),
          ]),
          _carte('6. Lampe torche (MethodChannel + argument)', [
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_torcheAllumee ? 'Allumée' : 'Éteinte'),
              secondary: Icon(
                _torcheAllumee ? Icons.flashlight_on : Icons.flashlight_off,
                color: _torcheAllumee ? Colors.amber : Colors.grey,
              ),
              value: _torcheAllumee,
              onChanged: _basculerTorche,
            ),
          ]),
        ],
      ),
    );
  }
}