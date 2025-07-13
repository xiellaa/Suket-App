import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

// Import semua screen yang akan digunakan sebagai route
import 'package:suket_desa_app/screens/splash_screen.dart'; // Ini akan jadi initialRoute penentu
import 'package:suket_desa_app/screens/login_screen.dart';
import 'package:suket_desa_app/screens/dashboard_screen.dart'; // User Dashboard
import 'package:suket_desa_app/admin/admin_dashboard_screen.dart'; // Admin Dashboard

void main() {
  // Pastikan binding Flutter sudah diinisialisasi sebelum panggilan Flutter apa pun
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi data lokal untuk DateFormat (misalnya Bahasa Indonesia)
  // Ini penting agar DateFormat berfungsi dengan benar di seluruh aplikasi
  initializeDateFormatting('id', null).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Tidak perlu ada state _initialScreen atau AuthService di sini,
  // karena penentuan route awal sekarang diatur oleh SplashScreen dan named routes.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Suket Desa App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF0056D6),
        hintColor: const Color(0xFFFFC107),
        fontFamily: 'Poppins',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0056D6),
          foregroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0056D6),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey[100],
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
          hintStyle: TextStyle(color: Colors.grey[600]),
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        ),
      ),
      // Definisikan Named Routes
      initialRoute: '/', // Selalu mulai dari splash screen
      routes: {
        '/':
            (context) =>
                const SplashScreen(), // SplashScreen akan menentukan route selanjutnya
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) {
          // Asumsikan email dikirim sebagai argumen jika diperlukan
          final args = ModalRoute.of(context)?.settings.arguments as String?;
          return DashboardScreen(
            userEmail: args ?? 'user@example.com',
          ); // Default email jika tidak ada
        },
        '/admin_dashboard': (context) {
          // Asumsikan email dikirim sebagai argumen jika diperlukan
          final args = ModalRoute.of(context)?.settings.arguments as String?;
          return AdminDashboardScreen(
            adminEmail: args ?? 'admin@example.com',
          ); // Default email jika tidak ada
        },
        // Anda bisa tambahkan route untuk form surat dan status request juga
        // '/data_suket': (context) => const DataSuketScreen(),
        // '/biodata': (context) => const BiodataScreen(),
        // '/status_request': (context) => const StatusRequestScreen(),
      },

      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id', 'ID')],
    );
  }
}
