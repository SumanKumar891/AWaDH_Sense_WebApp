import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:cloud_sense_webapp/buffalodata.dart';
import 'package:flutter/material.dart';
import 'package:email_validator/email_validator.dart';
import 'dart:ui'; // Import for BackdropFilter
import 'package:cloud_sense_webapp/DeviceListPage.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignInSignUpScreen extends StatefulWidget {
  @override
  _SignInSignUpScreenState createState() => _SignInSignUpScreenState();
}

class _SignInSignUpScreenState extends State<SignInSignUpScreen> {
  bool _isSignIn = true;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  String _errorMessage = '';
  bool _emailValid = true;
  bool _isLoading = false;
  String? _verificationCode;
  String? _emailToVerify;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
    _emailController.addListener(() {
      setState(() {
        _emailValid = EmailValidator.validate(_emailController.text);
      });
    });
  }

  Future<void> _checkCurrentUser() async {
    try {
      var currentUser = await Amplify.Auth.getCurrentUser();
      if (currentUser != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DataDisplayPage(),
          ),
        );
      }
    } catch (e) {}
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Sign out the user before trying to sign in again
      try {
        await Amplify.Auth.signOut();
      } catch (e) {
        // Ignore errors from signOut, as the user might not be signed in
      }

      SignInResult res = await Amplify.Auth.signIn(
        username: _emailController.text,
        password: _passwordController.text,
      );
      if (res.isSignedIn) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('email', _emailController.text);

        Navigator.pushReplacementNamed(context, '/devicelist');
      } else {
        setState(() {
          _errorMessage = 'Sign-in failed';
        });
      }
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

// Method to handle password reset process
  Future<void> _forgotPassword() async {
    String? email = await _showEmailInputDialog();
    if (email != null && _emailValid) {
      try {
        // Send password reset request
        await Amplify.Auth.resetPassword(username: email);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('A password reset code has been sent to your email.')),
        );

        // After the email is sent, show the dialog to enter the reset code and new password
        _showPasswordResetCodeDialog(email);
      } on AuthException catch (e) {
        setState(() {
          _errorMessage = e.message;
        });
      }
    }
  }

  // Dialog to enter the reset code
  Future<void> _showPasswordResetCodeDialog(String email) async {
    String? resetCode;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        TextEditingController resetCodeController = TextEditingController();

        return AlertDialog(
          title: Text('Enter Reset Code'),
          content: TextField(
            controller: resetCodeController,
            decoration: InputDecoration(labelText: 'Reset Code'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Submit'),
              onPressed: () {
                resetCode = resetCodeController.text;
                Navigator.of(context).pop();
                if (resetCode != null && resetCode!.isNotEmpty) {
                  // Show the new password dialog after the reset code is entered
                  _showNewPasswordDialog(email, resetCode!);
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Dialog to enter the new password and confirm password
  Future<void> _showNewPasswordDialog(String email, String resetCode) async {
    String? newPassword;
    String? confirmPassword;
    bool passwordsMatch = true;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        TextEditingController newPasswordController = TextEditingController();
        TextEditingController confirmPasswordController =
            TextEditingController();

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text('Enter New Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: newPasswordController,
                    obscureText: !_isPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  TextField(
                    controller: confirmPasswordController,
                    obscureText: !_isConfirmPasswordVisible,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isConfirmPasswordVisible
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _isConfirmPasswordVisible =
                                !_isConfirmPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  if (!passwordsMatch)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Passwords do not match',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Submit'),
                  onPressed: () async {
                    newPassword = newPasswordController.text;
                    confirmPassword = confirmPasswordController.text;

                    if (newPassword == confirmPassword) {
                      Navigator.of(context).pop();
                      await _confirmResetPassword(
                          email, resetCode, newPassword!);
                    } else {
                      setState(() {
                        passwordsMatch = false;
                      });
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmResetPassword(
      String email, String resetCode, String newPassword) async {
    try {
      await Amplify.Auth.confirmResetPassword(
        username: email,
        newPassword: newPassword,
        confirmationCode: resetCode,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Password has been reset. Please log in with your new password.')),
      );
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    }
  }

  Future<String?> _showEmailInputDialog() async {
    String? email;
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        TextEditingController emailController = TextEditingController();
        return AlertDialog(
          title: Text('Reset Password'),
          content: TextField(
            controller: emailController,
            decoration: InputDecoration(labelText: 'Email'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Submit'),
              onPressed: () {
                email = emailController.text;
                Navigator.of(context).pop(email);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _signUp() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await Amplify.Auth.signUp(
        username: _emailController.text,
        password: _passwordController.text,
        options: SignUpOptions(
          userAttributes: {
            CognitoUserAttributeKey.email: _emailController.text,
            CognitoUserAttributeKey.name: _nameController.text,
          },
        ),
      );
      _emailToVerify = _emailController.text;
      _showVerificationDialog();
    } on UsernameExistsException {
      setState(() {
        _errorMessage =
            'An account with this email already exists. Please log in or use a different email to sign up.';
      });
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _confirmSignUp() async {
    if (_verificationCode == null || _emailToVerify == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await Amplify.Auth.confirmSignUp(
        username: _emailToVerify!,
        confirmationCode: _verificationCode!,
      );

      // After successful sign-up and verification, redirect to the sign-in page
      setState(() {
        _isSignIn = true; // Switch to sign-in mode
      });

      // Display a success message or snackbar to notify the user
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Sign-up successful! Please sign in.')),
      );
    } on AuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Verify Your Email'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'A verification code has been sent to your email. Please enter the code below:'),
              TextField(
                onChanged: (value) {
                  _verificationCode = value;
                },
                decoration: InputDecoration(labelText: 'Verification Code'),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _confirmSignUp();
              },
              child: Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: isDarkMode ? Colors.black : Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/sun.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
              child: Container(
                color: isDarkMode
                    ? Colors.black
                        .withOpacity(0.7) // Darker overlay for dark mode
                    : Colors.black
                        .withOpacity(0.5), // Lighter overlay for light mode
              ),
            ),
          ),
          Center(
            child: AnimatedSwitcher(
              duration: Duration(milliseconds: 800),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(0.1, 0.0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                );
              },
              child: _isSignIn ? _buildSignIn(isDarkMode) : _buildSignUp(),
            ),
          ),
          if (_errorMessage.isNotEmpty)
            Positioned(
              bottom: 16.0,
              left: 16.0,
              right: 15.0,
              child: Container(
                padding: EdgeInsets.all(16.0),
                color: Colors.redAccent,
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSignIn(bool isDarkMode) {
    return SingleChildScrollView(
      key: ValueKey('SignIn'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isSmallScreen = constraints.maxWidth < 800;

          return isSmallScreen
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: _buildContent(isSmallScreen, isDarkMode),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: _buildContent(isSmallScreen, isDarkMode),
                );
        },
      ),
    );
  }

  List<Widget> _buildContent(bool isSmallScreen, bool isDarkMode) {
    return [
      Container(
        width: isSmallScreen ? double.infinity : 400,
        height: 500,
        color: isDarkMode
            ? Color.fromARGB(155, 255, 255, 255)
            : Color.fromARGB(155, 0, 0, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 55),
            Text(
              'Welcome Back!',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode
                      ? Colors.black
                      : Color.fromARGB(223, 216, 226, 231)),
            ),
            SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Text(
                'To keep connected with us please login with your personal info.',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? Colors.purple
                        : Color.fromARGB(223, 205, 108, 230)),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Container(
                width: 290,
                height: 190,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  image: DecorationImage(
                    image: AssetImage('assets/login.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: isSmallScreen ? 32 : 0),
      Container(
        width: isSmallScreen ? double.infinity : 400,
        height: 500,
        padding: EdgeInsets.all(32.0),
        color: isDarkMode
            ? const Color.fromARGB(255, 38, 37, 37)
            : const Color.fromARGB(155, 255, 255, 255),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 24),
            Text(
              'Login',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isDarkMode
                    ? Colors.white
                    : Color.fromARGB(243, 173, 21, 211),
              ),
            ),
            SizedBox(height: 42),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                border: OutlineInputBorder(),
                errorText: _emailValid ? null : 'Invalid email format',
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: isDarkMode ? Colors.redAccent : Colors.red),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: isDarkMode ? Colors.white30 : Colors.black),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: isDarkMode ? Colors.redAccent : Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: isDarkMode ? Colors.redAccent : Colors.red),
                ),
                errorStyle: TextStyle(
                  color: isDarkMode ? Colors.redAccent : Colors.red,
                ),
              ),
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: isDarkMode
                          ? Colors.blue
                          : const Color.fromARGB(255, 76, 39, 176)),
                ),
              ),
            ),
            if (_isLoading)
              CircularProgressIndicator()
            else
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: ElevatedButton(
                  onPressed: _signIn,
                  child: Text(
                    'Sign In',
                    style: TextStyle(
                        color: isDarkMode
                            ? Colors.black
                            : const Color.fromARGB(255, 245, 241, 240)),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    backgroundColor: isDarkMode
                        ? Colors.purple
                        : Color.fromARGB(223, 205, 108, 230),
                  ),
                ),
              ),
            SizedBox(height: 22),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? Colors.white
                        : Color.fromARGB(181, 113, 5, 214),
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: _forgotPassword,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        bottom: -1,
                        child: Container(
                          height: 1.5,
                          width: 40,
                          color: isDarkMode
                              ? Colors.blue
                              : Color.fromARGB(243, 32, 39, 230),
                        ),
                      ),
                      Text(
                        'Reset',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? Colors.blue
                              : Color.fromARGB(243, 32, 39, 230),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Don\'t have an Account?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? Colors.white
                        : Color.fromARGB(181, 113, 5, 214),
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSignIn = false;
                    });
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        bottom: -1,
                        child: Container(
                          height: 1.5,
                          width: 45,
                          color: isDarkMode
                              ? Colors.blue
                              : Color.fromARGB(243, 32, 39, 230),
                        ),
                      ),
                      Text(
                        'Sign Up',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? Colors.blue
                              : Color.fromARGB(243, 32, 39, 230),
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    ];
  }

  Widget _buildSignUp() {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      key: ValueKey('SignUp'),
      child: LayoutBuilder(
        builder: (context, constraints) {
          bool isSmallScreen = constraints.maxWidth < 800;

          return isSmallScreen
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: _buildSignUpContent(isSmallScreen, isDarkMode),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: _buildSignUpContent(isSmallScreen, isDarkMode),
                );
        },
      ),
    );
  }

  List<Widget> _buildSignUpContent(bool isSmallScreen, bool isDarkMode) {
    return [
      Container(
        width: isSmallScreen ? double.infinity : 400,
        height: 500,
        padding: EdgeInsets.all(32.0),
        color: isDarkMode
            ? const Color.fromARGB(255, 38, 37, 37)
            : Color.fromARGB(155, 255, 255, 255),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 16),
            Text(
              'Create Account',
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: isDarkMode
                    ? Colors.white
                    : Color.fromARGB(243, 173, 21, 211),
              ),
            ),
            SizedBox(height: 24),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: isDarkMode
                          ? Colors.blue
                          : const Color.fromARGB(255, 76, 39, 176)),
                ),
              ),
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                border: OutlineInputBorder(),
                errorText: _emailValid ? null : 'Invalid email format',
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: isDarkMode ? Colors.redAccent : Colors.red),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: isDarkMode ? Colors.white30 : Colors.black),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: isDarkMode ? Colors.redAccent : Colors.red),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: isDarkMode ? Colors.redAccent : Colors.red),
                ),
                errorStyle: TextStyle(
                  color: isDarkMode ? Colors.redAccent : Colors.red,
                ),
              ),
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle:
                    TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: isDarkMode ? Colors.white : Colors.black,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: isDarkMode
                          ? Colors.blue
                          : const Color.fromARGB(255, 76, 39, 176)),
                ),
              ),
              style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
            ),
            if (_isLoading)
              CircularProgressIndicator()
            else
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: ElevatedButton(
                  onPressed: _signUp,
                  child: Text(
                    'Sign Up',
                    style: TextStyle(
                        color: isDarkMode
                            ? Colors.black
                            : const Color.fromARGB(255, 245, 241, 240)),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    backgroundColor: isDarkMode
                        ? Colors.purple
                        : Color.fromARGB(223, 205, 108, 230),
                  ),
                ),
              ),
            SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Already have an Account?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? Colors.white
                        : Color.fromARGB(181, 113, 5, 214),
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSignIn = true;
                    });
                  },
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        bottom:
                            -1, // Adjust this value for spacing between text and underline
                        child: Container(
                          height: 1.5, // Thickness of the underline
                          width:
                              45, // Width of the underline to match the text length
                          color: isDarkMode
                              ? Colors.blue
                              : Color.fromARGB(
                                  243, 32, 39, 230), // Underline color
                        ),
                      ),
                      Text(
                        'Sign In',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode
                              ? Colors.blue
                              : Color.fromARGB(243, 32, 39, 230),
                          decoration:
                              TextDecoration.none, // Disable default underline
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
      SizedBox(height: isSmallScreen ? 32 : 0),
      Container(
        width: isSmallScreen ? double.infinity : 400,
        height: 500,
        color: isDarkMode
            ? Color.fromARGB(155, 255, 255, 255)
            : const Color.fromARGB(155, 0, 0, 0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 55),
            Text(
              'Welcome!',
              style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode
                      ? Colors.black
                      : Color.fromARGB(223, 216, 226, 231)),
            ),
            SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: Text(
                'Enter your personal details and start your journey with us.',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? Colors.purple
                        : Color.fromARGB(223, 205, 108, 230)),
                textAlign: TextAlign.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Container(
                width: 290,
                height: 190,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(50),
                  image: DecorationImage(
                    image: AssetImage('assets/login.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ];
  }
}
