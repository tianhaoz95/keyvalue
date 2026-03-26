import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

class BillingService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Refreshes the user's billing information using Stripe.
  /// This creates a payment method and then calls a Cloud Function
  /// to update the user's billing profile on the backend.
  Future<void> updateBillingInformation({
    required CardDetails cardDetails,
    required String billingEmail,
  }) async {
    try {
      // 1. Create a Payment Method via Stripe SDK
      // Note: In a real production app, you might use Stripe's CardField or PaymentSheet
      // but for this refactor we'll show the mechanism of tokenizing/creating a PM.
      final paymentMethod = await Stripe.instance.createPaymentMethod(
        params: PaymentMethodParams.card(
          paymentMethodData: PaymentMethodData(
            billingDetails: BillingDetails(
              email: billingEmail,
            ),
          ),
        ),
      );

      // 2. Call the Firebase Cloud Function to handle the billing change
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

  /// Simple version that just calls the function if you already have a payment method
  /// or if you're using Stripe's native UI elements that handle the PM creation.
  Future<void> notifyBillingChange(Map<String, dynamic> data) async {
    await _functions.httpsCallable('updateUserBilling').call(data);
  }
}
