import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hmd_system/pages/settings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hmd_system/model/Muser.dart';
import 'package:hmd_system/model/appoinment.dart';
import 'package:hmd_system/pages/profile/Userprofile.dart';

class ListApt extends StatelessWidget {
  ListApt({Key? key}) : super(key: key);

  //I'll propose some changes here.  I can't see your firebase obviously so I'm guessing on some things, but I think this will
  //get you what you want or at least closte.  It is probably easier to store the User's uid inside the appointment 
  // and then you don't have to retrieve the array before querying for the appointments.
  //  I changed the class name to Upper camel case to match the dart style guide and the file name to match as well.
  //  To each their own really, but my linter won't stop bugging if I don't.

  final User? user = FirebaseAuth.instance
      .currentUser; // I would use a StateNotifier here and store this globally.  Then you could just take a dependency on it here.
  late final Muser loggedInUser;
  final List<Appointment> aptList = [];
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  Future<List<Appointment>?> loadList() async {
   await FirebaseFirestore.instance
        .collection("mUsers")
        .doc(user!.uid)
        .get()
        .then((snapshot) async {
      loggedInUser = Muser.fromMap(snapshot.data());
      for (var apts in snapshot.data()?["appointment"]) {
        var _appointment = await FirebaseFirestore.instance
            .collection("appointment")
            .doc(apts)
            .get();

        aptList.add(Appointment.fromMap(_appointment.data()));
      }
    });
    return aptList;
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
