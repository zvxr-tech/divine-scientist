; This file is strictly because we are running out of room and we can stick 
; some functions here, even though logically they might belong to other function
; groupings


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SELECT_LEVEL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Level select screen. This will seed the prng.
; INPUT: -
; OUTPUT: -
; TRASHED: A,X,Y
; EXAMPLE: JSR level_select;
; NOTES: This can be entered without displaying anything, just waiting on input.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
select_level SUBROUTINE
  LDA #$16
	STA $9003 ; set 11x22 screen and 8x8 charset
	
	LDA $9005
	AND #$F0
  STA $9005
  
	LDA #$93 ; clearscreen controlcode 
  JSR CHROUT ;CHROUT ;clear screen

  LDX #(level_select_message_end-level_select_message-1) ;#39
.loop	
	LDA level_select_message,X
 	STA $1ec8,X 
	DEX
	BPL .loop
	
; we can JSR to this point when starting from the title screen
select_level_skip:
	; block on user input, use for initial seed
	JSR wait_on_key
	CMP #CH_SPACE
	BNE .new_level
	LDA level.seedA
 	LDX level.seedB
 	LDY level.seedC
 	JMP .seed
.new_level
	LDX $A2 ; use the jiffy clock to introduce more entropy
	LDY $A1 ; use the jiffy clock to introduce more entropy
	ASL 
	STA level.seedA
 	STX level.seedB
 	STY level.seedC
.seed
 	JSR rnd_seed
 	CLC
	RTS


  
  
  

