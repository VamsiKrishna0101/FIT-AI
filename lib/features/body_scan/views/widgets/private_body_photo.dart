import 'package:fitai_mobile/core/localization/fitness_copy.dart';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/cache/cache_scope.dart';
import '../../../../core/theme/fitness_theme.dart';
import '../../models/body_assessment_models.dart';
import '../../repositories/body_assessment_repository.dart';

class PrivateBodyPhoto extends StatefulWidget {
  final BodyPhoto photo;
  final BoxFit fit;
  const PrivateBodyPhoto(
      {super.key, required this.photo, this.fit = BoxFit.contain});
  @override
  State<PrivateBodyPhoto> createState() => _PrivateBodyPhotoState();
}

class _PrivateBodyPhotoState extends State<PrivateBodyPhoto> {
  late Future<Uint8List> _image;
  Future<Uint8List> _load() async {
    final user = await CacheScope.userId();
    final bytes = await BodyAssessmentRepository.shared.photo(widget.photo.url);
    if (await CacheScope.userId() != user) throw StateError('Session changed');
    return bytes;
  }

  @override
  void initState() {
    super.initState();
    _image = _load();
  }

  @override
  void didUpdateWidget(PrivateBodyPhoto old) {
    super.didUpdateWidget(old);
    if (old.photo.id != widget.photo.id) _image = _load();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Uint8List>(
      future: _image,
      builder: (context, snapshot) => Container(
            decoration: BoxDecoration(
                color: FitnessTheme.surface,
                borderRadius: BorderRadius.circular(16)),
            child: snapshot.connectionState == ConnectionState.done &&
                    snapshot.hasData
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(snapshot.data!,
                        fit: widget.fit,
                        gaplessPlayback: false,
                        errorBuilder: (_, __, ___) => const Center(
                            child: Icon(Icons.broken_image_outlined,
                                color: FitnessTheme.muted))))
                : snapshot.hasError
                    ? Center(
                        child: IconButton(
                            tooltip: fitnessText(context, 'Retry photo'),
                            onPressed: () => setState(() => _image = _load()),
                            icon: const Icon(Icons.refresh,
                                color: FitnessTheme.muted)))
                    : const Center(
                        child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 1.5, color: FitnessTheme.silver))),
          ));
}
