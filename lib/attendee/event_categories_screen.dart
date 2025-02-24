import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'attendee_events_page.dart';

class EventCategoriesScreen extends StatefulWidget {
  const EventCategoriesScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _EventCategoriesScreenState createState() => _EventCategoriesScreenState();
}

class _EventCategoriesScreenState extends State<EventCategoriesScreen> {
  List<String> categories = [
    "Academic",
    "Cultural",
    "Sports",
    "Social",
    "Technical",
    "Community",
    "Entertainment",
    "Religious",
  ];
  List<String> selectedCategories = [];
  bool isLoading = false;

  void toggleSelection(String category) {
    setState(() {
      if (selectedCategories.contains(category)) {
        selectedCategories.remove(category);
      } else {
        selectedCategories.add(category);
      }
    });
  }

  Future<void> saveCategories() async {
    setState(() {
      isLoading = true;
    });

    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').where('user_id', isEqualTo: userId).get().then((querySnapshot) {
        for (var doc in querySnapshot.docs) {
          doc.reference.update({'interested_categories': selectedCategories});
        }
      });
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) {
              return const Events();
            },
          ),
        );
      }
    } catch (e) {
      print('Error updating Firestore: $e');
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Event Categories'),
      automaticallyImplyLeading: false,

      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 20,),

                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "Please choose the event categories that you'd like to browse:",
                    style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20,),
                Expanded(
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      String category = categories[index];
                      bool isSelected = selectedCategories.contains(category);
                      return ListTile(
                        title: Text(category),
                        trailing: Icon(
                          isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                          color: isSelected ? Colors.blue : null,
                        ),
                        onTap: () => toggleSelection(category),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton(
                        onPressed: selectedCategories.isNotEmpty ? saveCategories : null,
                        child: const Text('Continue'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) {
                                return const Events();
                              },
                            ),
                          );
                        },
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
