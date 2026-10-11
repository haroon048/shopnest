import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopnest/app.dart';

void main() {
  testWidgets('ShopNest main starts the onboarding flow', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const ShopNestApp());

    expect(find.text('ShopNest'), findsOneWidget);
    expect(find.text('Shop Smart, Live Better.'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 2500));
    await tester.pumpAndSettle();

    expect(find.text('Shop Everything You Love'), findsOneWidget);
  });
}
