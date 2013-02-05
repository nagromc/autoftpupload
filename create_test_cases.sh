#!/usr/bin/env sh
# Create some test cases. Run from the root directory you want to create the test files.

set -u
set -e

ROOTD="$(dirname $0)/test_dir"

if [ -d "$ROOTD" ]; then rm -r "$ROOTD" ; fi

mkdir "$ROOTD"
cd "$ROOTD"
echo "f-root-1" > "f-root-1"
echo "f-root-2" > "f-root-2"

mkdir "d-1"
cd "d-1"
echo "f-d1-1" > "f-d1-1"
echo "f-d1-2" > "f-d1-2"
cd ..

mkdir "d-1/d-1-2"
cd "d-1/d-1-2"
echo "f-d12-1" > "f-d12-1"
echo "f-d12-2" > "f-d12-2"
cd ../..

mkdir "d-2"
cd "d-2"
echo "f d2 1" > "f d2 1"
echo "f d2 2" > "f d2 2"
cd ..

mkdir "d 3"
cd "d 3"
echo "f d3 1" > "f d3 1"
echo "f d3 2" > "f d3 2"
cd ..

