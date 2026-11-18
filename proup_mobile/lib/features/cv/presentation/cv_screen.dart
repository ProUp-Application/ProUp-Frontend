import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../core/di/injector.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/proup_widgets.dart';
import '../data/cv_models.dart';
import '../data/cv_repository.dart';

/// "Mejorar mi CV": análisis por secciones, revisión ATS orientativa, versión
/// mejorada editable (sin datos inventados) y descarga en Word.
class CvScreen extends StatefulWidget {
  const CvScreen({super.key});

  @override
  State<CvScreen> createState() => _CvScreenState();
}

class _CvScreenState extends State<CvScreen> {
  final _textCtrl = TextEditingController();
  final _roleCtrl = TextEditingController();
  CvDocument? _doc;
  CvAnalysis? _analysis;
  CvImproveResult? _improved;
  String? _busy; // mensaje del proceso en curso
  int _step = 0; // 0 = CV, 1 = análisis, 2 = versión mejorada

  CvRepository get _repo => getIt<CvRepository>();

  @override
  void dispose() {
    _textCtrl.dispose();
    _roleCtrl.dispose();
    super.dispose();
  }

  Future<T?> _run<T>(String message, Future<T> Function() task) async {
    setState(() => _busy = message);
    try {
      return await task();
    } on AppException catch (e) {
      _error(e.message);
    } catch (_) {
      _error('Ocurrió un problema. Revisa tu conexión e inténtalo de nuevo.');
    } finally {
      if (mounted) setState(() => _busy = null);
    }
    return null;
  }

  void _error(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), backgroundColor: AppColors.error, duration: const Duration(seconds: 6)));
  }

  void _ok(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _pickFile() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'docx', 'txt'],
      withData: true,
    );
    final file = picked?.files.firstOrNull;
    if (file == null || file.bytes == null) return;
    final doc = await _run('Leyendo tu CV…', () => _repo.extract(file.bytes!, file.name));
    if (doc == null) return;
    setState(() {
      _doc = doc;
      _textCtrl.text = doc.text;
    });
  }

  Future<void> _analyze() async {
    final text = _textCtrl.text.trim();
    if (text.length < 80) {
      _error('Adjunta tu CV o pega el texto completo (es muy corto para analizarlo).');
      return;
    }
    final doc = CvDocument(
      text: text,
      filename: _doc?.filename,
      hasTables: _doc?.hasTables,
      hasImages: _doc?.hasImages,
    );
    final analysis = await _run('Analizando tu CV por secciones…', () => _repo.analyze(doc));
    if (analysis == null) return;
    setState(() {
      _doc = doc;
      _analysis = analysis;
      _step = 1;
    });
  }

  Future<void> _improve() async {
    final result = await _run(
      'Generando una versión mejorada con tus datos…',
      () => _repo.improve(_textCtrl.text.trim(), targetRole: _roleCtrl.text),
    );
    if (result == null) return;
    setState(() {
      _improved = result;
      _step = 2;
    });
  }

  Future<void> _download() async {
    final cv = _improved?.cv;
    if (cv == null) return;
    if (cv.fullName.trim().isEmpty) {
      _error('Escribe tu nombre completo antes de descargar.');
      return;
    }
    final bytes = await _run('Preparando tu CV en Word…', () => _repo.exportDocx(cv));
    if (bytes == null) return;
    final safe = cv.fullName.trim().replaceAll(RegExp(r'[^A-Za-zÁÉÍÓÚáéíóúÑñ0-9]+'), '_');
    try {
      final path = await FilePicker.saveFile(
        dialogTitle: 'Guardar CV en Word',
        fileName: 'CV_$safe.docx',
        type: FileType.custom,
        allowedExtensions: ['docx'],
        bytes: bytes,
      );
      if (path == null) return; // el usuario canceló
      _ok('CV guardado en Word. Ábrelo y revísalo antes de enviarlo.');
    } catch (_) {
      _error('No se pudo guardar el archivo en el teléfono. Inténtalo de nuevo.');
    }
  }

  Future<void> _compareVacancy() async {
    final ctrl = TextEditingController();
    final vacancy = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Comparar con una vacante'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Pega la descripción del puesto (funciones y requisitos).', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 10),
            TextField(controller: ctrl, maxLines: 8, maxLength: 6000, decoration: const InputDecoration(hintText: 'Descripción de la vacante…')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: const Text('Comparar')),
        ],
      ),
    );
    ctrl.dispose();
    if (vacancy == null || vacancy.isEmpty) return;
    if (vacancy.length < 50) {
      _error('Pega la descripción completa de la vacante (requisitos y funciones).');
      return;
    }
    final match = await _run('Comparando tu CV con la vacante…', () => _repo.match(_textCtrl.text.trim(), vacancy));
    if (match == null || !mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        builder: (_, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(20),
          children: [
            Text('Tu CV frente a la vacante', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(match.notice, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            _BulletCard(title: 'Lo que tu CV sí evidencia', icon: Icons.check_circle, color: AppColors.tertiary, items: match.matches),
            const SizedBox(height: 12),
            _BulletCard(title: 'Lo que no se evidencia', icon: Icons.help_outline, color: AppColors.scoreMid, items: match.gaps),
            const SizedBox(height: 12),
            _BulletCard(title: 'Cómo destacar tu experiencia real', icon: Icons.lightbulb_outline, color: AppColors.primary, items: match.suggestions),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmLeave() async {
    if (_step == 0 && _textCtrl.text.trim().isEmpty) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Salir de Mejorar mi CV?'),
        content: const Text('No guardamos tu CV en ProUp: si sales, tendrás que adjuntarlo de nuevo. Descarga tu versión mejorada antes de salir.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Quedarme')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Salir')),
        ],
      ),
    );
    return ok == true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_step > 0) {
          setState(() => _step--);
          return;
        }
        if (await _confirmLeave() && context.mounted) Navigator.of(context).pop();
      },
      child: Scaffold(
        appBar: AppBar(title: Text(['Mejorar mi CV', 'Análisis de tu CV', 'Tu CV mejorado'][_step])),
        body: Column(
          children: [
            if (_busy != null)
              Container(
                width: double.infinity,
                color: AppColors.primaryContainer.withValues(alpha: 0.1),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2)),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_busy!, style: const TextStyle(fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
            Expanded(
              child: AbsorbPointer(
                absorbing: _busy != null,
                // La clave por paso hace que cada paso empiece arriba (sin heredar el desplazamiento)
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: switch (_step) {
                    0 => _inputStep(context),
                    1 => _analysisStep(context),
                    _ => _editorStep(context),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- Paso 1

  Widget _inputStep(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Text('Revisamos tu CV como un reclutador y te ayudamos a mejorarlo.', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 12),
        const _Steps(),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _pickFile,
          icon: const Icon(Icons.upload_file),
          label: const Text('Adjuntar mi CV (PDF, Word o TXT)'),
        ),
        if (_doc?.filename != null) ...[
          const SizedBox(height: 6),
          Text('Archivo leído: ${_doc!.filename}', style: Theme.of(context).textTheme.bodySmall),
        ],
        const SizedBox(height: 14),
        TextField(
          controller: _textCtrl,
          maxLines: 12,
          minLines: 6,
          maxLength: 9000,
          decoration: const InputDecoration(
            labelText: 'Texto de tu CV',
            hintText: 'También puedes pegar aquí el texto de tu CV…',
            alignLabelWithHint: true,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _roleCtrl,
          decoration: const InputDecoration(
            labelText: 'Puesto al que postulas (opcional)',
            hintText: 'Ej.: Desarrollador backend junior',
          ),
        ),
        const SizedBox(height: 16),
        const _PrivacyNote(),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _textCtrl.text.trim().isEmpty ? null : _analyze,
          icon: const Icon(Icons.fact_check_outlined),
          label: const Text('Analizar mi CV'),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- Paso 2

  Widget _analysisStep(BuildContext context) {
    final a = _analysis!;
    final theme = Theme.of(context);
    final okCount = a.atsChecks.where((c) => c.status == 'ok').length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        if (a.summary != null) ...[
          AmbientCard(child: Text(a.summary!, style: theme.textTheme.bodyMedium)),
          const SizedBox(height: 16),
        ],
        if (!a.aiAvailable)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text('El asesor de IA no respondió: te mostramos la revisión automática de secciones y la revisión ATS.',
                style: TextStyle(color: AppColors.scoreMid)),
          ),
        Text('Revisión por secciones', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        ...a.sections.map((s) => Padding(padding: const EdgeInsets.only(bottom: 10), child: _SectionCard(s: s))),
        if (a.issues.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Errores a corregir', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          ...a.issues.map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AmbientCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatusChip(label: i.label, background: AppColors.errorContainer, foreground: AppColors.onErrorContainer),
                      if (i.text.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text('"${i.text}"', style: theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic)),
                      ],
                      const SizedBox(height: 6),
                      Text(i.suggestion, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              )),
        ],
        const SizedBox(height: 12),
        Text('Compatibilidad con ATS', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('$okCount de ${a.atsChecks.length} pautas en buen estado', style: theme.textTheme.bodySmall),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(14)),
          child: Text(a.atsInfo, style: theme.textTheme.bodySmall),
        ),
        const SizedBox(height: 10),
        AmbientCard(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(children: a.atsChecks.map((c) => _AtsTile(c: c)).toList()),
        ),
        const SizedBox(height: 8),
        Text(a.atsDisclaimer, style: theme.textTheme.bodySmall?.copyWith(color: AppColors.onSurfaceVariant)),
        if (a.tips.isNotEmpty) ...[
          const SizedBox(height: 16),
          _BulletCard(title: 'Para presentar mejor tu perfil', icon: Icons.lightbulb_outline, color: AppColors.primary, items: a.tips),
        ],
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: _improve,
          icon: const Icon(Icons.auto_fix_high),
          label: const Text('Generar versión mejorada'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _compareVacancy,
          icon: const Icon(Icons.compare_arrows),
          label: const Text('Comparar con una vacante'),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- Paso 3

  Widget _editorStep(BuildContext context) {
    final r = _improved!;
    final cv = r.cv;
    final theme = Theme.of(context);

    Widget field(String label, String value, void Function(String) onChanged,
            {int lines = 1, String? hint, String? id}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextFormField(
            key: ValueKey(id ?? label),
            initialValue: value,
            minLines: lines,
            maxLines: lines == 1 ? 1 : lines + 4,
            decoration: InputDecoration(labelText: label, hintText: hint, alignLabelWithHint: lines > 1),
            onChanged: onChanged,
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Text(r.notice, style: theme.textTheme.bodySmall),
        ),
        if (r.removed.isNotEmpty) ...[
          const SizedBox(height: 12),
          _IntegrityCard(
            title: 'Datos descartados porque no estaban en tu CV',
            icon: Icons.block,
            color: AppColors.error,
            items: r.removed,
          ),
        ],
        if (r.possiblyMissing.isNotEmpty) ...[
          const SizedBox(height: 12),
          _IntegrityCard(
            title: 'Revisa: podría faltar información de tu CV original',
            icon: Icons.warning_amber,
            color: AppColors.scoreMid,
            items: r.possiblyMissing,
          ),
        ],
        if (r.changes.isNotEmpty) ...[
          const SizedBox(height: 12),
          _BulletCard(title: 'Qué cambiamos y por qué', icon: Icons.edit_note, color: AppColors.primary, items: r.changes),
        ],
        if (r.suggestions.isNotEmpty) ...[
          const SizedBox(height: 12),
          _BulletCard(title: 'Puedes agregar (solo si es real)', icon: Icons.add_circle_outline, color: AppColors.tertiary, items: r.suggestions),
        ],
        const SizedBox(height: 18),
        Text('Edita tu CV', style: theme.textTheme.titleLarge),
        const SizedBox(height: 10),
        field('Nombre completo', cv.fullName, (v) => cv.fullName = v),
        field('Titular', cv.headline, (v) => cv.headline = v, hint: 'Ej.: Bachiller en Ingeniería de Software'),
        field('Correo', cv.email, (v) => cv.email = v),
        field('Teléfono', cv.phone, (v) => cv.phone = v),
        field('Ubicación', cv.location, (v) => cv.location = v),
        field('LinkedIn', cv.linkedin, (v) => cv.linkedin = v),
        field('Perfil profesional', cv.profile, (v) => cv.profile = v, lines: 4),
        const SizedBox(height: 8),
        Text('Experiencia', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (var i = 0; i < cv.experience.length; i++)
          AmbientCard(
            key: ObjectKey(cv.experience[i]),
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
            child: Column(
              children: [
                Row(
                  children: [
                    Text('Experiencia ${i + 1}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Quitar',
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      onPressed: () => _removeExperience(i),
                    ),
                  ],
                ),
                field('Cargo', cv.experience[i].role, (v) => cv.experience[i].role = v),
                field('Organización', cv.experience[i].organization, (v) => cv.experience[i].organization = v),
                field('Periodo', cv.experience[i].period, (v) => cv.experience[i].period = v),
                field('Logros (uno por línea)', cv.experience[i].achievements.join('\n'),
                    (v) => cv.experience[i].achievements = v.split('\n'), lines: 3),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Text('Formación', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (var i = 0; i < cv.education.length; i++) ...[
          field('Carrera o grado', cv.education[i].degree, (v) => cv.education[i].degree = v, id: 'edu_degree_$i'),
          field('Institución', cv.education[i].institution, (v) => cv.education[i].institution = v, id: 'edu_inst_$i'),
          field('Periodo', cv.education[i].period, (v) => cv.education[i].period = v, id: 'edu_period_$i'),
        ],
        field('Habilidades (separadas por comas)', cv.skills.join(', '),
            (v) => cv.skills = v.split(','), lines: 2),
        field('Certificaciones y cursos (uno por línea)', cv.certifications.join('\n'),
            (v) => cv.certifications = v.split('\n'), lines: 2),
        field('Idiomas (separados por comas)', cv.languages.join(', '), (v) => cv.languages = v.split(',')),
        const SizedBox(height: 8),
        Text('El Word usa una sola columna, títulos estándar y sin tablas ni imágenes, para que los ATS lo lean bien.',
            style: theme.textTheme.bodySmall),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: _download,
          icon: const Icon(Icons.download),
          label: const Text('Descargar en Word (.docx)'),
        ),
      ],
    );
  }

  Future<void> _removeExperience(int i) async {
    final cv = _improved!.cv;
    final e = cv.experience[i];
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Quitar esta experiencia?'),
        content: Text('Se quitará "${e.role} — ${e.organization}" de la versión que vas a descargar.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Quitar')),
        ],
      ),
    );
    if (ok == true) setState(() => cv.experience.removeAt(i));
  }
}

class _Steps extends StatelessWidget {
  const _Steps();

  @override
  Widget build(BuildContext context) {
    const steps = [
      '1. Adjunta tu CV o pega su texto.',
      '2. Te mostramos observaciones por sección y una revisión para sistemas ATS.',
      '3. Generamos una versión mejorada con TUS datos: la revisas y la editas.',
      '4. La descargas en Word para seguir editándola.',
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: steps
            .map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(s, style: Theme.of(context).textTheme.bodySmall),
                ))
            .toList(),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.lock_outline, size: 18, color: AppColors.tertiary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Para analizarlo, el texto de tu CV se envía al proveedor de IA (Groq). ProUp no guarda tu CV: '
            'se procesa para responderte y se descarta. Revisa que no incluya datos sensibles como tu DNI.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.s});

  final SectionReview s;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = switch (s.status) {
      'completa' => (AppColors.tertiary.withValues(alpha: 0.12), AppColors.tertiary, 'Completa'),
      'ausente' => (AppColors.errorContainer, AppColors.onErrorContainer, 'No está'),
      _ => (AppColors.scoreMid.withValues(alpha: 0.15), const Color(0xFF7A5800), 'Mejorable'),
    };
    return AmbientCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(s.label, style: Theme.of(context).textTheme.titleSmall)),
              StatusChip(label: label, background: bg, foreground: fg),
            ],
          ),
          for (final o in s.observations)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('• $o', style: Theme.of(context).textTheme.bodySmall),
            ),
          if (s.recommendation.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(s.recommendation, style: Theme.of(context).textTheme.bodyMedium),
          ],
          if ((s.example ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
              child: Text('Ejemplo: ${s.example}', style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ],
      ),
    );
  }
}

class _AtsTile extends StatelessWidget {
  const _AtsTile({required this.c});

  final AtsCheck c;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (c.status) {
      'ok' => (Icons.check_circle, AppColors.tertiary),
      'warning' => (Icons.warning_amber_rounded, AppColors.scoreMid),
      _ => (Icons.info_outline, AppColors.primary),
    };
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: Icon(icon, color: color),
        tilePadding: const EdgeInsets.symmetric(horizontal: 6),
        title: Text(c.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(c.detail, style: Theme.of(context).textTheme.bodySmall),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          Text('¿Por qué importa? ${c.why}', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _BulletCard extends StatelessWidget {
  const _BulletCard({required this.title, required this.icon, required this.color, required this.items});

  final String title;
  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return AmbientCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
          ]),
          const SizedBox(height: 8),
          if (items.isEmpty) Text('—', style: Theme.of(context).textTheme.bodySmall),
          for (final i in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('• $i', style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

class _IntegrityCard extends StatelessWidget {
  const _IntegrityCard({required this.title, required this.icon, required this.color, required this.items});

  final String title;
  final IconData icon;
  final Color color;
  final List<IntegrityItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: Theme.of(context).textTheme.titleSmall)),
          ]),
          const SizedBox(height: 8),
          for (final i in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text('• ${i.value}: ${i.reason}', style: Theme.of(context).textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}
