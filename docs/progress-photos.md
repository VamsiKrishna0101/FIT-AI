# Progress photos

The photo journal is independent of retired AI body scans. A completed current-day workout with all exercises completed offers the capture sheet once per user/day on this device. Photos remain optional and can also be added from the workout summary or the top of Progress.

`/api/progress-photos` requires authentication for listing, creating and deleting. Creation accepts a stable client UUID (safe retry), recorded calendar date, optional workout date, and one base64 JPEG/PNG under 2 MB. The server validates and re-encodes images with Sharp, strips source metadata, and writes a full image and thumbnail to R2. Listing uses 30-photo cursor pages. Deletions use the existing durable R2 cleanup queue, including account deletion.

Configuration uses existing `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID`, `R2_SECRET_ACCESS_KEY`. Optional `R2_PROGRESS_BUCKET_NAME` overrides `R2_BODY_BUCKET_NAME` (default `fitai-body-images`). Optional `R2_PROGRESS_PUBLIC_URL` overrides the supplied public development URL. Credentials remain on the backend.

This initial delivery uses public image URLs, which anyone with the link can view. A private bucket with authenticated delivery or signed URLs is needed before promising privacy; a custom domain by itself does not make objects private.

Run `npm run generate`, `prisma migrate deploy`, and `npm run build` in the backend for deployment. `node --use-system-ca --import tsx scripts/test_progress_photos.ts` runs synthetic in-process API tests. `scripts/check_progress_photo_storage.ts` checks actual R2 upload/read/public delivery with a generated color swatch and deletes it afterward.

Flutter checks: `flutter test test/progress_photos_test.dart test/workout_session_redesign_test.dart test/progress_overview_redesign_test.dart`.
