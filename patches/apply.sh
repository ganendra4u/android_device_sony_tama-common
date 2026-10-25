#!/bin/bash
# Jalankan dari root tree setelah repo sync, sebelum breakfast.
T=$(pwd); P=$T/device/sony/tama-common/patches
ap(){
  [ -s "$P/$2" ] || { echo "lewati (kosong): $2"; return; }
  if git -C "$T/$1" apply --reverse --check "$P/$2" 2>/dev/null; then echo "sudah terpasang: $1"
  elif git -C "$T/$1" apply --check "$P/$2" 2>/dev/null; then git -C "$T/$1" apply "$P/$2" && echo "dipasang: $1"
  else echo "GAGAL: $1 (patch tidak cocok dengan source)"; fi
}
ap frameworks/native frameworks_native.patch
ap system/memory/libmeminfo system_memory_libmeminfo.patch
ap vendor/sony/tama-common vendor_sony_tama-common.patch
if [ ! -d "$T/hardware/interfaces/light/2.0" ]; then
  mkdir -p "$T/hardware/interfaces/light" && tar -xzf "$P/hardware_interfaces_light_2.0.tar.gz" -C "$T/hardware/interfaces/light" && echo "dipasang: light/2.0"
fi
