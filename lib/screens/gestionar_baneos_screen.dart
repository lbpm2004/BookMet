import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GestionarBaneosScreen extends StatefulWidget {
  const GestionarBaneosScreen({super.key});

  @override
  State<GestionarBaneosScreen> createState() => _GestionarBaneosScreenState();
}

class _GestionarBaneosScreenState extends State<GestionarBaneosScreen> {
  // Obtenemos tu ID de Admin para no mostrarte en la lista de "baneables"
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  // Función mágica que cambia el estado del usuario en la base de datos
  Future<void> _toggleBaneo(String userId, bool estadoActual) async {
    try {
      await FirebaseFirestore.instance.collection('usuarios').doc(userId).update({
        'baneado': !estadoActual, // Si estaba baneado, lo desbanea. Si estaba activo, lo banea.
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!estadoActual ? 'Usuario suspendido 🚫' : 'Cuenta reactivada ✅'),
          backgroundColor: !estadoActual ? Colors.red : Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al procesar: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('usuarios').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.red));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No hay usuarios registrados.'));
        }

        // Filtramos para que NO salgas tú misma en la lista (¡Los admins no se banean!)
        var usuarios = snapshot.data!.docs.where((doc) => doc.id != currentUserId).toList();

        return ListView.builder(
          itemCount: usuarios.length,
          itemBuilder: (context, index) {
            var doc = usuarios[index];
            var data = doc.data() as Map<String, dynamic>;
            
            String nombre = data['nombre'] ?? 'Usuario';
            String apellido = data['apellido'] ?? '';
            String email = data['email'] ?? 'Sin correo';
            String rol = data['rol'] ?? 'ESTUDIANTE';
            
            // Si el campo 'baneado' no existe aún, asumimos que es falso (está activo)
            bool estaBaneado = data.containsKey('baneado') ? data['baneado'] : false;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: estaBaneado ? Colors.red.shade200 : Colors.transparent, width: 2),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: estaBaneado ? Colors.red[100] : Colors.grey[200],
                  child: Icon(
                    estaBaneado ? Icons.block : Icons.person,
                    color: estaBaneado ? Colors.red : Colors.grey[600],
                  ),
                ),
                title: Text('$nombre $apellido', style: TextStyle(fontWeight: FontWeight.bold, decoration: estaBaneado ? TextDecoration.lineThrough : null)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(email),
                    Text('Rol: $rol', style: TextStyle(fontSize: 12, color: Colors.orange[800], fontWeight: FontWeight.bold)),
                  ],
                ),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: estaBaneado ? Colors.green : Colors.red[800],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _toggleBaneo(doc.id, estaBaneado),
                  child: Text(estaBaneado ? 'Desbanear' : 'Banear'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}