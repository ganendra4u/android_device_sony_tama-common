#!/bin/bash
T=${T:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)}
P=$T/device/sony/tama-common/patches
L=$P/hardware_interfaces_light_2.0.tar.gz
M=$T/.apollo_light
rc=0
case "${1:-apply}" in
  apply)
    python3 - "$T/frameworks/native/libs/ui/Android.bp" "$T/system/memory/libmeminfo/sysmeminfo.cpp" <<'PYEOF' || rc=1
import re, sys
ui, mi = sys.argv[1:3]
bad = 0
s = open(ui).read()
sel = 'soong_config_variable("libui", "legacy_gralloc")'
if '"-DLEGACY_GRALLOC"' in s and sel not in s:
    pass
else:
    old = '''}) + select(soong_config_variable("libui", "legacy_gralloc"), {
        true: ["-DLEGACY_GRALLOC"],
        default: [],
    }),'''
    if s.count(old) == 1:
        open(ui, 'w').write(s.replace(old, '}) + ["-DLEGACY_GRALLOC"],'))
    else:
        print('gagal: libui'); bad = 1
s = open(mi).read()
needle = 'auto map = bpf::BpfMapRO<uint64_t, uint64_t>(kBpfGpuMemTotalMap);'
guard = 'if (access(kBpfGpuMemTotalMap, F_OK) != 0) {\n        return false;\n    }\n    '
if needle not in s:
    if 'access(kBpfGpuMemTotalMap' not in s:
        print('gagal: libmeminfo'); bad = 1
else:
    parts = s.split(needle); out = parts[0]; ok = True
    for part in parts[1:]:
        fn = list(re.finditer(r'^(\w[^\n(]*?)\s+(\w+)\(', out, re.M))
        if not fn or not fn[-1].group(1).strip().startswith('bool'):
            ok = False; break
        if re.search(r'access\(kBpfGpuMemTotalMap, F_OK\)[^\n]*\{\s*return false;\s*\}\s*$', out):
            out += needle + part
        else:
            out += guard + needle + part
    if not ok:
        print('gagal: libmeminfo'); bad = 1
    else:
        if '<unistd.h>' not in out:
            out = re.sub(r'(#include [<"][^\n]+\n)', r'\1#include <unistd.h>\n', out, count=1)
        if out != s:
            open(mi, 'w').write(out)
sys.exit(bad)
PYEOF
    if [ ! -d "$T/hardware/interfaces/light/2.0" ]; then
      mkdir -p "$T/hardware/interfaces/light" && tar -xzf "$L" -C "$T/hardware/interfaces/light" && touch "$M" || { echo "gagal: light/2.0"; rc=1; }
    fi;;
  revert)
    git -C "$T/frameworks/native" checkout -- libs/ui/Android.bp
    git -C "$T/system/memory/libmeminfo" checkout -- sysmeminfo.cpp
    [ -f "$M" ] && rm -rf "$T/hardware/interfaces/light/2.0" "$M";;
  *) echo "apply|revert"; rc=1;;
esac
exit $rc
