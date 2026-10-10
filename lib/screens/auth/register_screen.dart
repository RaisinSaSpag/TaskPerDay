import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../services/auth_service.dart';
import '../../utils/constants.dart';
import '../../widgets/glassmorphic_card.dart';
import '../../widgets/gradient_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _passwordVisible = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await AuthService.instance.register(
        fullName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.home,
        (_) => false,
        arguments: user,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error is AuthException
          ? error.message
          : 'Unable to create your account. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.background, Color(0xFF111C32)],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const _RegisterBrandMark(),
                      const SizedBox(height: 26),
                      GlassmorphicCard(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Create your account',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 20),
                              TextFormField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                autofillHints: const [AutofillHints.name],
                                decoration: const InputDecoration(
                                  labelText: 'Full name',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (value) =>
                                    (value?.trim().isNotEmpty ?? false)
                                        ? null
                                        : 'Enter your full name',
                              ),
                              const SizedBox(height: 13),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(Icons.mail_outline),
                                ),
                                validator: (value) {
                                  final email = value?.trim() ?? '';
                                  return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                                          .hasMatch(email)
                                      ? null
                                      : 'Enter a valid email address';
                                },
                              ),
                              const SizedBox(height: 13),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: !_passwordVisible,
                                autofillHints: const [
                                  AutofillHints.newPassword
                                ],
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon:
                                      const Icon(Icons.lock_outline_rounded),
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(() =>
                                        _passwordVisible = !_passwordVisible),
                                    icon: Icon(_passwordVisible
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined),
                                  ),
                                ),
                                validator: (value) => (value?.length ?? 0) >= 8
                                    ? null
                                    : 'Use at least 8 characters',
                              ),
                              const SizedBox(height: 13),
                              TextFormField(
                                controller: _confirmController,
                                obscureText: !_passwordVisible,
                                decoration: const InputDecoration(
                                  labelText: 'Confirm password',
                                  prefixIcon: Icon(Icons.lock_outline_rounded),
                                ),
                                validator: (value) =>
                                    value == _passwordController.text
                                        ? null
                                        : 'Passwords do not match',
                                onFieldSubmitted: (_) => _register(),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 13),
                                Text(_error!,
                                    style: const TextStyle(
                                        color: AppColors.danger)),
                              ],
                              const SizedBox(height: 20),
                              GradientButton(
                                label: 'Create Account',
                                onPressed: _register,
                                isLoading: _loading,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, AppRoutes.login),
                        child: const Text.rich(
                          TextSpan(
                            style: TextStyle(color: AppColors.textSecondary),
                            children: [
                              TextSpan(text: 'Already have an account? '),
                              TextSpan(
                                text: 'Log In',
                                style: TextStyle(
                                  color: AppColors.accentTeal,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _RegisterBrandMark extends StatelessWidget {
  const _RegisterBrandMark();

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.primaryBlue, AppColors.accentTeal]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Text('3',
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ),
          const SizedBox(height: 12),
          Text(AppStrings.appName,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      );
}
