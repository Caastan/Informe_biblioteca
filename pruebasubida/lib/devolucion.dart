import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DevolucionScreen extends StatefulWidget {
  @override
  _DevolucionScreenState createState() => _DevolucionScreenState();
}

class _DevolucionScreenState extends State<DevolucionScreen> {
  final _formKey = GlobalKey<FormState>();
  String lector = '';
  String libroDevolver = '';

  void _confirmarDevolucion() async {
    if (_formKey.currentState!.validate()) {
      // Buscar préstamo activo que coincida con el lector y libro
      QuerySnapshot prestamoSnapshot = await FirebaseFirestore.instance
          .collection('prestamos')
          .where('lector', isEqualTo: lector)
          .where('libroTitulo', isEqualTo: libroDevolver)
          .where('estado', isEqualTo: 'Prestado')
          .get();
      if (prestamoSnapshot.docs.isNotEmpty) {
        var prestamoDoc = prestamoSnapshot.docs.first;
        await FirebaseFirestore.instance.collection('prestamos').doc(prestamoDoc.id).update({
          'estado': 'Devuelto',
          'fechaDevolucion': Timestamp.now()
        });
        // Actualizar el estado del libro a Disponible
        await FirebaseFirestore.instance.collection('libros').doc(prestamoDoc['libroId']).update({
          'estado': 'Disponible'
        });
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Devolución Confirmada'),
            content: Text('Préstamo actualizado correctamente.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Error'),
            content: Text('No se encontró un préstamo activo con esos datos.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Realizar Devolución'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Nombre del Lector'),
                onChanged: (value) {
                  setState(() {
                    lector = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre del lector';
                  }
                  return null;
                },
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Libro a Devolver'),
                onChanged: (value) {
                  setState(() {
                    libroDevolver = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el nombre del libro';
                  }
                  return null;
                },
              ),
              ElevatedButton(
                onPressed: _confirmarDevolucion,
                child: Text('Confirmar Devolución'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
