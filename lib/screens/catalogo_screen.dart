import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'detalle_libro_screen.dart';

class CatalogoScreen extends StatefulWidget {
  const CatalogoScreen({super.key});

  @override
  _CatalogoScreenState createState() => _CatalogoScreenState();
}

class _CatalogoScreenState extends State<CatalogoScreen> {
  String _filtroCarrera = 'Carreras (Todas)';
  String _filtroMateria = 'Materias (Todas)';
  
  String _filtroAlfa = 'Alfabético (-)'; 
  String _filtroTiempo = 'Más Recientes';
  
  String _busqueda = ''; 

  final List<String> _carreras = ['Carreras (Todas)', 'Ingenieria', 'Psicologia', 'Derecho', 'Administracion'];
  final List<String> _materias = ['Materias (Todas)', 'Matemáticas 1', 'Matemáticas 2', 'Matemáticas 5', 'Física'];
  final List<String> _opcionesAlfa = ['Alfabético (-)', 'A-Z', 'Z-A'];
  final List<String> _opcionesTiempo = ['Más Recientes', 'Más Antiguos'];

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
                
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
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
                      const SizedBox(width: 8),
                      _buildFiltro(
                        value: _filtroAlfa,
                        items: _opcionesAlfa,
                        onChanged: (val) {
                          setState(() {
                            _filtroAlfa = val!;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildFiltro(
                        value: _filtroTiempo,
                        items: _opcionesTiempo,
                        onChanged: (val) {
                          setState(() {
                            _filtroTiempo = val!;
                            if (val != 'Más Recientes' || val == 'Más Recientes') {
                               _filtroAlfa = 'Alfabético (-)';
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // GRILLA DE LIBROS
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // --- CAMBIO PRINCIPAL AQUÍ: ACEPTAMOS DISPONIBLES Y RESERVADOS ---
              stream: FirebaseFirestore.instance
                  .collection('publicaciones')
                  .where('estado', whereIn: ['DISPONIBLE', 'RESERVADO'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.orange));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No hay libros en el catálogo en este momento.'));
                }

                // Filtrado por búsqueda, carrera y materia
                var libros = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String titulo = (data['titulo'] ?? '').toString().toLowerCase();
                  String autor = (data['autor'] ?? '').toString().toLowerCase();
                  String carrera = (data['carrera'] ?? '').toString();
                  String materia = (data['materia'] ?? '').toString();

                  bool pasaBusqueda = titulo.contains(_busqueda) || autor.contains(_busqueda);
                  bool pasaCarrera = _filtroCarrera == 'Carreras (Todas)' || carrera == _filtroCarrera;
                  bool pasaMateria = _filtroMateria == 'Materias (Todas)' || materia == _filtroMateria;

                  return pasaBusqueda && pasaCarrera && pasaMateria;
                }).toList();

                // Lógica de Ordenamiento
                libros.sort((a, b) {
                  var dataA = a.data() as Map<String, dynamic>;
                  var dataB = b.data() as Map<String, dynamic>;
                  
                  if (_filtroAlfa != 'Alfabético (-)') {
                    String tituloA = (dataA['titulo'] ?? '').toString().toLowerCase();
                    String tituloB = (dataB['titulo'] ?? '').toString().toLowerCase();
                    if (_filtroAlfa == 'A-Z') return tituloA.compareTo(tituloB);
                    if (_filtroAlfa == 'Z-A') return tituloB.compareTo(tituloA);
                  }

                  Timestamp? fechaA = dataA['fechaPublicacion'] as Timestamp?;
                  Timestamp? fechaB = dataB['fechaPublicacion'] as Timestamp?;

                  if (fechaA == null && fechaB == null) return 0;
                  if (fechaA == null) return 1; 
                  if (fechaB == null) return -1;

                  if (_filtroTiempo == 'Más Antiguos') {
                    return fechaA.compareTo(fechaB);
                  } else { 
                    return fechaB.compareTo(fechaA);
                  }
                });

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 180, 
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.60, 
                  ),
                  itemCount: libros.length,
                  itemBuilder: (context, index) {
                    var libroData = libros[index].data() as Map<String, dynamic>;
                    String idDoc = libros[index].id;

                    return _HoverBookCard(
                      libroData: libroData,
                      onTap: () {
                        // Si está reservado, mostramos un aviso en lugar de abrir el detalle
                        if (libroData['estado'] == 'RESERVADO') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Este libro ya se encuentra reservado por otro usuario.'),
                              backgroundColor: Colors.grey,
                              duration: Duration(seconds: 2),
                            )
                          );
                        } else {
                          // Si está disponible, abrimos la pantalla normal
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DetalleLibroScreen(
                                libro: libroData, 
                                docId: idDoc,
                              ),
                            ),
                          );
                        }
                      },
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(20)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          style: const TextStyle(fontSize: 12, color: Colors.black),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// --- WIDGET PARA ANIMAR Y DETECTAR EL RATÓN (HOVER) ---
class _HoverBookCard extends StatefulWidget {
  final Map<String, dynamic> libroData;
  final VoidCallback onTap;

  const _HoverBookCard({required this.libroData, required this.onTap});

  @override
  State<_HoverBookCard> createState() => _HoverBookCardState();
}

class _HoverBookCardState extends State<_HoverBookCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    bool esReservado = widget.libroData['estado'] == 'RESERVADO';

    return MouseRegion(
      // Si está reservado, quitamos la manito de click para indicar que no está disponible
      cursor: esReservado ? SystemMouseCursors.basic : SystemMouseCursors.click, 
      onEnter: (_) => setState(() => _isHovering = !esReservado), // No hace hover si está reservado
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovering ? 1.05 : 1.0, 
          duration: const Duration(milliseconds: 200), 
          curve: Curves.easeInOut,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _isHovering ? Colors.black26 : Colors.black12, 
                  blurRadius: _isHovering ? 12 : 4,
                  offset: Offset(0, _isHovering ? 4 : 2),
                )
              ],
            ),
            child: Stack( // Usamos Stack para poder poner el aviso de "RESERVADO" encima
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        // Si está reservado, le bajamos la opacidad a la imagen
                        child: Opacity(
                          opacity: esReservado ? 0.5 : 1.0,
                          child: Image.network(
                            widget.libroData['fotoUrl'] ?? 'https://via.placeholder.com/150',
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(Icons.book, size: 50, color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        widget.libroData['titulo'] ?? 'Sin título',
                        style: TextStyle(
                          fontSize: 12, 
                          fontWeight: FontWeight.bold,
                          color: esReservado ? Colors.grey : Colors.black // Texto gris si está reservado
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.libroData['autor'] != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0).copyWith(bottom: 8.0),
                        child: Text(
                          widget.libroData['autor'],
                          style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                
                // --- ETIQUETA VISUAL DE RESERVADO ---
                if (esReservado)
                  Positioned(
                    top: 10,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'RESERVADO',
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}