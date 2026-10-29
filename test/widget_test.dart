
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:nguyenquanghuy_23805614880/main.dart';

void main() {
  testWidgets('Kiem tra giao dien dang nhap cham cong', (tester) async {
    await tester.pumpWidget(const ChamCongApp());

    expect(find.text('CHẤM CÔNG NHÓM 6'), findsOneWidget);
    expect(find.text('ĐĂNG NHẬP'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
