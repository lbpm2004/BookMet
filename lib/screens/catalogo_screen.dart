import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'publicacion_screen.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({Key? key}) : super(key: key);

  @override
  _CatalogoScreenState createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  // Variables de los filtros (por ahora visuales, luego les daremos lógica)
  String _filtroCarrera = 'Carrera (Todas)';
  String _filtroMateria = 'Materia (Todas)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // --- BARRA DE FILTROS SUPERIOR ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {}, // Futura lógica del CU-16
                    icon: const Icon(Icons.filter_list, size: 18, color: Colors.orange),
                    label: Text(_filtroCarrera, style: TextStyle(fontSize: 12, color: Colors.grey[800]), maxLines: 1, overflow: TextOverflow.ellipsis),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {}, // Futura lógica del CU-16
                    icon: const Icon(Icons.book, size: 18, color: Colors.orange),
                    label: Text(_filtroMateria, style: TextStyle(fontSize: 12, color: Colors.grey[800]), maxLines: 1, overflow: TextOverflow.ellipsis),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // --- FEED DE LIBROS DESDE FIREBASE ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Buscamos todas las publicaciones ordenadas por fecha de creación
              stream: FirebaseFirestore.instance
                  .collection('publicaciones')
                  .orderBy('fechaCreacion', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                // 1. Mientras carga
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.orange));
                }
                
                // 2. Si no hay libros en la base de datos
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.library_books, size: 80, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text('Aún no hay libros publicados en la comunidad.', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                      ],
                    ),
                  );
                }

                // 3. Extraemos la lista de libros
                final publicaciones = snapshot.data!.docs;

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,          // 2 columnas
                    crossAxisSpacing: 12,       // Espacio horizontal
                    mainAxisSpacing: 12,        // Espacio vertical
                    childAspectRatio: 0.7,      // Proporción (más alto que ancho)
                  ),
                  itemCount: publicaciones.length,
                  itemBuilder: (context, index) {
                    var libro = publicaciones[index].data() as Map<String, dynamic>;
                    
                    String titulo = libro['titulo'] ?? 'Sin título';
                    String materia = libro['materias'] ?? 'Sin materia';
                    String estado = libro['estado'] ?? 'PAUSADO';

                   return GestureDetector(
                      onTap: () {
                        // Temporalmente mostraremos un mensaje en lugar de cambiar de pantalla
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pronto programaremos los detalles del libro 🚀')),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 3))
                          ]
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // "Foto" del libro
                            Expanded(
                              flex: 3,
                              child: Container(
                                width: double.infinity,
                                decoration: const BoxDecoration(
                                  color: Colors.orange, // Fondo naranja temporal
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                                ),
                                child: const Icon(Icons.menu_book, size: 50, color: Colors.white),
                              ),
                            ),
                            // Datos del libro
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      titulo, 
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), 
                                      maxLines: 2, 
                                      overflow: TextOverflow.ellipsis
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      materia, 
                                      style: TextStyle(color: Colors.grey[600], fontSize: 11), 
                                      maxLines: 1, 
                                      overflow: TextOverflow.ellipsis
                                    ),
                                    const Spacer(),
                                    Text(
                                      estado, 
                                      style: TextStyle(
                                        color: estado == 'DISPONIBLE' ? Colors.green : Colors.amber[800], 
                                        fontSize: 10, 
                                        fontWeight: FontWeight.bold
                                      )
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}