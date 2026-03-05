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

enum AiEditContextType {
  draft,
  profile,
  guidelines,
}

class AiEditContext {
  final AiEditContextType type;
  final String content;
  final String? engagementId; // For draft type

  AiEditContext({required this.type, required this.content, this.engagementId});
}

class UiContextProvider with ChangeNotifier {
  AppView _currentView = AppView.dashboard;
  String? _activeCustomerId;
  Map<String, dynamic>? _draftClientData;
  AiEditContext? _activeEditContext;
  bool _isSidebarExpanded = true;
  SidebarMode _sidebarMode = SidebarMode.ai;

  AppView get currentView => _currentView;
  String? get activeCustomerId => _activeCustomerId;
  Map<String, dynamic>? get draftClientData => _draftClientData;
  AiEditContext? get activeEditContext => _activeEditContext;
  bool get isSidebarExpanded => _isSidebarExpanded;
  SidebarMode get sidebarMode => _sidebarMode;

  void setView(AppView view, {String? customerId, Map<String, dynamic>? draftData}) {
    _currentView = view;
    _activeCustomerId = customerId;
    _draftClientData = draftData;
    notifyListeners();
  }

  void setEditContext(AiEditContext? context) {
    _activeEditContext = context;
    notifyListeners();
  }

  void setAiEditMode(AiEditContext context) {
    _activeEditContext = context;
    _sidebarMode = SidebarMode.ai;
    _isSidebarExpanded = true;
    notifyListeners();
  }

  void clearEditContext() {
    _activeEditContext = null;
    notifyListeners();
  }

  // Backwards compatibility
  String? get activeDraftContext => _activeEditContext?.type == AiEditContextType.draft ? _activeEditContext?.content : null;
  String? get activeDraftEngagementId => _activeEditContext?.type == AiEditContextType.draft ? _activeEditContext?.engagementId : null;
  
  void setDraftContext(String? context, String? engagementId) {
    if (context == null) {
      clearEditContext();
    } else {
      setEditContext(AiEditContext(type: AiEditContextType.draft, content: context, engagementId: engagementId));
    }
  }

  void clearDraftContext() => clearEditContext();

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
