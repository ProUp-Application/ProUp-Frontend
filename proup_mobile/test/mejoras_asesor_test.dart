import 'package:flutter_test/flutter_test.dart';
import 'package:proup_mobile/features/analysis/data/models/analysis_models.dart';
import 'package:proup_mobile/features/analysis/presentation/ondevice/vision_types.dart';
import 'package:proup_mobile/features/auth/password_policy.dart';
import 'package:proup_mobile/features/cv/data/cv_models.dart';
import 'package:proup_mobile/features/interview/data/models/interview_models.dart';
import 'package:proup_mobile/features/interview/presentation/interview_timing.dart';

void main() {
  group('REG-01/02 · Política de contraseña (igual que el backend)', () {
    test('una contraseña válida no tiene requisitos pendientes', () {
      expect(missingPasswordRules('Segura2026'), isEmpty);
      expect(validatePassword('Segura2026'), isNull);
    });
    test('indica exactamente lo que falta', () {
      expect(missingPasswordRules('segura'), ['Al menos 8 caracteres', 'Una letra mayúscula', 'Un número']);
      expect(validatePassword('SEGURA2026'), contains('minúscula'));
    });
    test('REG-03 · mensajes claros para correo y nombre', () {
      expect(validateEmail('correo-sin-arroba'), contains('correo válido'));
      expect(validateEmail('ana@correo.com'), isNull);
      expect(validateName('', 'nombre'), 'Ingresa tu nombre');
      expect(validateName('Ana2', 'nombre'), contains('números'));
    });
  });

  group('ENT-05/06/07 · Temporizador', () {
    test('formato y texto del tiempo restante o excedido', () {
      expect(formatClock(65), '1:05');
      expect(timerLabel(20, 60), 'Quedan 0:40 de 1:00');
      expect(timerLabel(75, 60), '+0:15 sobre 1:00');
    });
    test('estado del tiempo', () {
      expect(timeState(10, 60), TimeState.onTrack);
      expect(timeState(50, 60), TimeState.closeToLimit);
      expect(timeState(61, 60), TimeState.overLimit);
    });
    test('el Elevator Pitch se corta a los 60 s; las demás preguntas no', () {
      expect(shouldAutoStop(isPitch: true, used: 60, limit: 60), isTrue);
      expect(shouldAutoStop(isPitch: false, used: 200, limit: 120), isFalse);
    });
    test('la retroalimentación por pregunta se lee del backend', () {
      final sim = InterviewSimulationModel.fromJson({
        'id': 's1',
        'overallScore': 62,
        'questionFeedback': [
          {'index': 1, 'question': 'Preséntate', 'score': 85, 'feedback': 'Buen gancho', 'durationSeconds': 24, 'timeLimitSeconds': 60, 'mode': 'VOICE'},
          {'index': 2, 'question': 'Convence', 'score': 40, 'feedback': 'Breve', 'timeNote': 'Duró 82 s', 'durationSeconds': 82, 'timeLimitSeconds': 60, 'mode': 'TEXT'},
        ],
      });
      expect(sim.questionFeedback.length, 2);
      expect(sim.questionFeedback.first.isVoice, isTrue);
      expect(sim.questionFeedback[1].timeNote, 'Duró 82 s');
    });
    test('el inicio de un pitch trae el límite de 60 s', () {
      final start = InterviewStart.fromJson({'id': 'x', 'track': 'Elevator Pitch', 'questions': ['a'], 'timeLimitSeconds': 60});
      expect(start.timeLimitSeconds, 60);
    });
  });

  group('IMG / PRO · Modelos', () {
    test('un análisis de primer plano trae vestimenta y postura sin evaluar', () {
      final r = AnalysisResultModel.fromJson({
        'id': 'r1',
        'faceScore': 80,
        'clothingScore': null,
        'postureScore': null,
        'contextScore': 90,
        'overallScore': 84,
        'frameType': 'PRIMER_PLANO',
        'assessment': {
          'evaluated': [
            {'category': 'face', 'evidence': ['Sonrisa leve']},
          ],
          'notEvaluated': [
            {'category': 'posture', 'reason': 'Es un primer plano'},
          ],
        },
      });
      expect(r.frameType, FrameType.primerPlano);
      expect(r.scoreOf('posture'), isNull);
      expect(r.assessment!.notEvaluated['posture'], 'Es un primer plano');
    });

    test('PRO-01 · los indicadores personales y de la comunidad van separados', () {
      final s = ProgressStats.fromJson({
        'personal': {'analyses': 2, 'latest': 67, 'average': 76, 'best': 84},
        'community': {'users': 3, 'average': null, 'minUsers': 5, 'description': 'Promedio…'},
      });
      expect(s.latest, 67);
      expect(s.communityAverage, isNull, reason: 'con menos de 5 usuarios no se publica');
    });
  });

  group('ASE · CV editable', () {
    test('el CV mejorado se edita y se serializa para el Word', () {
      final result = CvImproveResult.fromJson({
        'cv': {
          'fullName': 'Lucía Torres',
          'contact': {'email': 'lucia@correo.com'},
          'experience': [
            {'role': 'Practicante', 'organization': 'Fintech Andina SAC', 'period': '03/2024 - 12/2024', 'achievements': ['Logro 1']},
          ],
          'education': [],
          'skills': ['Node.js'],
          'certifications': [
            {'name': 'Scrum Fundamentals Certified', 'year': '2023'},
          ],
          'languages': ['Inglés intermedio'],
          'other': [],
        },
        'integrity': {
          'removed': [
            {'field': 'habilidades', 'value': 'Kubernetes', 'reason': 'No aparece en tu CV original.'},
          ],
          'possiblyMissing': [],
        },
      });
      expect(result.removed.single.value, 'Kubernetes');
      final cv = result.cv
        ..experience.first.achievements = ['Logro 1', '', 'Logro editado']
        ..skills = ['Node.js', ' TypeScript '];
      final json = cv.toJson();
      expect((json['experience'] as List).first['achievements'], ['Logro 1', 'Logro editado']);
      expect(json['skills'], ['Node.js', 'TypeScript']);
      expect((json['certifications'] as List).first, {'name': 'Scrum Fundamentals Certified', 'year': '2023'});
      expect(json['contact'], {'email': 'lucia@correo.com'});
    });
  });
}
