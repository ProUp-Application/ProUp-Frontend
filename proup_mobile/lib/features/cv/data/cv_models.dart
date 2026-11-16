// Modelos del módulo "Mejorar mi CV".

List<String> _strs(dynamic v) => (v as List<dynamic>? ?? []).map((e) => e.toString()).toList();

class CvDocument {
  const CvDocument({required this.text, this.filename, this.hasTables, this.hasImages});

  final String text;
  final String? filename;
  final bool? hasTables;
  final bool? hasImages;

  factory CvDocument.fromJson(Map<String, dynamic> j) => CvDocument(
        text: j['text'] as String? ?? '',
        filename: j['filename'] as String?,
        hasTables: j['hasTables'] as bool?,
        hasImages: j['hasImages'] as bool?,
      );
}

class SectionReview {
  const SectionReview({
    required this.key,
    required this.status,
    this.observations = const [],
    this.recommendation = '',
    this.example,
  });

  final String key;
  final String status; // completa | mejorable | ausente
  final List<String> observations;
  final String recommendation;
  final String? example;

  static const labels = {
    'contacto': 'Datos de contacto',
    'perfil': 'Perfil profesional',
    'experiencia': 'Experiencia',
    'formacion': 'Formación',
    'habilidades': 'Habilidades',
    'certificaciones': 'Certificaciones y cursos',
    'idiomas': 'Idiomas',
  };

  String get label => labels[key] ?? key;

  factory SectionReview.fromJson(Map<String, dynamic> j) => SectionReview(
        key: j['key'] as String? ?? '',
        status: j['status'] as String? ?? 'mejorable',
        observations: _strs(j['observations']),
        recommendation: j['recommendation'] as String? ?? '',
        example: j['example'] as String?,
      );
}

class CvIssue {
  const CvIssue({required this.type, required this.text, required this.suggestion});

  final String type;
  final String text;
  final String suggestion;

  static const labels = {
    'ortografia': 'Ortografía',
    'redaccion': 'Redacción',
    'claridad': 'Claridad',
    'organizacion': 'Organización',
    'informacion_incompleta': 'Información incompleta',
  };

  String get label => labels[type] ?? type;

  factory CvIssue.fromJson(Map<String, dynamic> j) => CvIssue(
        type: j['type'] as String? ?? 'redaccion',
        text: j['text'] as String? ?? '',
        suggestion: j['suggestion'] as String? ?? '',
      );
}

class AtsCheck {
  const AtsCheck({required this.id, required this.label, required this.status, required this.detail, required this.why});

  final String id;
  final String label;
  final String status; // ok | warning | info
  final String detail;
  final String why;

  factory AtsCheck.fromJson(Map<String, dynamic> j) => AtsCheck(
        id: j['id'] as String? ?? '',
        label: j['label'] as String? ?? '',
        status: j['status'] as String? ?? 'info',
        detail: j['detail'] as String? ?? '',
        why: j['why'] as String? ?? '',
      );
}

class CvAnalysis {
  const CvAnalysis({
    required this.aiAvailable,
    this.summary,
    this.sections = const [],
    this.issues = const [],
    this.tips = const [],
    this.atsInfo = '',
    this.atsDisclaimer = '',
    this.atsChecks = const [],
  });

  final bool aiAvailable;
  final String? summary;
  final List<SectionReview> sections;
  final List<CvIssue> issues;
  final List<String> tips;
  final String atsInfo;
  final String atsDisclaimer;
  final List<AtsCheck> atsChecks;

  factory CvAnalysis.fromJson(Map<String, dynamic> j) {
    final ats = j['ats'] as Map<String, dynamic>? ?? {};
    return CvAnalysis(
      aiAvailable: j['aiAvailable'] as bool? ?? false,
      summary: j['summary'] as String?,
      sections: (j['sections'] as List<dynamic>? ?? [])
          .map((e) => SectionReview.fromJson(e as Map<String, dynamic>))
          .toList(),
      issues: (j['issues'] as List<dynamic>? ?? []).map((e) => CvIssue.fromJson(e as Map<String, dynamic>)).toList(),
      tips: _strs(j['tips']),
      atsInfo: ats['info'] as String? ?? '',
      atsDisclaimer: ats['disclaimer'] as String? ?? '',
      atsChecks: (ats['checks'] as List<dynamic>? ?? [])
          .map((e) => AtsCheck.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// Experiencia editable del CV mejorado.
class CvExperience {
  CvExperience({this.role = '', this.organization = '', this.period = '', this.location = '', List<String>? achievements})
      : achievements = achievements ?? [];

  String role;
  String organization;
  String period;
  String location;
  List<String> achievements;

  factory CvExperience.fromJson(Map<String, dynamic> j) => CvExperience(
        role: j['role'] as String? ?? '',
        organization: j['organization'] as String? ?? '',
        period: j['period'] as String? ?? '',
        location: j['location'] as String? ?? '',
        achievements: _strs(j['achievements']),
      );

  Map<String, dynamic> toJson() => {
        'role': role.trim(),
        'organization': organization.trim(),
        if (period.trim().isNotEmpty) 'period': period.trim(),
        if (location.trim().isNotEmpty) 'location': location.trim(),
        'achievements': achievements.map((a) => a.trim()).where((a) => a.isNotEmpty).toList(),
      };
}

class CvEducation {
  CvEducation({this.degree = '', this.institution = '', this.period = ''});

  String degree;
  String institution;
  String period;

  factory CvEducation.fromJson(Map<String, dynamic> j) => CvEducation(
        degree: j['degree'] as String? ?? '',
        institution: j['institution'] as String? ?? '',
        period: j['period'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'degree': degree.trim(),
        'institution': institution.trim(),
        if (period.trim().isNotEmpty) 'period': period.trim(),
      };
}

/// CV mejorado que el usuario revisa y edita antes de descargarlo en Word.
class CvDraft {
  CvDraft({
    this.fullName = '',
    this.headline = '',
    this.email = '',
    this.phone = '',
    this.location = '',
    this.linkedin = '',
    this.website = '',
    this.profile = '',
    List<CvExperience>? experience,
    List<CvEducation>? education,
    List<String>? skills,
    List<String>? certifications,
    List<String>? languages,
    List<Map<String, dynamic>>? other,
  })  : experience = experience ?? [],
        education = education ?? [],
        skills = skills ?? [],
        certifications = certifications ?? [],
        languages = languages ?? [],
        other = other ?? [];

  String fullName;
  String headline;
  String email;
  String phone;
  String location;
  String linkedin;
  String website;
  String profile;
  List<CvExperience> experience;
  List<CvEducation> education;
  List<String> skills;

  /// Una por línea: "Nombre — Emisor — Año".
  List<String> certifications;
  List<String> languages;
  List<Map<String, dynamic>> other;

  factory CvDraft.fromJson(Map<String, dynamic> j) {
    final c = j['contact'] as Map<String, dynamic>? ?? {};
    return CvDraft(
      fullName: j['fullName'] as String? ?? '',
      headline: j['headline'] as String? ?? '',
      email: c['email'] as String? ?? '',
      phone: c['phone'] as String? ?? '',
      location: c['location'] as String? ?? '',
      linkedin: c['linkedin'] as String? ?? '',
      website: c['website'] as String? ?? '',
      profile: j['profile'] as String? ?? '',
      experience: (j['experience'] as List<dynamic>? ?? [])
          .map((e) => CvExperience.fromJson(e as Map<String, dynamic>))
          .toList(),
      education: (j['education'] as List<dynamic>? ?? [])
          .map((e) => CvEducation.fromJson(e as Map<String, dynamic>))
          .toList(),
      skills: _strs(j['skills']),
      certifications: (j['certifications'] as List<dynamic>? ?? []).map((e) {
        final m = e as Map<String, dynamic>;
        return [m['name'], m['issuer'], m['year']].where((x) => x != null && '$x'.isNotEmpty).join(' — ');
      }).toList(),
      languages: _strs(j['languages']),
      other: (j['other'] as List<dynamic>? ?? []).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    );
  }

  static String? _opt(String v) => v.trim().isEmpty ? null : v.trim();

  Map<String, dynamic> toJson() => {
        'fullName': fullName.trim(),
        if (_opt(headline) != null) 'headline': _opt(headline),
        'contact': {
          if (_opt(email) != null) 'email': _opt(email),
          if (_opt(phone) != null) 'phone': _opt(phone),
          if (_opt(location) != null) 'location': _opt(location),
          if (_opt(linkedin) != null) 'linkedin': _opt(linkedin),
          if (_opt(website) != null) 'website': _opt(website),
        },
        if (_opt(profile) != null) 'profile': _opt(profile),
        'experience': experience
            .where((e) => e.role.trim().isNotEmpty || e.organization.trim().isNotEmpty)
            .map((e) => e.toJson())
            .toList(),
        'education': education
            .where((e) => e.degree.trim().isNotEmpty || e.institution.trim().isNotEmpty)
            .map((e) => e.toJson())
            .toList(),
        'skills': skills.map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        'certifications': certifications.map((c) => c.trim()).where((c) => c.isNotEmpty).map((c) {
          final parts = c.split(RegExp(r'\s+[—-]\s+'));
          return {
            'name': parts[0],
            if (parts.length > 1 && !RegExp(r'^\d{4}$').hasMatch(parts[1])) 'issuer': parts[1],
            if (parts.any((p) => RegExp(r'^\d{4}$').hasMatch(p))) 'year': parts.firstWhere((p) => RegExp(r'^\d{4}$').hasMatch(p)),
          };
        }).toList(),
        'languages': languages.map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        'other': other,
      };
}

class IntegrityItem {
  const IntegrityItem(this.value, this.reason);

  final String value;
  final String reason;
}

class CvImproveResult {
  const CvImproveResult({
    required this.cv,
    this.changes = const [],
    this.suggestions = const [],
    this.removed = const [],
    this.possiblyMissing = const [],
    this.notice = '',
  });

  final CvDraft cv;
  final List<String> changes;
  final List<String> suggestions;

  /// Datos que la IA había agregado y se descartaron por no estar en el CV original.
  final List<IntegrityItem> removed;

  /// Información del original que no quedó en la versión mejorada.
  final List<IntegrityItem> possiblyMissing;
  final String notice;

  factory CvImproveResult.fromJson(Map<String, dynamic> j) {
    final integrity = j['integrity'] as Map<String, dynamic>? ?? {};
    List<IntegrityItem> items(dynamic v) => (v as List<dynamic>? ?? []).map((e) {
          final m = e as Map<String, dynamic>;
          return IntegrityItem(m['value']?.toString() ?? '', m['reason']?.toString() ?? '');
        }).toList();
    return CvImproveResult(
      cv: CvDraft.fromJson(j['cv'] as Map<String, dynamic>? ?? {}),
      changes: (j['changes'] as List<dynamic>? ?? []).map((e) {
        final m = e as Map<String, dynamic>;
        final section = (m['section'] as String? ?? '').trim();
        return section.isEmpty ? m['description'].toString() : '$section: ${m['description']}';
      }).toList(),
      suggestions: _strs(j['suggestions']),
      removed: items(integrity['removed']),
      possiblyMissing: items(integrity['possiblyMissing']),
      notice: j['notice'] as String? ?? '',
    );
  }
}

class VacancyMatch {
  const VacancyMatch({this.matches = const [], this.gaps = const [], this.suggestions = const [], this.notice = ''});

  final List<String> matches;
  final List<String> gaps;
  final List<String> suggestions;
  final String notice;

  factory VacancyMatch.fromJson(Map<String, dynamic> j) => VacancyMatch(
        matches: _strs(j['matches']),
        gaps: _strs(j['gaps']),
        suggestions: _strs(j['suggestions']),
        notice: j['notice'] as String? ?? '',
      );
}
