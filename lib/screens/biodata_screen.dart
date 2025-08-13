import 'package:flutter/material.dart';
import 'package:suket_desa_app/services/auth_service.dart';
import 'package:intl/intl.dart'; // Import untuk format tanggal
import 'package:suket_desa_app/screens/login_screen.dart'; // Pastikan jalur ini benar
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

class BiodataScreen extends StatefulWidget {
  const BiodataScreen({super.key});

  @override
  State<BiodataScreen> createState() => _BiodataScreenState();
}

class _BiodataScreenState extends State<BiodataScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isEditing = false; // State untuk mode edit
  String? _errorMessage;

  // --- START PERBAIKAN: Pindahkan definisi warna ke tingkat kelas ---
  final Color primaryBlue = const Color(0xFF007AFF);
  final Color darkBlue = const Color(0xFF0056B3);
  // --- END PERBAIKAN ---

  // Controllers untuk setiap input field
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _tempatLahirController = TextEditingController();
  final TextEditingController _tanggalLahirController = TextEditingController();
  final TextEditingController _alamatController = TextEditingController();
  final TextEditingController _teleponController = TextEditingController();

  // Variabel untuk nilai dropdown
  String? _selectedJenisKelamin;
  String? _selectedAgama;
  String? _selectedStatusWarga;

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

  @override
  void initState() {
    super.initState();
    _fetchBiodata(); // Ambil data biodata saat layar dimuat
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nikController.dispose();
    _tempatLahirController.dispose();
    _tanggalLahirController.dispose();
    _alamatController.dispose();
    _teleponController.dispose();
    super.dispose();
  }

  // Fungsi untuk mengambil data biodata dari API
  Future<void> _fetchBiodata() async {
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
      final response = await _authService.getUser(token); // Ambil data user
      if (!mounted) return;
      setState(() {
        _userData = response['user'];
        _initializeControllers(); // Isi controller dengan data yang didapat

        // Cek apakah ada data kosong, jika ada, langsung masuk mode edit
        // Ini sesuai dengan permintaan Anda: "saat baru regis semua itu masih kosong nah dibawah nya ada edit biodata, didalam edit biodata baru bisa melngkapi"
        if (_userData!['name'] == null ||
            _userData!['nik'] == null ||
            _userData!['jenis_kelamin'] == null ||
            _userData!['tempat_lahir'] == null ||
            _userData!['tanggal_lahir'] == null ||
            _userData!['agama'] == null ||
            _userData!['alamat'] == null ||
            _userData!['telepon'] == null ||
            _userData!['status_warga'] == null ||
            _userData!['name'] == '' ||
            _userData!['nik'] == '' ||
            _userData!['jenis_kelamin'] == '' ||
            _userData!['tempat_lahir'] == '' ||
            _userData!['tanggal_lahir'] == '' ||
            _userData!['agama'] == '' ||
            _userData!['alamat'] == '' ||
            _userData!['telepon'] == '' ||
            _userData!['status_warga'] == '') {
          _isEditing =
              true; // Langsung masuk mode edit jika biodata tidak lengkap
          _showSnackbar(
            'Mohon lengkapi biodata Anda.',
            isError: false, // Ini bukan error, hanya informasi
            isSuccess: false, // Bukan sukses, jadi warna default
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      print('Error fetching biodata: $_errorMessage'); // Log error
      if (e.toString().contains('Unauthorized')) {
        await _authService.deleteToken();
        if (mounted) {
          // navigator
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Mengisi controller dan nilai dropdown dari data pengguna
  void _initializeControllers() {
    if (_userData != null) {
      _nameController.text = _userData!['name'] ?? '';
      _nikController.text = _userData!['nik'] ?? '';
      _tempatLahirController.text = _userData!['tempat_lahir'] ?? '';

      // Tanggal Lahir: Format dari API ke format yang bisa ditampilkan
      if (_userData!['tanggal_lahir'] != null &&
          _userData!['tanggal_lahir'].isNotEmpty) {
        try {
          DateTime date = DateTime.parse(_userData!['tanggal_lahir']);
          _tanggalLahirController.text = DateFormat('yyyy-MM-dd').format(date);
        } catch (e) {
          _tanggalLahirController.text = ''; // Kosongkan jika parsing gagal
        }
      } else {
        _tanggalLahirController.text = '';
      }

      _alamatController.text = _userData!['alamat'] ?? '';
      _teleponController.text = _userData!['telepon'] ?? '';

      // Set nilai awal dropdown
      _selectedJenisKelamin = _userData!['jenis_kelamin'];
      _selectedAgama = _userData!['agama'];
      _selectedStatusWarga = _userData!['status_warga'];
    }
  }

  // Fungsi untuk update biodata ke API
  Future<void> _updateBiodata() async {
    // Validasi input
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showSnackbar(
        'Mohon lengkapi semua kolom yang wajib diisi dengan benar.',
        isError: true,
      );
      return;
    }

    if (_selectedJenisKelamin == null ||
        _selectedAgama == null ||
        _selectedStatusWarga == null) {
      _showSnackbar(
        'Mohon pilih Jenis Kelamin, Agama, dan Status Pekerjaan.',
        isError: true,
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    print('DEBUG: Memulai update biodata...');
    try {
      final token = await _authService.getToken();
      if (token == null) {
        print('DEBUG: Token tidak ditemukan, mengarahkan ke login.');
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      // Kumpulkan data yang akan diupdate
      final Map<String, dynamic> dataToUpdate = {
        'name': _nameController.text,
        'nik':
            _nikController.text.isEmpty
                ? null
                : _nikController.text, // Kirim null jika kosong
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

      print('DEBUG: Mengirim data ke API: $dataToUpdate');
      final response = await _authService.updateBiodata(token, dataToUpdate);
      print('DEBUG: Respons API diterima: $response');

      if (!mounted) {
        print('DEBUG: Widget tidak lagi mounted setelah respons API.');
        return;
      }

      // Pastikan respons memiliki kunci 'user' dan itu adalah Map
      if (response != null && response['user'] is Map<String, dynamic>) {
        setState(() {
          _userData =
              response['user']; // Perbarui data lokal dengan respons terbaru
          _isEditing = false; // Keluar dari mode edit
        });
        _showSnackbar(
          response['message'] ?? 'Biodata berhasil diperbarui!',
          isSuccess: true,
        );
        print('DEBUG: Biodata berhasil diperbarui, UI diupdate.');
        // BARIS INI TIDAK AKAN ADA PERUBAHAN, KARENA ANDA INGIN FUNGSIONALITASNYA TETAP SAMA
        Navigator.of(context).pop(true);
        // pastikan baris itu sudah DIHAPUS atau DIKOMENTARI di file Anda.
        // Saya tidak akan menambahkan/menghapus baris ini secara fungsional.
      } else {
        print('ERROR: Respons API tidak mengandung data user yang valid.');
        throw Exception('Data user tidak valid dari server.');
      }
    } catch (e) {
      if (!mounted) {
        print('DEBUG: Widget tidak lagi mounted saat menangani error.');
        return;
      }
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      _showSnackbar('Gagal memperbarui biodata: $_errorMessage', isError: true);
      print('ERROR: Gagal memperbarui biodata: $_errorMessage');
      if (e.toString().contains('Unauthorized') ||
          e.toString().contains('Sesi Anda telah berakhir')) {
        print('DEBUG: Token tidak valid, mengarahkan ke login.');
        await _authService.deleteToken();
        if (mounted) {
          // navigator
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false; // Sembunyikan loading indicator
        });
        print('DEBUG: Loading state diatur ke false.');
      }
    }
  }

  // Fungsi untuk memilih tanggal dari DatePicker
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
      firstDate: DateTime(1900), // Tanggal paling awal yang bisa dipilih
      lastDate: DateTime.now(), // Tanggal paling akhir (hari ini)
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: primaryBlue, // Warna primer date picker
            colorScheme: ColorScheme.light(
              primary: primaryBlue, // Warna skema date picker
              onPrimary: Colors.white, // Warna teks di primary color
              surface: Colors.white, // Background tanggal/bulan
              onSurface: Colors.black87, // Warna teks di surface
            ),
            buttonTheme: const ButtonThemeData(
              textTheme: ButtonTextTheme.primary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: darkBlue, // Warna teks tombol (OK, CANCEL)
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

  // Helper untuk menampilkan Snackbar
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
                    : primaryBlue), // Warna informasi default adalah primaryBlue
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Widget untuk menampilkan informasi biodata (mode non-edit)
  Widget _buildInfoField(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.black87, // Ganti primaryBlue menjadi hitam
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value ?? '-', // Tampilkan '-' jika nilai null
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey.shade900,
            ),
          ),
          Divider(
            height: 16,
            color: Colors.grey.shade300,
          ), // Divider yang lebih halus
        ],
      ),
    );
  }

  // GlobalKey untuk FormState
  final _formKey = GlobalKey<FormState>();

  // Widget untuk field yang bisa diedit (mode edit)
  Widget _buildEditableField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    VoidCallback? onTap,
    IconData? icon,
    int? maxLines = 1, // Default untuk TextField
    String? Function(String?)? validator, // Tambahkan validator
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        // Menggunakan TextFormField untuk validasi
        key: ValueKey(label), // Tambahkan key unik untuk setiap TextFormField
        controller: controller,
        keyboardType: keyboardType,
        readOnly: readOnly,
        onTap: onTap,
        maxLines: maxLines, // Mengizinkan multi-line untuk alamat
        style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade900),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0), // Sudut lebih membulat
            borderSide: BorderSide.none, // Hilangkan border default
          ),
          enabledBorder: OutlineInputBorder(
            // Border saat tidak aktif
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            // Border saat aktif
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(
              color: primaryBlue,
              width: 2.0,
            ), // Warna fokus sesuai tema
          ),
          prefixIcon:
              icon != null
                  ? Icon(icon, color: Colors.black87)
                  : null, // Ganti primaryBlue menjadi hitam
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14, // Padding vertikal lebih besar
            horizontal: 16, // Padding horizontal lebih besar
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        validator:
            validator ??
            (value) {
              // Gunakan validator yang diberikan atau validator default
              if (label.contains('NIK')) {
                if (value == null || value.isEmpty) {
                  return 'NIK wajib diisi';
                }
                if (value.length != 16) {
                  // Validasi panjang NIK
                  return 'NIK harus 16 digit';
                }
              } else if (value == null || value.isEmpty) {
                // Validasi umum untuk field wajib isi
                if (label.contains('Nama Lengkap'))
                  return 'Nama lengkap wajib diisi';
                if (label.contains('Tempat Lahir'))
                  return 'Tempat lahir wajib diisi';
                if (label.contains('Tanggal Lahir'))
                  return 'Tanggal lahir wajib diisi';
                if (label.contains('Alamat Lengkap'))
                  return 'Alamat wajib diisi';
                if (label.contains('Nomor Telepon'))
                  return 'Nomor telepon wajib diisi';
              }
              return null;
            },
      ),
    );
  }

  // Widget untuk dropdown field (mode edit)
  Widget _buildDropdownField(
    String label,
    String? selectedValue,
    List<String> items,
    ValueChanged<String?> onChanged, {
    IconData? icon,
    String? Function(String?)? validator, // Tambahkan validator
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        key: ValueKey(
          label,
        ), // Tambahkan key unik untuk setiap DropdownButtonFormField
        value: selectedValue,
        style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey.shade900),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0), // Sudut lebih membulat
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(
              color: primaryBlue,
              width: 2.0,
            ), // Warna fokus sesuai tema
          ),
          prefixIcon:
              icon != null
                  ? Icon(icon, color: Colors.black87)
                  : null, // Ganti primaryBlue menjadi hitam
          contentPadding: const EdgeInsets.symmetric(
            vertical: 14,
            horizontal: 16,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        items:
            items.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value, style: GoogleFonts.poppins(fontSize: 16)),
              );
            }).toList(),
        onChanged: onChanged,
        validator:
            validator ??
            (value) {
              // Gunakan validator yang diberikan atau validator default
              if (value == null || value.isEmpty) {
                return '$label wajib dipilih.';
              }
              return null;
            },
        dropdownColor: Colors.white, // Warna dropdown item
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Styling untuk AppBar dan loading state agar konsisten
    final appBarTitleStyle = GoogleFonts.montserrat(
      // Menggunakan Montserrat untuk judul AppBar
      fontWeight: FontWeight.w700,
      color: Colors.white,
      fontSize: 22,
    );

    // Common AppBar untuk semua kondisi loading/error/empty/main
    final commonAppBar = AppBar(
      title: Text(
        _isEditing
            ? 'Edit Biodata'
            : 'Detail Biodata', // Judul dinamis di AppBar
        style: appBarTitleStyle,
      ),
      backgroundColor: primaryBlue, // Warna AppBar
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
      elevation: 8, // Elevasi AppBar
      actions: [
        // Tombol edit hanya muncul jika tidak dalam mode edit, tidak loading, tidak error, dan ada data
        // Pastikan juga _userData!['name'] tidak null atau kosong untuk menunjukkan data memang ada
        if (!_isEditing &&
            !_isLoading &&
            _errorMessage == null &&
            _userData != null &&
            (_userData!['name'] != null && _userData!['name'].isNotEmpty))
          IconButton(
            icon: const Icon(
              Icons.edit_note,
              size: 28,
            ), // Ikon edit yang lebih besar
            onPressed: () {
              setState(() {
                _isEditing = true; // Masuk mode edit
              });
            },
          ),
      ],
    );

    // Tampilkan loading indicator saat data sedang diambil
    if (_isLoading) {
      return Scaffold(
        appBar: commonAppBar,
        body: Center(
          child: CircularProgressIndicator(
            color: primaryBlue,
          ), // Warna loading indicator
        ),
      );
    }

    // Tampilkan pesan error jika terjadi kesalahan
    if (_errorMessage != null) {
      return Scaffold(
        appBar: commonAppBar,
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
                  onPressed: _fetchBiodata, // Coba ambil data lagi
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: Text(
                    'Coba Lagi',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue, // Warna tombol elegan
                    foregroundColor: Colors.white,
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

    // Tampilan jika _userData null atau nama kosong (belum ada biodata sama sekali)
    // dan tidak dalam mode edit
    if ((_userData == null ||
            _userData!['name'] == null ||
            _userData!['name'].isEmpty) &&
        !_isEditing) {
      return Scaffold(
        appBar: commonAppBar,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: Colors.grey.shade500, size: 60),
                const SizedBox(height: 20),
                Text(
                  'Data biodata Anda belum lengkap. Silakan lengkapi informasi Anda.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isEditing =
                          true; // Langsung masuk mode edit untuk mengisi
                    });
                  },
                  icon: const Icon(
                    Icons.add_circle_outline,
                    color: Colors.white,
                  ),
                  label: Text(
                    'Lengkapi Biodata',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
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

    // Tampilan utama Biodata (detail atau edit form)
    return Scaffold(
      appBar: commonAppBar, // Menggunakan commonAppBar untuk konsistensi
      body: Container(
        color: Colors.grey.shade50, // Latar belakang body yang sangat terang
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0), // Padding lebih besar
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0), // Sudut lebih membulat
            ),
            elevation: 10, // Elevasi kartu lebih tinggi
            shadowColor: Colors.black.withOpacity(0.15), // Warna shadow
            child: Padding(
              padding: const EdgeInsets.all(
                25.0,
              ), // Padding internal kartu lebih besar
              child: Form(
                // Menggunakan Form untuk validasi
                key: _formKey, // Tambahkan key ke Form
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEditing
                          ? 'Lengkapi Data Diri Anda'
                          : 'Informasi Lengkap Biodata',
                      style: GoogleFonts.montserrat(
                        // Font Montserrat untuk judul
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue, // Warna judul sesuai tema
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isEditing
                          ? 'Pastikan semua informasi terisi dengan benar.'
                          : 'Berikut adalah detail biodata Anda yang tersimpan.',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 30),
                    // Tampilan mode edit atau mode lihat
                    if (_isEditing) ...[
                      _buildEditableField(
                        'Nama Lengkap',
                        _nameController,
                        icon: Icons.person_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama lengkap wajib diisi';
                          }
                          return null;
                        },
                      ),
                      _buildEditableField(
                        'NIK (Nomor Induk Kependudukan)',
                        _nikController,
                        keyboardType: TextInputType.number,
                        icon: Icons.credit_card_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'NIK wajib diisi';
                          }
                          if (value.length != 16) {
                            // Validasi panjang NIK
                            return 'NIK harus 16 digit';
                          }
                          return null; // Penting: kembalikan null jika valid
                        },
                      ),
                      _buildDropdownField(
                        'Jenis Kelamin',
                        _selectedJenisKelamin,
                        _jenisKelaminOptions,
                        (String? newValue) {
                          setState(() {
                            _selectedJenisKelamin = newValue;
                          });
                        },
                        icon: Icons.people_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Jenis Kelamin wajib dipilih.';
                          }
                          return null;
                        },
                      ),
                      _buildEditableField(
                        'Tempat Lahir',
                        _tempatLahirController,
                        icon: Icons.location_city_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Tempat lahir wajib diisi';
                          }
                          return null;
                        },
                      ),
                      _buildEditableField(
                        'Tanggal Lahir (YYYY-MM-DD)',
                        _tanggalLahirController,
                        readOnly: true, // Hanya bisa dipilih dari date picker
                        onTap: () => _selectDate(context),
                        icon: Icons.calendar_today_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Tanggal lahir wajib diisi';
                          }
                          return null;
                        },
                      ),
                      _buildDropdownField(
                        'Agama',
                        _selectedAgama,
                        _agamaOptions,
                        (String? newValue) {
                          setState(() {
                            _selectedAgama = newValue;
                          });
                        },
                        icon: Icons.church_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Agama wajib dipilih.';
                          }
                          return null;
                        },
                      ),
                      _buildEditableField(
                        'Alamat Lengkap',
                        _alamatController,
                        keyboardType: TextInputType.multiline,
                        maxLines: 3, // Izinkan 3 baris untuk alamat
                        icon: Icons.home_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Alamat wajib diisi';
                          }
                          return null;
                        },
                      ),
                      _buildEditableField(
                        'Nomor Telepon/HP',
                        _teleponController,
                        keyboardType: TextInputType.phone,
                        icon: Icons.phone_android_outlined,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nomor telepon wajib diisi';
                          }
                          return null;
                        },
                      ),
                      _buildDropdownField(
                        'Status Pekerjaan',
                        _selectedStatusWarga,
                        _statusWargaOptions,
                        (String? newValue) {
                          setState(() {
                            _selectedStatusWarga = newValue;
                          });
                        },
                        icon: Icons.work_outline,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Status Pekerjaan wajib dipilih.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isLoading
                                      ? null
                                      : _updateBiodata, // Nonaktifkan saat loading
                              icon:
                                  _isLoading
                                      ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : const Icon(
                                        Icons.save,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                              label: Text(
                                _isLoading
                                    ? 'Menyimpan...'
                                    : 'Simpan Perubahan',
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue, // Warna simpan
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    15.0,
                                  ), // Sudut lebih membulat
                                ),
                                elevation: 7, // Elevasi tombol
                              ),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isEditing = false; // Keluar dari mode edit
                                  _initializeControllers(); // Kembalikan perubahan ke data awal
                                });
                              },
                              icon: const Icon(
                                Icons.cancel_outlined,
                                color: Colors.redAccent,
                                size: 24,
                              ),
                              label: Text(
                                'Batal',
                                style: GoogleFonts.poppins(
                                  fontSize: 17,
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15.0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Tampilan mode lihat
                      _buildInfoField('Nama Lengkap', _userData!['name']),
                      _buildInfoField('Email', _userData!['email']),
                      _buildInfoField('NIK', _userData!['nik']),
                      _buildInfoField(
                        'Jenis Kelamin',
                        _userData!['jenis_kelamin'],
                      ),
                      _buildInfoField(
                        'Tempat Lahir',
                        _userData!['tempat_lahir'],
                      ),
                      _buildInfoField(
                        'Tanggal Lahir',
                        _userData!['tanggal_lahir'] != null &&
                                _userData!['tanggal_lahir'].isNotEmpty
                            ? DateFormat(
                              'dd MMMM yyyy',
                              'id_ID',
                            ) // Menggunakan 'id_ID' untuk bulan Indonesia
                            .format(DateTime.parse(_userData!['tanggal_lahir']))
                            : '-',
                      ),
                      _buildInfoField('Agama', _userData!['agama']),
                      _buildInfoField('Alamat', _userData!['alamat']),
                      _buildInfoField('Telepon', _userData!['telepon']),
                      _buildInfoField(
                        'Status Pekerjaan',
                        _userData!['status_warga'],
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _isEditing = true; // Masuk mode edit
                            });
                          },
                          icon: const Icon(
                            Icons.edit_note,
                            color: Colors.white,
                            size: 24,
                          ),
                          label: Text(
                            'Edit Biodata',
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            padding: const EdgeInsets.symmetric(
                              vertical: 18,
                              horizontal: 35,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            elevation: 7,
                          ),
                        ),
                      ),
                    ],
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
