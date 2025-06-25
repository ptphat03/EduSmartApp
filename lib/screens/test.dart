import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main_navigation_screen.dart';

class LoginScreenTest extends StatefulWidget {
  const LoginScreenTest({super.key});

  @override
  State<LoginScreenTest> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreenTest> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: "tanphatphan2003@gmail.com");
  final _passwordController = TextEditingController(text: "phat12345");

  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = switch (e.code) {
        'user-not-found' => 'No user found with this email.',
        'wrong-password' => 'Wrong password.',
        'invalid-email' => 'Invalid email format.',
        _ => 'Login failed. ${e.message}'
      };

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Email Field
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) =>
                  (value == null || value.isEmpty) ? 'Enter your email' : null,
                ),
                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) =>
                  (value == null || value.isEmpty) ? 'Enter your password' : null,
                ),
                const SizedBox(height: 24),

                // Login Button or Loading
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _login,
                  child: const Text("Login"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
