#!/bin/sh
# release.sh - put together a MiSTer LaserActive release zip.
#
#   ./release.sh VERSION CORE.rbf MiSTer [YYYYMMDD]
#
#   VERSION   e.g. 1.0
#   CORE.rbf  the built core (MegaCD_MiSTer/output_files/MegaCD.rbf, or the
#             seed build you picked: seed_builds/MegaCD_seed<n>.rbf)
#   MiSTer    the built Main (Main_MiSTer/bin/MiSTer)
#   YYYYMMDD  date for the core's file name (default: today)
#
# Builds the mmidsc command-line converter from the pinned sources (a static
# Linux x86-64 binary, and a Windows .exe when x86_64-w64-mingw32-gcc is
# installed) and takes the web converter from the pinned tree. Writes
# dist/MiSTer-LaserActive-VERSION/ laid out like the SD card, the zip of it,
# and SHA256SUMS.
set -e
cd "$(dirname "$0")"

if [ $# -lt 3 ]; then
	sed -n '2,/^set -e/{/^set -e/d;s/^# \{0,1\}//;p}' "$0"
	exit 2
fi
VERSION=$1 RBF=$2 MAIN=$3 DATE=${4:-$(date +%Y%m%d)}
case $DATE in [0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]) ;; *) echo "bad date: $DATE" >&2; exit 2 ;; esac
[ -f "$RBF" ] || { echo "no core file: $RBF" >&2; exit 2; }
[ -f "$MAIN" ] || { echo "no Main binary: $MAIN" >&2; exit 2; }
[ -f MegaCD_MiSTer/LaserActive.md ] || { echo "submodules missing: git submodule update --init" >&2; exit 2; }

NAME=MiSTer-LaserActive-$VERSION
OUT=dist/$NAME
TOOLS=MegaCD_MiSTer/tools/mmidsc
rm -rf "$OUT" "dist/$NAME.zip"
mkdir -p "$OUT/_Console" "$OUT/games/MegaLD" "$OUT/tools"

# core and Main, under the names MiSTer expects
cp "$RBF" "$OUT/_Console/MegaLD_$DATE.rbf"
cp "$MAIN" "$OUT/MiSTer_LD"
chmod 755 "$OUT/MiSTer_LD"

# settings examples
cp extras/MiSTer.ini.example extras/laseractive.cfg.example "$OUT/"
cp extras/games/MegaLD/README.txt "$OUT/games/MegaLD/"

# converters (compiler output goes to dist/build.log)
LOG=dist/build.log
: > "$LOG"
make -s -C "$TOOLS" clean >>"$LOG" 2>&1 || true
if make -s -C "$TOOLS" mmidsc CC="${CC:-cc} -static" >>"$LOG" 2>&1; then
	cp "$TOOLS/mmidsc" "$OUT/tools/mmidsc-linux-x86_64"
else
	echo "warning: static build failed (see $LOG), using a dynamic one" >&2
	make -s -C "$TOOLS" mmidsc >>"$LOG" 2>&1 || { echo "mmidsc build failed, see $LOG" >&2; exit 1; }
	cp "$TOOLS/mmidsc" "$OUT/tools/mmidsc-linux-x86_64"
fi
if command -v "${WINCC:-x86_64-w64-mingw32-gcc}" >/dev/null 2>&1; then
	make -s -C "$TOOLS" windows >>"$LOG" 2>&1 || { echo "Windows mmidsc build failed, see $LOG" >&2; exit 1; }
	cp "$TOOLS/mmidsc.exe" "$OUT/tools/mmidsc-windows-x86_64.exe"
else
	echo "note: no x86_64-w64-mingw32-gcc, so no Windows mmidsc in this release" >&2
fi
make -s -C "$TOOLS" clean >>"$LOG" 2>&1 || true
cp "$TOOLS/web/mmidsc.html" "$OUT/tools/mmidsc.html"
cp "$TOOLS/README.md" "$OUT/tools/mmidsc-README.md"
cp "$TOOLS/server/mmidsc_server.py" "$OUT/tools/mmidsc_server.py"

# what's in it, and from which sources
CORE_REV=$(git -C MegaCD_MiSTer rev-parse --short HEAD)
MAIN_REV=$(git -C Main_MiSTer rev-parse --short HEAD)
UMB_REV=$(git rev-parse --short HEAD 2>/dev/null || echo none)
cat > "$OUT/README.txt" <<TXT
MiSTer LaserActive $VERSION
===========================

Copy everything in this folder to the root of your MiSTer's SD card
(/media/fat), then:

1. Add the lines from MiSTer.ini.example to /media/fat/MiSTer.ini.
2. Put the Sega PAC BIOS files in games/MegaLD, renamed:
     Pioneer LaserActive Sega PAC Boot ROM v1.02 (1993)(Pioneer - Sega)(JP)(en-ja).bin -> boot_jp.rom
     Pioneer LaserActive Sega PAC Boot ROM v1.04 (1993)(Pioneer - Sega)(US).bin        -> boot_us.rom
     Pioneer LaserActive Sega PAC Boot ROM v1.02 (1993)(Pioneer - Sega)(US).bin        -> boot_us102.rom
   (only the regions you play; a single boot.rom from 1.x still works).
   Pick one in the OSD under LaserActive BIOS, or leave it on Auto.
3. Convert your .mmi disc images to .dscmmi with tools/mmidsc.html (open it
   in Chrome or Edge), tools/mmidsc-* on the command line, or
   tools/mmidsc_server.py (python3, no installs) on the machine that holds the
   discs, and put them in games/MegaLD.
4. Load MegaLD from the Console menu and pick a disc with Insert Disk.

Files:
  _Console/MegaLD_$DATE.rbf   the core
  MiSTer_LD                    the Main that plays LaserActive discs (MiSTer
                               switches to it when MegaLD loads)
  tools/                       the .mmi -> .dscmmi converters

Built from MiSTer-LaserActive $UMB_REV: MegaCD_MiSTer $CORE_REV, Main_MiSTer $MAIN_REV.
https://github.com/MukiEX/MiSTer-LaserActive
TXT

(cd "$OUT" && find . -type f ! -name SHA256SUMS | sed 's|^\./||' | sort | xargs sha256sum > SHA256SUMS)
(cd dist && zip -qr "$NAME.zip" "$NAME")
echo "wrote dist/$NAME.zip:"
(cd "$OUT" && find . -type f | sed 's|^\./|  |' | sort)
