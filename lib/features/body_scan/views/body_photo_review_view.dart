import '../../../core/theme/ds_motion.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import 'package:fitai_mobile/core/localization/fitness_text.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/components/liquid_chrome_button.dart';
import '../../../core/theme/fitness_theme.dart';
import '../repositories/body_assessment_repository.dart';
import 'body_estimate_view.dart';

class BodyPhotoReviewView extends StatefulWidget {
  final double? profileWeight;
  final double? profileHeight;
  final bool female;
  const BodyPhotoReviewView(
      {super.key, this.profileWeight, this.profileHeight, this.female = false});
  @override
  State<BodyPhotoReviewView> createState() => _BodyPhotoReviewViewState();
}

class _BodyPhotoReviewViewState extends State<BodyPhotoReviewView> {
  final _photos = <String, Uint8List>{};
  final _weight = TextEditingController();
  bool _consent = false, _processing = false, _savePhotos = false;
  bool _analysis = true;
  bool _weightChanged = false;
  String? _error;
  DateTime _date = DateTime.now();
  @override
  void initState() {
    super.initState();
    _weight.text = widget.profileWeight?.toString() ?? '';
  }

  @override
  void dispose() {
    _weight.dispose();
    super.dispose();
  }

  Future<void> _pick(String view) async {
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
    if (source == null) return;
    try {
      final image = await ImagePicker().pickImage(
          source: source, maxWidth: 1280, maxHeight: 1600, imageQuality: 78);
      if (image == null) return;
      final bytes = await image.readAsBytes();
      if (bytes.length > 2000000) {
        throw StateError('This photo is too large. Choose a JPEG below 2 MB.');
      }
      if (!(bytes.length > 3 && bytes[0] == 255 && bytes[1] == 216) &&
          !(bytes.length > 8 && bytes[0] == 137 && bytes[1] == 80)) {
        throw StateError('Choose a JPEG or PNG photo.');
      }
      if (mounted) {
        setState(() {
          _photos[view] = bytes;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = BodyAssessmentRepository.message(error));
      }
    }
  }

  Future<void> _review() async {
    final weight = double.tryParse(_weight.text.trim().replaceAll(',', '.'));
    if (weight == null || !weight.isFinite || weight < 20 || weight > 500) {
      setState(
          () => _error = 'Confirm your current scale weight in kilograms.');
      return;
    }
    setState(() {
      _processing = true;
      _analysis = true;
      _error = null;
    });
    try {
      final payload = <String, dynamic>{
        'recordedDate': CacheScope.todayKey(_date),
        'utcOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
        'weightKg': weight,
        'weightSource': _weightChanged || widget.profileWeight == null
            ? 'scale'
            : 'profile',
        'consentToPhotoAnalysis': _consent,
        'consentToVisualCoaching': _consent,
        'savePhotos': _savePhotos,
        'photos': [
          for (final item in _photos.entries)
            {
              'view': item.key,
              'base64': base64Encode(item.value),
              'mimeType': item.value[0] == 137 ? 'image/png' : 'image/jpeg'
            }
        ],
      };
      final route = AppPageRoute<bool>(
          page: BodyEstimateView(
              female: widget.female,
              estimate: (onStage, cancelled) => BodyAssessmentRepository.shared
                  .review(payload, cancelled: cancelled, onStage: onStage)));
      final saved = await Navigator.of(context).push(route);
      await route.completed;
      if (saved == true && mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() => _error = BodyAssessmentRepository.message(error));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _saveJournal() async {
    final weight = double.tryParse(_weight.text.trim().replaceAll(',', '.'));
    if (weight == null || !weight.isFinite || weight < 20 || weight > 500) {
      setState(() =>
          _error = 'Enter your scale weight for this entry in kilograms.');
      return;
    }
    final owner = await CacheScope.userId();
    if (!mounted) return;
    setState(() {
      _processing = true;
      _analysis = false;
      _error = null;
    });
    try {
      await BodyAssessmentRepository.shared.save({
        'recordedDate': CacheScope.todayKey(_date),
        'utcOffsetMinutes': DateTime.now().timeZoneOffset.inMinutes,
        'savePhotos': true,
        'metrics': {
          'weightKg': {
            'value': weight,
            'source': _weightChanged || widget.profileWeight == null
                ? 'scale'
                : 'profile'
          }
        },
        'photos': [
          for (final item in _photos.entries)
            {
              'view': item.key,
              'base64': base64Encode(item.value),
              'mimeType': item.value[0] == 137 ? 'image/png' : 'image/jpeg'
            }
        ],
      });
      final currentOwner = await CacheScope.userId();
      if (mounted && currentOwner == owner) {
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
            title: const FitnessText('Estimate from photos',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600))),
        body: SafeArea(
            top: false,
            child: Column(children: [
              Expanded(
                  child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      children: [
                    const FitnessText('Four views. One baseline.',
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -.7)),
                    const SizedBox(height: 8),
                    const FitnessText(
                        'Full body in frame. Level camera. Fitted clothing. Keep arms away from your torso, gently behind you in side views.',
                        style: TextStyle(
                            fontSize: 13,
                            color: FitnessTheme.muted,
                            height: 1.5)),
                    const SizedBox(height: 18),
                    GridView.count(
                        crossAxisCount: 2,
                        childAspectRatio: .85,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          for (final view in ['front', 'back', 'left', 'right'])
                            Material(
                                color: FitnessTheme.surface,
                                borderRadius: BorderRadius.circular(18),
                                child: InkWell(
                                    onTap:
                                        _processing ? null : () => _pick(view),
                                    borderRadius: BorderRadius.circular(18),
                                    child: Column(children: [
                                      Expanded(
                                          child: _photos[view] != null
                                              ? ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  child: Image.memory(
                                                      _photos[view]!,
                                                      fit: BoxFit.contain))
                                              : const Center(
                                                  child: Icon(
                                                      CupertinoIcons.camera,
                                                      size: 27,
                                                      color:
                                                          FitnessTheme.muted))),
                                      Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: FitnessText(
                                              '${view[0].toUpperCase()}${view.substring(1)}',
                                              style: const TextStyle(
                                                  fontSize: 13))),
                                    ]))),
                        ]),
                    const SizedBox(height: 16),
                    if (widget.profileHeight != null)
                      Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: FitnessText(
                              'Height from onboarding: ${widget.profileHeight} cm',
                              style: const TextStyle(
                                  fontSize: 12, color: FitnessTheme.muted))),
                    TextField(
                        controller: _weight,
                        enabled: !_processing,
                        onChanged: (_) => setState(() => _weightChanged = true),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                            labelText: _weightChanged
                                ? 'Current scale weight'
                                : 'Weight from onboarding',
                            hintText: widget.profileWeight?.toString(),
                            suffixText: 'kg',
                            helperText:
                                'Update if needed. Unchanged onboarding weight stays labelled as profile data.')),
                    const SizedBox(height: 8),
                    ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: FitnessText(
                            DateFormat(
                                    'MMMM d, y',
                                    Localizations.localeOf(context)
                                        .toLanguageTag())
                                .format(_date),
                            style: const TextStyle(fontSize: 14)),
                        subtitle: const FitnessText(
                            'Date these photos were taken',
                            style: TextStyle(
                                fontSize: 12, color: FitnessTheme.muted)),
                        trailing: const Icon(CupertinoIcons.calendar, size: 20),
                        onTap: _processing
                            ? null
                            : () async {
                                final date = await showDatePicker(
                                    context: context,
                                    initialDate: _date,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime.now());
                                if (date != null && mounted) {
                                  setState(() => _date = date);
                                }
                              }),
                    CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        controlAffinity: ListTileControlAffinity.leading,
                        value: _consent,
                        onChanged: _processing
                            ? null
                            : (value) => setState(() => _consent = value!),
                        title: const FitnessText('Analyze my photos',
                            style: TextStyle(fontSize: 13)),
                        subtitle: const FitnessText(
                            'I agree to FitAI and Google Gemini analyzing my photos, measurements, profile and training data for my report.',
                            style: TextStyle(
                                fontSize: 11,
                                color: FitnessTheme.muted,
                                height: 1.4))),
                    SwitchListTile.adaptive(
                        key: const ValueKey('body-save-photos'),
                        contentPadding: EdgeInsets.zero,
                        value: _savePhotos,
                        onChanged: _processing
                            ? null
                            : (value) => setState(() => _savePhotos = value),
                        title: const FitnessText('Save my progress photos',
                            style: TextStyle(fontSize: 13)),
                        subtitle: const FitnessText(
                            'Keep private photos for comparison. Delete them anytime.',
                            style: TextStyle(
                                fontSize: 11,
                                color: FitnessTheme.muted,
                                height: 1.4))),
                    if (!_savePhotos)
                      const FitnessText(
                          'FitAI keeps your report, not your uploaded photos.',
                          style: TextStyle(
                              fontSize: 11, color: FitnessTheme.muted)),
                    if (_processing)
                      FitnessCard(
                          child: Row(children: [
                        const CupertinoActivityIndicator(),
                        const SizedBox(width: 14),
                        Expanded(
                            child: FitnessText(
                                _analysis
                                    ? 'Preparing your body report…'
                                    : 'Saving your photo journal…',
                                style: const TextStyle(fontSize: 13)))
                      ])),
                    TextButton(
                        onPressed:
                            _savePhotos && _photos.length == 4 && !_processing
                                ? _saveJournal
                                : null,
                        child: const FitnessText('Save photos only',
                            style: TextStyle(fontSize: 13))),
                    const FitnessText(
                        'Turn on Save my progress photos to keep a journal without AI analysis.',
                        style: TextStyle(
                            fontSize: 11,
                            color: FitnessTheme.muted,
                            height: 1.4)),
                    if (_error != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: FitnessText(_error!,
                              style: const TextStyle(
                                  fontSize: 13, color: FitnessTheme.coral))),
                  ])),
              Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: LiquidChromeButton(
                      title: 'Estimate',
                      isLoading: _processing,
                      onPressed: _consent && _photos.length == 4 && !_processing
                          ? _review
                          : null)),
            ])),
      ));
}
