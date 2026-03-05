import 'package:flutter/material.dart';

enum AppView {
  dashboard,
  customerDetail,
  addClient,
}

enum SidebarMode {
  ai,
  settings,
}

class UiContextProvider with ChangeNotifier {
  AppView _currentView = AppView.dashboard;
  String? _activeCustomerId;
  Map<String, dynamic>? _draftClientData;
  String? _activeDraftContext;
  String? _activeDraftEngagementId;
  bool _isSidebarExpanded = true;
  SidebarMode _sidebarMode = SidebarMode.ai;

  AppView get currentView => _currentView;
  String? get activeCustomerId => _activeCustomerId;
  Map<String, dynamic>? get draftClientData => _draftClientData;
  String? get activeDraftContext => _activeDraftContext;
  String? get activeDraftEngagementId => _activeDraftEngagementId;
  bool get isSidebarExpanded => _isSidebarExpanded;
  SidebarMode get sidebarMode => _sidebarMode;

  void setView(AppView view, {String? customerId, Map<String, dynamic>? draftData}) {
    _currentView = view;
    _activeCustomerId = customerId;
    _draftClientData = draftData;
    notifyListeners();
  }

  void setDraftContext(String? context, String? engagementId) {
    _activeDraftContext = context;
    _activeDraftEngagementId = engagementId;
    notifyListeners();
  }

  void clearDraftContext() {
    _activeDraftContext = null;
    _activeDraftEngagementId = null;
    notifyListeners();
  }

  void clearDraftData() {
    _draftClientData = null;
    notifyListeners();
  }

  void toggleSidebar() {
    _isSidebarExpanded = !_isSidebarExpanded;
    notifyListeners();
  }

  void setSidebarExpanded(bool expanded) {
    _isSidebarExpanded = expanded;
    notifyListeners();
  }

  void setSidebarMode(SidebarMode mode) {
    if (_sidebarMode == mode && _isSidebarExpanded) {
      _isSidebarExpanded = false;
    } else {
      _sidebarMode = mode;
      _isSidebarExpanded = true;
    }
    notifyListeners();
  }
  
  Map<String, dynamic> toAiContext() {
    return {
      'currentView': _currentView.toString().split('.').last.toUpperCase(),
      'activeCustomerId': _activeCustomerId,
      'isSidebarExpanded': _isSidebarExpanded,
      'sidebarMode': _sidebarMode.toString().split('.').last.toUpperCase(),
    };
  }
}
