import 'package:flutter/material.dart';

class MisSolicitudesScreen extends StatefulWidget {
  const MisSolicitudesScreen({Key? key}) : super(key: key);

  @override
  _MisSolicitudesScreenState createState() => _MisSolicitudesScreenState();
}

class _MisSolicitudesScreenState extends State<MisSolicitudesScreen> {
  // --- DATOS SIMULADOS PARA DISEÑO ---
  final List<Map<String, dynamic>> _solicitudesEnviadas = [
    {
      'titulo': 'Cálculo de una variable',
      'autor': 'James Stewart',
      'fecha': '08 Mar 2026',
      'estado': 'Pendiente',
      'imagen': 'https://via.placeholder.com/150/003087/FFFFFF?text=Calculo',
    },
    {
      'titulo': 'Física Universitaria Vol. 1',
      'autor': 'Sears, Zemansky',
      'fecha': '01 Mar 2026',
      'estado': 'Aprobada',
      'imagen': 'https://via.placeholder.com/150/FF8200/FFFFFF?text=Fisica',
    },
    {
      'titulo': 'Introducción a la Programación',
      'autor': 'Luis Joyanes',
      'fecha': '15 Feb 2026',
      'estado': 'Rechazada',
      'imagen': 'https://via.placeholder.com/150/555555/FFFFFF?text=Prog',
    }
  ];

  final List<Map<String, dynamic>> _solicitudesRecibidas = [
    {
      'titulo': 'Química Orgánica',
      'solicitante': 'María Pérez (Ing. Química)',
      'fecha': '07 Mar 2026',
      'estado': 'Pendiente',
      'imagen': 'https://via.placeholder.com/150/28A745/FFFFFF?text=Quimica',
    }
  ];

  @override
  Widget build(BuildContext context) {
    // Usamos DefaultTabController para manejar las pestañas automáticamente
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          automaticallyImplyLeading: false, // Bloqueamos la flecha de atrás
          backgroundColor: Colors.white,
          elevation: 1,
          title: const Text('Mis Solicitudes', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
          centerTitle: true,
          bottom: const TabBar(
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.orange,
            indicatorWeight: 3,
            tabs: [
              Tab(text: 'Enviadas', icon: Icon(Icons.outbox)),
              Tab(text: 'Recibidas', icon: Icon(Icons.move_to_inbox)),
            ],
          ),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800), // Diseño responsivo para PC
            child: TabBarView(
              children: [
                _buildListaSolicitudes(_solicitudesEnviadas, esEnviada: true),
                _buildListaSolicitudes(_solicitudesRecibidas, esEnviada: false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Constructor de la lista (sirve para ambas pestañas)
  Widget _buildListaSolicitudes(List<Map<String, dynamic>> solicitudes, {required bool esEnviada}) {
    if (solicitudes.isEmpty) {
      return const Center(
        child: Text('No hay solicitudes aquí por ahora.', style: TextStyle(color: Colors.grey, fontSize: 16)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: solicitudes.length,
      itemBuilder: (context, index) {
        final item = solicitudes[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Imagen del libro
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item['imagen'],
                    width: 70,
                    height: 100,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Información del libro
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['titulo'],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        esEnviada ? 'Autor: ${item['autor']}' : 'Solicita: ${item['solicitante']}',
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Fecha: ${item['fecha']}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      
                      // Fila inferior: Estado y Botón de acción (si aplica)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildBadgeEstado(item['estado']),
                          
                          // Si es una solicitud recibida y está pendiente, mostramos botones de acción
                          if (!esEnviada && item['estado'] == 'Pendiente')
                            TextButton(
                              onPressed: () {
                                // Lógica futura para aprobar/rechazar
                              },
                              child: const Text('Gestionar', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            )
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget para la etiqueta de color según el estado
  Widget _buildBadgeEstado(String estado) {
    Color bgColor;
    Color textColor;

    switch (estado) {
      case 'Aprobada':
        bgColor = Colors.green[100]!;
        textColor = Colors.green[800]!;
        break;
      case 'Rechazada':
        bgColor = Colors.red[100]!;
        textColor = Colors.red[800]!;
        break;
      case 'Pendiente':
      default:
        bgColor = Colors.orange[100]!;
        textColor = Colors.orange[800]!;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        estado,
        style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}