import 'package:flutter/material.dart';
import 'package:suket_desa_app/services/auth_service.dart';
import 'package:suket_desa_app/screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart'; // Tetap diimpor jika ada rencana menggunakan Lottie di sini
import 'package:animate_do/animate_do.dart';

// Import halaman-halaman yang akan menjadi konten dashboard
import 'package:suket_desa_app/screens/data_suket_screen.dart';
import 'package:suket_desa_app/screens/biodata_screen.dart';
import 'package:suket_desa_app/screens/status_request_screen.dart';

class DashboardScreen extends StatefulWidget {
  final String userEmail;
  const DashboardScreen({super.key, required this.userEmail});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  String? _userName;
  int _selectedIndex = 0; // Mengontrol indeks halaman yang dipilih

  late final List<String> _pageTitles; // Judul untuk setiap halaman konten

  bool _isBiodataComplete = false;
  bool _isSidebarExpanded =
      true; // Untuk mengontrol lebar sidebar di layar besar

  // Animasi untuk header dashboard (di halaman utama)
  late AnimationController _headerAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fetchUserDataAndBiodataStatus();

    _pageTitles = <String>[
      'Beranda', // Index 0
      'Ajukan Surat Keterangan', // Index 1
      'Data Diri Anda', // Index 2
      'Status Permohonan', // Index 3
    ];

    // Inisialisasi animasi header
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOut,
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeInOutBack,
      ),
    );

    // Mulai animasi hanya jika halaman yang pertama adalah beranda
    if (_selectedIndex == 0) {
      _headerAnimationController.forward();
    }
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserDataAndBiodataStatus() async {
    if (!mounted) return;
    try {
      final token = await _authService.getToken();
      if (token == null) {
        _authService.deleteToken();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
        return;
      }

      final userData = await _authService.getUser(token);
      final bool biodataStatus = await _authService.isBiodataComplete();

      if (!mounted) return;
      setState(() {
        _userName = userData['user']['name'];
        _isBiodataComplete = biodataStatus;
      });
    } catch (e) {
      print(
        'Failed to fetch user data or biodata status: ${e.toString().replaceFirst('Exception: ', '')}',
      );
      _authService.deleteToken();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sesi berakhir atau gagal memuat data: ${e.toString().replaceFirst('Exception: ', '')}',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      final token = await _authService.getToken();
      if (token != null) {
        await _authService.logout(token);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Anda berhasil keluar!',
                style: GoogleFonts.poppins(color: Colors.white),
              ),
              backgroundColor: Colors.green.shade600,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal keluar: ${e.toString().replaceFirst('Exception: ', '')}',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            backgroundColor: Colors.red.shade600,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  void _onItemTapped(int index) async {
    if (index == 1) {
      // Index untuk 'Ajukan Surat Keterangan'
      if (!_isBiodataComplete) {
        await _showBiodataRequiredDialog();
        return;
      }
    }

    setState(() {
      _selectedIndex = index;
      // PENTING: Memicu ulang animasi saat kembali ke halaman Beranda
      if (index == 0) {
        _headerAnimationController.reset();
        _headerAnimationController.forward();
      }
    });
  }

  Future<void> _showBiodataRequiredDialog() async {
    final Color primaryBlue = const Color(0xFF007AFF);

    await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Biodata Belum Lengkap',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          content: Text(
            'Anda harus melengkapi biodata terlebih dahulu sebelum dapat mengajukan permohonan surat. Silakan lengkapi biodata Anda.',
            style: GoogleFonts.poppins(color: Colors.grey.shade700),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: Text(
                'Nanti Saja',
                style: GoogleFonts.poppins(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop(false);
                final bool? biodataUpdated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BiodataScreen(),
                  ),
                );

                if (biodataUpdated == true) {
                  await _fetchUserDataAndBiodataStatus();
                  if (_isBiodataComplete && mounted) {
                    setState(() {
                      _selectedIndex = 1;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Biodata lengkap! Silakan lanjutkan.',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        backgroundColor: Colors.green.shade600,
                        duration: const Duration(seconds: 3),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Lengkapi Sekarang',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  // Widget untuk poin-poin panduan
  Widget _buildGuidancePoint({
    required IconData icon,
    required String text,
    bool isNote = false,
  }) {
    final Color primaryBlue = const Color(0xFF007AFF);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: isNote ? Colors.orange.shade700 : primaryBlue,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Konten halaman Beranda
  Widget _buildDashboardHomeContent() {
    final Color primaryBlue = const Color(0xFF007AFF);
    final Color darkBlue = const Color(0xFF0056B3);

    return SingleChildScrollView(
      key: const ValueKey(
        'DashboardHomeContent',
      ), // Tambahkan key untuk stabilitas
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bagian Header Selamat Datang dengan Animasi
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBlue, darkBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blueGrey.withOpacity(0.3),
                      spreadRadius: 4,
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.account_circle,
                        size: 45,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, ${_userName ?? widget.userEmail}!',
                            style: GoogleFonts.montserrat(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Selamat datang di portal permohonan surat keterangan desa Anda. Mari mudahkan urusan administrasi Anda!',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Bagian Informasi Penting
          Text(
            'PANDUAN PENGGUNAAN APLIKASI',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade700,
              letterSpacing: 0.8,
            ),
          ),
          const Divider(height: 25, thickness: 1.5, color: Colors.blueGrey),
          Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Langkah-langkah Pengajuan Surat:',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildGuidancePoint(
                    icon: Icons.person_add_alt_1_outlined,
                    text:
                        'Lengkapi biodata Anda di menu "Profil Saya" untuk proses yang lebih cepat.',
                  ),
                  _buildGuidancePoint(
                    icon: Icons.description_outlined,
                    text:
                        'Pilih jenis surat yang Anda butuhkan di menu "Ajukan Surat" sesuai keperluan.',
                  ),
                  _buildGuidancePoint(
                    icon: Icons.cloud_upload_outlined,
                    text:
                        'Unggah dokumen pendukung (KTP & KK) yang diperlukan dengan jelas.',
                  ),
                  _buildGuidancePoint(
                    icon: Icons.track_changes_outlined,
                    text:
                        'Pantau status permohonan Anda secara real-time di menu "Status Permohonan".',
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Catatan Penting:',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrangeAccent,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildGuidancePoint(
                    icon: Icons.download_for_offline_outlined,
                    text:
                        'Surat yang sudah disetujui dapat diunduh langsung dalam format PDF.',
                    isNote: true,
                  ),
                  _buildGuidancePoint(
                    icon: Icons.wifi_outlined,
                    text:
                        'Pastikan koneksi internet Anda stabil untuk menghindari kendala saat mengajukan surat.',
                    isNote: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // Fungsi helper untuk mendapatkan widget halaman berdasarkan index
  Widget _getPageWidget(int index) {
    // Tambahkan ValueKey untuk setiap halaman agar state-nya terjaga
    // dan Flutter dapat mengidentifikasi widget dengan lebih baik saat tree berubah.
    switch (index) {
      case 0:
        return _buildDashboardHomeContent();
      case 1:
        return const DataSuketScreen(key: ValueKey('DataSuketScreen'));
      case 2:
        return const BiodataScreen(key: ValueKey('BiodataScreen'));
      case 3:
        return const StatusRequestScreen(key: ValueKey('StatusRequestScreen'));
      default:
        return _buildDashboardHomeContent();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 600;

    // final Color primaryBlue = const Color(0xFF007AFF); // Dihapus karena AppBar dihapus
    // final Color darkBlue = const Color(0xFF0056B3); // Dihapus karena AppBar dihapus

    return Scaffold(
      // AppBar sepenuhnya dihapus dari sini
      drawer:
          isLargeScreen
              ? null
              : Drawer(
                key: const ValueKey('mobileDrawer'), // Tambahkan key
                child: _buildDrawerContent(context, _onItemTapped, false),
              ),
      body: Row(
        children: [
          // Sidebar permanen di layar besar
          if (isLargeScreen)
            AnimatedContainer(
              key: const ValueKey('persistentSidebar'), // Tambahkan key
              duration: const Duration(milliseconds: 300),
              width:
                  _isSidebarExpanded
                      ? 280
                      : 70, // Lebar sidebar expanded atau collapsed
              decoration: BoxDecoration(
                color: Colors.white, // Background putih
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(2, 0), // Shadow ke kanan
                  ),
                ],
              ),
              child: _buildPersistentMenu(
                context,
                _onItemTapped,
                _isSidebarExpanded,
              ),
            ),
          // Konten utama (tidak lagi ada custom header di sini, langsung isi halaman)
          Expanded(
            key: const ValueKey('mainContentArea'), // Tambahkan key
            child: _getPageWidget(
              _selectedIndex,
            ), // Panggil fungsi untuk mendapatkan widget halaman
          ),
        ],
      ),
    );
  }

  // Konten Drawer/Sidebar
  Widget _buildDrawerContent(
    BuildContext context,
    ValueChanged<int> onItemTapped,
    bool isExpanded,
  ) {
    final Color primaryBlue = const Color(0xFF007AFF);
    final Color darkBlue = const Color(0xFF0056B3);

    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        // Header profil pengguna
        Container(
          height: isExpanded ? 220 : 100, // Tinggi header responsif
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryBlue, darkBlue],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.all(20.0),
          child:
              isExpanded
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      FadeInDown(
                        duration: const Duration(milliseconds: 600),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo.png', // PASTIKAN PATH INI BENAR KE LOGO ANDA
                            height: 70,
                            width: 70,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => const Icon(
                                  Icons.mail_outline,
                                  size: 70,
                                  color: Colors.white,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      FadeInLeft(
                        duration: const Duration(milliseconds: 700),
                        child: Text(
                          'SUKET-ONLINE',
                          style: GoogleFonts.montserrat(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      FadeInLeft(
                        duration: const Duration(milliseconds: 800),
                        child: Text(
                          _userName ?? widget.userEmail,
                          style: GoogleFonts.poppins(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  )
                  : Center(
                    // Tampilan ringkas saat collapsed
                    child: FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.png',
                          height: 50,
                          width: 50,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) => const Icon(
                                Icons.mail_outline,
                                size: 50,
                                color: Colors.white,
                              ),
                        ),
                      ),
                    ),
                  ),
        ),
        // Label fitur
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 20.0, top: 20.0, bottom: 10.0),
            child: Text(
              'MENU UTAMA',
              style: GoogleFonts.montserrat(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ),
        // Menu item Dashboard (Index 0)
        _buildDrawerListItem(
          icon: Icons.home_outlined,
          title: 'Beranda',
          index: 0,
          onItemTapped: onItemTapped,
          isExpanded: isExpanded,
          isSelected: _selectedIndex == 0,
          animationDelay: 0,
        ),
        // Menu item Data Suket (Index 1)
        _buildDrawerListItem(
          icon: Icons.description_outlined,
          title: 'Ajukan Surat Keterangan',
          index: 1,
          onItemTapped: onItemTapped,
          isExpanded: isExpanded,
          isSelected: _selectedIndex == 1,
          animationDelay: 100,
        ),
        // Menu item Biodata Anda (Index 2)
        _buildDrawerListItem(
          icon: Icons.person_outline,
          title: 'Data Diri Anda',
          index: 2,
          onItemTapped: onItemTapped,
          isExpanded: isExpanded,
          isSelected: _selectedIndex == 2,
          animationDelay: 200,
        ),
        // Menu item Status Request (Index 3)
        _buildDrawerListItem(
          icon: Icons.checklist_rtl_outlined,
          title: 'Status Permohonan',
          index: 3,
          onItemTapped: onItemTapped,
          isExpanded: isExpanded,
          isSelected: _selectedIndex == 3,
          animationDelay: 300,
        ),
        const SizedBox(height: 30),
        // Tombol Logout
        if (isExpanded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: FadeInUp(
              duration: const Duration(milliseconds: 900),
              delay: const Duration(milliseconds: 400),
              child: ElevatedButton(
                onPressed: _handleLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent.shade400,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.logout, size: 26),
                    const SizedBox(width: 10),
                    Text(
                      'Keluar',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Helper Widget untuk item list di Drawer/Sidebar
  Widget _buildDrawerListItem({
    required IconData icon,
    required String title,
    required int index,
    required ValueChanged<int> onItemTapped,
    required bool isExpanded,
    required bool isSelected,
    required int animationDelay,
  }) {
    final Color primaryBlue = const Color(0xFF007AFF);
    final Color translucentBlue = primaryBlue.withOpacity(0.1);
    final Color hoverBlue = primaryBlue.withOpacity(0.05);

    return FadeInRight(
      duration: const Duration(milliseconds: 500),
      delay: Duration(milliseconds: animationDelay),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? translucentBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: isSelected ? primaryBlue : Colors.grey.shade700,
            size: 26,
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              color: isSelected ? primaryBlue : Colors.grey.shade800,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              fontSize: isExpanded ? 16 : 12,
            ),
            overflow: isExpanded ? TextOverflow.clip : TextOverflow.ellipsis,
            maxLines: 1,
            softWrap: false,
          ),
          onTap: () {
            onItemTapped(index);
            if (!isExpanded && MediaQuery.of(context).size.width < 600) {
              Navigator.pop(context); // Tutup drawer di layar kecil
            }
          },
          selected: isSelected,
          hoverColor: hoverBlue,
        ),
      ),
    );
  }

  // Widget untuk Sidebar Permanen (di layar lebar)
  Widget _buildPersistentMenu(
    BuildContext context,
    ValueChanged<int> onItemTapped,
    bool isExpanded,
  ) {
    return Material(
      elevation: 8,
      child: Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        color: Theme.of(context).canvasColor,
        child: _buildDrawerContent(context, onItemTapped, isExpanded),
      ),
    );
  }
}
