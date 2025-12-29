#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LLAMA_CPP_DIR="${ROOT_DIR}/../llama.cpp"
OUTPUT_FRAMEWORK="${LLAMA_CPP_DIR}/build-apple/llama.xcframework"
DEST_FRAMEWORK="${ROOT_DIR}/llama-spm/Frameworks/llama.xcframework"

if [ ! -d "${LLAMA_CPP_DIR}" ]; then
  echo "Missing llama.cpp at ${LLAMA_CPP_DIR}"
  exit 1
fi

echo "Building mtmd-enabled llama.xcframework..."
cd "${LLAMA_CPP_DIR}"
./build-xcframework.sh

if [ ! -d "${OUTPUT_FRAMEWORK}" ]; then
  echo "Build failed: ${OUTPUT_FRAMEWORK} not found."
  exit 1
fi

echo "Replacing framework in llama-spm..."
rm -rf "${DEST_FRAMEWORK}"
cp -R "${OUTPUT_FRAMEWORK}" "${DEST_FRAMEWORK}"

echo "Done. Run scripts/check_mtmd.sh to verify."
