/* eslint-disable max-len */
const functions = require("firebase-functions");
const admin = require("firebase-admin");
// const firebase_tools = require('firebase-tools');
const querystring = require("querystring");
const cookieParser = require("cookie-parser");
const session = require("express-session");
// const firebase = require('firebase');
require("dotenv").config();
const bodyParser = require("body-parser");
const express = require("express");
const request = require("request-promise-native");
const cors = require("cors");
const stripe = require("stripe")(functions.config().stripe.test_sk);

admin.initializeApp(functions.config().firebase);

const db = admin.firestore();
const env = functions.config();
// const STRIPE_TEST_PK = env.stripe.test_pk;
const STRIPE_TEST_SK = env.stripe.test_sk;
// const STRIPE_PROD_PK = env.stripe.prod_pk;
// const STRIPE_PROD_SK = env.stripe.prod_sk;
const STRIPE_CLIENTID = env.stripe.client_id;
const STRIPE_AUTHORIZE_URI = env.stripe.authorize_uri;
const STRIPE_TOKEN_URI = env.stripe.token_uri;

const app = express();
app.use(cors());
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({extended: false}));
app.use(cookieParser(STRIPE_TEST_SK));
app.use(session({
  signed: true,
  resave: true,
  secret: STRIPE_TEST_SK,
  saveUninitialized: true,
})
);

exports.stripepaymentapi = functions.https.onRequest(async (req, res)=> {
  let fee = "";
  let description = "";
  let currency = "";

  // const fee = (req.query.amount/100) | 0;
  // Request should contain
  // : AccountID = accountid -> Query
  // : Document reference for the product = reference -> Query
  // : Payment method map = {paymentmethod} -> Body
  // Account fee from the document reference string

  console.log(`Check ${req.query.accountid} ${req.query.reference} \n ${req.body.paymentmethod}`);
  const stripeAccountId = req.query.accountid;
  const productDocumentReference = db.doc(req.query.reference);

  productDocumentReference.get().then((doc) => {
    if (doc.exists) {
      fee = doc.data().price;
      description = doc.data().description;
      currency = doc.data().currency.toLowerCase();

      console.log("Document data: %i , %s , %s", fee, description, currency);
    } else {
      console.log("No such document!");
    }
  }).catch((error) => {
    console.log("Error getting document:", error);
  });

  if (stripeAccountId !== null && stripeAccountId !== undefined) {
    console.log("Stripe account: %s %s", stripeAccountId, typeof stripeAccountId);

    const paymentMethodTest = await stripe.paymentMethods.create(
        req.body.paymentmethod
        , {
          stripe_account: stripeAccountId,
        },
    );

    console.log("Payment Method: ", paymentMethodTest.id);

    // intent
    const paymentIntent = await stripe.paymentIntents.create({
      payment_method: paymentMethodTest.id,
      payment_method_types: ["card"],
      amount: fee,
      currency: currency,
      application_fee_amount: 123,
      confirmation_method: "automatic",
      confirm: true,
      // customer: customer.id
    }, {
      stripe_account: stripeAccountId,
    });

    console.log("Payment intent: ", paymentIntent);

    res.json(
        {
          paymentIntent: paymentIntent,
          stripeAccount: stripeAccountId,
        }
    );
  } else {
    res.send("Could not find the account ID");
  }
});

app.get("/userbalance", async (req, res) => {
  if (req.query.accountid !== null && req.query.accountid !== undefined) { // req.query.accountid !== undefined
    const balance = await stripe.balance.retrieve({
      stripeAccount: req.query.accountid,
    });

    res.send(balance);
  } else {
    res.send("Could not find the stripe account");
  }
});

app.get("/payoutuser", async (req, res) => {
  try {
    // Fetch the account balance to determine the available funds
    const balance = await stripe.balance.retrieve({
      stripeAccount: req.query.accountid,
    });

    const {amount, currency} = balance.available[0];
    console.log("Balance : ", balance);

    const ts = Date.now();
    const dateOb = new Date(ts);
    const date = dateOb.getDate();
    const month = dateOb.getMonth() + 1;
    const year = dateOb.getFullYear();

    // Create a payout
    const payout = await stripe.payouts.create({
      amount: amount,
      currency: currency,
      method: "instant",
      statement_descriptor: year + "-" + month + "-" + date + "Take your money : )",
    }, {stripe_account: req.query.accountid},
    );

    console.log("Payout: ", payout);
  } catch (err) {
    console.log(err);
  }
});


app.get("/authorize", async (req, res) => {
  req.session.state = Math.random().toString(36).slice(2);
  req.session.save();
  req.session.uid = req.query.uid;
  // Define the mandatory Stripe parameters:
  // make sure to include our platform's client ID
  let parameters = {
    client_id: STRIPE_CLIENTID,
    state: req.session.state,
  };

  parameters = Object.assign(parameters, {
    "redirect_uri": "YOUR_CLOUD_FUNCTION_URL/stripeapi/token",
    // 'stripe_user[business_type]': req.user.type || 'individual',
    "stripe_user[business_name]": req.query.businessName || undefined,
    "stripe_user[first_name]": req.query.firstName || undefined,
    "stripe_user[last_name]": req.query.lastName || undefined,
    "stripe_user[email]": req.query.email || undefined,
    // 'stripe_user[country]': req.query.country || undefined
    // If we're suggesting this account have the `card_payments` capability,
    // we can pass some additional fields to prefill:
    // 'suggested_capabilities[]': 'card_payments',
    // 'stripe_user[street_address]': req.user.address || undefined,
    // 'stripe_user[city]': req.user.city || undefined,
    // 'stripe_user[zip]': req.user.postalCode || undefined,
    // 'stripe_user[state]': req.user.city || undefined,
  });
  console.log("Starting Express flow:", parameters);
  console.log("Printing the body:", req.query);

  res.redirect(STRIPE_AUTHORIZE_URI + "?" + querystring.stringify(parameters));
});


app.get("/token", async (req, res) => {
  if (req.session.state !== req.query.state) {
    // eslint-disable-next-line max-len
    console.log(`Level 1 -> I cannot find the request session state ${req.session.uid}, ${req.session.state} and this is what was sent ${req.query.state}`);

    return res.redirect("https://aworanapp.com/fail");
  }
  try {
    const expressAuthorized = await request.post({uri: STRIPE_TOKEN_URI, form: {
      grant_type: "authorization_code",
      client_id: STRIPE_CLIENTID,
      client_secret: STRIPE_TEST_SK,
      code: req.query.code},
    json: true});

    if (expressAuthorized.error) {
      throw (expressAuthorized.error);
    }

    // eslint-disable-next-line max-len
    console.log(`This is the stripe account ID to be saved to firebase ${expressAuthorized.stripe_user_id} and the request body \n${req.query}`);
    // req.user.stripeAccountId = expressAuthorized.stripe_user_id;
    console.log(`Do I still have my UID? ${req.session.uid}`);

    if (req.session.uid !== undefined && req.session.uid !== null) {
      // eslint-disable-next-line max-len
      await db.doc(`/User/${req.session.uid}`).update({
        "accountID": expressAuthorized.stripe_user_id,
        "bSetupDone": true,
      });
    }

    res.redirect("https://flutterstripemerchant.page.link/successful");
  } catch (err) {
    console.log(`The Stripe onboarding process has not succeeded. ${err}`);
  }
});


exports.stripeapi = functions.https.onRequest(app);
