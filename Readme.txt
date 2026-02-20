##################################################################
#                        updatesys tool                          #
#        Developed for Bash by Sergio Melas 2021-2026            #
#                                                                #
#                Email: sergiomelas@gmail.com                    #
#                    Released under GPL V2.0                     #
#                                                                #
##################################################################

UpdateSys is a universal, high-fidelity system maintenance utility.
It is designed to work across different desktop environments by
automatically detecting the available terminal emulator.

KEY FEATURES:
- Nala-style Progress bar (Green/Red/Cyan/Yellow morphing).
- Terminal Auto-Detection: Works with Konsole, GNOME, XFCE, and more.
- Intelligent Silent Check: Only prompts if [1-9] updates exist.
- Multi-Source: Sequential handling of APT, Flatpak, and Snap.
- Optimized Geometry: Automatically attempts 900x600 window sizing.

INSTALLATION:
Debian/Ubuntu/Sid: sudo apt install ./updatesys_1.1.0_all.deb

USAGE:
Type 'updatesys' from any command line or run via Alt+F2.
Or use the Icon

##################################################################
Change log:

 -V1.0   20-02-2026: Universal Terminal support added. Removed
                     strict Konsole dependency. Enhanced
                     regex for silent update detection.
##################################################################
