#!/bin/bash
# First compile a binary for an ESP8266 using the Arduino IDE from the command line

BOARD="esp8266:esp8266:generic"
ACTION="--verify" # Usually this is --upload, but since we might update 2 ESPs at once we'll handle that later for efficiency's sake
ARDUINO="arduino"
INO="elookout.ino"
BUILD_DIR="/tmp/esp8266_arduino_builds"
mkdir -p ${BUILD_DIR}

JAVA_TOOL_OPTIONS='-Djava.awt.headless=true' "${ARDUINO}" "${ACTION}" "${INO}" --board "${BOARD}"  --pref build.path="${BUILD_DIR}"

err=$?
if [ ${err} -ne 0 ]; then
  echo "ERROR compiling ${INO}.  Can't continue to uploading step"
  exit $err 
fi

# Now upload the binary to each ESP8266 we can find
OUTPUT_BIN="${BUILD_DIR}/${INO}.bin"

if ls /dev/ttyUSB* 1> /dev/null 2>&1; then
  ls /dev/ttyUSB* | while read PORT; do  
    echo
    echo "UPLOADING to ${PORT}..."
    # Note: this line was generated by copy/pasting what the arduino IDE does when updating.  If something changes, just
    # change --verify to --uploand and run it once.  Look for the line like this that uploads the program and replace it here.
    ~/.arduino15/packages/esp8266/tools/esptool/0.4.13/esptool -cd nodemcu -cb 921600 -cp ${PORT} -ca 0x00000 -cf ${OUTPUT_BIN}
  done
else
    echo "I don't see any /dev/ttyUSB* devices.  Can't upload, are you sure they're plugged in?"
fi

