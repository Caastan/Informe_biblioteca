import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Biblioteca',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CatalogoScreen(),
    );
  }
}

class CatalogoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Catálogo de Libros'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('libros').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar los libros'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          final libros = snapshot.data!.docs;
          return ListView.builder(
            itemCount: libros.length,
            itemBuilder: (context, index) {
              final data = libros[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: data['portada'] != null
                    ? Image.network(data['portada'])
                    : Icon(Icons.book),
                title: Text(data['titulo'] ?? ''),
                subtitle: Text(
                  'Autor: ${data['autor'] ?? ''}\n'
                  'Materia: ${data['materia'] ?? ''}\n'
                  'Estado: ${data['estado'] ?? ''}',
                ),
                // Dentro del ListTile de CatalogoScreen:
onTap: () {
  if ((data['estado'] ?? 'Disponible') == 'Disponible') {
    showDialog(
      context: context,
      builder: (context) {
        String lector = '';
        return AlertDialog(
          title: Text('Realizar Préstamo'),
          content: TextField(
            decoration: InputDecoration(labelText: 'Nombre del Lector'),
            onChanged: (value) {
              lector = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                if (lector.isNotEmpty) {
                  // Crear registro en la colección "prestamos"
                  await FirebaseFirestore.instance.collection('prestamos').add({
                    'lector': lector,
                    'libroId': libros[index].id,
                    'libroTitulo': data['titulo'],
                    'fechaPrestamo': Timestamp.now(),
                    'estado': 'Prestado'
                  });
                  // Actualizar estado del libro a "Prestado"
                  await FirebaseFirestore.instance.collection('libros').doc(libros[index].id).update({
                    'estado': 'Prestado'
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Préstamo realizado'))
                  );
                              }
                            },
                            child: Text('Confirmar'),
                          ),
                        ],
                      );
                    },
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Este libro ya está prestado'))
                  );
                }
              },

              );
            },
          );
        },
      ),
    );
  }
}
