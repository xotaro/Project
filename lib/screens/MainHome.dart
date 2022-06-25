import 'package:adaptive_speech/screens/home_page.dart';
import 'package:adaptive_speech/screens/profile_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:getwidget/components/card/gf_card.dart';
import 'package:getwidget/components/list_tile/gf_list_tile.dart';
import 'package:provider/provider.dart';

import '../Cards/categories.dart';
import '../providers/auth_provider.dart';
import 'login_page.dart';

class MainHome extends StatefulWidget {
  const MainHome({Key? key}) : super(key: key);

  @override
  _MainHomeState createState() => _MainHomeState();
}

class _MainHomeState extends State<MainHome> {
  String personType1 = 'Deaf';
  String personType2 = 'Normal';
  late AuthProvider authProvider;
  late String currentUserId;


  Future<void> googleSignOut() async {
    authProvider.googleSignOut();
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) =>
        LoginPage()), (Route<dynamic> route) => false);

  }
  @override
  void initState() {
    // TODO: implement initState
    authProvider = context.read<AuthProvider>();
    if (authProvider.getFirebaseUserId()?.isNotEmpty == true) {
      currentUserId = authProvider.getFirebaseUserId()!;
    } else {
      Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
              (Route<dynamic> route) => false);
    }
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(36, 36, 62, 1),
      appBar: AppBar(
          centerTitle: true,
          title: const Text('Hear Me'),
          actions: [
            IconButton(
                onPressed: () => googleSignOut(),
                icon: const Icon(Icons.logout)),
            IconButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ProfilePage()));
                },
                icon: const Icon(Icons.person)),
          ]),
      body: SingleChildScrollView(
        child: Column(
        children: [
          InkWell(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => HomePage()));
            },
            child: GFCard(
              color: Color(0xFF713094),
              clipBehavior: Clip.antiAlias,
              padding: EdgeInsets.all(3),
              elevation: 3,
              height: 195,
              boxFit: BoxFit.cover,
              //titlePosition: GFPosition.start,
              //showOverlayImage: true,
              //imageOverlay: AssetImage('assets/Chat1.png'),

              title: GFListTile(
                title: Center(
                  child: Text(
                    'Chat',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 25),
                  ),
                ),
              ),
              showImage: true,
              image:
              Image.asset('assets/Chat1.png', width: 110, height: 110),
            ),
          ),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => categoriesState(personType1),
                ),
              );
            },
            child: GFCard(
              color: Color(0xFF713094),
              clipBehavior: Clip.antiAlias,
              padding: EdgeInsets.all(3),
              elevation: 3,
              height: 195,
              boxFit: BoxFit.cover,
              //titlePosition: GFPosition.start,
              //showOverlayImage: true,
              //imageOverlay: AssetImage('assets/img1.png'),

              title: GFListTile(
                title: Center(
                  child: Text(
                    'Sign language',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 25),
                  ),
                ),
              ),
              showImage: true,
              image:
              Image.asset('assets/img1.png', width: 110, height: 110),
            ),
          ),

        ],
        ),
      ),
    );
  }
}
