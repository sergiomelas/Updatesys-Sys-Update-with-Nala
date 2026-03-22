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
- Sid-Optimized "Strict Silence": Uses dry-run simulations to ignore
  held packages, only prompting when actual upgrades are possible.
- Surgical Consolidation: Single-page handling of APT, Flatpak, and
  Snap that only displays sources with pending updates.
- Precision Maintenance: Smart cleanup of orphaned kernel modules
  verified against dpkg status and running kernel version.
- DKMS Verification: Checks driver integrity (e.g., Goodix) post-update.
- Sid Protection: Dedicated manual confirmation for Full-Upgrades.

INSTALLATION:
Debian/Ubuntu/Sid: sudo apt install ./updatesys_1.2.1_all.deb

USAGE:
Type 'updatesys' from any command line or run via Alt+F2.
Desktop entry (Icon) is automatically created in System Tools.

##################################################################
Change log:

 -V1.0   20-02-2026:  - Universal Terminal support added.
                      - Removed strict Konsole dependency.
                      - Enhanced regex for silent update detection.

 -V1.1   03-03-2026:  - Added progress bar and improved workflow.
                      - Added calculation of freed space by cleaner.

 -V1.2   05-03-2026:  - Precision Kernel Maintenance.
                      - Shifted logic from simple string patterns (amd64)
                        to verifying against dpkg 'linux-image' status
                        and active uname -r.
 -V1.2.1 06-03-2026:  - Corrected Session Savings calculation
                       logic for cache cleaning.
                      - Updated Icon

 -V1.2.2 09-03-2026: Major Logic Overhaul for Sid.
                     - Implemented strict Simulation (Dry-Run)
                       checks to eliminate false "Update" prompts.
                     - Surgical Page Consolidation: Only managers
                       with actual work are displayed.
                     - Added DKMS Integrity Check for post-upgrade
                       driver verification.

-V1.3.1  22-03-2026: The "Sid Sentinel" Security Patch.
                      - Added "Domino Effect" detector: Script triggers
                        Emergency Brake if critical components (KDE/GNOME)
                        or >5 packages are marked for removal.
                      - Integrated Manual Override for legitimate major
                        transitions (e.g., KDE 5 to 6).
                      - Fixed UI overlap glitch with smart screen clears.
                      - Upgraded probe to dist-upgrade simulation for
                        high-accuracy detection during repo syncs.

##################################################################
