import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class LottieColorShift {
  static final HSLColor baseColor = HSLColor.fromColor(const Color(0xFFBA0202));

  static Future<String> shiftLottieHue(String assetPath, Color targetColor) async {
    final String jsonStr = await rootBundle.loadString(assetPath);
    
    if (targetColor.toARGB32() == const Color(0xFFBA0202).toARGB32()) {
      return jsonStr;
    }

    final HSLColor targetHsl = HSLColor.fromColor(targetColor);
    final double hueShift = targetHsl.hue - baseColor.hue;
    final double satScale = targetHsl.saturation / baseColor.saturation;

    final dynamic data = jsonDecode(jsonStr);
    
    _walkAndShift(data, hueShift, satScale);

    return jsonEncode(data);
  }

  static void _walkAndShift(dynamic node, double hueShift, double satScale) {
    if (node is Map) {
      node.forEach((key, value) {
        if (value is List) {
          _processList(value, hueShift, satScale);
        } else if (value is Map) {
          _walkAndShift(value, hueShift, satScale);
        }
      });
    } else if (node is List) {
      _processList(node, hueShift, satScale);
    }
  }

  static void _processList(List list, double hueShift, double satScale) {
    if (list.isNotEmpty && list.every((e) => e is num)) {
      if (list.length == 4 && _isValidColor(list)) {
        _shiftRgbaList(list, hueShift, satScale);
      } else if (list.length >= 4 && list.length % 4 == 0) {
        for (int i = 0; i < list.length; i += 4) {
          if (_isValidRgb(list[i+1], list[i+2], list[i+3])) {
            _shiftRgbElements(list, i+1, i+2, i+3, hueShift, satScale);
          }
        }
      }
    } else {
      for (var element in list) {
        if (element is Map || element is List) {
          _walkAndShift(element, hueShift, satScale);
        }
      }
    }
  }

  static bool _isValidColor(List list) {
    for (int i = 0; i < 4; i++) {
      num val = list[i];
      if (val < 0.0 || val > 1.0) return false;
    }
    return true;
  }
  
  static bool _isValidRgb(num r, num g, num b) {
    return r >= 0.0 && r <= 1.0 && g >= 0.0 && g <= 1.0 && b >= 0.0 && b <= 1.0;
  }

  static void _shiftRgbaList(List list, double hueShift, double satScale) {
    _shiftRgbElements(list, 0, 1, 2, hueShift, satScale);
  }

  static void _shiftRgbElements(List list, int rIdx, int gIdx, int bIdx, double hueShift, double satScale) {
    num r = list[rIdx];
    num g = list[gIdx];
    num b = list[bIdx];

    // Some Lottie files use > 1 values, but valid color check filters those out.
    Color c = Color.fromRGBO((r * 255).round(), (g * 255).round(), (b * 255).round(), 1.0);
    HSLColor hsl = HSLColor.fromColor(c);
    
    // We only shift hue if saturation is noticeable to avoid tinting greys/whites weirdly
    if (hsl.lightness > 0.95 || hsl.lightness < 0.05 || hsl.saturation < 0.1) {
      return; 
    }

    double newHue = (hsl.hue + hueShift) % 360.0;
    if (newHue < 0) newHue += 360.0;

    double newSat = (hsl.saturation * satScale).clamp(0.0, 1.0);

    HSLColor newHsl = hsl.withHue(newHue).withSaturation(newSat);
    Color newColor = newHsl.toColor();

    list[rIdx] = newColor.red / 255.0;
    list[gIdx] = newColor.green / 255.0;
    list[bIdx] = newColor.blue / 255.0;
  }
}
