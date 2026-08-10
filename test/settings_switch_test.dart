import 'package:flix_app/core/app_preferences.dart';
import 'package:flix_app/screens/settings_screen.dart';
import 'package:flix_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('settings switches keep a contrasting thumb when enabled',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.instance.load();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme(),
        home: const SettingsScreen(),
      ),
    );
    await tester.pump();

    final switches = tester.widgetList<SwitchListTile>(
      find.byType(SwitchListTile),
    );
    expect(switches, isNotEmpty);
    expect(switches.every((tile) => tile.activeThumbColor == null), isTrue);

    final selectedThumb = Theme.of(
      tester.element(find.byType(SettingsScreen)),
    ).switchTheme.thumbColor!.resolve({WidgetState.selected});
    expect(selectedThumb, Colors.white);
  });
}
