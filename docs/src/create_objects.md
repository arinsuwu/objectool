# Fundamentals of creating objects

This section assumes that the reader has basic ASM knowledge. It is intended to teach you hot to create a custom object from scratch.  
First, though, we will more formally define *objects*.

## Standard and extended objects

An object is a snippet of code which runs during the level load code.  
In the level data, an object is normally defined by three bytes:

- The *command number*. Nintendo allocated commands up to `3F`.
- The position within the current subscreen being processed by the level load code, of the form `yyyy xxxx`.
- A third byte, usually dedicated to the object type and its size.

Under this definition, every object is, in a way, a *standard object*.

### *Custom* standard objects

It is via the command number that the game decided *which* standard object to run. But first, depending on the *foreground tileset*, the game jumps to one of *five* routines that run standard object code. These then decide which object it's actually running. This is the way tileset specific objects can exist, recycling their command number.  
Command numbers `22-2F` are unused. Lunar Magic claims *all* of them for its own purposes, *except* for object 2D, which FuSoYa left reserved for a user defined object. It is special in that he actually reserved two more bytes in the level data for this object, the *extension*. These bytes are up to interpretation by the end user. ObjecTool assigns them this way:

- The first extension byte is the *custom object number*. It's used to decide the object to run.
- The second extension byte is the *extra byte*, an additional parameter passed to object code for your own user-defined purposes.

ObjecTool's hijack for standard objects runs earlier than the tileset-specific decision, to avoid having five hijacks which would do the same. But this doesn't preclude you from making your objects tileset specific: you can always read `$1931` (or the `!tileset` define) and make your object act different depending on the tileset.

### Extended objects

An *extended object* is actually a special kind of standard object. When the command number is `00`, the routine which runs the code for the command is bypassed, instead running a different one. Said routine reads the third byte of the object, and uses it as its *extended object number*. This is why extended objects can't be resized. Additionally, extended objects don't care about the tileset.  
Nintendo prepared pointers for 256 extended objects, but some are left unused. Namely, extended objects `02-0F` and `98-FF` free for use. Due to the possibility of Lunar Magic claiming the earlier numbers for its own purposes, only `98-FF` are supported for insertion by ObjecTool.

## Basic object creation

For custom object files, the code's start is at the ``load:`` label, and it ends with an ``RTL``.

Now, how do you make an object place a tile in its position in the level?
```asar
load:
    LDY $57
    LDA #$00
    STA [$6B],y
    LDA #$01
    STA [$6E],y
    RTL
```

That's pretty much it. This is code for an object that places Map16 tile ``$0100`` in its position. You can try inserting it either as an extended or normal object, and if done correctly it should work as intended, by placing a ledge tile.  
In case it's not apparent, ``[$6B]`` and ``[$6E]`` each are 3-byte long pointers to where the Map16 data for the object would be written, and they should be indexed with Y containing the value of ``$57``. ``[$6B]`` is the low Map16 byte data pointer, and ``[$6E]`` is the high byte's. So you just index those with Y and write to them.  
Now, what if we want to place TWO ledge tiles next to each other? Then we'd have to call one of the shift routines, like so:
```asar
load:
    LDY $57
    LDA #$00
    STA [$6B],y
    LDA #$01
    STA [$6E],y
    %ShiftObjRight()
    LDA #$00
    STA [$6B],y
    LDA #$01
    STA [$6E],y
    RTL
```
And there we go, that's code for a 2-tile wide ledge. Same deal as before, insert and it should work.

While we're at it, there's defines for common addresses you'd need for object code, so if you forget what ``$57`` is, you can replace it with ``!obj_pos``, and for convenience sake you can replace ``[$6B]`` with ``!map16_low`` and ``[$6E]`` with ``!map16_high``. A full reference can be found in the [Defines and RAM Map](./ram.md) section.
  
Now what if we want a ledge whose width depends on the size byte of the object? Then we'd need a loop, like so:
```asar
load:
    LDY $57
    ; StoreNybbles gets the position and size
    ; of an object and stores them to scratch RAM.
    ; $08 contains the width.
    %StoreNybbles()
    LDX $08
.loop
    LDA #$00
    STA [$6B],y
    LDA #$01
    STA [$6E],y
    %ShiftObjRight()
    DEX
    BPL .loop
    RTL
```
Not so hard, right? X takes the value of ``$08`` which for a normal object is the settings byte's low 4 bits (the width of the object), and X decreases each iteration until it reaches ``$FF``.  
So the sequence is: ledge tile is written, shift right, check if X negative, decrease X and if X still positive then branch to ``.loop``. This happens until X (initially containing the width) is negative.

Let's take it a step further by adding height:
```asar
load:
    LDY $57
    %StoreNybbles()
    LDA $09
    STA $00
.loopV
    LDX $08
.loopH
    LDA #$00
    STA [$6B],y
    LDA #$01
    STA [$6E],y
    %ShiftObjRight()
    DEX
    BPL .loopH
    %ShiftObjDown()
    DEC $00
    BPL .loopV
    RTL
```
Now we have an object that places tiles both vertically and horizontally.  
What we did here is basically a loop inside of a loop. For each iteration of the vertical loop, an entire row of tiles gets written. Since Y is busy being the Map16 pointer index and X is busy being the horizontal loop's counter, we can use scratch RAM ``$00`` instead.  
So ``$00`` holds the height, X holds the width, and each iteration goes:
>  Give X the width, then write an entire row of tiles, and once that's done shift down one tile (the routine resets the X position, so we're back to the object's horizontal origin), decrease $00 and check if it's negative, otherwise go through the same process again.

Okay, that's great and all, but it's just one tile! So let's make the next step change the tiles depending on the current position:
```asar
table:
    dw $0100,$003F

load:
    LDY $57
    %StoreNybbles()
    LDA $09
    STA $01
    LDX #$00
.loopV
    LDA $08
    STA $00
.loopH
    LDA table,x
    STA [$6B],y
    LDA table+1,x
    STA [$6E],y
    %ShiftObjRight()
    DEC $00
    BPL .loopH
    %ShiftObjDown()
    CPX #$00
    BNE +
    INX #2
+   DEC $01
    BPL .loopV
    RTL
```
Here's what was changed: X no longer holds the width because we need it for indexing the table, so ``$00 = width``, ``$01 = height``, X = tile index.  
It's basically the same thing as before, except this time after the first row is written X increases if it equals ``#$00``, which is what we set it initially as. So every row after the first, it places a dirt tile.  
And that's pretty much it! We have a resizeable custom ledge object.

Of course, there's more to objects than just this, and it can get pretty intense if you're coding something like slopes, but it just boils down to place, shift, place, shift.  
You can check the included objects if you want something to base your code on.

## Word parameters

Unlike standard objects, extended objects do not have a settings byte or an extra byte, which is why an object is better off being extended if it doesn't require either of those. However, what if multiple extended objects share mostly the same code, yet they can be slightly different? For example, just a different Map16 tile or table? Wouldn't it be a waste of ROM space to include multiple blocks of code of objects that are almost identical?  
That's what *word parameters* are for. Two or more objects can use the same .asm file, but the code considers their assigned word parameter in the list file and adapts accordingly. Word parameters are available to both standard and extended objects. They are 16-bits (a *word*) long, and are indexed by ``<object number>*2``.

The information of every word parameter used is saved in the ROM in case you need to access it from another resource. In ObjecTool, this is done via the `standard_word_params` and the `extended_word_params` tables, each indexed by the respective object number. In other tools, you can do `read3($0DA100+11)` to find the location of the standard word parameters, and `read3($0DA100+11)+512` for the location of the extended word parameters.

Additionally, the word parameter for the current object can be accessed via ObjecTool using the define `!word_param`, but this is meant for tooltip use and will misbehave if you insert multiple copies of the same object.

## Lunar Magic tooltips and list

As mentioned before, ObjecTool allows you to create display tooltips and list entries for the custom objects you insert. This is handled via two defines: `!tooltip` and `!list`.

Define | Purpose
-|-
`!tooltip` | The text displayed when you hover over the object in Lunar Magic.
`!list` | The text displayed on the Custom Collections of Objects list in Lunar Magic.

You would fill the defines as you would any other, inside the object's asm file, with the string you want to show. For example:
```asar
!tooltip = "An object which is custom. Nice!"
!list    = "Custom object."
```

If you don't fill these, a default generic string will be given for both.  
Finally, run ObjecTool with `--generate_tooltip=false` to disable tooltips from being made.

