# ROM and Hijack Map

## Hijacks

Address | Size | Description
-|-|-
`$0586C5` | 16 | Rewrites the branching of standard vs. extended objects to get to the ObjecTool handlers faster.
`$0DA415` | 5 | Adds some vanilla code back to disable an old handler for Kevin's Multiple Midway Points (only if those are enabled).

## Claimed vanilla freespace

Address | Size | Description
-|-|-
`$0DA100` | 15 | ObjecTool's signature. See below.
`$0DA2D7` | 312 | Pointers for extended objects `98-FF`.
`$0DC620` | 300 | Pointers for shared subroutines. Used for cleanup.

### ObjecTool signature

Taking advantage of 15 bytes of vanilla freespace created at `$0DA100`, ObjecTool inserts some information it needs to fully work:

Address | Size | Description
-|-|-
`$0DA100` | 2 | The string `OT`.
`$0DA102` | 2 | The tool's version and subversion.
`$0DA104` | 4 | Four bytes reserved for Kevin's Multiple Midway Points as a way to jump to its code from ObjecTool.
`$0DA108` | 3 | Pointer to the standard object pointers. Used for cleanup.
`$0DA10B` | 3 | Pointer to the word parameter tables. Used for cleanup.
`$0DA10E` | 1 | Empty for now, but reserved.

