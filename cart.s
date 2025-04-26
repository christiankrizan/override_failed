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
RESET:
	SEI		; Set CPU to ignore all attempts to pull down the IRQ line.
	CLD		; Unset decimal mode register - the NES doesn't use decimal mode.
	
	; Disable sound IRQ
	LDX #%01000000
	STX $4017 ; Set APU frame interrupt flag to clear the flag.
	LDX #$00
	STX $4010 ; Disable pulse-code modulation on APU DCM

	; Initialise the stack register.
	LDX #$FF
	TXS ; Transfer X to the stack.
	
	; Clear out the PPU
	LDX #$00
	STX $2000 ; Set PPUCTRL Miscellaneous settings to #$00
	STX $2001 ; Set PPUMASK Rendering settings to #$00
	
:	
	; Wait for VBLANK -- we are waiting for the next screen to be drawn.
	BIT $2002 ; Wait for first bit of PPU register $2002 to be 1.
	BPL :-
	
	; Clear 2 kiB memory.
	TXA ; #$00 was already in X.
CLEARMEMORY:	; $0000 - $07FF
	STA $0000, X
	STA $0100, X
	;STA $0200, X ; To be initialised differently.
	STA $0300, X
	STA $0400, X
	STA $0500, X
	STA $0600, X
	STA $0700, X
	
	LDA #$FF
	STA $0200, X
	LDA #$00
	
	INX
	CPX #$00
	BNE CLEARMEMORY
	
	; All of this will take quite some time for the CPU to execute.
	; So, let's wait for another VBLANK.
:	
	BIT $2002 ; Wait for first bit of PPU register $2002 to be 1.
	BPL :-
	
	; Setting sprite range.
	LDA #$02
	STA $4014
	NOP ; Wait for transfer to happen.
	
	; Setting up palette data.
	; There is a total of 32 colours -- 4 palettes of 4 colours each,
	; for the background, and then the foreground sprites.
	LDA #$3F
	STA $2006
	LDA #$00
	STA $2006
	
	LDX #$00
LOADPALETTES:
	; Note: read/write to $2007 → PPU steps 1 step forward in memory.
	LDA PALETTEDATA, X
	STA $2007
	INX
	CPX #$20
	BNE LOADPALETTES
	
	LDX #$00
LOADSPRITES:
	LDA SPRITEDATA, X
	STA $0200, X
	INX
	CPX #$20	; 16 bytes - 4 bytes per sprite, 8 sprites in total.
	BNE LOADSPRITES
	
; Load background
LOADBACKGROUND:
	LDA $2002
	LDA #$21
	STA $2006
	LDA $00
	STA $2006
	LDX $00
LOADBACKGROUNDP1:
	LDA BACKGROUNDDATA, X
	STA $2007
	INX
	CPX #$00
	BNE LOADBACKGROUNDP1
LOADBACKGROUNDP2:
	LDA BACKGROUNDDATA+256, X
	STA $2007
	INX
	CPX #$00
	BNE LOADBACKGROUNDP2

; Load background palette data.
	LDA #$23
	STA $2006
	LDA #$D0
	STA $2006
	LDX #$00
LOADBACKGROUNDPALETTEDATA:
	LDA BACKGROUNDPALETTEDATA, X
	STA $2007
	INX
	CPX #$20
	BNE LOADBACKGROUNDPALETTEDATA

; Reset scrolling; the background will appear in the wrong place otherwise.
	LDA #$00
	STA $2005
	STA $2005

; Enable interrupts
	
	CLI ; Clear interrupt disable bit.
	
	LDA #%10010000	; Generate NMI whenever VBLANK occurs | Use second section of 256 sprites on the background.
	STA $2000
	
	LDA #%00011110	; Show sprites and background
	STA $2001
	
	INFLOOP:
		JMP INFLOOP
NMI:

	LDA #$02
	STA $4014
	RTI

PALETTEDATA:
	.byte $00, $0F, $00, $10, 	$00, $0A, $15, $01, 	$00, $29, $28, $27, 	$00, $34, $24, $14 	; Background palettes
	.byte $31, $0F, $15, $30, 	$00, $0F, $11, $30, 	$00, $0F, $30, $27, 	$00, $3C, $2C, $1C 	; Sprite palettes

SPRITEDATA:
	; Sprites are defined by 4 bytes, representing the Y coordinate,
	; which sprite of the 256 sprites in the CHR ROM it is, atributes,
	; and finally the X coordinate. Y, sprite number, attributes, X
	
	; Random sparkles.
	.byte $40, $00, $00, $40
	.byte $40, $01, $00, $48
	.byte $48, $10, $00, $40
	.byte $48, $11, $00, $48
	
	; Object-handle-thingy.
	.byte $50, $08, %00000001, $80
	.byte $50, $08, %01000001, $88
	.byte $58, $18, %00000001, $80
	.byte $58, $18, %01000001, $88

BACKGROUNDDATA:
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $01, $02, $03, $04, $05, $00, $00, $00, $00, $00, $00, $00, $06, $07, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $08, $09, $0A, $0B, $0B, $0B, $0C, $0D, $0E, $0F, $10, $11, $56, $13, $14, $0B, $15, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $16, $17, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $18, $19, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $1A, $1B, $1C, $1D, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $1E, $06, $1F, $00, $00, $00, $00, $00
	.byte $00, $00, $20, $21, $22, $23, $18, $24, $25, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $26, $27, $28, $00, $29, $2A, $00, $00, $00, $00, $00
	.byte $00, $00, $2B, $2C, $2D, $0B, $11, $2E, $2F, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $30, $31, $32, $33, $34, $35, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $36, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $18, $37, $38, $39, $3A, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $3B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $3C, $3D, $3E, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $3F, $40, $0B, $0B, $0B, $41, $42, $43, $44, $0B, $0B, $45, $0B, $0B, $0B, $0B, $46, $47, $48, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $49, $0B, $0B, $4A, $4B, $00, $4C, $4D, $0B, $4E, $4F, $50, $0B, $0B, $51, $00, $52, $53, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $3F, $54, $55, $12, $00, $00, $00, $57, $58, $59, $00, $5A, $5B, $5C, $5D, $00, $5E, $5F, $00, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $60, $61, $00, $00, $62, $63, $64, $65, $00, $66, $67, $68, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $69, $00, $00, $6A, $6B, $6C, $00, $6D, $6E, $6F, $70, $00, $00, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $71, $72, $73, $0B, $74, $75, $76, $77, $78, $00, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $79, $7A, $7B, $7C, $7D, $7E, $7F, $80, $81, $82, $00, $00, $00, $00, $00
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $4C, $83, $84, $85, $86, $35, $87, $00, $00, $00, $00, $00, $00

BACKGROUNDPALETTEDATA:
	.byte $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55
	.byte $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55, $55


.segment "VECTORS"
	; Used to define the behaviour of interupts. Three types may be defined.
	.word NMI ; Non-maskable interrupt
	.word RESET ; What happens after the reset button is pressed?
	; Specialised hardware interrupts would go here.
.segment "CHARS"
	; Tell the assembler to include the binary file rom.character
	.incbin "rom.chr"