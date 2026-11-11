/// In-app copies of the Privacy Policy and Terms of Use.
///
/// Bundled so they open instantly, work offline and never depend on the
/// website being up. Keep in sync with website/public/privacy.html and
/// website/public/terms.html whenever either changes.
library;

enum LegalBlockKind { paragraph, bullet, link }

class LegalBlock {
  final LegalBlockKind kind;
  final String text;
  final String? url;
  const LegalBlock.p(this.text)
      : kind = LegalBlockKind.paragraph,
        url = null;
  const LegalBlock.bullet(this.text)
      : kind = LegalBlockKind.bullet,
        url = null;
  const LegalBlock.link(this.text, String this.url)
      : kind = LegalBlockKind.link;
}

class LegalSection {
  final String title;
  final List<LegalBlock> blocks;
  const LegalSection(this.title, this.blocks);
}

class LegalDocument {
  final String title;
  final String updated;
  final String webUrl;
  final List<LegalSection> sections;
  const LegalDocument(
      {required this.title,
      required this.updated,
      required this.webUrl,
      required this.sections});
}

const privacyPolicy = LegalDocument(
  title: 'Privacy Policy',
  updated: 'Last updated November 10, 2026',
  webUrl: 'https://setcraft.fit/privacy.html',
  sections: [
    LegalSection('Overview', [
      LegalBlock.p(
          'Setcraft ("we", "our", or "us") provides workout tracking, training plans, nutrition planning and progress tools. We respect your privacy and are committed to protecting your personal data.'),
      LegalBlock.p(
          'This Privacy Policy explains what information we collect, how it is used, how you control it, and how it is protected when you use our apps and services.'),
    ]),
    LegalSection('Information We Collect', [
      LegalBlock.p(
          'We only collect data needed to provide and improve your fitness experience:'),
      LegalBlock.bullet(
          'Account information: your email address, name, sign-in details and account settings when you register or sign in with email, Sign in with Apple or Google Sign-In.'),
      LegalBlock.bullet(
          'Fitness and profile data: age, height, weight, goals, workout preferences, equipment, dietary preferences and allergies you enter during onboarding or in settings.'),
      LegalBlock.bullet(
          'Workout and nutrition logs: exercises, sets, reps, weights, completed workouts, meals and water you log.'),
      LegalBlock.bullet(
          'Customer support: messages and optional screenshots you send in a support or privacy request.'),
    ]),
    LegalSection('Apple Health & Health Connect', [
      LegalBlock.p(
          'With your permission, Setcraft reads and writes certain health data through Apple Health (HealthKit) on iPhone, or Health Connect on Android. We follow App Store Review Guideline 5.1.3.'),
      LegalBlock.bullet(
          'Read: steps, active calories, workouts and sleep, plus weight and body fat if you turn them on.'),
      LegalBlock.bullet(
          'Write: completed workouts and estimated active calories logged in Setcraft.'),
      LegalBlock.p('Our commitments for health data:'),
      LegalBlock.bullet(
          'We never use health data for marketing, advertising, profiling or cross-app tracking.'),
      LegalBlock.bullet(
          'We never sell or disclose health data to advertisers, data brokers or resellers.'),
      LegalBlock.bullet(
          'Health data is never shared with AI providers or AI assistants.'),
      LegalBlock.bullet(
          'You can remove access anytime in the Health app under Sharing → Apps & Services → Setcraft (or in Health Connect on Android).'),
    ]),
    LegalSection('AI Plan Generation', [
      LegalBlock.p(
          'Setcraft offers personalized AI-assisted training and nutrition suggestions. Before any data is sent, the app shows you what will be shared and with whom, and asks you to agree. Nothing is sent if you choose "Not now".'),
      LegalBlock.bullet(
          'Who receives it: OpenAI, a third-party AI service provider, through its API. If we change provider, we will ask for your consent again.'),
      LegalBlock.bullet(
          'What is shared: your training preferences, goals, equipment, food preferences and recent workout and meal logs.'),
      LegalBlock.bullet(
          'Never shared: photos, Apple Health or Health Connect data, and sensitive identity data.'),
      LegalBlock.bullet(
          'Your data is used only to create your recommendations and is never used to train public AI models.'),
      LegalBlock.bullet(
          'You can turn AI plan generation off anytime in Settings → Privacy & Data.'),
    ]),
    LegalSection('AI Assistant Connections', [
      LegalBlock.p(
          'You can optionally connect your account to an AI assistant you use, such as Claude by Anthropic, using the Model Context Protocol (MCP). This is off unless you create an access token in Settings.'),
      LegalBlock.bullet(
          'Each token is read-only and limited to the data you select: training profile, weekly workouts, workout history, nutrition and manually entered body measurements.'),
      LegalBlock.bullet(
          'Never shared: photos, health app data, email address, password and billing details.'),
      LegalBlock.bullet(
          'Data the assistant requests is sent to that assistant\'s provider (for example Anthropic) and handled under its privacy policy.'),
      LegalBlock.bullet(
          'Tokens expire after 7, 30 or 90 days and you can revoke them anytime. We keep a 30-day log of token use (tool, outcome and time, not the data returned), included in your data export.'),
    ]),
    LegalSection('Photos & Camera', [
      LegalBlock.p(
          'Setcraft asks for camera or photo access only when you take or choose a progress photo, or attach a screenshot to a support request.'),
      LegalBlock.bullet('Camera and photo access are optional.'),
      LegalBlock.bullet(
          'Your photos stay private to your account and are never shared publicly or used for AI training.'),
      LegalBlock.bullet('You can delete saved photos anytime in the app.'),
    ]),
    LegalSection('Data Retention & Deletion', [
      LegalBlock.bullet(
          'Export: download a copy of your account data anytime in Settings → Privacy & Data → Export my data.'),
      LegalBlock.bullet(
          'Delete: permanently delete your account anytime in Settings → Privacy & Data → Delete account.'),
      LegalBlock.bullet(
          'When you delete your account, your profile, logs, nutrition history, support requests, AI assistant tokens and photos are permanently removed from our active databases. If you signed in with Apple, your Sign in with Apple authorization is revoked and your sign-in identity is removed from our authentication provider.'),
      LegalBlock.bullet(
          'Deleting your account does not cancel an App Store or Google Play subscription. Manage it in your store account settings.'),
    ]),
    LegalSection('Service Providers & Security', [
      LegalBlock.p(
          'We use encryption in transit (HTTPS/TLS) and at rest. We do not sell your data and do not use it for advertising or cross-app tracking. We use these providers only to run Setcraft:'),
      LegalBlock.bullet('Supabase: database and file hosting.'),
      LegalBlock.bullet('Cloudflare: network security and delivery.'),
      LegalBlock.bullet(
          'Google Firebase: Apple and Google sign-in, and push notifications.'),
      LegalBlock.bullet(
          'RevenueCat, Apple App Store and Google Play: subscriptions. We never receive your card details.'),
      LegalBlock.bullet('OpenAI: AI plan generation, only with your consent.'),
      LegalBlock.bullet(
          'Anthropic or another AI assistant you connect: only data you allow through an access token.'),
    ]),
    LegalSection('Contact Us', [
      LegalBlock.p(
          'Questions or requests about this policy or your data? Contact us:'),
      LegalBlock.link('privacy@setcraft.fit', 'mailto:privacy@setcraft.fit'),
      LegalBlock.link('support@setcraft.fit', 'mailto:support@setcraft.fit'),
      LegalBlock.p(
          'You can also send a request in the app under Settings → Privacy & Data → Privacy question.'),
    ]),
  ],
);

const termsOfUse = LegalDocument(
  title: 'Terms of Use',
  updated: 'Last updated November 10, 2026',
  webUrl: 'https://setcraft.fit/terms.html',
  sections: [
    LegalSection('Acceptance of Terms', [
      LegalBlock.p(
          'By downloading, installing or using the Setcraft app or services, you agree to these Terms of Use and our Privacy Policy. If you do not agree, please do not use the app.'),
    ]),
    LegalSection('Fitness & Medical Disclaimer', [
      LegalBlock.p(
          'Setcraft is an informational fitness, workout tracking and nutrition tool. It is not a medical organization and does not provide medical advice, diagnosis or treatment.'),
      LegalBlock.p(
          'Always consult your physician or a qualified healthcare provider before starting a new fitness routine, diet or weight management plan. Never ignore professional medical advice because of something in the app.'),
    ]),
    LegalSection('Subscriptions & Billing', [
      LegalBlock.p(
          'Setcraft offers optional auto-renewing subscriptions ("Setcraft Premium").'),
      LegalBlock.bullet(
          'Billing: monthly or annually, as selected at purchase.'),
      LegalBlock.bullet(
          'Free trials: you are not charged during a trial. Unless cancelled at least 24 hours before it ends, the trial converts to a paid auto-renewing subscription.'),
      LegalBlock.bullet(
          'Renewal: subscriptions renew automatically unless auto-renew is turned off at least 24 hours before the current period ends. Your Apple ID or Google Play account is charged within 24 hours before the period ends.'),
      LegalBlock.bullet(
          'Manage or cancel anytime. iPhone: Settings → your name → Subscriptions. Android: Google Play → Payments & subscriptions → Subscriptions.'),
      LegalBlock.bullet(
          'Deleting the app or your Setcraft account does not cancel a store subscription. Cancel it through the App Store or Google Play.'),
    ]),
    LegalSection('Your Account', [
      LegalBlock.p(
          'You are responsible for keeping your sign-in details confidential and for providing accurate information. You can delete your account and its data anytime in Settings → Privacy & Data → Delete account.'),
    ]),
    LegalSection('Intellectual Property', [
      LegalBlock.p(
          'The Setcraft software, design, logos, exercise library, algorithms and illustrations are the property of Setcraft and protected by copyright and intellectual property laws.'),
    ]),
    LegalSection('Apple Standard EULA', [
      LegalBlock.p(
          'If you downloaded Setcraft from the Apple App Store, these Terms include and complement Apple\'s standard Licensed Application End User License Agreement.'),
      LegalBlock.link('Apple Standard EULA',
          'https://www.apple.com/legal/internet-services/itunes/dev/stdeula/'),
    ]),
    LegalSection('Contact', [
      LegalBlock.p('For questions, support or billing, contact us:'),
      LegalBlock.link('support@setcraft.fit', 'mailto:support@setcraft.fit'),
    ]),
  ],
);
