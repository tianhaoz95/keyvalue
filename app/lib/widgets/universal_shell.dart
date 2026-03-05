import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:feedback/feedback.dart';
import '../providers/ui_context_provider.dart';
import '../providers/advisor_provider.dart';
import '../providers/chat_provider.dart';
import '../screens/dashboard_view.dart';
import '../screens/customer_detail_view.dart';
import '../screens/settings_view.dart';
import '../screens/add_client_view.dart';
import 'chat_view.dart';

class UniversalShell extends StatelessWidget {
  const UniversalShell({super.key});

  @override
  Widget build(BuildContext context) {
    final uiContext = Provider.of<UiContextProvider>(context);
    final advisorProvider = Provider.of<AdvisorProvider>(context);
    final chatProvider = Provider.of<GlobalChatProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isMobile = screenWidth < 600;
    
    if (advisorProvider.currentAdvisor == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return PopScope(
      canPop: uiContext.currentView == AppView.dashboard && !uiContext.isSidebarExpanded,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (uiContext.isSidebarExpanded) {
          uiContext.setSidebarExpanded(false);
          return;
        }
        if (uiContext.currentView != AppView.dashboard) {
          uiContext.setView(AppView.dashboard);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              color: const Color(0xFFEEEEEE),
              height: 1.0,
            ),
          ),
          title: GestureDetector(
            onTap: () {
              uiContext.setSidebarExpanded(false);
              uiContext.setView(AppView.dashboard);
            },
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/images/logo_120.png',
                    height: 24,
                    color: Colors.black,
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 12),
                    Text(
                      advisorProvider.currentAdvisor?.firmName ?? 'KeyValue',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            if (isMobile)
              IconButton(
                icon: const Icon(Icons.feedback_outlined, size: 20),
                tooltip: 'Feedback',
                onPressed: () {
                  BetterFeedback.of(context).show((feedback) {
                    advisorProvider.submitFeedback(feedback.text, uiContext.currentView.name);
                  });
                },
              )
            else
              TextButton.icon(
                onPressed: () {
                  BetterFeedback.of(context).show((feedback) {
                    advisorProvider.submitFeedback(feedback.text, uiContext.currentView.name);
                  });
                },
                icon: const Icon(Icons.feedback_outlined, size: 18),
                label: const Text('FEEDBACK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                style: TextButton.styleFrom(foregroundColor: Colors.black),
              ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(uiContext.sidebarMode == SidebarMode.settings && uiContext.isSidebarExpanded 
                  ? Icons.settings : Icons.settings_outlined, size: 22),
              tooltip: 'Settings',
              onPressed: () => uiContext.setSidebarMode(SidebarMode.settings),
            ),
            IconButton(
              icon: Icon(uiContext.sidebarMode == SidebarMode.ai && uiContext.isSidebarExpanded 
                  ? Icons.auto_awesome : Icons.auto_awesome_outlined, size: 22),
              tooltip: uiContext.isSidebarExpanded ? 'Hide Sidebar' : 'Show AI Sidebar',
              onPressed: () => uiContext.setSidebarMode(SidebarMode.ai),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Stack(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Selector<UiContextProvider, (AppView, String?)>(
                    selector: (_, ui) => (ui.currentView, ui.activeCustomerId),
                    builder: (context, data, _) {
                      return _buildMainPort(uiContext, advisorProvider);
                    },
                  ),
                ),
                if (isDesktop && uiContext.isSidebarExpanded) ...[
                  const VerticalDivider(width: 1),
                  SizedBox(
                    width: 400,
                    child: _buildSidebar(uiContext, chatProvider),
                  ),
                ],
              ],
            ),
            // Mobile Sidebar Overlay
            if (!isDesktop && uiContext.isSidebarExpanded) ...[
              GestureDetector(
                onTap: () => uiContext.setSidebarExpanded(false),
                child: Container(
                  color: Colors.black.withOpacity(0.3),
                ),
              ),
              Positioned(
                top: 0,
                bottom: 0,
                right: 0,
                width: isMobile ? screenWidth * 0.85 : 400,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(-2, 0),
                      ),
                    ],
                  ),
                  child: _buildSidebar(uiContext, chatProvider),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar(UiContextProvider uiContext, GlobalChatProvider chatProvider) {
    if (uiContext.sidebarMode == SidebarMode.settings) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.settings_outlined, size: 16),
                    SizedBox(width: 8),
                    Text('SETTINGS', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                  onPressed: () => uiContext.setSidebarExpanded(false),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          const Expanded(child: SettingsView()),
        ],
      );
    }
    return KeyValueChatView(provider: chatProvider);
  }

  Widget _buildMainPort(UiContextProvider uiContext, AdvisorProvider advisorProvider) {
    switch (uiContext.currentView) {
      case AppView.dashboard:
        return const DashboardView(); 
      case AppView.customerDetail:
        if (uiContext.activeCustomerId == null) return const DashboardView();
        try {
          final customer = advisorProvider.customers.firstWhere((c) => c.customerId == uiContext.activeCustomerId);
          return CustomerDetailView(customer: customer);
        } catch (e) {
          return const DashboardView();
        }
      case AppView.addClient:
        return const AddClientView();
    }
  }
}
