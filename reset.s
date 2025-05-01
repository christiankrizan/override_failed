; Override Failed, copyright (c) 2025 Kristián Križan. All rights reserved.
; https://github.com/christiankrizan/override_failed/
; Use permitted under the BSD 3-Clause License. See LICENSE file for details.
; -----------------------------------------------------------------------------

; NES system startup routine:
; > Disables interrupts and APU frame IRQs
; > Initialises the stack
; > Clears PPU control registers
; > Clears 2 kiB of RAM
; > Synchronises to VBLANK

; RESET:
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
	STA $0200, X ; #$FF hides all sprites by default.
	LDA #$00
	
	INX
	CPX #$00
	BNE CLEARMEMORY
	
	; All of this will take quite some time for the CPU to execute.
	; So, let's wait for another VBLANK.
:	
	BIT $2002 ; Wait for first bit of PPU register $2002 to be 1.
	BPL :-