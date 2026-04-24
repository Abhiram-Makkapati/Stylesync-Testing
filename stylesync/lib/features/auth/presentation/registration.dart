import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';



/// A simple data model to manage registered usernames for uniqueness checks.
class UserData extends ChangeNotifier {
  final Set<String> _registeredUsernames = <String>{};

  /// Checks if a username is already taken.
  bool isUsernameTaken(String username) {
    return _registeredUsernames.contains(username.toLowerCase());
  }

  /// Adds a new username to the set of registered usernames.
  void addUsername(String username) {
    if (!isUsernameTaken(username)) {
      _registeredUsernames.add(username.toLowerCase());
      notifyListeners(); // Notify listeners when data changes
    }
  }

  /// Clears all registered usernames. (For testing or reset purposes)
  void clearUsernames() {
    _registeredUsernames.clear();
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StyleSync User Registration',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E8B57), // Sea green
          brightness: Brightness.light,
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF2E8B57).withOpacity(0.15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2E8B57), width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF2E8B57)),
          hintStyle: TextStyle(color: const Color(0xFF2E8B57).withOpacity(0.6)),
          prefixIconColor: WidgetStateColor.resolveWith((Set<WidgetState> states) {
            if (states.contains(WidgetState.focused)) {
              return const Color(0xFF2E8B57);
            }
            return const Color(0xFF2E8B57).withOpacity(0.6);
          }),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E8B57),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            elevation: 8,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF2E8B57),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFF2E8B57),
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: GoogleFonts.zillaSlab(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: const StyleSyncPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Custom reusable text field widget
class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.isPassword = false,
    this.validator,
    this.autovalidateMode = AutovalidateMode.disabled,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPassword;
  final String? Function(String?)? validator;
  final AutovalidateMode autovalidateMode;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.label,
        prefixIcon: Icon(widget.icon),
        suffixIcon: widget.isPassword
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
              )
            : null,
      ),
      obscureText: _obscureText,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
    );
  }
}

class StyleSyncPage extends StatelessWidget {
  const StyleSyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: AppBar(title: const Text('StyleSync'), centerTitle: true),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Color(0xFF2E8B57),
              Color(0xFF20B2AA),
              Color(0xFFE0F2F1),
            ],
            stops: <double>[0.0, 0.5, 1.0],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                 padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: <Widget>[
                      Text(
                        'StyleSync',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sync Once. Stay Stylish Always.',
                        style: GoogleFonts.zillaSlab(
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create your unique profile',
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      RegistrationForm(
                        onRegister: ({
                          required String firstName,
                          required String lastName,
                          required String username,
                          required String email,
                          required String password,
                        }) async {
                          try {
                            // Create account in Firebase Auth
                            UserCredential userCredential =
                                await FirebaseAuth.instance.createUserWithEmailAndPassword(
                              email: email,
                              password: password,
                            );

                            // Store additional user data in Firestore
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(userCredential.user!.uid)
                                .set({
                              'firstName': firstName,
                              'lastName': lastName,
                              'username': username,
                              'email': email,
                            });

                            // Navigate to HomeScreen
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute<void>(
                                builder: (BuildContext context) => HomeScreen(firstName: firstName,lastName: lastName,username: username,),
                              ),
                            );
                          } on FirebaseAuthException catch (e) {
                            String message = '';
                            if (e.code == 'email-already-in-use') {
                              message = 'This email is already registered.';
                            } else if (e.code == 'weak-password') {
                              message =
                                  'Password should be at least 6 characters.';
                            } else {
                              message = e.message ?? 'Registration failed.';
                            }

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(message),
                                backgroundColor: Colors.red,
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({super.key, required this.onRegister});

  final Function({
    required String firstName,
    required String lastName,
    required String username,
    required String email,
    required String password,
  }) onRegister;

  @override
  State<RegistrationForm> createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _usernameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a username';
    }
    if (value.length < 3) {
      return 'Username must be at least 3 characters long';
    }
    final UserData userData = Provider.of<UserData>(context, listen: false);
    if (userData.isUsernameTaken(value)) {
      return 'This username is already taken';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) return 'Please enter your email';
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a password';
    if (value.length < 8) return 'Password must be at least 8 characters long';
    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != _passwordController.text) return 'Passwords do not match';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          CustomTextField(
            controller: _firstNameController,
            label: 'First Name',
            icon: Icons.person,
            validator: (String? v) =>
                v == null || v.isEmpty ? 'Please enter your first name' : null,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _lastNameController,
            label: 'Last Name',
            icon: Icons.person_outline,
            validator: (String? v) =>
                v == null || v.isEmpty ? 'Please enter your last name' : null,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _usernameController,
            label: 'Username',
            icon: Icons.account_circle,
            validator: _usernameValidator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email,
            validator: _emailValidator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock,
            isPassword: true,
            validator: _passwordValidator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            icon: Icons.lock,
            isPassword: true,
            validator: _confirmPasswordValidator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState?.validate() ?? false) {
                widget.onRegister(
                firstName: _firstNameController.text,
                lastName: _lastNameController.text,
                username: _usernameController.text,
                email: _emailController.text,
                password: _passwordController.text,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E8B57),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 18),
              elevation: 2,
            ),
            child: const Text(
              'Create Account',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          )
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final String firstName;
  final String lastName;
  final String username;

  const HomeScreen({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.username,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to StyleSync!'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.check_circle_outline,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 20),
              Text(
                'Registration Successful!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'Welcome, $firstName $lastName!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Your username is: $username',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

