#!/usr/bin/env bash
if [ -d build ]
then
  rm -rf build
fi

mkdir build
touch stub
pub get
cp -R bin lib build/
cp pubspec.yaml dslink.json build/
cd build
zip -r ../../../files/dslink-dart-rpi.zip .
