import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/components/liquid_chrome_button.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/theme/ds_motion.dart';
import '../../../core/theme/fitness_theme.dart';
import '../repositories/body_assessment_repository.dart';
import 'body_estimate_view.dart';
import 'widgets/physique_photo_stage.dart';
import 'widgets/composition_readings_sheet.dart';

class BodyPhotoReviewView extends StatefulWidget {
  final double? profileWeight, profileHeight;
  final bool female;
  final Future<Uint8List?> Function(String view)? pickPhoto;
  final BodyAssessmentRepository? repository;
  const BodyPhotoReviewView(
      {super.key,
      this.profileWeight,
      this.profileHeight,
      this.female = false,
      this.pickPhoto,
      this.repository});
  @override
  State<BodyPhotoReviewView> createState() => _BodyPhotoReviewViewState();
}

class _BodyPhotoReviewViewState extends State<BodyPhotoReviewView> {
  Map<String, dynamic>? _readings;
  final _photos = <String, Uint8List>{};
  String _view = 'front';
  bool _consent = false,
      _processing = false,
      _savePhotos = false,
      _picking = false;
  String? _error;
  String _label(String view) => switch (view) {
        'back' => 'Back',
        'left' => 'Side',
        'right' => 'Right side',
        _ => 'Front'
      };

  Future<void> _pick(String view) async {
    if (_processing || _picking) return;
    setState(() => _picking = true);
    try {
      Uint8List? bytes;
      if (widget.pickPhoto != null) {
        bytes = await widget.pickPhoto!(view);
      } else {
        final source = await showModalBottomSheet<ImageSource>(
            sheetAnimationStyle: DSMotion.sheetStyle(context),
            context: context,
            backgroundColor: FitnessTheme.surface,
            builder: (context) => SafeArea(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                  ListTile(
                      leading: const Icon(CupertinoIcons.camera),
                      title: const FitnessText('Take photo'),
                      onTap: () => Navigator.pop(context, ImageSource.camera)),
                  ListTile(
                      leading: const Icon(CupertinoIcons.photo),
                      title: const FitnessText('Choose from library'),
                      onTap: () => Navigator.pop(context, ImageSource.gallery)),
                ])));
        if (source == null || !mounted) return;
        final image = await ImagePicker().pickImage(
            source: source,
            maxWidth: 1280,
            maxHeight: 1600,
            imageQuality: 85,
            requestFullMetadata: false);
        if (image == null) return;
        bytes = await image.readAsBytes();
      }
      if (bytes == null || !mounted) return;
      if (bytes.length > 2000000) {
        throw StateError('Choose a JPEG or PNG photo below 2 MB.');
      }
      if (!(bytes.length > 3 &&
              bytes[0] == 255 &&
              bytes[1] == 216 &&
              bytes[2] == 255) &&
          !(bytes.length > 8 &&
              bytes[0] == 137 &&
              bytes[1] == 80 &&
              bytes[2] == 78 &&
              bytes[3] == 71)) {
        throw StateError('Choose a JPEG or PNG photo.');
      }
      setState(() {
        _photos[view] = bytes!;
        _view = view;
        _error = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() => _error = BodyAssessmentRepository.message(error));
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _review() async {
    if (_processing || !_consent || !_photos.containsKey('front')) return;
    setState(() {
      _processing = true;
      _error = null;
    });
    final owner = await CacheScope.userId();
    if (!mounted) return;
    try {
      final payload = <String, dynamic>{
        'recordedDate': CacheScope.todayKey(DateTime.now()),
        'utcOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
        'consentToPhotoAnalysis': true,
        'analysisProvider': 'OPENAI',
        'consentToVisualCoaching': true,
        'savePhotos': _savePhotos,
        if (_readings != null) 'compositionReadings': _readings,
        'photos': [
          for (final item in _photos.entries)
            {
              'view': item.key,
              'base64': base64Encode(item.value),
              'mimeType': item.value[0] == 137 ? 'image/png' : 'image/jpeg',
            }
        ],
      };
      final localPhotos = Map<String, Uint8List>.unmodifiable(_photos);
      final route = AppPageRoute<bool>(
          page: BodyEstimateView(
              female: widget.female,
              localPhotos: localPhotos,
              repository: widget.repository,
              estimate: (onStage, cancelled) => (widget.repository ??
                      BodyAssessmentRepository.shared)
                  .review(payload, cancelled: cancelled, onStage: onStage)));
      final saved = await Navigator.of(context).push(route);
      await route.completed;
      if (saved == true &&
          mounted &&
          await CacheScope.userId() == owner &&
          mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = BodyAssessmentRepository.message(error));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) => FitnessTheme(
          child: Scaffold(
        backgroundColor: FitnessTheme.canvas,
        appBar: AppBar(
            backgroundColor: FitnessTheme.canvas,
            surfaceTintColor: Colors.transparent,
            title: const FitnessText('Physique review',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
        body: SafeArea(
            top: false,
            child: Column(children: [
              Expanded(
                  child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                      children: [
                    const FitnessText('Your starting point.\nIn focus.',
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w600,
                            height: 1.08,
                            letterSpacing: -1)),
                    const SizedBox(height: 10),
                    const FitnessText(
                        'Start with a front photo. Other views are optional.',
                        style: TextStyle(
                            fontSize: 13,
                            height: 1.5,
                            color: FitnessTheme.muted)),
                    const SizedBox(height: 20),
                    PhysiquePhotoStage(
                        borderColor: const Color(0xFF8DBBFF),
                        bytes: _photos[_view],
                        label: '${_label(_view)} view',
                        footer: Align(
                            alignment: Alignment.centerLeft,
                            child: OutlinedButton.icon(
                                key: const ValueKey('pick-review-photo'),
                                onPressed: _processing || _picking
                                    ? null
                                    : () => _pick(_view),
                                style: OutlinedButton.styleFrom(
                                    backgroundColor:
                                        Colors.black.withValues(alpha: .6),
                                    foregroundColor: FitnessTheme.silver,
                                    side: const BorderSide(
                                        color: FitnessTheme.line)),
                                icon:
                                    const Icon(CupertinoIcons.camera, size: 16),
                                label: FitnessText(_photos.containsKey(_view)
                                    ? 'Replace photo'
                                    : 'Add ${_label(_view).toLowerCase()} photo')))),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 6, children: [
                      for (final view in ['front', 'back', 'left'])
                        ChoiceChip(
                            key: ValueKey('photo-view-$view'),
                            label: FitnessText(
                                '${_label(view)}${_photos.containsKey(view) ? ' ✓' : ''}'),
                            selected: _view == view,
                            showCheckmark: false,
                            selectedColor: FitnessTheme.silver,
                            backgroundColor: FitnessTheme.surface,
                            labelStyle: TextStyle(
                                fontSize: 11,
                                color: _view == view
                                    ? FitnessTheme.canvas
                                    : FitnessTheme.silver),
                            side: const BorderSide(color: FitnessTheme.line),
                            onSelected: _processing
                                ? null
                                : (_) => setState(() => _view = view))
                    ]),
                    const SizedBox(height: 14),
                    const FitnessText(
                        'Gym clothes are fine; your face can stay out of frame. Include shoulders, hips and legs. Face a level camera with arms slightly away from your torso and feet comfortably apart.',
                        style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: FitnessTheme.muted)),
                    const SizedBox(height: 22),
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(CupertinoIcons.slider_horizontal_3,
                            size: 19),
                        title: const FitnessText('Composition readings',
                            style: TextStyle(fontSize: 14)),
                        subtitle: FitnessText(
                            _readings == null
                                ? 'Optional · Add scale or DEXA readings'
                                : 'Your readings are included',
                            style: const TextStyle(
                                fontSize: 11, color: FitnessTheme.muted)),
                        trailing:
                            const Icon(CupertinoIcons.chevron_right, size: 13),
                        onTap: _processing
                            ? null
                            : () async {
                                final readings = await showCompositionReadings(
                                    context,
                                    initial: _readings);
                                if (mounted && readings != null) {
                                  setState(() => _readings = readings);
                                }
                              }),
                    const Divider(height: 1, color: FitnessTheme.line),
                    SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        key: const ValueKey('save-scan-photos'),
                        value: _savePhotos,
                        activeTrackColor: FitnessTheme.silver,
                        activeThumbColor: FitnessTheme.canvas,
                        onChanged: _processing
                            ? null
                            : (value) => setState(() => _savePhotos = value),
                        title: const FitnessText('Save photos for comparison',
                            style: TextStyle(fontSize: 14)),
                        subtitle: const FitnessText(
                            'Optional. Compare after two scans with saved photos.',
                            style: TextStyle(
                                fontSize: 11,
                                height: 1.4,
                                color: FitnessTheme.muted))),
                    CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        key: const ValueKey('photo-analysis-consent'),
                        value: _consent,
                        activeColor: FitnessTheme.silver,
                        checkColor: FitnessTheme.canvas,
                        onChanged: _processing
                            ? null
                            : (value) =>
                                setState(() => _consent = value == true),
                        title: const FitnessText(
                            'I agree to AI analysis of these photos.',
                            style: TextStyle(fontSize: 13)),
                        subtitle: const FitnessText(
                            'Photos are sent to our server and AI provider. The review is separate from your workout plan.',
                            style: TextStyle(
                                fontSize: 11,
                                height: 1.5,
                                color: FitnessTheme.muted))),
                    if (_error != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: FitnessText(_error!,
                              style: const TextStyle(
                                  fontSize: 13, color: FitnessTheme.coral))),
                  ])),
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: LiquidChromeButton(
                      title: _processing
                          ? 'Opening review…'
                          : 'Review my physique',
                      onPressed: _processing ||
                              _picking ||
                              !_consent ||
                              !_photos.containsKey('front')
                          ? null
                          : _review)),
            ])),
      ));
}
