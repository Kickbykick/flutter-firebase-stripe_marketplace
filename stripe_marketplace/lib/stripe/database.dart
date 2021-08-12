import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stripe_marketplace/stripe/constants.dart';
import 'package:stripe_marketplace/stripe/history.dart';
import 'package:stripe_marketplace/stripe/product.dart';
import 'package:stripe_marketplace/stripe/user.dart';
import 'package:http/http.dart' as http;

class DatabaseService {
  final String uid;
  DatabaseService({this.uid});

  final CollectionReference userCollection =
      FirebaseFirestore.instance.collection('User');
  final CollectionReference productCollection =
      FirebaseFirestore.instance.collection('Product');

  FirebaseFirestore dbInstance = FirebaseFirestore.instance;

  Future<List<User>> listOfUsers() async {
    var query = await userCollection.get();
    List<DocumentSnapshot> theList = query.docs;

    List<User> listOfUsers = [];

    for (int i = 0; i < theList.length; i++) {
      User currUser = User.fromJson(theList[i].data());

      listOfUsers.add(currUser);
    }

    return listOfUsers;
  }

  Future<List<Product>> listOfProducts() async {
    var query = await productCollection.get();
    List<DocumentSnapshot> theList = query.docs;

    List<Product> listOfProducts = [];

    for (int i = 0; i < theList.length; i++) {
      Product currProduct = Product.fromJson(theList[i].data());

      listOfProducts.add(currProduct);
    }

    return listOfProducts;
  }

  Future<List<Product>> listOfProductsInCart() async {
    var query = await userCollection.doc(uid).collection("Cart").get();
    List<DocumentSnapshot> theList = query.docs;

    List<Product> listOfProducts = [];

    for (int i = 0; i < theList.length; i++) {
      Product currProduct = Product.fromJson(theList[i].data());

      listOfProducts.add(currProduct);
    }

    return listOfProducts;
  }

  Future<List<History>> listOfUsersHistory() async {
    var query = await userCollection.doc(uid).collection("History").get();
    List<DocumentSnapshot> theList = query.docs;

    List<History> listOfHistories = [];

    for (int i = 0; i < theList.length; i++) {
      History currHistory = History.fromJson(theList[i].data());

      listOfHistories.add(currHistory);
    }

    return listOfHistories;
  }

  Future dashboardCombination(String stripeAccountID) async {
    final http.Response response = await http.get(
      Uri.parse(
          '$cloudfunctionUrl$cloudfunctionUserbalancePath?accountid=$stripeAccountID'),
    );

    List<History> historyList = await listOfUsersHistory();

    var query = await userCollection.doc(uid).get();

    return [
      User.fromJson(query.data()),
      response,
      historyList,
    ];
  }

  Future payoutUser(String stripeAccountID) async {
    final http.Response response = await http.get(
      Uri.parse(
          '$cloudfunctionUrl$cloudfunctionPayoutPath?accountid=$stripeAccountID'),
    );

    return response;
  }

  createHistoryDocumentForUser(String productID, double amountPaid, double tax,
      double extraAmount, double tip, String sellersUserID) async {
    // The Seller
    final DocumentReference docRef = userCollection
        .doc(sellersUserID); // recieve UID of the person that owns the product
    docRef.update({"earnings": FieldValue.increment(amountPaid)});

    await userCollection.doc(sellersUserID).collection("History").doc().set({
      "bRefund": false,
      "productID": productID,
      "amountPaid": amountPaid,
      "extraAmount": extraAmount,
      "tax": tax,
      "tip": tip
    });

    // The buyer
    final DocumentReference docRef1 = userCollection.doc(uid);
    docRef1.update({"purchased": FieldValue.increment(amountPaid)});

    await userCollection.doc(uid).collection("Purchases").doc().set({
      "bRefund": false,
      "productID": productID,
      "amountPaid": amountPaid,
      "extraAmount": extraAmount,
      "tax": tax,
      "tip": tip
    });
  }

  createProductDocumentForUser(Product product) async {
    await productCollection.doc().set(product.toJson());
  }

  Future<void> modifyCart(String productId, Product product, int value) async {
    DocumentSnapshot query =
        await userCollection.doc(uid).collection("Cart").doc(productId).get();

    if (!query.exists) {
      await userCollection
          .doc(uid)
          .collection("Cart")
          .doc(productId)
          .set({"count": 1, ...product.toJson()});
    } else {
      if (query.data()["count"] == 1 && value <= -1) {
        await userCollection
            .doc(uid)
            .collection("Cart")
            .doc(productId)
            .delete();
      } else {
        await userCollection
            .doc(uid)
            .collection("Cart")
            .doc(productId)
            .update({"count": FieldValue.increment(value)});
      }
    }
  }
}
