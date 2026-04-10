import 'package:flutter/material.dart';

ThemeData buildLightTheme(Color seedColor) {
  return ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
  );
}

ThemeData buildDarkTheme(Color seedColor, {required bool pureBlack}) {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  );
  if (!pureBlack) return base;

  const pure = Colors.black;
  const containerHigh = Color(0xFF0D0D0D);
  const containerHighest = Color(0xFF141414);

  final cs = base.colorScheme.copyWith(
    surface: pure,
    surfaceDim: pure,
    surfaceContainerLowest: pure,
    surfaceContainerLow: pure,
    surfaceContainer: pure,
    surfaceContainerHigh: containerHigh,
    surfaceContainerHighest: containerHighest,
  );

  return base.copyWith(
    colorScheme: cs,
    scaffoldBackgroundColor: pure,
    canvasColor: pure,
    cardColor: containerHigh,
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: pure,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: base.dialogTheme.copyWith(backgroundColor: containerHighest),
    bottomSheetTheme: base.bottomSheetTheme.copyWith(backgroundColor: pure),
  );
}
