#!/bin/sh
set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
XCFRAMEWORK="${ROOT_DIR}/llama-spm/Frameworks/llama.xcframework"

if [ ! -d "${XCFRAMEWORK}" ]; then
  echo "Missing ${XCFRAMEWORK}"
  exit 1
fi

BIN_PATH="$(find "${XCFRAMEWORK}" -path "*/llama.framework/llama" -maxdepth 6 | head -n 1)"
HEADER_PATH="$(find "${XCFRAMEWORK}" -path "*/llama.framework/Headers/llama.h" -maxdepth 7 | head -n 1)"

if [ -z "${BIN_PATH}" ]; then
  echo "No llama binary found in xcframework."
  exit 1
fi

echo "Checking mtmd symbols in: ${BIN_PATH}"
if nm -gU "${BIN_PATH}" 2>/dev/null | rg -q "mtmd_"; then
  echo "mtmd symbols found in binary."
else
  echo "mtmd symbols NOT found in binary."
fi

if [ -n "${HEADER_PATH}" ]; then
  echo "Checking for mtmd API declarations in llama.h:"
  if rg -q "mtmd_" "${HEADER_PATH}"; then
    echo "mtmd references present in llama.h."
  else
    echo "No mtmd references in llama.h."
  fi
else
  echo "No llama.h found to inspect."
fi
