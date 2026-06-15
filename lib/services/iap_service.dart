import 'dart:async';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:quizzer/core/feature_flags.dart';
import 'package:quizzer/utils/constants.dart';
import 'package:quizzer/data/services/database_service.dart';
import 'package:quizzer/l10n/app_localizations.dart';
import 'dart:io';

class IapService extends ChangeNotifier {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;
  final DatabaseService _dbService;

  bool isAvailable = false;
  List<ProductDetails> products = [];
  bool isLoading = false;

  IapService(this._dbService);

  Future<void> init() async {
    if (!FeatureFlags.enableIap) return;
    if (!Platform.isAndroid && !Platform.isIOS) return; // Only support Mobile

    isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) return;

    final Stream<List<PurchaseDetails>> purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _listenToPurchaseUpdated,
      onDone: () => _subscription.cancel(),
      onError: (error) {
        debugPrint('Purchase stream error: $error');
      },
    );

    // Load products
    await _loadProducts();
  }

  Future<void> _loadProducts() async {
    final Set<String> kIds = <String>{IapConstants.removeAdsProductId};
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(kIds);
    if (response.notFoundIDs.isEmpty && response.productDetails.isNotEmpty) {
      products = response.productDetails;
      notifyListeners();
    }
  }

  Future<void> buyRemoveAds(BuildContext context) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('In-App Purchases are not supported on this platform.')),
      );
      return;
    }

    if (products.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.purchaseError)),
      );
      return;
    }

    final productDetails = products.firstWhere((p) => p.id == IapConstants.removeAdsProductId);
    final PurchaseParam purchaseParam = PurchaseParam(productDetails: productDetails);
    
    isLoading = true;
    notifyListeners();
    
    try {
      await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> restorePurchases() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;

    isLoading = true;
    notifyListeners();
    
    try {
      await _inAppPurchase.restorePurchases();
    } catch (e) {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        isLoading = true;
        notifyListeners();
      } else {
        isLoading = false;
        notifyListeners();

        if (purchaseDetails.status == PurchaseStatus.error) {
          debugPrint('Purchase error: ${purchaseDetails.error}');
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          
          if (purchaseDetails.productID == IapConstants.removeAdsProductId) {
            await _deliverProduct();
          }
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> _deliverProduct() async {
    final settings = await _dbService.getSettings();
    if (!settings.isAdFree) {
      settings.isAdFree = true;
      await _dbService.saveSettings(settings);
    }
  }

  @override
  void dispose() {
    if (FeatureFlags.enableIap) {
      _subscription.cancel();
    }
    super.dispose();
  }
}
