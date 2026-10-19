import '../../../core/theme/ds_motion.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/localization/fitness_copy.dart';
import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/theme/fitness_theme.dart';
import '../models/body_assessment_models.dart';
import '../repositories/body_assessment_repository.dart';
import 'body_entry_view.dart';
import 'widgets/body_controls.dart';
import 'widgets/private_body_photo.dart';

class BodyRecordView extends StatefulWidget {
  final BodyAssessment entry;
  final bool canCompare;
  final VoidCallback? onCompare;
  const BodyRecordView(
      {super.key,
      required this.entry,
      this.canCompare = false,
      this.onCompare});
  @override
  State<BodyRecordView> createState() => _BodyRecordViewState();
}

class _BodyRecordViewState extends State<BodyRecordView> {
  String? _owner, _error;
  bool _deleting = false;
  @override
  void initState() {
    super.initState();
    CacheScope.userId().then((user) {
      if (mounted) _owner = user;
    });
  }

  Future<void> _edit() async {
    final route =
        AppPageRoute<bool>(page: BodyEntryView(existing: widget.entry));
    final edited = await Navigator.of(context).push(route);
    await route.completed;
    if (mounted && edited == true) Navigator.of(context).pop(true);
  }

  Future<void> _delete() async {
    final approved = await showDialog<bool>(
        animationStyle: DSMotion.dialogStyle(context),
        context: context,
        builder: (context) => AlertDialog(
                backgroundColor: FitnessTheme.surface,
                title: const FitnessText('Delete this entry?'),
                content: const FitnessText(
                    'The measurements and photos in this entry will be removed.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const FitnessText('Keep entry')),
                  TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const FitnessText('Delete',
                          style: TextStyle(color: FitnessTheme.coral)))
                ]));
    if (approved != true || !mounted) return;
    if (await CacheScope.userId() != _owner) {
      if (mounted) {
        setState(() => _error = 'Your session changed. Reopen this entry.');
      }
      return;
    }
    setState(() => _deleting = true);
    try {
      await BodyAssessmentRepository.shared.delete(widget.entry.id);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() => _error = BodyAssessmentRepository.message(error));
      }
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    return FitnessTheme(
        child: Scaffold(
            backgroundColor: FitnessTheme.canvas,
            appBar: AppBar(
                backgroundColor: FitnessTheme.canvas,
                surfaceTintColor: Colors.transparent,
                title: FitnessText(bodyDate(entry.recordedDate),
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w600)),
                actions: [
                  TextButton(
                      onPressed: _deleting ? null : _edit,
                      child: const FitnessText('Edit'))
                ]),
            body: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                children: [
                  OutlinedButton.icon(
                      onPressed: widget.canCompare ? widget.onCompare : null,
                      icon:
                          const Icon(CupertinoIcons.arrow_left_right, size: 17),
                      label: const FitnessText('Compare')),
                  const BodySectionTitle('Readings'),
                  FitnessCard(
                      child: Column(children: [
                    for (final metric in entry.metrics.entries)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(children: [
                            Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                  FitnessText(
                                      bodyMetricSpecs[metric.key]!.label,
                                      style: const TextStyle(fontSize: 14)),
                                  const SizedBox(height: 4),
                                  FitnessText(
                                      bodySourceLabel(metric.value.source),
                                      style: const TextStyle(
                                          fontSize: 11,
                                          color: FitnessTheme.muted))
                                ])),
                            FitnessText(
                                metric.value
                                    .display(bodyMetricSpecs[metric.key]!.unit),
                                style: const TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.w500))
                          ]))
                  ])),
                  if (entry.photos.isNotEmpty) ...[
                    const BodySectionTitle('Photos'),
                    GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: .62,
                        children: [
                          for (final photo in entry.photos)
                            Column(children: [
                              Expanded(
                                  child: GestureDetector(
                                      onTap: () => Navigator.of(context).push(
                                          AppPageRoute<void>(
                                              page: BodyPhotoViewer(
                                                  photo: photo))),
                                      child: PrivateBodyPhoto(
                                          key: ValueKey(photo.id),
                                          photo: photo))),
                              const SizedBox(height: 8),
                              FitnessText(photo.view.toUpperCase(),
                                  style: const TextStyle(
                                      fontSize: 11, color: FitnessTheme.muted))
                            ])
                        ])
                  ],
                  if (entry.summary != null) ...[
                    const BodySectionTitle('Photo review'),
                    FitnessCard(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          FitnessText(entry.summary!,
                              style:
                                  const TextStyle(fontSize: 13, height: 1.5)),
                          const SizedBox(height: 8),
                          const FitnessText(
                              'AI observations · visual estimates are unvalidated',
                              style: TextStyle(
                                  fontSize: 11, color: FitnessTheme.muted)),
                          for (final note in entry.qualityNotes)
                            Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: FitnessText(note,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: FitnessTheme.muted,
                                        height: 1.4)))
                        ]))
                  ],
                  for (final note in entry.observations)
                    Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: FitnessCard(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              FitnessText(
                                  bodyRegionNames[note['region']] ??
                                      'Observation',
                                  style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500)),
                              const SizedBox(height: 6),
                              FitnessText(note['observation'] as String,
                                  style: const TextStyle(
                                      fontSize: 13, height: 1.4)),
                              const SizedBox(height: 6),
                              FitnessText(
                                  fitnessText(context,
                                      'Photo observation · {value} confidence',
                                      values: {
                                        'value': fitnessText(context,
                                            note['confidence'] as String)
                                      }),
                                  style: const TextStyle(
                                      fontSize: 10, color: FitnessTheme.muted))
                            ]))),
                  if (_error != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: FitnessText(_error!,
                            style: const TextStyle(
                                fontSize: 13, color: FitnessTheme.coral))),
                  const SizedBox(height: 24),
                  TextButton(
                      onPressed: _deleting ? null : _delete,
                      child: FitnessText(
                          _deleting ? 'Deleting…' : 'Delete entry',
                          style: const TextStyle(color: FitnessTheme.coral))),
                ])));
  }
}

class BodyPhotoViewer extends StatelessWidget {
  final BodyPhoto photo;
  const BodyPhotoViewer({super.key, required this.photo});
  @override
  Widget build(BuildContext context) => FitnessTheme(
      child: Scaffold(
          backgroundColor: FitnessTheme.canvas,
          appBar: AppBar(
              backgroundColor: FitnessTheme.canvas,
              title: FitnessText(
                  '${photo.view[0].toUpperCase()}${photo.view.substring(1)}',
                  style: const TextStyle(fontSize: 17))),
          body: SafeArea(
              child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: SizedBox.expand(
                      child: PrivateBodyPhoto(photo: photo))))));
}
