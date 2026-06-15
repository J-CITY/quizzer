import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:quizzer/core/feature_flags.dart';
import 'package:quizzer/utils/constants.dart';
import 'package:quizzer/data/services/database_service.dart';

class AdsService {
  final DatabaseService _dbService;

  AdsService(this._dbService);

  Future<void> init() async {
    if (!FeatureFlags.enableAds) return;
    if (!Platform.isAndroid && !Platform.isIOS) return; // Only support Mobile
    
    await MobileAds.instance.initialize();
  }

  Future<void> showInterstitialAd() async {
    if (!FeatureFlags.enableAds) return;
    if (!Platform.isAndroid && !Platform.isIOS) return; // Only support Mobile
    
    final settings = await _dbService.getSettings();
    if (settings.isAdFree) return; // User bought removal

    final String adUnitId = kReleaseMode
        ? (Platform.isAndroid ? AdConstants.androidInterstitialAdUnitId : AdConstants.iosInterstitialAdUnitId)
        : (Platform.isAndroid ? AdConstants.androidInterstitialAdUnitId : AdConstants.iosInterstitialAdUnitId); // Using test ids for both in this example

    InterstitialAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
            },
          );
          ad.show();
        },
        onAdFailedToLoad: (error) {
          debugPrint('Failed to load interstitial ad: $error');
        },
      ),
    );
  }
}
