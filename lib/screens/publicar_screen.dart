import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PublicarScreen extends StatefulWidget {
  final Map<String, dynamic>? libroAEditar;
  final String? docId;

  const PublicarScreen({super.key, this.libroAEditar, this.docId});

  @override
  _PublicarScreenState createState() => _PublicarScreenState();
}

class _PublicarScreenState extends State<PublicarScreen> {
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

  @override
  void initState() {
    super.initState();
    if (widget.libroAEditar != null) {
      _nombreController.text = widget.libroAEditar!['titulo'] ?? '';
      _autoresController.text = widget.libroAEditar!['autor'] ?? '';
      _materiasController.text = widget.libroAEditar!['materia'] ?? '';
      _carrerasController.text = widget.libroAEditar!['carrera'] ?? '';
      _descripcionController.text = widget.libroAEditar!['descripcion'] ?? '';
      _estadoSeleccionado = widget.libroAEditar!['estadoFisico'];
    }
  }

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
      await Supabase.instance.client.storage
          .from('portadas')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$extension'),
          );

      return Supabase.instance.client.storage
          .from('portadas')
          .getPublicUrl(fileName);
    } catch (e) {
      debugPrint("Error subiendo a Supabase: $e");
      return null;
    }
  }

  // ESTA FUNCIÓN ES LA QUE ARREGLA EL PANTALLAZO BLANCO
  void _enviarSolicitud() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);

    try {
      final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (userId.isEmpty) throw Exception('Sesión expirada. Inicia sesión de nuevo.');

      String? urlPortada = widget.libroAEditar?['fotoUrl'] ?? 'https://via.placeholder.com/300x400.png?text=Sin+Portada';
      String? urlContraportada = widget.libroAEditar?['contraportadaUrl'];

      if (_portadaBytes != null) {
        String? subida = await _subirImagenASupabase(_portadaBytes!, 'portada', _portadaExtension);
        if (subida != null) urlPortada = subida;
      }

      if (_contraportadaBytes != null) {
        String? subida = await _subirImagenASupabase(_contraportadaBytes!, 'contraportada', _contraportadaExtension);
        if (subida != null) urlContraportada = subida;
      }

      final Map<String, dynamic> datosLibro = {
        'titulo': _nombreController.text.trim(),
        'autor': _autoresController.text.trim(),
        'materia': _materiasController.text.trim(),
        'carrera': _carrerasController.text.trim(),
        'estadoFisico': _estadoSeleccionado,
        'descripcion': _descripcionController.text.trim(),
        'fotoUrl': urlPortada, 
        'contraportadaUrl': urlContraportada,
        'usuarioId': userId, 
        'estado': 'Pendiente', 
        'fechaActualizacion': FieldValue.serverTimestamp(),
      };

      if (widget.docId != null) {
        await FirebaseFirestore.instance.collection('publicaciones').doc(widget.docId).update(datosLibro);
      } else {
        datosLibro['fechaPublicacion'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('publicaciones').add(datosLibro);
      }

      // IMPORTANTE: Manejo de éxito sin bloquear la app
      if (!mounted) return;
      
      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Solicitud procesada correctamente! 🕒'), 
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.of(context).pop(); // Volver atrás de forma segura

    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
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

  Widget _buildFotoContainer(String titulo, Uint8List? bytes, String? urlPrevia, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180, 
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(color: Colors.grey[400]!),
          borderRadius: BorderRadius.circular(8),
          image: bytes != null
              ? DecorationImage(image: MemoryImage(bytes), fit: BoxFit.cover)
              : (urlPrevia != null && urlPrevia.isNotEmpty ? DecorationImage(image: NetworkImage(urlPrevia), fit: BoxFit.cover) : null),
        ),
        child: (bytes == null && (urlPrevia == null || urlPrevia.isEmpty))
            ? Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo, color: Colors.grey),
                  Text('Subir $titulo', style: TextStyle(color: Colors.grey[600])),
                ],
              ))
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.docId != null ? 'Editar Libro' : 'Nueva Publicación'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.orange[800],
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 40,
              child: Column(
                children: [
                  _buildFotoContainer('Portada', _portadaBytes, widget.libroAEditar?['fotoUrl'], () => _seleccionarImagen(true)),
                  _buildFotoContainer('Contraportada', _contraportadaBytes, widget.libroAEditar?['contraportadaUrl'], () => _seleccionarImagen(false)),
                  const Card(
                    color: Color(0xFFE3F2FD),
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text('Toda publicación pasa por revisión del administrador.', style: TextStyle(fontSize: 11, color: Colors.blue)),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 60,
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(labelText: 'Título del libro', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Ingresa el título' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _autoresController,
                      decoration: const InputDecoration(labelText: 'Autor', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Ingresa el autor' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _materiasController,
                      decoration: const InputDecoration(labelText: 'Materia', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Ingresa la materia' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _carrerasController,
                      decoration: const InputDecoration(labelText: 'Carrera', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Ingresa la carrera' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _estadoSeleccionado,
                      decoration: const InputDecoration(labelText: 'Estado físico', border: OutlineInputBorder()),
                      items: _opcionesEstado.map((e) => DropdownMenuItem(value: e, child: Text(e.replaceAll('_', ' ').toUpperCase()))).toList(),
                      onChanged: (val) => setState(() => _estadoSeleccionado = val),
                      validator: (v) => v == null ? 'Selecciona el estado' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descripcionController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.orange)
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _enviarSolicitud,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange[800],
                                padding: const EdgeInsets.symmetric(vertical: 18),
                              ),
                              child: Text(widget.docId != null ? 'GUARDAR CAMBIOS' : 'PUBLICAR', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
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