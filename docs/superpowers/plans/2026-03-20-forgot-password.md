# Forgot Password Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add "He olvidado mi contraseña" flow — email field pre-filled from LoginScreen, Firebase sends reset link, success/error feedback.

**Architecture:** New `ForgotPasswordScreen` on `/forgot-password?email=` (public GoRoute). `sendPasswordResetEmail` added to `AuthRepository` → `FirebaseAuthRepository` → `AuthNotifier`. LoginScreen pushes with current email as query param.

**Tech Stack:** Flutter, Riverpod v2 StreamNotifier, GoRouter, firebase_auth

---

### Task 1: Extend AuthRepository contract + FirebaseAuthRepository

**Files:**

- Modify: `apps/mobile/lib/features/auth/domain/repositories/auth_repository.dart:19`
- Modify: `apps/mobile/lib/features/auth/data/repositories/firebase_auth_repository.dart:71`

- [ ] Add `sendPasswordResetEmail` to abstract class after `reloadAndCheckEmailVerified`:

```dart
Future<void> sendPasswordResetEmail({required String email});
```

- [ ] Implement in `FirebaseAuthRepository` after `reloadAndCheckEmailVerified`:

```dart
@override
Future<void> sendPasswordResetEmail({required String email}) async {
  await _auth.sendPasswordResetEmail(email: email);
}
```

- [ ] Run `flutter analyze` — expect no errors

---

### Task 2: Add method to AuthNotifier

**Files:**

- Modify: `apps/mobile/lib/features/auth/application/providers/auth_provider.dart:121`

- [ ] Add after `sendEmailVerification()` method:

```dart
Future<void> sendPasswordResetEmail({required String email}) async {
  await ref.read(authRepositoryProvider).sendPasswordResetEmail(email: email);
}
```

---

### Task 3: Add route constant + GoRoute

**Files:**

- Modify: `apps/mobile/lib/app/router/route_names.dart:16`
- Modify: `apps/mobile/lib/app/router/app_router.dart`

- [ ] Add to `RouteNames` after `verifyEmail`:

```dart
static const forgotPassword = '/forgot-password';
```

- [ ] Add `RouteNames.forgotPassword` to `_publicRoutes` set in `app_router.dart`

- [ ] Add import for `ForgotPasswordScreen` in `app_router.dart`:

```dart
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
```

- [ ] Add GoRoute after the `verifyEmail` route:

```dart
GoRoute(
  path: RouteNames.forgotPassword,
  name: 'forgotPassword',
  builder: (context, state) {
    final email = state.uri.queryParameters['email'] ?? '';
    return ForgotPasswordScreen(initialEmail: email);
  },
),
```

---

### Task 4: Create ForgotPasswordScreen

**Files:**

- Create: `apps/mobile/lib/features/auth/presentation/screens/forgot_password_screen.dart`

- [ ] Create the file:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../shared/widgets/buttons/primary_button.dart';
import '../../application/providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  late final TextEditingController _emailController;
  bool _loading = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String value) =>
      value.contains('@') && value.contains('.');

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !_isValidEmail(email)) {
      setState(() => _error = 'Please enter a valid email address.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref
          .read(authProvider.notifier)
          .sendPasswordResetEmail(email: email);
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Forgot password')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _sent ? _buildSuccess() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        Text(
          'Enter your email address and we\'ll send you a link to reset your password.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 24),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _loading ? null : _submit(),
          enabled: !_loading,
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        const SizedBox(height: 32),
        PrimaryButton(
          label: _loading ? 'Sending...' : 'Send reset link',
          onPressed: _loading ? null : _submit,
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 32),
        const Icon(Icons.mark_email_read_outlined, size: 64),
        const SizedBox(height: 24),
        Text(
          'Check your inbox',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        Text(
          'If an account exists for ${_emailController.text.trim()}, you\'ll receive a password reset link shortly.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 40),
        PrimaryButton(
          label: 'Back to login',
          onPressed: () => context.go(RouteNames.login),
        ),
      ],
    );
  }
}
```

---

### Task 5: Update LoginScreen

**Files:**

- Modify: `apps/mobile/lib/features/auth/presentation/screens/login_screen.dart`

- [ ] Add import for RouteNames (already imported)

- [ ] Add TextButton after the "Don't have an account? Register" button:

```dart
TextButton(
  onPressed: () => context.push(
    '${RouteNames.forgotPassword}?email=${Uri.encodeComponent(_emailController.text.trim())}',
  ),
  child: const Text('Forgot your password?'),
),
```

---

### Task 6: Update mock + test

**Files:**

- Modify: `apps/mobile/test/helpers/mock_providers.dart` — `MockAuthRepository` auto-implements via `implements`, no change needed
- Modify: `apps/mobile/test/unit/features/auth/auth_provider_test.dart`

- [ ] Add stub for `sendPasswordResetEmail` in the test that uses `MockAuthRepository`:

```dart
when(() => repo.sendPasswordResetEmail(email: any(named: 'email')))
    .thenAnswer((_) async {});
```

- [ ] Add test case for `sendPasswordResetEmail`:

```dart
test('sendPasswordResetEmail delegates to repository', () async {
  final repo = MockAuthRepository();
  when(() => repo.authStateChanges()).thenAnswer((_) => Stream.value(null));
  when(() => repo.sendPasswordResetEmail(email: any(named: 'email')))
      .thenAnswer((_) async {});

  final container = makeContainer(repo);
  addTearDown(container.dispose);
  await container.read(authProvider.future);

  await container.read(authProvider.notifier).sendPasswordResetEmail(
        email: 'test@example.com',
      );

  verify(() => repo.sendPasswordResetEmail(email: 'test@example.com')).called(1);
});
```

- [ ] Run `flutter test` — expect all tests pass

---

### Task 7: Commit

- [ ] `git add` all changed files
- [ ] `git commit -m "feat: add forgot password flow with Firebase Auth"`
