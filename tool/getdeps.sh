#!/usr/bin/env bash
set -e

if [ -d /home/pi ]
then
  export HOME="/home/pi"
fi

PUB=$(which pub || true)

if [ -z "${PUB}" ]
then
  PUB=/opt/dsa/dart-sdk/bin/pub
fi

${PUB} get
${PUB} run rpi_gpio:build_lib