#!/usr/bin/env bash
set -e
if [ -z "$1" ]; then
  echo "Usage: ./quick_build.sh <project.zip>"
  exit 1
fi
python3 universal_compiler.py build "$1" --output build
