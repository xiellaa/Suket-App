import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:lottie/lottie.dart';

// Ganti dengan halaman pertama setelah splash, misalnya LoginScreen
import 'package:suket_desa_app/screens/login_screen.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Warna background yang konsisten dengan tema biru Anda
    final Color splashBackgroundColor = const Color(0xFF007AFF);

    return AnimatedSplashScreen(
      // Menggunakan Builder untuk mengakses MediaQuery di dalam splash widget
      splash: Builder(
        builder: (innerContext) {
          // Dapatkan ukuran layar saat ini
          final screenWidth = MediaQuery.of(innerContext).size.width;
          final screenHeight = MediaQuery.of(innerContext).size.height;

          // Mengatur ukuran Lottie agar memenuhi lebar atau tinggi,
          // tergantung orientasi dan rasio aspek Lottie itu sendiri.
          // BoxFit.cover akan memastikan Lottie menutupi seluruh area yang tersedia.
          return SizedBox(
            width: screenWidth,
            height: screenHeight,
            child: Lottie.asset(
              "assets/Lottie/log.json", // Path Lottie animation Anda
              fit:
                  BoxFit.cover, // Ini penting agar Lottie mengisi seluruh ruang
              repeat:
                  true, // Pastikan animasi berulang jika durasi splash lebih panjang
              animate: true, // Pastikan animasi berjalan
            ),
          );
        },
      ),
      nextScreen: const LoginScreen(), // Ganti dengan widget layar berikutnya
      backgroundColor: splashBackgroundColor, // Warna background splash screen
      // splashIconSize diset ke double.infinity agar splash widget (SizedBox)
      // yang berisi Lottie bisa mengambil ukuran maksimal dari AnimatedSplashScreen.
      splashIconSize: double.infinity,
      duration: 3000, // Durasi dalam milidetik (3 detik)
      splashTransition: SplashTransition.fadeTransition, // Efek transisi
    );
  }
}
