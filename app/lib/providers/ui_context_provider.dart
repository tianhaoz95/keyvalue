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
  bool _isSidebarExpanded = true;
  SidebarMode _sidebarMode = SidebarMode.ai;

  AppView get currentView => _currentView;
  String? get activeCustomerId => _activeCustomerId;
  bool get isSidebarExpanded => _isSidebarExpanded;
  SidebarMode get sidebarMode => _sidebarMode;

  void setView(AppView view, {String? customerId}) {
    _currentView = view;
    _activeCustomerId = customerId;
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
