import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:stripe_marketplace/stripe/database.dart';
import 'package:stripe_marketplace/stripe/product.dart';
import 'package:stripe_marketplace/stripe/user.dart';

class CreateProductPage extends StatefulWidget {
  CreateProductPage({Key key}) : super(key: key);

  @override
  _CreateProductPageState createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  TextEditingController descriptionController;
  TextEditingController pictureLinkController;
  TextEditingController productNameController;
  TextEditingController priceController;
  TextEditingController countController;

  Product product;

  @override
  void initState() {
    super.initState();
    descriptionController = TextEditingController();
    pictureLinkController = TextEditingController();
    productNameController = TextEditingController();
    priceController = TextEditingController();
    countController = TextEditingController();
  }

  @override
  void dispose() {
    descriptionController.dispose();
    pictureLinkController.dispose();
    productNameController.dispose();
    priceController.dispose();
    countController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<User>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Create new product"),
      ),
      body: Form(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 20),
          shrinkWrap: true,
          children: [
            SizedBox(
              height: 40,
            ),
            TextFormField(
              controller: descriptionController,
              decoration: InputDecoration(hintText: "Description"),
            ),
            SizedBox(
              height: 20,
            ),
            TextFormField(
              controller: pictureLinkController,
              decoration: InputDecoration(hintText: "Picture Link"),
            ),
            SizedBox(
              height: 20,
            ),
            TextFormField(
              controller: productNameController,
              decoration: InputDecoration(hintText: "Product Name"),
            ),
            SizedBox(
              height: 20,
            ),
            TextFormField(
              controller: priceController,
              decoration: InputDecoration(hintText: "Price"),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly
              ],
            ),
            SizedBox(
              height: 20,
            ),
            TextFormField(
              controller: countController,
              decoration: InputDecoration(hintText: "Count"),
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly
              ],
            ),
            SizedBox(
              height: 40,
            ),
            ElevatedButton(
                child: Text(
                  "Create new product ...",
                  style: TextStyle(fontSize: 30),
                ),
                onPressed: () async {
                  product = Product(
                    sellerid: userProvider.uid,
                    productname: productNameController.text,
                    picture: pictureLinkController.text,
                    price: double.tryParse(priceController.text),
                    currency: "CAD",
                    count: int.tryParse(countController.text), //10,
                    id: userProvider.uid +
                        descriptionController.text +
                        productNameController.text,
                  );
                  await DatabaseService().createProductDocumentForUser(product);
                  Navigator.pop(context);
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>(
                      (Set<MaterialState> states) {
                    if (states.contains(MaterialState.pressed))
                      return Colors.blueAccent;
                    return null; // Use the component's default.
                  }),
                )),
          ],
        ),
      ),
    );
  }
}
