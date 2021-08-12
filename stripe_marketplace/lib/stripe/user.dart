import 'dart:convert';

User userFromJson(String str) => User.fromJson(json.decode(str));

String userToJson(User data) => json.encode(data.toJson());

class User {
  User({
    this.uid,
    this.userHandle,
    this.bSetupDone,
    this.stripeAccountID,
    this.earnings,
    this.purchased,
  });

  String uid;
  String userHandle;
  String stripeAccountID;
  bool bSetupDone;
  double earnings;
  double purchased;

  factory User.fromJson(Map<String, dynamic> json) => User(
        uid: json["uid"],
        userHandle: json["userhandle"],
        bSetupDone: json["bSetupDone"],
        stripeAccountID: json["accountID"],
        earnings: json["earnings"] + 0.0,
        purchased: json["purchased"] + 0.0,
      );

  Map<String, dynamic> toJson() => {
        "uid": uid,
        "userhandle": userHandle,
        "bSetupDone": bSetupDone,
        "earnings": earnings,
        "purchased": purchased,
        "stripeAccountID": stripeAccountID,
      };

  @override
  String toString() {
    return toJson().toString();
  }
}
