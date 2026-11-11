import '../../../core/dodo_mode.dart';
import '../../../core/json.dart';
import '../domain/entities/checkout_enums.dart';
import '../domain/entities/checkout_options.dart';
import '../domain/entities/checkout_settings.dart';

/// Builds the options for `DodoPayments.Initialize()`.
JsonMap initializeOptionsToJson(
  DodoMode mode,
  CheckoutDisplayType displayType,
) => {'mode': mode.value, 'displayType': displayType.value};

/// Builds the options for `DodoPayments.Checkout.open()`.
JsonMap checkoutOptionsToJson(CheckoutOptions options) {
  final settings = options.settings;
  return compactJson({
    'checkoutUrl': options.checkoutUrl.toString(),
    'elementId': options.elementId,
    'options': settings == null ? null : _settingsToJson(settings),
  });
}

JsonMap _settingsToJson(CheckoutSettings settings) => compactJson({
  'showTimer': settings.showTimer,
  'showSecurityBadge': settings.showSecurityBadge,
  'manualRedirect': settings.manualRedirect,
  'payButtonText': settings.payButtonText,
  'fontSize': settings.fontSize?.value,
  'fontWeight': settings.fontWeight?.value,
});
