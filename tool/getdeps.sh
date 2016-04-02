#!/usr/bin/env bash
set -e

if [ -d /home/pi ]
then
  export HOME="/home/pi"
fi

PUB=$(which pub)

if [ -z "${PUB}" ]
then
  PUB=/opt/dsa/dart-sdk/bin/pub
fi

pub get
pub run rpi_gpio:build_lib
