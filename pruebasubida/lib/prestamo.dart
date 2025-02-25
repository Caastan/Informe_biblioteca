import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PrestamoScreen extends StatefulWidget {
  @override
  _PrestamoScreenState createState() => _PrestamoScreenState();
}

class _PrestamoScreenState extends State<PrestamoScreen> {
  final _formKey = GlobalKey<FormState>();
  String lector = '';
  String? libroSeleccionadoId;
  String? libroSeleccionadoTitulo;

  void _confirmarPrestamo() async {
    if (_formKey.currentState!.validate() && libroSeleccionadoId != null) {
      await FirebaseFirestore.instance.collection('prestamos').add({
        'lector': lector,
        'libroId': libroSeleccionadoId,
        'libroTitulo': libroSeleccionadoTitulo,
        'fechaPrestamo': Timestamp.now(),
        'estado': 'Prestado'
      });
      await FirebaseFirestore.instance.collection('libros').doc(libroSeleccionadoId).update({
        'estado': 'Prestado'
      });
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Préstamo Confirmado'),
          content: Text('Lector: $lector\nLibro: $libroSeleccionadoTitulo'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Realizar Préstamo'),
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
              SizedBox(height: 20),
              Text('Seleccione un libro disponible:'),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('libros')
                      .where('estado', isEqualTo: 'Disponible')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return CircularProgressIndicator();
                    final libros = snapshot.data!.docs;
                    return ListView.builder(
                      itemCount: libros.length,
                      itemBuilder: (context, index) {
                        final data = libros[index].data() as Map<String, dynamic>;
                        return ListTile(
                          title: Text(data['titulo'] ?? ''),
                          subtitle: Text(data['autor'] ?? ''),
                          selected: libroSeleccionadoId == libros[index].id,
                          onTap: () {
                            setState(() {
                              libroSeleccionadoId = libros[index].id;
                              libroSeleccionadoTitulo = data['titulo'];
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: _confirmarPrestamo,
                child: Text('Confirmar Préstamo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
