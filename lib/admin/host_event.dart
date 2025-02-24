// ignore_for_file: unnecessary_null_comparison

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:event_managment/.ai-api/groq_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:event_managment/admin/admin_navigation_drawer.dart';
import 'package:image_picker/image_picker.dart';
import 'admin_events.dart';
import '../admin/set_location.dart';
import 'package:intl/intl.dart';

class HostEvent extends StatefulWidget {
  const HostEvent({Key? key}) : super(key: key);

  @override
  State<HostEvent> createState() => _HostEventState();
}

class _HostEventState extends State<HostEvent> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _instructions;
  late final TextEditingController _capacity;
  late final TextEditingController _location;
  late final TextEditingController _mobile;
  late final TextEditingController _email;
  late final TextEditingController _host;
  late final TextEditingController _numberOfDaysController;
  DateTime? _startDate;
  DateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool loading = false;
  final ImagePicker _picker = ImagePicker();
    var selectedImages = <dynamic>[];
  var encodedImages = <dynamic>[];

  List<TextEditingController> _dayWiseDescription = [];
  int _numberOfDays = 0;

  int numOfRegisteredUsers = 0;

  String documentId = '';

  String? userEmail = '';

  @override
  void initState() {
    _title = TextEditingController();
    _description = TextEditingController();
    _instructions = TextEditingController();
    _capacity = TextEditingController();
    _location = TextEditingController();
    _mobile = TextEditingController();
    _email = TextEditingController();
    _host = TextEditingController();
    _numberOfDaysController = TextEditingController();
    _dayWiseDescription = [];
    _startDate = DateTime.now();
    _endDate = DateTime.now();
    _startTime = TimeOfDay.now();
    _endTime = TimeOfDay.now();

    userEmail = FirebaseAuth.instance.currentUser?.email;

    super.initState();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _instructions.dispose();
    _capacity.dispose();
    _location.dispose();
    _mobile.dispose();
    _email.dispose();
    _host.dispose();
    _numberOfDaysController.dispose();
    for (var controller in _dayWiseDescription) {
      controller.dispose();
    }

    super.dispose();
  }

    Future<void> pickImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    for (var file in pickedFiles) {
      File imageFile = File(file.path);
      selectedImages.add(imageFile);
      encodeImageToBase64(imageFile);
          setState(() {
      
    });
    }
  }

  void encodeImageToBase64(File imageFile) async {
    List<int> imageBytes = await imageFile.readAsBytes();
    String base64String = base64Encode(imageBytes);
    encodedImages.add(base64String);

  }

    void removeImage(int index) {
    selectedImages.removeAt(index);
    encodedImages.removeAt(index);
    setState(() {
      
    });
  }


  // ============= ADD EVENT DETAILS TO FIREBASE =============
  Future<void> addEventDetails(
    String title,
    String description,
    String instructions,
    String capacity,
    String location,
    String mobile,
    String email,
    String host,
    String timeStamp,
    int numberOfDays,
    DateTime startDate,
    DateTime endDate,
    TimeOfDay startTime,
    TimeOfDay endTime,
    int numOfRegisteredUsers,
    String category, // New parameter
  ) async {
    try {
      final eventDoc = FirebaseFirestore.instance.collection("events").doc();
      List<String> days = [];

      // Only process day-wise descriptions if numberOfDays > 0
      if (numberOfDays > 0) {
        for (int i = 0; i < numberOfDays; i++) {
          final description = _dayWiseDescription[i].text.trim();
          days.add(description);
        }
      }

      final eventData = {
        'title': title,
        'description': description,
        'instructions': instructions,
        'capacity': capacity,
        'location': location,
        'mobile': mobile,
        'email': email,
        'host': host,
        'timeStamp': timeStamp,
        'numberOfDays': numberOfDays,
        'days': days,
        'startDate': startDate,
        'endDate': endDate,
        'startTime': _formatTime(startTime),
        'endTime': _formatTime(endTime),
        'numOfRegisteredUsers': numOfRegisteredUsers,
        "images": encodedImages.toList(),
        'category': category, // Store AI-determined category
      };

      await eventDoc.set(eventData);

      documentId = eventDoc.id;
    } on Exception catch (e) {
      log('error: $e');
    }
  }
  // ============= END =============

  // ============= FORMAT TIME =============
  String _formatTime(TimeOfDay time) {
    final String timeFormat =
        MediaQuery.of(context).alwaysUse24HourFormat ? 'HH:mm' : 'h:mm a';
    final DateTime now = DateTime.now();
    return DateFormat(timeFormat).format(DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    ));
  }
  // ============= END =============

  // ============= SHOW ALERT DIALOG =============

  void showAlertDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.deepPurple),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
  // ============= END =============

  // ============= SHOW SUCCESS ALERT DIALOG =============

  void showSuccessAlertDialog(
      BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(color: Colors.deepPurple),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                // Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                //   return const AdminEvents();
                // }));
                log('Before Navigation documentId: $documentId');
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => SetLocation(
                      documentId: documentId,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
  // ============= END =============

  // ============= SELECT DATE AND TIME =============

  Future<void> _selectStartDate(BuildContext context) async {
    final ThemeData theme = Theme.of(context).copyWith(
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.deepPurple,
      ),
      dialogBackgroundColor: Colors.white,
    );
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(data: theme, child: child!);
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final ThemeData theme = Theme.of(context).copyWith(
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.deepPurple,
      ),
      dialogBackgroundColor: Colors.white,
    );
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(data: theme, child: child!);
      },
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  Future<void> _selectStartTime(BuildContext context) async {
    final ThemeData theme = Theme.of(context).copyWith(
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.deepPurple,
      ),
      dialogBackgroundColor: Colors.white,
    );
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(data: theme, child: child!);
      },
    );

    if (picked != null) {
      setState(() {
        _startTime = picked;
      });
    }
  }

  Future<void> _selectEndTime(BuildContext context) async {
    final ThemeData theme = Theme.of(context).copyWith(
      colorScheme: ColorScheme.fromSwatch(
        primarySwatch: Colors.deepPurple,
      ),
      dialogBackgroundColor: Colors.white,
    );
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? TimeOfDay.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(data: theme, child: child!);
      },
    );

    if (picked != null) {
      setState(() {
        _endTime = picked;
      });
    }
  }
  // ============= END =============
  // ============= END ALL METHODS =============

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "HOST AN EVENT",
          ),
          backgroundColor: Colors.deepPurple,
          centerTitle: true,
        ),
        drawer: const AdminNavigationDrawer(),
        backgroundColor: Colors.grey[300],
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  height: 30.0,
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: const [
                      Text(
                        "Host Events here",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Text(
                        " Fill up all the details correctly and select location on map ",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),

                //TITLE TEXTFIELD
                const SizedBox(
                  height: 20,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: TextField(
                        controller: _title,
                        cursorColor: Colors.deepPurple,
                        decoration: const InputDecoration(
                          hintText: 'Event title',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
                //DESCRIPTION TEXT FIELD
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: TextField(
                        controller: _description,
                        cursorColor: Colors.deepPurple,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: 'Event description',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
                //INSTRUCTIONS TEXTFIELD
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: TextField(
                        controller: _instructions,
                        cursorColor: Colors.deepPurple,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText: 'Instructions to be followed by attendee',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
                //START DATE FIELD
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 30.0, right: 30.0),
                  child: ListTile(
                    title: const Text('Start Date'),
                    subtitle: Text(_startDate != null
                        ? DateFormat.yMd().format(_startDate!)
                        : 'Not set'),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.calendar_today,
                        color: Colors.deepPurple,
                      ),
                      onPressed: () => _selectStartDate(context),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 30.0, right: 30.0),
                  child: ListTile(
                    title: const Text('End Date'),
                    subtitle: Text(_endDate != null
                        ? DateFormat.yMd().format(_endDate!)
                        : 'Not set'),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.calendar_today,
                        color: Colors.deepPurple,
                      ),
                      onPressed: () => _selectEndDate(context),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 30.0, right: 30.0),
                  child: ListTile(
                    title: const Text('Start Time'),
                    subtitle: Text(_startTime != null
                        ? _startTime!.format(context)
                        : 'Not set'),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.access_time,
                        color: Colors.deepPurple,
                      ),
                      onPressed: () => _selectStartTime(context),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 30.0, right: 30.0),
                  child: ListTile(
                    title: const Text('End Time'),
                    subtitle: Text(_endTime != null
                        ? _endTime!.format(context)
                        : 'Not set'),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.access_time,
                        color: Colors.deepPurple,
                      ),
                      onPressed: () => _selectEndTime(context),
                    ),
                  ),
                ),
                //CAPACITY
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: TextField(
                        controller: _capacity,
                        cursorColor: Colors.deepPurple,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Event capacity',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
                //DAYWISE DESCRIPTION OF EVENT
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: TextField(
                        controller: _numberOfDaysController,
                        cursorColor: Colors.deepPurple,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Number of Days',
                          border: InputBorder.none,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _numberOfDays = int.tryParse(value) ?? 0;
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Column(children: [
                  ElevatedButton(
                    onPressed: () {
                      if (_numberOfDays > 0) {
                        _dayWiseDescription.clear();
                        for (int i = 0; i < _numberOfDays; i++) {
                          _dayWiseDescription.add(TextEditingController());
                        }
                        setState(() {});
                      } else {
                        showAlertDialog(
                          context,
                          "Invalid Input",
                          "Please enter a valid number of days.",
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "Give daywise description",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ]),

                //DAYWISE DESCRIPTION FIELDS
                const SizedBox(
                  height: 20,
                ),
                Column(
                  children: List.generate(
                    _dayWiseDescription.length,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.white),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 25.0),
                              child: TextField(
                                controller: _dayWiseDescription[index],
                                cursorColor: Colors.deepPurple,
                                maxLines: null,
                                decoration: InputDecoration(
                                  hintText: 'Day ${index + 1} Description',
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                //EVENT LOCATION DETAILS
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: TextField(
                        controller: _location,
                        cursorColor: Colors.deepPurple,
                        maxLines: null,
                        decoration: const InputDecoration(
                          hintText:
                              'Event location (describe the location here you need to point the location on map later)',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
                //HOST MOBILE DETAILS
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: TextField(
                        controller: _mobile,
                        cursorColor: Colors.deepPurple,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Enter your mobile no. for contact details',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
                //HOST EMAIL
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: TextField(
                        controller: _email,
                        cursorColor: Colors.deepPurple,
                        decoration: const InputDecoration(
                          hintText: 'Enter your registered email',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
                //HOST NAME
                const SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.white),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 25.0),
                      child: TextField(
                        controller: _host,
                        cursorColor: Colors.deepPurple,
                        decoration: const InputDecoration(
                          hintText: 'Enter your name',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                ),
                //EVENT HOSTING BUTTON
                const SizedBox(
                  height: 20,
                ),
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: selectedImages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return GestureDetector(
                          onTap: pickImages,
                          child: Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              color: Colors.grey,
                            ),
                            child:  Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: const [
                                Icon(Icons.add_a_photo, size: 30, color: Colors.white),
                                SizedBox(height: 5),
                                Text("Add Images", style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                        );
                      } else {
                        int imageIndex = index - 1;
                        return Stack(
                          children: [
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 5),
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                image: DecorationImage(
                                  image: selectedImages[imageIndex] is String
                                      ? NetworkImage(selectedImages[imageIndex])
                                      : selectedImages[imageIndex] is MemoryImage
                                          ? selectedImages[imageIndex] as ImageProvider
                                          : FileImage(selectedImages[imageIndex] as File),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 5,
                              right: 5,
                              child: GestureDetector(
                                onTap: () => removeImage(imageIndex),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(4),
                                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),

                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 300,
                      height: 50,
                      // ============= ON PRESS HOST BUTTON WE HAVE TO PERFORM SOME VALIDATIONS =================
                      child: ElevatedButton(
                        onPressed: loading
                            ? null // Disable the button when loading
                            : () async {
                                setState(() {
                                  loading = true; // Start loading
                                });

                                final title = _title.text.trim();
                                final description = _description.text.trim();
                                final instructions = _instructions.text.trim();
                                final capacity = _capacity.text.trim();
                                final location = _location.text.trim();
                                final mobile = _mobile.text.trim();
                                final email = _email.text.trim();
                                final host = _host.text.trim();
                                final timeStamp = DateTime.now().toString();
                                final startDate = _startDate.toString();
                                final endDate = _endDate.toString();
                                final startTime = _startTime.toString();
                                final endTime = _endTime.toString();

                                try {
                                  // Validate day-wise descriptions
                                  if (_numberOfDays > 0) {
                                    if (_dayWiseDescription.isEmpty ||
                                        _dayWiseDescription.length !=
                                            _numberOfDays) {
                                      showAlertDialog(
                                        context,
                                        "Invalid Input",
                                        "Please click 'Give daywise description' and fill all day-wise descriptions.",
                                      );
                                      return;
                                    }

                                    bool isAnyDescriptionEmpty = false;
                                    for (int i = 0;
                                        i < _dayWiseDescription.length;
                                        i++) {
                                      if (_dayWiseDescription[i]
                                          .text
                                          .trim()
                                          .isEmpty) {
                                        isAnyDescriptionEmpty = true;
                                        break;
                                      }
                                    }
                                    if (isAnyDescriptionEmpty) {
                                      showAlertDialog(
                                        context,
                                        "Invalid Input",
                                        "Please add day-wise descriptions for all days.",
                                      );
                                      return;
                                    }
                                  }

                                  // Validate other fields
                                  if (title.isNotEmpty &&
                                      description.isNotEmpty &&
                                      instructions.isNotEmpty &&
                                      capacity.isNotEmpty &&
                                      location.isNotEmpty &&
                                      mobile.isNotEmpty &&
                                      email.isNotEmpty &&
                                      host.isNotEmpty &&
                                      email == userEmail &&
                                      email.contains('@') &&
                                      mobile.length == 11 &&
                                      startDate.isNotEmpty &&
                                      endDate.isNotEmpty &&
                                      startTime.isNotEmpty &&
                                      endTime.isNotEmpty) {
                                    // Call AI API to classify the event
                                    String category =
                                        await classifyEvent(description);

                                    // Add event details to Firestore
                                    await addEventDetails(
                                      title,
                                      description,
                                      instructions,
                                      capacity,
                                      location,
                                      mobile,
                                      email,
                                      host,
                                      timeStamp,
                                      _numberOfDays,
                                      _startDate!,
                                      _endDate!,
                                      _startTime!,
                                      _endTime!,
                                      numOfRegisteredUsers,
                                      category,
                                    );

                                    // Show success dialog
                                    showSuccessAlertDialog(
                                      context,
                                      "Success",
                                      "Event Hosted Successfully",
                                    );
                                  } else if (title.isEmpty) {
                                    showAlertDialog(
                                      context,
                                      "Invalid Input",
                                      "Please enter your event title",
                                    );
                                  } else if (description.isEmpty) {
                                    showAlertDialog(
                                      context,
                                      "Invalid Input",
                                      "Please enter your event description",
                                    );
                                  } else if (instructions.isEmpty) {
                                    showAlertDialog(
                                      context,
                                      "Invalid Input",
                                      "Please enter your event instructions",
                                    );
                                  } else if (location.isEmpty) {
                                    showAlertDialog(
                                      context,
                                      "Invalid Input",
                                      "Please enter your event location",
                                    );
                                  } else if (mobile.isEmpty) {
                                    showAlertDialog(
                                      context,
                                      "Invalid Input",
                                      "Please enter your mobile number",
                                    );
                                  } else if (mobile.length != 11) {
                                    showAlertDialog(
                                      context,
                                      "Invalid Input",
                                      "Please enter a valid mobile number of 11 digits",
                                    );
                                  } else if (email.isEmpty ||
                                      email != userEmail) {
                                    showAlertDialog(
                                      context,
                                      "Invalid Input",
                                      "Please enter your email address that you have used for registration",
                                    );
                                  } else if (host.isEmpty) {
                                    showAlertDialog(
                                      context,
                                      "Invalid Input",
                                      "Please enter your name i.e. event host name",
                                    );
                                  } else if (startDate.isEmpty) {
                                    showAlertDialog(
                                      context,
                                      "Invalid Input",
                                      "Please enter your event start date",
                                    );
                                  } else if (endDate.isEmpty) {
                                    showAlertDialog(
                                      context,
                                      "Invalid Input",
                                      "Please enter your event last date",
                                    );
                                  } else if (startTime.isEmpty) {
                                    showAlertDialog(
                                      context,
                                      "Invalid Input",
                                      "Please enter your event start time",
                                    );
                                  } else if (endTime.isEmpty) {
                                    showAlertDialog(
                                      context,
                                      "Invalid Input",
                                      "Please enter your event end time",
                                    );
                                  } else if (selectedImages.isEmpty) {
                                    showAlertDialog(
                                      context,
                                      "Invalid Input",
                                      "Please pick at least one image for the event",
                                    );
                                  } 
                                  else {
                                    showAlertDialog(
                                      context,
                                      "Invalid Input",
                                      "Please enter a title and select start and end times.",
                                    );
                                  }
                                } catch (e) {
                                  showAlertDialog(
                                      context, "Error", e.toString());
                                  log('errorrrrrrr: $e');
                                } finally {
                                  setState(() {
                                    loading = false; // Stop loading
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: loading
                            ? const CircularProgressIndicator(
                                color: Colors.white, // Show loading indicator
                              )
                            : const Text(
                                "HOST",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 100,
                )
              ],
            ),
          ),
        ),

        // =============  FLOATING ACTION BUTTON TO NAVIGATE TO MY EVENTS PAGE =============
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return const AdminEvents();
                }));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text("Go to My Events"),
            ),
          ],
        ),
      ),
    );
  }
}
