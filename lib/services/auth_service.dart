import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Iniciar sesión
  Future<void> iniciarSesion(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      // Aquí atrapamos los errores específicos de Firebase
      if (e.code == 'invalid-credential' || e.code == 'wrong-password') {
        throw Exception('Contraseña incorrecta. Inténtalo de nuevo.');
      } else if (e.code == 'user-not-found') {
        throw Exception('No existe ninguna cuenta con este correo.');
      } else if (e.code == 'user-disabled') {
        throw Exception('Esta cuenta ha sido deshabilitada.');
      } else {
        throw Exception('Error al iniciar sesión: ${e.message}');
      }
    } catch (e) {
      // Esto atrapa cualquier otro error raro que no sea de Firebase
      throw Exception('Ocurrió un error inesperado.');
    }
  }

  // Registrar usuario con nombre y apellido separados
  Future<void> registrarUsuario({
    required String nombre,
    required String apellido,
    required String cedula,
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

      // 2. Lógica dinámica para asignar el ROL
      // Si termina en @unimet.edu.ve es DOCENTE, de lo contrario es ESTUDIANTE
      String rolAsignado = email.endsWith('@unimet.edu.ve') ? 'DOCENTE' : 'ESTUDIANTE';


      // 2. Guardar los datos en Firestore (Base de Datos)
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