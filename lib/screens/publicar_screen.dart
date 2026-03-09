import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PublicarScreen extends StatefulWidget {
  const PublicarScreen({super.key});

  @override
  _PublicarScreenState createState() => _PublicarScreenState();
}

class _PublicarScreenState extends State<PublicarScreen> {
  // Controladores exactos que solicitaste
  final _nombreController = TextEditingController();
  final _autoresController = TextEditingController();
  final _materiasController = TextEditingController();
  final _carrerasController = TextEditingController();
  final _descripcionController = TextEditingController();
  
  String? _estadoSeleccionado;
  final List<String> _opcionesEstado = [
    'nuevo',
    'como_nuevo',
    'usado_bueno',
    'deteriorado'
  ];

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Uint8List? _portadaBytes;
  String _portadaExtension = 'jpg';

  Uint8List? _contraportadaBytes;
  String _contraportadaExtension = 'jpg';

  final ImagePicker _picker = ImagePicker();

  Future<void> _seleccionarImagen(bool esPortada) async {
    final XFile? imagen = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (imagen != null) {
      final bytes = await imagen.readAsBytes();
      final extension = imagen.name.split('.').last;

      setState(() {
        if (esPortada) {
          _portadaBytes = bytes;
          _portadaExtension = extension;
        } else {
          _contraportadaBytes = bytes;
          _contraportadaExtension = extension;
        }
      });
    }
  }

  Future<String?> _subirImagenASupabase(Uint8List bytes, String tipo, String extension) async {
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_$tipo.$extension';
      final String bucketName = 'publicaciones';
      final String filePath = 'imagenes/$fileName';

      await Supabase.instance.client.storage
          .from(bucketName)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$extension'),
          );

      return Supabase.instance.client.storage
          .from(bucketName)
          .getPublicUrl(filePath);
    } catch (e) {
      throw Exception('Fallo Supabase al subir $tipo: $e');
    }
  }

  void _publicarLibro() async {
    if (_formKey.currentState!.validate()) {
      if (_portadaBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La foto de la portada es obligatoria.'), backgroundColor: Colors.orange),
        );
        return;
      }

      setState(() => _isLoading = true);

      try {
        final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        if (userId.isEmpty) throw Exception('Debes iniciar sesión.');

        // 1. Subir imágenes
        String? urlPortada = await _subirImagenASupabase(_portadaBytes!, 'portada', _portadaExtension);
        String? urlContraportada;
        if (_contraportadaBytes != null) {
          urlContraportada = await _subirImagenASupabase(_contraportadaBytes!, 'contraportada', _contraportadaExtension);
        }

        // 2. Guardar en Firestore con tus atributos exactos
        await FirebaseFirestore.instance.collection('libros').add({
          'nombre': _nombreController.text.trim(),
          'autores': _autoresController.text.trim().split(',').map((e) => e.trim()).toList(),
          'materias': _materiasController.text.trim().split(',').map((e) => e.trim()).toList(),
          'carreras': _carrerasController.text.trim().split(',').map((e) => e.trim()).toList(),
          'estado_fisico': _estadoSeleccionado,
          'descripcion': _descripcionController.text.trim(),
          'portadaUrl': urlPortada,
          'contraportadaUrl': urlContraportada,
          'propietarioId': userId,
          'estado_publicacion': 'pendiente', // Para tu lógica de aprobación
          'fechaCreacion': FieldValue.serverTimestamp(),
        });

        
        if (!mounted) return;
        // 1. Mostramos el mensaje verde en el borde inferior
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Publicación exitosa!', style: TextStyle(fontWeight: FontWeight.bold)), 
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating, // Hace que flote un poco en el borde inferior (opcional pero se ve genial)
          ),
        );

        // 2. Redirigimos a la pantalla del usuario destruyendo la pantalla de publicar
        Navigator.pushReplacementNamed(context, '/usuario');

      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
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
        height: 180, // Un poco más altas para que se vean bien en la columna
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(8),
          image: bytes != null
              ? DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover)
              : null,
        ),
        child: bytes == null
            ? Center(child: Text('Subir $titulo', style: TextStyle(color: Colors.grey[600])))
            : null,
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _autoresController.dispose();
    _materiasController.dispose();
    _carrerasController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Publicar Material'),
      ),
      // SingleChildScrollView previene la pantalla blanca por desbordamiento de píxeles
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // --- COLUMNA IZQUIERDA: FOTOS Y MENSAJE (Menos de la mitad, aprox 35%) ---
            Expanded(
              flex: 35,
              child: Column(
                children: [
                  _buildFotoContainer('Portada', _portadaBytes, () => _seleccionarImagen(true)),
                  _buildFotoContainer('Contraportada', _contraportadaBytes, () => _seleccionarImagen(false)),
                  
                  // Recuadro azulado de advertencia
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[800]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Al enviar el formulario, se pausará la publicación hasta que un administrador la apruebe.',
                            style: TextStyle(color: Colors.blue[900], height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            
            const SizedBox(width: 32), // Separación entre columnas

            // --- COLUMNA DERECHA: FORMULARIO (Aprox 65%) ---
            Expanded(
              flex: 65,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre del libro', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _autoresController,
                      decoration: const InputDecoration(labelText: 'Autor(es) separados por coma', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _materiasController,
                      decoration: const InputDecoration(labelText: 'Materias separadas por coma', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _carrerasController,
                      decoration: const InputDecoration(labelText: 'Carreras separadas por coma', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    DropdownButtonFormField<String>(
                      value: _estadoSeleccionado,
                      decoration: const InputDecoration(labelText: 'Estado del libro', border: OutlineInputBorder()),
                      items: _opcionesEstado.map((estado) {
                        return DropdownMenuItem(value: estado, child: Text(estado.replaceAll('_', ' ').toUpperCase()));
                      }).toList(),
                      onChanged: (val) => setState(() => _estadoSeleccionado = val),
                      validator: (v) => v == null ? 'Selecciona un estado' : null,
                    ),
                    const SizedBox(height: 16),
                    
                    // Descripción condicional
                    TextFormField(
                      controller: _descripcionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Descripción detallada',
                        hintText: _estadoSeleccionado == 'deteriorado' ? 'Describe los daños obligatoriamente' : 'Opcional si está en buen estado',
                        border: const OutlineInputBorder(),
                      ),
                      validator: (v) {
                        // Validación: Solo es obligatorio si el estado es 'deteriorado'
                        if (_estadoSeleccionado == 'deteriorado' && (v == null || v.trim().isEmpty)) {
                          return 'Debes describir el estado deteriorado del libro.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            onPressed: _publicarLibro,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              backgroundColor: Colors.blue[800],
                            ),
                            child: const Text('ENVIAR FORMULARIO', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}