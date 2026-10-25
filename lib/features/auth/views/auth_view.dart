import '../../onboarding/viewmodels/onboarding_controller.dart';
import '../../../core/theme/ds_motion.dart';
import '../../../core/theme/fitness_theme.dart';
import '../../../core/branding/setcraft_brand.dart';
import 'dart:async';
import 'package:dio/dio.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/components/liquid_chrome_button.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/navigation/prepare_authenticated_home.dart';
import '../../../core/storage/onboarding_draft.dart';
import '../../../models/auth_models.dart';
import '../../../core/localization/fitness_text.dart';
import '../../../core/storage/secure_session_store.dart';
import '../auth_copy.dart';
import '../data/auth_repository.dart';
import '../data/social_sign_in.dart';

class AuthView extends StatefulWidget {
  final bool initialSignIn;
  final OnboardingController? controller;
  final AuthRepository? repository;
  final SocialSignIn? socialSignIn;
  final Future<Widget> Function(bool newlyRegistered)? prepareHome;
  const AuthView(
      {super.key,
      this.initialSignIn = false,
      this.controller,
      this.repository,
      this.socialSignIn,
      this.prepareHome});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  late final _repository = widget.repository ?? AuthRepository();
  late final _social = widget.socialSignIn ?? SocialSignIn();

  late bool _isSignIn = widget.initialSignIn;
  bool _isPasswordVisible = false;
  bool _isSubmitting = false;
  bool _navigating = false;
  int _credentialRevision = 0;
  _PendingAccountEntry? _pendingAccount;
  String? _errorMessage;

  AuthCopy get _copy =>
      AuthCopy.forLanguage(LanguageManager.shared.currentLanguage);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (_isSubmitting) return;
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;
    final credentialRevision = _credentialRevision;
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      setState(() => _errorMessage = _copy.invalidEmail);
      return;
    }
    if (password.length < 8) {
      setState(() => _errorMessage = _copy.shortPassword);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      if (await _resumeAccountEntry()) return;
      final previousEntry = _pendingAccount;
      if (_isSignIn || previousEntry?.newlyRegistered == true) {
        if (!_isSignIn) setState(() => _isSignIn = true);
        final auth = await _repository.signIn(email: email, password: password);
        _pendingAccount = _PendingAccountEntry(auth.user.id, credentialRevision,
            newlyRegistered: previousEntry?.owner == auth.user.id &&
                previousEntry?.newlyRegistered == true,
            profileCommitted: previousEntry?.owner == auth.user.id &&
                previousEntry?.profileCommitted == true);
        if (mounted) await _finishAccountEntry(_pendingAccount!);
        return;
      }

      await widget.controller?.flush();
      await _repository.sendOtp(email);
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      final draft = widget.controller?.draft ?? await OnboardingDraft.load();
      if (!mounted) return;
      final result = await showModalBottomSheet<AuthResponse>(
        sheetAnimationStyle: DSMotion.sheetStyle(context),
        context: context,
        useSafeArea: true,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black.withValues(alpha: 0.72),
        builder: (sheetContext) => _OtpVerificationSheet(
          email: email,
          copy: _copy,
          onResend: () => _repository.sendOtp(email),
          onVerifyOtp: (otp) => _repository.verifyOtp(email: email, otp: otp),
          onRegister: () async {
            await widget.controller?.flush();
            final auth = await _repository.registerVerifiedEmail(
              email: email,
              password: password,
              draft: draft,
            );
            widget.controller?.finish();
            return auth;
          },
        ),
      );
      if (result != null && mounted) {
        _pendingAccount = _PendingAccountEntry(
            result.user.id, credentialRevision,
            newlyRegistered: true, profileCommitted: true);
        await _finishAccountEntry(_pendingAccount!);
      }
    } catch (error) {
      _invalidateEntrySession(error);
      if (mounted) {
        setState(() => _errorMessage = AuthRepository.messageFor(error));
      }
    } finally {
      if (mounted && _isSubmitting && !_navigating) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _credentialsChanged(String _) {
    _credentialRevision++;
    _pendingAccount = null;
  }

  Future<bool> _resumeAccountEntry({SocialProvider? provider}) async {
    final pending = _pendingAccount;
    if (pending == null ||
        pending.requiresAuthentication ||
        pending.provider != provider ||
        pending.credentialRevision != _credentialRevision ||
        await SecureSessionStore.shared.userId != pending.owner ||
        (await SecureSessionStore.shared.accessToken)?.isNotEmpty != true) {
      return false;
    }
    await _finishAccountEntry(pending);
    return true;
  }

  Future<void> _finishAccountEntry(_PendingAccountEntry pending) async {
    if (await SecureSessionStore.shared.userId != pending.owner) {
      throw const AuthFlowException(
          'Your session changed. Please sign in again.');
    }
    if (!pending.profileCommitted && widget.controller != null) {
      await widget.controller!.flush();
      await _repository.completeMissingProfile(widget.controller!.draft);
      widget.controller!.finish();
    }
    pending.profileCommitted = true;
    if (mounted) await _openApp(newlyRegistered: pending.newlyRegistered);
  }

  void _invalidateEntrySession(Object error) {
    if (error is DioException && error.response?.statusCode == 401) {
      _pendingAccount?.requiresAuthentication = true;
    }
  }

  Future<void> _openApp({bool newlyRegistered = false}) async {
    setState(() => _isSubmitting = true);
    final destination = await (widget.prepareHome?.call(newlyRegistered) ??
        prepareAuthenticatedHome(
            newlyRegistered: newlyRegistered, auth: _repository));
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil<void>(
      OnboardingPageRoute<void>(page: destination),
      (route) => false,
    );
    _navigating = true;
  }

  void _toggleMode() {
    setState(() {
      _isSignIn = !_isSignIn;
      _pendingAccount = null;
      _errorMessage = null;
    });
  }

  Future<void> _continueWithProvider(SocialProvider provider) async {
    if (_isSubmitting || !_social.available(provider)) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      if (await _resumeAccountEntry(provider: provider)) return;
      final token = await _social.authenticate(provider);
      if (token == null || !mounted) return;
      final auth = await _repository.exchangeSocialToken(token);
      _pendingAccount = _PendingAccountEntry(auth.user.id, _credentialRevision,
          provider: provider);
      if (mounted) await _finishAccountEntry(_pendingAccount!);
    } catch (error) {
      _invalidateEntrySession(error);
      if (mounted) {
        setState(() => _errorMessage = error is StateError
            ? 'Sign-in is unavailable right now — continue with email'
            : AuthRepository.messageFor(error));
      }
    } finally {
      if (mounted && !_navigating) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = _copy;
    final apple = _social.available(SocialProvider.apple);
    final google = _social.available(SocialProvider.google);
    return FitnessTheme(
        child: AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: PopScope(
          canPop: !_isSubmitting,
          child: Scaffold(
            backgroundColor: Colors.black,
            resizeToAvoidBottomInset: false,
            body: Stack(fit: StackFit.expand, children: [
              const ColoredBox(
                  key: ValueKey('auth-background'), color: Colors.black),
              SafeArea(
                  child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.viewInsetsOf(context).bottom),
                child: Column(children: [
                  Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                          padding: const EdgeInsets.only(left: 12, top: 4),
                          child: IconButton(
                              tooltip: MaterialLocalizations.of(context)
                                  .backButtonTooltip,
                              onPressed: _isSubmitting
                                  ? null
                                  : () => Navigator.of(context).maybePop(),
                              icon: const Icon(Icons.arrow_back_rounded,
                                  color: Colors.white)))),
                  Expanded(
                      child: LayoutBuilder(
                          builder: (context, constraints) =>
                              SingleChildScrollView(
                                keyboardDismissBehavior:
                                    ScrollViewKeyboardDismissBehavior.onDrag,
                                padding:
                                    const EdgeInsets.fromLTRB(24, 16, 24, 24),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                      minHeight: (constraints.maxHeight - 40)
                                          .clamp(0, double.infinity)),
                                  child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              ExcludeSemantics(
                                                  child:
                                                      SetcraftMark(size: 34)),
                                              SizedBox(width: 9),
                                              Text('SETCRAFT',
                                                  textScaler:
                                                      TextScaler.noScaling,
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: Colors.white,
                                                      letterSpacing: 2.6)),
                                            ]),
                                        const SizedBox(height: 30),
                                        Text(copy.title(_isSignIn),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                                fontSize: 30,
                                                height: 1.15,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: -.9,
                                                color: Colors.white)),
                                        const SizedBox(height: 10),
                                        const FitnessText(
                                            'Your plan, your progress, together',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: 13,
                                                height: 1.5,
                                                color: Color(0xFF999999))),
                                        const SizedBox(height: 30),
                                        AutofillGroup(
                                            child: Column(children: [
                                          _LuxuryEmailField(
                                              controller: _emailController,
                                              focusNode: _emailFocus,
                                              readOnly: _isSubmitting,
                                              onChanged: _credentialsChanged,
                                              label: copy.email,
                                              onSubmitted: (_) => _passwordFocus
                                                  .requestFocus()),
                                          const SizedBox(height: 12),
                                          _LuxuryPasswordField(
                                              controller: _passwordController,
                                              focusNode: _passwordFocus,
                                              readOnly: _isSubmitting,
                                              onChanged: _credentialsChanged,
                                              label: copy.password,
                                              hint: copy.passwordHint,
                                              isSignIn: _isSignIn,
                                              isPasswordVisible:
                                                  _isPasswordVisible,
                                              onToggleVisibility: () =>
                                                  setState(() =>
                                                      _isPasswordVisible =
                                                          !_isPasswordVisible),
                                              onSubmitted: (_) => _continue()),
                                        ])),
                                        const SizedBox(height: 20),
                                        if (_errorMessage != null) ...[
                                          Semantics(
                                              liveRegion: true,
                                              child: _InlineError(
                                                  message: _errorMessage!)),
                                          const SizedBox(height: 14),
                                        ],
                                        LiquidChromeButton(
                                            title: _isSubmitting
                                                ? (_isSignIn
                                                    ? 'Signing in'
                                                    : 'Creating account')
                                                : _isSignIn
                                                    ? 'Sign in'
                                                    : LanguageManager
                                                        .shared
                                                        .currentLanguage
                                                        .continueButtonTitle,
                                            solid: true,
                                            pill: true,
                                            showArrow: false,
                                            isLoading: _isSubmitting,
                                            onPressed: _isSubmitting
                                                ? null
                                                : _continue),
                                        const SizedBox(height: 12),
                                        TextButton(
                                            onPressed: _isSubmitting
                                                ? null
                                                : _toggleMode,
                                            child:
                                                _buildAuthModeSwitcher(copy)),
                                        Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 18),
                                            child: Row(children: [
                                              const Expanded(
                                                  child: Divider(
                                                      color:
                                                          Color(0xFF292929))),
                                              Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 14),
                                                  child: Text(copy.or,
                                                      style: const TextStyle(
                                                          color:
                                                              Color(0xFF777777),
                                                          fontSize: 12))),
                                              const Expanded(
                                                  child: Divider(
                                                      color:
                                                          Color(0xFF292929))),
                                            ])),
                                        Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                  child: _ProviderButton(
                                                      key: const ValueKey(
                                                          'auth-apple'),
                                                      title: copy.continueApple,
                                                      apple: true,
                                                      configured: apple,
                                                      onPressed: _isSubmitting
                                                          ? null
                                                          : () =>
                                                              _continueWithProvider(
                                                                  SocialProvider
                                                                      .apple))),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                  child: _ProviderButton(
                                                      key: const ValueKey(
                                                          'auth-google'),
                                                      title: copy
                                                          .continueGoogle,
                                                      apple: false,
                                                      configured: google,
                                                      onPressed: _isSubmitting
                                                          ? null
                                                          : () =>
                                                              _continueWithProvider(
                                                                  SocialProvider
                                                                      .google))),
                                            ]),
                                        if (!apple && !google)
                                          const Padding(
                                              padding: EdgeInsets.only(top: 12),
                                              child: FitnessText('Coming soon',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          Color(0xFF777777)))),
                                      ]),
                                ),
                              ))),
                ]),
              )),
            ]),
          )),
    ));
  }

  Widget _buildAuthModeSwitcher(AuthCopy copy) {
    final text = copy.switchPrompt(_isSignIn);
    final parts = text.split('? ');
    if (parts.length == 2) {
      return Text.rich(
        TextSpan(
          text: '${parts[0]}? ',
          style: const TextStyle(
            fontFamily: null,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.15,
            color: Color(0xFF8E8E93),
          ),
          children: [
            TextSpan(
              text: parts[1],
              style: const TextStyle(
                fontFamily: null,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.15,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    return Text(
      text,
      style: const TextStyle(
        fontFamily: null,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
        color: Colors.white,
      ),
    );
  }
}

class _PendingAccountEntry {
  final String owner;
  final int credentialRevision;
  final bool newlyRegistered;
  final SocialProvider? provider;
  bool profileCommitted;
  bool requiresAuthentication = false;
  _PendingAccountEntry(this.owner, this.credentialRevision,
      {this.newlyRegistered = false,
      this.provider,
      this.profileCommitted = false});
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton(
      {super.key,
      required this.title,
      required this.apple,
      required this.configured,
      required this.onPressed});
  final String title;
  final bool apple, configured;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Semantics(
      label: title,
      child: OutlinedButton(
        onPressed: configured ? onPressed : null,
        style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            disabledForegroundColor: const Color(0xFFA6A6A6),
            backgroundColor: const Color(0xFF111111),
            side: const BorderSide(color: Color(0xFF303030)),
            minimumSize: const Size(0, 52),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16))),
        child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              if (apple)
                const Icon(Icons.apple, size: 21)
              else
                Image.asset('assets/branding/google_g_logo.png',
                    width: 19,
                    height: 19,
                    cacheWidth: 57,
                    excludeFromSemantics: true),
              Text(apple ? 'Apple' : 'Google',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ]),
      ));
}

class _InlineError extends StatelessWidget {
  final String message;

  const _InlineError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFF201315),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFF453A).withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 18,
            color: Color(0xFFFF6961),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: null,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFFFF9E9E),
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpVerificationSheet extends StatefulWidget {
  final String email;
  final AuthCopy copy;
  final Future<void> Function() onResend;
  final Future<void> Function(String otp) onVerifyOtp;
  final Future<AuthResponse> Function() onRegister;

  const _OtpVerificationSheet({
    required this.email,
    required this.copy,
    required this.onResend,
    required this.onVerifyOtp,
    required this.onRegister,
  });

  @override
  State<_OtpVerificationSheet> createState() => _OtpVerificationSheetState();
}

class _OtpVerificationSheetState extends State<_OtpVerificationSheet> {
  final _otpController = TextEditingController();
  final _otpFocus = FocusNode();
  Timer? _resendTimer;
  int _resendSeconds = 30;
  bool _isVerifying = false;
  bool _isResending = false;
  bool _isOtpVerified = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_onCodeChanged);
    _otpFocus.addListener(_onFocusChanged);
    _startResendTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _otpFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.removeListener(_onCodeChanged);
    _otpFocus.removeListener(_onFocusChanged);
    _otpController.dispose();
    _otpFocus.dispose();
    super.dispose();
  }

  void _onCodeChanged() {
    if (mounted) {
      setState(() {
        _errorMessage = null;
        _isOtpVerified = false;
      });
    }
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _verify() async {
    final otp = _otpController.text;
    if (otp.length != 6 || _isVerifying) {
      setState(() => _errorMessage = widget.copy.enterCode);
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });
    try {
      if (!_isOtpVerified) {
        await widget.onVerifyOtp(otp);
        if (!mounted) return;
        setState(() => _isOtpVerified = true);
      }
      final auth = await widget.onRegister();
      if (mounted) Navigator.of(context).pop(auth);
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = AuthRepository.messageFor(error);
          _isVerifying = false;
        });
      }
    }
  }

  Future<void> _resend() async {
    if (_resendSeconds > 0 || _isResending || _isVerifying) return;
    setState(() {
      _isResending = true;
      _errorMessage = null;
    });
    try {
      await widget.onResend();
      _otpController.clear();
      _isOtpVerified = false;
      _startResendTimer();
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = AuthRepository.messageFor(error));
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF121316),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 0.8,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _isVerifying
                            ? null
                            : () => Navigator.of(context).pop(),
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        icon: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: Colors.white.withValues(alpha: 0.50),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Container(
                      width: 52,
                      constraints: const BoxConstraints(minHeight: 52),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                          width: 0.8,
                        ),
                      ),
                      child: const Icon(
                        Icons.mark_email_read_outlined,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.copy.otpTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.copy.codeDescription(widget.email),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.4,
                      letterSpacing: -0.15,
                    ),
                  ),
                  const SizedBox(height: 24),
                  OtpCodeField(
                    controller: _otpController,
                    focusNode: _otpFocus,
                    onSubmitted: (_) => _verify(),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    _InlineError(message: _errorMessage!),
                  ],
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed:
                          _resendSeconds == 0 && !_isResending ? _resend : null,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF8E8E93),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.15,
                        ),
                      ),
                      child: _isResending
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _resendSeconds == 0
                                  ? widget.copy.resend
                                  : widget.copy.resendCountdown(_resendSeconds),
                              style: TextStyle(
                                color: _resendSeconds == 0
                                    ? Colors.white
                                    : const Color(0xFF8E8E93),
                                fontWeight: _resendSeconds == 0
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  LiquidChromeButton(
                    title: widget.copy.verify,
                    isLoading: _isVerifying,
                    onPressed: _isVerifying ? null : _verify,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A single autofill input keeps paste/backspace working across six visible boxes.
class OtpCodeField extends StatelessWidget {
  const OtpCodeField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: Listenable.merge([controller, focusNode]),
        builder: (context, _) {
          final digits = controller.text;

          return Semantics(
            label: 'Six-digit verification code',
            child: SizedBox(
              height: 58,
              child: Stack(
                children: [
                  Row(
                    children: List.generate(6, (index) {
                      final isCurrent =
                          focusNode.hasFocus && index == digits.length;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(right: index == 5 ? 0 : 8),
                          child: AnimatedContainer(
                            duration:
                                DSMotion.duration(context, DSMotion.press),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: const Color(0xFF282828),
                              border: Border.all(
                                color: isCurrent
                                    ? Colors.white.withValues(alpha: 0.75)
                                    : Colors.white.withValues(alpha: 0.28),
                                width: isCurrent ? 1.2 : 0.8,
                              ),
                            ),
                            child: Text(
                              index < digits.length ? digits[index] : '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  Positioned.fill(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      showCursor: false,
                      style: const TextStyle(color: Colors.transparent),
                      onSubmitted: onSubmitted,
                      decoration: const InputDecoration(
                        counterText: '',
                        filled: false,
                        fillColor: Colors.transparent,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        errorBorder: InputBorder.none,
                        focusedErrorBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
}

class _LuxuryEmailField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  const _LuxuryEmailField(
      {required this.controller,
      required this.focusNode,
      required this.label,
      this.onSubmitted,
      this.onChanged,
      this.readOnly = false});
  @override
  Widget build(BuildContext context) => TextField(
        key: const ValueKey('auth-email'),
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.username, AutofillHints.email],
        autocorrect: false,
        enableSuggestions: false,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        readOnly: readOnly,
        style: const TextStyle(fontSize: 16, color: Colors.white),
        decoration: _authDecoration(label),
      );
}

class _LuxuryPasswordField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label, hint;
  final bool isSignIn, isPasswordVisible;
  final VoidCallback onToggleVisibility;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  const _LuxuryPasswordField(
      {required this.controller,
      required this.focusNode,
      required this.label,
      required this.hint,
      required this.isSignIn,
      required this.isPasswordVisible,
      required this.onToggleVisibility,
      this.onSubmitted,
      this.onChanged,
      this.readOnly = false});
  @override
  Widget build(BuildContext context) => TextField(
        key: const ValueKey('auth-password'),
        controller: controller,
        focusNode: focusNode,
        obscureText: !isPasswordVisible,
        textInputAction: TextInputAction.done,
        autofillHints: [
          isSignIn ? AutofillHints.password : AutofillHints.newPassword
        ],
        autocorrect: false,
        enableSuggestions: false,
        onSubmitted: onSubmitted,
        onChanged: onChanged,
        readOnly: readOnly,
        style: const TextStyle(fontSize: 16, color: Colors.white),
        decoration: _authDecoration(label).copyWith(
            helperText: isSignIn ? null : hint,
            helperMaxLines: 3,
            helperStyle:
                const TextStyle(color: Color(0xFF969696), fontSize: 11),
            suffixIcon: IconButton(
                tooltip: isPasswordVisible ? 'Hide password' : 'Show password',
                onPressed: onToggleVisibility,
                icon: Icon(
                    isPasswordVisible
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: const Color(0xFFA8A8A8),
                    size: 21))),
      );
}

InputDecoration _authDecoration(String label) => InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFF181818),
      labelStyle: const TextStyle(color: Color(0xFFA0A0A0), fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 19),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Color(0xFF343434))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(17),
          borderSide: const BorderSide(color: Color(0xFFD8D8D8))),
    );
