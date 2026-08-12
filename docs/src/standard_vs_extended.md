# Standard and extended objects

## Basic object creation

This section assumes that the reader has basic ASM knowledge. It is for creating a custom object from scratch.  
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

