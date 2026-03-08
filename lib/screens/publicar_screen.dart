import 'package:flutter/material.dart';

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
    'Deteriorado' // <-- Cambiado según tu instrucción
  ];

  // Simuladores de imágenes
  bool _tienePortada = false;
  bool _tieneContraportada = false;

  void _enviarPublicacion() {
    if (_formKey.currentState!.validate()) {
      if (!_tienePortada || !_tieneContraportada) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, sube la portada y contraportada del libro.'), backgroundColor: Colors.red),
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Libro enviado a revisión!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Limpiar formulario después de enviar
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('Publicar un Libro', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.orange),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 800) {
            // DISEÑO PARA PC / WEB
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40.0),
                  child: Form(
                    key: _formKey,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 4, child: _buildSeccionImagenes()),
                        const SizedBox(width: 40),
                        Expanded(flex: 6, child: _buildSeccionFormulario()),
                      ],
                    ),
                  ),
                ),
              ),
            );
          } else {
            // DISEÑO PARA MÓVIL
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildSeccionImagenes(),
                    const SizedBox(height: 24),
                    _buildSeccionFormulario(),
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }

  // ==========================================
  // SECCIÓN 1: SUBIDA DE IMÁGENES
  // ==========================================
  Widget _buildSeccionImagenes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Fotos del Libro', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Añade exactamente 2 fotos. Asegúrate de que estén bien encuadradas y legibles.', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 16),
        
        // Cajas de imágenes más grandes para servir de previsualización
        Row(
          children: [
            Expanded(
              child: _buildSelectorImagen(
                titulo: 'Portada',
                tieneImagen: _tienePortada,
                onTap: () => setState(() => _tienePortada = !_tienePortada),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildSelectorImagen(
                titulo: 'Contraportada',
                tieneImagen: _tieneContraportada,
                onTap: () => setState(() => _tieneContraportada = !_tieneContraportada),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        
        // AVISO DE MODERACIÓN (Texto actualizado)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info, color: Colors.blue, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Proceso de Revisión', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    SizedBox(height: 4),
                    Text(
                      'Al enviar tu formulario, tu publicación quedará en estado PAUSADO. Un bibliotecario, verificará los datos antes de ponerlo DISPONIBLE en el catálogo público.',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Ahora simula mostrar la imagen real al hacer clic
  Widget _buildSelectorImagen({required String titulo, required bool tieneImagen, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 260, // <-- Altura aumentada para simular un encuadre real
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[400]!,
            width: tieneImagen ? 2 : 1, // Se hace más gruesa al cargar
            style: tieneImagen ? BorderStyle.solid : BorderStyle.solid, // continuo si no hay foto
          ),
          // Si tiene imagen, mostramos una imagen simulada (placeholder)
          image: tieneImagen 
            ? DecorationImage(
                image: NetworkImage('https://via.placeholder.com/400x600.png?text=Previsualizaci%C3%B3n+$titulo'),
                fit: BoxFit.cover,
              )
            : null,
        ),
        // Si NO tiene imagen, mostramos el icono de añadir
        child: tieneImagen ? null : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo, size: 50, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text('Añadir\n$titulo', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SECCIÓN 2: FORMULARIO DE TEXTO
  // ==========================================
  Widget _buildSeccionFormulario() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Detalles del Libro', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          _buildTextField(controlador: _tituloController, etiqueta: 'Título del libro', icono: Icons.book),
          const SizedBox(height: 16),
          
          // Se añadió la instrucción para los autores
          _buildTextField(
            controlador: _autorController, 
            etiqueta: 'Autor(es) separados por comas', 
            icono: Icons.person,
            hint: 'Ej: James Stewart, Lothar Redlin'
          ),
          const SizedBox(height: 16),
          
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: 'Estado Físico',
              prefixIcon: const Icon(Icons.star_border),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            value: _estadoFisicoSeleccionado,
            items: _opcionesEstado.map((estado) => DropdownMenuItem(value: estado, child: Text(estado))).toList(),
            onChanged: (value) => setState(() => _estadoFisicoSeleccionado = value),
            validator: (value) => value == null ? 'Selecciona el estado del libro' : null,
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controlador: _carrerasController, 
            etiqueta: 'Carreras (separadas por comas)', 
            icono: Icons.school,
            hint: 'Ej: Ing. Sistemas, Arquitectura',
          ),
          const SizedBox(height: 16),
          
          _buildTextField(
            controlador: _materiasController, 
            etiqueta: 'Materias (separadas por comas)', 
            icono: Icons.class_,
            hint: 'Ej: Cálculo I, Física',
          ),
          const SizedBox(height: 16),
          
          // La descripción solo es obligatoria si el estado es 'Deteriorado'
          _buildTextField(
            controlador: _descripcionController, 
            etiqueta: 'Descripción adicional', 
            icono: Icons.description,
            maxLines: 4,
            hint: 'Menciona si tiene notas, si le faltan páginas, edición, etc.',
            esObligatorio: _estadoFisicoSeleccionado == 'Deteriorado', // <-- REGLA DE NEGOCIO APLICADA
          ),
          
          const SizedBox(height: 32),
          
          // BOTÓN DE ENVÍO
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              onPressed: _enviarPublicacion,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.send, color: Colors.white),
              label: const Text('Enviar para Revisión', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // Modificamos el widget para que reciba si es obligatorio o no
  Widget _buildTextField({
    required TextEditingController controlador,
    required String etiqueta,
    required IconData icono,
    int maxLines = 1,
    String? hint,
    bool esObligatorio = true, // Por defecto todos son obligatorios
  }) {
    return TextFormField(
      controller: controlador,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: esObligatorio ? '$etiqueta *' : etiqueta, // Añadimos asterisco visual si es obligatorio
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
}
