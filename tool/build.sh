#!/usr/bin/env bash
if [ -d build ]
then
  rm -rf build
fi

mkdir -p build
touch stub
pub get
cp -R bin lib build/
cp pubspec.yaml dslink.json build/
mkdir -p build/tool
cp tool/getdeps.sh build/tool/
cd build
zip -r ../../../files/dslink-dart-rpi.zip .
