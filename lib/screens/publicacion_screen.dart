import 'package:flutter/material.dart';

class PublicacionScreen extends StatelessWidget {
  final String titulo = 'Cálculo de una variable: Trascendentes tempranas';
  final String autor = 'James Stewart';
  final String descripcion = 'Libro en muy buen estado. Tiene algunas notas a lápiz en los primeros capítulos, pero nada que impida la lectura. Ideal para los primeros trimestres.';
  final String estadoLibro = 'Usado - Buen estado';
  
  final List<String> carreras = ['Ing. Sistemas', 'Ing. Civil', 'Ciencias Básicas'];
  final List<String> materias = ['Matemáticas I', 'Cálculo I'];
  
  final List<String> imagenesUrls = [
    'https://via.placeholder.com/600x900.png?text=Portada',
    'https://via.placeholder.com/600x900.png?text=Contraportada'
  ];

  PublicacionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.orange),
        title: const Text('Detalles del Libro', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      
      // EL CEREBRO RESPONSIVO
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Si el ancho es mayor a 800px, mostramos el diseño de PC
          if (constraints.maxWidth > 800) {
            return _buildVistaEscritorio(context);
          } 
          // Si es menor, mostramos el diseño de Móvil
          else {
            return _buildVistaMovil(context);
          }
        },
      ),
    );
  }

  // ==========================================
  // 1. DISEÑO PARA PC / WEB (Pantallas anchas)
  // ==========================================
  Widget _buildVistaEscritorio(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 40),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, // Alinea todo arriba
        children: [
          // Columna Izquierda (Imágenes Grandes)
          Expanded(
            flex: 4, // Toma el 40% del espacio
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(child: _buildImagenLibro(imagenesUrls[0], altura: 450)), // ¡Imágenes más grandes!
                const SizedBox(width: 20),
                Expanded(child: _buildImagenLibro(imagenesUrls[1], altura: 450)),
              ],
            ),
          ),
          
          const SizedBox(width: 60), // Gran espacio separador
          
          // Columna Derecha (Información y Botón)
          Expanded(
            flex: 5, // Toma el 50% del espacio
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSeccionTextos(),
                const SizedBox(height: 40),
                // Botón integrado en el flujo, sin flotar
                _buildBotonPrestamo(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. DISEÑO PARA MÓVIL (Pantallas angostas)
  // ==========================================
  Widget _buildVistaMovil(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // Espacio abajo para el botón flotante
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imágenes apiladas u horizontales pero más pequeñas
              Row(
                children: [
                  Expanded(child: _buildImagenLibro(imagenesUrls[0], altura: 250)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildImagenLibro(imagenesUrls[1], altura: 250)),
                ],
              ),
              const SizedBox(height: 24),
              _buildSeccionTextos(),
            ],
          ),
        ),
        
        // Botón flotante al fondo para móviles (transparente a los lados)
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: SizedBox(
              width: 300,
              height: 55,
              child: _buildBotonPrestamo(context),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // COMPONENTES REUTILIZABLES (Para no repetir código)
  // ==========================================

  // Toda la información escrita del libro
  Widget _buildSeccionTextos() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, height: 1.2), // Título más grande
        ),
        const SizedBox(height: 12),
        Text(
          autor,
          style: TextStyle(fontSize: 20, color: Colors.grey[700], fontStyle: FontStyle.italic),
        ),
        const SizedBox(height: 20),
        
        Row(
          children: [
            const Icon(Icons.info_outline, size: 24, color: Colors.orange),
            const SizedBox(width: 8),
            Text('Estado: $estadoLibro', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 18)),
          ],
        ),
        const Divider(height: 40, thickness: 1),

        const Text('Carreras recomendadas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: carreras.map((c) => _buildChip(c, Colors.blue)).toList(),
        ),
        const SizedBox(height: 24),
        
        const Text('Materias relacionadas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: materias.map((m) => _buildChip(m, Colors.green)).toList(),
        ),
        const Divider(height: 40, thickness: 1),

        const Text('Descripción', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Text(
          descripcion,
          style: const TextStyle(fontSize: 16, height: 1.6),
        ),
      ],
    );
  }

  // El botón de préstamo centralizado
  Widget _buildBotonPrestamo(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Iniciando solicitud de préstamo...')),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange,
        elevation: 6,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 30),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      icon: const Icon(Icons.library_books, color: Colors.white, size: 24),
      label: const Text(
        'Solicitar Préstamo',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    );
  }

  // Creador de imágenes ajustable
  Widget _buildImagenLibro(String url, {required double altura}) {
    return Container(
      height: altura,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 5))
        ],
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover, // Llena el contenedor manteniendo la proporción
        ),
      ),
    );
  }

  Widget _buildChip(String texto, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color[200]!),
      ),
      child: Text(texto, style: TextStyle(color: color[800], fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }
}