import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/components/liquid_chrome_button.dart';
import '../../../core/localization/language_manager.dart';
import '../../../core/navigation/onboarding_page_route.dart';
import '../../../core/navigation/authenticated_home.dart';
import '../../../core/storage/onboarding_draft.dart';
import '../../../models/auth_models.dart';
import '../../onboarding/components/onboarding_scaffold.dart';
import '../auth_copy.dart';
import '../data/auth_repository.dart';

class AuthView extends StatefulWidget {
  final bool initialSignIn;
  const AuthView({super.key, this.initialSignIn = false});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _repository = AuthRepository();

  late bool _isSignIn = widget.initialSignIn;
  bool _isPasswordVisible = false;
  bool _isSubmitting = false;
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
      if (_isSignIn) {
        await _repository.signIn(email: email, password: password);
        if (mounted) _openApp();
        return;
      }

      await _repository.sendOtp(email);
      if (!mounted) return;
      setState(() => _isSubmitting = false);

      final draft = await OnboardingDraft.load();
      if (!mounted) return;
      final result = await showModalBottomSheet<AuthResponse>(
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
          onRegister: () => _repository.registerVerifiedEmail(
            email: email,
            password: password,
            draft: draft,
          ),
        ),
      );
      if (result != null && mounted) _openApp(newlyRegistered: true);
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = AuthRepository.messageFor(error));
      }
    } finally {
      if (mounted && _isSubmitting) setState(() => _isSubmitting = false);
    }
  }

  void _openApp({bool newlyRegistered = false}) {
    Navigator.of(context).pushAndRemoveUntil<void>(
      OnboardingPageRoute<void>(
          page: authenticatedHome(newlyRegistered: newlyRegistered)),
      (route) => false,
    );
  }

  void _showProviderMessage() {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(_copy.comingSoon),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF222222),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  void _toggleMode() {
    setState(() {
      _isSignIn = !_isSignIn;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final copy = _copy;

    return OnboardingScaffold(
      step: 8,
      title: copy.title(_isSignIn),
      subtitle: copy.subtitle,
      actionTitle: _isSignIn
          ? copy.signInTitle
          : LanguageManager.shared.currentLanguage.continueButtonTitle,
      onBack: () => Navigator.of(context).maybePop(),
      loading: _isSubmitting,
      onContinue: _isSubmitting ? null : _continue,
      children: [
        _AppleSignInButton(
          title: copy.continueApple,
          onTap: _showProviderMessage,
        ),
        const SizedBox(height: 10),
        _GoogleSignInButton(
          title: copy.continueGoogle,
          onTap: _showProviderMessage,
        ),
        const SizedBox(height: 22),
        _OrDivider(label: copy.or),
        const SizedBox(height: 20),
        _LuxuryEmailField(
          controller: _emailController,
          focusNode: _emailFocus,
          label: copy.email,
          onSubmitted: (_) => _passwordFocus.requestFocus(),
        ),
        const SizedBox(height: 12),
        _LuxuryPasswordField(
          controller: _passwordController,
          focusNode: _passwordFocus,
          label: copy.password,
          hint: copy.passwordHint,
          isSignIn: _isSignIn,
          isPasswordVisible: _isPasswordVisible,
          onToggleVisibility: () => setState(
            () => _isPasswordVisible = !_isPasswordVisible,
          ),
          onSubmitted: (_) => _continue(),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          _InlineError(message: _errorMessage!),
        ],
        const SizedBox(height: 18),
        Center(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _isSubmitting ? null : _toggleMode,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: _buildAuthModeSwitcher(copy),
            ),
          ),
        ),
      ],
    );
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

class _AppleSignInButton extends StatefulWidget {
  final String title;
  final VoidCallback onTap;

  const _AppleSignInButton({
    required this.title,
    required this.onTap,
  });

  @override
  State<_AppleSignInButton> createState() => _AppleSignInButtonState();
}

class _AppleSignInButtonState extends State<_AppleSignInButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            // Apple frosted liquid glass
            color: const Color(0xFF202020),
            border: Border.all(
              color: _pressed
                  ? Colors.white.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.16),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.apple_rounded,
                size: 22,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Flexible(
                  child: Text(
                widget.title,
                style: const TextStyle(
                  fontFamily: null,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatefulWidget {
  final String title;
  final VoidCallback onTap;

  const _GoogleSignInButton({
    required this.title,
    required this.onTap,
  });

  @override
  State<_GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<_GoogleSignInButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            // Apple frosted liquid glass
            color: const Color(0xFF202020),
            border: Border.all(
              color: _pressed
                  ? Colors.white.withValues(alpha: 0.45)
                  : Colors.white.withValues(alpha: 0.16),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/branding/google_g_logo.png',
                width: 20,
                height: 20,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.medium,
              ),
              const SizedBox(width: 10),
              Flexible(
                  child: Text(
                widget.title,
                style: const TextStyle(
                  fontFamily: null,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  final String label;

  const _OrDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 0.8,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: null,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: Color(0xFF8E8E93),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 0.8,
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }
}

class _LuxuryEmailField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final ValueChanged<String>? onSubmitted;

  const _LuxuryEmailField({
    required this.controller,
    required this.focusNode,
    required this.label,
    this.onSubmitted,
  });

  @override
  State<_LuxuryEmailField> createState() => _LuxuryEmailFieldState();
}

class _LuxuryEmailFieldState extends State<_LuxuryEmailField> {
  bool _isFocused = false;
  bool _hasContent = false;

  @override
  void initState() {
    super.initState();
    _isFocused = widget.focusNode.hasFocus;
    _hasContent = widget.controller.text.isNotEmpty;
    widget.focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
  }

  void _onFocusChange() {
    if (mounted && _isFocused != widget.focusNode.hasFocus) {
      setState(() => _isFocused = widget.focusNode.hasFocus);
    }
  }

  void _onTextChanged() {
    final hasContent = widget.controller.text.isNotEmpty;
    if (mounted && _hasContent != hasContent) {
      setState(() => _hasContent = hasContent);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isValidEmail = _hasContent &&
        RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
            .hasMatch(widget.controller.text.trim());

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      constraints: const BoxConstraints(minHeight: 54),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        // Apple frosted liquid glass
        color: const Color(0xFF202020),
        border: Border.all(
          color: _isFocused
              ? Colors.white.withValues(alpha: 0.60)
              : Colors.white.withValues(alpha: 0.12),
          width: _isFocused ? 1.0 : 0.8,
        ),
      ),
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        autofillHints: const [AutofillHints.email],
        autocorrect: false,
        cursorColor: Colors.white,
        onSubmitted: widget.onSubmitted,
        style: const TextStyle(
          fontFamily: null,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.2,
          color: Colors.white,
        ),
        decoration: InputDecoration(
          filled: false,
          hintText: widget.label,
          hintStyle: const TextStyle(
            fontFamily: null,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.2,
            color: Color(0xFF8E8E93),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 16, right: 12),
            child: Icon(
              Icons.mail_outline_rounded,
              size: 20,
              color: _isFocused ? Colors.white : const Color(0xFF8E8E93),
            ),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 48,
            minHeight: 24,
          ),
          suffixIcon: isValidEmail
              ? const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: Color(0xFFDADADA),
                  ),
                )
              : null,
          suffixIconConstraints: const BoxConstraints(
            minWidth: 44,
            minHeight: 24,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
      ),
    );
  }
}

class _LuxuryPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final bool isSignIn;
  final bool isPasswordVisible;
  final VoidCallback onToggleVisibility;
  final ValueChanged<String>? onSubmitted;

  const _LuxuryPasswordField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.isSignIn,
    required this.isPasswordVisible,
    required this.onToggleVisibility,
    this.onSubmitted,
  });

  @override
  State<_LuxuryPasswordField> createState() => _LuxuryPasswordFieldState();
}

class _LuxuryPasswordFieldState extends State<_LuxuryPasswordField> {
  bool _isFocused = false;
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _isFocused = widget.focusNode.hasFocus;
    _charCount = widget.controller.text.length;
    widget.focusNode.addListener(_onFocusChange);
    widget.controller.addListener(_onTextChanged);
  }

  void _onFocusChange() {
    if (mounted && _isFocused != widget.focusNode.hasFocus) {
      setState(() => _isFocused = widget.focusNode.hasFocus);
    }
  }

  void _onTextChanged() {
    final len = widget.controller.text.length;
    if (mounted && _charCount != len) {
      setState(() => _charCount = len);
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meetsRequirement = _charCount >= 8;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minHeight: 54),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            // Apple frosted liquid glass
            color: const Color(0xFF202020),
            border: Border.all(
              color: _isFocused
                  ? Colors.white.withValues(alpha: 0.60)
                  : Colors.white.withValues(alpha: 0.12),
              width: _isFocused ? 1.0 : 0.8,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            obscureText: !widget.isPasswordVisible,
            textInputAction: TextInputAction.done,
            autofillHints: [
              widget.isSignIn
                  ? AutofillHints.password
                  : AutofillHints.newPassword,
            ],
            autocorrect: false,
            enableSuggestions: false,
            cursorColor: Colors.white,
            onSubmitted: widget.onSubmitted,
            style: const TextStyle(
              fontFamily: null,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.2,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              filled: false,
              hintText: widget.label,
              hintStyle: const TextStyle(
                fontFamily: null,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                letterSpacing: -0.2,
                color: Color(0xFF8E8E93),
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 16, right: 12),
                child: Icon(
                  Icons.lock_outline_rounded,
                  size: 20,
                  color: _isFocused ? Colors.white : const Color(0xFF8E8E93),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 24,
              ),
              suffixIcon: IconButton(
                tooltip: widget.isPasswordVisible
                    ? 'Hide password'
                    : 'Show password',
                splashRadius: 20,
                onPressed: () {
                  HapticFeedback.selectionClick();
                  widget.onToggleVisibility();
                },
                icon: Icon(
                  widget.isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: widget.isPasswordVisible
                      ? Colors.white
                      : const Color(0xFF8E8E93),
                ),
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 48,
                minHeight: 24,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
            ),
          ),
        ),
        if (!widget.isSignIn) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    meetsRequirement
                        ? Icons.check_circle_rounded
                        : Icons.info_outline_rounded,
                    key: ValueKey(meetsRequirement),
                    size: 13,
                    color: meetsRequirement
                        ? const Color(0xFFDADADA)
                        : const Color(0xFF8E8E93),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                    child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontFamily:
                        Theme.of(context).textTheme.bodyMedium?.fontFamily,
                    fontSize: 12,
                    fontWeight:
                        meetsRequirement ? FontWeight.w500 : FontWeight.w400,
                    color: meetsRequirement
                        ? const Color(0xFFDADADA)
                        : const Color(0xFF8E8E93),
                  ),
                  child: Text(widget.hint),
                )),
              ],
            ),
          ),
        ],
      ],
    );
  }
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
                            duration: const Duration(milliseconds: 150),
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
