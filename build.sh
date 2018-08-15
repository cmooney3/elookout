#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# First compile a binary for an ESP8266 using the Arduino IDE from the command line
BOARD="esp8266:esp8266:nodemcu"
ACTION="--verify" # Usually this is --upload, but since we might update 2 ESPs at once we'll handle that later for efficiency's sake
ARDUINO="arduino"
INO="elookout.ino"
BUILD_DIR="/tmp/esp8266_arduino_builds"
mkdir -p ${BUILD_DIR}

echo "COMPILING STEP:"
JAVA_TOOL_OPTIONS='-Djava.awt.headless=true' "${ARDUINO}" "${ACTION}" "${INO}" --board "${BOARD}"  --pref build.path="${BUILD_DIR}"
err=$?
if [ ${err} -ne 0 ]; then
  echo -e "${RED}ERROR compiling ${INO}.  Can't continue to uploading step${N}"
  exit $err 
fi

# Now upload the binary to each ESP8266 we can find
OUTPUT_BIN="${BUILD_DIR}/${INO}.bin"

echo "UPLOADING STEP:"
if ls /dev/ttyUSB* 1> /dev/null 2>&1; then
  pids_to_wait_for=""
  echo "Spawning uploading process for each ESP8266 we can find:"
  while read -r PORT; do
    echo -n "	Starting ${PORT}..."
    # Note: this line was generated by copy/pasting what the arduino IDE does when updating.  If something changes, just
    # change --verify to --uploand and run it once.  Look for the line like this that uploads the program and replace it here.
    (~/.arduino15/packages/esp8266/tools/esptool/0.4.13/esptool -cd nodemcu -cb 115200 -cp ${PORT} -ca 0x00000 -cf ${OUTPUT_BIN} 1> /dev/null) &
    pid=$!
    echo "	STARTED (pid:${pid})"
    pids_to_wait_for="${pid} ${pids_to_wait_for}"
  done < <(ls /dev/ttyUSB*)

  # wait for all pids
  echo "All upload subprocesses spawned.  Waiting for them to complete..."
  upload_error_detected=0
  for pid in ${pids_to_wait_for[@]}; do
      echo -n "	Waiting for pid ${pid}..."
      wait $pid
      ret_code=$?
      if [ ${ret_code} -ne 0 ]; then
        upload_error_detected=1
        echo -ne "${RED}" 
      else
        echo -ne "${GREEN}" 
      fi
      echo -e "	DONE (return code: ${ret_code})${NC}"
  done
  echo "All upload subprocesses completed."

  if [ ${upload_error_detected} -eq 1 ]; then
    echo -e "${RED}ERROR:  At least one upload subprocess failed!${NC}"
  else
    echo -e "${GREEN}SUCCESS:  All upload subprocess succeded!${NC}"
  fi
else
    echo -e "${RED}ERROR: Can't attempt to upload -- no devices found.${NC}"
    echo "I don't see any /dev/ttyUSB* devices.  Are you sure they're plugged in?"
fi

