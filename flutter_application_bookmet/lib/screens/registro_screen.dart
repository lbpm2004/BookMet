import 'dart:typed_data'; 
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/fondo_con_blur.dart'; 
import 'login_screen.dart';

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({Key? key}) : super(key: key);

  @override
  _RegistroScreenState createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  // Controladores para leer lo que escribe el usuario
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController(); // Controlador para el apellido
  final _carnetController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Uint8List? _imagenBytes; // <-- En web guardamos los bytes
  final ImagePicker _picker = ImagePicker();

  Future<void> _seleccionarFoto() async {
    final XFile? imagen = await _picker.pickImage(source: ImageSource.gallery);
    if (imagen != null) {
      // Leemos los bytes de la imagen para la Web
      final bytes = await imagen.readAsBytes(); 
      setState(() {
        _imagenBytes = bytes;
      });
    }
  }

  Future<String?> _subirFotoSupabase(String uidUsuario) async {
    if (_imagenBytes == null) return null;

    try {
      final String rutaArchivo = '$uidUsuario.jpg';

      // Usamos uploadBinary que es el método compatible con Flutter Web
      await Supabase.instance.client.storage
          .from('perfiles')
          .uploadBinary(
            rutaArchivo, 
            _imagenBytes!,
            fileOptions: const FileOptions(contentType: 'image/jpeg'), // Le decimos a Supabase que es una imagen
          );

      final String urlPublica = Supabase.instance.client.storage
          .from('perfiles')
          .getPublicUrl(rutaArchivo);

      return urlPublica;
    } catch (e) {
      print('Error al subir a Supabase: $e');
      return null;
    }
  }

  void _registrar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        // 1. Subir la foto a Supabase (si el usuario seleccionó una)
        String? linkFoto;
        if (_imagenBytes != null) {
          // Usamos el carnet como nombre del archivo (ej. "2024001.jpg")
          linkFoto = await _subirFotoSupabase(_carnetController.text.trim());
        }

        // 2. Registrar en Firebase a través de tu AuthService
        await _authService.registrarUsuario(
          nombre: _nombreController.text.trim(),
          apellido: _apellidoController.text.trim(), 
          carnet: _carnetController.text.trim(),
          email: _correoController.text.trim(),
          password: _passwordController.text.trim(),
          fotoUrl: linkFoto ?? '', // <--- ¡Añadimos este nuevo parámetro!
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Registro Exitoso! Ahora inicia sesión'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  /* ANTIGUA FUNCION DE REGISTRO SIN SUPABASE void _registrar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _authService.registrarUsuario(
          // ¡Aquí los enviamos separados al AuthService!
          nombre: _nombreController.text.trim(),
          apellido: _apellidoController.text.trim(), 
          carnet: _carnetController.text.trim(),
          email: _correoController.text.trim(),
          password: _passwordController.text.trim(),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Registro Exitoso! Ahora inicia sesión'), backgroundColor: Colors.green),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }*/

  // Función auxiliar para dibujar las casillas de texto elegantemente
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
    bool obscure = false,
    String? Function(String?)? validator,
    String? hint,
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
          hintText: hint,
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
        iconTheme: const IconThemeData(color: Colors.black87), 
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
                      'Crea tu cuenta',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.orange),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    
                    // ---> INICIO DEL CÓDIGO DE LA FOTO DE PERFIL <---
                    GestureDetector(
                      onTap: _seleccionarFoto, // Llama a tu función al hacer clic
                      child: CircleAvatar(
                        radius: 50, // Tamaño del círculo
                        backgroundColor: Colors.orange.withOpacity(0.1),
                        // Si hay bytes en memoria, muestra la imagen, si no, es nulo
                        backgroundImage: _imagenBytes != null 
                            ? MemoryImage(_imagenBytes!) 
                            : null,
                        // Si no hay imagen, muestra un ícono de cámara por defecto
                        child: _imagenBytes == null
                            ? const Icon(Icons.add_a_photo, size: 40, color: Colors.orange)
                            : null,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Subir foto de perfil',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 20),
                    // ---> FIN DEL CÓDIGO DE LA FOTO DE PERFIL <---

                    // Nombre
                    _buildTextField(
                      controller: _nombreController,
                      label: 'Nombre',
                      icon: Icons.person_outline,
                      validator: (value) => value!.isEmpty ? 'Ingresa tu nombre' : null,
                    ),
                    const SizedBox(height: 20),

                    // Apellido
                    _buildTextField(
                      controller: _apellidoController,
                      label: 'Apellido',
                      icon: Icons.person_outline,
                      validator: (value) => value!.isEmpty ? 'Ingresa tu apellido' : null,
                    ),
                    const SizedBox(height: 20),

                    // Carnet
                    _buildTextField(
                      controller: _carnetController,
                      label: 'Carnet (ej. 2024001)',
                      icon: Icons.badge_outlined,
                      type: TextInputType.number,
                      validator: (value) => value!.isEmpty ? 'Ingresa tu número de carnet' : null,
                    ),
                    const SizedBox(height: 20),

                    // Correo Unimet
                    _buildTextField(
                      controller: _correoController,
                      label: 'Correo Institucional',
                      hint: 'ejemplo@correo.unimet.edu.ve',
                      icon: Icons.email_outlined,
                      type: TextInputType.emailAddress,
                      validator: (value) {
                        if (value!.isEmpty) return 'Ingresa tu correo';
                        if (!value.endsWith('@unimet.edu.ve') && !value.endsWith('@correo.unimet.edu.ve')) {
                          return 'Debes usar tu correo de la Unimet';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Contraseña
                    _buildTextField(
                      controller: _passwordController,
                      label: 'Contraseña',
                      icon: Icons.lock_outline,
                      obscure: true,
                      validator: (value) => value!.length < 6 ? 'Mínimo 6 caracteres' : null,
                    ),
                    const SizedBox(height: 35),

                    // Botón Registro
                    _isLoading 
                      ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                      : Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(color: Colors.orange.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 6))
                            ]
                          ),
                          child: ElevatedButton(
                              onPressed: _registrar,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[800],
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              child: const Text('REGISTRARME', style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
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