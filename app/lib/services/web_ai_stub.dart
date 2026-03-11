bool isWebOnline() => true;
Future<bool> isWebAiAvailable() async => false;
Future<String> getWebAiStatus() async => "Web AI not supported on this platform.";
Future<String> promptWebAi(String prompt) async => "Web AI not supported on this platform.";
