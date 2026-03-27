import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class BillingService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Refreshes the user's billing information using Stripe.
  Future<void> updateBillingInformation({
    required CardDetails cardDetails,
    required String billingEmail,
  }) async {
    try {
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(
              email: billingEmail,
            ),
          ),
        ),
      );

      final result = await _functions.httpsCallable('updateUserBilling').call({
        'paymentMethodId': paymentMethod.id,
        'email': billingEmail,
      });

      if (result.data['status'] != 'success') {
        throw Exception(result.data['message'] ?? 'Failed to update billing info.');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Creates a subscription and handles SCA if necessary.
  Future<String> createSubscription(String planId) async {
    try {
      final result = await _functions.httpsCallable('createSubscription').call({
        'planId': planId,
      });

      if (result.data['status'] != 'success') {
        throw Exception(result.data['message'] ?? 'Failed to create subscription.');
      }

      final clientSecret = result.data['clientSecret'];
      final subscriptionId = result.data['subscriptionId'];

      // If clientSecret is provided, it might need SCA confirmation
      if (clientSecret != null && !clientSecret.startsWith('pi_mock')) {
        await Stripe.instance.confirmPayment(
          paymentIntentClientSecret: clientSecret,
        );
      }

      return subscriptionId;
    } catch (e) {
      rethrow;
    }
  }

  /// Webhook simulator for local testing
  Future<void> simulatePaymentSuccess(String subscriptionId) async {
    await _functions.httpsCallable('simulateStripeWebhook').call({
      'type': 'invoice.paid',
      'subscriptionId': subscriptionId,
    });
  }

  Future<void> notifyBillingChange(Map<String, dynamic> data) async {
    await _functions.httpsCallable('updateUserBilling').call(data);
  }
}
