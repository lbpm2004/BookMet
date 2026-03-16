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
  final _descripcionController = TextEditingController();
  final _detallesFisicosController = TextEditingController(); 
  
  String? _carreraSeleccionada;
  String? _materiaSeleccionada;
  String? _estadoSeleccionado;
  
  final List<String> _carreras = ['Ingenieria', 'Psicologia', 'Derecho', 'Administracion', 'Economía', 'Educación'];
  final List<String> _materias = ['Matemáticas 1', 'Matemáticas 2', 'Matemáticas 3', 'Matemáticas 4', 'Matemáticas 5', 'Física 1', 'Física 2', 'Introducción a la Psicología', 'Psicología Cognitiva', 'Psicometría', 'Introducción a Derecho', 'Lógica y Argumentación', 'Derechos Humanos','Principios de Economía', 'Contabilidad 1', 'Finanzas 1','Introducción a las Ciencias Administrativas', 'Estadística 1', 'Gestión del Capital Humano'];

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
      _descripcionController.text = widget.libroAEditar!['descripcion'] ?? '';
      _detallesFisicosController.text = widget.libroAEditar!['detallesFisicos'] ?? ''; 
      
      String materiaGuardada = widget.libroAEditar!['materia'] ?? '';
      if (_materias.contains(materiaGuardada)) {
        _materiaSeleccionada = materiaGuardada;
      }
      
      String carreraGuardada = widget.libroAEditar!['carrera'] ?? '';
      if (_carreras.contains(carreraGuardada)) {
        _carreraSeleccionada = carreraGuardada;
      }

      String estadoGuardado = widget.libroAEditar!['estadoFisico'] ?? widget.libroAEditar!['estado'] ?? '';
      if (_opcionesEstado.contains(estadoGuardado)) {
        _estadoSeleccionado = estadoGuardado;
      }
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _autoresController.dispose();
    _descripcionController.dispose();
    _detallesFisicosController.dispose();
    super.dispose();
  }

  Future<void> _seleccionarImagen(bool esPortada) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      final bytes = await image.readAsBytes();
      final ext = image.name.split('.').last;
      setState(() {
        if (esPortada) {
          _portadaBytes = bytes;
          _portadaExtension = ext;
        } else {
          _contraportadaBytes = bytes;
          _contraportadaExtension = ext;
        }
      });
    }
  }

  Future<String?> _subirImagenSupabase(Uint8List bytes, bool esPortada, String uid) async {
    try {
      final String prefijo = esPortada ? 'portada' : 'contra';
      final String nombreArchivo = '${prefijo}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Armamos la ruta exacta que viste en Supabase: libros -> uid -> archivo.jpg
      final String rutaCompleta = 'libros/$uid/$nombreArchivo';
      
      await Supabase.instance.client.storage
          // AQUÍ ESTABA EL ERROR: Apuntamos al bucket real
          .from('publicaciones') 
          .uploadBinary(
            rutaCompleta, 
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );
          
      return Supabase.instance.client.storage
          .from('publicaciones')
          .getPublicUrl(rutaCompleta);
    } catch (e) {
      debugPrint("Error subiendo imagen a Supabase: $e");
      return null;
    }
  }

  Future<void> _enviarSolicitud() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (widget.docId == null && (_portadaBytes == null || _contraportadaBytes == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, añade ambas imágenes (portada y contraportada)')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("Usuario no autenticado");
      
      String? portadaUrl = widget.libroAEditar?['fotoUrl'];
      String? contraportadaUrl = widget.libroAEditar?['contraportadaUrl'];

      // AHORA LE PASAMOS EL user.uid AL MÉTODO
      if (_portadaBytes != null) {
        portadaUrl = await _subirImagenSupabase(_portadaBytes!, true, user.uid);
      }
      if (_contraportadaBytes != null) {
        contraportadaUrl = await _subirImagenSupabase(_contraportadaBytes!, false, user.uid);
      }

      final Map<String, dynamic> datosLibro = {
        'titulo': _nombreController.text.trim(),
        'autor': _autoresController.text.trim(),
        'materia': _materiaSeleccionada,
        'carrera': _carreraSeleccionada,
        'estadoFisico': _estadoSeleccionado,
        'descripcion': _descripcionController.text.trim(),
        'detallesFisicos': _detallesFisicosController.text.trim(), 
        'fotoUrl': portadaUrl,
        'contraportadaUrl': contraportadaUrl,
        'usuarioId': user.uid,
        'fechaPublicacion': FieldValue.serverTimestamp(),
      };

      if (widget.docId == null) {
        datosLibro['estado'] = 'PENDIENTE'; 
        await FirebaseFirestore.instance.collection('publicaciones').add(datosLibro);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Libro enviado a revisión 🕒. El administrador lo aprobará pronto.'), 
            backgroundColor: const Color(0xFF1859A9)
          ),
        );
      } else {
        await FirebaseFirestore.instance.collection('publicaciones').doc(widget.docId).update(datosLibro);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cambios guardados ✅'), backgroundColor: Colors.green),
        );
      }

      if (!mounted) return;
      _nombreController.clear();
      _autoresController.clear();
      _descripcionController.clear();
      _detallesFisicosController.clear(); 
      setState(() {
        _carreraSeleccionada = null;
        _materiaSeleccionada = null;
        _estadoSeleccionado = null;
        _portadaBytes = null;
        _contraportadaBytes = null;
      });

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.docId != null ? 'Editar Publicación' : 'Aportar Libro'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.orange[800], 
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Sube tus fotos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _seleccionarImagen(true),
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: _portadaBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(_portadaBytes!, fit: BoxFit.cover, width: double.infinity),
                              )
                            : (widget.libroAEditar?['fotoUrl'] != null && _portadaBytes == null)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(widget.libroAEditar!['fotoUrl'], fit: BoxFit.cover, width: double.infinity),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('Portada', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _seleccionarImagen(false),
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: _contraportadaBytes != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(_contraportadaBytes!, fit: BoxFit.cover, width: double.infinity),
                              )
                            : (widget.libroAEditar?['contraportadaUrl'] != null && _contraportadaBytes == null)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(widget.libroAEditar!['contraportadaUrl'], fit: BoxFit.cover, width: double.infinity),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text('Contraportada', style: TextStyle(color: Colors.grey)),
                                    ],
                                  ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nombreController,
                decoration: const InputDecoration(labelText: 'Título del libro', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Ingresa el título' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _autoresController,
                decoration: const InputDecoration(labelText: 'Autor(es)', border: OutlineInputBorder()),
                validator: (value) => value!.isEmpty ? 'Ingresa el autor' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _carreraSeleccionada,
                decoration: const InputDecoration(labelText: 'Carrera', border: OutlineInputBorder()),
                items: _carreras.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (value) => setState(() => _carreraSeleccionada = value),
                validator: (value) => value == null ? 'Selecciona una carrera' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _materiaSeleccionada,
                decoration: const InputDecoration(labelText: 'Materia', border: OutlineInputBorder()),
                items: _materias.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (value) => setState(() => _materiaSeleccionada = value),
                validator: (value) => value == null ? 'Selecciona una materia' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _estadoSeleccionado,
                decoration: const InputDecoration(labelText: 'Estado físico', border: OutlineInputBorder()),
                items: _opcionesEstado.map((e) => DropdownMenuItem(value: e, child: Text(e.replaceAll('_', ' ').toUpperCase()))).toList(),
                onChanged: (val) => setState(() => _estadoSeleccionado = val),
                validator: (v) => v == null ? 'Selecciona el estado' : null,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _detallesFisicosController,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Detalles de la condición física', border: OutlineInputBorder()),
                validator: (value) {
                  if (_estadoSeleccionado == 'deteriorado' && (value == null || value.trim().isEmpty)) {
                    return 'Por favor, describe el deterioro del libro.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descripcionController,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Descripción general del libro (Opcional)', border: OutlineInputBorder()),
              ),
              
              const SizedBox(height: 24),
              _isLoading
                  ? Center(child: CircularProgressIndicator(color: Colors.red[800]))
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _enviarSolicitud,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[800],
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        child: Text(widget.docId != null ? 'GUARDAR CAMBIOS' : 'ENVIAR A REVISIÓN', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}