import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stripe_marketplace/stripe/database.dart';
import 'package:stripe_marketplace/stripe/pick_role_page.dart';
import 'package:stripe_marketplace/stripe/user.dart';

class ListOfUsersPage extends StatefulWidget {
  const ListOfUsersPage({Key key}) : super(key: key);

  @override
  _ListOfUsersPageState createState() => _ListOfUsersPageState();
}

class _ListOfUsersPageState extends State<ListOfUsersPage> {
  bool bSuccessful = false;

  @override
  void initState() {
    super.initState();
    this.initDynamicLinks();
  }

  void initDynamicLinks() async {
    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData dynamicLink) async {
      final Uri deepLink = dynamicLink?.link;

      if (deepLink != null) {
        Navigator.pushNamed(context, deepLink.path);
      }
    }, onError: (OnLinkErrorException e) async {
      print('onLinkError');
      print(e.message);
    });

    final PendingDynamicLinkData data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri deepLink = data?.link;

    if (deepLink != null) {
      print(
        "This is the deeplink path ${deepLink.path} and the query parameters are ${deepLink.queryParameters}",
      );

      if (deepLink.queryParameters.containsKey("successful")) {
        print("The user was successfully registered.");
        bSuccessful = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Colors.black,
        // brightness: Brightness.dark,
        // backgroundColor: const Color(0xFF242323),
        // accentColor: Colors.white,
        accentIconTheme: IconThemeData(color: Colors.black),
        // dividerColor: Colors.black12,
      ),
      home: Scaffold(
        appBar:
            AppBar(title: Text(bSuccessful ? "Successful" : "List of Users")),
        body: FutureBuilder<List<User>>(
          future: DatabaseService().listOfUsers(),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (!snapshot.hasData)
              return Center(child: CircularProgressIndicator());
            else {
              List<User> userList = snapshot.data;

              return ListView.builder(
                itemCount: userList.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: Text(
                      userList[index]?.userHandle,
                      style: TextStyle(fontSize: 23),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Provider.value(
                                value: userList[index],
                                child: PickYourDestiny())),
                      );
                    },
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
