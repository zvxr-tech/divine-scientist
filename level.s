
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GET_STAR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Return an empty or starA or starB tile charcode, depending on a prob. distr.
;
; INPUT: -
; OUTPUT: A
; TRASHED: A
; EXAMPLE:  JSR get_star;
;			
; NOTES: The carry-bit is guaranteed to be cleared on return to the caller.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
get_star SUBROUTINE
	LDA player1.near_end
	BEQ .start 
	CLC 
	LDA #EMPTY_TILE
	RTS
.start
	; else
  JSR rnd ; A <- rnd
  SEC
  SBC #10 ;  starA ; PROBABILITY
  BCC .starA
  SBC #5;  starB ; PROBABILITY
  BCC .starB
  LDA #EMPTY_TILE
  CLC
  RTS
.starA
	LDA #STAR_A_TILE
	RTS
.starB
	LDA #STAR_B_TILE
	RTS
.level_end
	CLC ; needed? yes. because we might get here via the BEQ, therefore C=set
	LDA #EMPTY_TILE
	RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GET_TILE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Return a tile for the playboard, depending on a probability distribution
;
; INPUT: X current absolute offset in bytes from the start of the char buffer
; OUTPUT: A the charcode of the tile, 
;					Y = 7 (yellow) for certain tiles (gold bonus), unchanged otherwise.
; TRASHED: A,Y (sometimes, see above)
; EXAMPLE:  JSR get_tile;
;			
; NOTES: The carry-bit is guaranteed to be cleared on return to the caller.
; RTS is shorter len than a branch, so we use that to terminate condional bodies
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
get_tile SUBROUTINE
	; Test whether we are drawing at the end or beyond it.
	LDA player1.near_end
	BMI .past_end ;past_end=$8
	BNE .level_end;level_end=$1
	

	; Determine if we should draw a tracer by first Test if we are in the 
	; reverse play direction and then test whether we are drawing a column in 
	; reverse mode that contains a tracer
	LDA level.play_direction
	BMI .no_tracer
	
	CPX tracer_bank.load_absolute
	BNE .no_tracer
	
	; A <- rnd dont have extra register, so have to duplicate instruction
	; cheaper in len to put a couple comparisons, rather than set a common
	; branch below. We only have to construct a small part of the conditional
	; tree below by design.
	JSR rnd 
	SEC 
	SBC #$68 ; ; PROBABILITY 68% filled
	BCC .filled_tracer
	;;LDA #PLAYER_NBG_TILE+?
	LDA #8
	ORA load_tracer.local_frame 
  JMP .done_tracer
.filled_tracer
	;LDA #PLAYER_BG_TILE+?
	LDA #~8
	AND load_tracer.local_frame 
.done_tracer
	JSR advance_player_frame
	STA load_tracer.local_frame 
	RTS
load_tracer.local_frame ;automatically reset by the init_pull tracer setup
 DC 00

	
	
	
.no_tracer 
;;;;.hiset	
  JSR rnd ; A <- rnd
  SEC
  SBC #60; filled
  BCC .filled
  SBC #6 ; gold small
  BCC .gold_small
  SBC #2; gold large
  BCC .gold_large
  ; tiles with filled background above, unfilled below
  SBC #6 ; monster small 
  BCC .monster_small
  SBC #2; monster large
  BCC .monster_large
  
  
	LDA #EMPTY_TILE
	CLC ;1,2
	RTS ;1,6
.monster_large
	LDA #MONSTER_LG_TILE
	RTS
.monster_small
	LDA #MONSTER_SM_TILE
	RTS
.gold_large
	LDA #GOLD_LG_TILE
	LDY #7
	RTS
.gold_small  
	LDA #GOLD_SM_TILE
	LDY #7
	RTS
.level_end    
	LDY #1
	;STY .one_more_time
	JMP .filled
.past_end
	;LDY .one_more_time ; reuse this to fill in the tile color as well (retY)
	;BEQ .filled
	;DEC .one_more_time
	LDY #0
.filled
	LDA #FILLED_TILE
	CLC
	RTS
;.one_more_time
;	DC 00
  
  
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; LOAD_DOUBLE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Load content onto the playfield
;
; INPUT: X the offset relative to the first column of the start of the 
; 		   double_buffer.
; OUTPUT: -
; TRASHED: A,X,Y
; EXAMPLE:  LDX #66; JSR load_double;
;			
; NOTES: Instead of adding increased complexity to this function to create a 
;	reversed version, the developer needs to rewind the prng each time after using
; this function in reverese-mode.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
load_double SUBROUTINE
	;playfield upper border
  LDA #$1
  STA double_color,X
  JSR get_star ; carry is clear on return
  STA double_char,X
	
	TXA
	;;CLC ; needed? nope
	ADC #DOUBLE_COL_COUNT 
	TAX
	
	
	; playboard
	LDA #PLAYBOARD_ROW_COUNT
	STA .counter
.loopy
	LDA #7
	SEC
	SBC .counter ; this should always be > 0, so the carry will remain set
	TAY
	JSR get_tile ; carry is guaranteed clear on return
	STA double_char,X
	TYA
	STA double_color,X
	TXA
	;;;CLC ;needed? -> Nope
	ADC #DOUBLE_COL_COUNT 
	TAX
  DEC .counter 
  BNE .loopy 
  
  ;playfield lower border
  LDA #1
  STA double_color,X
  JSR get_star 
	STA double_char,X

	; if spawning a bonus cat
	LDA level.spawn_bonus_cat
	BEQ .nobonus
	LDA rnd.a
	AND #3
	TAY
	INY
	TXA
	SEC
.spawn_loop
	SBC #DOUBLE_COL_COUNT
	DEY
	BNE .spawn_loop
	TAX
	LDA #CAT_BG_TILE
	STA double_char,X
	LDA #1
	STA double_color,X
	STY level.spawn_bonus_cat ; reset bonus cat
.nobonus
  RTS
.counter
 DC 00
  
	

 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; DATA
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


level.cursor_lo
	DC $FF	
  
level.load.vector
	DC LEVEL_LOAD_VECTOR 

level.play_direction
	DC #PLAY_DIR_FORWARD 

level.cursor.show.final
 DC LEVEL_CURSOR_SHOW_FINAL 
	
; used to save the current level seed, for retry
level.seedA
  DC $00
level.seedB
	DC $00
level.seedC
  DC $00

; keep track of successfull backtracks to start
level.bonus_countdown
 DC MAX_FREQ_COUNT

level.spawn_bonus_cat
 DC 00
; keep track of how many times we have gone in reverse by counting down
level.freq_degree
 DC 00
level.freq
 DC DEFAULT_FREQ
