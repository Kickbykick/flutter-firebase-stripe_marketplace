// To parse this JSON data, do
//
//     final product = productFromJson(jsonString);

import 'dart:convert';

Product productFromJson(String str) => Product.fromJson(json.decode(str));

String productToJson(Product data) => json.encode(data.toJson());

class Product {
  Product({
    this.sellerid,
    this.productname,
    this.picture,
    this.price,
    this.currency,
    this.bRefund,
    this.id,
    this.count,
  });

  String sellerid;
  String productname;
  String picture;
  double price;
  String currency;
  String id;
  bool bRefund;
  int count;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        sellerid: json["sellerid"],
        productname: json["productname"],
        picture: json["picture"],
        price: json["price"] + 0.0,
        currency: json["currency"],
        id: json["id"],
        count: json["count"] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        "sellerid": sellerid,
        "productname": productname,
        "picture": picture,
        "price": price,
        "currency": currency,
        "id": id,
        "count": count
      };
}
