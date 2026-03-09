import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MisSolicitudesScreen extends StatelessWidget {
  const MisSolicitudesScreen({super.key});

  // Función para Aceptar o Rechazar una solicitud
  Future<void> _cambiarEstadoSolicitud(String solId, String nuevoEstado, String libroId) async {
    await FirebaseFirestore.instance.collection('solicitudes').doc(solId).update({
      'estadoSolicitud': nuevoEstado,
    });

    // Si se rechaza, el libro vuelve a estar 'DISPONIBLE' en el catálogo
    if (nuevoEstado == 'RECHAZADA') {
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
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis Solicitudes', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.orange[800],
          elevation: 1,
          bottom: TabBar(
            labelColor: Colors.orange[800],
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.orange[800],
            tabs: const [
              Tab(text: 'LO QUE PEDÍ'), 
              Tab(text: 'ME PIDIERON')
            ],
          ),
        ),
        body: userId == null
            ? const Center(child: Text('Inicia sesión para continuar'))
            : TabBarView(
                children: [
                  // 1. Pestaña: Lo que yo pedí (Filtro por solicitanteID con D mayúscula)
                  _solicitudesList(userId, 'solicitanteID', true),
                  // 2. Pestaña: Lo que me pidieron (Filtro por dueñoId con Ñ)
                  _solicitudesList(userId, 'dueñoId', false),
                ],
              ),
      ),
    );
  }

  Widget _solicitudesList(String uid, String campoFiltro, bool soyElQuePide) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('solicitudes')
          .where(campoFiltro, isEqualTo: uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.orange));
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 10),
                Text('No hay solicitudes aquí.', style: TextStyle(color: Colors.grey[500])),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final String solId = docs[index].id;
            final String estado = data['estadoSolicitud'] ?? 'PENDIENTE';
            final String libroId = data['libroId'] ?? '';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.orange,
                      child: Icon(Icons.book, color: Colors.white),
                    ),
                    title: Text(data['tituloLibro'] ?? 'Sin título', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Estado: $estado'),
                  ),
                  
                  // Si YO soy el dueño y la solicitud está PENDIENTE, muestro botones
                  if (!soyElQuePide && estado == 'PENDIENTE')
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _cambiarEstadoSolicitud(solId, 'RECHAZADA', libroId),
                            child: const Text('RECHAZAR', style: TextStyle(color: Colors.red)),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _cambiarEstadoSolicitud(solId, 'ACEPTADA', libroId),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                            child: const Text('ACEPTAR', style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                  
                  // Mensaje amigable si ya fue aceptada
                  if (estado == 'ACEPTADA')
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text('✅ ¡Trato hecho! Pónganse en contacto.', 
                        style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}