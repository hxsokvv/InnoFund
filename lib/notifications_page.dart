import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  String _timeAgo(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    Duration difference = DateTime.now().difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} días atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} horas atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutos atrás';
    } else {
      return 'Justo ahora';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifications')
            .where('recipientId', isEqualTo: currentUserId)
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          List<DocumentSnapshot> notifications = snapshot.data!.docs;

          if (notifications.isEmpty) {
            return const Center(
              child: Text(
                'No tienes notificaciones',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            itemCount: notifications.length,
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              Map<String, dynamic> notificationData =
                  notifications[index].data() as Map<String, dynamic>;
              String senderId = notificationData['senderId'];
              String type = notificationData['type'];
              Timestamp timestamp = notificationData['timestamp'];
              bool isRead = notificationData['isRead'];
              String? amount = notificationData['amount']?.toString();

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(senderId)
                    .get(),
                builder: (context, senderSnapshot) {
                  if (senderSnapshot.hasError) {
                    return ListTile(
                        title: Text('Error: ${senderSnapshot.error}'));
                  }

                  if (!senderSnapshot.hasData) {
                    return const ListTile(title: Text('Cargando...'));
                  }

                  Map<String, dynamic> senderData =
                      senderSnapshot.data!.data() as Map<String, dynamic>;
                  String senderName = senderData['name'] ?? 'Usuario';
                  String senderLastName =
                      senderData['lastName'] ?? ''; // Apellido del usuario.

                  String notificationText;

                  if (type == 'like') {
                    notificationText =
                        '$senderName $senderLastName le ha dado "me gusta" a tu proyecto.';
                  } else if (type == 'comment') {
                    notificationText =
                        '$senderName $senderLastName ha comentado en tu proyecto.';
                  } else if (type == 'donation') {
                    notificationText =
                        '$senderName $senderLastName ha donado \$${amount ?? '0.00'} a tu proyecto.';
                  } else {
                    notificationText =
                        'Nueva notificación de $senderName $senderLastName.';
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12.0),
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: isRead
                          ? Colors.white
                          : const Color(0xFFEDE7F6), // Color lavanda claro
                      border: Border.all(
                        color: Colors.grey.shade300,
                      ),
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          offset: const Offset(0, 4),
                          blurRadius: 8.0,
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(
                            senderData['profilePicture'] ??
                                'https://via.placeholder.com/150',
                          ),
                          radius: 25,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                notificationText,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _timeAgo(timestamp),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isRead)
                          const CircleAvatar(
                            radius: 5,
                            backgroundColor: Colors.blue,
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
