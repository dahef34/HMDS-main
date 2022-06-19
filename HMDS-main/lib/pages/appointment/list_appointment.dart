import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hmd_system/pages/settings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hmd_system/model/Muser.dart';
import 'package:hmd_system/model/appoinment.dart';
import 'package:hmd_system/pages/profile/Userprofile.dart';

class ListApt extends StatelessWidget {
  ListApt({Key? key}) : super(key: key);

  final User? user = FirebaseAuth.instance
      .currentUser; // I would use a StateNotifier here and store this globally.  Then you could just take a dependency on it here.
  late final Muser loggedInUser;
  final List<Appointment> aptList = [];
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<Muser> getUser() async {
    if (loggedInUser.uid == user?.uid) {return loggedInUser;}
    FirebaseAuth.instance.authStateChanges().listen((user) async {
        final snapshot = await FirebaseFirestore.instance
        .collection("mUsers")
        .doc(user!.uid)
        .get();
    loggedInUser = Muser.fromMap(snapshot.data());
     });
    return loggedInUser;
  }

  Future<List<Appointment>?> loadList() async {
     final List<String>? apts = await getUser().then((value) => value.appointment as List<String>?);
     if (apts != null && apts.isNotEmpty) {
      aptList.clear();
      for (final String apt in apts) {
        var _appointment = await FirebaseFirestore.instance
            .collection("appointment")
            .doc(apt)
            .get();

        aptList.add(Appointment.fromMap(_appointment.data()));
      }
      return aptList;
     } else {
       return null;
     }
    }

  Future<List<Appointment>?> addAppointment(Appointment apt) async {
    aptList.add(apt);
    List<String?> apptUids = aptList.map((e) => e.uid).toList();
    await FirebaseFirestore.instance
        .collection("mUsers")
        .doc('${loggedInUser.uid}')
        .set({"appointment": apptUids}).then((snapshot) async {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(apt.uid)
          .set(apt.toMap());
    });
    return loadList();
  }

  Future<List<Appointment>?> updateAppointment(Appointment apt) async {

    // You can use the update method here is you want, but you wouldn't pass in an Appoint
    // You would pass in the individial values that you want to update and
    // set individual fields in a map.  It's easier just to pass in the whole appointment
    // and use set to override the previous appointment.

      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(apt.uid)
          .set(apt.toMap());

    return loadList();
  }

  
  Future<List<Appointment>?> deleteAppointment(Appointment apt) async {

      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(apt.uid)
          .delete();

    return loadList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[100],
      appBar: AppBar(
        backgroundColor: Colors.lightBlue[800],
        elevation: 0,
        leading: const BackButton(),
        title: const Text(
          'Appointment List',
          style: TextStyle(
            fontSize: 15.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const userProfile(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.person,
                  color: Colors.black,
                ),
                label: const Text(''),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const setPage(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.settings,
                  color: Colors.black,
                ),
                label: const Text(''),
              ),
            ],
          )
        ],
      ),
      body: Center(
        child: FutureBuilder(
            future: loadList(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return ListView.builder(
                  itemCount: aptList.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: Column(
                        children: <Widget>[
                          ListTile(
                            title: Text(
                              "${aptList[index].title}",
                              style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "${aptList[index].details}",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                              ),
                            ),
                            trailing: Text(
                              "${aptList[index].month} / ${aptList[index].day} / ${aptList[index].year}",
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              } else if (snapshot.hasError) {
                return Text(snapshot.error.toString());
              } else {
                return const Center(child: CircularProgressIndicator());
              }
            }),
      ),
      endDrawer: ClipPath(
        clipper: _DrawerClipper(),
        child: Drawer(
          child: Container(
            padding: const EdgeInsets.only(top: 48.0),
            child: Column(
              children: const <Widget>[
                Text(
                  "Notifications",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ],
            ),
          ),
        ),
      ),
      key: _scaffoldKey,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.teal[200],
        onPressed: () {
          _scaffoldKey.currentState?.openEndDrawer();
        },
        child: const Icon(
          Icons.notifications,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _DrawerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(50, 0);
    path.quadraticBezierTo(0, size.height / 2, 50, size.height);
    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
