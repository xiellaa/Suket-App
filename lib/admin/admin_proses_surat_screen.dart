import 'package:flutter/material.dart';
import 'package:suket_desa_app/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart'; // Untuk membuka URL (misal: gambar scan atau PDF)
import 'package:intl/intl.dart'; // Untuk format tanggal
import 'package:suket_desa_app/screens/login_screen.dart'; // Pastikan path ini benar
import 'package:suket_desa_app/screens/surat_view_screen.dart'; // Import SuratViewScreen untuk Lihat Detail (admin juga bisa lihat)
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

class AdminProsesSuratScreen extends StatefulWidget {
  final int suratId; // ID surat yang akan diproses

  const AdminProsesSuratScreen({super.key, required this.suratId});

  @override
  State<AdminProsesSuratScreen> createState() => _AdminProsesSuratScreenState();
}

class _AdminProsesSuratScreenState extends State<AdminProsesSuratScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _suratDetail;
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _nomorSuratController = TextEditingController();
  String? _selectedStatus; // Status yang dipilih dari dropdown

  final List<String> _statusOptions = [
    'Diajukan',
    'Diproses',
    'Disetujui',
    'Ditolak',
  ];

  @override
  void initState() {
    super.initState();
    _fetchSuratDetail();
  }

  @override
  void dispose() {
    _nomorSuratController.dispose();
    super.dispose();
  }

  Future<void> _fetchSuratDetail() async {
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
      final data = await _authService.getSuratDetail(
        widget.suratId.toString(),
        token,
      );
      if (mounted) {
        setState(() {
          _suratDetail = data;
          _selectedStatus =
              _suratDetail!['status']; // Set status awal dari data
          _nomorSuratController.text =
              _suratDetail!['nomor_surat'] ?? ''; // Set nomor surat awal
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      print('Error fetching surat detail: $_errorMessage');
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

  Future<void> _updateSuratStatus() async {
    if (_selectedStatus == null) {
      _showSnackbar('Silakan pilih status surat.', isError: true);
      return;
    }

    if (_selectedStatus == 'Disetujui' &&
        _nomorSuratController.text.trim().isEmpty) {
      _showSnackbar(
        'Nomor surat wajib diisi jika status Disetujui.',
        isError: true,
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true; // Tampilkan loading saat update
    });

    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      await _authService.updateSuratStatusAdmin(
        token,
        widget.suratId,
        _selectedStatus!,
        _nomorSuratController.text.trim().isEmpty
            ? null
            : _nomorSuratController.text.trim(),
      );

      if (mounted) {
        _showSnackbar('Status surat berhasil diperbarui!', isSuccess: true);
        Navigator.pop(
          context,
          true,
        ); // Kembali ke daftar dan kirim sinyal refresh
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      _showSnackbar('Gagal memperbarui status: $_errorMessage', isError: true);
      print('Error updating surat status: $_errorMessage');
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
          _isLoading = false; // Sembunyikan loading
        });
      }
    }
  }

  // Fungsi untuk membuka URL (misal: gambar scan KTP/KK)
  Future<void> _launchUrl(String url) async {
    print(
      'DEBUG AdminProsesSuratScreen: Mencoba meluncurkan URL: $url',
    ); // Debug print
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        _showSnackbar('Tidak dapat membuka URL: $url', isError: true);
      }
    }
  }

  // Mengubah fungsi showSnackbar agar konsisten
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
    // Definisi gaya teks umum untuk AppBar
    final appBarTitleStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );
    final appBarBackgroundColor = Colors.teal.shade600;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detail & Proses Surat', style: appBarTitleStyle),
        backgroundColor: appBarBackgroundColor,
        foregroundColor: Colors.white,
        elevation: 6, // Elevasi AppBar
      ),
      body: Container(
        color: Colors.grey.shade50, // Latar belakang body
        child:
            _isLoading
                ? const Center(
                  child: CircularProgressIndicator(color: Colors.teal),
                )
                : _errorMessage != null
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade700,
                          size: 60,
                        ),
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
                          onPressed: _fetchSuratDetail,
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
                )
                : _suratDetail == null
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey.shade400,
                        size: 80,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Detail surat tidak ditemukan.',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          color: Colors.grey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detail Permohonan Surat',
                            style: GoogleFonts.montserrat(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Informasi lengkap mengenai permohonan surat ini.',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const Divider(
                            height: 30,
                            thickness: 1.5,
                            color: Colors.teal,
                          ), // Divider lebih tebal
                          _buildDetailRow(
                            'Jenis Surat',
                            (_suratDetail!['jenis_surat'] as String?)
                                    ?.toUpperCase() ??
                                '-', // Huruf kapital
                            Icons.mail_outline, // Icon jenis surat
                          ),
                          _buildDetailRow(
                            'Nama Pemohon',
                            _suratDetail!['user']['name'] ?? 'N/A',
                            Icons.person_outline, // Icon nama pemohon
                          ),
                          _buildDetailRow(
                            'NIK Pemohon',
                            _suratDetail!['user']['nik'] ?? 'N/A',
                            Icons.credit_card_outlined, // Icon NIK
                          ),
                          // Perbaikan untuk keperluan SKU
                          if (_suratDetail!['jenis_surat'] == 'SKU')
                            _buildDetailRow(
                              'Detail Keperluan',
                              _formatKeperluanSKU(
                                _suratDetail!['keperluan'] ?? '-',
                              ),
                              Icons.info_outline,
                            )
                          else
                            _buildDetailRow(
                              'Keperluan',
                              _suratDetail!['keperluan'] ?? '-',
                              Icons.assignment_outlined, // Icon keperluan umum
                            ),

                          _buildDetailRow(
                            'Tanggal Diajukan',
                            _suratDetail!['created_at'] != null
                                ? DateFormat(
                                  'dd MMMM yyyy, HH:mm', // Format lebih lengkap
                                  'id_ID', // Locale Indonesia
                                ).format(
                                  DateTime.parse(_suratDetail!['created_at']),
                                )
                                : 'N/A',
                            Icons.calendar_today_outlined, // Icon tanggal
                          ),
                          _buildDetailRow(
                            'Status Saat Ini',
                            _suratDetail!['status'] ?? '-',
                            _getStatusIcon(
                              _suratDetail!['status'] ?? 'Diajukan',
                            ), // Icon status
                            statusColor: _getStatusColor(
                              _suratDetail!['status'] ?? 'Diajukan',
                            ), // Warna status
                          ),
                          if (_suratDetail!['nomor_surat'] != null &&
                              _suratDetail!['nomor_surat'].isNotEmpty)
                            _buildDetailRow(
                              'Nomor Surat',
                              _suratDetail!['nomor_surat'],
                              Icons
                                  .confirmation_number_outlined, // Icon nomor surat
                            ),

                          const SizedBox(height: 30),
                          Text(
                            'Dokumen Pendukung',
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
                          _buildDocumentLink(
                            'Scan KTP',
                            _suratDetail!['scan_ktp_path'],
                            Icons.image_outlined, // Icon KTP
                          ),
                          _buildDocumentLink(
                            'Scan KK',
                            _suratDetail!['scan_kk_path'],
                            Icons.collections_bookmark_outlined, // Icon KK
                          ),
                          const SizedBox(height: 30),
                          Text(
                            'Proses Surat',
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
                          DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey.shade900,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Ubah Status Surat',
                              labelStyle: GoogleFonts.poppins(
                                color: Colors.grey.shade600,
                              ),
                              prefixIcon: Icon(
                                Icons.compare_arrows_outlined,
                                color: Colors.teal.shade700,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.teal.shade700,
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
                            items:
                                _statusOptions.map((String status) {
                                  return DropdownMenuItem<String>(
                                    value: status,
                                    child: Text(
                                      status,
                                      style: GoogleFonts.poppins(),
                                    ),
                                  );
                                }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedStatus = newValue;
                              });
                            },
                          ),
                          const SizedBox(height: 15),
                          TextField(
                            controller: _nomorSuratController,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey.shade900,
                            ),
                            decoration: InputDecoration(
                              labelText:
                                  'Nomor Surat (Opsional, Wajib jika Disetujui)',
                              hintText: 'Contoh: 470/123/DS/2024',
                              labelStyle: GoogleFonts.poppins(
                                color: Colors.grey.shade600,
                              ),
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.grey.shade400,
                              ),
                              prefixIcon: Icon(
                                Icons.numbers_outlined,
                                color: Colors.teal.shade700,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade300,
                                  width: 1.5,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.teal.shade700,
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
                          ),
                          const SizedBox(height: 30),
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _updateSuratStatus,
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
                                      ),
                              label: Text(
                                _isLoading
                                    ? 'Menyimpan...'
                                    : 'Simpan Perubahan',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 35,
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
      ),
    );
  }

  // Widget _buildDetailRow yang diperbarui dengan ikon
  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon, {
    Color? statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal.shade600, size: 22),
          const SizedBox(width: 12),
          SizedBox(
            width: 140, // Lebar tetap untuk label
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 15,
                color: statusColor ?? Colors.grey.shade900,
                fontWeight:
                    statusColor != null ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildDocumentLink yang diperbarui dengan ikon dan styling
  Widget _buildDocumentLink(String label, String? rawPath, IconData icon) {
    // Pastikan path lengkap ke file, termasuk base URL storage
    final String? fullUrl =
        rawPath != null && rawPath.isNotEmpty
            ? '${_authService.baseUrl.replaceFirst('/api', '')}/storage/$rawPath'
            : null;

    // Debug print
    print(
      'DEBUG _buildDocumentLink: Path mentah: $rawPath, URL lengkap: $fullUrl',
    );

    if (fullUrl == null || fullUrl.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.grey.shade500, size: 22),
            const SizedBox(width: 12),
            SizedBox(
              width: 140,
              child: Text(
                '$label:',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: Colors.grey.shade800,
                ),
              ),
            ),
            Expanded(
              child: Text(
                'Tidak ada dokumen',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal.shade600, size: 22),
          const SizedBox(width: 12),
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Colors.grey.shade800,
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => _launchUrl(fullUrl),
              borderRadius: BorderRadius.circular(
                8,
              ), // Sudut membulat pada InkWell
              splashColor: Colors.teal.shade100, // Efek sentuhan
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 4.0,
                ), // Padding dalam InkWell
                child: Text(
                  'Lihat Dokumen',
                  style: GoogleFonts.poppins(
                    color: Colors.blue.shade700, // Warna link yang jelas
                    decoration: TextDecoration.underline,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.open_in_new,
            size: 20,
            color: Colors.blue.shade700,
          ), // Ikon eksternal link
        ],
      ),
    );
  }

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
}
