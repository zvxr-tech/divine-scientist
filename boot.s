	processor 6502

	ORG $1001
	.BYTE $0b,$10,$0a,$00,$9e,$34,$31 ;magik NULL byte; 10 SYS 4128 ($1020)
	.BYTE $32,$38,$00,$17,$10,$14,$00,$99 ;20 PRINT "DONE" (Sanity)
	.BYTE $22,$44,$4f,$4e,$45,$22,$00,$1d ;30 END
	.BYTE $10,$1e,$00,$80,$00,$00,$00,$00 ; PADDING ($00)

	ORG $1020
