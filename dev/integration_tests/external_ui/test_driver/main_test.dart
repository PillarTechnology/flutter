// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'package:flutter_driver/flutter_driver.dart';
import 'package:test/test.dart';

final RegExp calibrationRegExp = new RegExp('Flutter frame rate is (.*)fps');
final RegExp statsRegExp = new RegExp('Produced: (.*)fps\nConsumed: (.*)fps\nWidget builds: (.*)');
const Duration samplingTime = const Duration(seconds: 3);

Future<Null> main() async {
  group('texture suite', () {
    FlutterDriver driver;

    setUpAll(() async {
      driver = await FlutterDriver.connect();
      // TODO(mravn): the following pause appears necessary on iOS to avoid
      // inflating elements too early (when there is no size).
      await new Future<Null>.delayed(const Duration(seconds: 1));
    });

    test('texture rendering', () async {
      final SerializableFinder fab = find.byValueKey('fab');
      final SerializableFinder summary = find.byValueKey('summary');

      // Wait for calibration to complete and fab to appear.
      await driver.waitFor(fab, timeout: const Duration(seconds: 10));

      final String calibrationResult = await driver.getText(summary);
      final Match matchCalibration = calibrationRegExp.matchAsPrefix(calibrationResult);
      expect(matchCalibration, isNotNull);
      final double flutterFrameRate = double.parse(matchCalibration.group(1));

      // Texture frame stats at 0.5x Flutter frame rate
      await driver.tap(fab);
      await new Future<Null>.delayed(samplingTime);
      await driver.tap(fab);

      final String statsSlow = await driver.getText(summary);
      final Match matchSlow = statsRegExp.matchAsPrefix(statsSlow);
      expect(matchSlow, isNotNull);
      expect(double.parse(matchSlow.group(1)), closeTo(flutterFrameRate / 2.0, 5.0));
      expect(double.parse(matchSlow.group(2)), closeTo(flutterFrameRate / 2.0, 5.0));
      expect(int.parse(matchSlow.group(3)), 1);

      // Texture frame stats at 2.0x Flutter frame rate
      await driver.tap(fab);
      await new Future<Null>.delayed(samplingTime);
      await driver.tap(fab);

      final String statsFast = await driver.getText(summary);
      final Match matchFast = statsRegExp.matchAsPrefix(statsFast);
      expect(matchFast, isNotNull);
      expect(double.parse(matchFast.group(1)), closeTo(flutterFrameRate * 2.0, 10.0));
      expect(double.parse(matchFast.group(2)), closeTo(flutterFrameRate, 10.0));
      expect(int.parse(matchFast.group(3)), 1);
    });

    tearDownAll(() async {
      driver?.close();
    });
  });
}
