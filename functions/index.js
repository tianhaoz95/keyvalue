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
    // let userDoc = await admin.firestore().collection('advisors').doc(uid).get();
    // let stripeCustomerId = userDoc.data().stripeCustomerId;
    
    // IF NO stripeCustomerId, create one:
    // const customer = await stripe.customers.create({ email: data.email, metadata: { firebaseUid: uid } });
    // stripeCustomerId = customer.id;

    // TODO: 2. Attach the PaymentMethod to the Stripe Customer
    // if (data.paymentMethodId) {
    //   await stripe.paymentMethods.attach(data.paymentMethodId, { customer: stripeCustomerId });
    //   await stripe.customers.update(stripeCustomerId, {
    //     invoice_settings: { default_payment_method: data.paymentMethodId },
    //   });
    // }

    // TODO: 3. Update the user's billing info in Firestore
    // await admin.firestore().collection('advisors').doc(uid).set({
    //   stripeCustomerId: stripeCustomerId,
    //   cardHolderName: data.cardHolderName,
    //   zipCode: data.zipCode,
    // }, { merge: true });

    return {
      status: "success",
      message: "Billing information updated successfully (simulated).",
      stripeCustomerId: "cus_mock_123" // Placeholder
    };
  } catch (error) {
    logger.error("Error updating billing info:", error);
    return {
      status: "error",
      message: error.message,
    };
  }
});

/**
 * Creates a Stripe Subscription for the user.
 */
exports.createSubscription = onCall(async (request) => {
  if (!request.auth) {
    throw new Error("The function must be called while authenticated.");
  }

  const data = request.data;
  const uid = request.auth.uid;
  const planId = data.planId; // e.g., 'pro_monthly'

  logger.info(`Creating subscription for user ${uid} to plan ${planId}`);

  try {
    // TODO: 1. Get user's stripeCustomerId from Firestore
    // const userDoc = await admin.firestore().collection('advisors').doc(uid).get();
    // const stripeCustomerId = userDoc.data().stripeCustomerId;

    // if (!stripeCustomerId) throw new Error("Customer has no billing information setup.");

    // TODO: 2. Create Stripe Subscription
    // const subscription = await stripe.subscriptions.create({
    //   customer: stripeCustomerId,
    //   items: [{ price: 'PRICE_ID_FROM_STRIPE' }],
    //   payment_behavior: 'default_incomplete',
    //   payment_settings: { save_default_payment_method: 'on_subscription' },
    //   expand: ['latest_invoice.payment_intent'],
    // });

    // TODO: 3. Store subscription details in Firestore
    // await admin.firestore().collection('advisors').doc(uid).update({
    //   subscriptionId: subscription.id,
    //   subscriptionStatus: subscription.status,
    // });

    return {
      status: "success",
      subscriptionId: "sub_mock_123", // Placeholder
      // clientSecret: subscription.latest_invoice.payment_intent.client_secret,
      clientSecret: "pi_mock_123_secret_mock_456" // Placeholder
    };
  } catch (error) {
    logger.error("Error creating subscription:", error);
    return {
      status: "error",
      message: error.message,
    };
  }
});

/**
 * Stripe Webhook simulator for local testing.
 * In production, Stripe would call a real webhook endpoint.
 */
exports.simulateStripeWebhook = onCall(async (request) => {
  if (!request.auth) {
    throw new Error("The function must be called while authenticated.");
  }

  const {type, subscriptionId} = request.data;
  const uid = request.auth.uid;

  logger.info(`Simulating webhook ${type} for subscription ${subscriptionId}`);

  if (type === 'invoice.paid') {
    await admin.firestore().collection('advisors').doc(uid).set({
      subscriptionStatus: 'active',
      nextBillingDate: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 30 * 24 * 60 * 60 * 1000))
    }, {merge: true});
  }

  return { status: "success" };
});
