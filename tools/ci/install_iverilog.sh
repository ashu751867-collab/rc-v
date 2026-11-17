#!/bin/sh
# Install Icarus Verilog on a GitHub runner, robust to Ubuntu mirror outages:
# use the cached .deb files if there are any, otherwise apt with retries and a
# fallback mirror, then keep the .deb files for the cache.
set -u
DEBS="$HOME/iverilog-debs"
if ls "$DEBS"/*.deb >/dev/null 2>&1 && sudo dpkg -i "$DEBS"/*.deb >/dev/null 2>&1; then
  echo "iverilog from cache"; iverilog -V 2>&1 | head -1; exit 0
fi
for i in 1 2 3 4; do
  if sudo apt-get update -qq -o Acquire::Retries=3 && \
     sudo apt-get install -y -qq -o Acquire::Retries=3 iverilog >/dev/null; then
    mkdir -p "$DEBS" && cp /var/cache/apt/archives/iverilog_*.deb "$DEBS"/ 2>/dev/null
    echo "iverilog from apt (attempt $i)"; iverilog -V 2>&1 | head -1; exit 0
  fi
  echo "apt attempt $i failed; switching mirror and retrying"
  echo "http://archive.ubuntu.com/ubuntu/" | sudo tee /etc/apt/apt-mirrors.txt >/dev/null
  sleep $((i * 15))
done
exit 1
