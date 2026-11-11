/// Dodo Payments checkout for Flutter web: overlay and inline checkout from a
/// session URL, typed checkout events and price breakdowns, return-URL
/// parsing and payment confirmation polling.
library;

// Core
export 'src/core/dodo_amount.dart';
export 'src/core/dodo_exception.dart';
export 'src/core/dodo_mode.dart';
export 'src/core/json.dart' show JsonMap;
export 'src/core/platform/dodo_checkout_bridge.dart';
export 'src/core/platform/dodo_frame_host.dart';
export 'src/core/platform/dodo_platform.dart';
export 'src/core/platform/dodo_script_loader.dart';
export 'src/dodo.dart';
export 'src/dodo_config.dart';

// Checkout
export 'src/features/checkout/domain/checkout_service.dart';
export 'src/features/checkout/domain/entities/checkout_breakdown.dart';
export 'src/features/checkout/domain/entities/checkout_enums.dart';
export 'src/features/checkout/domain/entities/checkout_event.dart';
export 'src/features/checkout/domain/entities/checkout_options.dart';
export 'src/features/checkout/domain/entities/checkout_settings.dart';
export 'src/features/checkout/domain/entities/checkout_state.dart';
export 'src/features/checkout/presentation/dodo_checkout_builder.dart';
export 'src/features/checkout/presentation/dodo_inline_checkout.dart';

// Return URL
export 'src/features/return_url/domain/checkout_return_result.dart';

// Confirmation
export 'src/features/confirmation/domain/payment_confirmation.dart';
export 'src/features/confirmation/domain/payment_confirmation_exception.dart';
export 'src/features/confirmation/domain/polling_policy.dart';
