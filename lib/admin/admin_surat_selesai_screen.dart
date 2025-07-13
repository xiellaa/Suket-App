import 'package:flutter/material.dart';
import 'package:suket_desa_app/services/auth_service.dart';
import 'package:suket_desa_app/screens/login_screen.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

class AdminSuratSelesaiScreen extends StatefulWidget {
  const AdminSuratSelesaiScreen({super.key});

  @override
  State<AdminSuratSelesaiScreen> createState() =>
      _AdminSuratSelesaiScreenState();
}

class _AdminSuratSelesaiScreenState extends State<AdminSuratSelesaiScreen> {
  final AuthService _authService = AuthService();
  List<dynamic> _suratRequests = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchCompletedSuratRequests();
  }

  Future<void> _fetchCompletedSuratRequests() async {
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
      final allSuratRequests = await _authService.getAdminSuratRequests(token);

      if (mounted) {
        setState(() {
          _suratRequests =
              allSuratRequests.where((surat) {
                final status = surat['status'] as String;
                return status == 'Disetujui' || status == 'Ditolak';
              }).toList();
          // Urutkan berdasarkan tanggal selesai (updated_at) terbaru
          _suratRequests.sort(
            (a, b) => (b['updated_at'] ?? '').compareTo(a['updated_at'] ?? ''),
          );
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      print('Error fetching completed surat requests: $_errorMessage');
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
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _launchPdf(int suratId) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final String signedUrl = await _authService.getSignedDownloadUrl(
        suratId.toString(),
      );
      print(
        'DEBUG AdminSuratSelesaiScreen: URL PDF yang dihasilkan: $signedUrl',
      );
      final Uri url = Uri.parse(signedUrl);

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        _showSnackbar('Mencoba membuka surat...', isSuccess: true);
      } else {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.inAppWebView);
          _showSnackbar('Mencoba membuka surat di WebView...', isSuccess: true);
        } else {
          _showSnackbar('Tidak dapat membuka link: $url', isError: true);
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackbar(
        'Terjadi kesalahan saat mencoba membuka surat: ${e.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                    : Colors.blueGrey.shade600),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _onRefresh() async {
    await _fetchCompletedSuratRequests();
  }

  // Helper untuk warna status (sama seperti di layar lain)
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Diajukan':
        return Colors.blueGrey.shade600;
      case 'Diproses':
        return Colors.amber.shade700;
      case 'Disetujui':
        return Colors.teal.shade600;
      case 'Ditolak':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  // Helper untuk ikon status (sama seperti di layar lain)
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

  // Fungsi pembantu untuk merapikan teks keperluan SKU (sama seperti di layar lain)
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
    return fullKeperluan;
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
          title: Text('Surat Selesai', style: appBarTitleStyle),
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
          title: Text('Surat Selesai', style: appBarTitleStyle),
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
                  onPressed: _fetchCompletedSuratRequests,
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  label: Text(
                    'Refresh Data',
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

    if (_suratRequests.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Surat Selesai', style: appBarTitleStyle),
          backgroundColor: appBarBackgroundColor,
          foregroundColor: Colors.white,
          elevation: 6,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.mark_email_read_outlined,
                color: Colors.grey.shade400,
                size: 80,
              ), // Ikon untuk surat selesai
              const SizedBox(height: 20),
              Text(
                'Tidak ada surat yang telah selesai diproses.',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Surat yang disetujui atau ditolak akan muncul di sini.',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Surat Selesai', style: appBarTitleStyle),
        backgroundColor: appBarBackgroundColor,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      body: Container(
        color: Colors.grey.shade50, // Latar belakang body
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: Colors.teal, // Warna indicator refresh
          child: ListView.separated(
            padding: const EdgeInsets.all(20.0), // Padding lebih besar
            itemCount: _suratRequests.length,
            separatorBuilder:
                (context, index) =>
                    const SizedBox(height: 15), // Spasi antar card
            itemBuilder: (context, index) {
              final request = _suratRequests[index];
              final user = request['user'];
              final jenisSurat = (request['jenis_surat'] as String?) ?? '-';
              final status = (request['status'] as String?) ?? '-';
              final nomorSurat = (request['nomor_surat'] as String?) ?? '-';
              final updatedAt = (request['updated_at'] as String?);

              String displayedKeperluan =
                  (request['keperluan'] as String?) ?? '-';
              if (jenisSurat == 'SKU') {
                displayedKeperluan = _formatKeperluanSKU(displayedKeperluan);
              }

              final bool canDownload =
                  status == 'Disetujui' && nomorSurat != '-';

              return Card(
                elevation: 8, // Elevasi kartu
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                shadowColor: Colors.black.withOpacity(0.1), // Warna shadow
                child: ExpansionTile(
                  // Menggunakan ExpansionTile
                  collapsedShape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(
                      status,
                    ).withOpacity(0.1), // Latar belakang avatar sesuai status
                    child: Icon(
                      _getStatusIcon(status), // Ikon sesuai status
                      color: _getStatusColor(status),
                      size: 28,
                    ),
                  ),
                  title: Text(
                    jenisSurat.toUpperCase(), // Jenis surat kapital
                    style: GoogleFonts.montserrat(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pemohon: ${user?['name'] ?? 'N/A'}',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      Text(
                        'Status: $status',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.grey.shade600,
                  ), // Ikon panah expand
                  children: <Widget>[
                    const Divider(
                      height: 1,
                      thickness: 1,
                      indent: 20,
                      endIndent: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20.0,
                        vertical: 10.0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow('Nomor Surat', nomorSurat),
                          _buildDetailRow('NIK Pemohon', user?['nik'] ?? 'N/A'),
                          _buildDetailRow('Keperluan', displayedKeperluan),
                          _buildDetailRow(
                            'Tanggal Selesai',
                            updatedAt != null
                                ? DateFormat(
                                  'dd MMMM hafa, HH:mm',
                                  'id_ID',
                                ).format(DateTime.parse(updatedAt))
                                : '-',
                          ),
                          _buildDetailRow(
                            'Diproses Oleh',
                            'Admin',
                          ), // Asumsi diproses oleh Admin
                          const SizedBox(height: 15),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: ElevatedButton.icon(
                              onPressed:
                                  canDownload
                                      ? () => _launchPdf(request['id'])
                                      : null,
                              icon: Icon(Icons.download, size: 20),
                              label: Text(
                                canDownload
                                    ? 'Unduh Surat'
                                    : 'Surat Tidak Tersedia',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    canDownload
                                        ? Colors.teal.shade700
                                        : Colors.grey.shade500,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 15,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // Helper widget untuk baris detail di dalam ExpansionTile
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140, // Lebar tetap untuk label
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
