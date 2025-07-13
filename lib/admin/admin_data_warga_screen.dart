import 'package:flutter/material.dart';
import 'package:suket_desa_app/services/auth_service.dart';
import 'package:suket_desa_app/screens/login_screen.dart';
import 'package:intl/intl.dart';
import 'package:suket_desa_app/admin/admin_edit_user_screen.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminDataWargaScreen extends StatefulWidget {
  const AdminDataWargaScreen({super.key});

  @override
  State<AdminDataWargaScreen> createState() => _AdminDataWargaScreenState();
}

class _AdminDataWargaScreenState extends State<AdminDataWargaScreen> {
  final AuthService _authService = AuthService();
  List<dynamic> _users = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
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

      final List<dynamic> usersData = await _authService.getAdminUsers(token);
      _users = usersData.where((user) => user['role'] == 'user').toList();

      if (mounted) {
        setState(() {
          // Data user sudah difilter di atas
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
      print('Error fetching users: $_errorMessage');
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

  Future<void> _onEditUser(Map<String, dynamic> user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AdminEditUserScreen(user: user)),
    );
    if (result == true) {
      _fetchUsers(); // Refresh daftar setelah edit
    }
  }

  Future<void> _onDeleteUser(int userId, String userName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Text(
            'Konfirmasi Hapus',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus user $userName? Tindakan ini tidak bisa dibatalkan.',
            style: GoogleFonts.poppins(),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Batal',
                style: GoogleFonts.poppins(color: Colors.grey.shade700),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Hapus', style: GoogleFonts.poppins()),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        final token = await _authService.getToken();
        if (token == null) throw Exception('Token tidak ditemukan.');

        await _authService.deleteAdminUser(token, userId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User $userName berhasil dihapus!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green.shade600,
          ),
        );
        _fetchUsers(); // Refresh daftar setelah hapus
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal menghapus user: ${e.toString().replaceFirst('Exception: ', '')}',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('dd MMMM hafa', 'id_ID').format(date);
    } catch (e) {
      return dateString; // Return original if parsing fails
    }
  }

  String _formatDateTime(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('dd MMM hafa HH:mm', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
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
          title: Text('Data Warga', style: appBarTitleStyle),
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
          title: Text('Data Warga', style: appBarTitleStyle),
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
                  onPressed: _fetchUsers,
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

    if (_users.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Data Warga', style: appBarTitleStyle),
          backgroundColor: appBarBackgroundColor,
          foregroundColor: Colors.white,
          elevation: 6,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people_outline, color: Colors.grey.shade400, size: 80),
              const SizedBox(height: 20),
              Text(
                'Tidak ada data warga terdaftar.',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Pastikan pengguna telah mendaftar sebagai warga.',
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
        title: Text('Data Warga', style: appBarTitleStyle),
        backgroundColor: appBarBackgroundColor,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      body: Container(
        color: Colors.grey.shade50, // Latar belakang body
        child: ListView.separated(
          padding: const EdgeInsets.all(20.0), // Padding lebih besar
          itemCount: _users.length,
          separatorBuilder:
              (context, index) =>
                  const SizedBox(height: 15), // Spasi antar card
          itemBuilder: (context, index) {
            final user = _users[index];
            return _buildUserCard(user, index + 1);
          },
        ),
      ),
    );
  }

  // Widget untuk setiap kartu warga
  Widget _buildUserCard(Map<String, dynamic> user, int index) {
    final String? nik = user['nik'];
    final String? name = user['name'];
    final String? tempatLahir = user['tempat_lahir'];
    final String? tanggalLahir = user['tanggal_lahir'];
    final String? jenisKelamin = user['jenis_kelamin'];
    final String? agama = user['agama'];
    final String? alamat = user['alamat'];
    final String? telepon = user['telepon'];
    final String? statusWarga = user['status_warga'];
    final String? updatedAt = user['updated_at'];

    // Cek apakah biodata lengkap atau tidak
    bool isBiodataComplete =
        (nik?.isNotEmpty ?? false) &&
        (name?.isNotEmpty ?? false) &&
        (tempatLahir?.isNotEmpty ?? false) &&
        (tanggalLahir?.isNotEmpty ?? false) &&
        (jenisKelamin?.isNotEmpty ?? false) &&
        (agama?.isNotEmpty ?? false) &&
        (alamat?.isNotEmpty ?? false) &&
        (telepon?.isNotEmpty ?? false) &&
        (statusWarga?.isNotEmpty ?? false);

    return Card(
      elevation: 8, // Elevasi kartu
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      shadowColor: Colors.black.withOpacity(0.1), // Warna shadow
      child: ExpansionTile(
        // Menggunakan ExpansionTile agar bisa di-expand
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
          backgroundColor:
              isBiodataComplete ? Colors.teal.shade100 : Colors.orange.shade100,
          // Ikon yang diganti agar kompatibel
          child: Icon(
            isBiodataComplete
                ? Icons.person
                : Icons.person_off, // Menggunakan ikon standar
            color:
                isBiodataComplete
                    ? Colors.teal.shade700
                    : Colors.orange.shade700,
          ),
        ),
        title: Text(
          name ?? 'Nama Tidak Diketahui',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade800,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NIK: ${nik ?? '-'}',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
            Text(
              'Email: ${user['email'] ?? '-'}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            if (!isBiodataComplete)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  'Biodata Belum Lengkap!',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue.shade700, size: 24),
              onPressed: () => _onEditUser(user),
              tooltip: 'Edit Data Warga',
            ),
            IconButton(
              icon: Icon(
                Icons.delete_forever,
                color: Colors.red.shade700,
                size: 24,
              ),
              onPressed:
                  () => _onDeleteUser(user['id'], user['name'] ?? 'user ini'),
              tooltip: 'Hapus Warga',
            ),
          ],
        ),
        children: <Widget>[
          const Divider(height: 1, thickness: 1, indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 10.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Jenis Kelamin', jenisKelamin ?? '-'),
                _buildDetailRow(
                  'Tempat, Tgl Lahir',
                  '${tempatLahir ?? '-'}, ${_formatDate(tanggalLahir)}',
                ),
                _buildDetailRow('Agama', agama ?? '-'),
                _buildDetailRow('Alamat', alamat ?? '-'),
                _buildDetailRow('Telepon', telepon ?? '-'),
                _buildDetailRow('Status Warga', statusWarga ?? '-'),
                _buildDetailRow(
                  'Terakhir Diupdate',
                  _formatDateTime(updatedAt),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
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
