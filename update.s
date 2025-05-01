; Override Failed, copyright (c) 2025 Kristián Križan. All rights reserved.
; https://github.com/christiankrizan/override_failed/
; Use permitted under the BSD 3-Clause License. See LICENSE file for details.
; -----------------------------------------------------------------------------

; NES system update subroutine:
; > Poll controller input, stashes button vector into 'controller1'

; UPDATE:

	; Read controller input into byte vector.
	; 76543210
	; ||||||||
	; |||||||+-	RIGHT
	; ||||||+--	LEFT
	; |||||+---	DOWN
	; ||||+----	UP
	; |||+-----	START
	; ||+------	SELECT
	; |+-------	Button
	; +--------	Autton
	
PollController:
	LDX #$07	; Loop counter, initialised to #$07, because 8 buttons total.
PollControllerLoop:
	LDA $4016		; Player 1, $4016 -> A
	LSR A			; Logical shift right of A
	ROL Controller1 ; Rotate left button vector in memory location $0003
	
	DEX		 ; Decrement loop counter.
	;CPX #$00 ; Loop iterator == 0 ?
	BNE PollControllerLoop
	RTS