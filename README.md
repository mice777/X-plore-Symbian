X-plore for Symbian

![X-plore app on Symbian phone small screen](https://www.lonelycatgames.com/wp-content/uploads/x-plore/symbian-shot2.jpg)

What is X-plore for Symbian? It was once very popular file manager for then popular mobile phones with Symbian OS. 
It was developed since 2004, and was since then top tool for Symbian, until Nokia and Symbian died in around 2013.  
Currently X-plore continues to live as an Android application, but that's another story.

Developed and (c) Lonely Cat Games

Released to public domain in December 2015

Compiles under MS Visual Studio 2008  
Required environment variables:  
IM_SYMB_S60_SDK = path to Symbian 7.0 (2nd edition) SDK (Epoc32 folder)  
IM_SYMB_S60_3RD_SDK = path to Symbian 9.1 (3nd edition) SDK (Epoc32 folder)

The project file is located at LcgApps\src\X-plore.sln  
It is compilable for Windows PC and Symbian 2nd/3rd edition, and for Series 80 v2.0 (see below)  
UIDs and signing certificate are different from original X-plore, so it should not collide with official app.

## Series 80 v2.0: Nokia 9500 and 9300 Communicator

X-plore now also runs on Series 80 v2.0 (Symbian OS 7.0s), the platform of the
Nokia 9500 and 9300 Communicators. It has been tested on a Nokia 9500.

- Uses the whole 640 x 200 screen and the full keyboard.
- Keys: top command button = Menu (left soft key), bottom command button =
  Back (right soft key), rocker press or Enter = OK. Esc and the Menu key also
  work.
- Shows all drives, e.g. C: (Communicator memory), D: (memory card),
  E: (RAM disk) and Z: (ROM).
- Includes all 26 languages.

The Series 80 build lives in the `S80` folder. It is built on Linux with Wine and the
Nokia Series 80 DP 2.0 SDK:

    S80/scripts/build-s80-wine.sh build    # -> S80/sis/xplore.sis

Install `xplore.sis` on the Communicator. Build details are in [S80/README.md](S80/README.md).

The S60 2nd/3rd edition builds are unchanged: the Series 80 parts of the shared
code are only compiled when `S80` is defined (in `S80/xplore.mmp`).

The Series 80 port is unofficial and is not supported by Lonely Cat Games.
