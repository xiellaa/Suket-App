import 'dart:convert';
import 'dart:io'; // Penting untuk File
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final String _baseUrl = 'https://10a8bdf41224.ngrok-free.app/api';

  String get baseUrl {
    return _baseUrl;
  }

  // Helper untuk menyimpan token autentikasi
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Helper untuk mendapatkan token autentikasi
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // Helper untuk menghapus token dan role saat logout
  Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role'); // Hapus juga role saat logout
  }

  // Method baru untuk menyimpan peran pengguna (role)
  Future<void> _saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', role);
  }

  // Method baru untuk mendapatkan peran pengguna (role)
  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  // Menyimpan email user yang sedang login sementara di memori
  String? _currentUserEmail;

  // Helper untuk POST request umum
  Future<dynamic> _post(
    String endpoint,
    Map<String, dynamic> data, {
    String? token,
    bool isMultipart = false,
  }) async {
    final url = Uri.parse('$_baseUrl/$endpoint');
    final headers = <String, String>{'Accept': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (!isMultipart) {
      headers['Content-Type'] = 'application/json; charset=UTF-8';
    }

    try {
      final http.Response response;
      if (isMultipart) {
        throw UnimplementedError(
          "Multipart requests should use submitSuratRequest method.",
        );
      } else {
        response = await http.post(
          url,
          headers: headers,
          body: jsonEncode(data),
        );
      }

      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw Exception('Tidak dapat terhubung ke server: ${e.message}');
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa jaringan Anda.');
    } catch (e) {
      throw Exception('Terjadi kesalahan tidak terduga: ${e.toString()}');
    }
  }

  // Helper untuk GET request umum
  Future<dynamic> _get(String endpoint, {String? token}) async {
    final url = Uri.parse('$_baseUrl/$endpoint');
    final headers = <String, String>{'Accept': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.get(url, headers: headers);
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw Exception('Tidak dapat terhubung ke server: ${e.message}');
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa jaringan Anda.');
    } catch (e) {
      throw Exception('Terjadi kesalahan tidak terduga: ${e.toString()}');
    }
  }

  // Helper untuk PUT request umum
  Future<dynamic> _put(
    String endpoint,
    Map<String, dynamic> data, {
    String? token,
  }) async {
    final url = Uri.parse('$_baseUrl/$endpoint');
    final headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.put(
        url,
        headers: headers,
        body: jsonEncode(data),
      );
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw Exception('Tidak dapat terhubung ke server: ${e.message}');
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa jaringan Anda.');
    } catch (e) {
      throw Exception('Terjadi kesalahan tidak terduga: ${e.toString()}');
    }
  }

  // Helper untuk DELETE request umum
  Future<dynamic> _delete(String endpoint, {String? token}) async {
    final url = Uri.parse('$_baseUrl/$endpoint');
    final headers = <String, String>{'Accept': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final response = await http.delete(url, headers: headers);
      return _handleResponse(response);
    } on http.ClientException catch (e) {
      throw Exception('Tidak dapat terhubung ke server: ${e.message}');
    } on SocketException {
      throw Exception('Tidak ada koneksi internet. Periksa jaringan Anda.');
    } catch (e) {
      throw Exception('Terjadi kesalahan tidak terduga: ${e.toString()}');
    }
  }

  // Helper untuk menangani respons API
  dynamic _handleResponse(http.Response response) {
    String errorMessage = 'Terjadi kesalahan server.';
    dynamic data;
    try {
      data = jsonDecode(response.body);
    } catch (e) {
      print(
        'Respons non-JSON (Status: ${response.statusCode}): ${response.body}',
      );
      throw Exception(
        'Server mengembalikan format data yang tidak valid. (${response.statusCode})',
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    } else if (response.statusCode == 401) {
      throw Exception(
        data['message'] ?? 'Sesi Anda telah berakhir. Silakan masuk kembali.',
      );
    } else if (response.statusCode == 403) {
      throw Exception(
        data['message'] ?? 'Akses ditolak. Anda tidak memiliki izin.',
      );
    } else if (response.statusCode == 422) {
      if (data.containsKey('errors')) {
        Map<String, dynamic> errors = data['errors'];
        errorMessage = errors.values.expand((list) => list).join('\n');
      } else if (data.containsKey('message')) {
        errorMessage = data['message'];
      }
      throw Exception(errorMessage);
    } else {
      throw Exception(
        data['message'] ??
            'Gagal memproses permintaan. (${response.statusCode})',
      );
    }
  }

  // --- Metode Autentikasi Pengguna ---
  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
    String passwordConfirmation,
  ) async {
    final response = await _post('register', {
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
    });
    if (response is Map && response.containsKey('token')) {
      _currentUserEmail = email;
      await _saveToken(response['token']);
      await _saveUserRole(response['user']['role'] ?? 'user');
    }
    return response as Map<String, dynamic>; // Pastikan cast ke Map
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _post('login', {
      'email': email,
      'password': password,
    });
    if (response is Map && response.containsKey('token')) {
      _currentUserEmail = email;
      await _saveToken(response['token']);
      await _saveUserRole(response['user']['role'] ?? 'user');
      print(
        'DEBUG AuthService: Role saved locally: ${response['user']['role']}',
      );
    }
    return response as Map<String, dynamic>; // Pastikan cast ke Map
  }

  String? getCurrentUserEmail() {
    return _currentUserEmail;
  }

  Future<Map<String, dynamic>> logout(String token) async {
    try {
      final response = await _post('logout', {}, token: token);
      await deleteToken();
      _currentUserEmail = null;
      return response as Map<String, dynamic>;
    } catch (e) {
      await deleteToken();
      _currentUserEmail = null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUser(String token) async {
    final response = await _get('user', token: token);
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateBiodata(
    String token,
    Map<String, dynamic> data,
  ) async {
    final response = await _put('user/biodata', data, token: token);
    return response as Map<String, dynamic>;
  }

  // --- BARIS YANG HILANG DAN KEMBALI DITAMBAHKAN ---
  // Metode untuk memeriksa apakah biodata pengguna sudah lengkap
  Future<bool> isBiodataComplete() async {
    final token = await getToken();
    if (token == null) {
      return false;
    }
    try {
      final userData = await getUser(token);
      final user = userData['user'];

      return user != null &&
          (user['nik'] != null && (user['nik'] as String).isNotEmpty) &&
          (user['jenis_kelamin'] != null &&
              (user['jenis_kelamin'] as String).isNotEmpty) &&
          (user['tempat_lahir'] != null &&
              (user['tempat_lahir'] as String).isNotEmpty) &&
          (user['tanggal_lahir'] != null &&
              (user['tanggal_lahir'] as String).isNotEmpty) &&
          (user['agama'] != null && (user['agama'] as String).isNotEmpty) &&
          (user['alamat'] != null && (user['alamat'] as String).isNotEmpty) &&
          (user['telepon'] != null && (user['telepon'] as String).isNotEmpty) &&
          (user['status_warga'] != null &&
              (user['status_warga'] as String).isNotEmpty);
    } on Exception catch (e) {
      print('Error checking biodata completeness: ${e.toString()}');
      return false;
    }
  }
  // --- AKHIR BARIS YANG HILANG ---

  // --- Metode Permohonan Surat (untuk User) ---
  Future<Map<String, dynamic>> submitSuratRequest({
    required String jenisSurat,
    required String keperluan,
    File? scanKtp,
    File? scanKk,
    String? jenisUsaha,
    required String token,
  }) async {
    // Menggunakan MultipartRequest untuk upload file
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/surat-request/create'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['jenis_surat'] = jenisSurat;
    request.fields['keperluan'] = keperluan;
    if (jenisUsaha != null) {
      request.fields['jenis_usaha'] = jenisUsaha;
    }

    if (scanKtp != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'scan_ktp',
          scanKtp.path,
          filename: scanKtp.path.split('/').last,
        ),
      );
    }
    if (scanKk != null) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'scan_kk',
          scanKk.path,
          filename: scanKk.path.split('/').last,
        ),
      );
    }

    var streamedResponse = await request.send();
    var response = await http.Response.fromStream(streamedResponse);

    return _handleResponse(response) as Map<String, dynamic>; // Pastikan cast
  }

  Future<List<dynamic>> getUserSuratRequests(String token) async {
    final response = await _get('user/surat-requests', token: token);
    if (response is List) {
      return response;
    } else if (response is Map && response.containsKey('surat_requests')) {
      return response['surat_requests'];
    }
    throw Exception(
      'Expected a list of surat requests from API, but got unexpected format.',
    );
  }

  // Endpoint ini digunakan oleh user dan admin untuk melihat detail surat
  Future<Map<String, dynamic>> getSuratDetail(
    String suratId,
    String token,
  ) async {
    final response = await _get('surat-request/$suratId', token: token);
    return response as Map<String, dynamic>;
  }

  Future<String> getSignedDownloadUrl(String suratId) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('No authentication token found. Silakan masuk kembali.');
    }
    final response = await _get(
      'surat-request/$suratId/generate-download-url',
      token: token,
    );
    return response['download_url'] as String; // Pastikan cast
  }

  // --- Metode Admin: Manajemen Surat ---
  Future<List<dynamic>> getAdminSuratRequests(String token) async {
    final response = await _get('admin/surat-requests', token: token);
    if (response is List) {
      return response;
    } else if (response is Map && response.containsKey('surat_requests')) {
      return response['surat_requests'];
    }
    throw Exception(
      'Expected a list of admin surat requests from API, but got unexpected format.',
    );
  }

  Future<Map<String, dynamic>> updateSuratStatusAdmin(
    String token,
    int suratId,
    String newStatus,
    String? nomorSurat,
  ) async {
    final data = {'status': newStatus};
    if (nomorSurat != null) {
      data['nomor_surat'] = nomorSurat;
    }
    final response = await _post(
      'admin/surat-requests/$suratId/update-status',
      data,
      token: token,
    );
    return response as Map<String, dynamic>;
  }

  // --- Metode Admin: Manajemen Pengguna (Data Warga) ---
  Future<List<dynamic>> getAdminUsers(String token) async {
    final response = await _get('admin/users', token: token);
    if (response is List) {
      return response;
    } else if (response is Map && response.containsKey('users')) {
      return response['users'];
    }
    throw Exception(
      'Expected a list of users from API, but got unexpected format.',
    );
  }

  Future<Map<String, dynamic>> getAdminUserDetail(
    String token,
    int userId,
  ) async {
    final response = await _get('admin/users/$userId', token: token);
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateAdminUser(
    String token,
    int userId,
    Map<String, dynamic> userData,
  ) async {
    final response = await _put('admin/users/$userId', userData, token: token);
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> deleteAdminUser(String token, int userId) async {
    final response = await _delete('admin/users/$userId', token: token);
    return response as Map<String, dynamic>;
  }
}
