import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_bookmet/screens/catalogo_screen.dart';
import 'package:flutter_application_bookmet/screens/usuario_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'firebase_options.dart';
import 'package:flutter_application_bookmet/screens/bienvenida_screen.dart';
import 'package:flutter_application_bookmet/screens/registro_screen.dart'; 
import 'package:flutter_application_bookmet/screens/login_screen.dart'; 
import 'package:flutter_application_bookmet/screens/donacion_screen.dart';
import 'package:flutter_application_bookmet/screens/admin_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializamos Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Inicializamos Supabase
  await Supabase.initialize(
    url: 'https://yreemoaspqrvggijwkcz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlyZWVtb2FzcHFydmdnaWp3a2N6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE3MTY5MzYsImV4cCI6MjA4NzI5MjkzNn0.zVmHoatjPkKLgkEb1Fj4eHYFBVu8thbqwncv6kw3qMQ',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BookMet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primaryColor: Colors.orange),
      initialRoute: '/',
    routes: {
      '/': (context) => const BienvenidaScreen(),
      
      '/login': (context) => const LoginScreen(),
      '/registro': (context) => const RegistroScreen(),
      '/usuario': (context) => const UsuarioScreen(),
      'catalogo': (context) => const CatalogoScreen(), 
      '/donar': (context) => const DonacionScreen(),
      '/admin': (context) => const AdminScreen(),
      },
    );
  }
}
