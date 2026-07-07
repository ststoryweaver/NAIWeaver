import 'package:flutter_test/flutter_test.dart';
import 'package:naiweaver/core/utils/nai_filename.dart';

void main() {
  test('matches the NAI format from issue #28 exactly', () {
    final base = naiFilenameBase(
      '2::1girl::, long hair, 2::black hair::, artist:test, painting (medium)',
      '12345678',
    );
    expect(
      base,
      '2__1girl__, long hair, 2__black hair__, artist_test, '
      'painting (medium) s-12345678',
    );
  });

  test('preserves case, spaces, commas, and parentheses', () {
    expect(
      naiFilenameBase('Masterpiece, Best Quality (photo)', '1'),
      'Masterpiece, Best Quality (photo) s-1',
    );
  });

  test('preserves curly/square emphasis brackets', () {
    expect(
      naiFilenameBase('{{1girl}}, [background]', '42'),
      '{{1girl}}, [background] s-42',
    );
  });

  test('handles negative and fractional numerical emphasis', () {
    expect(
      naiFilenameBase('-1::glasses::, 1.5::smile::', '7'),
      '-1__glasses__, 1.5__smile__ s-7',
    );
  });

  test('replaces each illegal character with one underscore', () {
    expect(
      naiFilenameBase(r'a<b>c:d"e/f\g|h?i*j', '9'),
      'a_b_c_d_e_f_g_h_i_j s-9',
    );
  });

  test('strips ASCII control characters', () {
    expect(naiFilenameBase('a\nb\tc', '3'), 'a_b_c s-3');
  });

  test('truncates the prompt portion, not the seed', () {
    final longPrompt = 'a' * 500;
    final base = naiFilenameBase(longPrompt, '12345678');
    expect(base, '${'a' * naiFilenamePromptMaxLength} s-12345678');
  });

  test('trims trailing dots and spaces (Windows-illegal)', () {
    expect(naiFilenameBase('1girl, solo...', '5'), '1girl, solo s-5');
    expect(naiFilenameBase('1girl,   ', '5'), '1girl, s-5');
  });

  test('falls back to bare seed when the prompt sanitizes to nothing', () {
    expect(naiFilenameBase('...', '99'), 's-99');
    expect(naiFilenameBase('', '99'), 's-99');
  });

  test('returns the bare prompt when the seed is empty', () {
    expect(naiFilenameBase('1girl', ''), '1girl');
  });
}
