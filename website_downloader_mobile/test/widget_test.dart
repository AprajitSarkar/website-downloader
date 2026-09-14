import 'package:flutter_test/flutter_test.dart';
import 'package:website_downloader_mobile/main.dart';

void main() {
  testWidgets('WebsiteDownloaderApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const WebsiteDownloaderApp());
    expect(find.text('Website Downloader'), findsOneWidget);
    expect(find.text('Offline Vault'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
