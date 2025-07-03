import 'package:flutter_test/flutter_test.dart';
import 'package:app/core/utils/deep_link_service.dart';

void main() {
  group('DeepLinkService', () {
    test('detects password-reset link and extracts token', () {
      final uri = Uri.parse(
        'myapp://reset?type=recovery&access_token=abc123&refresh_token=zzz',
      );

      expect(DeepLinkService.isPasswordReset(uri), isTrue);
      expect(DeepLinkService.extractAccessToken(uri), equals('abc123'));
    });

    test('returns false for non-recovery link', () {
      final uri = Uri.parse('myapp://other?foo=bar');
      expect(DeepLinkService.isPasswordReset(uri), isFalse);
      expect(DeepLinkService.extractAccessToken(uri), isNull);
    });
  });
}
