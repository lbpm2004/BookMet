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
  String _filtroFinalizadas = 'Todas'; 

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
              labelColor: Colors.red[800], // Ajustado al color del Admin
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.red[800],
              tabs: const [
                Tab(text: 'En Curso'),
                Tab(text: 'Finalizadas'),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // Ahora solo filtramos por lo que YO (el usuario) he solicitado a la biblioteca
              stream: FirebaseFirestore.instance.collection('solicitudes')
                  .where('solicitanteId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.red));
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No tienes pedidos realizados.'));
                }

                var todasLasSolicitudes = snapshot.data!.docs;

                // 1. En Curso (PENDIENTE)
                var enCurso = todasLasSolicitudes.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return data['estadoSolicitud'] == 'PENDIENTE';
                }).toList();

                // 2. Finalizadas (ACEPTADO o RECHAZADO)
                var finalizadas = todasLasSolicitudes.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String estado = data['estadoSolicitud'] ?? '';
                  
                  bool esFinalizada = estado == 'ACEPTADO' || estado == 'RECHAZADO';
                  if (!esFinalizada) return false;

                  if (_filtroFinalizadas == 'Aceptadas' && estado != 'ACEPTADO') return false;
                  if (_filtroFinalizadas == 'Rechazadas' && estado != 'RECHAZADO') return false;

                  return true;
                }).toList();

                return TabBarView(
                  children: [
                    _construirLista(enCurso),
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildFiltroChip('Todas'),
                              const SizedBox(width: 8),
                              _buildFiltroChip('Aceptadas'),
                              const SizedBox(width: 8),
                              _buildFiltroChip('Rechazadas'),
                            ],
                          ),
                        ),
                        Expanded(child: _construirLista(finalizadas)),
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
      onSelected: (bool selected) {
        if (selected) setState(() => _filtroFinalizadas = label);
      },
      selectedColor: Colors.red[100],
      labelStyle: TextStyle(
        color: isSelected ? Colors.red[800] : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _construirLista(List<QueryDocumentSnapshot> solicitudes) {
    if (solicitudes.isEmpty) {
      return const Center(child: Text('No hay registros aquí.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: solicitudes.length,
      itemBuilder: (context, index) {
        var doc = solicitudes[index];
        var data = doc.data() as Map<String, dynamic>;
        
        return _SolicitudCard(
          libroId: data['libroId'] ?? '',
          tituloLibro: data['tituloLibro'] ?? 'Libro',
          estado: data['estadoSolicitud'] ?? 'PENDIENTE',
        );
      },
    );
  }
}

class _SolicitudCard extends StatefulWidget {
  final String libroId;
  final String tituloLibro;
  final String estado;

  const _SolicitudCard({
    required this.libroId,
    required this.tituloLibro,
    required this.estado,
  });

  @override
  State<_SolicitudCard> createState() => _SolicitudCardState();
}

class _SolicitudCardState extends State<_SolicitudCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    Color colorEstado = widget.estado == 'ACEPTADO' 
        ? Colors.green 
        : (widget.estado == 'RECHAZADO' ? Colors.red : Colors.orange);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedScale(
        scale: _isHovering ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: _isHovering ? 8 : 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () async {
              // Lógica para ir al detalle del libro si se desea consultar
              var snap = await FirebaseFirestore.instance.collection('publicaciones').doc(widget.libroId).get();
              if (snap.exists && mounted) {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => DetalleLibroScreen(libro: snap.data()!, docId: widget.libroId)
                ));
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('ESTADO DEL PEDIDO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorEstado.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(widget.estado, style: TextStyle(color: colorEstado, fontWeight: FontWeight.bold, fontSize: 10)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(widget.tituloLibro, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  
                  // Mensajes informativos según estado centralizado
                  if (widget.estado == 'PENDIENTE')
                    const Row(
                      children: [
                        Icon(Icons.hourglass_empty, size: 16, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Esperando aprobación de la biblioteca...', style: TextStyle(color: Colors.orange, fontSize: 12)),
                      ],
                    ),
                  if (widget.estado == 'ACEPTADO')
                    const Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green),
                        SizedBox(width: 8),
                        Expanded(child: Text('¡Aprobado! Pasa por la biblioteca a retirar tu libro.', style: TextStyle(color: Colors.green, fontSize: 12))),
                      ],
                    ),
                  if (widget.estado == 'RECHAZADO')
                    const Row(
                      children: [
                        Icon(Icons.cancel, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Lo sentimos, tu solicitud no pudo ser procesada.', style: TextStyle(color: Colors.red, fontSize: 12)),
                      ],
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