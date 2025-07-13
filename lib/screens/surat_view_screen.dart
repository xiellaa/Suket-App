import 'package:flutter/material.dart';
import 'package:suket_desa_app/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // Untuk membuka URL PDF

class SuratViewScreen extends StatefulWidget {
  final int suratId;

  const SuratViewScreen({super.key, required this.suratId});

  @override
  State<SuratViewScreen> createState() => _SuratViewScreenState();
}

class _SuratViewScreenState extends State<SuratViewScreen> {
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _suratDetail;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchSuratDetail();
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
        throw Exception('Token not found. Please log in again.');
      }
      // Panggil API untuk mendapatkan detail surat (gunakan endpoint show)
      final response = await _authService.getSuratDetail(
        widget.suratId.toString(),
        token,
      ); // Mengirim ID sebagai String dan token

      if (!mounted) return;
      setState(() {
        _suratDetail =
            response; // Asumsi API mengembalikan detail surat langsung sebagai Map
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      _showSnackbar('Error: $_errorMessage', isError: true);
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _launchPdf(String suratId) async {
    if (!mounted) return;
    setState(() {
      _isLoading = true; // Tampilkan loading saat generate URL dan meluncurkan
    });
    try {
      final String signedUrl = await _authService.getSignedDownloadUrl(suratId);
      final Uri url = Uri.parse(signedUrl);

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        _showSnackbar('Mencoba membuka surat...', isError: false);
      } else {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.inAppWebView);
          _showSnackbar('Mencoba membuka surat di WebView...', isError: false);
        } else {
          _showSnackbar('Tidak dapat membuka link: $signedUrl', isError: true);
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackbar(
        'Terjadi kesalahan saat mencoba membuka surat: ${e.toString()}',
        isError: true,
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false; // Sembunyikan loading
      });
    }
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Surat')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Surat')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Error: $_errorMessage'),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _fetchSuratDetail,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_suratDetail == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Surat')),
        body: const Center(child: Text('Detail surat tidak ditemukan.')),
      );
    }

    // Akses data dengan aman
    final String jenisSurat = (_suratDetail!['jenis_surat'] as String?) ?? '-';
    final String keperluan = (_suratDetail!['keperluan'] as String?) ?? '-';
    final String status = (_suratDetail!['status'] as String?) ?? 'Diajukan';
    final String nomorSurat = (_suratDetail!['nomor_surat'] as String?) ?? '-';
    final String? createdAtRaw = _suratDetail!['created_at'] as String?;
    final int? idSurat = (_suratDetail!['id'] as int?);

    DateTime createdAt;
    try {
      createdAt = DateTime.parse(
        createdAtRaw ?? DateTime.now().toIso8601String(),
      );
    } catch (e) {
      createdAt = DateTime.now();
    }

    // Informasi pengguna dari data surat
    final Map<String, dynamic>? userData =
        (_suratDetail!['user'] as Map<String, dynamic>?);
    final String userName = (userData?['name'] as String?) ?? '-';
    final String userNik = (userData?['nik'] as String?) ?? '-';
    final String userJenisKelamin =
        (userData?['jenis_kelamin'] as String?) ?? '-';
    final String userTempatLahir =
        (userData?['tempat_lahir'] as String?) ?? '-';
    final String userTanggalLahir =
        (userData?['tanggal_lahir'] as String?) ?? '-';
    final String userAgama = (userData?['agama'] as String?) ?? '-';
    final String userAlamat = (userData?['alamat'] as String?) ?? '-';
    final String userTelepon = (userData?['telepon'] as String?) ?? '-';
    final String userStatusWarga =
        (userData?['status_warga'] as String?) ?? '-';

    // Logika untuk menampilkan tombol cetak
    final bool canCetak =
        status == 'Disetujui' &&
        nomorSurat != '-' &&
        nomorSurat.isNotEmpty &&
        idSurat != null;

    return Scaffold(
      appBar: AppBar(title: Text('Detail Surat $jenisSurat')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'INFORMASI SURAT',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoField('Jenis Surat', jenisSurat),
            _buildInfoField('Nomor Surat', nomorSurat),
            _buildInfoField('Status', status),
            _buildInfoField('Keperluan', keperluan),
            _buildInfoField(
              'Diajukan Pada',
              DateFormat('dd MMMM yyyy HH:mm', 'id').format(createdAt),
            ),
            const SizedBox(height: 20),

            const Text(
              'DATA PEMOHON',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _buildInfoField('Nama Lengkap', userName),
            _buildInfoField('NIK', userNik),
            _buildInfoField('Jenis Kelamin', userJenisKelamin),
            _buildInfoField(
              'Tempat/Tanggal Lahir',
              '$userTempatLahir, ${DateFormat('dd MMMM yyyy', 'id').format(DateTime.parse(userTanggalLahir))}',
            ),
            _buildInfoField('Agama', userAgama),
            _buildInfoField('Alamat', userAlamat),
            _buildInfoField('Telepon', userTelepon),
            _buildInfoField('Status Warga', userStatusWarga),
            const SizedBox(height: 30),

            Center(
              child: ElevatedButton.icon(
                onPressed:
                    canCetak ? () => _launchPdf(idSurat!.toString()) : null,
                icon: const Icon(Icons.print),
                label: const Text('Cetak/Unduh Surat PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: canCetak ? Colors.blue : Colors.grey,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 15,
                  ),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(': $value')),
        ],
      ),
    );
  }
}
