import 'package:flutter_test/flutter_test.dart';

import 'package:appm3ak/core/utils/profile_photo_rules.dart';

void main() {
  const base = 'https://api.example.com';

  group('resolveProfilePhotoDisplayUrl', () {
    test('empty', () {
      expect(resolveProfilePhotoDisplayUrl(null, base), '');
      expect(resolveProfilePhotoDisplayUrl('', base), '');
      expect(resolveProfilePhotoDisplayUrl('   ', base), '');
    });

    test('absolute URLs unchanged', () {
      expect(
        resolveProfilePhotoDisplayUrl('https://lh3.googleusercontent.com/a/abc', base),
        'https://lh3.googleusercontent.com/a/abc',
      );
      expect(
        resolveProfilePhotoDisplayUrl('http://cdn.example/x.png', base),
        'http://cdn.example/x.png',
      );
    });

    test('uploads/ prefix', () {
      expect(
        resolveProfilePhotoDisplayUrl('uploads/profile-uuid.jpg', base),
        'https://api.example.com/uploads/profile-uuid.jpg',
      );
    });

    test('base URL trailing slash stripped', () {
      expect(
        resolveProfilePhotoDisplayUrl('uploads/p.webp', 'https://api.example.com/'),
        'https://api.example.com/uploads/p.webp',
      );
    });

    test('legacy bare filename', () {
      expect(
        resolveProfilePhotoDisplayUrl('photo.jpg', base),
        'https://api.example.com/uploads/photo.jpg',
      );
    });
  });
}
