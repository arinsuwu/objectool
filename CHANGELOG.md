v2.0.0 (Arinsu)
---
### Features
- Tool ASM base rewritten.
  - Diverts from old ObjecTool in where the tool hacks, opting for an earlier hack in bank 05.
  - The ASM now handles both vanilla and custom extended objects by leveraging the space for unused extended objects.
  - Added handling for Kevin's Multiple Midway Points, which ship with his Retry system. This reserves standard objects 00-41, 50 and 51.
  - The 15 bytes starting at `$0DA100` have been claimed by ObjecTool for the following purpose:
    - Four bytes for a signature: `OT`, followed by the current version and subversion.
    - Four bytes reserved for Multiple Midway Points.
    - Three bytes for a pointer to the custom standard object pointers.
    - Three bytes for a pointer to the standard object word parameters.
    - One byte reserved.
  - For the most part I attempted to keep compatibility with old ObjecTool, but some parts change:
    - Custom objects of any kind must now end with `RTL` because they are *not* guaranteed to be in the same bank as the tool. Data bank is still set.
    - Extended objects have the *true* extended object number(i.e. the offset `$98` was not subtracted for it) in X, in analogy for the vanilla extended objects. Standard objects have *no discernible info* in any register.
- Tool C++ base rewritten.
  - Now equalized with BOWSIE's workflow.
- Added the ability to generate display tooltips and list entries for Lunar Magic, which were introduced in version 3.60.
  - The tool includes ``--osc``, ``--mw0`` and ``--mw0t`` switches to append an external set of display files to whatever ObjecTool generates.
  - The list has ``@osc`` and ``@mw0t`` commands to directly append entries to the display files ObjecTool generates.

This wouldn't have been possible without Burning Loaf, Donut and Kevin, so special thanks to them!

v1.0.0 (Burning Loaf)
---
### Features
- Initial release.