# MiSTer LaserActive

Plays Pioneer LaserActive **Mega-LD** discs (the Sega PAC) on MiSTer: the
Mega CD core with the PAC's LaserDisc player, video mixer and analog audio,
following Nemesis's work in [ares](https://github.com/ares-emulator/ares).

| | |
|---|---|
| `MegaCD_MiSTer/` | The core (submodule: [MukiEX/MegaCD_MiSTer](https://github.com/MukiEX/MegaCD_MiSTer), branch `laseractive-step1`). Builds `MegaLD.rbf`. Also holds the converters and tests in `tools/`, and the design notes in `LaserActive.md`. |
| `Main_MiSTer/` | MiSTer's Main with the LaserDisc player (submodule: [MukiEX/Main_MiSTer](https://github.com/MukiEX/Main_MiSTer), same branch). Installed as `MiSTer_LD`. |
| `extras/` | Example `MiSTer.ini` and `laseractive.cfg` lines, the BIOS folder note. |
| `release.sh` | Puts a release zip together. |

## Installing

Download the zip from [Releases](https://github.com/MukiEX/MiSTer-LaserActive/releases),
copy its contents to the root of the SD card, and:

1. Add this to `/media/fat/MiSTer.ini`:
   ```
   [MegaLD]
   main=MiSTer_LD
   ```
   The stock MiSTer loads the MegaLD core and then hands over to
   `MiSTer_LD`, so your normal `MiSTer` binary stays untouched.
2. Put the Sega PAC BIOS in `games/MegaLD/boot.rom`.
3. Load **MegaLD** from the Console menu and pick a disc with **Insert Disk**.

## Discs

The core plays `.dscmmi` files: an `.mmi` disc image (the format ares uses)
with its video compressed to a fixed bit rate the MiSTer can read from an SD
card. Convert yours with either:

- **`tools/mmidsc.html`**: open it in Chrome or Edge, pick the `.mmi`, press
  **Convert and save**. Nothing is uploaded.
- **`tools/mmidsc-*`**: the command-line version,
  `mmidsc convert "Game.mmi" "Game.dscmmi"`.

Both write identical files. Keep your `.mmi`: the `.dscmmi` is a playback copy.

## OSD options

- **LaserActive PD6103A**: the PAC (on by default in this core).
- **LaserDisc Video**: Auto, or Hide for the plain Mega Drive picture.
- **LaserDisc Fields**: Auto (what the game asks for, as the real hardware
  does), or Both for full 480-line 480i.
- **LaserDisc Field Order**: Normal or Reversed, for Both.
- **Deinterlace (HDMI)**: Weave or Bob, for 480i over HDMI.

Analog/CRT output works at 15 kHz; the scandoubler is bypassed while the PAC
is on.

## Building

```
git clone --recurse-submodules https://github.com/MukiEX/MiSTer-LaserActive.git
cd MiSTer-LaserActive

# core: Quartus 17.0 Lite (here in Docker; :z for SELinux)
cd MegaCD_MiSTer
docker run --rm -v "$(pwd)":/project:z -w /project theypsilon/quartus-lite-c5:17.0 \
  quartus_sh --flow compile MegaCD.qpf
# or try several fitter seeds in parallel: ./build_seeds.sh -s 1-8 -j 2
cd ..

# Main: the usual MiSTer ARM toolchain (gcc-arm 10.2)
cd Main_MiSTer && make && cd ..

./release.sh 1.0 MegaCD_MiSTer/output_files/MegaCD.rbf Main_MiSTer/bin/MiSTer
```

The FPGA is full (every RAM block, ~90 % of the logic), so some fitter seeds
don't fit or miss timing; `build_seeds.sh` finds one that does.

## Credits and licences

- The Mega CD core: Sorgelig and the MiSTer-devel contributors (GPL).
- MiSTer Main: the MiSTer-devel contributors (GPL).
- The LaserActive player and PAC behaviour: Nemesis's MegaLD emulation in
  ares (ISC), which this follows closely.
- The `.mmi` format and QON/QOI2 codecs: ares (MIT, Roger Sanders and
  Dominic Szablewski).
- The LaserActive additions in both submodules and the tools are by MukiEX.
