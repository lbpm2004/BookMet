import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detalle_libro_screen.dart'; // Asegúrate de que este archivo se llame así en tu carpeta

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  _CatalogoScreenState createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  String _filtroCarrera = 'Todas';
  String _filtroMateria = 'Todas';
  String _busqueda = ''; 

  final List<String> _carreras = ['Todas', 'Ingenieria', 'Psicologia', 'Derecho', 'Administracion'];
  final List<String> _materias = ['Todas', 'Matemáticas 1', 'Matemáticas 2', 'Matemáticas 5', 'Física'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // BARRA DE BÚSQUEDA Y FILTROS
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  onChanged: (value) => setState(() => _busqueda = value.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Buscar libro o autor...',
                    prefixIcon: const Icon(Icons.search, color: Colors.orange),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFiltro(
                      value: _filtroCarrera,
                      items: _carreras,
                      onChanged: (val) => setState(() => _filtroCarrera = val!),
                    ),
                    const SizedBox(width: 8),
                    _buildFiltro(
                      value: _filtroMateria,
                      items: _materias,
                      onChanged: (val) => setState(() => _filtroMateria = val!),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // GRILLA DE LIBROS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('publicaciones')
                  .where('estado', isEqualTo: 'DISPONIBLE')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.orange));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay libros disponibles.'));
                }

                var libros = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String titulo = (data['titulo'] ?? '').toString().toLowerCase();
                  String autor = (data['autor'] ?? '').toString().toLowerCase();
                  String carrera = (data['carrera'] ?? '').toString();
                  String materia = (data['materia'] ?? '').toString();

                  bool pasaBusqueda = titulo.contains(_busqueda) || autor.contains(_busqueda);
                  bool pasaCarrera = _filtroCarrera == 'Todas' || carrera == _filtroCarrera;
                  bool pasaMateria = _filtroMateria == 'Todas' || materia == _filtroMateria;

                  return pasaBusqueda && pasaCarrera && pasaMateria;
                }).toList();

                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.55,
                  ),
                  itemCount: libros.length,
                  itemBuilder: (context, index) {
                    var libroData = libros[index].data() as Map<String, dynamic>;
                    String idDoc = libros[index].id;

                    return GestureDetector(
                      onTap: () {
                        // LA CONEXIÓN CRÍTICA ESTÁ AQUÍ
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => DetalleLibroScreen(
                              libro: libroData, 
                              docId: idDoc,
                            ),
                          ),
                        );
                      },
                      child: _buildCardLibro(libroData),
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

  Widget _buildFiltro({required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(20)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            style: const TextStyle(fontSize: 12, color: Colors.black),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildCardLibro(Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: Image.network(
                data['fotoUrl'] ?? 'https://via.placeholder.com/150',
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.book),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              data['titulo'] ?? 'Sin título',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}