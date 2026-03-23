import 'dart:js_interop';
import 'dart:async';

@JS('window.navigator.onLine')
external bool get _navigatorOnLine;

@JS('window.ai')
external JSObject? get _windowAi;

@JS('LanguageModel')
external JSObject? get _globalLanguageModel;

@JS()
@staticInterop
class _AiObject {}

extension _AiObjectExtension on _AiObject {
  @JS('languageModel')
  external JSObject? get languageModel;
  
  @JS('assistant')
  external JSObject? get assistant;

  // Legacy
  @JS('canCreateTextSession')
  external JSPromise? _canCreateTextSession();
}

@JS()
@staticInterop
class _LanguageModelFactory {}

extension _LanguageModelFactoryExtension on _LanguageModelFactory {
  @JS('capabilities')
  external JSPromise? _capabilities();
  
  @JS('availability')
  external JSPromise? _availability();
  
  @JS('create')
  external JSPromise _create(JSObject? options);
}

@JS()
@staticInterop
class _AiCapabilities {}

extension _AiCapabilitiesExtension on _AiCapabilities {
  @JS('available')
  external JSString get available;
}

@JS()
@staticInterop
class _AiSession {}

extension _AiSessionExtension on _AiSession {
  @JS('prompt')
  external JSPromise _prompt(String text);
  
  @JS('execute')
  external JSPromise? _execute(String text);
}

bool isWebOnline() => _navigatorOnLine;

Future<String> getWebAiStatus() async {
  // 1. Try Global LanguageModel (User reported)
  final glm = _globalLanguageModel;
  if (glm != null) {
    try {
      final factory = glm as _LanguageModelFactory;
      final availabilityFn = factory._availability();
      if (factory._availability() != null) {
        final result = await availabilityFn!.toDart;
        return 'AVAILABLE (${(result as JSString).toDart.toUpperCase()})';
      }
    } catch (e) {
      // Fall through
    }
  }

  final aiObj = _windowAi;
  if (aiObj == null) return glm != null ? 'AVAILABLE (FOUND GLOBAL)' : 'UNAVAILABLE (window.ai missing)';
  
  try {
    final ai = aiObj as _AiObject;
    
    // 2. Try languageModel
    final lm = ai.languageModel;
    if (lm != null) {
      final factory = lm as _LanguageModelFactory;
      
      // Try availability() first (user reported)
      final availabilityFn = factory._availability();
      if (availabilityFn != null) {
        final result = await availabilityFn.toDart;
        return 'AVAILABLE (${(result as JSString).toDart.toUpperCase()})';
      }

      // Try capabilities() (Explainer version)
      final capabilitiesFn = factory._capabilities();
      if (capabilitiesFn != null) {
        final capabilities = await capabilitiesFn.toDart as _AiCapabilities;
        return 'AVAILABLE (${capabilities.available.toDart.toUpperCase()})';
      }
    }
    
    // 3. Try assistant
    final assistant = ai.assistant;
    if (assistant != null) {
      final factory = assistant as _LanguageModelFactory;
      final capabilitiesFn = factory._capabilities();
      if (capabilitiesFn != null) {
        final capabilities = await capabilitiesFn.toDart as _AiCapabilities;
        return 'AVAILABLE (${capabilities.available.toDart.toUpperCase()})';
      }
    }

    // 4. Legacy
    final canCreateFn = ai._canCreateTextSession();
    if (canCreateFn != null) {
      final canCreate = await canCreateFn.toDart;
      return 'AVAILABLE (${(canCreate as JSString).toDart.toUpperCase()})';
    }
    
    return 'UNAVAILABLE (API structure unknown)';
  } catch (e) {
    return 'ERROR: $e';
  }
}

Future<bool> isWebAiAvailable() async {
  final status = await getWebAiStatus();
  return status.contains('READILY') || status.contains('(AVAILABLE)');
}

Future<String> promptWebAi(String prompt) async {
  try {
    _AiSession? session;
    
    // 1. Try Global LanguageModel
    final glm = _globalLanguageModel;
    if (glm != null) {
      try {
        final factory = glm as _LanguageModelFactory;
        final result = await factory._create(null).toDart;
        session = result as _AiSession?;
      } catch (e) { /* Fall through */ }
    }

    if (session == null && _windowAi != null) {
      final ai = _windowAi as _AiObject;
      
      final lm = ai.languageModel;
      if (lm != null) {
        final result = await (lm as _LanguageModelFactory)._create(null).toDart;
        session = result as _AiSession?;
      } else if (ai.assistant != null) {
        final result = await (ai.assistant as _LanguageModelFactory)._create(null).toDart;
        session = result as _AiSession?;
      }
    }

    if (session == null) return "Web AI not available or failed to initialize.";

    final activeSession = session;
    try {
      final response = await activeSession._prompt(prompt).toDart;
      return (response as JSString).toDart;
    } catch (e) {
      final executeFn = activeSession._execute(prompt);
      if (executeFn != null) {
        final response = await executeFn.toDart;
        return (response as JSString).toDart;
      }
      rethrow;
    }
  } catch (e) {
    return "Error calling Web AI: $e";
  }
}
