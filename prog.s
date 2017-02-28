; The Divine Scientist
; Mike Clark - 2016
  INCLUDE "boot.s"
	INCLUDE "common.s"
	
	JSR init_once
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Display title

	; display the title screen
	LDX #(start_screen_message_end-start_screen_message-1)
	LDY #7
.title_screen_loop
	LDA start_screen_message,X
 	STA VIC_CHAR_LO+SCREEN_COL_COUNT*5+1,X 
 	TYA
 	STA VIC_COLOR_LO+SCREEN_COL_COUNT*5+1,X 
	DEY
	BNE .noblack
	LDY #7
.noblack
	DEX
	BPL .title_screen_loop
	JSR select_level_skip ;carry clear
	BCC .level_selected
	
.level_loop
	JSR select_level
.level_selected
	JSR init_level

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Load the level onto screen

  LDA #(DOUBLE_COL_COUNT-PLAYER_COL- START_END_LANDING_LEN)
  STA .counter
.pre_loop
  JSR lores_shiftdouble 
  LDX #((PLAYBOARD_COL_COUNT*3)-1) 
  JSR load_double
	JSR lores_copydouble
	JSR governor	
  DEC .counter ;we need to use an memory counter bc load_double trashes all regs
	BNE .pre_loop
	LDA #PLAYER_NBG_TILE  
	; STA (VIC_CHAR_LO+PLAYER_COL+DOUBLE_COL_COUNT*(PLAYER1_Y_START+UPPER_PLAYBOARD_ROW))
	STA VIC_CHAR_LO+11-1+22*5 
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
  JSR wait_on_key
.game_loop  
  JSR raster_busywait
  JSR lores_copydouble
  
  
  JSR governor
  JSR button_capture

  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ; parts of this could be factored out if we could 
  ; generalize the lores_shiftdouble* routines into a single one.
  
	LDA level.play_direction
	BPL .reverse; #PLAY_DIR_FORWARD 
.forward
  JSR lores_shiftdouble
  ;;;;SAME START
  LDX level.load.vector
  JSR load_double
  ;;;;SAME END
  JSR update_player
  JSR push_player_tracer 
	JMP .miss_reverse
.reverse
  JSR lores_shiftdouble_R
	JSR pull_player_tracer 
  ;;;;SAME START
	LDX level.load.vector
  JSR load_double
  ;;;;SAME END
  ; the prng is always played forward when loading double, so when operating in
  ; backwards direction of play, we rewind 2 columns, then load 1 column (forward),
  ; then continue in that fashion, so we don't have to write two double buffer 
  ; loaders for each direction.
  LDA player1.near_end ; skip rewind if the prng is at the start state
  BNE .skip_rewind
  ; Wind the PRNG back to the state that existed when drawing in the leftmost column
	LDX #PLAYFIELD_ROW_COUNT*2
.rewind_loop 
	JSR rnd_R
	DEX
	BNE .rewind_loop
.skip_rewind

  JSR update_player
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.miss_reverse
	;SEC ;update_player sets the carry)
	DEC level.cursor_lo
  BNE .game_loop
  
  ; if we are in reverse mode or coming out of it, then reset the
  ; counters
  LDA level.play_direction
	BMI .gameover
	DEC level.cursor_lo
	INC stop_reverse_flag
	LDA #10 ; give a bonus for reaching the start going backwards
	JSR mod_score 
	DEC level.bonus_countdown ; track how many times went backwards completely
	LDA #0
	STA player1.near_end
	JMP .game_loop
  
.gameover
	JSR lores_copydouble
	JSR validate_hi_score
	JSR wait_on_key
	LDA #1
	STA player1.near_end
	; near_end gets reset on level init so we don't have to change it back here
	; load the next beginning and player sprite
	LDX level.load.vector
	JSR load_double		

	JMP .level_loop
	
.counter
 DC DOUBLE_COL_COUNT-PLAYER_COL- START_END_LANDING_LEN

  INCLUDE "rnd.s"
	INCLUDE "func.s"
	INCLUDE "level.s"
  
  INCLUDE "player.s"

level_select_message
	; "space to retry" ;39
  DC.b 19,16,1,3,5,32,11,5,25,32,20,15,32,18,5,20,18,25,32,32,32,32,32,32
  ; "else new"
  DC.b 5,12,19,5,32,14,5,23
level_select_message_end
start_screen_message
	;"the divine scientist"
	DC.b 20,8,5,32,4,9,22,9,14,5,32,19,3,9,5,14,20,9,19,20
start_screen_message_end

before_charset:
	NOP
  org $1800 
charset:
 INCLUDE "block.dat" 
 INCLUDE "gfx.s"  
 INCLUDE "tail.s"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:;;;;;
; Do not work below this.
; this
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;:;;;;;
EOF
 ECHO "Space lost due to tracer_bank alignment: ", tracer_bank - before_tracer_bank - 1
 IF EOF > $1E00
	ECHO "Program is too large!"
	ECHO EOF - $1E00, " overlimit bytes [mid]" ; if <0,compiler complained already 
	ERR
 ELSE
  ECHO charset - before_charset, " free bytes [mid]" ; if <0,compiler complained already 
	ECHO VIC_CHAR_LO - EOF, " free bytes [tail]"
 ENDIF

 
