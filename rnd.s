;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RND
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 3 Byte XOR shift PRNG.
;	Returns a pseudorandom, 8 bit number with the high bit cleared.
;
; INPUT: -
; OUTPUT: A, Carry flag is clear.
; TRASHED: -
; EXAMPLE:  LDA $11
;						LDX $22
;						LDY $33
;						JSR rnd_seed 
;						JSR rnd ; get a random number between [0,127]
;			
; NOTES: Can be re-seeded at anytime to add more entropy.
; Based on C code here: 
; http://www.electro-tech-onlinernd.com/threads/ultra-fast-pseudorandom-number-
; generator-for-8-bit.124249/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
rnd SUBROUTINE
    INC rnd.x       ;x'=x++
    LDA rnd.a
    EOR rnd.c       
    EOR rnd.x       ;a' = (a^c^x)
    STA rnd.a       ; save A
    CLC
    ADC rnd.b       ;b' = (b+a')
    STA rnd.b       ; save B
    
    LSR         		; b >> 1
    CLC
    ADC rnd.c       ; c+(b>>1)
    EOR rnd.a       ; ((c+(b>>1))^a)
    STA rnd.c       ; c' = ((c+(b'>>1))^a')
    ;keep the lowest-order 7 bits (make non-negative)
    ;ASL
    ;LSR
    AND #$7F
    RTS         		; A <- return(c')

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RND_R
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Inverse of the above, 3 Byte XOR shift PRNG. 
;	Returns a pseudorandom, 8 bit number with the high bit cleared.
;
; INPUT: -
; OUTPUT: A, Carry flag is clear.
; TRASHED: -
; EXAMPLE:  LDA $11
;						LDX $22
;						LDY $33
;						JSR rnd_seed 
;						JSR rnd_reverse ; get a random number between [0,127]
;			
; NOTES: Can be re-seeded at anytime to add more entropy.
; Based on C code here: 
; http://www.electro-tech-onlinernd.com/threads/ultra-fast-pseudorandom-number-
; generator-for-8-bit.124249/
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
rnd_R SUBROUTINE
		LDA rnd.b  			
    LSR							; (b'>>1)
    STA .temp 
    LDA rnd.c 
    EOR rnd.a				; (c')^a'
    SEC
    SBC .temp
    STA rnd.c				; save C
    PHA
    LDA rnd.b				
    SEC						
    SBC rnd.a				; b = b' - a'
		STA rnd.b				; save B
		LDA rnd.a				
		EOR rnd.c
		EOR rnd.x				; a' = a'^c^x'
		STA rnd.a				; save A
		DEC rnd.x				; x = x'--
    ;keep the lowest-order 7 bits (make non-negative)
    PLA
    ;ASL
    ;LSR
    AND #$7F
    RTS         		; A <- return(c)
.temp
 DC 00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; RND_SEED
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Seed the PRNG.
;
; INPUT: A,X,Y
; OUTPUT: -
; TRASHED: A
; EXAMPLE:  LDA $11
;						LDX $22
;						LDY $33
;						JSR rnd_seed 
;						JSR rnd_reverse ; get a random number between [0,127]
;			
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
rnd_seed 
;Can also be used to seed the rng with more entropy during use.
    ;EOR rnd.a
    STA rnd.a ; a ^= s1 (A)
    
    ;TXA
    ;EOR rnd.b
    STX rnd.b ; b ^= s2 (X)
    
    ;TYA
    ;EOR rnd.c
    STY rnd.c ; c ^= s3 (Y)

    LDA #0
    STA rnd.x
    
    RTS
    
    
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
; DATA
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
; internal state for the prng
rnd.a
 HEX 00
rnd.b
 HEX 00
rnd.c
 HEX 00
rnd.x
 HEX 00
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 
