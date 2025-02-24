import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:event_managment/attendee/attendee_navigation_drawer.dart';
import 'package:event_managment/home/loading.dart';
import '/attendee/attendee_navigation.dart';
import '/attendee/event_info.dart';

class Events extends StatefulWidget {
  const Events({Key? key}) : super(key: key);

  @override
  State<Events> createState() => _EventsState();
}

class _EventsState extends State<Events> {
  String title = '';
  String description = '';
  String email = '';
  String timeStamp = '';

  List<String> registeredUsers = [];
  String? currentUser = FirebaseAuth.instance.currentUser?.email;
  final CollectionReference<Map<String, dynamic>> _reference = FirebaseFirestore.instance.collection("events");
  List<Map<String, dynamic>> allEvents = [];
  List<Map<String, dynamic>> recommendedEvents = [];
  bool isLoading = true;
  bool isError = false;

  void showAlertDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    String userId = FirebaseAuth.instance.currentUser!.uid;
    try {
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance.collection('users').where('user_id', isEqualTo: userId).get();

      List<String> interestedCategories = [];
      if (userSnapshot.docs.isNotEmpty) {
        interestedCategories = List<String>.from(userSnapshot.docs.first['interested_categories'] ?? []);
      }

      QuerySnapshot eventSnapshot = await _reference.get();
      List<Map<String, dynamic>> events = eventSnapshot.docs.map((e) => e.data() as Map<String, dynamic>).toList();

      List<Map<String, dynamic>> filteredRecommendedEvents =
          events.where((event) => interestedCategories.contains(event['category'])).toList();

      setState(() {
        allEvents = events;
        recommendedEvents = filteredRecommendedEvents;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching events: $e");
      setState(() {
        isLoading = false;
        isError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Events",
        ),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      drawer: const AttendeeNavigationDrawer(),
      backgroundColor: Colors.grey[300],
      body: Column(
        children: [
          const SizedBox(
            height: 30,
          ),
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              "There are many Events for you",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(20.0),
            child: Text(
              " Register and enjoy the Event ",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Expanded(
            child: isLoading
                ? const Loading()
                : isError
                    ? const Text("Some error has occurred")
                    : allEvents.isEmpty && recommendedEvents.isEmpty
                        ? const Center(child: Text("No Events found."))
                        : recommendedEvents.isNotEmpty
                            ? DefaultTabController(
                                length: 2,
                                child: Column(
                                  children: [
                                    const TabBar(
                                      tabs: [
                                        Tab(text: "Recommended"),
                                        Tab(text: "All Events"),
                                      ],
                                    ),
                                    Expanded(
                                      child: TabBarView(
                                        children: [
                                          buildEventList(recommendedEvents),
                                          buildEventList(allEvents),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : buildEventList(allEvents),
          )
        ],
      ),
    );
  }

  Widget buildEventList(List<Map<String, dynamic>> events) {
    if (events.isEmpty) {
      return const Center(child: Text("No Events found."));
    }
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: ListView.builder(
        itemCount: events.length,
        itemBuilder: (context, index) {
          Map<String, dynamic> thisItem = events[index];
          String? imageBase64 = thisItem['images'] != null && thisItem['images'].isNotEmpty ? thisItem['images'][0] : null;
          DecorationImage? backgroundImage;
          if (imageBase64 != null) {
            backgroundImage = DecorationImage(
              image: MemoryImage(base64Decode(imageBase64)),
              fit: BoxFit.cover,
            );
          }
    
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: double.infinity,
                child: Card(
                  elevation: 7,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: backgroundImage == null ? Colors.white : null,
                      image: backgroundImage,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              "${thisItem['title']}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20.0,
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: RichText(
                                    text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
                                  children: <TextSpan>[
                                    const TextSpan(
                                      text: "DESCRIPTION : ",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: "${thisItem['description']}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                )),
                              )
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: RichText(
                                    text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
                                  children: <TextSpan>[
                                    const TextSpan(
                                      text: "INSTRUCTIONS : ",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: "${thisItem['instructions']}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                )),
                              )
                            ],
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            children: [
                              Flexible(
                                child: RichText(
                                    text: TextSpan(
                                  style: DefaultTextStyle.of(context).style,
                                  children: <TextSpan>[
                                    const TextSpan(
                                      text: "LOCATION : ",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: "${thisItem['location']}",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                )),
                              )
                            ],
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const SizedBox(
                                  height: 20,
                                ),
                                SizedBox(
                                  height: 50,
                                  width: 300,
                                  child: ElevatedButton(
                                      onPressed: () {
                                        Navigator.of(context).push(MaterialPageRoute(
                                          builder: (context) => EventInfo(
                                            title: thisItem['title'],
                                            description: thisItem['description'],
                                            instructions: thisItem['instructions'],
                                            capacity: thisItem['capacity'],
                                            location: thisItem['location'],
                                            mobile: thisItem['mobile'],
                                            email: thisItem['email'],
                                            host: thisItem['host'],
                                            timeStamp: thisItem['timeStamp'],
                                            days: thisItem['days'],
                                            startTime: thisItem['startTime'],
                                            endTime: thisItem['endTime'],
                                            startDate: thisItem['startDate'] != null
                                                ? (thisItem['startDate'] as Timestamp).toDate().toString()
                                                : '',
                                            endDate: thisItem['endDate'] != null
                                                ? (thisItem['endDate'] as Timestamp).toDate().toString()
                                                : '',
                                              images: (thisItem['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
                                                  []
                                          ),
                                        ));
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.deepPurple,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                      child: const Text(
                                        "More Info",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Already Registered ? ",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  QuerySnapshot<Map<String, dynamic>> querySnapshot = await FirebaseFirestore.instance
                                      .collection('events')
                                      .where('title', isEqualTo: thisItem['title'])
                                      .where('description', isEqualTo: thisItem['description'])
                                      .get();
    
                                  if (querySnapshot.docs.isNotEmpty) {
                                    for (QueryDocumentSnapshot<Map<String, dynamic>> document in querySnapshot.docs) {
                                      CollectionReference registeredUsersCollection =
                                          document.reference.collection('registeredUsers');
                                      QuerySnapshot<Map<String, dynamic>> registeredUsersSnapshot =
                                          await registeredUsersCollection.get() as QuerySnapshot<Map<String, dynamic>>;
    
                                      if (registeredUsersSnapshot.docs.isNotEmpty) {
                                        List<String> registeredusers =
                                            registeredUsersSnapshot.docs.map((doc) => doc['email'] as String? ?? '').toList();
                                        setState(() {
                                          registeredUsers = registeredusers;
                                        });
                                      }
                                    }
                                  }
                                  if (registeredUsers.contains(currentUser)) {
                                    // ignore: use_build_context_synchronously
                                    Navigator.of(context).push(MaterialPageRoute(
                                      builder: (context) => AttendeeNavigation(
                                        title: thisItem['title'],
                                        description: thisItem['description'],
                                        email: currentUser.toString(),
                                        timeStamp: thisItem['timeStamp'],
                                      ),
                                    ));
                                  } else {
                                    // ignore: use_build_context_synchronously
                                    showAlertDialog(
                                        context, "Not registered", "You haven't registered for this event please register");
                                  }
                                },
                                child: const Text(
                                  "go to my event",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                    fontSize: 17,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}
