import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/main_navigation_bar.dart';
import 'home_page.dart';
import 'whitelist_page.dart';
import 'settings_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  WhitelistPage? _whitelistPage;
  final _whitelistKey = GlobalKey<WhitelistPageState>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentIndex == 1) {
          final state = _whitelistKey.currentState;
          if (state != null && state.handleBackPressed()) return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: [
            const HomePage(),
            _whitelistPage ??= WhitelistPage(key: _whitelistKey),
            const SettingsPage(),
          ],
        ),
        bottomNavigationBar: MainNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            FocusScope.of(context).unfocus();
            if (index == 1 && _whitelistPage == null) {
              setState(() {
                _whitelistPage = WhitelistPage(key: _whitelistKey);
                _currentIndex = index;
              });
            } else {
              setState(() => _currentIndex = index);
            }
          },
        ),
      ),
    );
  }
}
