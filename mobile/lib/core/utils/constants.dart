import 'dart:io' show Platform;

const kDefaultHeaders = {'Content-Type': 'application/json', 'Accept': '*/*'};

/// Backend base URL. The Express + TypeORM API listens on port 3000 and
/// mounts every route under `/api/v1/*` (see `backend/src/index.ts`).
///
/// Resolution order:
///   1. `--dart-define=API_BASE_URL=...` (build-time override, e.g. ngrok)
///   2. Android emulator: `http://10.0.2.2:3000/api/v1` — emulator-to-host
///      loopback, since `localhost` inside the emulator resolves to itself.
///   3. iOS simulator / desktop / web: `http://localhost:3000/api/v1`.
String get kApiBaseUrl {
  const override = String.fromEnvironment('API_BASE_URL');
  if (override.isNotEmpty) return override;
  if (Platform.isAndroid) return 'http://10.0.2.2:3000/api/v1';
  return 'http://localhost:3000/api/v1';
}

/// Path segments and header names used by the mobile sync flow (ADR-0004).
const String kDeviceIdStorageKey = 'device_id';
const String kDeviceIdHeader = 'X-Device-Id';

const double kMediumTabletBreakpoint = 1024;
const double kLargeTabletBreakpoint = 1280;
