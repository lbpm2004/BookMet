import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Iniciar sesión
  Future<void> iniciarSesion(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      rethrow;
    }
  }

  // Registrar usuario con nombre y apellido separados
  Future<void> registrarUsuario({
    required String nombre,
    required String apellido,
    required String carnet,
    required String email,
    required String password,
    required String fotoUrl,
  }) async {
    try {
      // 1. Crear el usuario en Firebase Authentication (correo y contraseña)
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Guardar los datos en Firestore (Base de Datos)
      await _firestore.collection('usuarios').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'nombre': nombre,
        'apellido': apellido, 
        'carnet': carnet,
        'email': email,
        'fotoPerfil': fotoUrl,
      });
      
    } catch (e) {
      rethrow;
    }
  }

  // Cerrar sesión
  Future<void> cerrarSesion() async {
    await _auth.signOut();
  }

  //Recuperar contraseña
  Future<void> recuperarPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw Exception('Error al enviar correo de recuperación: $e');
    }
  }
}