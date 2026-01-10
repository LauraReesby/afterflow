#!/usr/bin/env bash
set -euo pipefail

DESTINATION=${DESTINATION:-""}
SCHEME=${SCHEME:-"Afterflow"}
PROJECT_PATH=${PROJECT_PATH:-"Afterflow.xcodeproj"}
DERIVED_DATA=${DERIVED_DATA:-"build/DerivedData"}
UNIT_ONLY=false
EXTRA_ARGS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --destination)
      DESTINATION="$2"
      shift 2
      ;;
    --scheme)
      SCHEME="$2"
      shift 2
      ;;
    --project)
      PROJECT_PATH="$2"
      shift 2
      ;;
    --derived-data)
      DERIVED_DATA="$2"
      shift 2
      ;;
    --unit-only)
      UNIT_ONLY=true
      shift
      ;;
    *)
      EXTRA_ARGS+=("$1")
      shift
      ;;
  esac
done

mkdir -p "$DERIVED_DATA/Logs/Build" "$DERIVED_DATA/Logs/Test"

CMD=(xcodebuild test -project "$PROJECT_PATH" -scheme "$SCHEME" -derivedDataPath "$DERIVED_DATA")
if [[ -n "$DESTINATION" ]]; then
  CMD+=(-destination "$DESTINATION")
fi
if [[ "$UNIT_ONLY" == true ]]; then
  CMD+=(-skip-testing:AfterflowUITests)
fi
if [[ ${#EXTRA_ARGS[@]} -gt 0 ]]; then
  CMD+=("${EXTRA_ARGS[@]}")
fi

"${CMD[@]}"
