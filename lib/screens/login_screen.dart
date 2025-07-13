import 'package:flutter/material.dart';
import 'package:suket_desa_app/services/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:suket_desa_app/screens/dashboard_screen.dart';
import 'package:suket_desa_app/admin/admin_dashboard_screen.dart';
import 'package:animate_do/animate_do.dart'; // Import animate_do

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    // Warna gradasi yang senada dengan desain yang diberikan (biru cerah dan biru tua)
    final Color primaryBlue = const Color(
      0xFF007AFF,
    ); // Biru utama dari referensi
    final Color darkBlue = const Color(0xFF0056B3); // Biru tua untuk gradasi

    return Scaffold(
      backgroundColor: isSmallScreen ? Colors.white : Colors.transparent,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Latar belakang gradasi untuk layar lebar
              if (!isSmallScreen)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryBlue, darkBlue], // Gradasi biru
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),

              // Konten utama (Header dan Form) yang di-center
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Container(
                    width:
                        isSmallScreen
                            ? double.infinity
                            : 400, // Lebar terbatas untuk layar besar, penuh untuk layar kecil
                    padding: const EdgeInsets.all(30.0), // Padding internal
                    decoration: BoxDecoration(
                      color: Colors.white, // Latar belakang putih
                      borderRadius: BorderRadius.circular(
                        20.0,
                      ), // Sudut membulat
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 5,
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min, // Ukuran kolom menyesuaikan konten
                      children: <Widget>[
                        // Bagian atas dengan gambar background dan animasi (Header)
                        Container(
                          height:
                              isSmallScreen
                                  ? 250
                                  : 200, // Tinggi responsif, lebih kompak
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(
                                'assets/images/background.jpg', // Pastikan gambar ini ada
                              ), // Gambar background header
                              fit: BoxFit.fill, // Mengisi seluruh area
                            ),
                          ),
                          child: Stack(
                            children: <Widget>[
                              Positioned(
                                left: 30,
                                width: 80,
                                height: 200,
                                child: FadeInUp(
                                  duration: const Duration(seconds: 1),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      image: DecorationImage(
                                        image: AssetImage(
                                          'assets/images/light-1.png', // Elemen animasi
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 140,
                                width: 80,
                                height: 150,
                                child: FadeInUp(
                                  duration: const Duration(milliseconds: 1200),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      image: DecorationImage(
                                        image: AssetImage(
                                          'assets/images/light-2.png', // Elemen animasi
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 40,
                                top: 40,
                                width: 80,
                                height: 150,
                                child: FadeInUp(
                                  duration: const Duration(milliseconds: 1300),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      image: DecorationImage(
                                        image: AssetImage(
                                          'assets/images/clock.png', // Elemen animasi
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                child: FadeInUp(
                                  duration: const Duration(milliseconds: 1600),
                                  child: Container(
                                    margin: const EdgeInsets.only(top: 50),
                                    child: const Center(
                                      child: Text(
                                        "Login",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Bagian bawah dengan form login/register (_FormContent)
                        const Padding(
                          padding: EdgeInsets.all(30.0),
                          child:
                              _FormContent(), // Konten form dipindahkan ke widget terpisah
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _gap() => const SizedBox(height: 16); // Helper untuk spasi
}

// Widget untuk Konten Form Login/Register
class _FormContent extends StatefulWidget {
  const _FormContent();

  @override
  State<_FormContent> createState() => __FormContentState();
}

class __FormContentState extends State<_FormContent> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final AuthService _authService = AuthService();

  bool _isRegisterMode = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isPasswordVisible = false; // Untuk toggle visibilitas password

  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>(); // Key untuk validasi form

  // Fungsi untuk menampilkan Snackbar
  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Fungsi untuk menangani proses autentikasi (login/register)
  Future<void> _handleAuth() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showSnackbar('Mohon lengkapi semua kolom dengan benar.', isError: true);
      return;
    }

    if (_isRegisterMode) {
      if (_passwordController.text != _confirmPasswordController.text) {
        _showSnackbar('Konfirmasi Password tidak cocok.', isError: true);
        return;
      }
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isRegisterMode) {
        final response = await _authService.register(
          _nameController.text,
          _emailController.text,
          _passwordController.text,
          _confirmPasswordController.text,
        );
        _showSnackbar(response['message'] ?? 'Registrasi berhasil!');
        if (mounted) {
          setState(() {
            _isRegisterMode = false;
            _emailController.text = _emailController.text;
            _passwordController.clear();
            _confirmPasswordController.clear();
            _nameController.clear();
          });
        }
      } else {
        final response = await _authService.login(
          _emailController.text,
          _passwordController.text,
        );
        _showSnackbar('Login berhasil!');

        final userRole = response['user']['role'];
        final userEmail = response['user']['email'];

        if (mounted) {
          if (userRole == 'admin') {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder:
                    (context) => AdminDashboardScreen(adminEmail: userEmail),
              ),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => DashboardScreen(userEmail: userEmail),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      _showSnackbar(_errorMessage!, isError: true);
      print('Error autentikasi: $_errorMessage');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // New primary blue color
    final Color primaryBlue = const Color(0xFF007AFF);
    final Color darkBlue = const Color(0xFF0056B3);

    return FadeInUp(
      // Animasi FadeInUp untuk seluruh form konten
      duration: const Duration(milliseconds: 1800),
      child: Container(
        // Padding, border, dan shadow diatur di parent Container di LoginScreen
        // Ini hanya untuk konten internal form
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Input Nama Lengkap (hanya untuk Register Mode)
              if (_isRegisterMode) ...[
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: primaryBlue),
                    ), // Border bawah
                  ),
                  child: TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      border: InputBorder.none, // Hapus border default
                      hintText: 'Nama Lengkap',
                      hintStyle: TextStyle(color: Colors.grey.shade700),
                      // prefixIcon: Icon(Icons.person_outline, color: primaryBlue), // Ikon opsional
                    ),
                    keyboardType: TextInputType.text,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama lengkap wajib diisi';
                      }
                      return null;
                    },
                  ),
                ),
              ],

              // Input Email
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: primaryBlue),
                  ), // Border bawah
                ),
                child: TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    border: InputBorder.none, // Hapus border default
                    hintText: 'Email',
                    hintStyle: TextStyle(color: Colors.grey.shade700),
                    // prefixIcon: Icon(Icons.email_outlined, color: primaryBlue), // Ikon opsional
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Email wajib diisi';
                    }
                    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                      return 'Format email tidak valid';
                    }
                    return null;
                  },
                ),
              ),

              // Input Password
              Container(
                padding: const EdgeInsets.all(8.0),
                child: TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  style: const TextStyle(color: Colors.black87),
                  decoration: InputDecoration(
                    border: InputBorder.none, // Hapus border default
                    hintText: 'Password',
                    hintStyle: TextStyle(color: Colors.grey.shade700),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password wajib diisi';
                    }
                    if (value.length < 8) {
                      return 'Password minimal 8 karakter';
                    }
                    return null;
                  },
                ),
              ),

              // Input Konfirmasi Password (hanya untuk Register Mode)
              if (_isRegisterMode) ...[
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: primaryBlue),
                    ), // Border bawah
                  ),
                  child: TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: !_isPasswordVisible, // Bisa di-toggle juga
                    style: const TextStyle(color: Colors.black87),
                    decoration: InputDecoration(
                      border: InputBorder.none, // Hapus border default
                      hintText: 'Konfirmasi Password',
                      hintStyle: TextStyle(color: Colors.grey.shade700),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Konfirmasi password wajib diisi';
                      }
                      if (value != _passwordController.text) {
                        return 'Konfirmasi password tidak cocok';
                      }
                      return null;
                    },
                  ),
                ),
              ],

              const SizedBox(height: 30), // Spasi sebelum tombol login
              // Tombol Login/Daftar
              FadeInUp(
                duration: const Duration(milliseconds: 1900),
                child: Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(colors: [primaryBlue, darkBlue]),
                  ),
                  child: MaterialButton(
                    // Menggunakan MaterialButton untuk onPress
                    onPressed: _isLoading ? null : _handleAuth,
                    padding: const EdgeInsets.all(
                      0,
                    ), // Hilangkan padding default MaterialButton
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child:
                          _isLoading
                              ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                              : const Text(
                                "Login",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20), // Spasi setelah tombol login
              // Tombol Toggle Mode (Login/Register)
              FadeInUp(
                duration: const Duration(milliseconds: 2000),
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _isRegisterMode = !_isRegisterMode;
                      _errorMessage = null;
                      _passwordController.clear();
                      _confirmPasswordController.clear();
                      _nameController.clear();
                      _formKey.currentState?.reset(); // Reset validasi form
                    });
                  },
                  child: Text(
                    _isRegisterMode
                        ? 'Sudah punya akun? Login di sini'
                        : 'Belum punya akun? Daftar di sini',
                    style: TextStyle(color: primaryBlue),
                  ),
                ),
              ),
              const SizedBox(height: 20), // Spasi setelah tombol toggle
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.red.shade600,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _gap() => const SizedBox(height: 16);
}
