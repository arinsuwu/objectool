# ObjecTool
*v2.0.0 by Arinsu and Burning Loaf*

## What are Objects?

For the sake of Super Mario World hacking, especially in the context of Lunar Magic, you probably think an *object* as some sort of block or blocks. After all, when you, say, insert a custom block with GPS and place it in a level, is that not just placing an object? The answer, perhaps confusingly, is *yes* and *no*. In a way, yes, placing your custom block directly in a level using Direct Map16 is akin to placing an object, but the custom block is the code that actually *runs* during the game. The *object* is the code that placed the block there in the first place!  
Being more formal, to Super Mario World, an *object* is a piece of code, which runs *during level load only*, and which takes cares of properly deciding which *Map16 tiles* -- i.e. blocks -- to place in the level. An object might check certain RAM flags and depending on their value, make a different Map16 tile be placed in the level. For a couple of examples:

1. The ! blocks will display as dotted lines if you haven't pressed the adequate switch palace.
2. In many instances, things like coins don't reappear once you collected, leave for a sublevel, then return. That's because the *block* side sets an item memory bit: when exiting and returning, the *object* side verifies said item memory, and if it's marked as set, the object instead places a blank tile.

Objects come in two types, *standard* objects and *extended* objects. This is a basic explanation: for their more technical differences, see the [Standard and extended objects](./standard_vs_extended.md) section.
- *Standard objects* can actually vary depending on the level tileset. They can be resized, and as such, they usually render arrangements which can take different sizes, like ledges or slopes.
- *Extended objects* are available in every level. They can't be resized. These objects usually render tiles such as item blocks, or tile arrangements which don't need to change sizes such as large bushes.

## What's ObjecTool?

*ObjecTool* allows you to insert custom objects, both standard and extended.  
The original version of ObjecTool was actually a patch made by [0x400](https://smwc.me/u/109) -- she developed it all the way back in [2008](https://smwc.me/t/9610)! A couple of years after, [imamelia](https://smwc.me/u/3471) took over updating said patch, and her patch version is the most commonly used object-inserting resource to this day.  
More than a decade later, in 2024, [Burning Loaf](https://smwc.me/u/31800) made v1.0.0 of the actual ObjecTool, using imamelia's patch as a base, and adding innovations such as shared subroutines and word parameters. Beginning in 2026, the current tool is being developed by [Arinsu](https://smwc.me/u/17672): it's a complete rewrite from the old patch adn tool, though its objects are compatible for the most part; and it adds support for Lunar Magic tooltips.

