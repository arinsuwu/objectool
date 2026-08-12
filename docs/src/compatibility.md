# Compatibility

## Compatibility with Kevin's Retry System

Thanks to Kevin's help, ObjecTool is fully compatible with the multiple midway points included in his Retry system. There are a couple of notes:
- Retry expects ObjecTool to be inserted first. Although to be safe, ObjecTool takes some safeguards to avoid your ROM from crashing, make sure you rerun UberASMTool to reinsert Retry *the first time you use ObjecTool*. Doing that all the time isn't needed, just the first time as a safeguard.
- Some standard object slots are restricted from the tool because said system claims them: namely standard objects `00-41`, `50` and `51` *cannot* be used by ObjecTool.

## Compatibility with old ObjecTool objects

- Objects made for the previous versions of ObjecTool expected code to be pasted into the appropriate object slots in the main patch's file, so a lot of errors will show up if you insert a file as-is. To fix these errors, all you need to do is look for all lines containing a ``JSR routineName``, and change it to ``%routineName()`` instead.
- The ObjecTool patch used to place everything in the same bank, and as such, objects needed to return with `RTS`. This is now changed, and objects expect to return with an `RTL` now.
- If the file has a ``.txt`` extension, change it to ``.asm``.
