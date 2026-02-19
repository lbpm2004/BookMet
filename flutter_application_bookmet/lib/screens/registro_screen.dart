import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart'; // Si están en la misma carpeta 'screens'

class RegistroScreen extends StatefulWidget {
  const RegistroScreen({super.key});

  @override
  _RegistroScreenState createState() => _RegistroScreenState();
}

class _RegistroScreenState extends State<RegistroScreen> {
  // Estos controladores guardan lo que el usuario escribe en tiempo real
  final _nombreController = TextEditingController();
  final _carnetController = TextEditingController();
  final _correoController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // Esta llave sirve para que Flutter sepa si el formulario es válido o tiene errores
  final _formKey = GlobalKey<FormState>();
  
  // Llamamos a nuestro "mensajero" de Firebase
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  // La función mágica que crea la cuenta
  void _registrar() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _authService.registrarUsuario(
          nombre: _nombreController.text.trim(),
          carnet: _carnetController.text.trim(),
          email: _correoController.text.trim(),
          password: _passwordController.text.trim(),
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('¡Registro Exitoso! Ahora inicia sesión')),
        );

      //Lo manda al Login automáticamente
      Navigator.pushReplacement(
      context, 
      MaterialPageRoute(builder: (context) => const LoginScreen())
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Usuario'),
        backgroundColor: Colors.orange[800], // Color representativo de la Unimet
        centerTitle: true,
      ),
      body: SingleChildScrollView( // Para que no dé error de espacio si sale el teclado
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Crea tu cuenta',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              
              // Campo: Nombre
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) => value!.isEmpty ? 'Por favor, ingresa tu nombre' : null,
              ),
              const SizedBox(height: 15),

              // Campo: Carnet
              TextFormField(
                controller: _carnetController,
                decoration: const InputDecoration(
                  labelText: 'Carnet (ej. 2024001)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty ? 'Ingresa tu número de carnet' : null,
              ),
              const SizedBox(height: 15),

              // Campo: Correo Unimet
              TextFormField(
                controller: _correoController,
                decoration: const InputDecoration(
                  labelText: 'Correo Institucional',
                  hintText: 'ejemplo@correo.unimet.edu.ve',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value!.isEmpty) return 'Ingresa tu correo';
                  if (!value.endsWith('@unimet.edu.ve') && !value.endsWith('@correo.unimet.edu.ve')) {
                    return 'Debes usar tu correo de la Unimet';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 15),

              // Campo: Contraseña
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Contraseña',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                validator: (value) => value!.length < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 30),

              // Botón de Registro
              _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _registrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[800],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('REGISTRARME', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}