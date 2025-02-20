import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:final_app/pages/add_review_page.dart';
import 'package:final_app/pages/login_page.dart';
import 'package:final_app/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cafe Reviews'),
        actions: [
          IconButton(
            onPressed: () async {
              final authProvider = Provider.of<MyAuthProvider>(
                context,
                listen: false,
              );

              await authProvider.signOut();

              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              }
            },
            icon: Icon(Icons.logout, color: Colors.red),
          ),
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('reviews').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return CircularProgressIndicator();

          final reviews = snapshot.data!.docs;

          return ListView.builder(
            itemCount: reviews.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> data = reviews[index].data();
              return ListTile(
                title: Text(data['cafe_name']),
                subtitle: Text(data['description']),
                leading: Image.network(
                  data['image_url'],
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
                onTap: () {
                  print(reviews[index].id);
                  // Navigator.push(context, MaterialPageRoute(builder: (context) => ReviewDetailPage(reviewId: reviews[index].id),));
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddReviewPage()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
