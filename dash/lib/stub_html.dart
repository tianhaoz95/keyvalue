// ignore_for_file: camel_case_types

class StubWindow {
  StubLocation get location => StubLocation();
}

class StubLocation {
  void reload() {}
}

final window = StubWindow();
