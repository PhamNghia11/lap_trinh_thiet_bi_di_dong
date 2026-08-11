import 'package:flix_app/core/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Flutter Web mặc định dùng backend Render HTTPS', () {
    expect(
      ApiClient.resolveBaseUrl(isWeb: true, configuredBaseUrl: ''),
      'https://lap-trinh-thiet-bi-di-dong.onrender.com/api/v1',
    );
  });

  test('Android local vẫn dùng địa chỉ emulator', () {
    expect(
      ApiClient.resolveBaseUrl(isWeb: false, configuredBaseUrl: ''),
      'http://10.0.2.2:3000/api/v1',
    );
  });

  test('FLIX_API_URL ghi đè fallback và bỏ dấu gạch chéo cuối', () {
    expect(
      ApiClient.resolveBaseUrl(
        isWeb: true,
        configuredBaseUrl: 'https://api.example.com/api/v1/',
      ),
      'https://api.example.com/api/v1',
    );
  });

  test('phản hồi máy chủ không hợp lệ được đổi thành lỗi dễ hiểu', () {
    expect(
      () => ApiClient.decodeResponseBody(
        '<html>Bad gateway</html>',
        statusCode: 502,
      ),
      throwsA(
        isA<ApiException>()
            .having((error) => error.statusCode, 'statusCode', 502)
            .having(
              (error) => error.message,
              'message',
              'Máy chủ đang tạm thời không ổn định. Vui lòng thử lại.',
            ),
      ),
    );
  });
}
