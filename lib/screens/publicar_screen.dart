import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PublicarScreen extends StatefulWidget {
  const PublicarScreen({super.key});

  @override
  _PublicarScreenState createState() => _PublicarScreenState();
}

class _PublicarScreenState extends State<PublicarScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  final TextEditingController _tituloController = TextEditingController();
  final TextEditingController _autorController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _carrerasController = TextEditingController();
  final TextEditingController _materiasController = TextEditingController();

  // Variables de estado
  String? _estadoFisicoSeleccionado;
  final List<String> _opcionesEstado = [
    'Nuevo',
    'Como nuevo',
    'Buen estado',
    'Deteriorado'
  ];

  // Simuladores de imágenes
  bool _tienePortada = false;
  bool _tieneContraportada = false;
  bool _estaCargando = false; // Para mostrar un circulito de carga al enviar

  // Buena práctica: Limpiar los controladores cuando se destruye la pantalla
  @override
  void dispose() {
    _tituloController.dispose();
    _autorController.dispose();
    _descripcionController.dispose();
    _carrerasController.dispose();
    _materiasController.dispose();
    super.dispose();
  }

  // --- FUNCIÓN PRINCIPAL PARA GUARDAR EN FIREBASE ---
  void _enviarPublicacion() async {
    if (_formKey.currentState!.validate()) {
      if (!_tienePortada || !_tieneContraportada) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, sube la portada y contraportada del libro.'), backgroundColor: Colors.red),
        );
        return;
      }

      final String? userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Debes iniciar sesión para publicar.'), backgroundColor: Colors.red),
        );
        return;
      }

      setState(() {
        _estaCargando = true; // Mostramos el indicador de carga
      });

      try {
        await FirebaseFirestore.instance.collection('publicaciones').add({
          'titulo': _tituloController.text.trim(),
          'autor': _autorController.text.trim(),
          'estadoFisico': _estadoFisicoSeleccionado,
          'carreras': _carrerasController.text.trim(),
          'materias': _materiasController.text.trim(),
          'descripcion': _descripcionController.text.trim(),
          'estado': 'PAUSADO', // Inicia pausado para revisión según tu documento
          'fechaCreacion': FieldValue.serverTimestamp(),
          'usuarioId': userId, // ¡CLAVE para que funcione "Mis Publicaciones"!
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Libro guardado y enviado a revisión!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Limpiamos todo el formulario
        _formKey.currentState!.reset();
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
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) {
          setState(() {
            _estaCargando = false; // Ocultamos el indicador de carga
          });
        }
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Publicar Material Académico',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 8),
              Text(
                'Llena los datos del libro para enviarlo a revisión. Recuerda que la calidad de la información ayuda a otros estudiantes.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // --- CAMPOS DE TEXTO ---
              _buildTextField(
                controlador: _tituloController,
                etiqueta: 'Título del Libro',
                icono: Icons.book,
                hint: 'Ej: Cálculo de una variable',
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controlador: _autorController,
                etiqueta: 'Autor(es)',
                icono: Icons.person,
                hint: 'Ej: James Stewart',
              ),
              const SizedBox(height: 16),

              // --- DROPDOWN ESTADO FÍSICO ---
              DropdownButtonFormField<String>(
                initialValue: _estadoFisicoSeleccionado,
                decoration: InputDecoration(
                  labelText: 'Estado Físico *',
                  prefixIcon: const Icon(Icons.health_and_safety),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                items: _opcionesEstado.map((estado) {
                  return DropdownMenuItem(value: estado, child: Text(estado));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _estadoFisicoSeleccionado = value;
                  });
                },
                validator: (value) => value == null ? 'Selecciona el estado del libro' : null,
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controlador: _carrerasController,
                      etiqueta: 'Carrera',
                      icono: Icons.school,
                      hint: 'Ej: Ing. Sistemas',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controlador: _materiasController,
                      etiqueta: 'Materia',
                      icono: Icons.class_,
                      hint: 'Ej: Matemáticas I',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildTextField(
                controlador: _descripcionController,
                etiqueta: 'Descripción / Detalles',
                icono: Icons.description,
                maxLines: 3,
                hint: 'Comenta si tiene rayones, si le faltan páginas, edición, etc.',
                esObligatorio: false, // La descripción no es obligatoria
              ),
              const SizedBox(height: 24),

              // --- SECCIÓN DE IMÁGENES ---
              const Text('Fotografías del Material *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildBotonImagen(
                      titulo: 'Portada',
                      tieneImagen: _tienePortada,
                      onTap: () => setState(() => _tienePortada = !_tienePortada),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildBotonImagen(
                      titulo: 'Contraportada',
                      tieneImagen: _tieneContraportada,
                      onTap: () => setState(() => _tieneContraportada = !_tieneContraportada),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // --- BOTÓN DE ENVIAR ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: _estaCargando
                    ? const Center(child: CircularProgressIndicator(color: Colors.orange))
                    : ElevatedButton.icon(
                        onPressed: _enviarPublicacion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[800],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.send, color: Colors.white),
                        label: const Text('Enviar para Revisión', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS REUTILIZABLES ---

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

  Widget _buildBotonImagen({required String titulo, required bool tieneImagen, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: tieneImagen ? Colors.green[50] : Colors.grey[100],
          border: Border.all(color: tieneImagen ? Colors.green : Colors.grey[300]!, width: 2, style: tieneImagen ? BorderStyle.solid : BorderStyle.none),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              tieneImagen ? Icons.check_circle : Icons.camera_alt,
              color: tieneImagen ? Colors.green : Colors.grey[400],
              size: 40,
            ),
            const SizedBox(height: 8),
            Text(
              tieneImagen ? '$titulo Lista' : 'Subir $titulo',
              style: TextStyle(
                color: tieneImagen ? Colors.green[700] : Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}