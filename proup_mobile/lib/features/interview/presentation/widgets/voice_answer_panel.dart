import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/interview_repository.dart';
import '../interview_timing.dart';

enum _VoiceState { idle, recording, transcribing, done, error }

/// Por debajo de este nivel (dBFS) durante TODA la grabación se considera silencio.
const silenceThresholdDb = -45.0;

/// Respuesta oral de una pregunta: grabar → detener → (escuchar / volver a grabar)
/// → transcripción que el usuario revisa en el campo de texto.
/// El audio se guarda solo temporalmente en el teléfono, se envía únicamente para
/// transcribirlo (el servidor no lo guarda) y se borra al salir de la pregunta.
class VoiceAnswerPanel extends StatefulWidget {
  const VoiceAnswerPanel({
    super.key,
    required this.limitSeconds,
    required this.isPitch,
    required this.hasTranscript,
    required this.onTranscribed,
    this.onRecordingChanged,
  });

  final int limitSeconds;
  final bool isPitch;

  /// Si ya hay una transcripción de esta pregunta (para confirmar antes de regrabar).
  final bool hasTranscript;
  final void Function(String text, int seconds) onTranscribed;
  final void Function(bool recording)? onRecordingChanged;

  @override
  State<VoiceAnswerPanel> createState() => _VoiceAnswerPanelState();
}

class _VoiceAnswerPanelState extends State<VoiceAnswerPanel> {
  final _recorder = AudioRecorder();
  final _player = AudioPlayer();
  Timer? _ticker;
  StreamSubscription<Amplitude>? _levelSub;
  double _levelDb = -60; // nivel actual del micrófono (dBFS)
  double _peakDb = -160; // nivel máximo de la grabación
  _VoiceState _state = _VoiceState.idle;
  String? _path;
  int _seconds = 0;
  bool _playing = false;
  bool _autoStopped = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.hasTranscript) _state = _VoiceState.done;
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playing = false);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _levelSub?.cancel();
    _recorder.stop().catchError((_) => null).whenComplete(_recorder.dispose);
    _player.dispose();
    _deleteAudio();
    super.dispose();
  }

  void _deleteAudio() {
    final p = _path;
    if (p != null) File(p).delete().catchError((_) => File(p));
  }

  Future<void> _start() async {
    if (widget.hasTranscript || _state == _VoiceState.done) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('¿Volver a grabar?'),
          content: const Text('Se reemplazarán tu grabación y la transcripción de esta pregunta.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Volver a grabar')),
          ],
        ),
      );
      if (ok != true) return;
    }
    if (!await _recorder.hasPermission()) {
      setState(() {
        _state = _VoiceState.error;
        _error = 'ProUp necesita permiso para usar el micrófono. Actívalo en los ajustes del teléfono o responde por escrito.';
      });
      return;
    }
    await _player.stop();
    _deleteAudio();
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/proup_respuesta_${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, sampleRate: 16000, numChannels: 1, bitRate: 64000),
      path: path,
    );
    _peakDb = -160;
    _levelSub = _recorder.onAmplitudeChanged(const Duration(milliseconds: 250)).listen((a) {
      if (!mounted) return;
      setState(() {
        _levelDb = a.current;
        if (a.current > _peakDb) _peakDb = a.current;
      });
    });
    setState(() {
      _path = path;
      _seconds = 0;
      _autoStopped = false;
      _error = null;
      _state = _VoiceState.recording;
    });
    widget.onRecordingChanged?.call(true);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds++);
      if (shouldAutoStop(isPitch: widget.isPitch, used: _seconds, limit: widget.limitSeconds)) {
        _autoStopped = true;
        _stop();
      }
    });
  }

  Future<void> _stop() async {
    _ticker?.cancel();
    await _levelSub?.cancel();
    _levelSub = null;
    final path = await _recorder.stop();
    widget.onRecordingChanged?.call(false);
    if (!mounted) return;
    // Silencio: no se envía (Whisper inventa texto como "Gracias." cuando no hay voz)
    if (_peakDb < silenceThresholdDb) {
      setState(() {
        _path = path;
        _state = _VoiceState.error;
        _error = 'No detectamos tu voz en la grabación. Revisa que el micrófono no esté silenciado o cubierto y vuelve a grabar.';
      });
      return;
    }
    if (path == null || _seconds < 2) {
      setState(() {
        _state = _VoiceState.error;
        _error = 'La grabación fue muy corta. Graba tu respuesta completa y luego pulsa "Detener".';
      });
      return;
    }
    _path = path;
    await _transcribe();
  }

  Future<void> _transcribe() async {
    final path = _path;
    if (path == null) return;
    setState(() {
      _state = _VoiceState.transcribing;
      _error = null;
    });
    try {
      final t = await getIt<InterviewRepository>().transcribe(path);
      if (!mounted) return;
      widget.onTranscribed(t.text, t.durationSeconds ?? _seconds);
      setState(() => _state = _VoiceState.done);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _state = _VoiceState.error;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _state = _VoiceState.error;
        _error = 'No pudimos transcribir tu respuesta. Reintenta o responde por escrito.';
      });
    }
  }

  Future<void> _togglePlay() async {
    final p = _path;
    if (p == null) return;
    if (_playing) {
      await _player.stop();
      setState(() => _playing = false);
    } else {
      await _player.play(DeviceFileSource(p));
      setState(() => _playing = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = timeState(_seconds, widget.limitSeconds);
    final timerColor = switch (state) {
      TimeState.onTrack => AppColors.primary,
      TimeState.closeToLimit => AppColors.scoreMid,
      TimeState.overLimit => AppColors.error,
    };
    final canReplay = _path != null && File(_path!).existsSync();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: _state == _VoiceState.recording ? AppColors.error : AppColors.surfaceContainer, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_state == _VoiceState.recording) ...[
            Row(
              children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                const Text('Grabando…', style: TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(timerLabel(_seconds, widget.limitSeconds),
                    style: TextStyle(color: timerColor, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (_seconds / widget.limitSeconds).clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: AppColors.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation(timerColor),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.graphic_eq, size: 18, color: _levelDb > silenceThresholdDb ? AppColors.tertiary : AppColors.outline),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: ((_levelDb + 60) / 60).clamp(0.0, 1.0),
                      minHeight: 6,
                      backgroundColor: AppColors.surfaceContainerHigh,
                      valueColor: const AlwaysStoppedAnimation(AppColors.tertiary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(_levelDb > silenceThresholdDb ? 'Te escuchamos' : 'Habla más cerca',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            if (widget.isPitch) ...[
              const SizedBox(height: 6),
              Text('La grabación se detiene sola a los ${widget.limitSeconds} s.',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _stop,
              icon: const Icon(Icons.stop_circle_outlined),
              label: const Text('Detener grabación'),
              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            ),
          ] else if (_state == _VoiceState.transcribing) ...[
            const Row(
              children: [
                SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4)),
                SizedBox(width: 12),
                Expanded(child: Text('Convirtiendo tu voz en texto…')),
              ],
            ),
          ] else ...[
            if (_state == _VoiceState.done)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _autoStopped
                      ? 'Se cumplieron los ${widget.limitSeconds} s y la grabación se detuvo. Revisa la transcripción abajo.'
                      : 'Listo. Revisa la transcripción abajo y corrige lo que no se haya reconocido bien.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (_state == _VoiceState.error && _error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.mic),
                  label: Text(_state == _VoiceState.idle ? 'Grabar respuesta' : 'Volver a grabar'),
                ),
                if (canReplay && _state != _VoiceState.idle)
                  OutlinedButton.icon(
                    onPressed: _togglePlay,
                    icon: Icon(_playing ? Icons.stop : Icons.play_arrow),
                    label: Text(_playing ? 'Detener' : 'Escuchar mi grabación'),
                  ),
                if (_state == _VoiceState.error && canReplay)
                  OutlinedButton.icon(
                    onPressed: _transcribe,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar transcripción'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
