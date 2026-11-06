import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../../core/cache/cache_scope.dart';
import '../../../core/localization/fitness_copy.dart';
import '../../../core/theme/ds_colors.dart';
import '../../train/repositories/training_repository.dart';
import '../repositories/progress_photo_repository.dart';

String _copy(BuildContext context, String text) => fitnessText(context, text);
ThemeData _photoTheme(BuildContext context) => Theme.of(context).copyWith(
    colorScheme: Theme.of(context).colorScheme.copyWith(
        primary: DSColors.silver,
        onPrimary: DSColors.bg,
        secondary: DSColors.silver,
        onSecondary: DSColors.bg),
    textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: DSColors.silver)),
    progressIndicatorTheme:
        const ProgressIndicatorThemeData(color: DSColors.silver));
String _date(BuildContext context, String date) =>
    DateFormat.MMMd(Localizations.localeOf(context).toLanguageTag())
        .format(DateTime.parse(date));

Future<bool> showProgressPhotoCapture(BuildContext context,
    {String? workoutDate, bool afterWorkout = false}) async {
  return await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: DSColors.bgElevated,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              side: BorderSide(color: DSColors.border)),
          builder: (_) => Theme(
              data: _photoTheme(context),
              child: _PhotoCapture(
                  workoutDate: workoutDate, afterWorkout: afterWorkout))) ??
      false;
}

class _PhotoCapture extends StatefulWidget {
  final String? workoutDate;
  final bool afterWorkout;
  const _PhotoCapture({this.workoutDate, required this.afterWorkout});
  @override
  State<_PhotoCapture> createState() => _PhotoCaptureState();
}

class _PhotoCaptureState extends State<_PhotoCapture> {
  final _owner = CacheScope.userId();
  Uint8List? _bytes;
  String _id = ProgressPhotoRepository.uploadId();
  bool _busy = false;
  String? _error;
  late final String _date = CacheScope.todayKey();

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await ImagePicker().pickImage(
          source: source,
          maxWidth: 1440,
          maxHeight: 1800,
          imageQuality: 82,
          requestFullMetadata: false);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (bytes.length > 2000000) {
        throw StateError('Choose a photo under 2 MB.');
      }
      if (mounted) {
        setState(() {
          _bytes = bytes;
          _id = ProgressPhotoRepository.uploadId();
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error =
            'Could not open this photo. Check camera or photo permissions and try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ProgressPhotoRepository.shared.save(_bytes!,
          id: _id,
          date: _date,
          workoutDate: widget.workoutDate,
          expectedOwner: await _owner);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final message = _copy(context, 'Progress photo saved.');
      Navigator.pop(context, true);
      messenger.showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (mounted) {
        setState(() => _error = TrainingRepository.errorMessage(error,
            'Your photo could not be saved. Your workout is saved. Try again.'));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: !_busy,
      child: SafeArea(
          child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                  child: Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                          color: DSColors.borderHi,
                          borderRadius: BorderRadius.circular(4)))),
              const SizedBox(height: 28),
              const Icon(CupertinoIcons.camera,
                  size: 32, color: DSColors.silver),
              const SizedBox(height: 18),
              Text(
                  _copy(
                      context,
                      _bytes != null
                          ? 'A moment worth keeping.'
                          : widget.afterWorkout
                              ? 'Your effort. Captured.'
                              : 'Capture your progress.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -.7,
                      color: DSColors.textPrimary)),
              const SizedBox(height: 10),
              Text(
                  _copy(
                      context,
                      _bytes != null
                          ? 'Save this photo to your progress journal.'
                          : widget.afterWorkout
                              ? 'Add a photo now, or later from Today → Update your stats.'
                              : 'Small changes add up. Give yourself something to look back on.'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, height: 1.5, color: DSColors.muted)),
              const SizedBox(height: 24),
              if (_bytes != null) ...[
                ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.memory(_bytes!,
                        height: 260, fit: BoxFit.contain)),
                const SizedBox(height: 20),
              ],
              if (_error != null)
                Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(_copy(context, _error!),
                        style: const TextStyle(
                            color: DSColors.silver, height: 1.4))),
              FilledButton(
                  onPressed: _busy
                      ? null
                      : _bytes != null
                          ? _save
                          : () => _pick(ImageSource.camera),
                  style: FilledButton.styleFrom(
                      backgroundColor: DSColors.silver,
                      foregroundColor: DSColors.bg,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                  child: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: DSColors.bg))
                      : Text(_copy(context,
                          _bytes != null ? 'Save photo' : 'Take a photo'))),
              TextButton(
                  style: TextButton.styleFrom(foregroundColor: DSColors.silver),
                  onPressed: _busy
                      ? null
                      : () => _pick(_bytes == null
                          ? ImageSource.gallery
                          : ImageSource.camera),
                  child: Text(
                      _copy(context,
                          _bytes == null ? 'Choose from library' : 'Retake'),
                      style: const TextStyle(color: DSColors.silver))),
              TextButton(
                  style: TextButton.styleFrom(foregroundColor: DSColors.silver),
                  onPressed: _busy ? null : () => Navigator.pop(context),
                  child: Text(_copy(context, 'Maybe later'),
                      style: const TextStyle(color: DSColors.muted))),
            ]),
      )));
}

class ProgressPhotoShelf extends StatefulWidget {
  final bool isActive;
  final int refreshVersion;
  const ProgressPhotoShelf(
      {super.key, this.isActive = true, this.refreshVersion = 0});
  @override
  State<ProgressPhotoShelf> createState() => _ProgressPhotoShelfState();
}

class _ProgressPhotoShelfState extends State<ProgressPhotoShelf> {
  List<ProgressPhoto> _photos = [];
  bool _failed = false;
  StreamSubscription<void>? _changes;
  int _request = 0;
  @override
  void initState() {
    super.initState();
    _changes = ProgressPhotoRepository.shared.changes.stream.listen((_) {
      if (widget.isActive) unawaited(_load());
    });
    if (widget.isActive) unawaited(_load());
  }

  @override
  void didUpdateWidget(ProgressPhotoShelf oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive &&
        (!oldWidget.isActive ||
            oldWidget.refreshVersion != widget.refreshVersion)) {
      unawaited(
          _load(refresh: oldWidget.refreshVersion != widget.refreshVersion));
    }
  }

  Future<void> _load({bool refresh = false}) async {
    final request = ++_request;
    try {
      final page = await ProgressPhotoRepository.shared.load(refresh: refresh);
      if (mounted && request == _request) {
        setState(() {
          _photos = page.photos;
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted && request == _request) {
        setState(() {
          _failed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _changes?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_photos.isEmpty) return const SizedBox.shrink();
    return Padding(
        key: const ValueKey('progress-photo-shelf'),
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Expanded(
                    child: InkWell(
                        onTap: () async {
                          await Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const ProgressPhotoGallery()));
                          if (mounted) unawaited(_load());
                        },
                        child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(children: [
                              Flexible(
                                  child: Text(_copy(context, 'Progress photos'),
                                      style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w500,
                                          color: DSColors.textPrimary,
                                          letterSpacing: -.3))),
                              const SizedBox(width: 6),
                              const Icon(CupertinoIcons.chevron_right,
                                  size: 11, color: DSColors.muted),
                            ])))),
                if (_failed)
                  IconButton(
                      tooltip: _copy(context, 'Retry'),
                      onPressed: () => _load(refresh: true),
                      icon: const Icon(CupertinoIcons.arrow_clockwise,
                          size: 18, color: DSColors.silver)),
                IconButton(
                    tooltip: _copy(context, 'Add progress photo'),
                    onPressed: () => showProgressPhotoCapture(context),
                    icon: const Icon(CupertinoIcons.plus,
                        color: DSColors.silver, size: 20)),
              ]),
              const SizedBox(height: 6),
              SizedBox(
                  height: 112,
                  child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _photos.length.clamp(0, 8),
                      separatorBuilder: (_, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) => SizedBox(
                          width: 84,
                          child: _PhotoTile(
                              photo: _photos[index],
                              onTap: () async {
                                await _openPhoto(context, _photos[index]);
                                if (mounted) unawaited(_load());
                              })))),
            ]));
  }
}

class _PhotoTile extends StatelessWidget {
  final ProgressPhoto photo;
  final VoidCallback onTap;
  const _PhotoTile({required this.photo, required this.onTap});
  @override
  Widget build(BuildContext context) => Semantics(
      label:
          '${_copy(context, 'Progress photo')}, ${_date(context, photo.date)}',
      button: true,
      child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Material(
              color: DSColors.bgCard,
              child: InkWell(
                  onTap: onTap,
                  child: Stack(fit: StackFit.expand, children: [
                    Image.network(photo.thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, error, stack) => const Icon(
                            CupertinoIcons.photo,
                            color: DSColors.muted)),
                    const DecoratedBox(
                        decoration: BoxDecoration(
                            gradient: LinearGradient(
                                begin: Alignment.center,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black87]))),
                    Positioned(
                        left: 12,
                        bottom: 12,
                        child: Text(_date(context, photo.date),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600))),
                  ])))));
}

class ProgressPhotoGallery extends StatefulWidget {
  const ProgressPhotoGallery({super.key});
  @override
  State<ProgressPhotoGallery> createState() => _ProgressPhotoGalleryState();
}

class _ProgressPhotoGalleryState extends State<ProgressPhotoGallery> {
  final List<ProgressPhoto> _photos = [];
  String? _cursor;
  bool _loading = false, _failed = false, _hasMore = true;
  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load({bool refresh = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final page = await ProgressPhotoRepository.shared
          .load(cursor: refresh ? null : _cursor, refresh: refresh);
      if (mounted) {
        setState(() {
          if (refresh) _photos.clear();
          _photos.addAll(page.photos);
          _cursor = page.nextCursor;
          _hasMore = _cursor != null;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: DSColors.bg,
      appBar: AppBar(
          backgroundColor: DSColors.bg,
          foregroundColor: DSColors.silver,
          title: Text(_copy(context, 'Progress photos')),
          actions: [
            IconButton(
                tooltip: _copy(context, 'Add progress photo'),
                icon: const Icon(CupertinoIcons.plus),
                onPressed: () async {
                  final saved = await showProgressPhotoCapture(context);
                  if (mounted && saved) unawaited(_load(refresh: true));
                })
          ]),
      body: RefreshIndicator(
          onRefresh: () => _load(refresh: true),
          child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                    padding: const EdgeInsets.all(18),
                    sliver: SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: .75,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12),
                        delegate: SliverChildBuilderDelegate(
                            (context, index) => _PhotoTile(
                                photo: _photos[index],
                                onTap: () async {
                                  final deleted =
                                      await _openPhoto(context, _photos[index]);
                                  if (mounted && deleted) {
                                    setState(() => _photos.removeAt(index));
                                  }
                                }),
                            childCount: _photos.length))),
                SliverToBoxAdapter(
                    child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                            child: _loading
                                ? const CupertinoActivityIndicator()
                                : _failed
                                    ? TextButton(
                                        style: TextButton.styleFrom(
                                            foregroundColor: DSColors.silver),
                                        onPressed: _load,
                                        child: Text(_copy(context, 'Retry')))
                                    : _photos.isEmpty
                                        ? Text(
                                            _copy(context,
                                                'Your journey starts here'),
                                            style: const TextStyle(
                                                color: DSColors.muted))
                                        : _hasMore
                                            ? TextButton(
                                                style: TextButton.styleFrom(
                                                    foregroundColor:
                                                        DSColors.silver),
                                                onPressed: _load,
                                                child: Text(_copy(
                                                    context, 'Load more')))
                                            : const SizedBox.shrink()))),
              ])));
}

Future<bool> _openPhoto(BuildContext context, ProgressPhoto photo) async =>
    await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => _PhotoViewer(photo: photo))) ??
    false;

class _PhotoViewer extends StatefulWidget {
  final ProgressPhoto photo;
  const _PhotoViewer({required this.photo});
  @override
  State<_PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<_PhotoViewer> {
  bool _deleting = false;
  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
                backgroundColor: DSColors.bgCard,
                title: Text(_copy(context, 'Delete progress photo?')),
                content: Text(_copy(context,
                    'This photo will be permanently removed from your journal.')),
                actions: [
                  TextButton(
                      style: TextButton.styleFrom(
                          foregroundColor: DSColors.silver),
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(_copy(context, 'Cancel'))),
                  TextButton(
                      style: TextButton.styleFrom(
                          foregroundColor: DSColors.silver),
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(_copy(context, 'Delete'),
                          style: const TextStyle(color: DSColors.silver)))
                ]));
    if (confirmed != true || !mounted) return;
    setState(() => _deleting = true);
    try {
      await ProgressPhotoRepository.shared.delete(widget.photo.id);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() => _deleting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                _copy(context, 'Could not delete this photo. Try again.'))));
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: DSColors.bg,
      appBar: AppBar(
          backgroundColor: DSColors.bg,
          foregroundColor: DSColors.silver,
          title: Text(_date(context, widget.photo.date)),
          actions: [
            IconButton(
                tooltip: _copy(context, 'Delete photo'),
                onPressed: _deleting ? null : _delete,
                icon: _deleting
                    ? const CupertinoActivityIndicator()
                    : const Icon(CupertinoIcons.trash))
          ]),
      body: Center(
          child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Image.network(widget.photo.url,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) => progress == null
                      ? child
                      : const CupertinoActivityIndicator(),
                  errorBuilder: (_, error, stack) =>
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_copy(context, 'This photo couldn’t load.'),
                            style: const TextStyle(color: DSColors.muted)),
                        TextButton(
                            style: TextButton.styleFrom(
                                foregroundColor: DSColors.silver),
                            onPressed: () => setState(() {}),
                            child: Text(_copy(context, 'Retry'))),
                      ])))));
}
