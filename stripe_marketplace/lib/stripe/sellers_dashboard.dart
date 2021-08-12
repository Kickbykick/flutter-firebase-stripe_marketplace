import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stripe_marketplace/stripe/constants.dart';
import 'package:stripe_marketplace/stripe/create_product_page.dart';
import 'package:stripe_marketplace/stripe/dashlayout.dart';
import 'package:stripe_marketplace/stripe/user.dart';
import 'package:url_launcher/url_launcher.dart';

class SellersDashboard extends StatefulWidget {
  final User user;
  SellersDashboard({Key key, @required this.user}) : super(key: key);

  @override
  _SellersDashboardState createState() => _SellersDashboardState();
}

class _SellersDashboardState extends State<SellersDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(!widget.user.bSetupDone ? "Payment Setup" : "Dashboard"),
        actions: [
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Provider.value(
                        value: widget.user, child: CreateProductPage())),
              );
            },
            child: !widget.user.bSetupDone
                ? SizedBox()
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(Icons.add),
                  ),
          ),
        ],
      ),
      body: !widget.user.bSetupDone
          ? PaymentSetup(user: widget.user)
          : DashboardLayout(user: widget.user),
    );
  }
}

class PaymentSetup extends StatefulWidget {
  final User user;
  const PaymentSetup({Key key, @required this.user}) : super(key: key);

  @override
  _PaymentSetupState createState() => _PaymentSetupState();
}

class _PaymentSetupState extends State<PaymentSetup> {
  TextEditingController firstNameController;
  TextEditingController lastNameController;
  TextEditingController emailController;
  TextEditingController businessNameController;

  @override
  void initState() {
    super.initState();
    firstNameController = TextEditingController();
    lastNameController = TextEditingController();
    emailController = TextEditingController();
    businessNameController = TextEditingController();
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    businessNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
        child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 20),
            shrinkWrap: true,
            children: [
          SizedBox(
            height: 40,
          ),
          TextFormField(
            controller: businessNameController,
            decoration: InputDecoration(hintText: "Business Name"),
          ),
          SizedBox(
            height: 20,
          ),
          TextFormField(
            controller: firstNameController,
            decoration: InputDecoration(hintText: "First Name"),
          ),
          SizedBox(
            height: 20,
          ),
          TextFormField(
            controller: lastNameController,
            decoration: InputDecoration(hintText: "Last Name"),
          ),
          SizedBox(
            height: 20,
          ),
          TextFormField(
            controller: emailController,
            decoration: InputDecoration(hintText: "Email"),
          ),
          SizedBox(
            height: 40,
          ),
          ElevatedButton(
              child: Text(
                "Continue Setup ...",
                style: TextStyle(fontSize: 30),
              ),
              onPressed: () async {
                await launch(
                  "$cloudfunctionUrl$cloudfunctionAuthorizePath?businessName=${businessNameController.text}&firstName=${firstNameController.text}&lastName=${lastNameController.text}&email=${emailController.text}&uid=${widget.user.uid}",
                );
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.resolveWith<Color>(
                    (Set<MaterialState> states) {
                  if (states.contains(MaterialState.pressed))
                    return Colors.blueAccent;
                  return null; // Use the component's default.
                }),
              )),
        ]));
  }
}

class ShowDialogToDismiss extends StatelessWidget {
  final String content;
  final String title;
  final String buttonText;
  ShowDialogToDismiss({this.title, this.buttonText, this.content});
  @override
  Widget build(BuildContext context) {
    if (!Platform.isIOS) {
      return AlertDialog(
        title: new Text(
          title,
        ),
        content: new Text(
          this.content,
        ),
        actions: <Widget>[
          new FlatButton(
            child: new Text(
              buttonText,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    } else {
      return CupertinoAlertDialog(
          title: Text(
            title,
          ),
          content: new Text(
            this.content,
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              isDefaultAction: true,
              child: new Text(
                buttonText[0].toUpperCase() +
                    buttonText.substring(1).toLowerCase(),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ]);
    }
  }
}

// UTILITY FUNCTIONS