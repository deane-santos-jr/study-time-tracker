import 'package:flutter/material.dart';

const Color kPrimaryBase = Color(0xff5B5FE9);
const Color kPrimary400 = Color(0xff7A7EF0);
const Color kPrimary100 = Color(0xffEDEEFD);

const Color kSuccessBase = Color(0xff0CAF60);
const Color kErrorBase = Color(0xffE03137);
const Color kWarningBase = Color(0xffFFB020);

const Color kGray50 = Color(0xffFAFAFA);
const Color kGray100 = Color(0xffF4F5F7);
const Color kGray200 = Color(0xffE9EAEC);
const Color kGray300 = Color(0xffD0D3D9);
const Color kGray500 = Color(0xff8A8F98);
const Color kGray700 = Color(0xff323B49);
const Color kGray900 = Color(0xff111827);

const Color kWhite = Color(0xffFFFFFF);

const double kRadiusSm = 6.0;
const double kRadiusMd = 10.0;
const double kRadiusLg = 12.0;

final ThemeData defaultTheme = _createDefaultLightTheme();

ThemeData _createDefaultLightTheme() {
  final base = ThemeData.light();
  return base.copyWith(
    visualDensity: VisualDensity.adaptivePlatformDensity,
    scaffoldBackgroundColor: kWhite,
    primaryColor: kPrimaryBase,
    colorScheme: ColorScheme.fromSeed(seedColor: kPrimaryBase),
  );
}
