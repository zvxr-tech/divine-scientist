;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; UPDATE_PLAYER
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Update position, animate, and handle player events
; INPUT: -
; OUTPUT: -
; TRASHED: A,X,Y
; EXAMPLE:  -
; NOTES: The conditional tree used to identify a tile, works on the assumption
;				 that the charcode will be < $80 (non-negative).
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
update_player SUBROUTINE
	; turn off SFX
	LDA VIC_NOISE_CH
	AND $7F
	
	; Restore the tile the player is leaving
	LDA player1.y
	ASL
	TAX
	
	LDA level.play_direction
	BMI .forward1
	LDA player1.old_tile ;load the old tile before the player occupied the space
	;LDA #GOLD_SM_TILE
	STA (DOUBLE_CHAR_PLAYER_VECTOR_P1,X) ; restore the old tile
	JMP .reverse1
.forward1
	LDA player1.old_tile ;load the old tile before the player occupied the space
	;LDA #GOLD_SM_TILE
	STA (DOUBLE_CHAR_PLAYER_VECTOR_M1,X) ; restore the old tile
.reverse1

	
	; update the players vertical position, dependent on their motion
	
.move_player
	LDA player1.y
	CLC
	ADC player1.dir ; 1 or -1 (2compliment) = 
	TAX
	BMI .mv_skip
	SEC
	SBC #PLAYBOARD_ROW_COUNT
	BPL .mv_skip	 ; #3 ; this will capture 0 <= y <= 3BMI .mv_skip
	; valid movement
	TXA
	STA player1.y
	JMP .mv_done
	
;DEBUG try separating this into forw/reverse
.mv_skip
	; we need to reflect whether or no the move was valid/made for the tracer push
	LDA #DIRECTION_NONE 
	STA player1.dir
.mv_done
	
	; load the player sprite into the tile it's entering
	LDA player1.y
	TAY ; mod_paint needs Y to contain the playboard row of the player
	ASL
	TAX
	
	
	LDA (DOUBLE_CHAR_PLAYER_VECTOR,X) ; load the new location char type
	

	
	; detect events resulting from the player's new position and handle them
	;EMPTY_TILE
	CMP #EMPTY_TILE
	BNE .10
	; do empty tile
	LDA #(-2)
	JSR mod_score
	LDA #(-1) 
	JSR mod_paint
	JMP .empty
.10
	;FILLED_TILE
	CMP #FILLED_TILE
	BNE .11
	; do filled tile
	LDA #1
	JSR mod_score
	LDA #1
	JSR mod_paint
	JMP .filled
.11
	;GOLD_SM_TILE
	SEC
	SBC #4
	BPL .12
	; do gold small
	LDA #4
	JSR mod_score
	JMP .empty
.12
	;CAT_BG_TILE  
	SBC #4
	BPL .12b
	LDA #10
	JSR mod_score
	JMP .filled
.12b
	;GOLD_LG_TILE
	SBC #4
	BPL .13
	; do goldlarge
	LDA #8
	JSR mod_score
	JMP .empty
.13
	;CAT_NBG_TILE  
	SBC #4
	BPL .13b
	LDA #10
	JSR mod_score
	JMP .empty
.13b
	;MONSTER_SM_TILE
	SBC #4
	BPL .14
	; do monstersmall
	LDA #(-4)
	JSR mod_score
	; turn on SFX
	LDA VIC_NOISE_CH
	ORA $8F
	STA VIC_NOISE_CH
	JMP .filled
.14
	;PLAYER_BG_TILE  
	SBC #4
	BPL .15
	LDA #1
	JSR mod_score
	INC stop_reverse_flag
	JMP .empty
.15
	;MONSTER_LG_TILE
	SBC #4
	BPL .16
	; turn on SFX
	LDA VIC_NOISE_CH
	ORA $8F
	STA VIC_NOISE_CH
	; do monsterlarge
	LDA #(-8)
	JSR mod_score
	JMP .filled
.16	
	;PLAYER_NBG_TILE  
	SBC #4
	BPL .17
	LDA #1
	JSR mod_score
	INC stop_reverse_flag
	;JMP filled
.17

.filled
	LDX #FILLED_TILE
	LDA #8 ;#PLAYER_NBG_TILE
	JMP .after
.empty
	LDX #EMPTY_TILE
	LDA #0  ;#PLAYER_BG_TILE
.after
	STA player1.bg
	STX player1.old_tile
		
	
	
	LDA level.play_direction
	BMI .forward2
	LDA  stop_reverse_flag
	; if we are going backwards, flip the meaning of the stop_reverse_flag, 
	; because we used the negative meaning in this function to min code len
	EOR  #1 
	STA stop_reverse_flag


	; because we use non-animate flagged gaps in the encoding, we cannot use 
	; the optimiz3ed code to advance animation as was done for the other tiles
	; in gfx.s
	; This tradefoff is worth it because this animation is called once per tick,
	; while the other is called once per character screen cell.
	
.forward2
	LDA player1.frame ;3,4
	JSR advance_player_frame
	STA player1.frame ;3,4
	; this will adjust the player tile to be from the background set or non-background set
  ; depending on the type of tile the player is occupying
	EOR player1.bg

	; Y contains player1.y
	PHA
	TYA
	ASL
	TAX
	PLA
	STA (DOUBLE_CHAR_PLAYER_VECTOR,X)
	
	
	; we now fill up the paintmeter  1 row (2 meters) per iteration
	LDX #DOUBLE_COL_COUNT
	LDA #0
.paintmeter_loop
	TAY
	PHA
	LDA player1.paint,Y
	TAY
	LDA #FILLED_TILE
	JSR display_paint
	PLA
	PHA
	TAY
	LDA #MAX_PAINT
	SEC
	SBC player1.paint+1,Y
	TAY
	LDA #EMPTY_TILE
	JSR display_paint
	TXA 
	ADC #153
	TAX
	PLA 
	CLC 
	ADC #3 
	CMP #6 
	BNE .paintmeter_loop
	
	RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


; flag used to indicate that reverse direction should be flipped for the next 
; game clock tick
stop_reverse_flag
 DC 00


 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; ADVANCE_PLAYER_FRAME
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Advance the animation frame for the player.
; INPUT: A
; OUTPUT: A
; TRASHED: A
; EXAMPLE:  -
; NOTES: This will treat the LSB 2 bits as a finite field (wrapping)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
advance_player_frame SUBROUTINE
	AND #(~4)
	CLC 
	ADC #1
	ORA #4
	RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MOD_SCORE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Increment or decrement the player score 
; INPUT: A will contain the amount to increase or decrease [-10,0] or [0,10]
; OUTPUT: -
; TRASHED: A,X
; EXAMPLE:  LDA #4; JSR mod_score;
; NOTES: We update the double buffer directly.
;
;				 The caller expects that Y CANNOT BE MODIFIED
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mod_score SUBROUTINE
	; save the highest digit to use as a fast check for underflow
	LDX #SCORE_LEN
.loop
	CMP #0
	BEQ .loop_skip
	CLC
	ADC DOUBLE_CHAR_SCORE_VECTOR-1,X 
	CMP #CH_0_TILE
	BMI .minus
	CMP #CH_9_TILE+1 ;$36
	BMI .nowrap;< 10
	SEC
	SBC #SCORE_RADIX 
	STA DOUBLE_CHAR_SCORE_VECTOR-1,X 
	LDA #1
	JMP .loop_guard
.minus
	CLC
	ADC #SCORE_RADIX
	STA DOUBLE_CHAR_SCORE_VECTOR-1,X 
	LDA #(-1)
.loop_guard
	DEX
	BNE .loop
	JMP .loop_skip
.nowrap
	STA DOUBLE_CHAR_SCORE_VECTOR-1,X 
.loop_skip
	LDA DOUBLE_CHAR_SCORE_VECTOR
	SEC
	SBC DOUBLE_CHAR_SCORE_VECTOR-1
	CMP #2 ;this will only detect underflow (not overflow)
	BMI .no_underflow
	JSR reset_score
.no_underflow
	LDA DOUBLE_CHAR_SCORE_VECTOR
	STA DOUBLE_CHAR_SCORE_VECTOR-1
	RTS
.flag_zero
 DC 00

 
 
 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;RESET_SCORE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Reset a the score board to 0's
; INPUT: -
; OUTPUT: -
; TRASHED: A,X
; EXAMPLE:  JSR reset_score;
; NOTES: -
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
reset_score SUBROUTINE
	LDX #SCORE_LEN+1
	LDA #CH_0_TILE
.loop
	STA DOUBLE_CHAR_SCORE_VECTOR-2,X 
	DEX
	BNE .loop
	
	RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RESET_PAINT
; Reset all of the paint meters
;
; INPUT: -
; OUTPUT: Same return as mod_paint
; TRASHED: A,Y,X
; EXAMPLE:  JSR reset_paint;
; NOTES: Preserves A!
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

reset_paint SUBROUTINE
 	LDY #SPECIAL_PAINT_ROW
 	LDA #(-10)
 	JSR mod_paint
 	RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; MOD_PAINT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Increment or decrement a players paint can. If the player paint to modify is 
;	the SPECIAL_PAINT_ROW, all paint cans are decremented when the 
; SPECIAL_PAINT_ROW is decremented. (Does not apply to incrementing.)
;
; INPUT: A will contain the amount to step [-10,10]
;        Y will contain paint to modify (row 0,1,2,3,4)
; OUTPUT: A will contain 1 if overflow, -1 ($FF) on underflow, or 0 otherwise.
;					On multiple mods( I.e. middle row), underflow will dominate and A will
;					contain *only* the sum of underflows.
; TRASHED: X
; EXAMPLE:  LDY#2; LDA #4; JSR mod_paint;
; NOTES: The SPECIAL_PAINT_ROW should decrement every other one.
;				 This assumes the caller loads A *immediately* before this routine is 
;				 called.
;
;				 The caller expects that Y CANNOT BE MODIFIED
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
mod_paint SUBROUTINE
	BPL .1 ;assuming A is loaded immediately before this routine is called
	CPY #SPECIAL_PAINT_ROW
	BNE .1
	LDY #(MAX_NUM_REAL_PAINT-1)
	LDX #(MAX_NUM_REAL_PAINT-1)
	BNE .2 ;JMP .2
.1
	LDX #(-1)
.2
	PHA
	CLC
	ADC player1.paint,Y
	BMI .underflow
	CMP #MAX_PAINT+1
	BPL .overflow
	STA player1.paint,Y
	LDA #0
	BEQ .done ;JMP .done
.overflow
	LDA #MAX_PAINT
	STA player1.paint,Y
	LDA #1 
	BNE .done ;JMP .done
.underflow
	LDA #MIN_PAINT
	STA player1.paint,Y
	LDA #(-1) 
.done
	PLA
	DEY
	DEX
	BPL .2
	INY
	CPX #(-2) 
	BEQ .real_y
	LDY #SPECIAL_PAINT_ROW
.real_y
	RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; IS_PAINT_FULL
; Check if all the paint meters are full (except for the exempt row)
;
; INPUT: -
; OUTPUT: X is set if all of the non-excluded paint meters are full,
;					clear otherwise
; TRASHED: A,X,Y
; EXAMPLE:  JSR is_paint_full;
; NOTES: Preserves A!
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
is_paint_full SUBROUTINE
  ;PHA
  LDX #MAX_NUM_REAL_PAINT ; 5 
  LDY #(MAX_NUM_PAINT/2)  ; 4/2 = 2
  STY .counter
  
.loop
	LDA player1.paint-1,X
	CMP #MAX_PAINT
	BNE .not_full
	DEX
	DEY
	BNE .loop
	LDY #(MAX_NUM_PAINT/2)  ; 4/2 = 2
	DEX
	BPL .loop
.full 
	LDX #1
	RTS 
.not_full
	;PLA
	LDX #0
	RTS
.counter 
 DC 00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DISPLAY_PAINT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Update the visual paint meter, using the X to pick which color meter to 
;	operate on.
; INPUT: X offset
;				 A starting tile
;				 Y paint qty
; OUTPUT: A' = (A xor 1)
;					X' = X + MAX_PAINT
; TRASHED: A,Y,X
; EXAMPLE:  
; NOTES: To make paint updating easier we keep track of all colors (5), but here
;				 we want to use all but the middle entry, so it screws up iterating over
;				 it without some nasty conditional in the middle.
;
;					
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
display_paint SUBROUTINE
	
	;LDX #0
	;LDY player1.paint ; this number must be < 128!!!
	;LDA #FILLED_TILE
	STY .player1.current_paint
	
	; fill in the first half
.0
	DEY
	BMI .1
	STA double_char,X
	INX
	JMP .0
.1
	PHA
	; fill in the second half
	LDA #MAX_PAINT
	SEC
	SBC .player1.current_paint
	TAY
	PLA
	EOR #1 ; assuming the two tile status sprites are adjacent in the character map
.2
	DEY
	BMI .3
	STA double_char,X
	INX
	JMP .2

.3
	RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.player1.current_paint
 DC 00
	

	


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;DATA
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
player1.bg
 DC 00
player1.y
 DC PLAYER1_Y_START
player1.old_tile
 DC PLAYER1_START_TILE
player1.dir
 DC PLAYER1_DIR_START
player1.near_end
 DC 00
player1.near_end_old
 DC 00
 
player1.frame 
 DC PLAYER_BG_TILE

; 1 byte for each playboard row color
player1.paint ; this number must be < 128!!!
 REPEAT PLAYBOARD_ROW_COUNT 
 DC $00
 REPEND
