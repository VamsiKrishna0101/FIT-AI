# Apple and Google sign-in setup

The screen and native/server exchange are prepared. Both providers are disabled
by default and clearly labelled Coming soon. Email sign-in remains available.
No provider IDs, private keys or fabricated callbacks are included.

## Before enabling

1. Use one Firebase project for mobile and backend. Enable Google and Apple in
   Firebase Authentication. Configure the project's authorized domains.
2. Register the real Android application ID and debug/release SHA fingerprints.
   Download the updated `android/app/google-services.json` with its OAuth clients.
   Obtain the **Web** OAuth client ID for the server client ID build define.
3. For Apple, configure the Apple developer App ID, Sign in with Apple capability,
   Service ID and Firebase-provided return URL. Put Apple Team ID, Key ID and
   private key in Firebase console, never in Flutter source or build defines.
4. For iOS, add the correct `GoogleService-Info.plist`, Google reversed-client-ID
   URL scheme and Sign in with Apple entitlement in Xcode. No placeholder URL
   schemes or entitlements are added to this unconfigured project.
5. On backend, apply the additive `20261024120000_social_auth_identity` migration
   with the normal deployment process, generate Prisma client, configure the
   Firebase Admin service account, and set `SOCIAL_AUTH_ENABLED=true`.
   This task generated the local client but did **not** migrate the database.
6. Build Flutter with only the providers actually configured:

   ```powershell
   flutter build apk --dart-define=SETCRAFT_GOOGLE_SIGN_IN=true --dart-define=SETCRAFT_GOOGLE_SERVER_CLIENT_ID=<web-oauth-client-id> --dart-define=SETCRAFT_APPLE_SIGN_IN=true
   ```

   iOS also accepts `SETCRAFT_GOOGLE_IOS_CLIENT_ID`. These IDs are public config;
   server credentials and Apple private keys must never be build defines.

## Session behavior

The native provider signs in through Firebase and returns a Firebase ID token.
`POST /api/auth/social` verifies the token with Firebase Admin including
revocation, accepts only Google/Apple and requires recent authentication.
The Firebase UID maps to `AuthIdentity`; new accounts require a verified email.
Tokens are never stored in this table. The endpoint issues the usual Setcraft
JWT session; profile completion and subscription gates still apply. It cannot
grant a trial or bypass the paywall. Firebase's temporary session is signed out.

A new provider is **never** silently linked by email. Existing email-account
owners get a clear instruction to use email sign-in. Account linking is outside
this rollout and needs a separate authenticated confirmation flow later.

The endpoint is default-off, uses strict Redis rate limiting (20 attempts per
IP per 15 minutes), bounds token input and returns `Cache-Control: no-store`.
No contact, calendar or extra Google API scopes are requested.

Before release, test both providers on real devices with cancellation, offline
errors, revoked tokens, existing email accounts, Apple private relay email and
returning users. Provider sign-in cannot be live-tested without configuration.

References: [Firebase Flutter providers](https://firebase.google.com/docs/auth/flutter/federated-auth),
[server token verification](https://firebase.google.com/docs/auth/admin/verify-id-tokens),
[official Google plugin setup](https://pub.dev/packages/google_sign_in).

## Sign-in appearance and performance

The final screen uses a pure black background, the existing vector Setcraft mark,
a compact centered heading, visible email fields, a silver sign-in action and
small Apple/Google options below the form.
There is no background photograph or decorative animation. The only image is
Google's tiny existing brand logo. No video, live blur, repeating ticker, network
image or authentication SDK initialization runs while displaying the screen.
The unused portrait WebP was removed from app assets; its original generated
PNG remains in Codex generated images, outside the app.

The final layout presents email/password immediately. The heading is 30 px and
the form is centered as one compact group; provider buttons share a small row
below the primary action. It does not require a separate email-selection step.
`auth_entry_redesign_test.dart` verifies unconfigured-provider state, cancellation,
input validation, password visibility, no background imagery/blur/tickers,
and narrow screens with enlarged text and the keyboard. Its six checks passed
after the final refinement. The preceding onboarding regression run passed all
37 checks. Backend TypeScript build, social identity security checks and session
refresh checks passed without database writes. Real provider login still needs
the configuration and device checks described above.
