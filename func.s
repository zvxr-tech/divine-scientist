;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INIT_ONCE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Tasks to do once on program start.
; INPUT: -
; OUTPUT: -
; TRASHED: A
; EXAMPLE: JSR init_once;
; NOTES: -
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
init_once SUBROUTINE
  CLD ;turn off BCD-mode

	LDA #8 ; set screen  to black, border to black, reversemode=off
  STA VIC_COLOR
  
	LDA #$93 ; clearscreen controlcode 
  JSR CHROUT ;CHROUT ;clear screen
    
  ; setup ZP mem
  JSR vector_genesis
  
	RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; WAIT_ON_KEY
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Wait for any keypress
; INPUT: -
; OUTPUT: A: keycode
; TRASHED: 
; EXAMPLE: JSR wait_on_key;
; NOTES: -
; return A=key, X,Y trashed
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
wait_on_key SUBROUTINE
.getkey	
	JSR GETIN
	BEQ .getkey ;presumes Z reflects LDA in GETIN
	RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Tasks to do once on level start.
; INPUT: -
; OUTPUT: -
; TRASHED: A,X,Y
; EXAMPLE: JSR init_level;
; NOTES: -
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
init_level SUBROUTINE
	LDA #$93 ; clearscreen controlcode
  JSR CHROUT ;CHROUT ;clear screen
	
  ; set 8x16 mode and screen dimensions 11 rows by 22 columns
	LDA #$17
	STA $9003
	
  ; set custom charset @ $1800 
	LDA $9005
	;EOR #$0E
	AND #$F0
  CLC 
	ADC #$0E
  STA $9005
 
	; reset global state
	
 	LDA #TRACER_PER_BYTE 
 IF (TRACER_PER_BYTE != MAX_FREQ_COUNT)
 ECHO "TRACER_PER_BYTE != MAX_FREQ_COUNT"
 ERR
 ENDIF
 	STA tracer_bank.current_byte_cursor
	STA level.bonus_countdown
	
	; because a level can only end with a forward direction of play, we can assume
	;		instruction .wind_loop2 is correct
	;   
 	
 	;JSR reset_paint
 	LDA #0
	STA level.freq_degree
	STA player1.bg
	STA player1.near_end
	STA player1.near_end_old
	STA level.spawn_bonus_cat
	; reset the tracer metadata
	;LDA #0
	STA init_push.mod_instr+1
	STA pull.mod_instr+1
	STA push.mod_instr1+1
	STA push.mod_instr2+1
	
	
	LDA #PLAYER1_Y_START
	STA player1.y ;2
	
	LDA #PLAYER1_START_TILE
	STA player1.old_tile
	
	LDA #PLAYER_BG_TILE
	STA player1.frame
 	
 	LDA #DEFAULT_FREQ
	STA level.freq 	
  
	JSR reset_score  
	
  RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; VALIDATE_HI_SCORE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; check if we have a hi score and transfer it to the hi score part of the screen
; INPUT: -
; OUTPUT: -
; TRASHED: X,A,
; EXAMPLE: JSR validate_hi_score;
; NOTES:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
validate_hi_score SUBROUTINE
	LDX #0
.loop
	LDA DOUBLE_CHAR_SCORE_VECTOR,X
	CMP DOUBLE_CHAR_HISCORE_VECTOR,X 
	BEQ .tie_score
	BPL .hi_score
	RTS
.tie_score
	INX
	CPX #SCORE_LEN 
	BNE .loop

.hi_score_loop
	LDA DOUBLE_CHAR_SCORE_VECTOR,X
.hi_score
	STA DOUBLE_CHAR_HISCORE_VECTOR,X 
	INX
	CPX #SCORE_LEN 
	BNE .hi_score_loop
	RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; BUTTON_CAPTURE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Capture user input
; INPUT: -
; OUTPUT: -
; TRASHED: A,X
; EXAMPLE: JSR button_capture;
; NOTES: -
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
button_capture SUBROUTINE
	LDA #0
	STA player1.dir 
	
	; test if we are coming out of reverse-mode
	LDX stop_reverse_flag
	BEQ .getkey
	LDX #0
	STX stop_reverse_flag
	JSR reverse_play_direction
	JSR init_push_player_tracer
	
.getkey	
	; get user input (up/down/reverse)
	JSR GETIN
	
	CMP #CH_SPACE
	BNE .nextkey1
	
	;test to see if we have enough paint
	JSR is_paint_full 
	; the last instruction before the RTS was loading the success into X
	; we can just do a branch on the flags that load set
	BEQ .keyskip
		
	;test to see if we have maxed out the number of times we can reverse, if so 
	; give a bonus cat instead.
	JSR reset_paint 
	
	LDA level.freq_degree
	CMP #MAX_FREQ_COUNT
	BNE .do_reverse_direction
	; check if we have gone backwards to the start every time
	LDA level.bonus_countdown
	BNE .keyskip
	INC level.spawn_bonus_cat
	BNE .keyskip ;JMP
.do_reverse_direction
	JSR reverse_play_direction
	JMP .keyskip

.nextkey1		
  CMP #CH_DOWN
	BNE .nextkey2
.keydown
	LDA #DIRECTION_DOWN
	STA player1.dir 
	;;INC game_freq
	BNE .keyskip;JMP
.nextkey2
	CMP #CH_UP
	BNE .keyskip
	LDA #DIRECTION_UP
	STA player1.dir 
	;;DEC game_freq
.keyskip
	; update the global state we use to check if the start/end tiles are onscreen
	JSR is_end_near
	RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; REVERSE_PLAY_DIRECTION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Reverse the direction of play
; INPUT: A current degree of level frequency (level.freq_degree)
; OUTPUT: -
; TRASHED: A,Y,X
; EXAMPLE: JSR reverse_play_direction;
; NOTES: Caller is responsible for ensuring a reversal is permitted.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
reverse_play_direction SUBROUTINE
	TAY

	; this assumes starting in the forward direction for each level
	
	LDA level.play_direction
	EOR #(PLAY_DIR_FORWARD^PLAY_DIR_REVERSE); $1 ^ $FF (-1) = $FE 
	STA level.play_direction
	
	; make use of the way the flags are set on EOR
	BPL .reverse_freq ;positive=reverse_mode, negative=forward_mode
	LDA #DEFAULT_FREQ
	STA level.freq
	BNE .done_freq
.reverse_freq
	; we take advantage of the fact that when reverse_play_direction is called in 
	; backwards direction, A will contain the will contain the degree of frequency
	; modulation to apply.
	INY 
	STY level.freq_degree
	LDA level.freq
	SEC
.freq_loop
	SBC #FREQUENCY_MODULATION
	DEY
	BNE .freq_loop
	STA level.freq
.done_freq
	
	
	
	
	; we wan to toggle between these two values for when reverse mode is off/on
	;	#((PLAYBOARD_COL_COUNT*3)-1)
	;	#((PLAYBOARD_COL_COUNT*2))
	; , so we use the XOR to toggle.
	LDA level.load.vector
	EOR #LEVEL_LOAD_VECTOR_XOR
	STA level.load.vector
	
	; change the prng direction by modifying the JSR call
	LDA .wind_loop2+1
	EOR #RND_TOGGLE
	STA .wind_loop2+1
	
	
; Wind the prng to the proper position based on the reversal of play
; If the start/end column is onscreen, we do not wind back as far because 
; we only want to wind the prng as far as the initial/final state ,depending
; on the direction of travel.
	LDA player1.near_end
	BNE .partial_wind ;non-zero means we are near the end
	LDA level.cursor_lo
	SEC 
	SBC level.cursor.show.final
	BCC .partial_wind2 ; cursor < show
	BEQ .partial_wind2 ; cursor == show
	;else, >0
	; in this case the reversal still puts us with the start/end
	; offscreen
	LDX #(PLAYFIELD_COL_COUNT+1)
	JMP .wind_loop
.partial_wind
	LDA level.cursor_lo
	;SEC ; set because we didn't branch to .partial_wind2
	SBC level.cursor.show.final
.partial_wind2
; A := cursor - show
	CLC 
	ADC #PLAYFIELD_COL_COUNT+1
	TAX
.wind_loop
	LDY #PLAYFIELD_ROW_COUNT
.wind_loop2
	JSR rnd ;NOTE: This must be at the same offset as .wind_loop2
	DEY
	BNE .wind_loop2
	DEX
	BNE .wind_loop
	
	
	
	; These are separate values because the number of columns between the player 
	; column and the edge are different depending on the direction of play.
	LDA level.cursor.show.final
	EOR #LEVEL_CURSOR_SHOW_FINAL_XOR
	STA level.cursor.show.final
	
	
	
	; re-index the cursor that keeps track of how far away the player is from the 
	; start/end
	LDA level.cursor_lo
	EOR #$FF 
	STA level.cursor_lo

	; start the trace engine puller
	LDA level.play_direction
	BMI .forward
	JSR init_pull_player_tracer
.forward
	
	
	RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; IS_END_NEAR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Detect if the player is within range* of the start/end column.
; *is the next column to be loaded in, an start/end column?
; INPUT: -
; OUTPUT: A - MSb set = past end
;						  LSb set = at end
;							Zero, otherwise
; TRASHED: A
; EXAMPLE: -
; NOTES: Returns value in A register and updates player data struct with this 
;				 value.
;				 Each level will have two distinct start/end columns.
;				 When we reverese, the counter that tracks how far into the level the 
;				 player is will be re-indexed so that the zero'th counter value 
;				 indicates the player is on the start tile.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
is_end_near SUBROUTINE
	LDA player1.near_end
	STA player1.near_end_old
	
	LDA level.cursor_lo
	SEC 
	SBC level.cursor.show.final
	BEQ .at_end
	BCC .past_end
.hiset
	LDA #NOT_END
	STA player1.near_end
	RTS
.at_end
	LDA #AT_END 
	STA player1.near_end
	RTS
.past_end
	LDA #PAST_END
	STA player1.near_end
	RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;




  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; GOVERNOR
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Retard execution for N jiffies.
; INPUT: -
; OUTPUT: -
; TRASHED: A,X,Y
; EXAMPLE: JSR governor;
; NOTES: The governor defaults to $10 jiffies on start and reset. 
;				 The value wait-time value persists across calls to this routine.
;				 We use the XOR to toggle beween values -- it is presumed that the level
;		  	 begins in the forward direction state.
;				 We also toggle/modify the target JSR in the prng winding code section.
;				 it is important that this is reset between levels.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
governor SUBROUTINE  
  LDX level.freq  
.retard_loop
  LDA $A2 ;read jiffy clock
  CMP .retard_store ; has it changed?
  BEQ .retard_loop
  STA .retard_store ;store the new value
	DEX
	BNE .retard_loop
	RTS
.retard_store
 HEX 00
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
  


	
 ; Placed here to be close to a 100 byte boundry. move as necessary to maintain
; min wasted space
;' this is 40 bytes, but we can eat into the next function, which is only called once
; before the tracer bank is populated
before_tracer_bank:
 DC $FF
tracer_bank ALIGN $100
 REPEAT $40
  DC 00
 REPEND
sentry:
 DC $FF
tracer_bank.current_byte_cursor 
	DC #TRACER_PER_BYTE


	


	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; VECTOR_GENESIS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Dynamically populate the zero-page vectors used in the program
; INPUT: -
; OUTPUT: -
; TRASHED: X
; EXAMPLE: -
; NOTES: Use after control is given from basic.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
vector_genesis SUBROUTINE
K		SET 		0
		REPEAT  5
		LDX #<(double_char+PLAYER_COL+(UPPER_PLAYBOARD_ROW+K)*PLAYBOARD_COL_COUNT)
		STX DOUBLE_CHAR_PLAYER_VECTOR+K*2
		LDX #>(double_char+PLAYER_COL+(UPPER_PLAYBOARD_ROW+K)*PLAYBOARD_COL_COUNT)
		STX DOUBLE_CHAR_PLAYER_VECTOR+1+K*2
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		LDX #<(double_char+PLAYER_COL+(UPPER_PLAYBOARD_ROW+K)*PLAYBOARD_COL_COUNT-1)
		STX DOUBLE_CHAR_PLAYER_VECTOR_M1+K*2
		LDX #>(double_char+PLAYER_COL+(UPPER_PLAYBOARD_ROW+K)*PLAYBOARD_COL_COUNT-1)
		STX DOUBLE_CHAR_PLAYER_VECTOR_M1+1+K*2
		;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		LDX #<(double_char+PLAYER_COL+(UPPER_PLAYBOARD_ROW+K)*PLAYBOARD_COL_COUNT+1)
		STX DOUBLE_CHAR_PLAYER_VECTOR_P1+K*2
		LDX #>(double_char+PLAYER_COL+(UPPER_PLAYBOARD_ROW+K)*PLAYBOARD_COL_COUNT+1)
		STX DOUBLE_CHAR_PLAYER_VECTOR_P1+1+K*2
K   SET     K + 1
		REPEND
		RTS
		
		
	
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;INIT_PULL_PLAYER_TRACER 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Routine to prepare the tracer bank for pulling tracer states.
; INPUT: -
; OUTPUT: A - position relative to start of double_buffer
; TRASHED: A,X
; EXAMPLE: JSR init_pull_player_tracer;
; NOTES: This begins by winding back and display onscreen tracers at the moment
; of redirection. It will prepare the state for later calls to the pull routine
; so that it is pulling from the correct location.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
init_pull_player_tracer SUBROUTINE
  ; invert the byte's bit cursor
  LDA #TRACER_PER_BYTE; 4
  SEC 
  SBC tracer_bank.current_byte_cursor
  STA tracer_bank.load_byte_cursor
  
  
  ;load in the current tracer byte address, and then the byte value
  LDX push.mod_instr2+1
  STX pull.mod_instr+1
	STX init_push.mod_instr+1
init_push.mod_instr
  LDA tracer_bank
  STA tracer_bank.load_byte
	
  ; get the players position relative to the start of the double buffer
  LDX player1.y
  ; offset minus DOUBLE_COL_COUNT to make up for the extra iteration below
  LDA #(PLAYER_COL+PLAYBOARD_START-DOUBLE_COL_COUNT)
  CLC ;needed b/c the SBC above will keep carry set
.position_loop
  ADC #DOUBLE_COL_COUNT 
  DEX
  BPL .position_loop
  STA tracer_bank.load_absolute
	
	; we need to populate all of the tiles to the left of the player
	; with tracers up until and including the start/tiles if they are 
	; coming onscreen
	; determine how many tracers should appear onscreen immediately, before 
	; dropping into the draw loop
  
  ; save a local version of the animation frame for drawing the first set of
  ; onscreen tracers. We draw at most double col count (22, but in our case 10),
  ; so we can just increment and examine the lower 2 bits [0,3]

  LDA player1.frame
  JSR advance_player_frame
  STA .local_frame
  
  LDA #PLAYER_COL 
  TAY
  SEC ;needed
  SBC level.cursor_lo
  BCC .draw_loop
  LDY level.cursor_lo
  
.draw_loop
  JSR pull_player_tracer ; leaves Y untouched
  
  ; A,X contains the relative offset into double buffer
  DEC tracer_bank.load_absolute ; we need to shift to the left as we draw
  LDA double_char-1,X ; load the existing tile (X does not contain the shift 1 left)
  AND #1
  BEQ .filled
	;#PLAYER_NBG_TILE 
	LDA #~8
	AND .local_frame
	JMP .after
.filled
	;#PLAYER_BG_TILE 
	LDA #8
	ORA .local_frame
.after
	
	
	STA double_char-1,X ;overwrite with a tracer
	JSR advance_player_frame
	STA .local_frame
	DEY
	BNE .draw_loop
	STA load_tracer.local_frame ;save the frame as the next one to load onscreen
	RTS
.local_frame
	DC 00
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; PULL_PLAYER_TRACER
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Pull a 2-bit encoding of the player movement as left the level coloumn 
; currently being loaded when the direction of play is in reverese. 
; This will auto-increment the current byte being operated.
; on.
; INPUT:   
; OUTPUT: A=X : position relative to start of double_buffer
; TRASHED: A,X
; EXAMPLE: JSR
; NOTES: 2Bit Encoding= 00-no move, 10=up, 01=down, 11=reserved. 
;				(for reference, bits shown here are big-endian)
;	We operate on a copy because the direction of play could toggle 
; whilst we are set to read from the middle of a byte meaning the byte could 
; possibly be rotated. If the player went in reverse again this tracer state 
; would not be correct.
; For this reason, the copy is *never* written back to the level tracer bank, 
; preserving the integrity of the level tracer bank.
;
; An index (cursor) maintains the number of slots left in the current byte.
; When the current byte is completely read from, we wait until the next read
; before modifying the instruction that then loads the next byte.

; This should be wound to the loading column's tracer state in the level 
; tracer bank before each time backwards diretion of play is entered into. 
; (I.e. iteratively run it and write out the tracer chars to the double buffer 
; to fill in the initial space between the lefthand edge and the player.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
pull_player_tracer SUBROUTINE
	LDA tracer_bank.load_byte
	LDX tracer_bank.load_byte_cursor
	DEX
	BPL .not_empty
	DEC pull.mod_instr+1
pull.mod_instr
	LDA tracer_bank
	STA tracer_bank.load_byte
	; we set this at 1 less than the max count to account for the DEX, that would
	; otherwise be occuring
	LDX #TRACER_PER_BYTE-1 
.not_empty
	; A <= tracer_bank_load_byte
	STX tracer_bank.load_byte_cursor 
	;decode
	;ROR
	LSR
	BCS .downmove
	;ROR
	LSR
	BCS .upmove
	JSR .storeandload
	JMP .done
.upmove ;if up, move down
	JSR .storeandload
	CLC ;needed
	ADC #DOUBLE_COL_COUNT
	JMP .done
.downmove ;if down, move up
	LSR ; pull off the high bit of the encoding (irrelevant)
	JSR .storeandload
	SEC
	SBC #DOUBLE_COL_COUNT ; carry is set
.done
	;;;;;SEC
	;;;;;SBC #1
	STA tracer_bank.load_absolute
	TAX 
	RTS
.storeandload
	STA tracer_bank.load_byte
	LDA tracer_bank.load_absolute
	RTS
	
; A copy of the current byte where we are pulling tracer states from.	
tracer_bank.load_byte
 DC 00

; this is an index of the next 2bit encoding in the byte (4positions)
tracer_bank.load_byte_cursor
 DC 00

; this is an absolute offset of the most current tracer on the screen relative
; to the start of the double buffer.
; this is used during a comparison in the load_double routine, where it is 
; convinient to use this value.
tracer_bank.load_absolute
 DC 00
 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;INIT_PLAYER_PUSH
; reset the push cursor (instruction) and byte cursor based on the player cursor
; 0,0 => 3
; 0,1 => 2
; 1,0 => 1
; 1,1 => 0
init_push_player_tracer SUBROUTINE
	LDX #4
	LDA level.cursor_lo
	BEQ .done
	SEC
	SBC #1
	LDX #3
	LSR 
	BCC .2or3
.0or1
	DEX
	DEX
.2or3
	LSR
	BCC .3or1
	DEX
.3or1
	; X now contains the current_byte cursor and A contains the byte relative to
	; the start of the tracer bank. Since the tracer bank is aligned on $100, we 
	; can just store A in tracer_bank's LSB
	

.done
	; this assumes the tracer bank is $100 byte aligned
	STX tracer_bank.current_byte_cursor
	STA push.mod_instr1+1
	STA push.mod_instr2+1

	RTS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; PUSH_PLAYER_TRACER
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Push a 2-bit encoding of the player movement as it leaves the current level 
; cursor_lo position. This will auto-increment the current byte being operated 
; on.
; INPUT: -
; OUTPUT: -
; TRASHED: A,X
; EXAMPLE: JSR set_tracer;
; NOTES: 2Bit Encoding= 00-no move, 10=up, 01=down, 11=reserved. 
;				(for reference, bits shown here are big-endian)
; We can operate directly on the tracer bank because it is the leading edge. 
;	For getting, we operate on a copy because the direction of play could toggle 
; whilst we are set to read from the middle of a byte meaning the byte could 
; possibly be rotated.
;
; An index (cursor) maintains the number of slots left in the current byte.
; When the current byte is completely written into, we wait until the next write
; before commiting it to the actual tracer bank storage.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
push_player_tracer SUBROUTINE
	LDX tracer_bank.current_byte_cursor
	DEX
	BPL push.mod_instr1
	INC push.mod_instr1+1 ;next time we write a byte, use the next byte location
	INC push.mod_instr2+1 ;next time we write a byte, use the next byte location
	; we don't care that the ACCUM is dirty, because the code
	; below assumes as much
	
	; we set this at 1 less than the max count to account for the DEX, that would
	; otherwise be occuring
	LDX #TRACER_PER_BYTE-1
push.mod_instr1
	LDA tracer_bank
	STX tracer_bank.current_byte_cursor
	LDX player1.dir
	BEQ .nomove
	BPL .downmove
.upmove ;if up, encode=>10 
	SEC
	ROL
	ASL
	JMP push.mod_instr2
.downmove ;if down, encode=>01
	ASL
	SEC
	ROL
	JMP push.mod_instr2
.nomove	;if nomove, encode=>00
	ASL
	ASL
push.mod_instr2
	STA tracer_bank	
	RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RASTER_BUSYWAIT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Wait until the raster is at the first line.
; INPUT: -
; OUTPUT: -
; TRASHED: A
; EXAMPLE: JSR raster_busywait;
; NOTES: -
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
raster_busywait SUBROUTINE
.loop
	LDA VIC_RASTER ; loop until we are at rasterline zero 
  BNE .loop
  LDA VIC_RASTER_AUX
  AND #$80
  BNE .loop
  RTS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



