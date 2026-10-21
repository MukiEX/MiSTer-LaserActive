Put the Sega PAC (LaserActive) BIOS files here, renamed:

  Pioneer LaserActive Sega PAC Boot ROM v1.02 (1993)(Pioneer - Sega)(JP)(en-ja).bin -> boot_jp.rom
  Pioneer LaserActive Sega PAC Boot ROM v1.04 (1993)(Pioneer - Sega)(US).bin        -> boot_us.rom
  Pioneer LaserActive Sega PAC Boot ROM v1.02 (1993)(Pioneer - Sega)(US).bin        -> boot_us102.rom

You only need the regions you play. The OSD's LaserActive BIOS option picks
one: Auto (by the Region option, or else the disc's region), Japan, USA or
USA v1.02. If the file it wants isn't here, MiSTer_LD falls back to
cd_bios.rom in the disc's folder, then boot.rom (the 1.x setup), then the
other region's file. laseractive.log names the BIOS it loaded.

Put your .dscmmi disc images here too (or anywhere under games/MegaLD).
