# Included objects

## Standard or extended objects
Filename | Description | Word parameter
-|-|-
``cluster.asm`` | Creates a group of Map16 tiles with a specified set of dimensions. | As an extended object: determines which table it should use.

## Standard objects
Filename | Description | Extra byte and word parameter
-|-|-
``square.asm``/``squareBig.asm`` | Create an array of tiles that can be stretched along both axes according to the size in Lunar Magic. The "big" variation also uses the extra byte for 8 additional size bits (yyyyxxxx) to allow making the object larger (note, that Lunar Magic will not take the extra size bits into account when displaying the object in the editor). | ``square``: The object's extra byte determines which table to use. ``squareBig``: The object's parameter word determines which table to use.
``square2.asm``/``squareBig2.asm`` | The above, but their tiles change when over top of a non-blank tile. | ``square2``: The object's extra byte determines which table to use. ``squareBig2``: The object's parameter word determines which table to use.
``horiz2End.asm`` | Creates an array of tiles that can be stretched horizontally only. | The object's extra byte determines which table to use.
``vert2End.asm`` | Creates an array of tiles that can be stretched vertically only. | The object's extra byte determines which table to use.
``unidimensional.asm`` | Creates an array of tiles that can be stretched in only one direction. | The object's extra byte determines which table to use.
``unidimensional2.asm`` | The above, but its tiles change when over top of a specific tile number. | The object's extra byte determines which table to use.
``unidimensionalWide.asm`` | Like the first unidimensional object, except that the object is 2 tiles wide instead of 1. | The object's extra byte determines which table to use.
``itemMemory1x1.asm`` | Creates an array of a single Map16 tile that can be stretched in both directions and set to take item memory into account. | The object's extra byte determines which table to use.
``ledge.asm`` | Creates an array of tiles that can be stretched in both directions, be set to have any combination of 4 edges, and will change according to which tiles it is placed over. | The object's parameter word and extra byte determine which table to use. Additionally, the object's extra byte determines the ledge part.
``slopes.asm`` | Creates a variety of slope types. | The object's parameter word indicates the slope type. The object's extra byte determines which table to use.

## Extended objects
Filename | Description | Word parameter
-|-|-
| ``Objects1x1.asm`` | Creates a single Map16 tile. | Determines which table to use.
| ``Objects2x1.asm`` | Creates 2 tiles in a 2x1 arrangement. | Determines which table to use.
| ``Objects1x2.asm`` | Creates 2 tiles in a 1x2 arrangement. | Determines which table to use.
| ``Objects2x2.asm`` | Creates 4 Map16 tiles in a 2x2 arrangement. | Determines which table to use.

