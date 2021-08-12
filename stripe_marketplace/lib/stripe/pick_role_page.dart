import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stripe_marketplace/stripe/list_of_products.dart';
import 'package:stripe_marketplace/stripe/sellers_dashboard.dart';
import 'package:stripe_marketplace/stripe/user.dart';

class PickYourDestiny extends StatelessWidget {
  const PickYourDestiny({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<User>(context);

    print(userProvider.bSetupDone);
    return Scaffold(
      appBar: AppBar(
        title: Text("PICK YOUR DESTINY"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: 50,
              child: ElevatedButton(
                  child: Text(
                    "SELLER ...",
                    style: TextStyle(fontSize: 40),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SellersDashboard(
                                user: userProvider,
                              )),
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
            ),
            SizedBox(height: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                  child: Text(
                    "BUYER ...",
                    style: TextStyle(fontSize: 40),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => Provider.value(
                              value: userProvider,
                              child: ListOfProductsPage())),
                    );
                  },
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (Set<MaterialState> states) {
                      if (states.contains(MaterialState.pressed))
                        return Colors.greenAccent;
                      return null; // Use the component's default.
                    }),
                  )),
            )
          ],
        ),
      ),
    );
  }
}
