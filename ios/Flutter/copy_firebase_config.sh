#!/bin/sh
set -eu

# Optional until Apple/Firebase enrollment is complete. No placeholder credentials.
firebase_config="$PROJECT_DIR/Runner/GoogleService-Info.plist"
if [ -n "${GOOGLE_SERVICE_INFO_FILE:-}" ]; then
  firebase_config="$GOOGLE_SERVICE_INFO_FILE"
fi
firebase_target="$TARGET_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/GoogleService-Info.plist"
if [ ! -f "$firebase_config" ]; then
  # Avoid retaining configuration from an earlier incremental build.
  if [ -f "$firebase_target" ]; then rm -f "$firebase_target"; fi
  echo "warning: Setcraft remote push is not configured. Local rest alerts remain available."
  exit 0
fi
firebase_bundle=$(/usr/libexec/PlistBuddy -c 'Print :BUNDLE_ID' "$firebase_config")
if [ "$firebase_bundle" != "$PRODUCT_BUNDLE_IDENTIFIER" ]; then
  echo "error: GoogleService-Info.plist must match $PRODUCT_BUNDLE_IDENTIFIER."
  exit 1
fi
cp "$firebase_config" "$firebase_target"
