#!/bin/bash

BOARD="esp8266:esp8266:generic"
PORT="$(ls /dev/ttyUSB* | head -n1)"
ACTION="--upload"
ARDUINO="arduino"
INO_LOCATION="./elookout.ino"

JAVA_TOOL_OPTIONS='-Djava.awt.headless=true' "${ARDUINO}" "${ACTION}" "${INO_LOCATION}" --board "${BOARD}" --port "${PORT}"
