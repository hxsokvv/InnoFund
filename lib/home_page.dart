import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:uuid/uuid.dart';
import 'profile_page.dart';
import 'project_grid_page.dart';
import 'create_project_page.dart';
import 'notifications_page.dart';
import 'users_list_page.dart';
import 'wallet_page.dart';
import 'package:flutter_paypal/flutter_paypal.dart';
import 'comments_page.dart';

// Importa la nueva página de detalles del proyecto
import 'post_detail_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  int _selectedIndex = 0;
  final TextEditingController _descriptionController = TextEditingController();
  List<File> _images = [];
  final ImagePicker _picker = ImagePicker();
  String? _userType;
  User? _loggedUser;

  // Controla el estado expandido de cada publicación
  final Map<String, bool> _isExpandedMap = {};

  @override
  void initState() {
    super.initState();
    _getUserType();
    _loggedUser = FirebaseAuth.instance.currentUser;
  }

  Future<void> _getUserType() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted) {
        setState(() {
          _userType = (userDoc.data() as Map<String, dynamic>)['userType'];
        });
      }
    }
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage(imageQuality: 85);
    if (pickedFiles.length <= 4) {
      if (mounted) {
        setState(() {
          _images =
              pickedFiles.map((pickedFile) => File(pickedFile.path)).toList();
        });
      }
    } else if (pickedFiles.length > 4) {
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Puedes subir hasta 4 imágenes'),
          ),
        );
      }
    }
  }

  Future<void> _uploadPost() async {
    if (_descriptionController.text.isNotEmpty && _images.isNotEmpty) {
      try {
        List<String> imageUrls = [];
        for (var image in _images) {
          String imageId = const Uuid().v4();
          Reference storageRef =
              FirebaseStorage.instance.ref().child("posts/$imageId");
          UploadTask uploadTask = storageRef.putFile(image);
          TaskSnapshot storageSnapshot = await uploadTask;
          String downloadUrl = await storageSnapshot.ref.getDownloadURL();
          imageUrls.add(downloadUrl);
        }

        await FirebaseFirestore.instance.collection('posts').add({
          'description': _descriptionController.text,
          'imageUrls': imageUrls,
          'timestamp': Timestamp.now(),
          'userId': FirebaseAuth.instance.currentUser!.uid,
          'likes': [],
        });

        if (mounted) {
          setState(() {
            _descriptionController.clear();
            _images = [];
          });
        }

        Navigator.of(context).pop();
      } catch (e) {
        if (mounted) {
          print('Error al subir la publicación: $e');
        }
      }
    }
  }

  Future<void> _addComment(String projectId, String comment) async {
    if (comment.isNotEmpty) {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // Agregar el comentario
      await FirebaseFirestore.instance.collection('comments').add({
        'postId': projectId,
        'comment': comment,
        'timestamp': Timestamp.now(),
        'userId': userId,
      });

      // Obtener el autor de la publicación
      DocumentSnapshot projectSnapshot = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .get();
      if (projectSnapshot.exists) {
        Map<String, dynamic> projectData =
            projectSnapshot.data() as Map<String, dynamic>;
        String ownerId = projectData['userId'];

        // Crear una notificación si el comentarista no es el autor de la publicación
        if (ownerId != userId) {
          await FirebaseFirestore.instance.collection('notifications').add({
            'recipientId': ownerId,
            'senderId': userId,
            'type': 'comment',
            'postId': projectId,
            'timestamp': Timestamp.now(),
            'isRead': false,
          });
        }
      }
    }
  }

  // Método para editar un comentario
  void _editComment(
      BuildContext context, String commentId, String currentText) {
    TextEditingController editController =
        TextEditingController(text: currentText);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Editar Comentario'),
          content: TextField(
            controller: editController,
            decoration: const InputDecoration(
              labelText: 'Editar comentario',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                String updatedText = editController.text.trim();
                if (updatedText.isNotEmpty) {
                  // Actualizar el comentario en Firestore
                  await FirebaseFirestore.instance
                      .collection('comments')
                      .doc(commentId)
                      .update({'comment': updatedText});

                  Navigator.of(context).pop(); // Cerrar el diálogo
                } else {
                  // Mostrar mensaje de error si el comentario está vacío
                  _scaffoldMessengerKey.currentState?.showSnackBar(
                    const SnackBar(
                        content: Text('El comentario no puede estar vacío.')),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  // Método para eliminar un comentario
  void _deleteComment(BuildContext context, String commentId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar Comentario'),
          content: const Text(
              '¿Estás seguro de que deseas eliminar este comentario?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                // Eliminar el comentario de Firestore
                await FirebaseFirestore.instance
                    .collection('comments')
                    .doc(commentId)
                    .delete();

                Navigator.of(context).pop(); // Cerrar el diálogo
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  String _timeAgo(Timestamp timestamp) {
    DateTime postTime = timestamp.toDate();
    Duration difference = DateTime.now().difference(postTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} días';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} horas';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutos';
    } else {
      return 'Justo ahora';
    }
  }

  Future<void> _toggleLike(String projectId) async {
    final userId = _loggedUser!.uid;
    DocumentReference projectRef =
        FirebaseFirestore.instance.collection('projects').doc(projectId);

    DocumentSnapshot projectSnapshot = await projectRef.get();
    if (projectSnapshot.exists) {
      Map<String, dynamic> projectData =
          projectSnapshot.data() as Map<String, dynamic>;
      List<dynamic> likes = projectData['likes'] ?? [];
      String ownerId = projectData['userId']; // ID del autor de la publicación

      if (likes.contains(userId)) {
        likes.remove(userId);
      } else {
        likes.add(userId);

        // Crear una notificación si el usuario actual no es el autor de la publicación
        if (ownerId != userId) {
          await FirebaseFirestore.instance.collection('notifications').add({
            'recipientId': ownerId,
            'senderId': userId,
            'type': 'like',
            'postId': projectId,
            'timestamp': Timestamp.now(),
            'isRead': false,
          });
        }
      }

      await projectRef.update({'likes': likes});
    }
  }

  // Función para formatear números grandes
  String formatNumber(double number) {
    if (number >= 1e9) {
      return '\$${(number / 1e9).toStringAsFixed(1)}B';
    } else if (number >= 1e6) {
      return '\$${(number / 1e6).toStringAsFixed(1)}M';
    } else if (number >= 1e3) {
      return '\$${(number / 1e3).toStringAsFixed(1)}K';
    } else {
      return '\$${number.toStringAsFixed(0)}';
    }
  }

  Future<void> _donate(String projectId, double amount) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final String donorId = FirebaseAuth.instance.currentUser!.uid;

    await firestore.runTransaction((transaction) async {
      DocumentReference projectRef =
          firestore.collection('projects').doc(projectId);
      DocumentReference entrepreneurRef;

      // Leer el documento del proyecto
      DocumentSnapshot projectSnapshot = await transaction.get(projectRef);

      if (projectSnapshot.exists) {
        Map<String, dynamic> projectData =
            projectSnapshot.data() as Map<String, dynamic>;
        double currentAmount = projectData.containsKey('currentAmount') &&
                projectData['currentAmount'] != null
            ? double.tryParse(projectData['currentAmount'].toString()) ?? 0.0
            : 0.0;
        double updatedAmount = currentAmount + amount;

        String entrepreneurId = projectData['userId'];
        entrepreneurRef = firestore.collection('users').doc(entrepreneurId);

        // Leer el documento del emprendedor
        DocumentSnapshot entrepreneurSnapshot =
            await transaction.get(entrepreneurRef);

        Map<String, dynamic> entrepreneurData =
            entrepreneurSnapshot.data() as Map<String, dynamic>;
        double currentWalletBalance = entrepreneurData
                    .containsKey('walletBalance') &&
                entrepreneurData['walletBalance'] != null
            ? double.tryParse(entrepreneurData['walletBalance'].toString()) ??
                0.0
            : 0.0;
        double newWalletBalance = currentWalletBalance + amount;

        // Obtener el nombre del donador desde Firestore
        DocumentSnapshot donorSnapshot =
            await firestore.collection('users').doc(donorId).get();
        String donorName =
            (donorSnapshot.data() as Map<String, dynamic>)['name'] ??
                'Desconocido';

        // Guardar el depósito en la colección 'deposits'
        transaction.set(firestore.collection('deposits').doc(), {
          'userId': donorId,
          'userName': donorName,
          'amount': amount,
          'projectId': projectId,
          'timestamp': Timestamp.now(),
        });

        // Actualizar la cantidad recaudada y el saldo de la billetera del emprendedor
        transaction.update(projectRef, {'currentAmount': updatedAmount});
        transaction
            .update(entrepreneurRef, {'walletBalance': newWalletBalance});

        // Crear una notificación para el propietario del proyecto
        DocumentReference notificationRef =
            firestore.collection('notifications').doc();

        transaction.set(notificationRef, {
          'recipientId': entrepreneurId,
          'senderId': donorId,
          'senderName': donorName, // Agregar el nombre del donador
          'type': 'donation',
          'postId': projectId,
          'amount': amount,
          'timestamp': Timestamp.now(),
          'isRead': false,
        });
      }
    });
  }

  void _showDonateDialog(BuildContext context, String projectId) {
    TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Donar al Proyecto"),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Ingrese el monto a invertir',
              prefixText: '\$',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                double? amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  Navigator.of(context).pop();
                  double amountInUSD = _convertPesosToUSD(amount);
                  _startPayPalPayment(amountInUSD, projectId);
                } else {
                  _scaffoldMessengerKey.currentState?.showSnackBar(
                    const SnackBar(
                        content: Text('Por favor, ingrese un monto válido.')),
                  );
                }
              },
              child: const Text("Invertir"),
            ),
          ],
        );
      },
    );
  }

  double _convertPesosToUSD(double pesosAmount) {
    const double exchangeRate = 4000;
    return pesosAmount / exchangeRate;
  }

  void _startPayPalPayment(double amount, String projectId) {
    final BuildContext parentContext = context; // Guarda el contexto actual
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => Scaffold(
          appBar: AppBar(title: const Text('Pago con PayPal')),
          body: UsePaypal(
            key: UniqueKey(),
            sandboxMode: true,
            clientId:
                "AQ5dorXnLrdhWwcLJGy5e2t2AUbD0hZtQticx5e0BPwqnjU44LQk0iUwa16rHqUiat8FdRNP0fswEjSN",
            secretKey:
                "EN4-qZoG3yvUuoYALYjizhc1KL07Dyb31TFR-FhOwfsxZbyf4O60xtwSAYUCv8gxsCZjUDRdzqpW39DD",
            returnURL: "https://tusitio.com/return",
            cancelURL: "https://tusitio.com/cancel",
            transactions: [
              {
                "amount": {
                  "total": amount.toStringAsFixed(2),
                  "currency": "USD",
                  "details": {
                    "subtotal": amount.toStringAsFixed(2),
                    "shipping": '0',
                    "shipping_discount": 0
                  }
                },
                "description": "Donación al proyecto",
                "item_list": {
                  "items": [
                    {
                      "name": "Donación",
                      "quantity": 1,
                      "price": amount.toStringAsFixed(2),
                      "currency": "USD"
                    }
                  ],
                }
              }
            ],
            note: "Gracias por tu apoyo al proyecto.",
            onSuccess: (Map params) async {
              if (!mounted) return;
              double amountInPesos = amount * 4000;
              await _donate(projectId, amountInPesos);
              _scaffoldMessengerKey.currentState?.showSnackBar(
                const SnackBar(
                    content: Text('Donación completada exitosamente.')),
              );
              // Cerrar la pantalla de pago
              Navigator.of(parentContext).pop();
              // Navegar a la publicación
              Navigator.of(parentContext).push(
                MaterialPageRoute(
                  builder: (context) => PostDetailPage(projectId: projectId),
                ),
              );
            },
            onError: (error) {
              if (mounted) {
                _scaffoldMessengerKey.currentState?.showSnackBar(
                  SnackBar(content: Text('Error en el pago: $error')),
                );
              }
            },
            onCancel: (params) {
              if (mounted) {
                _scaffoldMessengerKey.currentState?.showSnackBar(
                  const SnackBar(content: Text('Donación cancelada.')),
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFeed() {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection('projects')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No hay proyectos disponibles.'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot project = snapshot.data!.docs[index];
            Map<String, dynamic> projectData =
                project.data() as Map<String, dynamic>;

            double goalAmount = projectData['goalAmount'] != null
                ? double.tryParse(projectData['goalAmount'].toString()) ?? 0.0
                : 0.0;
            double currentAmount = projectData['currentAmount'] != null
                ? double.tryParse(projectData['currentAmount'].toString()) ??
                    0.0
                : 0.0;

            double progress = (goalAmount > 0)
                ? (currentAmount / goalAmount).clamp(0.0, 1.0)
                : 0.0;

            List<dynamic> imageUrls = projectData['imageUrls'] ?? [];
            List<dynamic> likes = projectData['likes'] ?? [];
            String userId = projectData['userId'] ?? '';

            String projectTitle = projectData['name'] ?? 'Proyecto sin título';
            ValueNotifier<bool> isExpanded = ValueNotifier(false);

            return FutureBuilder(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(userId)
                  .get(),
              builder: (context, AsyncSnapshot<DocumentSnapshot> userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                Map<String, dynamic> userData =
                    userSnapshot.data!.data() as Map<String, dynamic>;

                String firstName = userData['name'] ?? 'Usuario';
                String lastName = userData['lastName'] ?? '';
                String fullName = '$firstName $lastName';
                String userProfilePicture = userData['profilePicture'] ??
                    'https://via.placeholder.com/150';

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(userProfilePicture),
                        ),
                        title: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProfilePage(userId: userId),
                              ),
                            );
                          },
                          child: Text(
                            fullName,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        subtitle: Text(_timeAgo(projectData['timestamp'])),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          projectTitle,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ValueListenableBuilder<bool>(
                          valueListenable: isExpanded,
                          builder: (context, expanded, child) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expanded
                                      ? projectData['description'] ?? ''
                                      : (projectData['description'] ?? '')
                                          .split('\n')
                                          .first,
                                  maxLines: expanded ? null : 2,
                                  overflow: expanded
                                      ? TextOverflow.visible
                                      : TextOverflow.ellipsis,
                                ),
                                GestureDetector(
                                  onTap: () {
                                    isExpanded.value = !expanded;
                                  },
                                  child: Text(
                                    expanded ? 'Ver menos' : 'Ver más',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      if (imageUrls.isNotEmpty)
                        SizedBox(
                          height: 250,
                          child: PageView.builder(
                            itemCount: imageUrls.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(15.0),
                                  child: Image.network(
                                    imageUrls[index],
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: goalAmount > 0
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Financiamiento del proyecto:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.monetization_on_rounded,
                                          color: Colors.green),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Stack(
                                          children: [
                                            Container(
                                              height: 16,
                                              decoration: BoxDecoration(
                                                color: Colors.grey[300],
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            Container(
                                              height: 16,
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width *
                                                  0.6 *
                                                  progress,
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Colors.blue,
                                                    Colors.lightBlueAccent,
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.flag, color: Colors.red),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Progreso: ${(progress * 100).toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '\$${currentAmount.toStringAsFixed(0)} de \$${goalAmount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              )
                            : const Text('Financiamiento no disponible'),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(
                                  likes.contains(_loggedUser!.uid)
                                      ? Icons.thumb_up
                                      : Icons.thumb_up_alt_outlined,
                                ),
                                onPressed: () => _toggleLike(project.id),
                              ),
                              Text('${likes.length}'),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.comment_outlined),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      CommentsPage(projectId: project.id),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.share_outlined),
                            onPressed: () {},
                          ),
                          TextButton(
                            onPressed: () {
                              _showDonateDialog(context, project.id);
                            },
                            child: const Text(
                              'Invertir',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Nuevo método para mostrar los depósitos
  Widget _buildDeposits() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('deposits')
          .where('userId', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final deposits = snapshot.data!.docs;
        final total = deposits.fold<double>(
          0.0,
          (sum, doc) => sum + (doc['amount'] as num).toDouble(),
        );
        return ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Total Depositado: \$${total.toStringAsFixed(2)}',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            ...deposits.map((doc) => ListTile(
                  title: Text('\$${doc['amount']}'),
                  subtitle: Text(
                    'Donado por: ${doc['userName'] ?? 'Desconocido'}\nFecha: ${(doc['timestamp'] as Timestamp).toDate()}',
                  ),
                )),
          ],
        );
      },
    );
  }

  void _showPostModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 16.0,
            left: 16.0,
            right: 16.0,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
              ),
              const SizedBox(height: 10),
              _images.isNotEmpty
                  ? GridView.builder(
                      shrinkWrap: true,
                      itemCount: _images.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2),
                      itemBuilder: (context, index) {
                        return Image.file(
                          _images[index],
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Icon(
                        Icons.image,
                        size: 100,
                        color: Colors.grey,
                      ),
                    ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _pickImages,
                    child: const Text('Seleccionar Imágenes'),
                  ),
                  ElevatedButton(
                    onPressed: _uploadPost,
                    child: const Text('Publicar'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lista de páginas ajustada
    final List<Widget> pages = <Widget>[
      _buildFeed(),
      const ProjectGridPage(),
      const CreateProjectPage(),
      const NotificationsPage(),
      ProfilePage(userId: FirebaseAuth.instance.currentUser!.uid),
      if (_userType == 'Emprendedor')
        _buildDeposits(), // Solo para "emprendedor"
    ];

    // Lista de ítems del BottomNavigationBar ajustada
    List<BottomNavigationBarItem> navigationBarItems = [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home),
        label: 'Inicio',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.search),
        label: 'Explorar',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.add_box),
        label: 'Crear',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.notifications),
        label: 'Notificaciones',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Perfil',
      ),
    ];

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leadingWidth: 100, // Ajusta el ancho para el logo
          leading: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Row(
              children: [
                // Logo circular con "iF"
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Colors.white, // Fondo del círculo
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'i',
                            style: TextStyle(
                              color:
                                  Colors.blueAccent, // Color azul para la "i"
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                          TextSpan(
                            text: 'F',
                            style: TextStyle(
                              color: Colors.black, // Color negro para la "F"
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8), // Espaciado entre el logo y el borde
              ],
            ),
          ),
          actions: [
            // Indicador de notificaciones no leídas
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('recipientId',
                      isEqualTo: FirebaseAuth.instance.currentUser!.uid)
                  .where('isRead', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                int unreadCount = 0;
                if (snapshot.hasData) {
                  unreadCount = snapshot.data!.docs.length;
                }
                return IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.favorite_outline, color: Colors.black),
                      if (unreadCount > 0)
                        Positioned(
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const NotificationsPage()),
                    );
                  },
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              color: Colors.black,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const UsersListPage()),
                );
              },
            ),
          ],
        ),
        body: pages[_selectedIndex],
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          items: navigationBarItems,
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          onTap: (int index) {
            setState(() {
              if (index < pages.length) {
                _selectedIndex = index;
              }
            });
          },
        ),
        floatingActionButton: _userType == 'Emprendedor'
            ? FloatingActionButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const WalletPage()),
                  );
                },
                child: const Icon(Icons.account_balance_wallet),
              )
            : FloatingActionButton(
                onPressed: () => _showPostModal(context),
                child: const Icon(Icons.add),
              ),
      ),
    );
  }
}
