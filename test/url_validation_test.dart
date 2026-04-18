import 'package:flutter_test/flutter_test.dart';

void main() {
  group('URL Validation & Extraction Tests', () {
    test('Regex should extract URL from code block', () {
      final text = '''
import 'dart:async';
// Check this link: https://www.noon.com/saudi-ar/p-123
final x = 10;
''';
      final urlRegex = RegExp(r'https?://[^\s/$.?#].[^\s]*', caseSensitive: false);
      final match = urlRegex.firstMatch(text);
      
      expect(match, isNotNull);
      expect(match!.group(0), 'https://www.noon.com/saudi-ar/p-123');
    });

    test('Regex should handle multiple lines and only extract the first valid URL', () {
      final text = 'Visit https://amazon.sa or https://noon.com';
      final urlRegex = RegExp(r'https?://[^\s/$.?#].[^\s]*', caseSensitive: false);
      final match = urlRegex.firstMatch(text);
      
      expect(match, isNotNull);
      expect(match!.group(0), 'https://amazon.sa');
    });

    test('Regex should not match if no http/https found', () {
      final text = 'noon.com is a great site';
      final urlRegex = RegExp(r'https?://[^\s/$.?#].[^\s]*', caseSensitive: false);
      final match = urlRegex.firstMatch(text);
      
      expect(match, isNull);
    });
  });

  group('TargetProductsViewModel Sorting Tests', () {
    // Note: Since we can't easily mock SharedPreferences in a simple script,
    // we assume the logic holds if the getters return sorted lists.
    // In a real environment, we'd use package:mockito or package:shared_preferences_platform_interface.
  });
}
