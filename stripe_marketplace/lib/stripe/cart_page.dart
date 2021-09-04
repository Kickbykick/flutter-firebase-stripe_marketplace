import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_credit_card/credit_card_model.dart';
import 'package:provider/provider.dart';
import 'package:stripe_marketplace/stripe/constants.dart';
import 'package:stripe_marketplace/stripe/credit_card_page.dart';
import 'package:stripe_marketplace/stripe/database.dart';
import 'package:stripe_marketplace/stripe/product.dart';
import 'package:stripe_marketplace/stripe/sellers_dashboard.dart';
import 'package:stripe_marketplace/stripe/user.dart';
import 'package:http/http.dart' as http;
import 'package:stripe_payment/stripe_payment.dart';

//TODO: Switch plugin
class CartPage extends StatefulWidget {
  final String accountID;
  final Product product;
  CartPage({Key key, @required this.accountID, @required this.product})
      : super(key: key);

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  String text = 'Click the button to start the payment';
  double totalCost = 1000.0;
  double tip = 1.0;
  double tax = 0.0;
  double extraAmount = 0.0;

  double taxPercent = 0.2;
  int amount = 0;
  bool showSpinner = false;

  @override
  void initState() {
    super.initState();
    StripePayment.setOptions(
      StripeOptions(
        publishableKey: stripePrivateKey,
        merchantId: 'merchant.kickbykickmarkeplace',
        androidPayMode: 'test',
      ),
    );
  }

  Future<void> createPaymentMethod(CreditCardModel creditCardModel) async {
    StripePayment.setStripeAccount(null);

    tax = ((totalCost * taxPercent) * 100).ceil() / 100;
    amount = ((totalCost + tip + tax) * 100).toInt();
    List<String> listOfExpiryDate =
        creditCardModel.expiryDate.split("/"); //e.g [11, 22]

    print(listOfExpiryDate);
    processPaymentAsDirectCharge({
      "paymentmethod": {
        "type": "card",
        "card": {
          "number": creditCardModel.cardNumber,
          "exp_month": int.parse(listOfExpiryDate[0]),
          "exp_year": int.parse('20${listOfExpiryDate[1]}'),
          "cvc": creditCardModel.cvvCode
        },
        "billing_details": {
          "name": 'Jenny Rosen',
          "address": {"postal_code": "R2J1P6"}
        }
      }
    });
  }

  Future<void> processPaymentAsDirectCharge(Map paymentMethod) async {
    setState(() {
      showSpinner = true;
    });

    // String uidPayment = "4oHYQE3z3b7WeEgjh8u7";
    String stripeAccountId = widget.accountID ?? "acct_1IhUiS2RGp15zJDq";
    String productReference = "/Product/${widget.product.id}" ?? "";
    print(stripeAccountId);

    try {
      print(paymentMethod);
      final http.Response response = await http.post(
        Uri.parse(
            '$stripepaymentCloudUrl?accountid=$stripeAccountId&reference=$productReference&paymentMethod=$paymentMethod'),
        body: json.encode(paymentMethod),
        headers: {
          'Content-type': 'application/json',
        },
      );

      print(response.body);

      if (response.body != null && response.body != 'error') {
        final paymentIntentX = jsonDecode(response.body);
        final status = paymentIntentX['paymentIntent']['status'];
        final strAccount = paymentIntentX['stripeAccount'];
        //step 3: check if payment was succesfully confirmed
        if (status == 'succeeded') {
          StripePayment.completeNativePayRequest();

          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  'Payment completed. ${paymentIntentX['paymentIntent']['amount'].toString()}\$ succesfully charged')));
        } else {
          StripePayment.setStripeAccount(strAccount);
          await StripePayment.confirmPaymentIntent(PaymentIntent(
                  paymentMethodId: paymentIntentX['paymentIntent']
                      ['payment_method'],
                  clientSecret: paymentIntentX['paymentIntent']
                      ['client_secret']))
              .then(
            (PaymentIntentResult paymentIntentResult) async {
              final statusFinal = paymentIntentResult.status;
              if (statusFinal == 'succeeded') {
                StripePayment.completeNativePayRequest();
                await DatabaseService(
                        uid: Provider.of<User>(context, listen: false).uid)
                    .createHistoryDocumentForUser(productReference, totalCost,
                        tax, extraAmount, tip, widget.product.sellerid);
                setState(() {
                  showSpinner = false;
                });
                // Generate history for user - uid, product id, brefund false
              } else if (statusFinal == 'processing') {
                StripePayment.cancelNativePayRequest();

                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        'The payment is still in \'processing\' state. This is unusual. Please contact us')));
              } else {
                StripePayment.cancelNativePayRequest();
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                        'There was an error to confirm the payment. Details: $statusFinal')));
              }
            },
            //If Authentication fails, a PlatformException will be raised which can be handled here
          ).catchError((e) {
            //case B1
            StripePayment.cancelNativePayRequest();

            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(
                    'There was an error to confirm the payment. Please try again with another card')));
          });
        }
      } else {
        //case A
        StripePayment.cancelNativePayRequest();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'There was an error in creating the payment. Please try again with another card')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<User>(context);

    return Scaffold(
      appBar: AppBar(title: Text("List of Users")),
      body: FutureBuilder<List<Product>>(
        future: DatabaseService(uid: userProvider.uid).listOfProductsInCart(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          else {
            List<Product> cartList = snapshot.data;

            return ListView.builder(
              itemCount: cartList.length + 1,
              itemBuilder: (BuildContext context, int index) {
                if (index == cartList.length)
                  return widget.product == null
                      ? Container()
                      : Padding(
                          padding: const EdgeInsets.only(
                              top: 50.0, left: 50, right: 50),
                          child: SizedBox(
                            height: 50,
                            child: ElevatedButton(
                              child: Text(
                                "PAY NOW!!!!!!",
                                style: TextStyle(fontSize: 40),
                              ),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CreditCardPage(),
                                  ),
                                ).then((creditCartModel) async {
                                  if (creditCartModel is CreditCardModel) {
                                    await createPaymentMethod(creditCartModel);
                                  }
                                });
                              },
                            ),
                          ),
                        );

                return ListTile(
                  contentPadding: EdgeInsets.all(10),
                  leading: Image.network(cartList[index].picture),
                  title: Text(
                    cartList[index]?.productname,
                    style: TextStyle(fontSize: 23),
                  ),
                  trailing: Text("x${cartList[index].count}"),
                );
              },
            );
          }
        },
      ),
    );
  }
}
