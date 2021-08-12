import 'package:flutter/material.dart';
import 'package:stripe_marketplace/string_apis.dart';
import 'package:provider/provider.dart';
import 'package:stripe_marketplace/stripe/cart_page.dart';
import 'package:stripe_marketplace/stripe/database.dart';
import 'package:stripe_marketplace/stripe/product.dart';
import 'package:stripe_marketplace/stripe/user.dart';

class ListOfProductsPage extends StatefulWidget {
  ListOfProductsPage({Key key}) : super(key: key);

  @override
  _ListOfProductsPageState createState() => _ListOfProductsPageState();
}

class _ListOfProductsPageState extends State<ListOfProductsPage> {
  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<User>(context);

    return Scaffold(
      appBar: AppBar(title: Text("List of Products"), actions: [
        IconButton(
          icon: Icon(Icons.shopping_cart),
          onPressed: () async {
            List<Product> productList =
                await DatabaseService(uid: userProvider.uid)
                    .listOfProductsInCart();

            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => Provider.value(
                      value: userProvider,
                      child: CartPage(
                        accountID: userProvider.stripeAccountID,
                        product:
                            productList.length >= 1 ? productList[0] : null,
                      ))),
            );
          },
        ),
      ]),
      body: FutureBuilder<List<Product>>(
        future: DatabaseService().listOfProducts(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());
          else {
            List<Product> productList = snapshot.data;

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                // childAspectRatio: 2,
              ),
              itemCount: productList.length,
              itemBuilder: (BuildContext context, int index) {
                return ProductCard(
                  product: productList[index],
                );
              },
            );
          }
        },
      ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({Key key, @required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<User>(context);

    return Center(
      child: Container(
          height: 500,
          width: 130,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                height: 110,
                child: product.picture.notNullAndEmpty()
                    ? Image.network(product.picture)
                    : Placeholder(),
              ),
              Text(product.productname),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline_rounded,
                      size: 30,
                    ),
                    onPressed: () async {
                      await DatabaseService(uid: userProvider.uid)
                          .modifyCart(product.id, product, -1);
                    },
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_rounded,
                      size: 30,
                    ),
                    onPressed: () async {
                      await DatabaseService(uid: userProvider.uid)
                          .modifyCart(product.id, product, 1);
                    },
                  ),
                ],
              ),
            ],
          )),
    );
  }
}
