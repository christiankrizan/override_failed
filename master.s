; Override Failed, copyright (c) 2025 Kristián Križan. All rights reserved.
; https://github.com/christiankrizan/override_failed/
; Use permitted under the BSD 3-Clause License. See LICENSE file for details.
; -----------------------------------------------------------------------------

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
SpriteYPos:   	.res 1
SpriteTile:   	.res 1
SpriteAttrib: 	.res 1
SpriteXPos:   	.res 1
Controller1:	.res 1

.segment "STARTUP"
RESET:
	.include "reset.s"
	
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
	
	; Use variables to define a few sprite characteristics.
	LDA #$40        ; Start Y position
    STA SpriteYPos
    LDA #$00        ; Tile number 0 (example tile)
    STA SpriteTile
    LDA #$00        ; No flipping, palette 0
    STA SpriteAttrib
    LDA #$40        ; Start X position
    STA SpriteXPos
	
	LDX #$00
LOADSPRITES:
	LDA SPRITEDATA, X
	STA $0200, X
	INX
	CPX #$20	; 16 bytes - 4 bytes per sprite, 8 sprites in total.
	BNE LOADSPRITES

; Load background
;LOADBACKGROUND:
;	LDA $2002
;	LDA #$21
;	STA $2006
;	LDA $00
;	STA $2006
;	LDX $00
;LOADBACKGROUNDP1:
;	LDA BACKGROUNDDATA, X
;	STA $2007
;	INX
;	CPX #$00
;	BNE LOADBACKGROUNDP1
;LOADBACKGROUNDP2:
;	LDA BACKGROUNDDATA+256, X
;	STA $2007
;	INX
;	CPX #$00
;	BNE LOADBACKGROUNDP2

; Load background palette data.
;	LDA #$23
;	STA $2006
;	LDA #$D0
;	STA $2006
;	LDX #$00
;LOADBACKGROUNDPALETTEDATA:
;	LDA BACKGROUNDPALETTEDATA, X
;	STA $2007
;	INX
;	CPX #$20
;	BNE LOADBACKGROUNDPALETTEDATA

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
	; This happens in the VBLANK period.
	
	; The NMI segment should look more like this:
	; MAINLOOP: (this is the NMI (draw the screen))
	;	LDA #$00	; Load 1 byte of 0 in A
	;	STA $2003	; Set low byte (00) of the RAM address
		LDA #$02	; Load 1 byte of $02
		STA $4014	; Set high byte (02) of the RAM address, start the transfer
	
	; Draw game
	;JSR Draw
	
	; Update game
	JSR UPDATE
	
	RTI		; Return from interrupt.

UPDATE:
	.include "update.s"

PALETTEDATA:
	.byte $00, $0F, $00, $10, 	$00, $0A, $15, $01, 	$00, $29, $28, $27, 	$00, $34, $24, $14 	; Background palettes
	.byte $31, $0F, $15, $30, 	$00, $0F, $11, $30, 	$00, $0F, $30, $27, 	$00, $3C, $2C, $1C 	; Sprite palettes

SPRITEDATA:
	; Sprites are defined by 4 bytes, representing the Y coordinate,
	; which sprite of the 256 sprites in the CHR ROM it is, attributes,
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

; Include the backgound data and its palette.
.include "background_data_and_palette.s"
	; BACKGROUNDDATA
	; BACKGROUNDPALETTEDATA

.segment "VECTORS"
	; Used to define the behaviour of interupts. Three types may be defined.
	.word NMI   ; Non-maskable interrupt
	.word RESET ; What happens after the reset button is pressed?
	; Specialised hardware interrupts would go here.
.segment "CHARS"
	; Tell the assembler to include the binary file rom.character
	.incbin "rom.chr"