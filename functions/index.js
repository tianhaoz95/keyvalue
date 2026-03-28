const {onRequest, onCall} = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

// Basic Hello World function to verify local infrastructure
exports.helloWorld = onRequest((request, response) => {
  logger.info("Hello logs!", {structuredData: true});
  response.send("Hello from Firebase!");
});

/**
 * Handles user billing information changes.
 * This function should integrate with Stripe API to update customer details
 * and update the user's document in Firestore.
 */
exports.updateUserBilling = onCall(async (request) => {
  // Check if user is authenticated
  if (!request.auth) {
    throw new Error("The function must be called while authenticated.");
  }

  const data = request.data;
  const uid = request.auth.uid;

  logger.info(`Updating billing for user ${uid}`, {data});

  try {
    // TODO: Initialize Stripe with your secret key
    // const stripe = require('stripe')('sk_test_...');

    // TODO: 1. Retrieve or create Stripe Customer ID for this user from Firestore
    // const userDoc = await admin.firestore().collection('advisors').doc(uid).get();
    // let stripeCustomerId = userDoc.data().stripeCustomerId;

    // TODO: 2. Attach the PaymentMethod to the Stripe Customer
    // if (data.paymentMethodId) {
    //   await stripe.paymentMethods.attach(data.paymentMethodId, { customer: stripeCustomerId });
    //   await stripe.customers.update(stripeCustomerId, {
    //     invoice_settings: { default_payment_method: data.paymentMethodId },
    //   });
    // }

    // TODO: 3. Update the user's billing info in Firestore
    // await admin.firestore().collection('advisors').doc(uid).update({
    //   cardHolderName: data.cardHolderName,
    //   zipCode: data.zipCode,
    //   // last4: ..., brand: ..., etc.
    // });

    return {
      status: "success",
      message: "Billing information updated successfully (simulated).",
    };
  } catch (error) {
    logger.error("Error updating billing info:", error);
    return {
      status: "error",
      message: error.message,
    };
  }
});
