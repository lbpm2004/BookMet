import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'registro_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controladores para leer lo que el usuario escribe
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Llave para validar el formulario
  final _formKey = GlobalKey<FormState>();
  
  // Instancia de nuestro servicio de autenticación
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;

  void _iniciarSesion() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        await _authService.iniciarSesion(
          _correoController.text.trim(),
          _passwordController.text.trim(),
        );
        
        // Si el login es exitoso
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Bienvenido de nuevo a BookMet! 📚'),
            backgroundColor: Colors.green,
          ),
        );

        // Aquí podrías navegar a la pantalla principal (Home)
        // Navigator.pushReplacementNamed(context, '/home');

      } on FirebaseAuthException catch (e) {
        // Manejo de errores específicos de Firebase
        String mensajeError = 'Ocurrió un error inesperado';
        
        if (e.code == 'user-not-found') {
          mensajeError = 'No existe un usuario con este correo.';
        } else if (e.code == 'wrong-password') {
          mensajeError = 'La contraseña es incorrecta.';
        } else if (e.code == 'invalid-email') {
          mensajeError = 'El formato del correo no es válido.';
        } else if (e.code == 'user-disabled') {
          mensajeError = 'Esta cuenta ha sido deshabilitada.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensajeError),
            backgroundColor: Colors.red,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo o Icono
                const Icon(Icons.menu_book_rounded, size: 80, color: Colors.orange),
                const SizedBox(height: 20),
                const Text(
                  'BookMet',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Inicia sesión para continuar',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 40),

                // Campo de Correo
                TextFormField(
                  controller: _correoController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Correo Unimet',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Ingresa tu correo';
                    if (!value.contains('@')) return 'Ingresa un correo válido';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Campo de Contraseña
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.lock_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value!.isEmpty ? 'Ingresa tu contraseña' : null,
                ),
                const SizedBox(height: 30),

                // Botón Entrar
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                    : ElevatedButton(
                        onPressed: _iniciarSesion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[800],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text(
                          'INICIAR SESIÓN',
                          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                
                const SizedBox(height: 20),

                // Botón para ir a Registro
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegistroScreen()),
                    );
                  },
                  child: const Text(
                    '¿No tienes cuenta? Regístrate aquí',
                    style: TextStyle(color: Colors.orange),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}