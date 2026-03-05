import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../providers/ui_context_provider.dart';
import '../l10n/app_localizations.dart';

class PendingReviewList extends StatelessWidget {
  final List<Customer> customers;

  const PendingReviewList({super.key, required this.customers});

  @override
  Widget build(BuildContext context) {
    if (customers.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;
    final horizontalPadding = isCompact ? 16.0 : 24.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 32, horizontalPadding, 16),
          child: Text(
            l10n.pendingActions.toUpperCase(),
            style: TextStyle(
              fontSize: isCompact ? 10 : 12, 
              fontWeight: FontWeight.w900, 
              letterSpacing: 1.5, 
              color: Colors.grey
            ),
          ),
        ),
        SizedBox(
          height: isCompact ? 120 : 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: customers.length,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding - 8),
            itemBuilder: (context, index) {
              final customer = customers[index];
              return Container(
                width: isCompact ? 240 : 280,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                child: Card(
                  color: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: InkWell(
                    onTap: () {
                      context.read<UiContextProvider>().setView(
                        AppView.customerDetail,
                        customerId: customer.customerId,
                      );
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: EdgeInsets.all(isCompact ? 16.0 : 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.auto_awesome_outlined, color: Colors.white, size: isCompact ? 16 : 18),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  customer.name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: isCompact ? 14 : 16,
                                    letterSpacing: -0.2
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isCompact ? 8 : 12),
                          Text(
                            'PROACTIVE DRAFT READY',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: isCompact ? 8 : 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(height: isCompact ? 8 : 12),
                          Row(
                            children: [
                              Text(
                                l10n.reviewNow.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isCompact ? 10 : 11,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_forward, color: Colors.white, size: isCompact ? 10 : 12),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
