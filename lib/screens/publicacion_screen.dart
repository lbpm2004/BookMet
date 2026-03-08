import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PublicarScreen extends StatefulWidget {
  const PublicarScreen({Key? key}) : super(key: key);

  @override
  _PublicarScreenState createState() => _PublicarScreenState();
}

class _PublicarScreenState extends State<PublicarScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _autorController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _carrerasController = TextEditingController();
  final TextEditingController _materiasController = TextEditingController();

  String? _estadoFisicoSeleccionado;
  final List<String> _opcionesEstado = [
    'Nuevo',
    'Como nuevo',
    'Buen estado',
    'Deteriorado'
  ];

  // Simuladores de imágenes (Pronto los haremos reales con Supabase)
  bool _tienePortada = false;
  bool _tieneContraportada = false;
  
  // Variable para mostrar un circulito de carga mientras se guarda en Firebase
  bool _estaPublicando = false;

  Future<void> _enviarPublicacion() async {
    // 1. Validamos que el formulario esté lleno
    if (_formKey.currentState!.validate()) {
      if (!_tienePortada || !_tieneContraportada) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, simula subir la portada y contraportada.'), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() {
        _estaPublicando = true; // Empezamos a cargar
      });

      try {
        // 2. Obtenemos quién es el usuario que está publicando
        final String? userId = FirebaseAuth.instance.currentUser?.uid;
        
        if (userId == null) throw Exception("No hay usuario logueado");

        // 3. ¡AQUÍ ESTÁ LA MAGIA! Guardamos los datos reales en Firestore
        await FirebaseFirestore.instance.collection('publicaciones').add({
          'usuarioId': userId,
          'titulo': _tituloController.text.trim(),
          'autor': _autorController.text.trim(),
          'descripcion': _descripcionController.text.trim(),
          'carreras': _carrerasController.text.trim(),
          'materias': _materiasController.text.trim(),
          'condicionFisica': _estadoFisicoSeleccionado,
          'estado': 'DISPONIBLE', // Lo ponemos disponible de una vez para que lo veas
          'fechaCreacion': FieldValue.serverTimestamp(), // La hora exacta del servidor
          'portadaUrl': '', // Por ahora vacío, luego conectamos Supabase
          'contraportadaUrl': '',
        });

        if (!mounted) return;

        // 4. Mostramos mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Libro publicado con éxito! 📚'), backgroundColor: Colors.green),
        );

        // 5. Limpiamos el formulario para que quede vacío de nuevo
        _tituloController.clear();
        _autorController.clear();
        _descripcionController.clear();
        _carrerasController.clear();
        _materiasController.clear();
        setState(() {
          _estadoFisicoSeleccionado = null;
          _tienePortada = false;
          _tieneContraportada = false;
        });

      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al publicar: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() {
          _estaPublicando = false; // Apagamos el circulito de carga
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Publicar Material',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Llena los datos para que otros puedan encontrar tu libro.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // --- FOTOS (Simuladas por ahora) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildBotonFoto('Portada', _tienePortada, () {
                    setState(() => _tienePortada = !_tienePortada);
                  }),
                  _buildBotonFoto('Contraportada', _tieneContraportada, () {
                    setState(() => _tieneContraportada = !_tieneContraportada);
                  }),
                ],
              ),
              const SizedBox(height: 24),

              // --- FORMULARIO ---
              _buildTextField(
                controlador: _tituloController,
                etiqueta: 'Título del Libro',
                icono: Icons.menu_book,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controlador: _autorController,
                etiqueta: 'Autor(es)',
                icono: Icons.person_outline,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _estadoFisicoSeleccionado,
                decoration: InputDecoration(
                  labelText: 'Estado físico del libro *',
                  prefixIcon: const Icon(Icons.info_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: _opcionesEstado.map((String estado) {
                  return DropdownMenuItem(value: estado, child: Text(estado));
                }).toList(),
                onChanged: (String? nuevoValor) {
                  setState(() {
                    _estadoFisicoSeleccionado = nuevoValor;
                  });
                },
                validator: (value) => value == null ? 'Selecciona el estado' : null,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controlador: _carrerasController,
                etiqueta: 'Carrera(s)',
                hint: 'Ej: Ing. Sistemas, Psicología...',
                icono: Icons.school_outlined,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controlador: _materiasController,
                etiqueta: 'Materia(s)',
                hint: 'Ej: Programación III, Cálculo...',
                icono: Icons.class_outlined,
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controlador: _descripcionController,
                etiqueta: 'Descripción adicional',
                hint: 'Ej: Tiene algunas notas a lápiz...',
                icono: Icons.description_outlined,
                maxLines: 3,
                esObligatorio: false, // Este campo no es obligatorio
              ),
              const SizedBox(height: 32),

              // --- BOTÓN DE ENVIAR ---
              SizedBox(
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _estaPublicando ? null : _enviarPublicacion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[800],
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _estaPublicando 
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send, color: Colors.white),
                  label: Text(
                    _estaPublicando ? 'Publicando...' : 'Publicar Libro', 
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS AUXILIARES (Para que el código quede limpio arriba) ---

  Widget _buildTextField({
    required TextEditingController controlador,
    required String etiqueta,
    required IconData icono,
    int maxLines = 1,
    String? hint,
    bool esObligatorio = true,
  }) {
    return TextFormField(
      controller: controlador,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: esObligatorio ? '$etiqueta *' : etiqueta,
        hintText: hint,
        prefixIcon: Icon(icono),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey[50],
      ),
      validator: (value) {
        if (esObligatorio && (value == null || value.trim().isEmpty)) {
          return 'Este campo es obligatorio';
        }
        return null;
      },
    );
  }

  Widget _buildBotonFoto(String titulo, bool tieneFoto, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        width: 100,
        decoration: BoxDecoration(
          color: tieneFoto ? Colors.green[50] : Colors.grey[100],
          border: Border.all(color: tieneFoto ? Colors.green : Colors.grey[300]!, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tieneFoto ? Icons.check_circle : Icons.add_a_photo,
              color: tieneFoto ? Colors.green : Colors.grey[500],
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              titulo,
              style: TextStyle(
                color: tieneFoto ? Colors.green[700] : Colors.grey[700],
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}