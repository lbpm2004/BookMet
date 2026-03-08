import 'package:flutter/material.dart';

class PublicacionScreen extends StatelessWidget {
  // En el futuro, estos datos llegarán desde la pantalla anterior (el Catálogo)
  // Por ahora los simulamos basándonos en tus nuevas reglas
  final String titulo = 'Cálculo de una variable: Trascendentes tempranas';
  final String autor = 'James Stewart';
  final String descripcion = 'Libro en muy buen estado. Tiene algunas notas a lápiz en los primeros capítulos, pero nada que impida la lectura. Ideal para los primeros trimestres.';
  final String estadoLibro = 'Usado - Buen estado';
  
  // ¡Aplicando tu regla! Carreras y Materias como Listas
  final List<String> carreras = ['Ing. Sistemas', 'Ing. Civil', 'Ciencias Básicas'];
  final List<String> materias = ['Matemáticas I', 'Cálculo I'];
  
  // Simulando las 2 imágenes máximo (Portada y Contraportada)
  final List<String> imagenesUrls = [
    'https://via.placeholder.com/400x600.png?text=Portada',
    'https://via.placeholder.com/400x600.png?text=Contraportada'
  ];

  PublicacionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.orange),
        title: const Text('Detalles del Libro', style: TextStyle(color: Colors.black87)),
      ),
      
      // El cuerpo principal
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100), // Espacio para que el botón flotante no tape texto
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Carrusel de Imágenes (Máximo 2)
            SizedBox(
              height: 300,
              child: PageView.builder(
                itemCount: imagenesUrls.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: NetworkImage(imagenesUrls[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                    // Si la imagen falla, mostramos un ícono de libro
                    child: const Center(child: Icon(Icons.menu_book, size: 80, color: Colors.grey)),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            // Indicador de imagen (1/2, 2/2)
            Center(
              child: Text(
                'Desliza para ver la contraportada',
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Información Principal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.2),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    autor,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700], fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),
                  
                  // Estado del libro
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 20, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text('Estado: $estadoLibro', style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                  const Divider(height: 30),

                  // 3. Listas de Etiquetas (Carreras y Materias)
                  const Text('Carreras recomendadas:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: carreras.map((c) => _buildChip(c, Colors.blue)).toList(),
                  ),
                  const SizedBox(height: 16),
                  
                  const Text('Materias relacionadas:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: materias.map((m) => _buildChip(m, Colors.green)).toList(),
                  ),
                  const Divider(height: 30),

                  // 4. Descripción
                  const Text('Descripción', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(
                    descripcion,
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // 5. BOTÓN FLOTANTE ESTÁTICO (Siempre visible abajo)
      bottomSheet: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: ElevatedButton(
          onPressed: () {
            // Aquí irá la lógica para iniciar el intercambio
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Iniciando solicitud de intercambio...')),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Solicitar Intercambio',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
          ),
        ),
      ),
    );
  }

  // Widget auxiliar para crear las "píldoras" visuales de las listas
  Widget _buildChip(String texto, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color[200]!),
      ),
      child: Text(
        texto,
        style: TextStyle(color: color[800], fontSize: 13, fontWeight: FontWeight.w500),
      ),
    );
  }
}