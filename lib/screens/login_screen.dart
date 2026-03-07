import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../widgets/fondo_con_blur.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
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
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Bienvenido de nuevo! 📚'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacementNamed(context, '/usuario'); // Ruta centralizada
        
      } catch (e) {
        // AQUÍ ESTÁ EL CAMBIO: Atrapamos el error de auth_service y lo limpiamos
        String mensajeError = e.toString().replaceAll('Exception: ', '');
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              mensajeError, 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.red[800], // Un rojo elegante para los errores
            duration: const Duration(seconds: 4),
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // Función auxiliar para que los campos queden igualitos a los del registro
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.orange),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.orange, width: 2)),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), 
      ),
      body: FondoConBlur(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450), 
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95), 
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15), 
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min, 
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'BookMet',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 38, fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                    const SizedBox(height: 10), 
                    Text(
                      'Inicia sesión para continuar',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[800], fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 35),

                    // Campo Correo
                    _buildTextField(
                      controller: _correoController,
                      label: 'Correo Unimet',
                      icon: Icons.email_outlined,
                      type: TextInputType.emailAddress,
                      validator: (value) => value!.isEmpty ? 'Ingresa tu correo' : null,
                    ),
                    const SizedBox(height: 20),

                    // Campo Contraseña
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Contraseña',
                      icon: Icons.lock_outline,
                      obscure: true,
                      validator: (value) => value!.isEmpty ? 'Ingresa tu contraseña' : null,
                    ),
                    const SizedBox(height: 35),

                    // Botón Entrar
                    _isLoading
                        ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                        : Container(
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))
                              ]
                            ),
                            child: ElevatedButton(
                                onPressed: _iniciarSesion,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange[800],
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  elevation: 0, 
                                ),
                                child: const Text('INICIAR SESIÓN', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                          ),
                    const SizedBox(height: 20),

                    // Botón Registro 
                    TextButton(
                      onPressed: () => Navigator.pushNamed(context, '/registro'),
                      child: Text('¿No tienes cuenta? Regístrate aquí', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold)),
                    ),

                    // Botón Recuperación de contraseña 
                    TextButton(
                       onPressed: () async {
                        final correo = _correoController.text.trim();
                        if (correo.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Por favor, escribe tu correo arriba para enviar el enlace.'), backgroundColor: Colors.orange));
                            return;
                        }
                        
                        // Expresión regular para validar formato de correo básico
                        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                        if (!emailRegex.hasMatch(correo)) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Por favor, ingresa un formato de correo válido.'), backgroundColor: Colors.red));
                            return;
                        }

                        try {
                          await _authService.recuperarPassword(correo);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Correo de recuperación enviado 📧. Revisa tu bandeja/spam.'), backgroundColor: Colors.green)
                          );
                        } on FirebaseAuthException catch (e) {
                          String errorMsg = 'Error al enviar el correo';
                          if (e.code == 'user-not-found') {
                            errorMsg = 'No hay ninguna cuenta registrada con este correo.';
                          }
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Error inesperado al intentar recuperar la contraseña.'), backgroundColor: Colors.red));
                        }
                       },
                       child: Text('¿Olvidaste tu contraseña? Recupérala aquí', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold))
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}