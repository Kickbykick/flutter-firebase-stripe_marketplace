import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:stripe_marketplace/stripe/database.dart';
import 'package:stripe_marketplace/stripe/history.dart';
import 'package:stripe_marketplace/stripe/user.dart';
import 'package:http/http.dart' as http;

class DashboardLayout extends StatelessWidget {
  final User user;
  const DashboardLayout({Key key, @required this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get all this data directly from stripe

    // Future for UserCollection Document, User History and Stripe account retrieval stuff
    return FutureBuilder<dynamic>(
      future: DatabaseService(uid: user.uid)
          .dashboardCombination(user.stripeAccountID),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData)
          return Center(child: CircularProgressIndicator());
        else {
          dynamic list = snapshot.data;
          User user = snapshot.data[0] as User;
          List<History> historyList = list[2] as List<History>;
          http.Response response = list[1] as http.Response;
          Map responseJson = jsonDecode(response.body);
          print(list[1]);

          return RefreshIndicator(
            onRefresh: () {},
            child: ListView(
              shrinkWrap: true,
              children: [
                SizedBox(height: 10),
                Center(
                  child: Text(
                    user.userHandle,
                    style: TextStyle(fontSize: 20),
                  ),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Balance",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Column(
                      children: <Widget>[
                        Text(
                          "Available",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                            "${responseJson["available"][0]["amount"].toString()} ${responseJson["available"][0]["currency"]}"),
                      ],
                    ),
                    SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          "Instant Available",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                            "${responseJson["instant_available"][0]["amount"].toString()} ${responseJson["instant_available"][0]["currency"]}"),
                      ],
                    ),
                    SizedBox(width: 10),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          "Pending",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                            "${responseJson["pending"][0]["amount"].toString()} ${responseJson["pending"][0]["currency"]}"),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Total amount earned: ${user.earnings} CAD",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "History",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(height: 10),

                // Name - userhandle
                // Total Earnings
                // Amount Ready for payout
                // Earnings in account
                // Payout button
                // History, listview

                ListView.builder(
                  itemCount: historyList.length,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                                "ProductID: ${historyList[index].productId}\nAmountPaid: ${historyList[index].amountPaid}"),
                            Divider(),
                          ],
                        ));
                  },
                ),

                SizedBox(height: 20),

                // Ignore payout if the user does not have up to $5
                IgnorePointer(
                  ignoring: responseJson["instant_available"][0]["amount"] < 5,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: ElevatedButton(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "Payout ME",
                          style: TextStyle(fontSize: 30),
                        ),
                      ),
                      onPressed: () async {
                        http.Response response = await DatabaseService()
                            .payoutUser(user.stripeAccountID);
                        print(response);
                      },
                      style: ElevatedButton.styleFrom(
                          primary:
                              responseJson["instant_available"][0]["amount"] < 5
                                  ? Colors.grey
                                  : Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
