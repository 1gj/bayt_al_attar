import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bayt_al_attar/main.dart'; // تأكد أن هذا المسار يطابق اسم مشروعك

void main() {
  testWidgets('App renders correctly smoke test', (WidgetTester tester) async {
    // 1. بناء التطبيق باستخدام الاسم الصحيح AttaraApp
    await tester.pumpWidget(const AttaraApp());

    // 2. التحقق من أن التطبيق يبدأ (نبحث عن العنوان الرئيسي)
    // ملاحظة: بما أن التطبيق يستخدم Firebase، قد تحتاج لإعدادات إضافية للاختبارات الحقيقية
    // لكن هذا الكود يحل مشكلة الاسم MyApp.
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('عطارة بيت العطار'), findsOneWidget);
  });
}
