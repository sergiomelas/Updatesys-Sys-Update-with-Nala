##################################################################
#                                                                #
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
- Consolidated Workflow: Single-page handling of APT, Flatpak, and Snap.
- Explicit Reporting: Clearly states "No updates" for specific sources.
- Precision Maintenance: Smart cleanup of orphaned kernel modules.
- DKMS Verification: Checks driver integrity (e.g., Goodix) post-update.
- Sid Protection: Dedicated manual confirmation for Full-Upgrades.

INSTALLATION:
Debian/Ubuntu/Sid: sudo apt install ./updatesys_1.2.1_all.deb

USAGE:
Type 'updatesys' from any command line or run via Alt+F2.
Desktop entry (Icon) is automatically created in System Tools.

##################################################################
Change log:

 -V1.0   20-02-2026: Universal Terminal support added. Removed
                     strict Konsole dependency. Enhanced
                     regex for silent update detection.

 -V1.1   03-03-2026: Added progress bar and improved workflow.
                     Added calculation of freed space by cleaner.

 -V1.2   05-03-2026: Precision Kernel Maintenance. Shifted logic
                     from simple string patterns (amd64) to
                     verifying against dpkg 'linux-image' status
                     and active uname -r.

 -V1.2.1 09-03-2026: Consolidated all update sources into a single
                     visual page. Added explicit status reporting
                     (No normal package/Flatpak/Snaptd updates).
                     Integrated DKMS integrity check to verify
                     drivers after SID kernel transitions.
##################################################################
