;    <-                 228 (114)             ->
;    <- 68 -> <-             160 (80)         ->
;   +--------+----------------------------------+  
;   |                      VSYNC                ]0       3        ^
;   |                                           |                 |
;   +--------+----------------------------------+               
;   |                      VBLANK               |      37 
;   |                                           |
;   |                                           |
;   +--------+----------------------------------+
;   |        |                                  ]---40 (20) FIRST DRAW LINE
;   |        |                                  |
;   |        |                                  |               262
;   | HBLANK |            DRAW AREA             |     192      
;   |        |                                  |
;   |        |                                  |
;   +--------+----------------------------------+
;   |                                           ]---232 (116) FIRST OVERSCAN LINE
;   |                OVERSCAN                   |      30        |
;   |                                           ]---262 (82)     v
;   +--------+----------------------------------+         
;
; Screen Dimensions in Pixel (and raster lines in parentheses) values
;
; Total pixels = l*w = 228*262 =59736
; The 1 byte, VIC register @ $9004 takes on the "TV raster beam line" value.
; The value ranges over 83 possible states indexed from zero [0, 82].
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; LORES_COPYDOUBLE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Copy the char and color double buffers to the respective screen buffers.
; INPUT: -
; OUTPUT: -
; TRASHED: X,A
; EXAMPLE:  
; NOTES: Assumes SCREEN_TILE_COUNT < $100
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
lores_copydouble SUBROUTINE
  LDX #SCREEN_TILE_COUNT
.loop
  LDA double_char-1,X
  STA VIC_CHAR_LO-1,X
  LDA double_color-1,X
  STA VIC_COLOR_LO-1,X
  DEX
  BNE .loop 
  RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; LORES_SHIFTDOUBLE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Shift each element of the char and color double buffers left once.
; INPUT: -
; OUTPUT: -
; TRASHED: A,X,Y
; EXAMPLE: JSR lores_shiftdouble;
; NOTES: Assumes SCREEN_TILE_COUNT > 2 
;				 Assumes SCREEN_TILE_COUNT < $100
;				 The FIRST element is dropped, while the LAST element is unchanged.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
lores_shiftdouble SUBROUTINE
  LDX #PLAYFIELD_START
.loop
  ; shift b[x] <- b[x+1]
  LDA double_char+1,X
  TAY
  AND #ANIMATE_FLAG
  BNE .no_animate
  INY
  TYA
  AND #~ANIMATE_FLAG 
  TAY
.no_animate
  TYA
  STA double_char,X
	LDA double_color+1,X
  STA double_color,X
  INX
  CPX #(PLAYFIELD_TILE_COUNT+PLAYFIELD_START-1)
  BNE .loop
  RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; LORES_SHIFTDOUBLE_R
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Shift each element of the double buffer right once.
; INPUT: -
; OUTPUT: -
; TRASHED: A,X,Y
; EXAMPLE: JSR lores_shiftdouble;
; NOTES: Assumes SCREEN_TILE_COUNT > 2 
;				 Assumes SCREEN_TILE_COUNT < $100
;				 The FIRST element is dropped, while the LAST element is unchanged.
;				 This could be generalized into the non-reverse method
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
lores_shiftdouble_R SUBROUTINE
  LDX #PLAYFIELD_START+PLAYFIELD_TILE_COUNT-1
.loop
  ; shift b[x] <- b[x-1]
  LDA double_char-1,X
  TAY
  AND #ANIMATE_FLAG
  BNE .no_animate
  INY
  TYA
  AND #~ANIMATE_FLAG
  TAY
.no_animate
  TYA
  STA double_char,X
	LDA double_color-1,X
  STA double_color,X
  DEX
  CPX #PLAYFIELD_START
  BNE .loop
  RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DATA
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; we add #LEVEL_LEN_GRANULARITY columns of start/end tiles to simulate the start
; area. If the player backtracks this will be generated by code in the double-
; buffer level loader that checks for the player coming close enough to the 
; bounds of the level to start loading start/end tiles in on the active side 
; being loaded to.
double_color:
  .byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 ;1
  .byte 2,2,2,2,2,2,2,2,2,2,2,3,3,3,3,3,3,3,3,3,3,3
  .byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
  .byte 2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,1
  .byte 3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,1
  .byte 4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,4,1
  .byte 5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,1
  .byte 6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,6,1
;;
  .byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1
  .byte 5,5,5,5,5,5,5,5,5,5,5,6,6,6,6,6,6,6,6,6,6,6
  .byte 1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1 ;11

 ; this single byte is used to store a clone of the highest digit of the player score. it is used
 ; to cheaply detect underflow in the mod_score routine !!!DO NOT MOVE!!!
 DC $2C
double_char:
  .byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
  .byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
  .byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$24
  .byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$24
  .byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$1c
  .byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$24
  .byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$24
  .byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
  .byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25
	.byte $25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25,$25