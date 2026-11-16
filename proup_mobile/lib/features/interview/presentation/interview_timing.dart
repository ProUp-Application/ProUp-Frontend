// Reglas del temporizador del simulador (sin dependencias de Flutter, para tests).

/// "1:05" a partir de segundos.
String formatClock(int seconds) {
  final s = seconds.abs();
  return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}

enum TimeState { onTrack, closeToLimit, overLimit }

/// Estado del tiempo usado frente al tiempo de referencia.
TimeState timeState(int used, int limit) {
  if (used > limit) return TimeState.overLimit;
  if (limit - used <= (limit * 0.2).round()) return TimeState.closeToLimit;
  return TimeState.onTrack;
}

/// Texto del temporizador: tiempo restante o exceso sobre la referencia.
String timerLabel(int used, int limit) {
  if (used <= limit) return 'Quedan ${formatClock(limit - used)} de ${formatClock(limit)}';
  return '+${formatClock(used - limit)} sobre ${formatClock(limit)}';
}

/// En el Elevator Pitch la grabación se detiene sola al llegar a los 60 s.
bool shouldAutoStop({required bool isPitch, required int used, required int limit}) =>
    isPitch && used >= limit;
