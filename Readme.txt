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
Debian/Ubuntu/Sid: sudo apt install ./updatesys_1.3.5_all.deb

USAGE:
Type 'updatesys' from any command line or run via Alt+F2.
Desktop entry (Icon) is automatically created in System Tools.

##################################################################
Change log:


 -V1.3.6   30-06-2026: The "Byte-Perfect Panda Guardian" Production Release.
                      - Patched global syntax scopes (`local`), dynamic boolean variable validation
                        (`CRITICAL_HIT`), acurate block byte storage accounting via `df`, and robust 
                        background spinner stream cleanups.
                      - Cleans a plethora of small cosmetic bugs.

 -V1.3.5   25-06-2026: The "Surgical Precision Sniper" Transition Release.
                      - Hardened extraction scopes to trap simulation removals (`Remv`/`Purg`) and 
                        input frameworks (`maliit`).
                      - Redesigned visual hardware telemetry banner into a balanced 79-column laptop workspace layout.

 -V1.3.4   03-06-2026: The "Surgical Precision Sniper" Update.
                      - Rewrote data engines to parse updates line-by-line, ending false removal warnings.
                      - Integrated network exception fallbacks avoiding terminal hangs on stalled Snap APIs.

 -V1.3.3   20-04-2026: The "Sentinel Precision" Update.
                      - Stripped package version metadata strings away from backend security array tracking.
                      - Hardened automated package group isolation routines to intercept hidden input-method drops.

 -V1.3.2  26-03-2026: The "Grand Master" Diagnostic & UX Update.
                      - Embedded live terminal heartbeat progress indicators during long network transactions.
                      - Created a granular, weighted risk score algorithm covering 16 infrastructure categories.

 -V1.3.1  22-03-2026: The "Sid Sentinel" Security Patch to avoid residual disaster.
                      - Built an emergency system interrupter guarding core desktop environmental items.
                      - Switched background dependency validation queries to full dist-upgrade simulations.

 -V1.2.2 09-03-2026:  The "Baby Sentinel" Major Logic Overhaul for Sid disaster avoidance.
                      - Implemented safe simulation simulations to suppress broken dependency upgrade flags.
                      - Added driver validation checks across DKMS infrastructures following installations.

 -V1.2.1 06-03-2026:  The "Wise Administrator" patch
                      - Corrected edge-case mathematical errors in the package cache tracking logic.
                      - Restyled the default desktop utility launch icon configuration layout.

 -V1.2   05-03-2026:  The "Wise Administrator" integrate kerne maintenance and cleanups
                      - Deployed a smart routine to discover and remove orphaned driver directories.
                      - Tied kernel cleanup rules directly to active dpkg status records.

 -V1.1   03-03-2026:  The "handsome" interlace overhaul
                      - Integrated a responsive, multi-colored progress bar workflow interface.
                      - Added telemetry calculation tracking cumulative disk storage space saved.

 -V1.0   20-02-2026:  The "baby" First Public version on GITHUB
                      - Added universal terminal emulator detection and removed strict dependency on Konsole.
                      - Hardened simulation matching filters using advanced regular expressions.

 -V0.1   15-05-2019:  The "ancestor" Private Edition for personal use
                      - Created initial core script architecture for automated package maintenance.
                      - Integrated basic cleanups for local APT cache and system log files.
















##################################################################
