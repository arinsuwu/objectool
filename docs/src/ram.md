# Defines and RAM Map

## General purpose defines
Define | Value | Description
-|-|-
`sa1` | 1 if SA-1 is installed | Whether SA-1 is being used.
`fullsa1` | 1 if a 6/8MB SA-1 ROM | Whether this is a big SA-1 ROM (6/8MB).
`dp` | `$0000` (lorom) / `$3000` (SA-1) | Direct page RAM offset.
`addr` | `$0000` (lorom) / `$6000` (SA-1) | Address size RAM offset.
`bank` | `$800000` (lorom) / `$000000` (SA-1) | High bit of the mapper.
`ram` | `$7E0000` (lorom) / `$400000` (SA-1) | Bank for full RAM.

## Helper defines for custom objects

Define | Value | Description
-|-|-
``!obj_pos`` | ``$57`` | Position of the object within the subscreen.
``!extended_num`` | ``$59`` | Extended object number.
``!obj_settings`` | ``$59`` | Standard object size or type.
``!obj_num`` | ``$5A`` | Custom standard object number.
``!extra_byte`` | ``$58`` | Standard object extra byte.
``!map16_low`` | ``[$6B]`` | Pointer to the low byte of Map16 data.
``!map16_high`` | ``[$6E]`` | Pointer to the high byte of Map16 data.
``!obj_screen`` | ``$1928\|!addr`` | Screen where the object was placed.
``!tileset`` | ``$1931\|!addr`` | Foreground tileset.
``!tile_screen`` | ``$1BA1\|!addr`` | Screen where the current tile is being placed.
``!word_param`` | Word parameter | Word parameter.

## Versioning defines
Define | Description
-|-
`!objectool_version` | ObjecTool version (i.e. the first number in vX.X.X) 
`!objectool_subversion` | ObjecTool subversion (i.e. the second number in vX.X.X)

## Labels
Label | Location | Size | Description
-|-|-|-
`standard_word_params` | `read3($0DA100+11)` | 512 | Standard object word parameters. Indexed by the object number times two. Defaults to `0000` when none is given.
`extended_word_params` | `read3($0DA100+11)+512` | 208 | Extended object word parameters. Indexed by the object number times two. Defaults to `0000` when none is given.