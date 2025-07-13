import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:suket_desa_app/services/auth_service.dart';
import 'package:suket_desa_app/screens/login_screen.dart';
import 'package:suket_desa_app/screens/dashboard_screen.dart'; // Import DashboardScreen
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

class SktmFormScreen extends StatefulWidget {
  const SktmFormScreen({super.key});

  @override
  State<SktmFormScreen> createState() => _SktmFormScreenState();
}

class _SktmFormScreenState extends State<SktmFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _keperluanController = TextEditingController();
  File? _scanKtpFile;
  File? _scanKkFile;
  bool _isLoading = false;
  String? _errorMessage;
  final ImagePicker _picker = ImagePicker();
  final AuthService _authService = AuthService();

  // Definisi warna biru konsisten Anda, persis seperti SKD/SKU
  final Color primaryBlue = const Color(0xFF1976D2); // Biru utama
  final Color darkBlue = const Color(0xFF0D47A1); // Biru tua untuk gradasi
  final Color accentOrange = const Color(0xFFFF9800); // Aksen oranye

  @override
  void initState() {
    super.initState();
    _fetchUserNik();
  }

  @override
  void dispose() {
    _nikController.dispose();
    _keperluanController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserNik() async {
    setState(() => _isLoading = true);
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final response = await _authService.getUser(token);
      if (mounted) {
        setState(() {
          _nikController.text =
              response?['user']['nik'] ?? ''; // NIK kosong jika belum ada
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = e.toString().replaceFirst('Exception: ', ''),
        );
        if (e.toString().contains('Unauthorized')) {
          await _authService.deleteToken();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickFile(String fileType) async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null && mounted) {
        setState(() {
          if (fileType == 'ktp') {
            _scanKtpFile = File(pickedFile.path);
          } else {
            _scanKkFile = File(pickedFile.path);
          }
        });
        _showSnackbar(
          'File ${pickedFile.name} berhasil dipilih.',
          isError: false,
          isSuccess: true,
        );
      }
    } catch (e) {
      _showSnackbar('Gagal memilih file: ${e.toString()}', isError: true);
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;
    if (_scanKtpFile == null) {
      _showSnackbar('Scan KTP wajib diunggah.', isError: true);
      return;
    }
    if (_scanKkFile == null) {
      _showSnackbar('Scan KK wajib diunggah.', isError: true);
      return;
    }
    if (_nikController.text.isEmpty) {
      _showSnackbar(
        'NIK belum terisi di biodata Anda. Harap lengkapi biodata terlebih dahulu.',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final response = await _authService.submitSuratRequest(
        jenisSurat: 'SKTM',
        keperluan: _keperluanController.text,
        scanKtp: _scanKtpFile,
        scanKk: _scanKkFile,
        token: token,
      );

      _resetForm(); // Reset form setelah sukses

      await _showSuccessDialog(
        response['message'] ?? 'Permohonan SKTM berhasil diajukan!',
      );

      if (mounted) {
        // Kembali ke DashboardScreen setelah sukses
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder:
                (context) => DashboardScreen(
                  userEmail: _authService.getCurrentUserEmail() ?? '',
                ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _errorMessage = e.toString().replaceFirst('Exception: ', ''),
        );
      }
      _showSnackbar('Gagal mengajukan: $_errorMessage', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showSuccessDialog(String message) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: Colors.green.shade600,
                  size: 30,
                ),
                const SizedBox(width: 10),
                Text(
                  'Sukses!',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: Text(message, style: GoogleFonts.poppins()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(
                    color: primaryBlue,
                  ), // Diganti ke primaryBlue
                ),
              ),
            ],
          ),
    );
  }

  void _showSnackbar(
    String message, {
    bool isError = false,
    bool isSuccess = false,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor:
            isError
                ? Colors.red.shade600
                : (isSuccess
                    ? Colors.green.shade600
                    : primaryBlue), // Diganti ke primaryBlue
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _keperluanController.clear();
    setState(() {
      _scanKtpFile = null;
      _scanKkFile = null;
    });
    _fetchUserNik(); // Ambil ulang NIK setelah reset
  }

  @override
  Widget build(BuildContext context) {
    // Definisi gaya teks umum
    final appBarTitleStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );
    // appBarBackgroundColor dihapus karena sekarang menggunakan gradasi

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Formulir Surat Keterangan Tidak Mampu (SKTM)',
          style: appBarTitleStyle,
        ),
        backgroundColor:
            primaryBlue, // Menggunakan primaryBlue sebagai warna dasar AppBar
        flexibleSpace: Container(
          // Tambahkan gradasi di AppBar
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [darkBlue, primaryBlue],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      body: Container(
        color: Colors.grey.shade50, // Latar belakang body
        child:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    color: primaryBlue,
                  ), // Warna loading indicator
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0), // Padding lebih besar
                  child: Card(
                    elevation: 10, // Elevasi kartu lebih tinggi
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        20.0,
                      ), // Sudut lebih membulat
                    ),
                    shadowColor: Colors.black.withOpacity(0.15), // Warna shadow
                    child: Padding(
                      padding: const EdgeInsets.all(
                        25.0,
                      ), // Padding internal kartu
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Ajukan Surat Keterangan Tidak Mampu',
                              style: GoogleFonts.montserrat(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: primaryBlue, // Diganti ke primaryBlue
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Lengkapi formulir di bawah ini dan unggah dokumen yang diperlukan.',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 30),
                            _buildTextFormField(
                              controller: _nikController,
                              label: 'NIK (Nomor Induk Kependudukan)',
                              icon: Icons.credit_card_outlined,
                              readOnly: true, // NIK tidak bisa diedit di sini
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'NIK wajib diisi di Biodata Anda. Harap lengkapi biodata.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildTextFormField(
                              controller: _keperluanController,
                              label: 'Keperluan Pengajuan SKTM',
                              hintText:
                                  'Contoh: Untuk pengajuan beasiswa / Keringanan biaya rumah sakit',
                              icon: Icons.assignment_outlined,
                              maxLines: 3,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Keperluan wajib diisi.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 30),
                            Text(
                              'Dokumen Pendukung:',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: darkBlue, // Diganti ke darkBlue
                              ),
                            ),
                            const SizedBox(height: 15),
                            _buildFilePickerButton(
                              onPressed: () => _pickFile('ktp'),
                              label:
                                  _scanKtpFile != null
                                      ? 'KTP: ${_scanKtpFile!.path.split('/').last}'
                                      : 'Unggah Scan KTP (.jpg, .png)',
                              icon: Icons.image_outlined,
                              fileType: 'ktp',
                            ),
                            // BAGIAN PREVIEW KTP DIHAPUS
                            const SizedBox(height: 15),
                            _buildFilePickerButton(
                              onPressed: () => _pickFile('kk'),
                              label:
                                  _scanKkFile != null
                                      ? 'KK: ${_scanKkFile!.path.split('/').last}'
                                      : 'Unggah Scan Kartu Keluarga (.jpg, .png)',
                              icon: Icons.collections_bookmark_outlined,
                              fileType: 'kk',
                            ),
                            // BAGIAN PREVIEW KK DIHAPUS
                            const SizedBox(height: 40),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _submitRequest,
                              icon:
                                  _isLoading
                                      ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                      : const Icon(
                                        Icons.send_outlined,
                                        size: 24,
                                      ),
                              label: Text(
                                _isLoading
                                    ? 'Mengajukan...'
                                    : 'Ajukan Permohonan SKTM',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    accentOrange, // Diganti ke accentOrange
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                                elevation: 7,
                              ),
                            ),
                            if (_errorMessage != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 20.0),
                                child: Text(
                                  'Error: $_errorMessage',
                                  style: GoogleFonts.poppins(
                                    color: Colors.red.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
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

  // Helper Widget untuk TextFormField
  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    required IconData icon,
    bool readOnly = false,
    int? maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade900),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
        prefixIcon: Icon(icon, color: primaryBlue), // Diganti ke primaryBlue
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(
            color: primaryBlue, // Diganti ke primaryBlue
            width: 2.0,
          ),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
      validator: validator,
    );
  }

  // Helper Widget untuk tombol file picker (SUDAH DIHAPUS PREVIEW-NYA)
  Widget _buildFilePickerButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    required String fileType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(
            icon,
            color: primaryBlue,
            size: 24,
          ), // Diganti ke primaryBlue
          label: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade800,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
              side: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            elevation: 2,
          ),
        ),
        // Tidak ada lagi blok `if` yang menampilkan gambar di sini
      ],
    );
  }
}
