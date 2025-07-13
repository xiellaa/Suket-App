import 'package:flutter/material.dart';
import 'package:suket_desa_app/services/auth_service.dart';
import 'package:suket_desa_app/screens/login_screen.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

class AdminEditUserScreen extends StatefulWidget {
  final Map<String, dynamic> user; // Data user yang akan diedit

  const AdminEditUserScreen({super.key, required this.user});

  @override
  State<AdminEditUserScreen> createState() => _AdminEditUserScreenState();
}

class _AdminEditUserScreenState extends State<AdminEditUserScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>(); // Key untuk validasi form

  // Controllers untuk setiap input field
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController =
      TextEditingController(); // Untuk update password opsional
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _tempatLahirController = TextEditingController();
  final TextEditingController _tanggalLahirController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _teleponController = TextEditingController();

  String? _selectedJenisKelamin;
  String? _selectedAgama;
  String? _selectedStatusWarga;
  String? _selectedRole; // Untuk mengubah role user

  bool _isLoading = false;
  String? _errorMessage;

  // Opsi-opsi dropdown
  final List<String> _jenisKelaminOptions = ['Laki-laki', 'Perempuan'];
  final List<String> _agamaOptions = [
    'Islam',
    'Kristen',
    'Katolik',
    'Hindu',
    'Buddha',
    'Konghucu',
  ];
  final List<String> _statusWargaOptions = [
    'Pelajar',
    'Mahasiswa',
    'Pekerja Swasta',
    'PNS',
    'Wiraswasta',
    'Ibu Rumah Tangga',
    'Belum Bekerja',
    'Pensiunan',
  ];
  final List<String> _roleOptions = ['user', 'admin']; // Opsi role

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  // Mengisi controller dengan data user yang diterima
  void _initializeControllers() {
    _nameController.text = widget.user['name'] ?? '';
    _emailController.text = widget.user['email'] ?? '';
    _nikController.text = widget.user['nik'] ?? '';
    _tempatLahirController.text = widget.user['tempat_lahir'] ?? '';
    _alamatController.text = widget.user['alamat'] ?? '';
    _teleponController.text = widget.user['telepon'] ?? '';

    // Tanggal Lahir
    if (widget.user['tanggal_lahir'] != null) {
      try {
        DateTime date = DateTime.parse(widget.user['tanggal_lahir']);
        _tanggalLahirController.text = DateFormat('yyyy-MM-dd').format(date);
      } catch (e) {
        _tanggalLahirController.text = '';
      }
    } else {
      _tanggalLahirController.text = '';
    }

    // Set nilai awal dropdown
    _selectedJenisKelamin = widget.user['jenis_kelamin'];
    _selectedAgama = widget.user['agama'];
    _selectedStatusWarga = widget.user['status_warga'];
    _selectedRole = widget.user['role']; // Inisialisasi role
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nikController.dispose();
    _tempatLahirController.dispose();
    _tanggalLahirController.dispose();
    _alamatController.dispose();
    _teleponController.dispose();
    super.dispose();
  }

  // Fungsi untuk memilih tanggal
  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    if (_tanggalLahirController.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(_tanggalLahirController.text);
      } catch (e) {
        initialDate = DateTime(2000, 1, 1); // Default jika parse gagal
      }
    } else {
      initialDate = DateTime(2000, 1, 1); // Default jika kosong
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.teal.shade700, // Warna primer date picker
            colorScheme: ColorScheme.light(primary: Colors.teal.shade700),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
            textButtonTheme: TextButtonThemeData(
              // Warna teks tombol
              style: TextButton.styleFrom(
                foregroundColor: Colors.teal.shade700,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != initialDate) {
      if (!mounted) return;
      setState(() {
        _tanggalLahirController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  // Fungsi untuk menyimpan perubahan user
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_passwordController.text.isNotEmpty &&
        _passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Konfirmasi password tidak cocok.',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red.shade600,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      // Kumpulkan data yang akan diupdate
      final Map<String, dynamic> dataToUpdate = {
        'name': _nameController.text,
        'email': _emailController.text,
        'role': _selectedRole, // Role juga diupdate
        'nik': _nikController.text.isEmpty ? null : _nikController.text,
        'jenis_kelamin': _selectedJenisKelamin,
        'tempat_lahir':
            _tempatLahirController.text.isEmpty
                ? null
                : _tempatLahirController.text,
        'tanggal_lahir':
            _tanggalLahirController.text.isEmpty
                ? null
                : _tanggalLahirController.text,
        'agama': _selectedAgama,
        'alamat':
            _alamatController.text.isEmpty ? null : _alamatController.text,
        'telepon':
            _teleponController.text.isEmpty ? null : _teleponController.text,
        'status_warga': _selectedStatusWarga,
      };

      // Tambahkan password jika diisi
      if (_passwordController.text.isNotEmpty) {
        dataToUpdate['password'] = _passwordController.text;
        dataToUpdate['password_confirmation'] = _confirmPasswordController.text;
      }

      await _authService.updateAdminUser(
        token,
        widget.user['id'],
        dataToUpdate,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Data user berhasil diperbarui!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green.shade600,
          ),
        );
        Navigator.pop(
          context,
          true,
        ); // Kembali ke daftar dan beri sinyal refresh
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memperbarui user: $_errorMessage',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.red.shade600,
        ),
      );
      print('Error updating user data: $_errorMessage');
      if (e.toString().contains('Unauthorized') ||
          e.toString().contains('Akses ditolak')) {
        await _authService.deleteToken();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Helper untuk membangun TextField
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    IconData? icon,
    bool isObscure = false,
    TextInputType keyboardType = TextInputType.text,
    FormFieldValidator<String>? validator,
    VoidCallback? onTap,
    bool readOnly = false,
    int? maxLines = 1, // Untuk field alamat
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        obscureText: isObscure,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        maxLines: maxLines,
        style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade900),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
          prefixIcon:
              icon != null ? Icon(icon, color: Colors.teal.shade700) : null,
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
            borderSide: BorderSide(color: Colors.teal.shade700, width: 2.0),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16, // Lebih besar untuk estetika
            horizontal: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }

  // Helper untuk membangun DropdownButtonFormField
  Widget _buildDropdownField({
    required String labelText,
    required String? selectedValue,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    IconData? icon,
    FormFieldValidator<String>? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: selectedValue,
        style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade900),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
          prefixIcon:
              icon != null ? Icon(icon, color: Colors.teal.shade700) : null,
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
            borderSide: BorderSide(color: Colors.teal.shade700, width: 2.0),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
        items:
            items.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: GoogleFonts.poppins()),
              );
            }).toList(),
        onChanged: onChanged,
        validator: validator,
        dropdownColor: Colors.white, // Warna dropdown item
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appBarTitleStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );
    final appBarBackgroundColor = Colors.teal.shade600;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Memuat Data...', style: appBarTitleStyle),
          backgroundColor: appBarBackgroundColor,
          foregroundColor: Colors.white,
          elevation: 6,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.teal),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Error', style: appBarTitleStyle),
          backgroundColor: appBarBackgroundColor,
          foregroundColor: Colors.white,
          elevation: 6,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 60),
                const SizedBox(height: 20),
                Text(
                  'Terjadi Kesalahan: $_errorMessage\nMohon Coba Lagi.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    color: Colors.red.shade700,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () {
                    // Coba lagi mengambil data awal user jika ada error
                    _initializeControllers(); // Re-initialize to reflect original user data state, then _saveChanges() can retry if needed.
                    setState(() {
                      _errorMessage =
                          null; // Clear error message to show form if needed.
                      _isLoading = false;
                    });
                  },
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: Text(
                    'Coba Lagi',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade700,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 25,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 5,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Data Warga: ${widget.user['name']}',
          style: appBarTitleStyle,
        ),
        backgroundColor: appBarBackgroundColor,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      body: Container(
        color: Colors.grey.shade50, // Latar belakang body
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0), // Padding lebih besar
          child: Card(
            elevation: 10, // Elevasi kartu lebih tinggi
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0), // Sudut lebih membulat
            ),
            shadowColor: Colors.black.withOpacity(0.15), // Warna shadow
            child: Padding(
              padding: const EdgeInsets.all(25.0), // Padding internal kartu
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Informasi Akun',
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    ),
                    const Divider(
                      height: 20,
                      thickness: 1.5,
                      color: Colors.teal,
                    ),
                    _buildTextField(
                      controller: _nameController,
                      labelText: 'Nama Lengkap',
                      icon: Icons.person_outline, // Ikon outline
                      validator:
                          (value) =>
                              value!.isEmpty
                                  ? 'Nama lengkap wajib diisi'
                                  : null,
                    ),
                    _buildTextField(
                      controller: _emailController,
                      labelText: 'Email',
                      icon: Icons.email_outlined, // Ikon outline
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value!.isEmpty) return 'Email wajib diisi';
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value))
                          return 'Format email tidak valid';
                        return null;
                      },
                    ),
                    _buildDropdownField(
                      labelText: 'Role Pengguna', // Label lebih spesifik
                      selectedValue: _selectedRole,
                      items: _roleOptions,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedRole = newValue;
                        });
                      },
                      icon: Icons.admin_panel_settings_outlined, // Ikon outline
                      validator:
                          (value) =>
                              value == null ? 'Role wajib dipilih' : null,
                    ),
                    _buildTextField(
                      controller: _passwordController,
                      labelText: 'Password Baru (Kosongkan jika tidak diubah)',
                      icon: Icons.lock_outline, // Ikon outline
                      isObscure: true,
                      validator: (value) {
                        if (value!.isNotEmpty && value.length < 8)
                          return 'Password minimal 8 karakter';
                        return null;
                      },
                    ),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      labelText: 'Konfirmasi Password Baru',
                      icon: Icons.lock_reset_outlined, // Ikon outline
                      isObscure: true,
                      validator: (value) {
                        if (_passwordController.text.isNotEmpty &&
                            value != _passwordController.text) {
                          return 'Konfirmasi password tidak cocok';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 30),
                    Text(
                      'Informasi Biodata',
                      style: GoogleFonts.montserrat(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade800,
                      ),
                    ),
                    const Divider(
                      height: 20,
                      thickness: 1.5,
                      color: Colors.teal,
                    ),
                    _buildTextField(
                      controller: _nikController,
                      labelText: 'NIK (Nomor Induk Kependudukan)',
                      icon: Icons.credit_card_outlined, // Ikon outline
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value!.isNotEmpty && value.length != 16)
                          return 'NIK harus 16 digit';
                        return null;
                      },
                    ),
                    _buildDropdownField(
                      labelText: 'Jenis Kelamin',
                      selectedValue: _selectedJenisKelamin,
                      items: _jenisKelaminOptions,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedJenisKelamin = newValue;
                        });
                      },
                      icon: Icons.people_outline, // Ikon outline
                    ),
                    _buildTextField(
                      controller: _tempatLahirController,
                      labelText: 'Tempat Lahir',
                      icon: Icons.location_city_outlined, // Ikon outline
                    ),
                    _buildTextField(
                      controller: _tanggalLahirController,
                      labelText: 'Tanggal Lahir (YYYY-MM-DD)', // Format tanggal
                      icon: Icons.calendar_today_outlined, // Ikon outline
                      readOnly: true,
                      onTap: () => _selectDate(context),
                    ),
                    _buildDropdownField(
                      labelText: 'Agama',
                      selectedValue: _selectedAgama,
                      items: _agamaOptions,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedAgama = newValue;
                        });
                      },
                      icon: Icons.church_outlined, // Ikon outline
                    ),
                    _buildTextField(
                      controller: _alamatController,
                      labelText: 'Alamat Lengkap', // Label lebih jelas
                      icon: Icons.home_outlined, // Ikon outline
                      keyboardType: TextInputType.multiline,
                      maxLines: 3, // Izinkan 3 baris
                    ),
                    _buildTextField(
                      controller: _teleponController,
                      labelText: 'Nomor Telepon/HP', // Label lebih jelas
                      icon: Icons.phone_android_outlined, // Ikon outline
                      keyboardType: TextInputType.phone,
                    ),
                    _buildDropdownField(
                      labelText: 'Status Pekerjaan', // Label lebih jelas
                      selectedValue: _selectedStatusWarga,
                      items: _statusWargaOptions,
                      onChanged: (newValue) {
                        setState(() {
                          _selectedStatusWarga = newValue;
                        });
                      },
                      icon: Icons.work_outline, // Ikon outline
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveChanges,
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
                                  Icons.save_outlined,
                                  size: 24,
                                ), // Ikon outline
                        label: Text(
                          _isLoading ? 'Menyimpan...' : 'Simpan Perubahan',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Colors.teal.shade700, // Warna tombol teal
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 35,
                            vertical: 18,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              15,
                            ), // Sudut membulat
                          ),
                          elevation: 7, // Elevasi tombol
                        ),
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
}
