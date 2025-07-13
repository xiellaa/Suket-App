import 'package:flutter/material.dart';
import 'package:suket_desa_app/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:suket_desa_app/screens/login_screen.dart'; // Pastikan jalur ini benar
import 'package:suket_desa_app/screens/surat_view_screen.dart'; // Pastikan ini diimpor
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

class StatusRequestScreen extends StatefulWidget {
  const StatusRequestScreen({super.key});

  @override
  State<StatusRequestScreen> createState() => _StatusRequestScreenState();
}

class _StatusRequestScreenState extends State<StatusRequestScreen> {
  final AuthService _authService = AuthService();
  List<dynamic> _suratRequests = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Definisi warna biru konsisten Anda
  final Color primaryBlue = const Color(0xFF007AFF); // Biru utama
  final Color darkBlue = const Color(0xFF0056B3); // Biru tua untuk gradasi

  @override
  void initState() {
    super.initState();
    _fetchSuratRequests();
  }

  Future<void> _fetchSuratRequests() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token not found. Silakan login kembali.');
      }
      final List<dynamic> requests = await _authService.getUserSuratRequests(
        token,
      );

      if (!mounted) return;
      setState(() {
        _suratRequests = requests;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      if (e.toString().contains('Unauthorized')) {
        await _authService.deleteToken();
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const LoginScreen()),
          );
        }
      }
      _showSnackbar('Error: $_errorMessage', isError: true);
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Mengubah warna status agar lebih elegan dan konsisten dengan tema biru
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Diajukan':
        return primaryBlue; // Biru utama untuk "Diajukan"
      case 'Diproses':
        return Colors.amber.shade700; // Tetap kuning tua untuk "Diproses"
      case 'Disetujui':
        return Colors
            .green
            .shade600; // Hijau yang lebih cerah untuk "Disetujui"
      case 'Ditolak':
        return Colors.red.shade600; // Merah untuk "Ditolak"
      default:
        return Colors.grey.shade600;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Diajukan':
        return Icons.pending_actions_outlined;
      case 'Diproses':
        return Icons.hourglass_empty_outlined;
      case 'Disetujui':
        return Icons.check_circle_outline;
      case 'Ditolak':
        return Icons.cancel_outlined;
      default:
        return Icons.info_outline;
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins(color: Colors.white)),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating, // Efek floating
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Fungsi pembantu untuk merapikan teks keperluan SKU
  String _formatKeperluanSKU(String fullKeperluan) {
    if (fullKeperluan.contains('Pengajuan SKU untuk jenis usaha:')) {
      final RegExp regExp = RegExp(
        r'Pengajuan SKU untuk jenis usaha: "([^"]*)". Keperluan: "([^"]*)"',
      );
      final match = regExp.firstMatch(fullKeperluan);
      if (match != null) {
        final jenisUsaha = match.group(1);
        final keperluanDetail = match.group(2);
        return 'Jenis Usaha: "$jenisUsaha"\nKeperluan: "$keperluanDetail"';
      }
    }
    return fullKeperluan; // Kembali ke teks asli jika format tidak cocok
  }

  @override
  Widget build(BuildContext context) {
    // Definisi gaya teks umum
    final appBarTitleStyle = GoogleFonts.montserrat(
      // Menggunakan Montserrat untuk AppBar
      fontWeight: FontWeight.w700,
      color: Colors.white,
      fontSize: 22,
    );

    // Common AppBar (used for loading, error, empty, and main states)
    final commonAppBar = AppBar(
      title: Text('Status Permohonan Surat', style: appBarTitleStyle),
      backgroundColor: primaryBlue, // Warna AppBar loading state
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
      elevation: 8, // Elevasi lebih tinggi
    );

    if (_isLoading) {
      return Scaffold(
        appBar: commonAppBar,
        body: Center(
          child: CircularProgressIndicator(
            color: primaryBlue, // Warna indicator
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: commonAppBar,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade700, size: 60),
              const SizedBox(height: 20),
              Text(
                'Terjadi Kesalahan: $_errorMessage',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  color: Colors.red.shade700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _fetchSuratRequests,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: Text(
                  'Coba Lagi',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
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
      );
    }

    if (_suratRequests.isEmpty) {
      return Scaffold(
        appBar: commonAppBar,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, color: Colors.grey.shade400, size: 80),
              const SizedBox(height: 20),
              Text(
                'Belum ada permohonan surat.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Ajukan surat baru melalui menu "Ajukan Surat Keterangan" di samping!',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: () {
                  // Kembali ke dashboard (index 1 untuk "Data Suket")
                  // Jika ini adalah bagian dari PageView di Dashboard, Anda tidak perlu navigasi di sini.
                  // Asumsi ini adalah layar mandiri untuk demo.
                  Navigator.pop(
                    context,
                  ); // Kembali ke layar sebelumnya (Dashboard)
                },
                icon: const Icon(Icons.add_box_outlined, color: Colors.white),
                label: Text(
                  'Ajukan Surat Baru',
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue, // Warna tombol
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
      );
    }

    return Scaffold(
      appBar: commonAppBar,
      body: Container(
        color: Colors.grey.shade50, // Latar belakang body yang sangat terang
        child: ListView.builder(
          padding: const EdgeInsets.all(20.0), // Padding lebih besar
          itemCount: _suratRequests.length,
          itemBuilder: (context, index) {
            final Map<String, dynamic>? request =
                _suratRequests[index] as Map<String, dynamic>?;

            if (request == null) {
              return const SizedBox.shrink();
            }

            final String jenisSurat =
                (request['jenis_surat'] as String?) ?? '-';
            final String keperluan = (request['keperluan'] as String?) ?? '-';
            final String status = (request['status'] as String?) ?? 'Diajukan';
            final String nomorSurat =
                (request['nomor_surat'] as String?) ?? '-';
            final String? createdAtRaw = request['created_at'] as String?;
            final int? requestId = request['id'] as int?;

            DateTime createdAt;
            try {
              createdAt = DateTime.parse(
                createdAtRaw ?? DateTime.now().toIso8601String(),
              );
            } catch (e) {
              createdAt = DateTime.now();
            }

            final bool canView =
                requestId != null &&
                (status == 'Disetujui' ||
                    status ==
                        'Ditolak'); // Hanya bisa dilihat jika disetujui/ditolak

            // Perbaikan: Format teks keperluan SKU
            String displayedKeperluan = keperluan;
            if (jenisSurat == 'SKU') {
              displayedKeperluan = _formatKeperluanSKU(keperluan);
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 20.0), // Margin antar card
              elevation: 8, // Elevasi lebih tinggi
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15), // Sudut lebih membulat
              ),
              shadowColor: Colors.black.withOpacity(0.15), // Warna shadow
              child: Padding(
                padding: const EdgeInsets.all(20.0), // Padding internal card
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            jenisSurat.toUpperCase(), // Huruf kapital semua
                            style: GoogleFonts.montserrat(
                              // Menggunakan Montserrat
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color:
                                  Colors
                                      .black87, // Ganti darkBlue menjadi hitam
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status),
                            borderRadius: BorderRadius.circular(
                              20,
                            ), // Badge lebih membulat
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(status),
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                status,
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(
                      height: 25,
                      thickness: 1,
                      color: Colors.grey,
                    ), // Divider elegan
                    Text(
                      'Diajukan pada: ${DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(createdAt)}', // Format tanggal lebih lengkap
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Keperluan:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      displayedKeperluan,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.grey.shade900,
                      ),
                      maxLines: 3, // Batasi jumlah baris untuk keperluan
                      overflow:
                          TextOverflow
                              .ellipsis, // Tambahkan ellipsis jika terlalu panjang
                    ),
                    const SizedBox(height: 16),
                    // Hanya tampilkan Nomor Surat jika statusnya 'Disetujui' dan ada nomornya
                    if (status == 'Disetujui' && nomorSurat != '-') ...[
                      Text(
                        'Nomor Surat:',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87, // Ganti darkBlue menjadi hitam
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        nomorSurat,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color:
                              Colors.black87, // Ganti primaryBlue menjadi hitam
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Align(
                      alignment: Alignment.bottomRight,
                      child: ElevatedButton.icon(
                        onPressed:
                            canView
                                ? () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => SuratViewScreen(
                                            suratId: requestId!,
                                          ),
                                    ),
                                  );
                                }
                                : null, // Tombol non-aktif jika tidak bisa dilihat
                        icon: const Icon(Icons.visibility_outlined, size: 22),
                        label: Text(
                          canView
                              ? 'Lihat/Unduh Surat'
                              : 'Detail Tidak Tersedia',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              canView
                                  ? primaryBlue // Warna tombol dinamis
                                  : Colors.grey.shade500,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              10,
                            ), // Sudut membulat
                          ),
                          elevation: 5, // Elevasi tombol
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
