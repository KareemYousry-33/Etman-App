import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_login/flutter_login.dart';
import 'etman_colors.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/admin_controller.dart';

class EtmanLoginScreen extends StatefulWidget {
  const EtmanLoginScreen({Key? key}) : super(key: key);

  @override
  State<EtmanLoginScreen> createState() => _EtmanLoginScreenState();
}

class _EtmanLoginScreenState extends State<EtmanLoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isSignUp = false;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Decorative background element
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: EtmanColors.primaryTeal.withOpacity(0.05),
              ),
            ),
          ),
          SafeArea(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 30.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 20),
                    // Header
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: EtmanColors.primaryTeal.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.security_outlined, color: EtmanColors.primaryTeal, size: 40),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _isSignUp ? "إنشاء حساب جديد" : "مرحباً بك مجدداً",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isSignUp ? "سجل بياناتك للانضمام إلينا" : "سجل دخولك للمتابعة",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
    
                    _buildSocialButton(
                      "التسجيل بواسطة جوجل",
                      "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/120px-Google_%22G%22_logo.svg.png",
                      onPressed: _handleGoogleLogin,
                    ),
                    const SizedBox(height: 30),
    
                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider(color: Colors.black12, thickness: 1)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            _isSignUp ? "أو سجل بواسطة" : "أو ادخل بواسطة",
                            style: const TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const Expanded(child: Divider(color: Colors.black12, thickness: 1)),
                      ],
                    ),
                    const SizedBox(height: 30),
    
                    // Email
                    _buildLabel("البريد الإلكتروني"),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textAlign: TextAlign.right,
                      decoration: _buildInputDecoration("البريد الإلكتروني أو الهاتف", Icons.email_outlined),
                    ),
                    const SizedBox(height: 20),
    
                    // Password
                    _buildLabel("كلمة المرور"),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textAlign: TextAlign.right,
                      decoration: _buildInputDecoration("كلمة المرور", Icons.lock_outline).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: EtmanColors.primaryTeal,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.black12, size: 20),
                    ),
                  ),
                    const SizedBox(height: 16),
    
                    // Remember Me & Forget Password
                    Row(
                      children: [
                        // Forgot Password on the LEFT (now explicitly positioned)
                        if (!_isSignUp)
                        TextButton(
                          onPressed: _handleForgotPassword,
                          style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero),
                          child: Text(
                            "نسيت كلمة المرور؟",
                            style: TextStyle(
                              color: EtmanColors.primaryTeal,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        
                        const Spacer(), // Pushes them to the edges
                        
                        // Remember Me on the RIGHT
                        GestureDetector(
                          onTap: () => setState(() => _rememberMe = !_rememberMe),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text("تذكرني", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.black87)),
                              const SizedBox(width: 4),
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (v) => setState(() => _rememberMe = v ?? false),
                                  activeColor: EtmanColors.primaryTeal,
                                  side: const BorderSide(color: Colors.black12, width: 1.5),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
    
                    // Login/Register Button
                    Container(
                      height: 58,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        gradient: LinearGradient(
                          colors: [EtmanColors.primaryTeal, EtmanColors.primaryTeal.withOpacity(0.8)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: EtmanColors.primaryTeal.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleAuth,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: _isLoading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              _isSignUp ? "إنشاء حساب" : "تسجيل الدخول",
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                      ),
                    ),
                    const SizedBox(height: 50),
    
                    // Footer
                    Center(
                      child: GestureDetector(
                        onTap: () => setState(() => _isSignUp = !_isSignUp),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(color: Colors.black54, fontSize: 14),
                            children: [
                              TextSpan(text: _isSignUp ? "لديك حساب بالفعل؟ " : "ليس لديك حساب؟ "),
                              TextSpan(
                                text: _isSignUp ? "سجل دخولك" : "سجل الآن",
                                style: TextStyle(
                                  color: EtmanColors.primaryTeal,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      textAlign: TextAlign.right,
      style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.bold),
    );
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFFBFBFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      alignLabelWithHint: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF1E8C78), width: 1.5),
      ),
    );
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      Get.snackbar(
        "تنبيه", 
        "من فضلك اكتب البريد الإلكتروني أولاً لإرسال رابط استعادة كلمة المرور",
        backgroundColor: Colors.orangeAccent,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM
      );
      return;
    }

    setState(() => _isLoading = true);
    final authController = Get.find<AuthController>();
    final String result = await authController.recoverPassword(email);
    setState(() => _isLoading = false);

    Get.snackbar(
      "استعادة كلمة المرور", 
      result,
      backgroundColor: result.contains('sent') ? EtmanColors.primaryTeal : Colors.redAccent,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM
    );
  }

  Widget _buildSocialButton(String label, String? imageUrl, {IconData? icon, VoidCallback? onPressed}) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (imageUrl != null)
              Image.network(imageUrl, width: 22, height: 22)
            else
              Icon(icon, color: Colors.black, size: 24),
            const SizedBox(width: 12),
            Text(
              label, 
              style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 15)
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    final authController = Get.find<AuthController>();
    final String? err = await authController.signInWithGoogle();
    setState(() => _isLoading = false);

    if (err != null && err != "Login Cancelled") {
      Get.snackbar("Error", err, backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }

  Future<void> _handleAuth() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      Get.snackbar("Error", "Please fill in all fields", backgroundColor: Colors.redAccent, colorText: Colors.white);
      return;
    }

    setState(() => _isLoading = true);
    final authController = Get.find<AuthController>();
    
    String? err;
    if (_isSignUp) {
      err = await authController.signupUser(
        SignupData.fromSignupForm(
          name: _emailController.text, 
          password: _passwordController.text,
          additionalSignupData: {}
        )
      );
    } else {
      err = await authController.authUser(
        LoginData(name: _emailController.text, password: _passwordController.text)
      );
    }

    setState(() => _isLoading = false);

    if (err == null) {
      // success - AuthController will handle navigation
      return;
    } else {
      Get.snackbar("Error", err, backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }
}

