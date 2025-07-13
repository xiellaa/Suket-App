import 'package:flutter/material.dart';
import 'package:suket_desa_app/services/auth_service.dart';
import 'package:suket_desa_app/screens/login_screen.dart'; // Untuk redirect saat logout
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:lottie/lottie.dart'; // Untuk animasi Lottie (pastikan ditambahkan ke pubspec.yaml)

// Admin Screens
import 'package:suket_desa_app/admin/admin_surat_requests_list_screen.dart'; // Masih dibutuhkan, diakses dari kartu summary
import 'package:suket_desa_app/admin/admin_data_warga_screen.dart';
import 'package:suket_desa_app/admin/admin_surat_selesai_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String adminEmail; // Menerima email admin dari main.dart
  const AdminDashboardScreen({super.key, required this.adminEmail});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  String? _adminName; // Untuk menyimpan nama admin
  int _selectedIndex =
      0; // Mengontrol indeks halaman yang dipilih (sekarang default ke Data Surat Keterangan)

  late final PageController _pageController; // Untuk mengontrol PageView
  late final List<String> _pageTitles; // Judul AppBar untuk setiap halaman

  // Data untuk menampilkan jumlah permohonan di halaman "Data Surat Keterangan"
  Map<String, int> _suratCounts = {'SKTM': 0, 'SKU': 0, 'SKD': 0, 'Total': 0};
  bool _isLoadingCounts = true;
  String? _errorMessageCounts;

  bool _isSidebarExpanded = true;

  // Animasi untuk header dashboard
  late AnimationController _headerAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fetchAdminDataAndSuratCounts();
    _pageController = PageController(initialPage: _selectedIndex);

    _pageTitles = <String>[
      'Ringkasan Permohonan', // Sekarang ini adalah halaman ringkasan surat, index 0
      'Data Warga', // Sekarang ini adalah index 1
      'Surat Selesai', // Sekarang ini adalah index 2
    ];

    // Inisialisasi animasi header
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000), // Durasi lebih panjang
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _headerAnimationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _headerAnimationController.forward(); // Mulai animasi saat initState
  }

  @override
  void dispose() {
    _pageController.dispose();
    _headerAnimationController.dispose(); // Dispose controller animasi
    super.dispose();
  }

  // Fungsi untuk mengambil nama admin dan jumlah permohonan surat
  Future<void> _fetchAdminDataAndSuratCounts() async {
    if (!mounted) return;
    setState(() {
      _isLoadingCounts = true;
      _errorMessageCounts = null;
    });

    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final userData = await _authService.getUser(token);
      if (mounted) {
        _adminName = userData['user']['name'];
      }

      final allSuratRequests = await _authService.getAdminSuratRequests(token);

      int sktmCount = 0;
      int skuCount = 0;
      int skdCount = 0;
      int totalPending = 0; // Tambahkan total pending

      for (var req in allSuratRequests) {
        if (req['status'] == 'Diajukan' || req['status'] == 'Diproses') {
          // Hitung yang perlu ditindaklanjuti
          totalPending++;
          if (req['jenis_surat'] == 'SKTM') {
            sktmCount++;
          } else if (req['jenis_surat'] == 'SKU') {
            skuCount++;
          } else if (req['jenis_surat'] == 'SKD') {
            skdCount++;
          }
        }
      }

      if (mounted) {
        setState(() {
          _suratCounts = {
            'SKTM': sktmCount,
            'SKU': skuCount,
            'SKD': skdCount,
            'Total': totalPending, // Perbarui total pending
          };
          _isLoadingCounts = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessageCounts = e.toString().replaceFirst('Exception: ', '');
        _isLoadingCounts = false;
      });
      print('Error fetching admin data or surat counts: $_errorMessageCounts');
      if (e.toString().contains('Unauthorized') ||
          e.toString().contains('Akses ditolak')) {
        await _authService.deleteToken();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Sesi berakhir atau akses ditolak. Silakan login ulang.',
                style: GoogleFonts.poppins(),
              ),
              backgroundColor: Colors.red.shade600,
            ),
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
    }
  }

  // Fungsi untuk logout
  Future<void> _handleLogout() async {
    try {
      final token = await _authService.getToken();
      if (token != null) {
        await _authService.logout(token);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Berhasil logout!', style: GoogleFonts.poppins()),
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
              'Gagal logout: ${e.toString().replaceFirst('Exception: ', '')}',
              style: GoogleFonts.poppins(),
            ),
          ),
        );
      }
    }
  }

  // Fungsi saat item menu sidebar ditekan
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  // Widget untuk halaman "Data Surat Keterangan" yang baru (sebelumnya Dashboard Admin Home)
  Widget _buildSuratKeteranganOverview() {
    if (_isLoadingCounts) {
      return const Center(child: CircularProgressIndicator(color: Colors.teal));
    }

    if (_errorMessageCounts != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700, size: 60),
              const SizedBox(height: 20),
              Text(
                'Terjadi Kesalahan: $_errorMessageCounts\nMohon Coba Lagi.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.red.shade700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _fetchAdminDataAndSuratCounts,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: Text(
                  'Refresh Data',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
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
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0), // Padding lebih besar
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Selamat Datang dengan Animasi
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Container(
                padding: const EdgeInsets.all(25), // Padding lebih besar
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade700, Colors.teal.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(
                    20,
                  ), // Sudut lebih membulat
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        0.2,
                      ), // Shadow lebih gelap
                      spreadRadius: 3,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Contoh ilustrasi sederhana atau ikon admin
                    Icon(
                      Icons
                          .admin_panel_settings_outlined, // Ikon admin yang relevan
                      size: 60,
                      color: Colors.white.withOpacity(0.8),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Halo, ${_adminName ?? 'Administrator'}!',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Selamat datang di Panel Admin SUKET ONLINE Desa UZUMAKI Puruk Cahu.',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                          ),
                          Text(
                            'Anda memiliki ${_suratCounts['Total']} permohonan surat yang menunggu untuk diproses.',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
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

          Text(
            'DAFTAR PERMOHONAN SURAT BARU',
            style: GoogleFonts.montserrat(
              fontSize: 22, // Ukuran lebih besar
              fontWeight: FontWeight.w700,
              color: Colors.teal.shade800,
              letterSpacing: 0.8,
            ),
          ),
          const Divider(height: 25, thickness: 1.5, color: Colors.teal),
          const SizedBox(height: 20),

          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 800 ? 3 : 1,
            childAspectRatio:
                MediaQuery.of(context).size.width > 800
                    ? 1.4
                    : 2.0, // Sesuaikan rasio
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // Non-scrollable
            children: [
              _buildSuratCountCard(
                'SKTM',
                _suratCounts['SKTM']!,
                Icons.description_outlined, // Ikon baru
                Colors.orange.shade700, // Warna yang berbeda dari biru
                () {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder:
                              (context) => const AdminSuratRequestsListScreen(
                                initialJenisSurat: 'SKTM',
                                initialStatus: 'Diajukan',
                              ),
                        ),
                      )
                      .then((_) {
                        _fetchAdminDataAndSuratCounts(); // Panggil ulang untuk refresh
                      });
                },
              ),
              _buildSuratCountCard(
                'SKU',
                _suratCounts['SKU']!,
                Icons.store_outlined, // Ikon baru
                Colors.lightBlue.shade700, // Warna yang berbeda
                () {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder:
                              (context) => const AdminSuratRequestsListScreen(
                                initialJenisSurat: 'SKU',
                                initialStatus: 'Diajukan',
                              ),
                        ),
                      )
                      .then((_) {
                        _fetchAdminDataAndSuratCounts(); // Panggil ulang untuk refresh
                      });
                },
              ),
              _buildSuratCountCard(
                'SKD',
                _suratCounts['SKD']!,
                Icons.location_on_outlined, // Ikon baru
                Colors.purple.shade700, // Warna yang berbeda
                () {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder:
                              (context) => const AdminSuratRequestsListScreen(
                                initialJenisSurat: 'SKD',
                                initialStatus: 'Diajukan',
                              ),
                        ),
                      )
                      .then((_) {
                        _fetchAdminDataAndSuratCounts(); // Panggil ulang untuk refresh
                      });
                },
              ),
            ],
          ),
          const SizedBox(height: 30),
          // Bagian Opsional: Kartu untuk melihat semua surat yang sedang diproses/diajukan
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () {
                Navigator.of(context)
                    .push(
                      MaterialPageRoute(
                        builder:
                            (context) => const AdminSuratRequestsListScreen(
                              initialStatus:
                                  'Diajukan', // Default menampilkan semua yang diajukan
                            ),
                      ),
                    )
                    .then((_) {
                      _fetchAdminDataAndSuratCounts(); // Panggil ulang untuk refresh
                    });
              },
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Icon(Icons.list_alt, color: Colors.teal.shade700, size: 40),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lihat Semua Permohonan Baru',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Total ${_suratCounts['Total']} permintaan menunggu tindakan Anda.',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.grey.shade500),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget untuk Kartu Jumlah Surat dengan ikon dan warna yang lebih dinamis
  Widget _buildSuratCountCard(
    String title,
    int count,
    IconData icon, // Menambahkan parameter ikon
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      color: color, // Gunakan warna yang diberikan
      elevation: 7, // Elevasi sedikit lebih tinggi
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 45,
              ), // Gunakan ikon yang diberikan
              const SizedBox(height: 10),
              Text(
                'Permohonan $title',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                count.toString(),
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 42, // Ukuran font angka lebih besar
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Konten Drawer/Sidebar
  Widget _buildDrawerContent(
    BuildContext context,
    ValueChanged<int> onItemTapped,
    bool forLargeScreen,
  ) {
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        // Header profil admin
        Container(
          height: 220,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade700, Colors.teal.shade500],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Logo Aplikasi atau ilustrasi admin
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.verified_user, // Ikon admin yang stylish
                  size: 50,
                  color: Colors.teal.shade700,
                ),
              ),
              const SizedBox(height: 15),
              Text(
                'SUKET-ONLINE ADMIN', // Judul lebih spesifik
                style: GoogleFonts.montserrat(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              Text(
                _adminName ?? widget.adminEmail,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
        // Label menu
        Padding(
          padding: const EdgeInsets.only(left: 20.0, top: 20.0, bottom: 10.0),
          child: Text(
            'MENU ADMINISTRATOR',
            style: GoogleFonts.montserrat(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 1,
            ),
          ),
        ),
        // Menu item Data Surat Keterangan
        _buildDrawerListItem(
          icon: Icons.assignment_outlined, // Ikon lebih elegan
          title: 'Permohonan Surat',
          index: 0,
          onItemTapped: onItemTapped,
          forLargeScreen: forLargeScreen,
          isSelected: _selectedIndex == 0,
        ),
        // Menu item Data Warga
        _buildDrawerListItem(
          icon: Icons.groups_outlined, // Ikon lebih elegan
          title: 'Data Warga',
          index: 1,
          onItemTapped: onItemTapped,
          forLargeScreen: forLargeScreen,
          isSelected: _selectedIndex == 1,
        ),
        // Menu item Surat Selesai
        _buildDrawerListItem(
          icon: Icons.verified_outlined, // Ikon lebih elegan
          title: 'Surat Selesai',
          index: 2,
          onItemTapped: onItemTapped,
          forLargeScreen: forLargeScreen,
          isSelected: _selectedIndex == 2,
        ),
        const SizedBox(height: 30),
        // Tombol Logout
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
      ],
    );
  }

  // Helper Widget untuk item list di Drawer (disesuaikan agar konsisten)
  Widget _buildDrawerListItem({
    required IconData icon,
    required String title,
    required int index,
    required ValueChanged<int> onItemTapped,
    required bool forLargeScreen,
    required bool isSelected,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? Colors.teal.shade50 : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.teal.shade700 : Colors.grey.shade700,
          size: 26,
        ),
        title: Text(
          title,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.teal.shade900 : Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 16,
          ),
        ),
        onTap: () {
          onItemTapped(index);
          if (!forLargeScreen) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  // Widget untuk Sidebar Permanen (di layar lebar)
  Widget _buildPersistentMenu(
    BuildContext context,
    ValueChanged<int> onItemTapped,
  ) {
    return Material(
      elevation: 8,
      child: Container(
        padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
        color: Theme.of(context).canvasColor,
        child: _buildDrawerContent(context, onItemTapped, true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bool isLargeScreen = screenWidth > 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _pageTitles[_selectedIndex], // Judul dinamis sesuai halaman PageView
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.teal.shade600, // Warna AppBar
        foregroundColor: Colors.white,
        elevation: 6, // Elevasi lebih tinggi
        leading: Builder(
          builder: (BuildContext context) {
            return IconButton(
              icon: const Icon(Icons.menu), // Ikon hamburger
              onPressed: () {
                if (isLargeScreen) {
                  setState(() {
                    _isSidebarExpanded = !_isSidebarExpanded;
                  });
                } else {
                  Scaffold.of(
                    context,
                  ).openDrawer(); // Buka drawer di layar kecil
                }
              },
            );
          },
        ),
      ),
      drawer:
          isLargeScreen
              ? null
              : Drawer(
                child: _buildDrawerContent(
                  context,
                  _onItemTapped,
                  false, // isLargeScreen = false untuk drawer
                ),
              ),
      body: Row(
        children: [
          if (isLargeScreen)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300), // Durasi animasi
              width: _isSidebarExpanded ? 280 : 0, // Lebar sidebar
              child:
                  _isSidebarExpanded // Hanya tampilkan konten jika expanded
                      ? _buildPersistentMenu(context, _onItemTapped)
                      : const SizedBox.shrink(), // Sembunyikan konten jika collapsed
            ),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount:
                        _pageTitles
                            .length, // Sesuaikan dengan jumlah halaman baru
                    onPageChanged: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      switch (index) {
                        case 0:
                          return _buildSuratKeteranganOverview(); // Halaman pertama adalah ringkasan surat
                        case 1:
                          return const AdminDataWargaScreen(); // Data Warga
                        case 2:
                          return const AdminSuratSelesaiScreen(); // Surat Selesai
                        default:
                          return _buildSuratKeteranganOverview();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
