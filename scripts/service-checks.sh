#!/bin/bash
# Script to check various services
EMAIL="alerts@lunar.systems"

# NFS variables
NFS_MOUNT="/nfs"

# Tor variables
TOR_RESTART_FLAG="/home/user/flags/tor-restart"
TOR_NOTICE_LOG="/var/log/tor/notice.log"
HSV3="6voaf7iamjpufgwoulypzwwecsm2nu7j5jpgadav2rfqixmpl4d65kid.onion"
HSV2="y2qmqomqpszzryei.onion"
LOG_ATTRIBUTE_HSDIR1="No more HSDir available to query"

# Prosody variables
PROSODY_RESTART_FLAG="/home/user/flags/prosody-restart"

# Check NFS mount
function nfs_check_mount {
if mount | grep "${NFS_MOUNT}" | grep "(rw," > /dev/null; then
  echo "The "${NFS_MOUNT}" mount point shows up, and is mounted as rw!"
else
  echo "There is an issue with the "${NFS_MOUNT}" NFS mount on "${HOSTNAME}"" | mail -s "NFS Mount Issue" "${EMAIL}"
fi
}

# Checks Tor log for common errors, and sets flag if needed
function tor_check_logs {
echo "Parsing logs now!"
if sed -n "/^$(date --date='5 minutes ago' '+%b %_d %H')/,\$p" "${TOR_NOTICE_LOG}" | grep "${HSV2}" | grep "${LOG_ATTRIBUTE_HSDIR1}"; then
  echo "The '"${LOG_ATTRIBUTE_HSDIR1}"' attribute was found in the log for "${HSV2}"" | mail -s "Bad Tor log attribute found" "${EMAIL}"
  echo ""${HSV2}" is having issues, setting flag to 1"
  echo "1" > "${TOR_RESTART_FLAG}"
else
  echo "The '"${LOG_ATTRIBUTE_HSDIR1}"' attribute was not found in the log for "${HSV2}""
fi
if sed -n "/^$(date --date='5 minutes ago' '+%b %_d %H')/,\$p" "${TOR_NOTICE_LOG}" | grep "${HSV3}" | grep "${LOG_ATTRIBUTE_HSDIR1}"; then
  echo "The '"${LOG_ATTRIBUTE_HSDIR1}"' attribute was found in the log for "${HSV3}"" | mail -s "Bad Tor log attribute found" "${EMAIL}"
  echo ""${HSV3}" is having issues, setting flag to 1"
  echo "1" > "${TOR_RESTART_FLAG}"
else
  echo "The '"${LOG_ATTRIBUTE_HSDIR1}"' attribute was not found in the log for "${HSV3}""
fi
echo "Done parsing logs!"
}

# Performs a curl test on the hidden service
function tor_curl_test {
# Check if curl is already running a test
if ps aux | grep -v grep | grep curl | grep ".onion"; then
  echo "curl is running, exiting now"
  exit
fi

echo "Checking HSv2"
if torsocks curl --connect-timeout 45 --max-time 45 "${HSV2}":5222/ | grep "xml" | grep "stream" > /dev/null 2>&1
  then
    echo "The Tor HSv2 "${HSV2}":5222 was reachable!"
  else
    echo "The Tor HSv2 "${HSV2}":5222 is unreachable!" | mail -s "Tor HSv2 Down" "${EMAIL}"
fi

echo "Checking HSv3"
if torsocks curl --connect-timeout 45 --max-time 45 "${HSV3}":5222/ | grep "xml" | grep "stream" > /dev/null 2>&1
  then
    echo "The Tor HSv3 "${HSV3}":5222 is reachable!"
  else
    echo "The Tor HSv3 "${HSV3}":5222 is unreachable!" | mail -s "Tor HSv3 Down" "${EMAIL}"
fi
}

function prosody_check {
if ps aux | grep -v grep | grep lua | grep prosody; then
  echo "Prosody is currently running, exiting script now!"
  exit
else
  echo "Prosody doesn't seem to be running, setting flag!"
  echo "1" > "${PROSODY_RESTART_FLAG}"
fi
}

# Magic code for flags
while [ ! $# -eq 0 ]
do
case "$1" in

  --nfs-check-mount)
  nfs_check_mount
  ;;

  --tor-curl-test)
  tor_curl_test
  ;;

  --tor-check-logs)
  tor_check_logs
  ;;

  --prosody-check)
  prosody_check
  ;;

  *)
  echo "Unknown parameter detected: ${1}" >&2
  exit 1
  ;;

esac
shift
done
