# X-plore for Nokia 9300/9500 (Series 80)

Port of [X-plore for Symbian](https://github.com/mice777/X-plore-Symbian) by
Lonely Cat Games (released to the public domain, Apache 2.0 licence file) to
Series 80 DP 2.0 / Symbian OS 7.0s. Unofficial; not supported by Lonely Cat Games.

The S60 2nd edition code path is kept (`S60` is still defined); `S80` swaps out
the few Avkon parts:

- `LibSrc/Symbian/SymbianAppStart.cpp`: plain `CEikApplication`/`CEikAppUi`
  instead of the Avkon view app; `NewApplication` export; full keyboard.
- `LibSrc/Symbian/IGraph.cpp`: Series 80 keys (command buttons, rocker).
- `LibSrc/Symbian/TextEditSymbian.cpp`: no Avkon editor state / T9 indicator.

Keys: top command button = left soft key (Menu), bottom command button =
right soft key (Back), rocker press or Enter = OK, Menu and Esc keys work too.

Runs on a Nokia 9500: it shows the drives C: (phone memory), D: (memory
card), E: (RAM disk) and Z: (ROM).

Build on Linux with Wine and the Nokia Series 80 DP 2.0 SDK (Symbian OS 7.0s)
installed in Wine's `drive_c` (GCC 2.9 toolchain, Perl for the SDK scripts):

    S80/scripts/build-s80-wine.sh build    # -> S80/sis/xplore.sis
    S80/scripts/build-s80-wine.sh clean    # after changing compiler flags

The mmp sets `-Os -fno-default-inline` on purpose: without both, GCC 2.9 does
not emit the virtual functions of function-local classes and the link fails.

`Data.dta` (fonts, icons, all 26 languages) is rebuilt by `scripts/make-data.py`.
