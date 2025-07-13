import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:animate_do/animate_do.dart'; // Import animate_do for animations

// Import halaman-halaman form surat keterangan
import 'package:suket_desa_app/screens/sktm_form_screen.dart';
import 'package:suket_desa_app/screens/sku_form_screen.dart';
import 'package:suket_desa_app/screens/skd_form_screen.dart';

class DataSuketScreen extends StatelessWidget {
  const DataSuketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Warna utama yang konsisten (biru cerah dan biru tua)
    final Color primaryBlue = const Color(
      0xFF007AFF,
    ); // Biru utama dari referensi
    final Color darkBlue = const Color(0xFF0056B3); // Biru tua untuk gradasi

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pilih Jenis Surat', // Judul lebih ringkas
          style: GoogleFonts.montserrat(
            // Menggunakan Montserrat untuk AppBar
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        // Menggunakan flexibleSpace untuk menambahkan gradasi ke AppBar
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                darkBlue,
                primaryBlue,
              ], // Gradasi dari biru tua ke biru utama
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 10, // Elevasi ditingkatkan untuk kesan menonjol
        iconTheme: const IconThemeData(
          color: Colors.white, // Warna ikon back putih
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Deskripsi awal dengan animasi
            FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Text(
                'Silakan pilih jenis surat keterangan yang Anda butuhkan dari daftar di bawah ini untuk memulai proses pengajuan. Kami siap membantu urusan administrasi Anda dengan cepat dan mudah.',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 35),

            // Card untuk SKTM
            FadeInUp(
              duration: const Duration(milliseconds: 700),
              delay: const Duration(milliseconds: 100), // Animasi berurutan
              child: _buildSuratCard(
                context,
                'SURAT KETERANGAN TIDAK MAMPU',
                'SKTM',
                primaryBlue, // Warna utama (biru cerah)
                Icons
                    .attach_money_outlined, // Ikon lebih relevan (kemiskinan/finansial)
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SktmFormScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 25),

            // Card untuk SKU
            FadeInUp(
              duration: const Duration(milliseconds: 700),
              delay: const Duration(milliseconds: 200), // Animasi berurutan
              child: _buildSuratCard(
                context,
                'SURAT KETERANGAN USAHA',
                'SKU',
                const Color(
                  0xFF3399FF,
                ), // Nuansa biru berbeda untuk variasi kartu
                Icons.store_outlined, // Ikon toko/usaha
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SkuFormScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 25),

            // Card untuk SKD
            FadeInUp(
              duration: const Duration(milliseconds: 700),
              delay: const Duration(milliseconds: 300), // Animasi berurutan
              child: _buildSuratCard(
                context,
                'SURAT KETERANGAN DOMISILI',
                'SKD',
                const Color(0xFF66B3FF), // Nuansa biru lain untuk variasi kartu
                Icons.location_city_outlined, // Ikon kota/lokasi
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SkdFormScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 25),

            // Tambahkan Call to Action atau Info Tambahan
            FadeInUp(
              duration: const Duration(milliseconds: 700),
              delay: const Duration(milliseconds: 400),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Column(
                  children: [
                    Text(
                      'Butuh Bantuan?',
                      style: GoogleFonts.montserrat(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Jika Anda memiliki pertanyaan atau membutuhkan bantuan dalam memilih jenis surat, jangan ragu untuk menghubungi layanan dukungan kami.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Implementasi navigasi ke halaman bantuan/kontak
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Fitur Bantuan akan segera hadir!',
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                            backgroundColor: primaryBlue,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 25,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 5,
                      ),
                      icon: const Icon(Icons.help_outline_rounded, size: 24),
                      label: Text(
                        'Hubungi Dukungan',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget yang diperbarui untuk _buildSuratCard
  Widget _buildSuratCard(
    BuildContext context,
    String title,
    String subtitle,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      // Menggunakan Card langsung untuk elevasi dan bentuk
      elevation: 10, // Elevasi lebih tinggi untuk kesan 3D
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // Sudut lebih membulat
      ),
      clipBehavior: Clip.antiAlias, // Penting untuk InkWell di dalam Card
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            // Menambahkan gradasi ke dalam card
            colors: [
              color,
              color.withOpacity(0.7),
            ], // Gradasi dari warna solid ke sedikit transparan
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20), // Tetap membulat
        ),
        child: Material(
          color: Colors.transparent, // Penting agar InkWell berfungsi
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: Colors.white.withOpacity(
              0.4,
            ), // Efek sentuhan yang lebih jelas
            highlightColor: Colors.white.withOpacity(0.2), // Efek saat ditekan
            child: Padding(
              padding: const EdgeInsets.symmetric(
                vertical: 30.0, // Padding vertikal lebih besar
                horizontal: 20.0,
              ),
              child: Column(
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 70, // Ukuran ikon lebih besar
                  ),
                  const SizedBox(height: 20), // Spasi lebih besar
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22, // Ukuran font judul lebih besar
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1, // Spasi antar huruf lebih terasa
                    ),
                  ),
                  const SizedBox(
                    height: 8,
                  ), // Spasi sedikit antara judul dan subtitle
                  Text(
                    '($subtitle)',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(
                    height: 25,
                  ), // Spasi lebih besar sebelum tombol
                  ElevatedButton.icon(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor:
                          color, // Warna teks dan ikon sesuai warna card
                      padding: const EdgeInsets.symmetric(
                        horizontal: 35, // Padding horizontal lebih besar
                        vertical: 14, // Padding vertical lebih besar
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          30,
                        ), // Tombol lebih membulat (pill-shaped)
                      ),
                      elevation:
                          4, // Elevasi tombol sedikit lebih rendah dari card
                    ),
                    icon: Icon(
                      Icons
                          .arrow_forward_ios_rounded, // Ikon panah yang lebih bulat
                      size: 20,
                      color: color,
                    ),
                    label: Text(
                      'Ajukan Sekarang',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.w700, // Lebih tebal
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
}
