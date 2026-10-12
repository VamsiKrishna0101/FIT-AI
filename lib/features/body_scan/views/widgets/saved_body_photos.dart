import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../../core/localization/fitness_text.dart';
import '../../../../core/navigation/onboarding_page_route.dart';
import '../../../../core/theme/fitness_theme.dart';
import '../../models/body_assessment_models.dart';
import '../body_record_view.dart';
import 'private_body_photo.dart';

class SavedBodyPhotos extends StatelessWidget {
  final BodyAssessment entry;
  final VoidCallback? onDelete;
  const SavedBodyPhotos({super.key, required this.entry, this.onDelete});
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const FitnessText('Saved photos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: .65,
            children: [
              for (final photo in entry.photos)
                Column(children: [
                  Expanded(
                      child: GestureDetector(
                          onTap: () => Navigator.of(context).push(
                              AppPageRoute<void>(
                                  page: BodyPhotoViewer(photo: photo))),
                          child: PrivateBodyPhoto(
                              key: ValueKey(photo.id), photo: photo))),
                  const SizedBox(height: 6),
                  FitnessText(photo.view,
                      style: const TextStyle(
                          fontSize: 11, color: FitnessTheme.muted)),
                ])
            ]),
        const SizedBox(height: 8),
        TextButton.icon(
            onPressed: onDelete,
            icon: const Icon(CupertinoIcons.trash, size: 15),
            label: const FitnessText('Delete photos · Keep report',
                style: TextStyle(fontSize: 12))),
      ]);
}
