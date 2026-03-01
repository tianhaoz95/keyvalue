import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Asset Existence Tests', () {
    test('logo_icon.png exists in filesystem', () {
      final file = File('assets/images/logo_icon.png');
      expect(file.existsSync(), isTrue, reason: 'logo_icon.png should exist in assets/images/');
    });

    test('logo_120.png exists in filesystem', () {
      final file = File('assets/images/logo_120.png');
      expect(file.existsSync(), isTrue, reason: 'logo_120.png should exist in assets/images/');
    });

    test('logo_512.png exists in filesystem', () {
      final file = File('assets/images/logo_512.png');
      expect(file.existsSync(), isTrue, reason: 'logo_512.png should exist in assets/images/');
    });

    test('logo_cropped.png exists in filesystem', () {
      final file = File('assets/images/logo_cropped.png');
      expect(file.existsSync(), isTrue, reason: 'logo_cropped.png should exist in assets/images/');
    });

    testWidgets('logo_cropped.png can be loaded via rootBundle', (WidgetTester tester) async {
      try {
        await rootBundle.load('assets/images/logo_cropped.png');
      } catch (e) {
        fail('Failed to load assets/images/logo_cropped.png: $e');
      }
    });

    testWidgets('logo_512.png can be loaded via rootBundle', (WidgetTester tester) async {
      try {
        await rootBundle.load('assets/images/logo_512.png');
      } catch (e) {
        fail('Failed to load assets/images/logo_512.png: $e');
      }
    });

    testWidgets('logo_icon.png can be loaded via rootBundle', (WidgetTester tester) async {
      // This test ensures the asset is actually declared in pubspec.yaml and accessible
      try {
        await rootBundle.load('assets/images/logo_icon.png');
      } catch (e) {
        fail('Failed to load assets/images/logo_icon.png: $e');
      }
    });

    testWidgets('logo_120.png can be loaded via rootBundle', (WidgetTester tester) async {
      try {
        await rootBundle.load('assets/images/logo_120.png');
      } catch (e) {
        fail('Failed to load assets/images/logo_120.png: $e');
      }
    });
  });
}
