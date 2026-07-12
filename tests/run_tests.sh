#!/bin/bash
# run_tests.sh - Run Maxwell QML unit tests
#
# Usage:
#   cd tests
#   ./run_tests.sh
#
# Requirements:
#   - qmltestrunner-qt6 (part of Qt6-devel/qtbase-devel)
#   - Qt6 Quick and Test modules installed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================"
echo " Maxwell QML Unit Tests"
echo "========================================"
echo ""

# Check for qmltestrunner-qt6
if ! command -v qmltestrunner-qt6 &> /dev/null; then
    echo "ERROR: qmltestrunner-qt6 not found!"
    echo "Install Qt6 Quick Test module (e.g., qt6-declarative-devel or qtbase-devel)"
    exit 1
fi

echo "Running tests..."
echo ""

# Run the test suite
qmltestrunner-qt6 \
    -input "$SCRIPT_DIR" \
    -import "$SCRIPT_DIR/../contents/ui" \

EXIT_CODE=$?

echo ""
echo "========================================"
if [ $EXIT_CODE -eq 0 ]; then
    echo " All tests PASSED!"
else
    echo " Some tests FAILED! (exit code: $EXIT_CODE)"
fi
echo "========================================"

exit $EXIT_CODE