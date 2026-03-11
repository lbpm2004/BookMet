import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; 

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final SupabaseClient _supabase = Supabase.instance.client; 
  Future<void> registrarUsuario({
    required String nombre,
    required String apellido,
    required String cedula,
    required String email,
    required String password,
    Uint8List? fotoBytes,
  }) async {
    try {
      String fotoUrl = '';

      // 1. Subir a Supabase
      if (fotoBytes != null) {
        final String nombreArchivo = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        await _supabase.storage.from('perfiles').uploadBinary(
          nombreArchivo, 
          fotoBytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
        fotoUrl = _supabase.storage.from('perfiles').getPublicUrl(nombreArchivo);
      }

      // 2. Crear el usuario en Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 3. Asignar ROL
      String rolAsignado = email.endsWith('@unimet.edu.ve') ? 'DOCENTE' : 'ESTUDIANTE';

      // 4. Guardar los datos en Firestore
      await _firestore.collection('usuarios').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'nombre': nombre,
        'apellido': apellido, 
        'cedula': cedula,
        'email': email,
        'fotoPerfil': fotoUrl,
        'estaActivo': true,
        'rol': rolAsignado,
      });
      
    } catch (e) {
      rethrow;
    }
  }

  // Iniciar sesión
  Future<void> iniciarSesion(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  // Cerrar sesión
  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }

  //Recuperar contraseña
  Future<void> recuperarPassword(String correo) async {
    try {
      await _auth.sendPasswordResetEmail(email: correo);
    } catch (e) {
      //throw Exception('Error al enviar correo de recuperación: $e');
      rethrow;
    }
  }
}