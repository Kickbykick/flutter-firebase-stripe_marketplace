// To parse this JSON data, do
//
//     final history = historyFromJson(jsonString);

import 'dart:convert';

History historyFromJson(String str) => History.fromJson(json.decode(str));

String historyToJson(History data) => json.encode(data.toJson());

class History {
  History({
    this.bRefund,
    this.productId,
    this.amountPaid,
    this.extraAmount,
    this.tax,
    this.tip,
  });

  bool bRefund;
  String productId;
  double amountPaid;
  double extraAmount;
  double tax;
  double tip;

  factory History.fromJson(Map<String, dynamic> json) => History(
        bRefund: json["bRefund"],
        productId: json["productID"],
        amountPaid: json["amountPaid"],
        extraAmount: json["extraAmount"],
        tax: json["tax"],
        tip: json["tip"],
      );

  Map<String, dynamic> toJson() => {
        "bRefund": bRefund,
        "productID": productId,
        "amountPaid": amountPaid,
        "extraAmount": extraAmount,
        "tax": tax,
        "tip": tip,
      };
}
