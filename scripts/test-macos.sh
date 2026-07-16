#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="${TMPDIR:-/tmp}/quota-bubble-tests"
mkdir -p "$BUILD_DIR"
export CLANG_MODULE_CACHE_PATH="$BUILD_DIR/clang-module-cache"
export SWIFT_MODULECACHE_PATH="$BUILD_DIR/swift-module-cache"
mkdir -p "$CLANG_MODULE_CACHE_PATH" "$SWIFT_MODULECACHE_PATH"

bash -n "$ROOT"/scripts/{install,package-installer,restart,ensure-usage-widget,start-usage-widget,status,uninstall}.sh

swiftc -parse-as-library -o "$BUILD_DIR/QuotaModelsTests" \
    "$ROOT/sources/QuotaModels.swift" "$ROOT/tests/QuotaModelsTests.swift"
"$BUILD_DIR/QuotaModelsTests"

swiftc -parse-as-library -o "$BUILD_DIR/QuotaStoreTests" \
    "$ROOT/sources/QuotaModels.swift" "$ROOT/sources/QuotaSnapshotService.swift" "$ROOT/sources/QuotaStore.swift" "$ROOT/tests/QuotaStoreTests.swift" \
    -framework Cocoa -framework Combine
"$BUILD_DIR/QuotaStoreTests"

swiftc -parse-as-library -o "$BUILD_DIR/QuotaSnapshotServiceTests" \
    "$ROOT/sources/QuotaModels.swift" "$ROOT/sources/QuotaSnapshotService.swift" "$ROOT/tests/QuotaSnapshotServiceTests.swift"
"$BUILD_DIR/QuotaSnapshotServiceTests"

swiftc -parse-as-library -o "$BUILD_DIR/QuotaBubble" \
    "$ROOT/sources/QuotaModels.swift" "$ROOT/sources/QuotaSnapshotService.swift" "$ROOT/sources/QuotaStore.swift" "$ROOT/sources/QuotaBubbleApp.swift" \
    -framework Cocoa -framework SwiftUI -framework Combine

echo "macOS SwiftUI build tests passed."
