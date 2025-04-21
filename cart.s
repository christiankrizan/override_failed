.segment "HEADER"
	.byte "NES"			; Identification string.
	.byte $1A
	.byte $02 ; Amount of program ROM in 16 kiB units.
	.byte $01 ; Amount of character ROM in 8 kiB units.
	.byte $00 ; Mapper and mirroring setup.
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00 ; Currently unused bytes
.segment "ZEROPAGE"
	; First of eight pages of 256 B of memory in the NES.
	; The first page is for variables to be used in the program.
VAR:	.RES	1	; Reserves 1 B of memory in the zero page for this variable
.segment "STARTUP"
.segment "VECTORS"
	; Used to define the behaviour of interupts. Three types may be defined.
	
.segment "CHARS"




00

slo