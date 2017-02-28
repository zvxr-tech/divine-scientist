;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; KERNAL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
GETIN EQU $FFE4
CHROUT EQU $FFD2
SCNKEY EQU $FF9F
CLRCHN EQU $FFCC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; VIC Charset Keycodes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
CH_A EQU $41
CH_B EQU $42
CH_C EQU $43
CH_D EQU $44
CH_E EQU $45
CH_F EQU $46
CH_G EQU $47
CH_H EQU $48
CH_I EQU $49
CH_J EQU $4A
CH_K EQU $4B
CH_L EQU $4C
CH_M EQU $4D
CH_N EQU $4E
CH_O EQU $4F
CH_P EQU $50
CH_Q EQU $51
CH_R EQU $52
CH_S EQU $53
CH_T EQU $54
CH_U EQU $55
CH_V EQU $56
CH_W EQU $57
CH_X EQU $58
CH_Y EQU $59
CH_Z EQU $5A

CH_SPACE EQU $20
CH_CR EQU $0D
CH_UP EQU $11
CH_DOWN EQU $91


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Graphics
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Screen Memory Pointer ($f2 size total)
VIC_CHAR_LO EQU $1E00 ; $ff in size
VIC_COLOR_LO EQU $9600 ; $1fa in size


; VIC chip addresses
VIC_COLOR EQU $900F
; RASTER runs 0-$82 (131 lines)
;(MSB) xxxxxxxxy   (LSB)
VIC_RASTER EQU $9004 ;x
VIC_RASTER_AUX EQU $9003 ;y

VIC_NOISE_CH EQU $900D


; A logical view of the visible screen is shown below.
;
;___________________________+
;     UPPER STATUS ROW1     |
;_____UPPER STATUS ROW2_____|
;______UPPER PLAYFIELD______|
;   UPPER PLAYBOARD (ROW1)  |
;      PLAYBOARD ROW2       |
;      PLAYBOARD ROW3       |
;      PLAYBOARD ROW4       |
;   LOWER PLAYBOARD (ROW5)  |
;______LOWER PLAYFIELD______|
;     LOWER STATUS ROW2     |
;_____LOWER STATUS ROW1_____+
;
; The player is restricted to the playboard.
; The playfield (incl playboard) shift left every game tick(), except when special powers
; "reverse" time. (In which case it's left-to-right.)
; New level is content is loaded from the right side. (Again, reversed sometimes.)



; The following constants define the geometry of the game screen and double 
; buffers that mirror them
; (zero-indexed, unless otherwise noted)

;SCREEN
SCREEN_ROW_COUNT EQU 11
SCREEN_COL_COUNT EQU 22
SCREEN_TILE_COUNT EQU SCREEN_ROW_COUNT*SCREEN_COL_COUNT

; DOUBLE BUFFER
DOUBLE_ROW_COUNT EQU SCREEN_ROW_COUNT 
DOUBLE_COL_COUNT EQU SCREEN_COL_COUNT
DOUBLE_TILE_COUNT EQU SCREEN_TILE_COUNT 


;STATUS
UPPER_STATUS1_ROW EQU 0
LOWER_STATUS1_ROW EQU 1

UPPER_STATUS2_ROW EQU 9
LOWER_STATUS2_ROW EQU 10



DOUBLE_CHAR_SCORE_VECTOR EQU double_char+UPPER_STATUS1_ROW
DOUBLE_CHAR_HISCORE_VECTOR EQU double_char+LOWER_STATUS2_ROW*DOUBLE_COL_COUNT


;PLAYBOARD
UPPER_PLAYBOARD_ROW EQU 3
LOWER_PLAYBOARD_ROW EQU 7

PLAYBOARD_ROW_COUNT EQU LOWER_PLAYBOARD_ROW-UPPER_PLAYBOARD_ROW+1
PLAYBOARD_COL_COUNT EQU SCREEN_COL_COUNT
PLAYBOARD_TILE_COUNT EQU PLAYBOARD_COL_COUNT * PLAYBOARD_ROW_COUNT
PLAYBOARD_START EQU ((UPPER_PLAYBOARD_ROW)*PLAYBOARD_COL_COUNT)

;PLAYFIELD
UPPER_PLAYFIELD_ROW EQU 2
LOWER_PLAYFIELD_ROW EQU 8

PLAYFIELD_ROW_COUNT EQU LOWER_PLAYFIELD_ROW-UPPER_PLAYFIELD_ROW+1
PLAYFIELD_COL_COUNT EQU SCREEN_COL_COUNT
PLAYFIELD_TILE_COUNT EQU PLAYFIELD_COL_COUNT * PLAYFIELD_ROW_COUNT
PLAYFIELD_START EQU ((UPPER_PLAYFIELD_ROW)*PLAYFIELD_COL_COUNT)

; the column the player is limited to
PLAYER_COL EQU 10


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SPRITES
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; custom "sprite" charset indicies
; For animated sprites, this points to the 1st (of 4) frame.
GOLD_SM_TILE EQU $00
CAT_BG_TILE EQU $04
GOLD_LG_TILE EQU $08
CAT_NBG_TILE EQU $0C
MONSTER_SM_TILE EQU $10
PLAYER_BG_TILE EQU $14
MONSTER_LG_TILE EQU $18
PLAYER_NBG_TILE EQU $1C
STAR_A_TILE EQU $20
FILLED_TILE EQU $24
EMPTY_TILE EQU $25
PLAYER_HAPPY EQU $26
PLAYER_SAD EQU $27
STAR_B_TILE EQU $28
CH_0_TILE EQU $2C
CH_1_TILE EQU $2D
CH_2_TILE EQU $2E
CH_3_TILE EQU $2F
CH_4_TILE EQU $30
CH_5_TILE EQU $31
CH_6_TILE EQU $32
CH_7_TILE EQU $33
CH_8_TILE EQU $34
CH_9_TILE EQU $35


; if set, this flag indicates that the double_buffer animator 
; lores_shiftdouble should not animate a tile.
ANIMATE_FLAG EQU 4


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; PLAYER
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; default values on start
PLAYER1_DIR_START EQU 00
PLAYER1_Y_START EQU 02
PLAYER1_START_TILE EQU FILLED_TILE

; Directions that a player might be moving
DIRECTION_NONE EQU $00
DIRECTION_UP EQU $01
DIRECTION_DOWN EQU $FF





;!!  MODIFYING the PAINT CONSTAINTS???
; These constants must be non-negative, because code is optimized to make use of 
; that property.
MAX_NUM_PAINT EQU 4
MAX_NUM_REAL_PAINT EQU 5
MIN_PAINT EQU 0 
MAX_PAINT EQU 11 
SPECIAL_PAINT_ROW EQU 2

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; TIMING
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; frequency of each game tick (Hz)
DEFAULT_SPEED_RATE EQU 4
DEFAULT_FREQ EQU 60/DEFAULT_SPEED_RATE
MAX_FREQ_COUNT EQU 4
FREQUENCY_MODULATION EQU 3

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MISC
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Number of digits used to display the score
SCORE_LEN  EQU 9

; this is the base of each score digit
SCORE_RADIX EQU 10
	
	

; how many tracer states occupy 1 byte
TRACER_PER_BYTE EQU 4


NOT_END EQU 0
AT_END EQU 1
PAST_END EQU $80

; how many columns the level start/end landing areas are composed of
; the level loader depends on this being two
START_END_LANDING_LEN EQU 1


CURSOR_LO_START EQU $FF

;;LEVEL_CURSOR_SHOW_FINAL EQU ((PLAYBOARD_COL_COUNT-PLAYER_COL)/LEVEL_LEN_GRANULARITY) + (((PLAYBOARD_COL_COUNT-PLAYER_COL) % LEVEL_LEN_GRANULARITY) > 0)
;;LEVEL_CURSOR_SHOW_FINAL_R EQU ((PLAYER_COL/LEVEL_LEN_GRANULARITY) + ((PLAYER_COL % LEVEL_LEN_GRANULARITY) > 0) - 1)

LEVEL_CURSOR_SHOW_FINAL EQU DOUBLE_COL_COUNT - PLAYER_COL
LEVEL_CURSOR_SHOW_FINAL_R EQU PLAYER_COL + 1


LEVEL_CURSOR_SHOW_FINAL_XOR EQU (LEVEL_CURSOR_SHOW_FINAL^LEVEL_CURSOR_SHOW_FINAL_R)


; this gives the absolute offset into the double buffer of the first cell to
; load (playfield row 1)
LEVEL_LOAD_VECTOR EQU	((PLAYBOARD_COL_COUNT*3)-1)
; the same vector for reverse mode
LEVEL_LOAD_R_VECTOR EQU	((PLAYBOARD_COL_COUNT*2))
; XOR toggle for the LOAD vectors
LEVEL_LOAD_VECTOR_XOR EQU (LEVEL_LOAD_R_VECTOR^LEVEL_LOAD_VECTOR)



PLAY_DIR_FORWARD EQU (-1)
PLAY_DIR_REVERSE EQU 1

; this is used to toggle an instruction in the reverse-mode set that will 
; call either rnd or rnd_R
RND_TOGGLE EQU <(rnd^rnd_R)
; we also do a sanity check to make sure the addresses differ only in the LSB
 IF (>rnd != >rnd_R);
 ECHO "Function rnd and rnd_R must be withing the same $100 alignment"
 ERR
 ENDIF

 

 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ZP Vectors
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; These addresses contain pointers that are used to quickly lookup addresses
; in the double buffer.

; Memory locations of the left/right-most column cells
; (each macro points to a set of 5 addresses)
PLAYBOARD_CHAR_LEFT_VECTOR   EQU $10
PLAYBOARD_COLOR_LEFT_VECTOR  EQU $20
PLAYBOARD_CHAR_RIGHT_VECTOR  EQU $30
PLAYBOARD_COLOR_RIGHT_VECTOR EQU $40
; END $26 (inclusive)
 
; the locations these constants point to will hold a contiguous set of 16bit
; memory addresses, each one being the location the player sprite can occupy
; on the gameboard
DOUBLE_CHAR_PLAYER_VECTOR EQU $50
; same as above, but 1 position to the left.
; we store this set of vectors to trade memory for less time.
DOUBLE_CHAR_PLAYER_VECTOR_M1 EQU $60 
DOUBLE_CHAR_PLAYER_VECTOR_P1 EQU $70 
; END @ $35 (inclusive)
