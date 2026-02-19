import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // REGISTRO: Guarda en Auth y luego crea el documento en Firestore
  Future<void> registrarUsuario({
    required String nombre,
    required String carnet,
    required String email,
    required String password,
  }) async {
    // Esto crea el usuario en la lista de "Authentication"
    UserCredential resultado = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Esto guarda los datos extra (nombre, carnet) en la base de datos "usuarios"
    await _db.collection('usuarios').doc(resultado.user!.uid).set({
      'nombre': nombre,
      'carnet': carnet,
      'email': email,
      'uid': resultado.user!.uid,
    });
  }

  // LOGIN: Verifica credenciales
  Future<void> iniciarSesion(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }
}