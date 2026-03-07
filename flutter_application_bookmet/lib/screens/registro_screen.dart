import 'dart:typed_data'; 
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/fondo_con_blur.dart'; 

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({Key? key}) : super(key: key);

  @override
  _RegistroScreenState createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  // Controladores para leer lo que escribe el usuario
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController(); 
  final _cedulaController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Uint8List? _imagenBytes; 
  final ImagePicker _picker = ImagePicker();

  Future<void> _seleccionarFoto() async {
    final XFile? imagen = await _picker.pickImage(source: ImageSource.gallery);
    if (imagen != null) {
      final bytes = await imagen.readAsBytes(); 
      setState(() {
        _imagenBytes = bytes;
      });
    }
  }

  Future<String?> _subirFotoSupabase(String nombreArchivo) async {
    if (_imagenBytes == null) return null;

    try {
      final String rutaArchivo = '$nombreArchivo.jpg';

      await Supabase.instance.client.storage
          .from('perfiles')
          .uploadBinary(
            rutaArchivo, 
            _imagenBytes!,
            fileOptions: const FileOptions(contentType: 'image/jpeg'), 
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
        // 1. Subir la foto a Supabase (si seleccionó una)
        String? linkFoto;
        if (_imagenBytes != null) {
          // Generamos un nombre único basado en la fecha/hora actual
          // Así evitamos errores si la cédula/carnet está vacía
          final String nombreUnico = DateTime.now().millisecondsSinceEpoch.toString();
          linkFoto = await _subirFotoSupabase(nombreUnico);
        }

        // 2. Registrar en Firebase a través del AuthService
        await _authService.registrarUsuario(
          nombre: _nombreController.text.trim(),
          apellido: _apellidoController.text.trim(), 
          cedula: _cedulaController.text.trim(), // Puede ir vacío sin problema
          email: _correoController.text.trim(),
          password: _passwordController.text.trim(),
          fotoUrl: linkFoto ?? '', 
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Registro Exitoso! Ahora inicia sesión'), backgroundColor: Colors.green),
        );
        // Usamos rutas nombradas para mantener la coherencia con el diagrama
        Navigator.pushReplacementNamed(context, '/login'); 
        
      } on FirebaseAuthException catch (e) {
        String mensajeError = 'Ocurrió un error al registrar el usuario.';

        // Traducimos los códigos más comunes de Firebase al español
        if (e.code == 'email-already-in-use') {
          mensajeError = 'Este correo electrónico ya está registrado. Intenta iniciar sesión.';
        } else if (e.code == 'weak-password') {
          mensajeError = 'La contraseña es muy débil. Debe tener al menos 6 caracteres.';
        } else if (e.code == 'invalid-email') {
          mensajeError = 'El formato del correo electrónico no es válido.';
        } else if (e.code == 'operation-not-allowed') {
          mensajeError = 'El registro por correo está deshabilitado en el sistema.';
        } else {
          // Si es un error raro, mostramos el código para poder rastrearlo
          mensajeError = 'Error: ${e.code}'; 
        }

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(mensajeError), backgroundColor: Colors.red),
        );
        
      } catch (e) {
        // Para cualquier otro error que no sea de Firebase (ej. no hay internet)
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ocurrió un error inesperado en el sistema.'), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  // Función auxiliar para las casillas de texto
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
        boxShadow:[
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
                boxShadow:[
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
                  children:[
                    const Text(
                      'Crea tu cuenta',
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.orange),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    
                    // --- FOTO DE PERFIL ---
                    GestureDetector(
                      onTap: _seleccionarFoto, 
                      child: CircleAvatar(
                        radius: 50, 
                        backgroundColor: Colors.orange.withOpacity(0.1),
                        backgroundImage: _imagenBytes != null 
                            ? MemoryImage(_imagenBytes!) 
                            : null,
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

                    // Cédula o Carnet (OPCIONAL)
                    _buildTextField(
                      controller: _cedulaController,
                      label: 'Cédula (Opcional)',
                      icon: Icons.badge_outlined,
                      type: TextInputType.number,
                      validator: (value) => null, 
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
                            boxShadow:[
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
                    const SizedBox(height: 20),

                    // Botón de regreso al Login (por si el usuario ya tiene cuenta)
                    TextButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                      child: Text('¿Ya tienes cuenta? Inicia sesión aquí', style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.bold)),
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