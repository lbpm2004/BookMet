import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/fondo_con_blur.dart';

class DonacionScreen extends StatefulWidget {
  const DonacionScreen({super.key});

  @override
  State<DonacionScreen> createState() => _DonacionScreenState();
}

class _DonacionScreenState extends State<DonacionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _referenciaController = TextEditingController();
  final _montoController = TextEditingController();
  final _notaController = TextEditingController();
  bool _isSaving = false;

  final String banco = "Banco Mercantil";
  final String cuenta = "0105-XXXX-XX-XXXXXXXXXX";
  final String titular = "Universidad Metropolitana";
  final String rif = "J-12345678-9";

  Future<void> _registrarDonacion() async {
    if (_formKey.currentState!.validate()) {
      setState(() =>_isSaving = true);
      try {
        final user = FirebaseAuth.instance.currentUser;

        //cumpliendo la seguridad de datos via firebase
        await FirebaseFirestore.instance.collection('contribuciones').add({
          'usuarioId' : user?.uid,
          'email': user?.email,
          'referencia': _referenciaController.text.trim(),
          'monto': double.parse(_montoController.text.trim()),
          'comentario': _notaController.text.trim(),
          'fecha': FieldValue.serverTimestamp(),
          'estado': 'Pendiente',
          'tipo': 'Transferencia bancaria',
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡Gracias por tu apoyo! Registro exitoso.'))
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al registrar: $e')));
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Donar a biblioteca', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: const Color(0xFF003087),
      iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FondoConBlur(child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInfoCard(),
            const SizedBox(height: 20),
            _buildDonationForm(),
            const SizedBox(height: 20)
          ],
        ),
      ))
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.account_balance, color: Colors.orange, size:40),
            const SizedBox(height: 10),
            const Text('Datos de transferencia', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            _buildBankDetail('Banco: ', banco),
            _buildBankDetail('Titular:', titular),
            _buildBankDetail('RIF:', rif),
            _buildBankDetail('Cuenta:', cuenta)
          ],
        ))
        );
  }

  Widget _buildBankDetail(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w500))]
      )
    );

  Widget _buildDonationForm() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20)
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            const Text('Registra tu Pago', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
            const SizedBox(height: 20),
            TextFormField(
              controller: _referenciaController,
              decoration: const InputDecoration(labelText: 'Número de Referencia', prefixIcon: Icon(Icons.numbers)),
              validator: (v) => v!.isEmpty ? 'Ingresa la referencia': null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _montoController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Monto Donado', prefixIcon: Icon(Icons.attach_money)),
              validator: (v) => v!.isEmpty ? 'Ingresa el monto' : null
            ),
            const SizedBox(height: 30),
            _isSaving
              ? const CircularProgressIndicator(color: Colors.orange)
              : ElevatedButton(onPressed: _registrarDonacion,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[800],
                padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
               child: const Text('GUARDAR REGISTRO', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),))
          ]
        )),
    );
  }
}