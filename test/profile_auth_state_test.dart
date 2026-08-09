import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flix_app/screens/profile_screen.dart';

void main() {
  testWidgets('khách chỉ thấy đăng nhập và không thấy đăng xuất',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
    await tester.pump();

    expect(find.text('Khách FLIX'), findsOneWidget);
    expect(find.text('Chưa đăng nhập'), findsOneWidget);
    expect(find.text('Đăng Xuất Tài Khoản'), findsNothing);
    expect(find.text('Đăng Nhập Tài Khoản'), findsOneWidget);
    expect(find.text('Chưa có tài khoản? Đăng ký ngay'), findsOneWidget);
    expect(find.byTooltip('Đổi ảnh đại diện'), findsNothing);
    expect(find.byTooltip('Đổi ảnh bìa'), findsNothing);
  });
}
