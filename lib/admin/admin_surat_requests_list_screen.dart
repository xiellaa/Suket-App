import 'package:flutter/material.dart';
import 'package:suket_desa_app/services/auth_service.dart';
import 'package:suket_desa_app/admin/admin_proses_surat_screen.dart';
import 'package:intl/intl.dart';
import 'package:suket_desa_app/screens/login_screen.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

class AdminSuratRequestsListScreen extends StatefulWidget {
  final String initialJenisSurat;
  final String initialStatus;

  const AdminSuratRequestsListScreen({
    super.key,
    this.initialJenisSurat = 'Semua', // Default jika tidak diberikan
    this.initialStatus =
        'Diajukan', // Default jika tidak diberikan (sesuai kebutuhan dari Summary Cards)
  });

  @override
  State<AdminSuratRequestsListScreen> createState() =>
      _AdminSuratRequestsListScreenState();
}

class _AdminSuratRequestsListScreenState
    extends State<AdminSuratRequestsListScreen> {
  final AuthService _authService = AuthService();
  List<dynamic> _allSuratRequests = []; // Menyimpan semua data mentah
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = ''; // Untuk filter pencarian

  late String _selectedStatus;
  late String _selectedJenisSurat;

  final List<String> _statusOptions = [
    'Semua',
    'Diajukan',
    'Diproses',
    'Disetujui',
    'Ditolak',
  ];
  final List<String> _jenisSuratOptions = ['Semua', 'SKTM', 'SKU', 'SKD'];

  @override
  void initState() {
    super.initState();
    _selectedJenisSurat = widget.initialJenisSurat;
    _selectedStatus = widget.initialStatus;

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
        throw Exception('Token tidak ditemukan. Silakan login kembali.');
      }

      final allRequests = await _authService.getAdminSuratRequests(token);

      if (mounted) {
        setState(() {
          _allSuratRequests = allRequests; // Simpan semua data
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      print('Error fetching surat requests: $_errorMessage');
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

  Future<void> _updateSuratStatus(
    int requestId,
    String newStatus,
    String? nomorSurat,
  ) async {
    setState(() {
      _isLoading = true;
    });
    try {
      final token = await _authService.getToken();
      if (token == null) {
        throw Exception('Token tidak ditemukan.');
      }
      await _authService.updateSuratStatusAdmin(
        token,
        requestId,
        newStatus,
        nomorSurat,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Status surat berhasil diperbarui menjadi "$newStatus"',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green.shade600,
          ),
        );
        _fetchSuratRequests(); // Refresh list after update
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal memperbarui status: ${e.toString().replaceFirst('Exception: ', '')}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Fungsi untuk memfilter daftar surat berdasarkan pencarian dan status
  List<dynamic> get _filteredSuratRequests {
    List<dynamic> filtered = _allSuratRequests;

    // Filter berdasarkan status yang dipilih dari Dropdown
    if (_selectedStatus != 'Semua') {
      filtered =
          filtered
              .where((surat) => surat['status'] == _selectedStatus)
              .toList();
    }

    // Filter berdasarkan jenis surat yang dipilih dari Dropdown
    if (_selectedJenisSurat != 'Semua') {
      filtered =
          filtered
              .where((surat) => surat['jenis_surat'] == _selectedJenisSurat)
              .toList();
    }

    // Filter berdasarkan pencarian (nama user, jenis surat, keperluan)
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered =
          filtered.where((surat) {
            final userName =
                (surat['user'] != null ? surat['user']['name'] : '')
                    ?.toLowerCase() ??
                '';
            final jenisSurat = (surat['jenis_surat'] ?? '').toLowerCase();
            final keperluan = (surat['keperluan'] ?? '').toLowerCase();
            return userName.contains(query) ||
                jenisSurat.contains(query) ||
                keperluan.contains(query);
          }).toList();
    }
    return filtered;
  }

  // Fungsi untuk menangani refresh data
  Future<void> _onRefresh() async {
    await _fetchSuratRequests();
  }

  // Helper untuk warna status
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

  // Helper untuk ikon status
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

  @override
  Widget build(BuildContext context) {
    // Judul AppBar yang dinamis berdasarkan filter
    String appBarTitle = 'Daftar Permohonan Surat';
    if (_selectedJenisSurat != 'Semua' || _selectedStatus != 'Semua') {
      appBarTitle = ''; // Kosongkan jika ada filter
      if (_selectedJenisSurat != 'Semua') {
        appBarTitle += '${_selectedJenisSurat.toUpperCase()} ';
      }
      if (_selectedStatus != 'Semua') {
        appBarTitle += '(${_selectedStatus})';
      }
      appBarTitle = appBarTitle.trim(); // Hapus spasi di awal/akhir
    }

    final appBarTitleStyle = GoogleFonts.poppins(
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );
    final appBarBackgroundColor = Colors.teal.shade600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appBarTitle.isEmpty ? 'Daftar Permohonan' : appBarTitle,
          style: appBarTitleStyle,
        ),
        backgroundColor: appBarBackgroundColor,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      body: Container(
        color: Colors.grey.shade50, // Latar belakang body
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0), // Padding lebih besar
              child: TextField(
                controller: TextEditingController(text: _searchQuery),
                style: GoogleFonts.poppins(fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Cari nama pemohon, jenis surat, atau keperluan...',
                  hintStyle: GoogleFonts.poppins(color: Colors.grey.shade500),
                  prefixIcon: Icon(Icons.search, color: Colors.teal.shade700),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      12,
                    ), // Sudut lebih membulat
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
                    vertical: 14,
                    horizontal: 16,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
              ), // Padding konsisten
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.grey.shade900,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Filter Status',
                        labelStyle: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                        ),
                        prefixIcon: Icon(
                          Icons.filter_list,
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
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items:
                          _statusOptions.map((String status) {
                            return DropdownMenuItem<String>(
                              value: status,
                              child: Text(status, style: GoogleFonts.poppins()),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedStatus = newValue!;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 15), // Spasi antar dropdown
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedJenisSurat,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.grey.shade900,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Filter Jenis Surat',
                        labelStyle: GoogleFonts.poppins(
                          color: Colors.grey.shade600,
                        ),
                        prefixIcon: Icon(
                          Icons.category_outlined,
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
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      items:
                          _jenisSuratOptions.map((String jenis) {
                            return DropdownMenuItem<String>(
                              value: jenis,
                              child: Text(jenis, style: GoogleFonts.poppins()),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedJenisSurat = newValue!;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16), // Spasi setelah filter

            Expanded(
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
                                onPressed: _fetchSuratRequests,
                                icon: const Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                ),
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
                      : _filteredSuratRequests.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              color: Colors.grey.shade400,
                              size: 80,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _filteredSuratRequests.isEmpty &&
                                      (_searchQuery.isNotEmpty ||
                                          _selectedJenisSurat != 'Semua' ||
                                          _selectedStatus != 'Semua')
                                  ? 'Tidak ada permohonan yang cocok dengan filter.'
                                  : 'Tidak ada permohonan surat baru.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (_filteredSuratRequests.isEmpty &&
                                (_searchQuery.isNotEmpty ||
                                    _selectedJenisSurat != 'Semua' ||
                                    _selectedStatus != 'Semua'))
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  'Coba sesuaikan filter atau kata kunci pencarian Anda.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      )
                      : RefreshIndicator(
                        onRefresh: _onRefresh,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16.0),
                          itemCount: _filteredSuratRequests.length,
                          separatorBuilder:
                              (context, index) => const SizedBox(
                                height: 15,
                              ), // Spasi antar kartu
                          itemBuilder: (context, index) {
                            final request = _filteredSuratRequests[index];
                            final tanggalPermohonan = DateTime.parse(
                              request['created_at'],
                            );

                            return Card(
                              elevation: 8, // Elevasi lebih tinggi
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  15,
                                ), // Sudut lebih membulat
                              ),
                              shadowColor: Colors.black.withOpacity(
                                0.1,
                              ), // Shadow halus
                              child: InkWell(
                                borderRadius: BorderRadius.circular(15),
                                onTap: () async {
                                  final result = await Navigator.of(
                                    context,
                                  ).push(
                                    MaterialPageRoute(
                                      builder:
                                          (context) => AdminProsesSuratScreen(
                                            suratId: request['id'],
                                          ),
                                    ),
                                  );
                                  if (result == true) {
                                    _fetchSuratRequests(); // Refresh daftar setelah kembali
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    18.0,
                                  ), // Padding internal lebih besar
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${request['jenis_surat']}'
                                                  .toUpperCase(), // Jenis surat KAPITAL
                                              style: GoogleFonts.montserrat(
                                                fontSize: 19,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.teal.shade800,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: _getStatusColor(
                                                request['status'],
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    20,
                                                  ), // Badge lebih membulat
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  _getStatusIcon(
                                                    request['status'],
                                                  ),
                                                  color: Colors.white,
                                                  size: 16,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  request['status'],
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(
                                        height: 20,
                                        thickness: 1,
                                        color: Colors.grey,
                                      ),
                                      Text(
                                        'Pemohon: ${request['user']['name'] ?? 'N/A'}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey.shade900,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Diajukan pada: ${DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(tanggalPermohonan)}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 15),
                                      Align(
                                        alignment: Alignment.bottomRight,
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            final result = await Navigator.of(
                                              context,
                                            ).push(
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        AdminProsesSuratScreen(
                                                          suratId:
                                                              request['id'],
                                                        ),
                                              ),
                                            );
                                            if (result == true) {
                                              _fetchSuratRequests(); // Refresh daftar setelah kembali
                                            }
                                          },
                                          icon: const Icon(
                                            Icons.visibility_outlined,
                                            size: 20,
                                          ),
                                          label: Text(
                                            'Lihat Detail & Proses',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Colors.teal.shade700,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 15,
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            elevation: 4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
