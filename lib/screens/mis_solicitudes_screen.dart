import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'detalle_libro_screen.dart';

class MisSolicitudesScreen extends StatefulWidget {
  const MisSolicitudesScreen({super.key});

  @override
  State<MisSolicitudesScreen> createState() => _MisSolicitudesScreenState();
}

class _MisSolicitudesScreenState extends State<MisSolicitudesScreen> {
  // Opciones: 'Todas', 'Devueltas', 'Canceladas', 'Rechazadas'
  String _filtroFinalizadas = 'Todas'; 

  // Función para que el usuario pueda cancelar su propia solicitud
  Future<void> _cambiarEstadoSolicitud(String solId, String nuevoEstado, String libroId) async {
    await FirebaseFirestore.instance.collection('solicitudes').doc(solId).update({
      'estadoSolicitud': nuevoEstado,
    });

    // Si se cancela o rechaza, el libro vuelve a estar 'DISPONIBLE' en el catálogo
    if (nuevoEstado == 'CANCELADA' || nuevoEstado == 'RECHAZADA') {
      await FirebaseFirestore.instance.collection('publicaciones').doc(libroId).update({
        'estado': 'DISPONIBLE',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: Colors.orange[800],
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.orange[800],
              tabs: const [
                Tab(text: 'En Curso'),
                Tab(text: 'Finalizadas'),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Ahora solo buscamos las solicitudes donde el usuario es el que pide el libro
              stream: FirebaseFirestore.instance.collection('solicitudes')
                  .where('solicitanteId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(
                        'Falta el Índice en Firebase.\n\nRevisa la consola (Terminal). Firebase generó un enlace azul. Haz clic en él.\n\nError técnico: ${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.orange));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No tienes solicitudes registradas.'));
                }

                var todasLasSolicitudes = snapshot.data!.docs;

                // 1. Filtro para "En Curso" (Pendientes de revisión o Aceptadas/En préstamo)
                var enCurso = todasLasSolicitudes.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String estado = data['estadoSolicitud'] ?? '';
                  return estado == 'PENDIENTE' || estado == 'ACEPTADA';
                }).toList();

                // 2. Filtro dinámico para "Finalizadas"
                  var finalizadas = todasLasSolicitudes.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                    String estado = data['estadoSolicitud'] ?? '';
  
                    bool esFinalizada = estado == 'DEVUELTA' || estado == 'CANCELADA' || estado == 'RECHAZADA';
                    if (!esFinalizada) return false;

                    if (_filtroFinalizadas == 'Devueltas' && estado != 'DEVUELTA') return false;
                    if (_filtroFinalizadas == 'Canceladas' && estado != 'CANCELADA') return false;
                    if (_filtroFinalizadas == 'Rechazadas' && estado != 'RECHAZADA') return false;

                    return true;
                  }).toList();

                return TabBarView(
                  children: [
                    _construirLista(enCurso, userId!),
                    
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildFiltroChip('Todas'),
                                const SizedBox(width: 8),
                                _buildFiltroChip('Devueltas'),
                                const SizedBox(width: 8),
                                _buildFiltroChip('Canceladas'),
                                const SizedBox(width: 8),
                                _buildFiltroChip('Rechazadas'),
                              ],
                            ),
                          ),
                        ),
                        Expanded(child: _construirLista(finalizadas, userId)),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltroChip(String label) {
    bool isSelected = _filtroFinalizadas == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      showCheckmark: false,
      onSelected: (bool selected) {
        if (selected) {
          setState(() {
            _filtroFinalizadas = label;
          });
        }
      },
      selectedColor: Colors.orange[100],
      backgroundColor: Colors.grey[200],
      labelStyle: TextStyle(
        color: isSelected ? Colors.orange[800] : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(color: isSelected ? Colors.orange : Colors.transparent),
    );
  }

  Widget _construirLista(List<QueryDocumentSnapshot> solicitudes, String userId) {
    if (solicitudes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Text('No hay solicitudes en esta categoría.', style: TextStyle(color: Colors.grey[600])),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: solicitudes.length,
      itemBuilder: (context, index) {
        var doc = solicitudes[index];
        var data = doc.data() as Map<String, dynamic>;
        String solId = doc.id;
        String libroId = data['libroId'] ?? '';
        String tituloLibro = data['tituloLibro'] ?? 'Libro';
        String estado = data['estadoSolicitud'] ?? 'PENDIENTE';

        return _HoverSolicitudCard(
          solId: solId,
          libroId: libroId,
          tituloLibro: tituloLibro,
          estado: estado,
          data: data,
          onCancelar: () => _cambiarEstadoSolicitud(solId, 'CANCELADA', libroId),
        );
      },
    );
  }
}

class _HoverSolicitudCard extends StatefulWidget {
  final String solId;
  final String libroId;
  final String tituloLibro;
  final String estado;
  final Map<String, dynamic> data;
  final VoidCallback onCancelar;

  const _HoverSolicitudCard({
    required this.solId,
    required this.libroId,
    required this.tituloLibro,
    required this.estado,
    required this.data,
    required this.onCancelar,
  });

  @override
  State<_HoverSolicitudCard> createState() => _HoverSolicitudCardState();
}

class _HoverSolicitudCardState extends State<_HoverSolicitudCard> {
  bool _isHovering = false;

  Widget _buildBadgeEstado(String estado) {
    Color color;
    switch (estado) {
      case 'ACEPTADA': color = Colors.green; break;
      case 'RECHAZADA': color = Colors.red; break;
      case 'CANCELADA': color = Colors.grey; break;
      case 'DEVUELTA': color = Colors.blue; break;
      default: color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        estado,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click, 
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: () async {
          showDialog(
            context: context, 
            barrierDismissible: false,
            builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.orange))
          );

          try {
            var libroSnapshot = await FirebaseFirestore.instance.collection('publicaciones').doc(widget.libroId).get();
            
            if (!context.mounted) return;
            Navigator.pop(context); 

            if (libroSnapshot.exists) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetalleLibroScreen(
                    libro: libroSnapshot.data() as Map<String, dynamic>,
                    docId: widget.libroId,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('El libro original ya fue eliminado de la base de datos.'), backgroundColor: Colors.grey)
              );
            }
          } catch (e) {
            if (!context.mounted) return;
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error de conexión al cargar el libro.'), backgroundColor: Colors.red)
            );
          }
        },
        child: AnimatedScale(
          scale: _isHovering ? 1.02 : 1.0, 
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _isHovering ? Colors.black26 : Colors.black12, 
                  blurRadius: _isHovering ? 10 : 4,
                  offset: Offset(0, _isHovering ? 4 : 2),
                )
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Row(
                    children: [
                      const Icon(Icons.local_library, color: Colors.blue),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Reserva de biblioteca:',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12),
                        ),
                      ),
                      _buildBadgeEstado(widget.estado),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(widget.tituloLibro, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  if (widget.estado == 'PENDIENTE')
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: widget.onCancelar,
                          icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
                          label: const Text('CANCELAR RESERVA', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),

                  if (widget.estado == 'ACEPTADA')
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('✅ Aprobado. Pasa a retirar tu libro por la biblioteca.', 
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  
                  if (widget.estado == 'RECHAZADA')
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('❌ La biblioteca no pudo procesar esta solicitud.', 
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),

                  if (widget.estado == 'PENDIENTE')
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('⏳ En revisión por el administrador...', 
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),

                  if (widget.estado == 'DEVUELTA')
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('📚 Devuelto correctamente. ¡Gracias por leer!', 
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),

                  if (widget.estado == 'CANCELADA')
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('🚫 Cancelaste esta reserva.', 
                        style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}