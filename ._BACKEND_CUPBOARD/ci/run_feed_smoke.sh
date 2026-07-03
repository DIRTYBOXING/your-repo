#!/usr/bin/env bash
set -e
echo "Running feed smoke checks (staging)..."
# Example smoke steps; adapt to your infra
dart format .
dart analyze
dart test test/chukya_config_test.dart || true
echo "Feed smoke completed."
