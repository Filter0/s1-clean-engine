;  =========================================================================
; |           Sonic the Hedgehog Disassembly for Sega Mega Drive            |
;  =========================================================================
;
; Disassembly created by Hivebrain
; thanks to drx, Stealth and Esrael L.G. Neto

; ===========================================================================

	include	"Constants.asm"
	include	"Variables.asm"
	include	"Macros.asm"

EnableSRAM:	equ 0	; change to 1 to enable SRAM
BackupSRAM:	equ 1
AddressSRAM:	equ 3	; 0 = odd+even; 2 = even only; 3 = odd only

FixSpikeFeature:equ 0

; ===========================================================================

StartOfRom:
Vectors:	dc.l v_systemstack&$FFFFFF	; Initial stack pointer value
		dc.l EntryPoint			; Start of program
		dc.l ErrorTrap			; Bus error
		dc.l ErrorTrap		; Address error (4)
		dc.l ErrorTrap		; Illegal instruction
		dc.l ErrorTrap			; Division by zero
		dc.l ErrorTrap			; CHK exception
		dc.l ErrorTrap			; TRAPV exception (8)
		dc.l ErrorTrap		; Privilege violation
		dc.l ErrorTrap				; TRACE exception
		dc.l ErrorTrap		; Line-A emulator
		dc.l ErrorTrap		; Line-F emulator (12)
		dc.l ErrorTrap		; Unused (reserved)
		dc.l ErrorTrap		; Unused (reserved)
		dc.l ErrorTrap		; Unused (reserved)
		dc.l ErrorTrap		; Unused (reserved) (16)
		dc.l ErrorTrap		; Unused (reserved)
		dc.l ErrorTrap		; Unused (reserved)
		dc.l ErrorTrap		; Unused (reserved)
		dc.l ErrorTrap		; Unused (reserved) (20)
		dc.l ErrorTrap		; Unused (reserved)
		dc.l ErrorTrap		; Unused (reserved)
		dc.l ErrorTrap		; Unused (reserved)
		dc.l ErrorTrap		; Unused (reserved) (24)
		dc.l ErrorTrap		; Spurious exception
		dc.l ErrorTrap			; IRQ level 1
		dc.l ErrorTrap			; IRQ level 2
		dc.l ErrorTrap			; IRQ level 3 (28)
		dc.l HBlank				; IRQ level 4 (horizontal retrace interrupt)
		dc.l ErrorTrap			; IRQ level 5
		dc.l VBlank				; IRQ level 6 (vertical retrace interrupt)
		dc.l ErrorTrap			; IRQ level 7 (32)
		dc.l ErrorTrap			; TRAP #00 exception
		dc.l ErrorTrap			; TRAP #01 exception
		dc.l ErrorTrap			; TRAP #02 exception
		dc.l ErrorTrap			; TRAP #03 exception (36)
		dc.l ErrorTrap			; TRAP #04 exception
		dc.l ErrorTrap			; TRAP #05 exception
		dc.l ErrorTrap			; TRAP #06 exception
		dc.l ErrorTrap			; TRAP #07 exception (40)
		dc.l ErrorTrap			; TRAP #08 exception
		dc.l ErrorTrap			; TRAP #09 exception
		dc.l ErrorTrap			; TRAP #10 exception
		dc.l ErrorTrap			; TRAP #11 exception (44)
		dc.l ErrorTrap			; TRAP #12 exception
		dc.l ErrorTrap			; TRAP #13 exception
		dc.l ErrorTrap			; TRAP #14 exception
		dc.l ErrorTrap			; TRAP #15 exception (48)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.l ErrorTrap			; Unused (reserved)
		dc.b "SEGA MEGA DRIVE " ; Hardware system ID (Console name)
		dc.b "(C)SEGA 1989.OCT" ; Copyright holder and release date (In this case, the Japanese release of the MD)
		dc.b "SONIC THE               HEDGEHOG                " ; Domestic name
		dc.b "SONIC THE               HEDGEHOG                " ; International name
		dc.b "GM 00000000-00"   ; Serial/version number
Checksum:       dc.w 0
		dc.b "J               " ; I/O support
		dc.l StartOfRom		; Start address of ROM
RomEndLoc:	dc.l EndOfRom-1		; End address of ROM
		dc.l $FF0000		; Start address of RAM
		dc.l $FFFFFF		; End address of RAM
		if EnableSRAM=1
		dc.b $52, $41, $A0+(BackupSRAM<<6)+(AddressSRAM<<3), $20 ; SRAM support
		else
		dc.l $20202020
		endc
		dc.l $20202020		; SRAM start ($200001)
		dc.l $20202020		; SRAM end ($20xxxx)
		dc.b "                                                    " ; Notes (unused, anything can be put in this space, but it has to be 52 bytes.)
		dc.b "JUE             " ; Region (Country code)
EndOfHeader:

; ===========================================================================

EntryPoint:
		tst.l	(z80_port_1_control).l ; test port A & B control registers
		bne.s	PortA_Ok
		tst.w	(z80_expansion_control).l ; test port C control register

PortA_Ok:
		bne.s	SkipSetup ; Skip the VDP and Z80 setup code if port A, B or C is ok...?
		lea	SetupValues(pc),a5	; Load setup values array address.
		movem.w	(a5)+,d5-d7
		movem.l	(a5)+,a0-a4
		move.b	-$10FF(a1),d0	; get hardware version (from $A10001)
		andi.b	#$F,d0
		beq.s	SkipSecurity	; If the console has no TMSS, skip the security stuff.
		move.l	#'SEGA',$2F00(a1) ; move "SEGA" to TMSS register ($A14000)

SkipSecurity:
		move.w	(a4),d0	; clear write-pending flag in VDP to prevent issues if the 68k has been reset in the middle of writing a command long word to the VDP.
		moveq	#0,d0	; clear d0
		movea.l	d0,a6	; clear a6
		move.l	a6,usp	; set usp to $0

		moveq	#$17,d1
VDPInitLoop:
		move.b	(a5)+,d5	; add $8000 to value
		move.w	d5,(a4)		; move value to	VDP register
		add.w	d7,d5		; next register
		dbf	d1,VDPInitLoop

		move.l	(a5)+,(a4)
		move.w	d0,(a3)		; clear	the VRAM
		move.w	d7,(a1)		; stop the Z80
		move.w	d7,(a2)		; reset	the Z80

WaitForZ80:
		btst	d0,(a1)		; has the Z80 stopped?
		bne.s	WaitForZ80	; if not, branch

		moveq	#$25,d2
Z80InitLoop:
		move.b	(a5)+,(a0)+
		dbf	d2,Z80InitLoop

		move.w	d0,(a2)
		move.w	d0,(a1)		; start	the Z80
		move.w	d7,(a2)		; reset	the Z80

ClrRAMLoop:
		move.l	d0,-(a6)	; clear 4 bytes of RAM
		dbf	d6,ClrRAMLoop	; repeat until the entire RAM is clear
		move.l	(a5)+,(a4)	; set VDP display mode and increment mode
		move.l	(a5)+,(a4)	; set VDP to CRAM write

		moveq	#$1F,d3	; set repeat times
ClrCRAMLoop:
		move.l	d0,(a3)	; clear 2 palettes
		dbf	d3,ClrCRAMLoop	; repeat until the entire CRAM is clear
		move.l	(a5)+,(a4)	; set VDP to VSRAM write

		moveq	#$13,d4
ClrVSRAMLoop:
		move.l	d0,(a3)	; clear 4 bytes of VSRAM.
		dbf	d4,ClrVSRAMLoop	; repeat until the entire VSRAM is clear
		moveq	#3,d5

PSGInitLoop:
		move.b	(a5)+,$11(a3)	; reset	the PSG
		dbf	d5,PSGInitLoop	; repeat for other channels
		move.w	d0,(a2)
		movem.l	(a6),d0-a6	; clear all registers
		disable_ints

SkipSetup:
		bra.s	GameProgram	; begin game

; ===========================================================================
SetupValues:	dc.w $8000		; VDP register start number
		dc.w $3FFF		; size of RAM/4
		dc.w $100		; VDP register diff

		dc.l z80_ram		; start	of Z80 RAM
		dc.l z80_bus_request	; Z80 bus request
		dc.l z80_reset		; Z80 reset
		dc.l vdp_data_port	; VDP data
		dc.l vdp_control_port	; VDP control

		dc.b 4			; VDP $80 - 8-colour mode
		dc.b $14		; VDP $81 - Megadrive mode, DMA enable
		dc.b ($C000>>10)	; VDP $82 - foreground nametable address
		dc.b ($F000>>10)	; VDP $83 - window nametable address
		dc.b ($E000>>13)	; VDP $84 - background nametable address
		dc.b ($D800>>9)		; VDP $85 - sprite table address
		dc.b 0			; VDP $86 - unused
		dc.b 0			; VDP $87 - background colour
		dc.b 0			; VDP $88 - unused
		dc.b 0			; VDP $89 - unused
		dc.b 255		; VDP $8A - HBlank register
		dc.b 0			; VDP $8B - full screen scroll
		dc.b $81		; VDP $8C - 40 cell display
		dc.b ($DC00>>10)	; VDP $8D - hscroll table address
		dc.b 0			; VDP $8E - unused
		dc.b 1			; VDP $8F - VDP increment
		dc.b 1			; VDP $90 - 64 cell hscroll size
		dc.b 0			; VDP $91 - window h position
		dc.b 0			; VDP $92 - window v position
		dc.w $FFFF		; VDP $93/94 - DMA length
		dc.w 0			; VDP $95/96 - DMA source
		dc.b $80		; VDP $97 - DMA fill VRAM
		dc.l $40000080		; VRAM address 0

		dc.b $AF		; xor	a
		dc.b $01, $D9, $1F	; ld	bc,1fd9h
		dc.b $11, $27, $00	; ld	de,0027h
		dc.b $21, $26, $00	; ld	hl,0026h
		dc.b $F9		; ld	sp,hl
		dc.b $77		; ld	(hl),a
		dc.b $ED, $B0		; ldir
		dc.b $DD, $E1		; pop	ix
		dc.b $FD, $E1		; pop	iy
		dc.b $ED, $47		; ld	i,a
		dc.b $ED, $4F		; ld	r,a
		dc.b $D1		; pop	de
		dc.b $E1		; pop	hl
		dc.b $F1		; pop	af
		dc.b $08		; ex	af,af'
		dc.b $D9		; exx
		dc.b $C1		; pop	bc
		dc.b $D1		; pop	de
		dc.b $E1		; pop	hl
		dc.b $F1		; pop	af
		dc.b $F9		; ld	sp,hl
		dc.b $F3		; di
		dc.b $ED, $56		; im1
		dc.b $36, $E9		; ld	(hl),e9h
		dc.b $E9		; jp	(hl)

		dc.w $8104		; VDP display mode
		dc.w $8F02		; VDP increment
		dc.l $C0000000		; CRAM write mode
		dc.l $40000010		; VSRAM address 0

		dc.b $9F, $BF, $DF, $FF	; values for PSG channel volumes
; ===========================================================================

GameProgram:
		tst.w	(vdp_control_port).l
		btst	#6,($A1000D).l
		beq.s	CheckSumCheck
		cmpi.l	#'init',(v_init).w ; has checksum routine already run?
		beq.s	GameInit	; if yes, branch

CheckSumCheck:
		lea	($FFFFFE00).w,a6
		moveq	#0,d7
		moveq	#$7F,d6
	@clearRAM:
		move.l	d7,(a6)+
		dbf	d6,@clearRAM	; clear RAM ($FE00-$FFFF)

		move.b	(z80_version).l,d0
		andi.b	#$C0,d0
		move.b	d0,(v_megadrive).w ; get region setting
		move.l	#'init',(v_init).w ; set flag so checksum won't run again

GameInit:
		lea	($FF0000).l,a6
		moveq	#0,d7
		move.w	#$3F7F,d6
	@clearRAM:
		move.l	d7,(a6)+
		dbf	d6,@clearRAM	; clear RAM ($0000-$FDFF)

		bsr.w	VDPSetupGame
		bsr.w	SoundDriverLoad
		bsr.w	JoypadInit
		move.b	#id_Sega,(v_gamemode).w ; set Game Mode to Sega Screen

MainGameLoop:
		move.b	(v_gamemode).w,d0 ; load Game Mode
		andi.w	#$1C,d0	; limit Game Mode value to $1C max (change to a maximum of 7C to add more game modes)
		jsr	GameModeArray(pc,d0.w) ; jump to apt location in ROM
		bra.s	MainGameLoop	; loop indefinitely
; ===========================================================================
; ---------------------------------------------------------------------------
; Main game mode array
; ---------------------------------------------------------------------------

GameModeArray:

ptr_GM_Sega:	bra.w	GM_Sega		; Sega Screen ($00)

ptr_GM_Title:	bra.w	GM_Title	; Title	Screen ($04)

ptr_GM_Level:	bra.w	GM_Level	; Normal Level ($08)

; ===========================================================================
; Crash/Freeze the 68000. Unlike Sonic 2, Sonic 1 uses the 68000 for playing music, so it stops too

ErrorTrap:
		bra.s	ErrorTrap

; ===========================================================================

Art_Text:	incbin	"artunc\menutext.bin" ; text used in level select and debug mode
		even

; ===========================================================================
; ---------------------------------------------------------------------------
; Vertical interrupt
; ---------------------------------------------------------------------------

VBlank:
		movem.l	d0-a6,-(sp)
		tst.b	(v_vbla_routine).w
		beq.s	VBla_00
		move.l	#$40000010,(vdp_control_port).l
		move.l	(v_scrposy_dup).w,(vdp_data_port).l ; send screen y-axis pos. to VSRAM
		move.b	(v_vbla_routine).w,d0
		clr.b	(v_vbla_routine).w
		move.w	#1,(f_hbla_pal).w
		andi.w	#$3E,d0
		move.w	VBla_Index(pc,d0.w),d0
		jsr	VBla_Index(pc,d0.w)

VBla_Music:
		jsr	(UpdateMusic).l

VBla_Exit:
		addq.l	#1,(v_vbla_count).w
		movem.l	(sp)+,d0-a6
		rte
; ===========================================================================
VBla_Index:	dc.w VBla_00-VBla_Index
                dc.w VBla_02-VBla_Index
		dc.w VBla_04-VBla_Index
                dc.w VBla_06-VBla_Index
		dc.w VBla_08-VBla_Index
                dc.w VBla_0A-VBla_Index
		dc.w VBla_0C-VBla_Index
                dc.w VBla_0E-VBla_Index
		dc.w VBla_10-VBla_Index
                dc.w VBla_12-VBla_Index
		dc.w VBla_14-VBla_Index
                dc.w VBla_16-VBla_Index
; ===========================================================================

VBla_00:
		cmpi.b	#$80+id_Level,(v_gamemode).w
		beq.s	@islevel
		cmpi.b	#id_Level,(v_gamemode).w ; is game on a level?
		bne.s	VBla_Music	; if not, branch

	@islevel:
		tst.b	(f_water).w ; is level LZ ?
		beq.s	VBla_Music	; if not, branch

		move.w	(vdp_control_port).l,d0
		move.w	#1,(f_hbla_pal).w ; set HBlank flag
		tst.b	(f_wtr_state).w	; is water above top of screen?
		bne.s	@waterabove 	; if yes, branch

		writeCRAM	v_pal_dry,$80,0
		bra.s	@waterbelow

@waterabove:
		writeCRAM	v_pal_water,$80,0

	@waterbelow:
		move.w	(v_hbla_hreg).w,(a5)
		bra.w	VBla_Music
; ===========================================================================

VBla_02:
		bsr.w	sub_106E

VBla_14:
		tst.w	(v_demolength).w
		beq.s	@end
		subq.w	#1,(v_demolength).w

	@end:
		rts
; ===========================================================================

VBla_04:
		bsr.w	sub_106E
		bsr.w	LoadTilesAsYouMove_BGOnly
		bsr.w	sub_1642
		tst.w	(v_demolength).w
		beq.s	@end
		subq.w	#1,(v_demolength).w

	@end:
		rts
; ===========================================================================

VBla_06:
		bra.w	sub_106E
; ===========================================================================

VBla_10:
VBla_08:
		bsr.w	ReadJoypads
		tst.b	(f_wtr_state).w
		bne.s	@waterabove

		writeCRAM	v_pal_dry,$80,0
		bra.s	@waterbelow

@waterabove:
		writeCRAM	v_pal_water,$80,0

	@waterbelow:
		move.w	(v_hbla_hreg).w,(a5)

		writeVRAM	v_hscrolltablebuffer,$380,vram_hscroll
		writeVRAM	v_spritetablebuffer,$280,vram_sprites
		tst.b	(f_sonframechg).w ; has Sonic's sprite changed?
		beq.s	@nochg		; if not, branch

		writeVRAM	v_sgfx_buffer,$2E0,vram_sonic ; load new Sonic gfx
		move.b	#0,(f_sonframechg).w

	@nochg:
		movem.l	(v_screenposx).w,d0-d7
		movem.l	d0-d7,(v_screenposx_dup).w
		movem.l	(v_fg_scroll_flags).w,d0-d1
		movem.l	d0-d1,(v_fg_scroll_flags_dup).w
		bsr.w	LoadTilesAsYouMove
		jsr	(AnimateLevelGfx).l
		jsr	(HUD_Update).l
		bsr.w	ProcessDPLC2
		tst.w	(v_demolength).w ; is there time left on the demo?
		beq.s	@end		; if not, branch
		subq.w	#1,(v_demolength).w ; subtract 1 from time left

	@end:
		rts
; End of function Demo_Time

; ===========================================================================

VBla_0A:
		bsr.w	ReadJoypads
		writeCRAM	v_pal_dry,$80,0
		writeVRAM	v_spritetablebuffer,$280,vram_sprites
		writeVRAM	v_hscrolltablebuffer,$380,vram_hscroll
		tst.b	(f_sonframechg).w ; has Sonic's sprite changed?
		beq.s	@nochg		; if not, branch

		writeVRAM	v_sgfx_buffer,$2E0,vram_sonic ; load new Sonic gfx
		move.b	#0,(f_sonframechg).w

	@nochg:
		tst.w	(v_demolength).w	; is there time left on the demo?
		beq.s	@end	; if not, return
		subq.w	#1,(v_demolength).w	; subtract 1 from time left in demo

	@end:
		rts
; ===========================================================================

VBla_0C:
		bsr.w	ReadJoypads
		tst.b	(f_wtr_state).w
		bne.s	@waterabove

		writeCRAM	v_pal_dry,$80,0
		bra.s	@waterbelow

@waterabove:
		writeCRAM	v_pal_water,$80,0

	@waterbelow:
		move.w	(v_hbla_hreg).w,(a5)
		writeVRAM	v_hscrolltablebuffer,$380,vram_hscroll
		writeVRAM	v_spritetablebuffer,$280,vram_sprites
		tst.b	(f_sonframechg).w
		beq.s	@nochg
		writeVRAM	v_sgfx_buffer,$2E0,vram_sonic
		move.b	#0,(f_sonframechg).w

	@nochg:
		movem.l	(v_screenposx).w,d0-d7
		movem.l	d0-d7,(v_screenposx_dup).w
		movem.l	(v_fg_scroll_flags).w,d0-d1
		movem.l	d0-d1,(v_fg_scroll_flags_dup).w
		bsr.w	LoadTilesAsYouMove
		jsr	(AnimateLevelGfx).l
		jsr	(HUD_Update).l
		bra.w	sub_1642
; ===========================================================================

VBla_0E:
		bsr.w	sub_106E
		addq.b	#1,($FFFFF628).w
		move.b	#$E,(v_vbla_routine).w
		rts
; ===========================================================================

VBla_12:
		bsr.w	sub_106E
		move.w	(v_hbla_hreg).w,(a5)
		bra.w	sub_1642
; ===========================================================================

VBla_16:
		bsr.w	ReadJoypads
		writeCRAM	v_pal_dry,$80,0
		writeVRAM	v_spritetablebuffer,$280,vram_sprites
		writeVRAM	v_hscrolltablebuffer,$380,vram_hscroll
		tst.b	(f_sonframechg).w
		beq.s	@nochg
		writeVRAM	v_sgfx_buffer,$2E0,vram_sonic
		move.b	#0,(f_sonframechg).w

	@nochg:
		tst.w	(v_demolength).w
		beq.s	@end
		subq.w	#1,(v_demolength).w

	@end:
		rts

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_106E:
		bsr.w	ReadJoypads
		tst.b	(f_wtr_state).w ; is water above top of screen?
		bne.s	@waterabove	; if yes, branch
		writeCRAM	v_pal_dry,$80,0
		bra.s	@waterbelow

	@waterabove:
		writeCRAM	v_pal_water,$80,0

	@waterbelow:
		writeVRAM	v_spritetablebuffer,$280,vram_sprites
		writeVRAM	v_hscrolltablebuffer,$380,vram_hscroll
		rts
; End of function sub_106E

; ---------------------------------------------------------------------------
; Horizontal interrupt
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


HBlank:
		disable_ints
		tst.w	(f_hbla_pal).w	; is palette set to change?
		beq.s	@nochg		; if not, branch
		clr.w	(f_hbla_pal).w
		movem.l	a0-a1,-(sp)
		lea	(vdp_data_port).l,a1
		lea	(v_pal_water).w,a0 ; get palette from RAM
		move.l	#$C0000000,4(a1) ; set VDP to CRAM write
		move.l	(a0)+,(a1)	; move palette to CRAM
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.w	#$8A00+223,4(a1) ; reset HBlank register
		movem.l	(sp)+,a0-a1

	@nochg:
		rte
; End of function HBlank

; ---------------------------------------------------------------------------
; Subroutine to	initialise joypads
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


JoypadInit:
		moveq	#$40,d0
		move.b	d0,($A10009).l	; init port 1 (joypad 1)
		move.b	d0,($A1000B).l	; init port 2 (joypad 2)
		move.b	d0,($A1000D).l	; init port 3 (expansion/extra)
		rts
; End of function JoypadInit

; ---------------------------------------------------------------------------
; Subroutine to	read joypad input, and send it to the RAM
; ---------------------------------------------------------------------------
; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ReadJoypads:
		lea	(v_jpadhold1).w,a0 ; address where joypad states are written
		lea	($A10003).l,a1	; first	joypad port
		bsr.s	@read		; do the first joypad
		addq.w	#2,a1		; do the second	joypad

	@read:
		move.b	#0,(a1)
		nop
		nop
		move.b	(a1),d0
		lsl.b	#2,d0
		andi.b	#$C0,d0
		move.b	#$40,(a1)
		nop
		nop
		move.b	(a1),d1
		andi.b	#$3F,d1
		or.b	d1,d0
		not.b	d0
		move.b	(a0),d1
		eor.b	d0,d1
		move.b	d0,(a0)+
		and.b	d0,d1
		move.b	d1,(a0)+
		rts
; End of function ReadJoypads


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


VDPSetupGame:
		lea	(vdp_control_port).l,a0
		lea	(vdp_data_port).l,a1
		lea	VDPSetupArray(pc),a2
		moveq	#$12,d7

	@setreg:
		move.w	(a2)+,(a0)
		dbf	d7,@setreg	; set the VDP registers

		move.w	(VDPSetupArray+2).l,d0
		move.w	d0,(v_vdp_buffer1).w
		move.w	#$8A00+223,(v_hbla_hreg).w	; H-INT every 224th scanline
		moveq	#0,d0
		move.l	#$C0000000,(vdp_control_port).l ; set VDP to CRAM write
		moveq	#$3F,d7

	@clrCRAM:
		move.w	d0,(a1)
		dbf	d7,@clrCRAM	; clear	the CRAM

		moveq   #0,d0
                move.l	d0,(v_scrposy_dup).w
		move.l	d0,(v_scrposx_dup).w
		move.l	d1,-(sp)
		fillVRAM	0,$FFFF,0

	@waitforDMA:
		move.w	(a5),d1
		btst	#1,d1		; is DMA (fillVRAM) still running?
		bne.s	@waitforDMA	; if yes, branch

		move.w	#$8F02,(a5)	; set VDP increment size
		move.l	(sp)+,d1
		rts
; End of function VDPSetupGame

; ===========================================================================
VDPSetupArray:	dc.w $8004		; 8-colour mode
		dc.w $8134		; enable V.interrupts, enable DMA
		dc.w $8200+(vram_fg>>10) ; set foreground nametable address
		dc.w $8300+($A000>>10)	; set window nametable address
		dc.w $8400+(vram_bg>>13) ; set background nametable address
		dc.w $8500+(vram_sprites>>9) ; set sprite table address
		dc.w $8600		; unused
		dc.w $8700		; set background colour (palette entry 0)
		dc.w $8800		; unused
		dc.w $8900		; unused
		dc.w $8A00		; default H.interrupt register
		dc.w $8B00		; full-screen vertical scrolling
		dc.w $8C81		; 40-cell display mode
		dc.w $8D00+(vram_hscroll>>10) ; set background hscroll address
		dc.w $8E00		; unused
		dc.w $8F02		; set VDP increment size
		dc.w $9001		; 64-cell hscroll size
		dc.w $9100		; window horizontal position
		dc.w $9200		; window vertical position

; ---------------------------------------------------------------------------
; Subroutine to	clear the screen
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ClearScreen:
		fillVRAM	0,$FFF,vram_fg ; clear foreground namespace

	@wait1:
		move.w	(a5),d1
		btst	#1,d1
		bne.s	@wait1

		move.w	#$8F02,(a5)
		fillVRAM	0,$FFF,vram_bg ; clear background namespace

	@wait2:
		move.w	(a5),d1
		btst	#1,d1
		bne.s	@wait2

		move.w	#$8F02,(a5)
		moveq   #0,d0
                move.l	d0,(v_scrposy_dup).w
		move.l	d0,(v_scrposx_dup).w

		lea	(v_spritetablebuffer).w,a1
		moveq	#0,d0
		move.w	#($280/4)-1,d1

	@clearsprites:
		move.l	d0,(a1)+
		dbf	d1,@clearsprites ; clear sprite table (in RAM)

		lea	(v_hscrolltablebuffer).w,a1
		moveq	#0,d0
		move.w	#($400/4)-1,d1

	@clearhscroll:
		move.l	d0,(a1)+
		dbf	d1,@clearhscroll ; clear hscroll table (in RAM)
		rts
; End of function ClearScreen

; ---------------------------------------------------------------------------
; Subroutine to	load the sound driver
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SoundDriverLoad:
		stopZ80
		resetZ80
		lea	(Kos_Z80).l,a0	; load sound driver
		lea	(z80_ram).l,a1	; target Z80 RAM
		bsr.w	KosDec		; decompress
		resetZ80a
		resetZ80
		startZ80
		rts
; End of function SoundDriverLoad

		include	"_incObj\sub PlaySound.asm"
		include	"_inc\PauseGame.asm"

; ---------------------------------------------------------------------------
; Subroutine to	copy a tile map from RAM to VRAM namespace

; input:
;	a1 = tile map address
;	d0 = VRAM address
;	d1 = width (cells)
;	d2 = height (cells)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


TilemapToVRAM:
		lea	(vdp_data_port).l,a6
		move.l	#$800000,d4

	Tilemap_Line:
		move.l	d0,4(a6)	; move d0 to VDP_control_port
		move.w	d1,d3

	Tilemap_Cell:
		move.w	(a1)+,(a6)	; write value to namespace
		dbf	d3,Tilemap_Cell	; next tile
		add.l	d4,d0		; goto next line
		dbf	d2,Tilemap_Line	; next line
		rts
; End of function TilemapToVRAM

		include	"_inc\Nemesis Decompression.asm"


; ---------------------------------------------------------------------------
; Subroutine to load pattern load cues (aka to queue pattern load requests)
; ---------------------------------------------------------------------------

; ARGUMENTS
; d0 = index of PLC list
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

; LoadPLC:
AddPLC:
		movem.l	a1-a2,-(sp)
		lea	(ArtLoadCues).l,a1
		add.w	d0,d0
		move.w	(a1,d0.w),d0
		lea	(a1,d0.w),a1		; jump to relevant PLC
		lea	(v_plc_buffer).w,a2 ; PLC buffer space

	@findspace:
		tst.l	(a2)		; is space available in RAM?
		beq.s	@copytoRAM	; if yes, branch
		addq.w	#6,a2		; if not, try next space
		bra.s	@findspace
; ===========================================================================

@copytoRAM:
		move.w	(a1)+,d0	; get length of PLC
		bmi.s	@skip

	@loop:
		move.l	(a1)+,(a2)+
		move.w	(a1)+,(a2)+	; copy PLC to RAM
		dbf	d0,@loop	; repeat for length of PLC

	@skip:
		movem.l	(sp)+,a1-a2 ; a1=object
		rts
; End of function AddPLC


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||
; Queue pattern load requests, but clear the PLQ first

; ARGUMENTS
; d0 = index of PLC list (see ArtLoadCues)

; NOTICE: This subroutine does not check for buffer overruns. The programmer
;	  (or hacker) is responsible for making sure that no more than
;	  16 load requests are copied into the buffer.
;	  _________DO NOT PUT MORE THAN 16 LOAD REQUESTS IN A LIST!__________
;         (or if you change the size of Plc_Buffer, the limit becomes (Plc_Buffer_Only_End-Plc_Buffer)/6)

; LoadPLC2:
NewPLC:
		movem.l	a1-a2,-(sp)
		lea	(ArtLoadCues).l,a1
		add.w	d0,d0
		move.w	(a1,d0.w),d0
		lea	(a1,d0.w),a1	; jump to relevant PLC
		bsr.s	ClearPLC	; erase any data in PLC buffer space
		lea	(v_plc_buffer).w,a2
		move.w	(a1)+,d0	; get length of PLC
		bmi.s	@skip		; if it's negative, skip the next loop

	@loop:
		move.l	(a1)+,(a2)+
		move.w	(a1)+,(a2)+	; copy PLC to RAM
		dbf	d0,@loop		; repeat for length of PLC

	@skip:
		movem.l	(sp)+,a1-a2
		rts
; End of function NewPLC

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

; ---------------------------------------------------------------------------
; Subroutine to	clear the pattern load cues
; ---------------------------------------------------------------------------

; Clear the pattern load queue ($FFF680 - $FFF700)


ClearPLC:
		lea	(v_plc_buffer).w,a2 ; PLC buffer space in RAM
		moveq   #0,d1
		moveq	#$1F,d0	; bytesToLcnt(v_plc_buffer_end-v_plc_buffer)

	@loop:
		move.l	d1,(a2)+
		dbf	d0,@loop
		rts
; End of function ClearPLC

; ---------------------------------------------------------------------------
; Subroutine to	use graphics listed in a pattern load cue
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


RunPLC:
		tst.l	(v_plc_buffer).w
		beq.s	Rplc_Exit
		tst.w	(f_plc_execute).w
		bne.s	Rplc_Exit
		movea.l	(v_plc_buffer).w,a0
		lea	NemPCD_WriteRowToVDP(pc),a3
		lea	(v_ngfx_buffer).w,a1
		move.w	(a0)+,d2
		bpl.s	loc_160E
		lea	NemPCD_WriteRowToVDP_XOR-NemPCD_WriteRowToVDP(a3),a3

loc_160E:
		andi.w	#$7FFF,d2
		bsr.w	NemDec_BuildCodeTable
		move.b	(a0)+,d5
		asl.w	#8,d5
		move.b	(a0)+,d5
		moveq	#$10,d6
		moveq	#0,d0
		move.l	a0,(v_plc_buffer).w
		move.l	a3,(v_ptrnemcode).w
		move.l	d0,($FFFFF6E4).w
		move.l	d0,($FFFFF6E8).w
		move.l	d0,($FFFFF6EC).w
		move.l	d5,($FFFFF6F0).w
		move.l	d6,($FFFFF6F4).w
		move.w	d2,(f_plc_execute).w

Rplc_Exit:
		rts
; End of function RunPLC


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_1642:
		tst.w	(f_plc_execute).w
		beq.w	locret_16DA
		move.w	#9,($FFFFF6FA).w
		moveq	#0,d0
		move.w	($FFFFF684).w,d0
		addi.w	#$120,($FFFFF684).w
		bra.s	loc_1676
; End of function sub_1642


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


; sub_165E:
ProcessDPLC2:
		tst.w	(f_plc_execute).w
		beq.s	locret_16DA
		move.w	#3,($FFFFF6FA).w
		moveq	#0,d0
		move.w	($FFFFF684).w,d0
		addi.w	#$60,($FFFFF684).w

loc_1676:
		lea	(vdp_control_port).l,a4
		lsl.l	#2,d0
		lsr.w	#2,d0
		ori.w	#$4000,d0
		swap	d0
		move.l	d0,(a4)
		subq.w	#4,a4
		movea.l	(v_plc_buffer).w,a0
		movea.l	(v_ptrnemcode).w,a3
		move.l	($FFFFF6E4).w,d0
		move.l	($FFFFF6E8).w,d1
		move.l	($FFFFF6EC).w,d2
		move.l	($FFFFF6F0).w,d5
		move.l	($FFFFF6F4).w,d6
		lea	(v_ngfx_buffer).w,a1

loc_16AA:
		movea.w	#8,a5
		bsr.w	NemPCD_NewRow
		subq.w	#1,(f_plc_execute).w
		beq.s	loc_16DC
		subq.w	#1,($FFFFF6FA).w
		bne.s	loc_16AA
		move.l	a0,(v_plc_buffer).w
		move.l	a3,(v_ptrnemcode).w
		move.l	d0,($FFFFF6E4).w
		move.l	d1,($FFFFF6E8).w
		move.l	d2,($FFFFF6EC).w
		move.l	d5,($FFFFF6F0).w
		move.l	d6,($FFFFF6F4).w

locret_16DA:
		rts
; ===========================================================================

loc_16DC:
		lea	(v_plc_buffer).w,a0
		moveq	#$15,d0

loc_16E2:
		move.l	6(a0),(a0)+
		dbf	d0,loc_16E2
		rts
; End of function ProcessDPLC2

; ---------------------------------------------------------------------------
; Subroutine to	execute	the pattern load cue
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


QuickPLC:
		lea	(ArtLoadCues).l,a1 ; load the PLC index
		add.w	d0,d0
		move.w	(a1,d0.w),d0
		lea	(a1,d0.w),a1
		move.w	(a1)+,d1	; get length of PLC

	Qplc_Loop:
		movea.l	(a1)+,a0	; get art pointer
		moveq	#0,d0
		move.w	(a1)+,d0	; get VRAM address
		lsl.l	#2,d0
		lsr.w	#2,d0
		ori.w	#$4000,d0
		swap	d0
		move.l	d0,(vdp_control_port).l ; converted VRAM address to VDP format
		bsr.w	NemDec		; decompress
		dbf	d1,Qplc_Loop	; repeat for length of PLC
		rts
; End of function QuickPLC

		include	"_inc\Enigma Decompression.asm"
		include	"_inc\Kosinski Decompression.asm"

		include	"_inc\PaletteCycle.asm"

Pal_TitleCyc:	incbin	"palette\Cycle - Title Screen Water.bin"
Pal_GHZCyc:	incbin	"palette\Cycle - GHZ.bin"

; ---------------------------------------------------------------------------
; Subroutine to	fade in from black
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PaletteFadeIn:
		move.w	#$003F,(v_pfade_start).w ; set start position = 0; size = $40

PalFadeIn_Alt:				; start position and size are already set
		moveq	#0,d0
		lea	(v_pal_dry).w,a0
		move.b	(v_pfade_start).w,d0
		adda.w	d0,a0
		moveq	#cBlack,d1
		move.b	(v_pfade_size).w,d0

	@fill:
		move.w	d1,(a0)+
		dbf	d0,@fill 	; fill palette with black

		moveq	#$15,d4

	@mainloop:
		move.b	#$12,(v_vbla_routine).w
		bsr.w	WaitForVBla
		bsr.s	FadeIn_FromBlack
		bsr.w	RunPLC
		dbf	d4,@mainloop
		rts
; End of function PaletteFadeIn


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


FadeIn_FromBlack:
		moveq	#0,d0
		lea	(v_pal_dry).w,a0
		lea	(v_pal_dry_dup).w,a1
		move.b	(v_pfade_start).w,d0
		adda.w	d0,a0
		adda.w	d0,a1
		move.b	(v_pfade_size).w,d0

	@addcolour:
		bsr.s	FadeIn_AddColour ; increase colour
		dbf	d0,@addcolour	; repeat for size of palette

		tst.b	(f_water).w	; is level Labyrinth?
		beq.s	@exit		; if not, branch

		moveq	#0,d0
		lea	(v_pal_water).w,a0
		lea	(v_pal_water_dup).w,a1
		move.b	(v_pfade_start).w,d0
		adda.w	d0,a0
		adda.w	d0,a1
		move.b	(v_pfade_size).w,d0

	@addcolour2:
		bsr.s	FadeIn_AddColour ; increase colour again
		dbf	d0,@addcolour2 ; repeat

@exit:
		rts
; End of function FadeIn_FromBlack


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


FadeIn_AddColour:
@addblue:
		move.w	(a1)+,d2
		move.w	(a0),d3
		cmp.w	d2,d3		; is colour already at threshold level?
		beq.s	@next		; if yes, branch
		move.w	d3,d1
		addi.w	#$200,d1	; increase blue	value
		cmp.w	d2,d1		; has blue reached threshold level?
		bhi.s	@addgreen	; if yes, branch
		move.w	d1,(a0)+	; update palette
		rts
; ===========================================================================

@addgreen:
		move.w	d3,d1
		addi.w	#$20,d1		; increase green value
		cmp.w	d2,d1
		bhi.s	@addred
		move.w	d1,(a0)+	; update palette
		rts
; ===========================================================================

@addred:
		addq.w	#2,(a0)+	; increase red value
		rts
; ===========================================================================

@next:
		addq.w	#2,a0		; next colour
		rts
; End of function FadeIn_AddColour


; ---------------------------------------------------------------------------
; Subroutine to fade out to black
; ---------------------------------------------------------------------------


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PaletteFadeOut:
		move.w	#$003F,(v_pfade_start).w ; start position = 0; size = $40
		moveq	#$15,d4

	@mainloop:
		move.b	#$12,(v_vbla_routine).w
		bsr.w	WaitForVBla
		bsr.s	FadeOut_ToBlack
		bsr.w	RunPLC
		dbf	d4,@mainloop
		rts
; End of function PaletteFadeOut


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


FadeOut_ToBlack:
		moveq	#0,d0
		lea	(v_pal_dry).w,a0
		move.b	(v_pfade_start).w,d0
		adda.w	d0,a0
		move.b	(v_pfade_size).w,d0

	@decolour:
		bsr.s	FadeOut_DecColour ; decrease colour
		dbf	d0,@decolour	; repeat for size of palette

		moveq	#0,d0
		lea	(v_pal_water).w,a0
		move.b	(v_pfade_start).w,d0
		adda.w	d0,a0
		move.b	(v_pfade_size).w,d0

	@decolour2:
		bsr.s	FadeOut_DecColour
		dbf	d0,@decolour2
		rts
; End of function FadeOut_ToBlack


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


FadeOut_DecColour:
@dered:
		move.w	(a0),d2
		beq.s	@next
		move.w	d2,d1
		andi.w	#$E,d1
		beq.s	@degreen
		subq.w	#2,(a0)+	; decrease red value
		rts
; ===========================================================================

@degreen:
		move.w	d2,d1
		andi.w	#$E0,d1
		beq.s	@deblue
		subi.w	#$20,(a0)+	; decrease green value
		rts
; ===========================================================================

@deblue:
		move.w	d2,d1
		andi.w	#$E00,d1
		beq.s	@next
		subi.w	#$200,(a0)+	; decrease blue	value
		rts
; ===========================================================================

@next:
		addq.w	#2,a0
		rts
; End of function FadeOut_DecColour

; ---------------------------------------------------------------------------
; Subroutine to	fade in from white (Special Stage)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PaletteWhiteIn:
		move.w	#$003F,(v_pfade_start).w ; start position = 0; size = $40
		moveq	#0,d0
		lea	(v_pal_dry).w,a0
		move.b	(v_pfade_start).w,d0
		adda.w	d0,a0
		move.w	#cWhite,d1
		move.b	(v_pfade_size).w,d0

	@fill:
		move.w	d1,(a0)+
		dbf	d0,@fill 	; fill palette with white

		moveq	#$15,d4

	@mainloop:
		move.b	#$12,(v_vbla_routine).w
		bsr.w	WaitForVBla
		bsr.s	WhiteIn_FromWhite
		bsr.w	RunPLC
		dbf	d4,@mainloop
		rts
; End of function PaletteWhiteIn


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


WhiteIn_FromWhite:
		moveq	#0,d0
		lea	(v_pal_dry).w,a0
		lea	(v_pal_dry_dup).w,a1
		move.b	(v_pfade_start).w,d0
		adda.w	d0,a0
		adda.w	d0,a1
		move.b	(v_pfade_size).w,d0

	@decolour:
		bsr.s	WhiteIn_DecColour ; decrease colour
		dbf	d0,@decolour	; repeat for size of palette

		tst.b	(f_water).w	; is level Labyrinth?
		beq.s	@exit		; if not, branch
		moveq	#0,d0
		lea	(v_pal_water).w,a0
		lea	(v_pal_water_dup).w,a1
		move.b	(v_pfade_start).w,d0
		adda.w	d0,a0
		adda.w	d0,a1
		move.b	(v_pfade_size).w,d0

	@decolour2:
		bsr.s	WhiteIn_DecColour
		dbf	d0,@decolour2

	@exit:
		rts
; End of function WhiteIn_FromWhite


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


WhiteIn_DecColour:
@deblue:
		move.w	(a1)+,d2
		move.w	(a0),d3
		cmp.w	d2,d3
		beq.s	@next
		move.w	d3,d1
		subi.w	#$200,d1	; decrease blue	value
		blo.s	@degreen
		cmp.w	d2,d1
		blo.s	@degreen
		move.w	d1,(a0)+
		rts
; ===========================================================================

@degreen:
		move.w	d3,d1
		subi.w	#$20,d1		; decrease green value
		blo.s	@dered
		cmp.w	d2,d1
		blo.s	@dered
		move.w	d1,(a0)+
		rts
; ===========================================================================

@dered:
		subq.w	#2,(a0)+	; decrease red value
		rts
; ===========================================================================

@next:
		addq.w	#2,a0
		rts
; End of function WhiteIn_DecColour

; ---------------------------------------------------------------------------
; Subroutine to fade to white (Special Stage)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PaletteWhiteOut:
		move.w	#$003F,(v_pfade_start).w ; start position = 0; size = $40
		moveq	#$15,d4

	@mainloop:
		move.b	#$12,(v_vbla_routine).w
		bsr.w	WaitForVBla
		bsr.s	WhiteOut_ToWhite
		bsr.w	RunPLC
		dbf	d4,@mainloop
		rts
; End of function PaletteWhiteOut


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


WhiteOut_ToWhite:
		moveq	#0,d0
		lea	(v_pal_dry).w,a0
		move.b	(v_pfade_start).w,d0
		adda.w	d0,a0
		move.b	(v_pfade_size).w,d0

	@addcolour:
		bsr.s	WhiteOut_AddColour
		dbf	d0,@addcolour

		moveq	#0,d0
		lea	(v_pal_water).w,a0
		move.b	(v_pfade_start).w,d0
		adda.w	d0,a0
		move.b	(v_pfade_size).w,d0

	@addcolour2:
		bsr.s	WhiteOut_AddColour
		dbf	d0,@addcolour2
		rts
; End of function WhiteOut_ToWhite


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


WhiteOut_AddColour:
@addred:
		move.w	(a0),d2
		cmpi.w	#cWhite,d2
		beq.s	@next
		move.w	d2,d1
		andi.w	#$E,d1
		cmpi.w	#cRed,d1
		beq.s	@addgreen
		addq.w	#2,(a0)+	; increase red value
		rts
; ===========================================================================

@addgreen:
		move.w	d2,d1
		andi.w	#$E0,d1
		cmpi.w	#cGreen,d1
		beq.s	@addblue
		addi.w	#$20,(a0)+	; increase green value
		rts
; ===========================================================================

@addblue:
		move.w	d2,d1
		andi.w	#$E00,d1
		cmpi.w	#cBlue,d1
		beq.s	@next
		addi.w	#$200,(a0)+	; increase blue	value
		rts
; ===========================================================================

@next:
		addq.w	#2,a0
		rts
; End of function WhiteOut_AddColour

; ---------------------------------------------------------------------------
; Palette cycling routine - Sega logo
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalCycle_Sega:
		tst.b	(v_pcyc_time+1).w
		bne.s	loc_206A
		lea	(v_pal_dry+$20).w,a1
		lea	Pal_Sega1(pc),a0
		moveq	#5,d1
		move.w	(v_pcyc_num).w,d0

loc_2020:
		bpl.s	loc_202A
		addq.w	#2,a0
		subq.w	#1,d1
		addq.w	#2,d0
		bra.s	loc_2020
; ===========================================================================

loc_202A:
		move.w	d0,d2
		andi.w	#$1E,d2
		bne.s	loc_2034
		addq.w	#2,d0

loc_2034:
		cmpi.w	#$60,d0
		bhs.s	loc_203E
		move.w	(a0)+,(a1,d0.w)

loc_203E:
		addq.w	#2,d0
		dbf	d1,loc_202A

		move.w	(v_pcyc_num).w,d0
		addq.w	#2,d0
		move.w	d0,d2
		andi.w	#$1E,d2
		bne.s	loc_2054
		addq.w	#2,d0

loc_2054:
		cmpi.w	#$64,d0
		blt.s	loc_2062
		move.w	#$401,(v_pcyc_time).w
		moveq	#-$C,d0

loc_2062:
		move.w	d0,(v_pcyc_num).w
		moveq	#1,d0
		rts
; ===========================================================================

loc_206A:
		subq.b	#1,(v_pcyc_time).w
		bpl.s	loc_20BC
		move.b	#4,(v_pcyc_time).w
		move.w	(v_pcyc_num).w,d0
		addi.w	#$C,d0
		cmpi.w	#$30,d0
		blo.s	loc_2088
		moveq	#0,d0
		rts
; ===========================================================================

loc_2088:
		move.w	d0,(v_pcyc_num).w
		lea	Pal_Sega2(pc),a0
		lea	(a0,d0.w),a0
		lea	(v_pal_dry+$04).w,a1
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.w	(a0)+,(a1)
		lea	(v_pal_dry+$20).w,a1
		moveq	#0,d0
		moveq	#$2C,d1

loc_20A8:
		move.w	d0,d2
		andi.w	#$1E,d2
		bne.s	loc_20B2
		addq.w	#2,d0

loc_20B2:
		move.w	(a0),(a1,d0.w)
		addq.w	#2,d0
		dbf	d1,loc_20A8

loc_20BC:
		moveq	#1,d0
		rts
; End of function PalCycle_Sega

; ===========================================================================

Pal_Sega1:	incbin	"palette\Sega1.bin"
Pal_Sega2:	incbin	"palette\Sega2.bin"

; ---------------------------------------------------------------------------
; Subroutines to load palettes

; input:
;	d0 = index number for palette
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalLoad1:
		lea	PalPointers(pc),a1
		lsl.w	#3,d0
		adda.w	d0,a1
		movea.l	(a1)+,a2	; get palette data address
		movea.w	(a1)+,a3	; get target RAM address
		adda.w	#v_pal_dry_dup-v_pal_dry,a3		; skip to "main" RAM address
		move.w	(a1)+,d7	; get length of palette data

	@loop:
		move.l	(a2)+,(a3)+	; move data to RAM
		dbf	d7,@loop
		rts
; End of function PalLoad1


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalLoad2:
		lea	PalPointers(pc),a1
		lsl.w	#3,d0
		adda.w	d0,a1
		movea.l	(a1)+,a2	; get palette data address
		movea.w	(a1)+,a3	; get target RAM address
		move.w	(a1)+,d7	; get length of palette

	@loop:
		move.l	(a2)+,(a3)+	; move data to RAM
		dbf	d7,@loop
		rts
; End of function PalLoad2

; ---------------------------------------------------------------------------
; Underwater palette loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalLoad3_Water:
		lea	PalPointers(pc),a1
		lsl.w	#3,d0
		adda.w	d0,a1
		movea.l	(a1)+,a2	; get palette data address
		movea.w	(a1)+,a3	; get target RAM address
		suba.w	#v_pal_dry-v_pal_water,a3		; skip to "main" RAM address
		move.w	(a1)+,d7	; get length of palette data

	@loop:
		move.l	(a2)+,(a3)+	; move data to RAM
		dbf	d7,@loop
		rts
; End of function PalLoad3_Water


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalLoad4_Water:
		lea	PalPointers(pc),a1
		lsl.w	#3,d0
		adda.w	d0,a1
		movea.l	(a1)+,a2	; get palette data address
		movea.w	(a1)+,a3	; get target RAM address
		suba.w	#v_pal_dry-v_pal_water_dup,a3
		move.w	(a1)+,d7	; get length of palette data

	@loop:
		move.l	(a2)+,(a3)+	; move data to RAM
		dbf	d7,@loop
		rts
; End of function PalLoad4_Water

; ===========================================================================

		include	"_inc\Palette Pointers.asm"

; ---------------------------------------------------------------------------
; Palette data
; ---------------------------------------------------------------------------
Pal_SegaBG:	incbin	"palette\Sega Background.bin"
Pal_Title:	incbin	"palette\Title Screen.bin"
Pal_LevelSel:	incbin	"palette\Level Select.bin"
Pal_Sonic:	incbin	"palette\Sonic.bin"
Pal_GHZ:	incbin	"palette\Green Hill Zone.bin"

; ---------------------------------------------------------------------------
; Subroutine to	wait for VBlank routines to complete
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


WaitForVBla:
		enable_ints

	@wait:
		tst.b	(v_vbla_routine).w ; has VBlank routine finished?
		bne.s	@wait		; if not, branch
		rts
; End of function WaitForVBla

		include	"_incObj\sub RandomNumber.asm"
		include	"_incObj\sub CalcSine.asm"
		include	"_incObj\sub CalcAngle.asm"

; ---------------------------------------------------------------------------
; Sega screen
; ---------------------------------------------------------------------------

GM_Sega:
		move.b	#bgm_Stop,d0
		bsr.w	PlaySound_Special ; stop music
		bsr.w	ClearPLC
		bsr.w	PaletteFadeOut
		lea	(vdp_control_port).l,a6
		move.w	#$8004,(a6)	; use 8-colour mode
		move.w	#$8200+(vram_fg>>10),(a6) ; set foreground nametable address
		move.w	#$8400+(vram_bg>>13),(a6) ; set background nametable address
		move.w	#$8700,(a6)	; set background colour (palette entry 0)
		move.w	#$8B00,(a6)	; full-screen vertical scrolling
		clr.b	(f_wtr_state).w
		disable_ints
		move.w	(v_vdp_buffer1).w,d0
		andi.b	#$BF,d0
		move.w	d0,(vdp_control_port).l
		bsr.w	ClearScreen
		locVRAM	0
		lea	(Nem_SegaLogo).l,a0 ; load Sega	logo patterns
		bsr.w	NemDec
		lea	($FF0000).l,a1
		lea	(Eni_SegaLogo).l,a0 ; load Sega	logo mappings
		moveq	#0,d0
		bsr.w	EniDec

		copyTilemap	$FF0000,$E510,$17,7
		copyTilemap	$FF0180,$C000,$27,$1B

		tst.b   (v_megadrive).w	; is console Japanese?
		bmi.s   @loadpal
		copyTilemap	$FF0A40,$C53A,2,1 ; hide "TM" with a white rectangle

	@loadpal:
		moveq	#palid_SegaBG,d0
		bsr.w	PalLoad2	; load Sega logo palette
		move.w	#-$A,(v_pcyc_num).w
		moveq   #0,d0
		move.w	d0,(v_pcyc_time).w
		move.w	d0,(v_pal_buffer+$10).w
		move.w	(v_vdp_buffer1).w,d0
		ori.b	#$40,d0
		move.w	d0,(vdp_control_port).l

Sega_WaitPal:
		move.b	#2,(v_vbla_routine).w
		bsr.w	WaitForVBla
		bsr.w	PalCycle_Sega
		bne.s	Sega_WaitPal

		move.b	#sfx_Sega,d0
		bsr.w	PlaySound_Special	; play "SEGA" sound
		move.b	#$14,(v_vbla_routine).w
		bsr.w	WaitForVBla
		move.w	#$1E,(v_demolength).w

Sega_WaitEnd:
		move.b	#2,(v_vbla_routine).w
		bsr.w	WaitForVBla
		tst.w	(v_demolength).w
		beq.s	Sega_GotoTitle
		bra.s   Sega_WaitEnd

Sega_GotoTitle:
		move.b	#id_Title,(v_gamemode).w ; go to title screen
		rts
; ===========================================================================

; ---------------------------------------------------------------------------
; Title	screen
; ---------------------------------------------------------------------------

GM_Title:
		move.b	#bgm_Stop,d0
		bsr.w	PlaySound_Special ; stop music
		bsr.w	ClearPLC
		bsr.w	PaletteFadeOut
		disable_ints
		bsr.w	SoundDriverLoad
		lea	(vdp_control_port).l,a6
		move.w	#$8004,(a6)	; 8-colour mode
		move.w	#$8200+(vram_fg>>10),(a6) ; set foreground nametable address
		move.w	#$8400+(vram_bg>>13),(a6) ; set background nametable address
		move.w	#$9001,(a6)	; 64-cell hscroll size
		move.w	#$9200,(a6)	; window vertical position
		move.w	#$8B03,(a6)
		move.w	#$8720,(a6)	; set background colour (palette line 2, entry 0)
		clr.b	(f_wtr_state).w
		bsr.w	ClearScreen

		lea	(v_objspace).w,a1
		moveq	#0,d0
		move.w	#$7FF,d1

	Tit_ClrObj1:
		move.l	d0,(a1)+
		dbf	d1,Tit_ClrObj1	; fill object space ($D000-$EFFF) with 0

		lea	(v_pal_dry_dup).w,a1
		moveq	#cBlack,d0
		moveq	#$1F,d1

	Tit_ClrPal:
		move.l	d0,(a1)+
		dbf	d1,Tit_ClrPal	; fill palette with 0 (black)

		disable_ints
		locVRAM	$4000
		lea	(Nem_TitleFg).l,a0 ; load title	screen patterns
		bsr.w	NemDec
		locVRAM	$6000
		lea	(Nem_TitleSonic).l,a0 ;	load Sonic title screen	patterns
		bsr.w	NemDec
		locVRAM	$A200
		lea	(Nem_TitleTM).l,a0 ; load "TM" patterns
		bsr.w	NemDec
		lea	(vdp_data_port).l,a6
		locVRAM	$D000,4(a6)
		lea	(Art_Text).l,a5	; load level select font
		move.w	#$28F,d1

	Tit_LoadText:
		move.w	(a5)+,(a6)
		dbf	d1,Tit_LoadText	; load level select font

		moveq   #0,d0
                move.b	d0,(v_lastlamp).w ; clear lamppost counter
		move.w	d0,(v_debuguse).w ; disable debug item placement mode
		move.w	d0,(f_nobgscroll).w ; clear nobgscroll variable
		move.w	d0,(v_zone).w	; set level to GHZ (00)
		move.w	d0,(v_pcyc_time).w ; disable palette cycling
		bsr.w	LevelSizeLoad
		bsr.w	DeformLayers
		lea	(Blk16_GHZ).l,a0 ; load	GHZ 16x16 mappings
		lea	(v_16x16).w,a1
		moveq	#0,d0
		bsr.w	EniDec
		lea	(Blk256_GHZ).l,a0 ; load GHZ 256x256 mappings
		lea	(v_256x256).l,a1
		bsr.w	KosDec
		bsr.w	LevelLayoutLoad
		bsr.w	PaletteFadeOut
		disable_ints
		bsr.w	ClearScreen
		lea	(vdp_control_port).l,a5
		lea	(vdp_data_port).l,a6
		lea	(v_bgscreenposx).w,a3
		lea	(v_lvllayout+$40).w,a4
		move.w	#$6000,d2
		bsr.w	DrawChunks
		lea	($FF0000).l,a1
		lea	(Eni_Title).l,a0 ; load	title screen mappings
		moveq	#0,d0
		bsr.w	EniDec

		copyTilemap	$FF0000,$C208,$21,$15

		locVRAM	0
		lea	(Nem_GHZ_1st).l,a0 ; load GHZ patterns
		bsr.w	NemDec
		moveq	#palid_Title,d0	; load title screen palette
		bsr.w	PalLoad1
		move.b	#bgm_Title,d0
		bsr.w	PlaySound_Special	; play title screen music
		clr.b	(f_debugmode).w ; disable debug mode
		move.w	#$178,(v_demolength).w ; run title screen for $178 frames

		move.b	#id_TitleSonic,(v_objspace+$40).w ; load big Sonic object
		move.b	#id_PSBTM,(v_objspace+$80).w ; load "PRESS START BUTTON" object

		tst.b   (v_megadrive).w	; is console Japanese?
		bpl.s   @isjap		; if yes, branch

		move.b	#id_PSBTM,(v_objspace+$C0).w ; load "TM" object
		move.b	#3,(v_objspace+$C0+obFrame).w
	@isjap:
		move.b	#id_PSBTM,(v_objspace+$100).w ; load object which hides part of Sonic
		move.b	#2,(v_objspace+$100+obFrame).w
		jsr	ExecuteObjects(pc)
		bsr.w	DeformLayers
		jsr	BuildSprites(pc)
		moveq	#plcid_Main,d0
		bsr.w	NewPLC
		moveq   #0,d0
		move.w	d0,(v_title_dcount).w
		move.w	d0,(v_title_ccount).w
		move.w	(v_vdp_buffer1).w,d0
		ori.b	#$40,d0
		move.w	d0,(vdp_control_port).l
		bsr.w	PaletteFadeIn

Tit_MainLoop:
		move.b	#4,(v_vbla_routine).w
		bsr.w	WaitForVBla
		jsr	ExecuteObjects(pc)
		bsr.w	DeformLayers
		jsr	BuildSprites(pc)
		bsr.w	PCycle_Title
		bsr.w	RunPLC
		addq.w	#2,(v_objspace+obX).w ; move Sonic to the right
		cmpi.w	#$1C00,(v_objspace+obX).w	; has Sonic object passed $1C00 on x-axis?
		blo.s	Tit_ChkRegion	; if not, branch

		move.b	#id_Sega,(v_gamemode).w ; go to Sega screen
		rts
; ===========================================================================

Tit_ChkRegion:
		tst.b	(v_megadrive).w	; check	if the machine is US or	Japanese
		bpl.s	Tit_RegionJap	; if Japanese, branch

		lea	LevSelCode_US(pc),a0 ; load US code
		bra.s	Tit_EnterCheat

	Tit_RegionJap:
		lea	LevSelCode_J(pc),a0 ; load J code

Tit_EnterCheat:
		move.w	(v_title_dcount).w,d0
		adda.w	d0,a0
		move.b	(v_jpadpress1).w,d0 ; get button press
		andi.b	#btnDir,d0	; read only UDLR buttons
		cmp.b	(a0),d0		; does button press match the cheat code?
		bne.s	Tit_ResetCheat	; if not, branch
		addq.w	#1,(v_title_dcount).w ; next button press
		tst.b	d0
		bne.s	Tit_CountC
		lea	(f_levselcheat).w,a0
		move.w	(v_title_ccount).w,d1
		lsr.w	#1,d1
		andi.w	#3,d1
		beq.s	Tit_PlayRing
		tst.b	(v_megadrive).w
		bpl.s	Tit_PlayRing
		moveq	#1,d1
		move.b	d1,1(a0,d1.w)	; cheat depends on how many times C is pressed

	Tit_PlayRing:
		move.b	#1,(a0,d1.w)	; activate cheat
		move.b	#sfx_Ring,d0
		bsr.w	PlaySound_Special	; play ring sound when code is entered
		bra.s	Tit_CountC
; ===========================================================================

Tit_ResetCheat:
		tst.b	d0
		beq.s	Tit_CountC
		cmpi.w	#9,(v_title_dcount).w
		beq.s	Tit_CountC
		move.w	#0,(v_title_dcount).w ; reset UDLR counter

Tit_CountC:
		move.b	(v_jpadpress1).w,d0
		andi.b	#btnC,d0	; is C button pressed?
		beq.s	loc_3230	; if not, branch
		addq.w	#1,(v_title_ccount).w ; increment C counter

loc_3230:
		btst	#7,(v_jpadhold1).w ; check if Start is pressed
		beq.w	Tit_MainLoop	; if not, branch

Tit_ChkLevSel:
		tst.b	(f_levselcheat).w ; check if level select code is on
		beq.w	PlayLevel	; if not, play level
		btst	#bitA,(v_jpadhold1).w ; check if A is pressed
		beq.w	PlayLevel	; if not, play level

		moveq	#palid_LevelSel,d0
		bsr.w	PalLoad2	; load level select palette
		lea	(v_hscrolltablebuffer).w,a1
		moveq	#0,d0
		move.w	#$DF,d1

	Tit_ClrScroll1:
		move.l	d0,(a1)+
		dbf	d1,Tit_ClrScroll1 ; clear scroll data (in RAM)

		move.l	d0,(v_scrposy_dup).w
		disable_ints
		lea	(vdp_data_port).l,a6
		locVRAM	$E000
		move.w	#$3FF,d1

	Tit_ClrScroll2:
		move.l	d0,(a6)
		dbf	d1,Tit_ClrScroll2 ; clear scroll data (in VRAM)

		bsr.w	LevSelTextLoad

; ---------------------------------------------------------------------------
; Level	Select
; ---------------------------------------------------------------------------

LevelSelect:
		move.b	#4,(v_vbla_routine).w
		bsr.w	WaitForVBla
		bsr.w	LevSelControls
		bsr.w	RunPLC
		tst.l	(v_plc_buffer).w
		bne.s	LevelSelect
		andi.b	#btnABC+btnStart,(v_jpadpress1).w ; is A, B, C, or Start pressed?
		beq.s	LevelSelect	; if not, branch
		move.w	(v_levselitem).w,d0
		cmpi.w	#3,d0		; have you selected item 3 (sound test)?
		bne.s	LevSel_Level	; if not, go to	Level subroutine
		move.w	(v_levselsound).w,d0

LevSel_PlaySnd:
		bsr.w	PlaySound_Special
		bra.s	LevelSelect
; ===========================================================================

LevSel_Level:
		andi.w	#$3FFF,d0
		move.w	d0,(v_zone).w	; set level number

PlayLevel:
		move.b	#id_Level,(v_gamemode).w ; set screen mode to $0C (level)
		move.b	#3,(v_lives).w	; set lives to 3
		moveq	#0,d0
		move.w	d0,(v_rings).w	; clear rings
		move.l	d0,(v_time).w	; clear time
		move.l	d0,(v_score).w	; clear score
		move.b	d0,(v_lastspecial).w ; clear special stage number
		move.b	d0,(v_emeralds).w ; clear emeralds
		move.l	d0,(v_emldlist).w ; clear emeralds
		move.l	d0,(v_emldlist+4).w ; clear emeralds
		move.l	#5000,(v_scorelife).w ; extra life is awarded at 50000 points
		move.b	#bgm_Fade,d0
		bra.w	PlaySound_Special ; fade out music
; ===========================================================================
; ---------------------------------------------------------------------------
; Level	select - level pointers
; ---------------------------------------------------------------------------
LevSel_Ptrs:
		; default level order
		dc.b id_GHZ, 0
		dc.b id_GHZ, 1
		dc.b id_GHZ, 2
		dc.w $8000		; Sound Test
		even
; ---------------------------------------------------------------------------
; Level	select codes
; ---------------------------------------------------------------------------
LevSelCode_J:   dc.b btnUp,btnDn,btnDn,btnDn,btnL,btnR,0,$FF
		even

LevSelCode_US:	dc.b btnUp,btnDn,btnL,btnR,0,$FF
		even
; ===========================================================================

; ---------------------------------------------------------------------------
; Subroutine to	change what you're selecting in the level select
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LevSelControls:
		move.b	(v_jpadpress1).w,d1
		andi.b	#btnUp+btnDn,d1	; is up/down pressed and held?
		bne.s	LevSel_UpDown	; if yes, branch
		subq.w	#1,(v_levseldelay).w ; subtract 1 from time to next move
		bpl.s	LevSel_SndTest	; if time remains, branch

LevSel_UpDown:
		move.w	#$B,(v_levseldelay).w ; reset time delay
		move.b	(v_jpadhold1).w,d1
		andi.b	#btnUp+btnDn,d1	; is up/down pressed?
		beq.s	LevSel_SndTest	; if not, branch
		move.w	(v_levselitem).w,d0
		btst	#bitUp,d1	; is up	pressed?
		beq.s	LevSel_Down	; if not, branch
		subq.w	#1,d0		; move up 1 selection
		bhs.s	LevSel_Down
		moveq	#3,d0		; if selection moves below 0, jump to selection	3

LevSel_Down:
		btst	#bitDn,d1	; is down pressed?
		beq.s	LevSel_Refresh	; if not, branch
		addq.w	#1,d0		; move down 1 selection
		cmpi.w	#4,d0
		blo.s	LevSel_Refresh
		moveq	#0,d0		; if selection moves above 3,	jump to	selection 0

LevSel_Refresh:
		move.w	d0,(v_levselitem).w ; set new selection
		bra.s	LevSelTextLoad	; refresh text

LevSel_NoMove:
		rts
; ===========================================================================

LevSel_SndTest:
		cmpi.w	#3,(v_levselitem).w ; is item 3 selected?
		bne.s	LevSel_NoMove	; if not, branch
		move.b	(v_jpadpress1).w,d1
		andi.b	#btnR+btnL,d1	; is left/right	pressed?
		beq.s	LevSel_NoMove	; if not, branch
		move.w	(v_levselsound).w,d0
		btst	#bitL,d1	; is left pressed?
		beq.s	LevSel_Right	; if not, branch
		subq.w	#1,d0		; subtract 1 from sound	test

LevSel_Right:
		btst	#bitR,d1	; is right pressed?
		beq.s	LevSel_Refresh2	; if not, branch
		addq.w	#1,d0		; add 1	to sound test

LevSel_Refresh2:
		move.w	d0,(v_levselsound).w ; set sound test number
; End of function LevSelControls

; ---------------------------------------------------------------------------
; Subroutine to load level select text
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LevSelTextLoad:

	textpos:	= ($40000000+(($E590&$3FFF)<<16)+(($E590&$C000)>>14))
					; $E210 is a VRAM address

		lea	LevelMenuText(pc),a1
		lea	(vdp_data_port).l,a6
		move.l	#textpos,d4	; text position on screen
		move.w	#$E680,d3	; VRAM setting (4th palette, $680th tile)
		moveq	#3,d1		; number of lines of text

	LevSel_DrawAll:
		move.l	d4,4(a6)
		bsr.s	LevSel_ChgLine	; draw line of text
		addi.l	#$800000,d4	; jump to next line
		dbf	d1,LevSel_DrawAll

		moveq	#0,d0
		move.w	(v_levselitem).w,d0
		move.w	d0,d1
		move.l	#textpos,d4
		lsl.w	#7,d0
		swap	d0
		add.l	d0,d4
		lea	LevelMenuText(pc),a1
		lsl.w	#3,d1
		move.w	d1,d0
		add.w	d1,d1
		add.w	d0,d1
		adda.w	d1,a1
		move.w	#$C680,d3	; VRAM setting (3rd palette, $680th tile)
		move.l	d4,4(a6)
		bsr.s	LevSel_ChgLine	; recolour selected line
		move.w	#$E680,d3
		cmpi.w	#3,(v_levselitem).w
		bne.s	LevSel_DrawSnd
		move.w	#$C680,d3

LevSel_DrawSnd:
		locVRAM	$E72A		; sound test position on screen
		move.w	(v_levselsound).w,d0
		move.b	d0,d2
		lsr.b	#4,d0
		bsr.s	LevSel_ChgSnd	; draw 1st digit
		move.b	d2,d0
; End of function LevSelTextLoad


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LevSel_ChgSnd:
		andi.w	#$F,d0
		cmpi.b	#$A,d0		; is digit $A-$F?
		blo.s	LevSel_Numb	; if not, branch
		addi.b	#7,d0		; use alpha characters

	LevSel_Numb:
		add.w	d3,d0
		move.w	d0,(a6)
		rts
; End of function LevSel_ChgSnd


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LevSel_ChgLine:
		moveq	#$17,d2		; number of characters per line

	LevSel_LineLoop:
		moveq	#0,d0
		move.b	(a1)+,d0	; get character
		bpl.s	LevSel_CharOk	; branch if valid
		move.w	#0,(a6)		; use blank character
		dbf	d2,LevSel_LineLoop
		rts


	LevSel_CharOk:
		add.w	d3,d0		; combine char with VRAM setting
		move.w	d0,(a6)		; send to VRAM
		dbf	d2,LevSel_LineLoop
		rts
; End of function LevSel_ChgLine

; ===========================================================================
; ---------------------------------------------------------------------------
; Level	select menu text
; ---------------------------------------------------------------------------
LevelMenuText:	incbin	"misc\Level Select Text.bin"
		even
; ---------------------------------------------------------------------------
; Music	playlist
; ---------------------------------------------------------------------------
MusicList:
		dc.b bgm_GHZ	; GHZ
		even
; ===========================================================================

; ---------------------------------------------------------------------------
; Level
; ---------------------------------------------------------------------------

GM_Level:
		bset	#7,(v_gamemode).w ; add $80 to screen mode (for pre level sequence)
		move.b	#bgm_Fade,d0
		bsr.w	PlaySound_Special ; fade out music
		bsr.w	ClearPLC
		bsr.w	PaletteFadeOut
		disable_ints
		locVRAM	$B000
		lea	(Nem_TitleCard).l,a0 ; load title card patterns
		bsr.w	NemDec
		enable_ints
		moveq	#0,d0
		move.b	(v_zone).w,d0
		lsl.w	#4,d0
		lea	(LevelHeaders).l,a2
		lea	(a2,d0.w),a2
		moveq	#0,d0
		move.b	(a2),d0
		beq.s	loc_37FC
		bsr.w	AddPLC		; load level patterns

loc_37FC:
		moveq	#plcid_Main2,d0
		bsr.w	AddPLC		; load standard	patterns

Level_ClrRam:
		lea	(v_objspace).w,a1
		moveq	#0,d0
		move.w	#$7FF,d1

	Level_ClrObjRam:
		move.l	d0,(a1)+
		dbf	d1,Level_ClrObjRam ; clear object RAM

		lea	($FFFFF628).w,a1
		moveq	#0,d0
		moveq	#$15,d1

	Level_ClrVars1:
		move.l	d0,(a1)+
		dbf	d1,Level_ClrVars1 ; clear misc variables

		lea	(v_screenposx).w,a1
		moveq	#0,d0
		moveq	#$3F,d1

	Level_ClrVars2:
		move.l	d0,(a1)+
		dbf	d1,Level_ClrVars2 ; clear misc variables

		lea	(v_oscillate+2).w,a1
		moveq	#0,d0
		moveq	#$47,d1

	Level_ClrVars3:
		move.l	d0,(a1)+
		dbf	d1,Level_ClrVars3 ; clear object variables

		disable_ints
		bsr.w	ClearScreen
		lea	(vdp_control_port).l,a6
		move.w	#$8B03,(a6)	; line scroll mode
		move.w	#$8200+(vram_fg>>10),(a6) ; set foreground nametable address
		move.w	#$8400+(vram_bg>>13),(a6) ; set background nametable address
		move.w	#$8500+(vram_sprites>>9),(a6) ; set sprite table address
		move.w	#$9001,(a6)		; 64-cell hscroll size
		move.w	#$8004,(a6)		; 8-colour mode
		move.w	#$8720,(a6)		; set background colour (line 3; colour 0)
		move.w	#$8A00+223,(v_hbla_hreg).w ; set palette change position (for water)
		move.w	(v_hbla_hreg).w,(a6)

Level_LoadPal:
		move.w	#30,(v_air).w
		enable_ints
		moveq	#palid_Sonic,d0
		bsr.w	PalLoad2	; load Sonic's palette

Level_GetBgm:
		moveq	#0,d0
		move.b	(v_zone).w,d0
		lea	MusicList(pc),a1 ; load	music playlist
		move.b	(a1,d0.w),d0
		bsr.w	PlaySound	; play music
		move.b	#id_TitleCard,(v_objspace+$80).w ; load title card object

Level_TtlCardLoop:
		move.b	#$C,(v_vbla_routine).w
		bsr.w	WaitForVBla
		jsr	ExecuteObjects(pc)
		jsr	BuildSprites(pc)
		bsr.w	RunPLC
		move.w	(v_objspace+$108).w,d0
		cmp.w	(v_objspace+$130).w,d0 ; has title card sequence finished?
		bne.s	Level_TtlCardLoop ; if not, branch
		tst.l	(v_plc_buffer).w ; are there any items in the pattern load cue?
		bne.s	Level_TtlCardLoop ; if yes, branch
		jsr	(Hud_Base).l	; load basic HUD gfx

	Level_SkipTtlCard:
		moveq	#palid_Sonic,d0
		bsr.w	PalLoad1	; load Sonic's palette
		bsr.w	LevelSizeLoad
		bsr.w	DeformLayers
		bset	#2,(v_fg_scroll_flags).w
		bsr.w	LevelDataLoad ; load block mappings and palettes
		bsr.w	LoadTilesFromStart
		bsr.w	ColIndexLoad
		move.b	#id_SonicPlayer,(v_player).w ; load Sonic object
		move.b	#id_HUD,(v_objspace+$40).w ; load HUD object
		tst.b	(f_debugcheat).w ; has debug cheat been entered?
		beq.s	Level_ChkWater	; if not, branch
		btst	#bitA,(v_jpadhold1).w ; is A button held?
		beq.s	Level_ChkWater	; if not, branch
		move.b	#1,(f_debugmode).w ; enable debug mode

Level_ChkWater:
		moveq   #0,d0
                move.w	d0,(v_jpadhold2).w
		move.w	d0,(v_jpadhold1).w

Level_LoadObj:
		jsr	ObjPosLoad(pc)
		jsr	ExecuteObjects(pc)
		jsr	BuildSprites(pc)
		moveq	#0,d0
		tst.b	(v_lastlamp).w	; are you starting from	a lamppost?
		bne.s	Level_SkipClr	; if yes, branch
		move.w	d0,(v_rings).w	; clear rings
		move.l	d0,(v_time).w	; clear time
		move.b	d0,(v_lifecount).w ; clear lives counter

	Level_SkipClr:
		move.b	d0,(f_timeover).w
		move.b	d0,(v_shield).w	; clear shield
		move.b	d0,(v_invinc).w	; clear invincibility
		move.b	d0,(v_shoes).w	; clear speed shoes
		move.b	d0,($FFFFFE2F).w
		move.w	d0,(v_debuguse).w
		move.w	d0,(f_restart).w
		move.w	d0,(v_framecount).w
		bsr.w	OscillateNumInit
		moveq   #1,d0
		move.b	d0,(f_scorecount).w ; update score counter
		move.b	d0,(f_ringcount).w ; update rings counter
		move.b	d0,(f_timecount).w ; update time counter
		move.w	#0,(v_btnpushtime1).w

Level_ChkWaterPal:
		moveq	#3,d1

	Level_DelayLoop:
		move.b	#8,(v_vbla_routine).w
		bsr.w	WaitForVBla
		dbf	d1,Level_DelayLoop

		move.w	#$202F,(v_pfade_start).w ; fade in 2nd, 3rd & 4th palette lines
		bsr.w	PalFadeIn_Alt
		addq.b	#2,(v_objspace+$80+obRoutine).w ; make title card move
		addq.b	#4,(v_objspace+$C0+obRoutine).w
		addq.b	#4,(v_objspace+$100+obRoutine).w
		addq.b	#4,(v_objspace+$140+obRoutine).w
		bra.s	Level_StartGame
; ===========================================================================

Level_ClrCardArt:
		moveq	#plcid_Explode,d0
		bsr.w	AddPLC	; load explosion gfx
		moveq	#0,d0
		move.b	(v_zone).w,d0
		addi.w	#plcid_GHZAnimals,d0
		bsr.w	AddPLC	; load animal gfx (level no. + $15)

Level_StartGame:
		bclr	#7,(v_gamemode).w ; subtract $80 from mode to end pre-level stuff

; ---------------------------------------------------------------------------
; Main level loop (when	all title card and loading sequences are finished)
; ---------------------------------------------------------------------------

Level_MainLoop:
		bsr.w	PauseGame
		move.b	#8,(v_vbla_routine).w
		bsr.w	WaitForVBla
		addq.w	#1,(v_framecount).w ; add 1 to level timer
		jsr	ExecuteObjects(pc)
		tst.w   (f_restart).w
		bne.w   GM_Level
		tst.w	(v_debuguse).w	; is debug mode being used?
		bne.s	Level_DoScroll	; if yes, branch
		cmpi.b	#6,(v_player+obRoutine).w ; has Sonic just died?
		bhs.s	Level_SkipScroll ; if yes, branch

	Level_DoScroll:
		bsr.w	DeformLayers

	Level_SkipScroll:
		jsr	BuildSprites(pc)
		jsr	ObjPosLoad(pc)
		bsr.w	PaletteCycle
		bsr.w	RunPLC
		bsr.w	OscillateNumDo
		bsr.w	SynchroAnimate
		bsr.w	SignpostArtLoad

		cmpi.b	#id_Level,(v_gamemode).w
		beq.w	Level_MainLoop	; if mode is $C (level), branch
		rts
; ===========================================================================

; ---------------------------------------------------------------------------
; Collision index pointer loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ColIndexLoad:
		moveq	#0,d0
		move.b	(v_zone).w,d0
		lsl.w	#2,d0
		move.l	ColPointers(pc,d0.w),(v_collindex).w
		rts
; End of function ColIndexLoad

; ===========================================================================
; ---------------------------------------------------------------------------
; Collision index pointers
; ---------------------------------------------------------------------------
ColPointers:	dc.l Col_GHZ

		include	"_inc\Oscillatory Routines.asm"

; ---------------------------------------------------------------------------
; Subroutine to	change synchronised animation variables (rings, giant rings)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SynchroAnimate:

; Used for GHZ spiked log
Sync1:
		subq.b	#1,(v_ani0_time).w ; has timer reached 0?
		bpl.s	Sync2		; if not, branch
		move.b	#$B,(v_ani0_time).w ; reset timer
		subq.b	#1,(v_ani0_frame).w ; next frame
		andi.b	#7,(v_ani0_frame).w ; max frame is 7

; Used for rings and giant rings
Sync2:
		subq.b	#1,(v_ani1_time).w
		bpl.s	Sync3
		move.b	#7,(v_ani1_time).w
		addq.b	#1,(v_ani1_frame).w
		andi.b	#3,(v_ani1_frame).w

; Used for bouncing rings
Sync3:
		tst.b	(v_ani3_time).w
		beq.s	SyncEnd
		moveq	#0,d0
		move.b	(v_ani3_time).w,d0
		add.w	(v_ani3_buf).w,d0
		move.w	d0,(v_ani3_buf).w
		rol.w	#7,d0
		andi.w	#3,d0
		move.b	d0,(v_ani3_frame).w
		subq.b	#1,(v_ani3_time).w

SyncEnd:
		rts
; End of function SynchroAnimate

; ---------------------------------------------------------------------------
; End-of-act signpost pattern loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SignpostArtLoad:
		tst.w	(v_debuguse).w	; is debug mode	being used?
		bne.s	@exit		; if yes, branch
		cmpi.b	#2,(v_act).w	; is act number 02 (act 3)?
		beq.s	@exit		; if yes, branch

		move.w	(v_screenposx).w,d0
		move.w	(v_limitright2).w,d1
		subi.w	#$100,d1
		cmp.w	d1,d0		; has Sonic reached the	edge of	the level?
		blt.s	@exit		; if not, branch
		tst.b	(f_timecount).w
		beq.s	@exit
		cmp.w	(v_limitleft2).w,d1
		beq.s	@exit
		move.w	d1,(v_limitleft2).w ; move left boundary to current screen position
		moveq	#plcid_Signpost,d0
		bra.w	NewPLC		; load signpost	patterns

	@exit:
		rts
; End of function SignpostArtLoad

		include	"_inc\LevelSizeLoad & BgScrollSpeed.asm"
		include	"_inc\DeformLayers.asm"


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

; sub_6886:
LoadTilesAsYouMove_BGOnly:
		lea	(vdp_control_port).l,a5
		lea	(vdp_data_port).l,a6
		lea	(v_bg1_scroll_flags).w,a2
		lea	(v_bgscreenposx).w,a3
		lea	(v_lvllayout+$40).w,a4
		move.w	#$6000,d2
		bsr.w	DrawBGScrollBlock1
		lea	(v_bg2_scroll_flags).w,a2
		lea	(v_bg2screenposx).w,a3
		bra.w	DrawBGScrollBlock2
; End of function sub_6886

; ---------------------------------------------------------------------------
; Subroutine to	display	correct	tiles as you move
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LoadTilesAsYouMove:
		lea	(vdp_control_port).l,a5
		lea	(vdp_data_port).l,a6
		; First, update the background
		lea	(v_bg1_scroll_flags_dup).w,a2	; Scroll block 1 scroll flags
		lea	(v_bgscreenposx_dup).w,a3	; Scroll block 1 X coordinate
		lea	(v_lvllayout+$40).w,a4
		move.w	#$6000,d2			; VRAM thing for selecting Plane B
		bsr.w	DrawBGScrollBlock1
		lea	(v_bg2_scroll_flags_dup).w,a2	; Scroll block 2 scroll flags
		lea	(v_bg2screenposx_dup).w,a3	; Scroll block 2 X coordinate
		bsr.w	DrawBGScrollBlock2
		; REV01 added a third scroll block, though, technically,
		; the RAM for it was already there in REV00
		lea	(v_bg3_scroll_flags_dup).w,a2	; Scroll block 3 scroll flags
		lea	(v_bg3screenposx_dup).w,a3	; Scroll block 3 X coordinate
		bsr.w	DrawBGScrollBlock3
		; Then, update the foreground
		lea	(v_fg_scroll_flags_dup).w,a2	; Foreground scroll flags
		lea	(v_screenposx_dup).w,a3		; Foreground X coordinate
		lea	(v_lvllayout).w,a4
		move.w	#$4000,d2			; VRAM thing for selecting Plane A
		; The FG's update function is inlined here
		tst.b	(a2)
		beq.s	locret_6952	; If there are no flags set, nothing needs updating
		bclr	#0,(a2)
		beq.s	loc_6908
		; Draw new tiles at the top
		moveq	#-16,d4	; Y coordinate. Note that 16 is the size of a block in pixels
		moveq	#-16,d5 ; X coordinate
		bsr.w	Calc_VRAM_Pos
		moveq	#-16,d4 ; Y coordinate
		moveq	#-16,d5 ; X coordinate
		bsr.w	DrawBlocks_LR

loc_6908:
		bclr	#1,(a2)
		beq.s	loc_6922
		; Draw new tiles at the bottom
		move.w	#224,d4	; Start at bottom of the screen. Since this draws from top to bottom, we don't need 224+16
		moveq	#-16,d5
		bsr.w	Calc_VRAM_Pos
		move.w	#224,d4
		moveq	#-16,d5
		bsr.w	DrawBlocks_LR

loc_6922:
		bclr	#2,(a2)
		beq.s	loc_6938
		; Draw new tiles on the left
		moveq	#-16,d4
		moveq	#-16,d5
		bsr.w	Calc_VRAM_Pos
		moveq	#-16,d4
		moveq	#-16,d5
		bsr.w	DrawBlocks_TB

loc_6938:
		bclr	#3,(a2)
		beq.s	locret_6952
		; Draw new tiles on the right
		moveq	#-16,d4
		move.w	#320,d5
		bsr.w	Calc_VRAM_Pos
		moveq	#-16,d4
		move.w	#320,d5
		bsr.w	DrawBlocks_TB

locret_6952:
		rts
; End of function LoadTilesAsYouMove


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

; sub_6954:
DrawBGScrollBlock1:
		tst.b	(a2)
		beq.w	locret_69F2
		bclr	#0,(a2)
		beq.s	loc_6972
		; Draw new tiles at the top
		moveq	#-16,d4
		moveq	#-16,d5
		bsr.w	Calc_VRAM_Pos
		moveq	#-16,d4
		moveq	#-16,d5
		bsr.w	DrawBlocks_LR

loc_6972:
		bclr	#1,(a2)
		beq.s	loc_698E
		; Draw new tiles at the top
		move.w	#224,d4
		moveq	#-16,d5
		bsr.w	Calc_VRAM_Pos
		move.w	#224,d4
		moveq	#-16,d5
		bsr.w	DrawBlocks_LR

loc_698E:
		bclr	#2,(a2)
		beq.s	locj_6D56
		; Draw new tiles on the left
		moveq	#-16,d4
		moveq	#-16,d5
		bsr.w	Calc_VRAM_Pos
		moveq	#-16,d4
		moveq	#-16,d5
		bsr.w	DrawBlocks_TB
locj_6D56:

		bclr	#3,(a2)
		beq.s	locj_6D70
		; Draw new tiles on the right
		moveq	#-16,d4
		move.w	#320,d5
		bsr.w	Calc_VRAM_Pos
		moveq	#-16,d4
		move.w	#320,d5
		bsr.w	DrawBlocks_TB
locj_6D70:

		bclr	#4,(a2)
		beq.s	locj_6D88
		; Draw entire row at the top
		moveq	#-16,d4
		moveq	#0,d5
		bsr.w	Calc_VRAM_Pos_2
		moveq	#-16,d4
		moveq	#0,d5
		moveq	#(512/16)-1,d6
		bsr.w	DrawBlocks_LR_3
locj_6D88:

		bclr	#5,(a2)
		beq.s	locret_69F2
		; Draw entire row at the bottom
		move.w	#224,d4
		moveq	#0,d5
		bsr.w	Calc_VRAM_Pos_2
		move.w	#224,d4
		moveq	#0,d5
		moveq	#(512/16)-1,d6
		bsr.w	DrawBlocks_LR_3

locret_69F2:
		rts
; End of function DrawBGScrollBlock1


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

; Essentially, this draws everything that isn't scroll block 1
; sub_69F4:
DrawBGScrollBlock2:
		tst.b	(a2)
		beq.w	locj_6DF2
		cmpi.b	#id_SBZ,(v_zone).w
		beq.w	Draw_SBz
		bclr	#0,(a2)
		beq.s	locj_6DD2
		; Draw new tiles on the left
		move.w	#224/2,d4	; Draw the bottom half of the screen
		moveq	#-16,d5
		bsr.w	Calc_VRAM_Pos
		move.w	#224/2,d4
		moveq	#-16,d5
		moveq	#3-1,d6		; Draw three rows... could this be a repurposed version of the above unused code?
		bsr.w	DrawBlocks_TB_2
locj_6DD2:
		bclr	#1,(a2)
		beq.s	locj_6DF2
		; Draw new tiles on the right
		move.w	#224/2,d4
		move.w	#320,d5
		bsr.w	Calc_VRAM_Pos
		move.w	#224/2,d4
		move.w	#320,d5
		moveq	#3-1,d6
		bsr.w	DrawBlocks_TB_2
locj_6DF2:
		rts
;===============================================================================
locj_6DF4:
		dc.b $00,$00,$00,$00,$00,$06,$06,$06,$06,$06,$06,$06,$06,$06,$06,$04
		dc.b $04,$04,$04,$04,$04,$04,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
		dc.b $02,$00
;===============================================================================
Draw_SBz:
		moveq	#-16,d4
		bclr	#0,(a2)
		bne.s	locj_6E28
		bclr	#1,(a2)
		beq.s	locj_6E72
		move.w	#224,d4
locj_6E28:
		lea	(locj_6DF4+1).l,a0
		move.w	(v_bgscreenposy).w,d0
		add.w	d4,d0
		andi.w	#$1F0,d0
		lsr.w	#4,d0
		move.b	(a0,d0.w),d0
		lea	(locj_6FE4).l,a3
		movea.w	(a3,d0.w),a3
		beq.s	locj_6E5E
		moveq	#-16,d5
		movem.l	d4/d5,-(sp)
		bsr.w	Calc_VRAM_Pos
		movem.l	(sp)+,d4/d5
		bsr.w	DrawBlocks_LR
		bra.s	locj_6E72
;===============================================================================
locj_6E5E:
		moveq	#0,d5
		movem.l	d4/d5,-(sp)
		bsr.w	Calc_VRAM_Pos_2
		movem.l	(sp)+,d4/d5
		moveq	#(512/16)-1,d6
		bsr.w	DrawBlocks_LR_3
locj_6E72:
		tst.b	(a2)
		bne.s	locj_6E78
		rts
;===============================================================================
locj_6E78:
		moveq	#-16,d4
		moveq	#-16,d5
		move.b	(a2),d0
		andi.b	#$A8,d0
		beq.s	locj_6E8C
		lsr.b	#1,d0
		move.b	d0,(a2)
		move.w	#320,d5
locj_6E8C:
		lea	(locj_6DF4).l,a0
		move.w	(v_bgscreenposy).w,d0
		andi.w	#$1F0,d0
		lsr.w	#4,d0
		lea	(a0,d0.w),a0
		bra.w	locj_6FEC
;===============================================================================


; locj_6EA4:
DrawBGScrollBlock3:
		tst.b	(a2)
		beq.w	locj_6EF0
		cmpi.b	#id_MZ,(v_zone).w
		beq.w	Draw_Mz
		bclr	#0,(a2)
		beq.s	locj_6ED0
		; Draw new tiles on the left
		move.w	#$40,d4
		moveq	#-16,d5
		bsr.w	Calc_VRAM_Pos
		move.w	#$40,d4
		moveq	#-16,d5
		moveq	#3-1,d6
		bsr.w	DrawBlocks_TB_2
locj_6ED0:
		bclr	#1,(a2)
		beq.s	locj_6EF0
		; Draw new tiles on the right
		move.w	#$40,d4
		move.w	#320,d5
		bsr.w	Calc_VRAM_Pos
		move.w	#$40,d4
		move.w	#320,d5
		moveq	#3-1,d6
		bsr.w	DrawBlocks_TB_2
locj_6EF0:
		rts
locj_6EF2:
		dc.b $00,$00,$00,$00,$00,$00,$06,$06,$04,$04,$04,$04,$04,$04,$04,$04
		dc.b $04,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
		dc.b $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
		dc.b $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
		dc.b $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
		dc.b $02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02,$02
		dc.b $02,$00
;===============================================================================
Draw_Mz:
		moveq	#-16,d4
		bclr	#0,(a2)
		bne.s	locj_6F66
		bclr	#1,(a2)
		beq.s	locj_6FAE
		move.w	#224,d4
locj_6F66:
		lea	(locj_6EF2+1).l,a0
		move.w	(v_bgscreenposy).w,d0
		subi.w	#$200,d0
		add.w	d4,d0
		andi.w	#$7F0,d0
		lsr.w	#4,d0
		move.b	(a0,d0.w),d0
		movea.w	locj_6FE4(pc,d0.w),a3
		beq.s	locj_6F9A
		moveq	#-16,d5
		movem.l	d4/d5,-(sp)
		bsr.w	Calc_VRAM_Pos
		movem.l	(sp)+,d4/d5
		bsr.w	DrawBlocks_LR
		bra.s	locj_6FAE
;===============================================================================
locj_6F9A:
		moveq	#0,d5
		movem.l	d4/d5,-(sp)
		bsr.w	Calc_VRAM_Pos_2
		movem.l	(sp)+,d4/d5
		moveq	#(512/16)-1,d6
		bsr.w	DrawBlocks_LR_3
locj_6FAE:
		tst.b	(a2)
		bne.s	locj_6FB4
		rts
;===============================================================================
locj_6FB4:
		moveq	#-16,d4
		moveq	#-16,d5
		move.b	(a2),d0
		andi.b	#$A8,d0
		beq.s	locj_6FC8
		lsr.b	#1,d0
		move.b	d0,(a2)
		move.w	#320,d5
locj_6FC8:
		lea	(locj_6EF2).l,a0
		move.w	(v_bgscreenposy).w,d0
		subi.w	#$200,d0
		andi.w	#$7F0,d0
		lsr.w	#4,d0
		lea	(a0,d0.w),a0
		bra.w	locj_6FEC
;===============================================================================
locj_6FE4:
		dc.w v_bgscreenposx_dup, v_bgscreenposx_dup, v_bg2screenposx_dup, v_bg3screenposx_dup
locj_6FEC:
		moveq	#((224+16+16)/16)-1,d6
		move.l	#$800000,d7
locj_6FF4:
		moveq	#0,d0
		move.b	(a0)+,d0
		btst	d0,(a2)
		beq.s	locj_701C
		movea.w	locj_6FE4(pc,d0.w),a3
		movem.l	d4/d5/a0,-(sp)
		movem.l	d4/d5,-(sp)
		bsr.w	GetBlockData
		movem.l	(sp)+,d4/d5
		bsr.w	Calc_VRAM_Pos
		bsr.w	DrawBlock
		movem.l	(sp)+,d4/d5/a0
locj_701C:
		addi.w	#16,d4
		dbf	d6,locj_6FF4
		clr.b	(a2)
		rts

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

; Don't be fooled by the name: this function's for drawing from left to right
; when the camera's moving up or down
; DrawTiles_LR:
DrawBlocks_LR:
		moveq	#((320+16+16)/16)-1,d6	; Draw the entire width of the screen + two extra columns
; DrawTiles_LR_2:
DrawBlocks_LR_2:
		move.l	#$800000,d7	; Delta between rows of tiles
		move.l	d0,d1

	@loop:
		movem.l	d4-d5,-(sp)
		bsr.w	GetBlockData
		move.l	d1,d0
		bsr.w	DrawBlock
		addq.b	#4,d1		; Two tiles ahead
		andi.b	#$7F,d1		; Wrap around row
		movem.l	(sp)+,d4-d5
		addi.w	#16,d5		; Move X coordinate one block ahead
		dbf	d6,@loop
		rts
; End of function DrawBlocks_LR

; DrawTiles_LR_3:
DrawBlocks_LR_3:
		move.l	#$800000,d7
		move.l	d0,d1

	@loop:
		movem.l	d4-d5,-(sp)
		bsr.w	GetBlockData_2
		move.l	d1,d0
		bsr.w	DrawBlock
		addq.b	#4,d1
		andi.b	#$7F,d1
		movem.l	(sp)+,d4-d5
		addi.w	#16,d5
		dbf	d6,@loop
		rts
; End of function DrawBlocks_LR_3


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

; Don't be fooled by the name: this function's for drawing from top to bottom
; when the camera's moving left or right
; DrawTiles_TB:
DrawBlocks_TB:
		moveq	#((224+16+16)/16)-1,d6	; Draw the entire height of the screen + two extra rows
; DrawTiles_TB_2:
DrawBlocks_TB_2:
		move.l	#$800000,d7	; Delta between rows of tiles
		move.l	d0,d1

	@loop:
		movem.l	d4-d5,-(sp)
		bsr.w	GetBlockData
		move.l	d1,d0
		bsr.w	DrawBlock
		addi.w	#$100,d1	; Two rows ahead
		andi.w	#$FFF,d1	; Wrap around plane
		movem.l	(sp)+,d4-d5
		addi.w	#16,d4		; Move X coordinate one block ahead
		dbf	d6,@loop
		rts
; End of function DrawBlocks_TB_2


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

; Draws a block's worth of tiles
; Parameters:
; a0 = Pointer to block metadata (block index and X/Y flip)
; a1 = Pointer to block
; a5 = Pointer to VDP command port
; a6 = Pointer to VDP data port
; d0 = VRAM command to access plane
; d2 = VRAM plane A/B specifier
; d7 = Plane row delta
; DrawTiles:
DrawBlock:
		or.w	d2,d0	; OR in that plane A/B specifier to the VRAM command
		swap	d0
		btst	#4,(a0)	; Check Y-flip bit
		bne.s	DrawFlipY
		btst	#3,(a0)	; Check X-flip bit
		bne.s	DrawFlipX
		move.l	d0,(a5)
		move.l	(a1)+,(a6)	; Write top two tiles
		add.l	d7,d0		; Next row
		move.l	d0,(a5)
		move.l	(a1)+,(a6)	; Write bottom two tiles
		rts
; ===========================================================================

DrawFlipX:
		move.l	d0,(a5)
		move.l	(a1)+,d4
		eori.l	#$8000800,d4	; Invert X-flip bits of each tile
		swap	d4		; Swap the tiles around
		move.l	d4,(a6)		; Write top two tiles
		add.l	d7,d0		; Next row
		move.l	d0,(a5)
		move.l	(a1)+,d4
		eori.l	#$8000800,d4
		swap	d4
		move.l	d4,(a6)		; Write bottom two tiles
		rts
; ===========================================================================

DrawFlipY:
		btst	#3,(a0)
		bne.s	DrawFlipXY
		move.l	d0,(a5)
		move.l	(a1)+,d5
		move.l	(a1)+,d4
		eori.l	#$10001000,d4
		move.l	d4,(a6)
		add.l	d7,d0
		move.l	d0,(a5)
		eori.l	#$10001000,d5
		move.l	d5,(a6)
		rts
; ===========================================================================

DrawFlipXY:
		move.l	d0,(a5)
		move.l	(a1)+,d5
		move.l	(a1)+,d4
		eori.l	#$18001800,d4
		swap	d4
		move.l	d4,(a6)
		add.l	d7,d0
		move.l	d0,(a5)
		eori.l	#$18001800,d5
		swap	d5
		move.l	d5,(a6)
		rts
; End of function DrawBlocks

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

; Gets address of block at a certain coordinate
; Parameters:
; a4 = Pointer to level layout
; d4 = Relative Y coordinate
; d5 = Relative X coordinate
; Returns:
; a0 = Address of block metadata
; a1 = Address of block
; DrawBlocks:
GetBlockData:
		add.w	(a3),d5
GetBlockData_2:
		add.w	4(a3),d4
		lea	(v_16x16).w,a1
		; Turn Y coordinate into index into level layout
		move.w	d4,d3
		lsr.w	#1,d3
		andi.w	#$380,d3
		; Turn X coordinate into index into level layout
		lsr.w	#3,d5
		move.w	d5,d0
		lsr.w	#5,d0
		andi.w	#$7F,d0
		; Get chunk from level layout
		add.w	d3,d0
		moveq	#-1,d3
		move.b	(a4,d0.w),d3
		beq.s	locret_6C1E	; If chunk 00, just return a pointer to the first block (expected to be empty)
		; Turn chunk ID into index into chunk table
		subq.b	#1,d3
		andi.w	#$7F,d3
		ror.w	#7,d3
		; Turn Y coordinate into index into chunk
		add.w	d4,d4
		andi.w	#$1E0,d4
		; Turn X coordinate into index into chunk
		andi.w	#$1E,d5
		; Get block metadata from chunk
		add.w	d4,d3
		add.w	d5,d3
		movea.l	d3,a0
		move.w	(a0),d3
		; Turn block ID into address
		andi.w	#$3FF,d3
		lsl.w	#3,d3
		adda.w	d3,a1

locret_6C1E:
		rts
; End of function GetBlockData


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

; Produces a VRAM plane access command from coordinates
; Parameters:
; d4 = Relative Y coordinate
; d5 = Relative X coordinate
; Returns VDP command in d0
Calc_VRAM_Pos:
		add.w	(a3),d5
Calc_VRAM_Pos_2:
		add.w	4(a3),d4
		; Floor the coordinates to the nearest pair of tiles (the size of a block).
		; Also note that this wraps the value to the size of the plane:
		; The plane is 64*8 wide, so wrap at $100, and it's 32*8 tall, so wrap at $200
		andi.w	#$F0,d4
		andi.w	#$1F0,d5
		; Transform the adjusted coordinates into a VDP command
		lsl.w	#4,d4
		lsr.w	#2,d5
		add.w	d5,d4
		moveq	#3,d0	; Highest bits of plane VRAM address
		swap	d0
		move.w	d4,d0
		rts
; End of function Calc_VRAM_Pos

; ---------------------------------------------------------------------------
; Subroutine to	load tiles as soon as the level	appears
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LoadTilesFromStart:
		lea	(vdp_control_port).l,a5
		lea	(vdp_data_port).l,a6
		lea	(v_screenposx).w,a3
		lea	(v_lvllayout).w,a4
		move.w	#$4000,d2
		bsr.s	DrawChunks
		lea	(v_bgscreenposx).w,a3
		lea	(v_lvllayout+$40).w,a4
		move.w	#$6000,d2
		tst.b	(v_zone).w
		beq.w	Draw_GHz_Bg
		cmpi.b	#id_MZ,(v_zone).w
		beq.w	Draw_Mz_Bg
		cmpi.w	#(id_SBZ<<8)+0,(v_zone).w
		beq.w	Draw_SBz_Bg
		cmpi.b	#id_EndZ,(v_zone).w
		beq.w	Draw_GHz_Bg
; End of function LoadTilesFromStart


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


DrawChunks:
		moveq	#-16,d4
		moveq	#((224+16+16)/16)-1,d6

	@loop:
		movem.l	d4-d6,-(sp)
		moveq	#0,d5
		move.w	d4,d1
		bsr.w	Calc_VRAM_Pos
		move.w	d1,d4
		moveq	#0,d5
		moveq	#(512/16)-1,d6
		bsr.w	DrawBlocks_LR_2
		movem.l	(sp)+,d4-d6
		addi.w	#16,d4
		dbf	d6,@loop
		rts
; End of function DrawChunks

Draw_GHz_Bg:
		moveq	#0,d4
		moveq	#((224+16+16)/16)-1,d6
locj_7224:
		movem.l	d4-d6,-(sp)
		lea	(locj_724a),a0
		move.w	(v_bgscreenposy).w,d0
		add.w	d4,d0
		andi.w	#$F0,d0
		bsr.w	locj_72Ba
		movem.l	(sp)+,d4-d6
		addi.w	#16,d4
		dbf	d6,locj_7224
		rts
locj_724a:
		dc.b $00,$00,$00,$00,$06,$06,$06,$04,$04,$04,$00,$00,$00,$00,$00,$00
;-------------------------------------------------------------------------------
Draw_Mz_Bg:;locj_725a:
		moveq	#-16,d4
		moveq	#((224+16+16)/16)-1,d6
locj_725E:
		movem.l	d4-d6,-(sp)
		lea	(locj_6EF2+1),a0
		move.w	(v_bgscreenposy).w,d0
		subi.w	#$200,d0
		add.w	d4,d0
		andi.w	#$7F0,d0
		bsr.w	locj_72Ba
		movem.l	(sp)+,d4-d6
		addi.w	#16,d4
		dbf	d6,locj_725E
		rts
;-------------------------------------------------------------------------------
Draw_SBz_Bg:;locj_7288:
		moveq	#-16,d4
		moveq	#((224+16+16)/16)-1,d6
locj_728C:
		movem.l	d4-d6,-(sp)
		lea	(locj_6DF4+1),a0
		move.w	(v_bgscreenposy).w,d0
		add.w	d4,d0
		andi.w	#$1F0,d0
		bsr.w	locj_72Ba
		movem.l	(sp)+,d4-d6
		addi.w	#16,d4
		dbf	d6,locj_728C
		rts
;-------------------------------------------------------------------------------
locj_72B2:
		dc.w v_bgscreenposx, v_bgscreenposx, v_bg2screenposx, v_bg3screenposx
locj_72Ba:
		lsr.w	#4,d0
		move.b	(a0,d0.w),d0
		movea.w	locj_72B2(pc,d0.w),a3
		beq.s	locj_72da
		moveq	#-16,d5
		movem.l	d4/d5,-(sp)
		bsr.w	Calc_VRAM_Pos
		movem.l	(sp)+,d4/d5
		bsr.w	DrawBlocks_LR
		bra.s	locj_72EE
locj_72da:
		moveq	#0,d5
		movem.l	d4/d5,-(sp)
		bsr.w	Calc_VRAM_Pos_2
		movem.l	(sp)+,d4/d5
		moveq	#(512/16)-1,d6
		bsr.w	DrawBlocks_LR_3
locj_72EE:
		rts

; ---------------------------------------------------------------------------
; Subroutine to load basic level data
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LevelDataLoad:
		moveq	#0,d0
		move.b	(v_zone).w,d0
		lsl.w	#4,d0
		lea	(LevelHeaders).l,a2
		lea	(a2,d0.w),a2
		move.l	a2,-(sp)
		addq.l	#4,a2
		movea.l	(a2)+,a0
		lea	(v_16x16).w,a1	; RAM address for 16x16 mappings
		moveq	#0,d0
		bsr.w	EniDec
		movea.l	(a2)+,a0
		lea	(v_256x256).l,a1 ; RAM address for 256x256 mappings
		bsr.w	KosDec
		bsr.s	LevelLayoutLoad
		move.w	(a2)+,d0
		move.w	(a2),d0
		andi.w	#$FF,d0
		bsr.w	PalLoad1	; load palette (based on d0)
		movea.l	(sp)+,a2
		addq.w	#4,a2		; read number for 2nd PLC
		moveq	#0,d0
		move.b	(a2),d0
		beq.s	@skipPLC	; if 2nd PLC is 0 (i.e. the ending sequence), branch
		bra.w	AddPLC		; load pattern load cues

	@skipPLC:
		rts
; End of function LevelDataLoad

; ---------------------------------------------------------------------------
; Level	layout loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LevelLayoutLoad:
		lea	(v_lvllayout).w,a3 ; RAM address for level layout
		moveq	#0,d1
		bsr.s	LevelLayoutLoad2 ; load	level layout into RAM
		lea	(v_lvllayout+$40).w,a3 ; RAM address for background layout
		moveq	#2,d1
; End of function LevelLayoutLoad

; "LevelLayoutLoad2" is	run twice - for	the level and the background

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LevelLayoutLoad2:
		move.w	(v_zone).w,d0
		lsl.b	#6,d0
		lsr.w	#5,d0
		move.w	d0,d2
		add.w	d0,d0
		add.w	d2,d0
		add.w	d1,d0
		lea	(Level_Index).l,a1
		move.w	(a1,d0.w),d0
		lea	(a1,d0.w),a1
		moveq	#0,d1
		move.w	d1,d2
		move.b	(a1)+,d1	; load level width (in tiles)
		move.b	(a1)+,d2	; load level height (in	tiles)

LevLoad_NumRows:
		move.w	d1,d0
		movea.l	a3,a0

LevLoad_Row:
		move.b	(a1)+,(a0)+
		dbf	d0,LevLoad_Row	; load 1 row
		lea	$80(a3),a3	; do next row
		dbf	d2,LevLoad_NumRows ; repeat for	number of rows
		rts
; End of function LevelLayoutLoad2

		include	"_inc\DynamicLevelEvents.asm"

		include	"_incObj\11 Bridge (part 1).asm"

; ---------------------------------------------------------------------------
; Platform subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||

PlatformObject:
		lea	(v_player).w,a1
		tst.w	obVelY(a1)	; is Sonic moving up/jumping?
		bmi.w	Plat_Exit	; if yes, branch

;		perform x-axis range check
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		add.w	d1,d0
		bmi.w	Plat_Exit
		add.w	d1,d1
		cmp.w	d1,d0
		bhs.w	Plat_Exit

	Plat_NoXCheck:
		move.w	obY(a0),d0
		subq.w	#8,d0

Platform3:
;		perform y-axis range check
		move.w	obY(a1),d2
		move.b	obHeight(a1),d1
		ext.w	d1
		add.w	d2,d1
		addq.w	#4,d1
		sub.w	d1,d0
		bhi.w	Plat_Exit
		cmpi.w	#-$10,d0
		blo.w	Plat_Exit

		tst.b	(f_lockmulti).w
		bmi.w	Plat_Exit
		cmpi.b	#6,obRoutine(a1)
		bhs.w	Plat_Exit
		add.w	d0,d2
		addq.w	#3,d2
		move.w	d2,obY(a1)
		addq.b	#2,obRoutine(a0)

loc_74AE:
		btst	#3,obStatus(a1)
		beq.s	loc_74DC
		moveq	#0,d0
		move.b	standonobject(a1),d0
		lsl.w	#6,d0
		addi.l	#v_objspace&$FFFFFF,d0
		movea.l	d0,a2
		bclr	#3,obStatus(a2)
		clr.b	ob2ndRout(a2)
		cmpi.b	#4,obRoutine(a2)
		bne.s	loc_74DC
		subq.b	#2,obRoutine(a2)

loc_74DC:
		move.w	a0,d0
		subi.w	#-$3000,d0
		lsr.w	#6,d0
		andi.w	#$7F,d0
		move.b	d0,standonobject(a1)
		move.b	#0,obAngle(a1)
		move.w	#0,obVelY(a1)
		move.w	obVelX(a1),obInertia(a1)
		btst	#1,obStatus(a1)
		beq.s	loc_7512
		move.l	a0,-(sp)
		movea.l	a1,a0
		jsr	(Sonic_ResetOnFloor).l
		movea.l	(sp)+,a0

loc_7512:
		bset	#3,obStatus(a1)
		bset	#3,obStatus(a0)

Plat_Exit:
		rts
; End of function PlatformObject

; ---------------------------------------------------------------------------
; Sloped platform subroutine (GHZ collapsing ledges and	SLZ seesaws)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SlopeObject:
		lea	(v_player).w,a1
		tst.w	obVelY(a1)
		bmi.w	Plat_Exit
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		add.w	d1,d0
		bmi.s	Plat_Exit
		add.w	d1,d1
		cmp.w	d1,d0
		bhs.s	Plat_Exit
		btst	#0,obRender(a0)
		beq.s	loc_754A
		not.w	d0
		add.w	d1,d0

loc_754A:
		lsr.w	#1,d0
		moveq	#0,d3
		move.b	(a2,d0.w),d3
		move.w	obY(a0),d0
		sub.w	d3,d0
		bra.w	Platform3
; End of function SlopeObject


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Swing_Solid:
		lea	(v_player).w,a1
		tst.w	obVelY(a1)
		bmi.w	Plat_Exit
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		add.w	d1,d0
		bmi.w	Plat_Exit
		add.w	d1,d1
		cmp.w	d1,d0
		bhs.w	Plat_Exit
		move.w	obY(a0),d0
		sub.w	d3,d0
		bra.w	Platform3
; End of function Obj15_Solid

; ===========================================================================

		include	"_incObj\11 Bridge (part 2).asm"

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to walk or jump off	a platform
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ExitPlatform:
		move.w	d1,d2

ExitPlatform2:
		add.w	d2,d2
		lea	(v_player).w,a1
		btst	#1,obStatus(a1)
		bne.s	loc_75E0
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		add.w	d1,d0
		bmi.s	loc_75E0
		cmp.w	d2,d0
		blo.s	locret_75F2

loc_75E0:
		bclr	#3,obStatus(a1)
		move.b	#2,obRoutine(a0)
		bclr	#3,obStatus(a0)

locret_75F2:
		rts
; End of function ExitPlatform

		include	"_incObj\11 Bridge (part 3).asm"
Map_Bri:	include	"_maps\Bridge.asm"

		include	"_incObj\15 Swinging Platforms (part 1).asm"

; ---------------------------------------------------------------------------
; Subroutine to	change Sonic's position with a platform
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


MvSonicOnPtfm:
		lea	(v_player).w,a1
		move.w	obY(a0),d0
		sub.w	d3,d0
		bra.s	MvSonic2
; End of function MvSonicOnPtfm

; ---------------------------------------------------------------------------
; Subroutine to	change Sonic's position with a platform
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


MvSonicOnPtfm2:
		lea	(v_player).w,a1
		move.w	obY(a0),d0
		subi.w	#9,d0

MvSonic2:
		tst.b	(f_lockmulti).w
		bmi.s	locret_7B62
		cmpi.b	#6,(v_player+obRoutine).w
		bhs.s	locret_7B62
		tst.w	(v_debuguse).w
		bne.s	locret_7B62
		moveq	#0,d1
		move.b	obHeight(a1),d1
		sub.w	d1,d0
		move.w	d0,obY(a1)
		sub.w	obX(a0),d2
		sub.w	d2,obX(a1)

locret_7B62:
		rts
; End of function MvSonicOnPtfm2

		include	"_incObj\15 Swinging Platforms (part 2).asm"
Map_Swing_GHZ:	include	"_maps\Swinging Platforms (GHZ).asm"
		include	"_incObj\17 Spiked Pole Helix.asm"
Map_Hel:	include	"_maps\Spiked Pole Helix.asm"
		include	"_incObj\18 Platforms.asm"
Map_Plat_GHZ:	include	"_maps\Platforms (GHZ).asm"
Map_GBall:	include	"_maps\GHZ Ball.asm"
		include	"_incObj\1A Collapsing Ledge (part 1).asm"

; ===========================================================================

Ledge_Fragment:
		move.b	#0,ledge_collapse_flag(a0)

loc_847A:
		lea	CFlo_Data1(pc),a4
		moveq	#$18,d1
		addq.b	#2,obFrame(a0)

loc_8486:
		moveq	#0,d0
		move.b	obFrame(a0),d0
		add.w	d0,d0
		movea.l	obMap(a0),a3
		adda.w	(a3,d0.w),a3
		addq.w	#1,a3
		bset	#5,obRender(a0)
		movea.l	a0,a1
		bra.s	loc_84B2
; ===========================================================================

loc_84AA:
		bsr.w	FindFreeObj
		bne.s	loc_84F2
		addq.w	#5,a3

loc_84B2:
		move.b	#6,obRoutine(a1)
		move.b	0(a0),0(a1)
		move.l	a3,obMap(a1)
		move.b	obRender(a0),obRender(a1)
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		move.w	obGfx(a0),obGfx(a1)
		move.b	obPriority(a0),obPriority(a1)
		move.b	obActWid(a0),obActWid(a1)
		move.b	(a4)+,ledge_timedelay(a1)

loc_84EE:
		dbf	d1,loc_84AA

loc_84F2:
		move.w	#sfx_Collapse,d0
		jmp	(PlaySound_Special).l	; play collapsing sound
; ===========================================================================
; ---------------------------------------------------------------------------
; Disintegration data for collapsing ledges (MZ, SLZ, SBZ)
; ---------------------------------------------------------------------------
CFlo_Data1:	dc.b $1C, $18, $14, $10, $1A, $16, $12,	$E, $A,	6, $18,	$14, $10, $C, 8, 4
		dc.b $16, $12, $E, $A, 6, 2, $14, $10, $C, 0
CFlo_Data2:	dc.b $1E, $16, $E, 6, $1A, $12,	$A, 2
CFlo_Data3:	dc.b $16, $1E, $1A, $12, 6, $E,	$A, 2

; ---------------------------------------------------------------------------
; Sloped platform subroutine (GHZ collapsing ledges and	MZ platforms)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SlopeObject2:
		lea	(v_player).w,a1
		btst	#3,obStatus(a1)
		beq.s	locret_856E
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		add.w	d1,d0
		lsr.w	#1,d0
		btst	#0,obRender(a0)
		beq.s	loc_854E
		not.w	d0
		add.w	d1,d0

loc_854E:
		moveq	#0,d1
		move.b	(a2,d0.w),d1
		move.w	obY(a0),d0
		sub.w	d1,d0
		moveq	#0,d1
		move.b	obHeight(a1),d1
		sub.w	d1,d0
		move.w	d0,obY(a1)
		sub.w	obX(a0),d2
		sub.w	d2,obX(a1)

locret_856E:
		rts
; End of function SlopeObject2

; ===========================================================================
; ---------------------------------------------------------------------------
; Collision data for GHZ collapsing ledge
; ---------------------------------------------------------------------------
Ledge_SlopeData:
		incbin	"misc\GHZ Collapsing Ledge Heightmap.bin"
		even

Map_Ledge:	include	"_maps\Collapsing Ledge.asm"
Map_CFlo:	include	"_maps\Collapsing Floors.asm"

		include	"_incObj\1C Scenery.asm"
Map_Scen:	include	"_maps\Scenery.asm"

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Obj44_SolidWall:
		bsr.w	Obj44_SolidWall2
		beq.s	loc_8AA8
		bmi.s	loc_8AC4
		tst.w	d0
		beq.s	loc_8A92
		bmi.s	loc_8A7C
		tst.w	obVelX(a1)
		bmi.s	loc_8A92
		bra.s	loc_8A82
; ===========================================================================

loc_8A7C:
		tst.w	obVelX(a1)
		bpl.s	loc_8A92

loc_8A82:
		sub.w	d0,obX(a1)
		move.w	#0,obInertia(a1)
		move.w	#0,obVelX(a1)

loc_8A92:
		btst	#1,obStatus(a1)
		bne.s	loc_8AB6
		bset	#5,obStatus(a1)
		bset	#5,obStatus(a0)
		rts
; ===========================================================================

loc_8AA8:
		btst	#5,obStatus(a0)
		beq.s	locret_8AC2
		move.w	#id_Run,obAnim(a1)

loc_8AB6:
		bclr	#5,obStatus(a0)
		bclr	#5,obStatus(a1)

locret_8AC2:
		rts
; ===========================================================================

loc_8AC4:
		tst.w	obVelY(a1)
		bpl.s	locret_8AD8
		tst.w	d3
		bpl.s	locret_8AD8
		sub.w	d3,obY(a1)
		move.w	#0,obVelY(a1)

locret_8AD8:
		rts
; End of function Obj44_SolidWall


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Obj44_SolidWall2:
		lea	(v_player).w,a1
		move.w	obX(a1),d0
		sub.w	obX(a0),d0
		add.w	d1,d0
		bmi.s	loc_8B48
		move.w	d1,d3
		add.w	d3,d3
		cmp.w	d3,d0
		bhi.s	loc_8B48
		move.b	obHeight(a1),d3
		ext.w	d3
		add.w	d3,d2
		move.w	obY(a1),d3
		sub.w	obY(a0),d3
		add.w	d2,d3
		bmi.s	loc_8B48
		move.w	d2,d4
		add.w	d4,d4
		cmp.w	d4,d3
		bhs.s	loc_8B48
		tst.b	(f_lockmulti).w
		bmi.s	loc_8B48
		cmpi.b	#6,(v_player+obRoutine).w
		bhs.s	loc_8B48
		tst.w	(v_debuguse).w
		bne.s	loc_8B48
		move.w	d0,d5
		cmp.w	d0,d1
		bhs.s	loc_8B30
		add.w	d1,d1
		sub.w	d1,d0
		move.w	d0,d5
		neg.w	d5

loc_8B30:
		move.w	d3,d1
		cmp.w	d3,d2
		bhs.s	loc_8B3C
		sub.w	d4,d3
		move.w	d3,d1
		neg.w	d1

loc_8B3C:
		cmp.w	d1,d5
		bhi.s	loc_8B44
		moveq	#1,d4
		rts
; ===========================================================================

loc_8B44:
		moveq	#-1,d4
		rts
; ===========================================================================

loc_8B48:
		moveq	#0,d4
		rts
; End of function Obj44_SolidWall2

; ===========================================================================

		include	"_incObj\27 & 3F Explosions.asm"
		include	"_maps\Explosions.asm"

		include	"_incObj\28 Animals.asm"
		include	"_incObj\29 Points.asm"
Map_Animal1:	include	"_maps\Animals 1.asm"
Map_Animal2:	include	"_maps\Animals 2.asm"
Map_Animal3:	include	"_maps\Animals 3.asm"
Map_Poi:	include	"_maps\Points.asm"

		include	"_incObj\1F Crabmeat.asm"
		include	"_anim\Crabmeat.asm"
Map_Crab:	include	"_maps\Crabmeat.asm"
		include	"_incObj\22 Buzz Bomber.asm"
		include	"_incObj\23 Buzz Bomber Missile.asm"
		include	"_anim\Buzz Bomber.asm"
		include	"_anim\Buzz Bomber Missile.asm"
Map_Buzz:	include	"_maps\Buzz Bomber.asm"
Map_Missile:	include	"_maps\Buzz Bomber Missile.asm"

		include	"_incObj\25 & 37 Rings.asm"
		include	"_incObj\4B Giant Ring.asm"
		include	"_incObj\7C Ring Flash.asm"

		include	"_anim\Rings.asm"
Map_Ring:	include	"_maps\Rings.asm"
Map_GRing:	include	"_maps\Giant Ring.asm"
Map_Flash:	include	"_maps\Ring Flash.asm"
		include	"_incObj\26 Monitor.asm"
		include	"_incObj\2E Monitor Content Power-Up.asm"
		include	"_incObj\26 Monitor (SolidSides subroutine).asm"
		include	"_anim\Monitor.asm"
Map_Monitor:	include	"_maps\Monitor.asm"

		include	"_incObj\0E Title Screen Sonic.asm"
		include	"_incObj\0F Press Start and TM.asm"

		include	"_anim\Title Screen Sonic.asm"
		include	"_anim\Press Start and TM.asm"

		include	"_incObj\sub AnimateSprite.asm"

Map_PSB:	include	"_maps\Press Start and TM.asm"
Map_TSon:	include	"_maps\Title Screen Sonic.asm"

		include	"_incObj\2B Chopper.asm"
		include	"_anim\Chopper.asm"
Map_Chop:	include	"_maps\Chopper.asm"

		include	"_incObj\34 Title Cards.asm"
		include	"_incObj\39 Game Over.asm"
		include	"_incObj\3A Got Through Card.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - zone title cards
; ---------------------------------------------------------------------------
Map_Card:	dc.w M_Card_GHZ-Map_Card
		dc.w M_Card_Zone-Map_Card
		dc.w M_Card_Act1-Map_Card
		dc.w M_Card_Act2-Map_Card
		dc.w M_Card_Act3-Map_Card
		dc.w M_Card_Oval-Map_Card
M_Card_GHZ:	dc.b 9 			; GREEN HILL
		dc.b $F8, 5, 0,	$18, $B4
		dc.b $F8, 5, 0,	$3A, $C4
		dc.b $F8, 5, 0,	$10, $D4
		dc.b $F8, 5, 0,	$10, $E4
		dc.b $F8, 5, 0,	$2E, $F4
		dc.b $F8, 5, 0,	$1C, $14
		dc.b $F8, 1, 0,	$20, $24
		dc.b $F8, 5, 0,	$26, $2C
		dc.b $F8, 5, 0,	$26, $3C
		even
M_Card_Zone:	dc.b 4			; ZONE
		dc.b $F8, 5, 0,	$4E, $E0
		dc.b $F8, 5, 0,	$32, $F0
		dc.b $F8, 5, 0,	$2E, 0
		dc.b $F8, 5, 0,	$10, $10
		even
M_Card_Act1:	dc.b 2			; ACT 1
		dc.b 4,	$C, 0, $53, $EC
		dc.b $F4, 2, 0,	$57, $C
M_Card_Act2:	dc.b 2			; ACT 2
		dc.b 4,	$C, 0, $53, $EC
		dc.b $F4, 6, 0,	$5A, 8
M_Card_Act3:	dc.b 2			; ACT 3
		dc.b 4,	$C, 0, $53, $EC
		dc.b $F4, 6, 0,	$60, 8
M_Card_Oval:	dc.b $D			; Oval
		dc.b $E4, $C, 0, $70, $F4
		dc.b $E4, 2, 0,	$74, $14
		dc.b $EC, 4, 0,	$77, $EC
		dc.b $F4, 5, 0,	$79, $E4
		dc.b $14, $C, $18, $70,	$EC
		dc.b 4,	2, $18,	$74, $E4
		dc.b $C, 4, $18, $77, 4
		dc.b $FC, 5, $18, $79, $C
		dc.b $EC, 8, 0,	$7D, $FC
		dc.b $F4, $C, 0, $7C, $F4
		dc.b $FC, 8, 0,	$7C, $F4
		dc.b 4,	$C, 0, $7C, $EC
		dc.b $C, 8, 0, $7C, $EC
		even

Map_Over:	include	"_maps\Game Over.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - "SONIC HAS PASSED" title card
; ---------------------------------------------------------------------------
Map_Got:	dc.w M_Got_SonicHas-Map_Got
		dc.w M_Got_Passed-Map_Got
		dc.w M_Got_Score-Map_Got
		dc.w M_Got_TBonus-Map_Got
		dc.w M_Got_RBonus-Map_Got
		dc.w M_Card_Oval-Map_Got
		dc.w M_Card_Act1-Map_Got
		dc.w M_Card_Act2-Map_Got
		dc.w M_Card_Act3-Map_Got
M_Got_SonicHas:	dc.b 8			; SONIC HAS
		dc.b $F8, 5, 0,	$3E, $B8
		dc.b $F8, 5, 0,	$32, $C8
		dc.b $F8, 5, 0,	$2E, $D8
		dc.b $F8, 1, 0,	$20, $E8
		dc.b $F8, 5, 0,	8, $F0
		dc.b $F8, 5, 0,	$1C, $10
		dc.b $F8, 5, 0,	0, $20
		dc.b $F8, 5, 0,	$3E, $30
M_Got_Passed:	dc.b 6			; PASSED
		dc.b $F8, 5, 0,	$36, $D0
		dc.b $F8, 5, 0,	0, $E0
		dc.b $F8, 5, 0,	$3E, $F0
		dc.b $F8, 5, 0,	$3E, 0
		dc.b $F8, 5, 0,	$10, $10
		dc.b $F8, 5, 0,	$C, $20
M_Got_Score:	dc.b 6			; SCORE
		dc.b $F8, $D, 1, $4A, $B0
		dc.b $F8, 1, 1,	$62, $D0
		dc.b $F8, 9, 1,	$64, $18
		dc.b $F8, $D, 1, $6A, $30
		dc.b $F7, 4, 0,	$6E, $CD
		dc.b $FF, 4, $18, $6E, $CD
M_Got_TBonus:	dc.b 7			; TIME BONUS
		dc.b $F8, $D, 1, $5A, $B0
		dc.b $F8, $D, 0, $66, $D9
		dc.b $F8, 1, 1,	$4A, $F9
		dc.b $F7, 4, 0,	$6E, $F6
		dc.b $FF, 4, $18, $6E, $F6
		dc.b $F8, $D, $FF, $F0,	$28
		dc.b $F8, 1, 1,	$70, $48
M_Got_RBonus:	dc.b 7			; RING BONUS
		dc.b $F8, $D, 1, $52, $B0
		dc.b $F8, $D, 0, $66, $D9
		dc.b $F8, 1, 1,	$4A, $F9
		dc.b $F7, 4, 0,	$6E, $F6
		dc.b $FF, 4, $18, $6E, $F6
		dc.b $F8, $D, $FF, $F8,	$28
		dc.b $F8, 1, 1,	$70, $48
		even

		include	"_incObj\36 Spikes.asm"
Map_Spike:	include	"_maps\Spikes.asm"
		include	"_incObj\3B Purple Rock.asm"
		include	"_incObj\49 Waterfall Sound.asm"
Map_PRock:	include	"_maps\Purple Rock.asm"
		include	"_incObj\3C Smashable Wall.asm"

		include	"_incObj\sub SmashObject.asm"

; ===========================================================================
; Smashed block	fragment speeds
;
Smash_FragSpd1:	dc.w $400, -$500	; x-move speed,	y-move speed
		dc.w $600, -$100
		dc.w $600, $100
		dc.w $400, $500
		dc.w $600, -$600
		dc.w $800, -$200
		dc.w $800, $200
		dc.w $600, $600

Smash_FragSpd2:	dc.w -$600, -$600
		dc.w -$800, -$200
		dc.w -$800, $200
		dc.w -$600, $600
		dc.w -$400, -$500
		dc.w -$600, -$100
		dc.w -$600, $100
		dc.w -$400, $500

Map_Smash:	include	"_maps\Smashable Walls.asm"

; ---------------------------------------------------------------------------
; Object code execution subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ExecuteObjects:
		lea	(v_objspace).w,a0 ; set address for object RAM
		moveq	#$7F,d7
		cmpi.b	#6,(v_player+obRoutine).w
		bhs.s	loc_D362

loc_D348:
		moveq	#0,d0
                move.b	(a0),d0		; load object number from RAM
		beq.s	loc_D358
		lsl.w	#2,d0
		movea.l	Obj_Index-4(pc,d0.w),a1
		jsr	(a1)		; run the object's code

loc_D358:
		lea	$40(a0),a0	; next object
		dbf	d7,loc_D348
		rts
; ===========================================================================

loc_D362:
		moveq	#$1F,d7
		bsr.s	loc_D348
		moveq	#$5F,d7

loc_D368:
		moveq	#0,d0
		move.b	(a0),d0
		beq.s	loc_D378
		tst.b	obRender(a0)
		bpl.s	loc_D378
		bsr.w	DisplaySprite

loc_D378:
		lea	$40(a0),a0

loc_D37C:
		dbf	d7,loc_D368
		rts
; End of function ExecuteObjects

; ===========================================================================
; ---------------------------------------------------------------------------
; Object pointers
; ---------------------------------------------------------------------------
Obj_Index:
		include	"_inc\Object Pointers.asm"

		include	"_incObj\sub ObjectFall.asm"
		include	"_incObj\sub SpeedToPos.asm"
		include	"_incObj\sub DisplaySprite.asm"
		include	"_incObj\sub DeleteObject.asm"

; ===========================================================================
BldSpr_ScrPos:	dc.l 0				; blank
		dc.l v_screenposx&$FFFFFF	; main screen x-position
		dc.l v_bgscreenposx&$FFFFFF	; background x-position	1
		dc.l v_bg3screenposx&$FFFFFF	; background x-position	2
; ---------------------------------------------------------------------------
; Subroutine to	convert	mappings (etc) to proper Megadrive sprites
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


BuildSprites:
		lea	(v_spritetablebuffer).w,a2 ; set address for sprite table
		moveq	#0,d5
		lea	(v_spritequeue).w,a4
		moveq	#7,d7

	@priorityLoop:
		tst.w	(a4)	; are there objects left to draw?
		beq.w	@nextPriority	; if not, branch
		moveq	#2,d6

	@objectLoop:
		movea.w	(a4,d6.w),a0	; load object ID
		tst.b	(a0)		; if null, branch
		beq.w	@skipObject
		bclr	#7,obRender(a0)		; set as not visible

		move.b	obRender(a0),d0
		move.b	d0,d4
		andi.w	#$C,d0		; get drawing coordinates
		beq.s	@screenCoords	; branch if 0 (screen coordinates)
		movea.l	BldSpr_ScrPos(pc,d0.w),a1
	; check object bounds
		moveq	#0,d0
		move.b	obActWid(a0),d0
		move.w	obX(a0),d3
		sub.w	(a1),d3
		move.w	d3,d1
		add.w	d0,d1
		bmi.w	@skipObject	; left edge out of bounds
		move.w	d3,d1
		sub.w	d0,d1
		cmpi.w	#320,d1
		bge.s	@skipObject	; right edge out of bounds
		addi.w	#128,d3		; VDP sprites start at 128px

		btst	#4,d4		; is assume height flag on?
		beq.s	@assumeHeight	; if yes, branch
		moveq	#0,d0
		move.b	obHeight(a0),d0
		move.w	obY(a0),d2
		sub.w	4(a1),d2
		move.w	d2,d1
		add.w	d0,d1
		bmi.s	@skipObject	; top edge out of bounds
		move.w	d2,d1
		sub.w	d0,d1
		cmpi.w	#224,d1
		bge.s	@skipObject
		addi.w	#128,d2		; VDP sprites start at 128px
		bra.s	@drawObject
; ===========================================================================

	@screenCoords:
		move.w	$A(a0),d2	; special variable for screen Y
		move.w	obX(a0),d3
		bra.s	@drawObject
; ===========================================================================

	@assumeHeight:
		move.w	obY(a0),d2
		sub.w	obMap(a1),d2
		addi.w	#$80,d2
		cmpi.w	#$60,d2
		blo.s	@skipObject
		cmpi.w	#$180,d2
		bhs.s	@skipObject

	@drawObject:
		movea.l	obMap(a0),a1
		moveq	#0,d1
		btst	#5,d4		; is static mappings flag on?
		bne.s	@drawFrame	; if yes, branch
		move.b	obFrame(a0),d1
		add.b	d1,d1
		adda.w	(a1,d1.w),a1	; get mappings frame address
		move.b	(a1)+,d1	; number of sprite pieces
		subq.b	#1,d1
		bmi.s	@setVisible

	@drawFrame:
		bsr.s	BuildSpr_Draw	; write data from sprite pieces to buffer

	@setVisible:
		bset	#7,obRender(a0)		; set object as visible

	@skipObject:
		addq.w	#2,d6
		subq.w	#2,(a4)			; number of objects left
		bne.w	@objectLoop

	@nextPriority:
		lea	$80(a4),a4
		dbf	d7,@priorityLoop
		move.b	d5,(v_spritecount).w
		cmpi.b	#$50,d5
		beq.s	@spriteLimit
		move.l	#0,(a2)
		rts
; ===========================================================================

	@spriteLimit:
		move.b	#0,-5(a2)	; set last sprite link
		rts
; End of function BuildSprites


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


BuildSpr_Draw:
		movea.w	obGfx(a0),a3
		btst	#0,d4
		bne.s	BuildSpr_FlipX
		btst	#1,d4
		bne.w	BuildSpr_FlipY
; End of function BuildSpr_Draw


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


BuildSpr_Normal:
		cmpi.b	#$50,d5		; check sprite limit
		beq.s	@return
		move.b	(a1)+,d0	; get y-offset
		ext.w	d0
		add.w	d2,d0		; add y-position
		move.w	d0,(a2)+	; write to buffer
		move.b	(a1)+,(a2)+	; write sprite size
		addq.b	#1,d5		; increase sprite counter
		move.b	d5,(a2)+	; set as sprite link
		move.b	(a1)+,d0	; get art tile
		lsl.w	#8,d0
		move.b	(a1)+,d0
		add.w	a3,d0		; add art tile offset
		move.w	d0,(a2)+	; write to buffer
		move.b	(a1)+,d0	; get x-offset
		ext.w	d0
		add.w	d3,d0		; add x-position
		andi.w	#$1FF,d0	; keep within 512px
		bne.s	@writeX
		addq.w	#1,d0

	@writeX:
		move.w	d0,(a2)+	; write to buffer
		dbf	d1,BuildSpr_Normal	; process next sprite piece

	@return:
		rts	
; End of function BuildSpr_Normal

; ===========================================================================

BuildSpr_FlipX:
		btst	#1,d4		; is object also y-flipped?
		bne.w	BuildSpr_FlipXY	; if yes, branch

	@loop:
		cmpi.b	#$50,d5		; check sprite limit
		beq.s	@return
		move.b	(a1)+,d0	; y position
		ext.w	d0
		add.w	d2,d0
		move.w	d0,(a2)+
		move.b	(a1)+,d4	; size
		move.b	d4,(a2)+	
		addq.b	#1,d5		; link
		move.b	d5,(a2)+
		move.b	(a1)+,d0	; art tile
		lsl.w	#8,d0
		move.b	(a1)+,d0	
		add.w	a3,d0
		eori.w	#$800,d0	; toggle flip-x in VDP
		move.w	d0,(a2)+	; write to buffer
		move.b	(a1)+,d0	; get x-offset
		ext.w	d0
		neg.w	d0			; negate it
		add.b	d4,d4		; calculate flipped position by size
		andi.w	#$18,d4
		addq.w	#8,d4
		sub.w	d4,d0
		add.w	d3,d0
		andi.w	#$1FF,d0	; keep within 512px
		bne.s	@writeX
		addq.w	#1,d0

	@writeX:
		move.w	d0,(a2)+	; write to buffer
		dbf	d1,@loop		; process next sprite piece

	@return:
		rts	
; ===========================================================================

BuildSpr_FlipY:
		cmpi.b	#$50,d5		; check sprite limit
		beq.s	@return
		move.b	(a1)+,d0	; get y-offset
		move.b	(a1),d4		; get size
		ext.w	d0
		neg.w	d0		; negate y-offset
		lsl.b	#3,d4	; calculate flip offset
		andi.w	#$18,d4
		addq.w	#8,d4
		sub.w	d4,d0
		add.w	d2,d0	; add y-position
		move.w	d0,(a2)+	; write to buffer
		move.b	(a1)+,(a2)+	; size
		addq.b	#1,d5
		move.b	d5,(a2)+	; link
		move.b	(a1)+,d0	; art tile
		lsl.w	#8,d0
		move.b	(a1)+,d0
		add.w	a3,d0
		eori.w	#$1000,d0	; toggle flip-y in VDP
		move.w	d0,(a2)+
		move.b	(a1)+,d0	; x-position
		ext.w	d0
		add.w	d3,d0
		andi.w	#$1FF,d0
		bne.s	@writeX
		addq.w	#1,d0

	@writeX:
		move.w	d0,(a2)+	; write to buffer
		dbf	d1,BuildSpr_FlipY	; process next sprite piece

	@return:
		rts
; ===========================================================================

BuildSpr_FlipXY:
		cmpi.b	#$50,d5		; check sprite limit
		beq.s	@return
		move.b	(a1)+,d0	; calculated flipped y
		move.b	(a1),d4
		ext.w	d0
		neg.w	d0
		lsl.b	#3,d4
		andi.w	#$18,d4
		addq.w	#8,d4
		sub.w	d4,d0
		add.w	d2,d0
		move.w	d0,(a2)+	; write to buffer
		move.b	(a1)+,d4	; size
		move.b	d4,(a2)+	; link
		addq.b	#1,d5
		move.b	d5,(a2)+	; art tile
		move.b	(a1)+,d0
		lsl.w	#8,d0
		move.b	(a1)+,d0
		add.w	a3,d0
		eori.w	#$1800,d0	; toggle flip-x/y in VDP
		move.w	d0,(a2)+
		move.b	(a1)+,d0	; calculate flipped x
		ext.w	d0
		neg.w	d0
		add.b	d4,d4
		andi.w	#$18,d4
		addq.w	#8,d4
		sub.w	d4,d0
		add.w	d3,d0
		andi.w	#$1FF,d0
		bne.s	@writeX
		addq.w	#1,d0

	@writeX:
		move.w	d0,(a2)+	; write to buffer
		dbf	d1,BuildSpr_FlipXY	; process next sprite piece

	@return:
		rts

		include	"_incObj\sub ChkObjectVisible.asm"

; ---------------------------------------------------------------------------
; Subroutine to	load a level's objects
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ObjPosLoad:
		moveq	#0,d0
		move.b	(v_opl_routine).w,d0
		jmp	OPL_Index(pc,d0.w)
; End of function ObjPosLoad

; ===========================================================================
OPL_Index:	bra.w   OPL_Main
		bra.w   OPL_Next
; ===========================================================================

OPL_Main:
		addq.b	#4,(v_opl_routine).w
		move.w	(v_zone).w,d0
		lsl.b	#6,d0
		lsr.w	#4,d0
		lea	(ObjPos_Index).l,a0
		movea.l	a0,a1
		adda.w	(a0,d0.w),a0
		move.l	a0,(v_opl_data).w
		move.l	a0,(v_opl_data+4).w
		adda.w	2(a1,d0.w),a1
		move.l	a1,(v_opl_data+8).w
		move.l	a1,(v_opl_data+$C).w
		lea	(v_objstate).w,a2
		move.w	#$101,(a2)+
		moveq   #0,d1
		moveq	#$5E,d0

OPL_ClrList:
		move.l	d1,(a2)+
		dbf	d0,OPL_ClrList	; clear	pre-destroyed object list

		lea	(v_objstate).w,a2
		moveq	#0,d2
		move.w	(v_screenposx).w,d6
		subi.w	#$80,d6
		bhs.s	loc_D93C
		moveq	#0,d6

loc_D93C:
		andi.w	#$FF80,d6
		movea.l	(v_opl_data).w,a0

loc_D944:
		cmp.w	(a0),d6
		bls.s	loc_D956
		tst.b	4(a0)
		bpl.s	loc_D952
		move.b	(a2),d2
		addq.b	#1,(a2)

loc_D952:
		addq.w	#6,a0
		bra.s	loc_D944
; ===========================================================================

loc_D956:
		move.l	a0,(v_opl_data).w
		movea.l	(v_opl_data+4).w,a0
		subi.w	#$80,d6
		blo.s	loc_D976

loc_D964:
		cmp.w	(a0),d6
		bls.s	loc_D976
		tst.b	4(a0)
		bpl.s	loc_D972
		addq.b	#1,1(a2)

loc_D972:
		addq.w	#6,a0
		bra.s	loc_D964
; ===========================================================================

loc_D976:
		move.l	a0,(v_opl_data+4).w
		move.w	#-1,(v_opl_screen).w

OPL_Next:
		lea	(v_objstate).w,a2
		moveq	#0,d2
		move.w	(v_screenposx).w,d6
		andi.w	#$FF80,d6
		cmp.w	(v_opl_screen).w,d6
		beq.w	locret_DA3A
		bge.s	loc_D9F6
		move.w	d6,(v_opl_screen).w
		movea.l	(v_opl_data+4).w,a0
		subi.w	#$80,d6
		blo.s	loc_D9D2

loc_D9A6:
		cmp.w	-6(a0),d6
		bge.s	loc_D9D2
		subq.w	#6,a0
		tst.b	4(a0)
		bpl.s	loc_D9BC
		subq.b	#1,1(a2)
		move.b	1(a2),d2

loc_D9BC:
		bsr.s	loc_DA3C
		bne.s	loc_D9C6
		subq.w	#6,a0
		bra.s	loc_D9A6
; ===========================================================================

loc_D9C6:
		tst.b	4(a0)
		bpl.s	loc_D9D0
		addq.b	#1,1(a2)

loc_D9D0:
		addq.w	#6,a0

loc_D9D2:
		move.l	a0,(v_opl_data+4).w
		movea.l	(v_opl_data).w,a0
		addi.w	#$300,d6

loc_D9DE:
		cmp.w	-6(a0),d6
		bgt.s	loc_D9F0
		tst.b	-2(a0)
		bpl.s	loc_D9EC
		subq.b	#1,(a2)

loc_D9EC:
		subq.w	#6,a0
		bra.s	loc_D9DE
; ===========================================================================

loc_D9F0:
		move.l	a0,(v_opl_data).w
		rts
; ===========================================================================

loc_D9F6:
		move.w	d6,(v_opl_screen).w
		movea.l	(v_opl_data).w,a0
		addi.w	#$280,d6

loc_DA02:
		cmp.w	(a0),d6
		bls.s	loc_DA16
		tst.b	4(a0)
		bpl.s	loc_DA10
		move.b	(a2),d2
		addq.b	#1,(a2)

loc_DA10:
		bsr.s	loc_DA3C
		beq.s	loc_DA02

loc_DA16:
		move.l	a0,(v_opl_data).w
		movea.l	(v_opl_data+4).w,a0
		subi.w	#$300,d6
		blo.s	loc_DA36

loc_DA24:
		cmp.w	(a0),d6
		bls.s	loc_DA36
		tst.b	4(a0)
		bpl.s	loc_DA32
		addq.b	#1,1(a2)

loc_DA32:
		addq.w	#6,a0
		bra.s	loc_DA24
; ===========================================================================

loc_DA36:
		move.l	a0,(v_opl_data+4).w

locret_DA3A:
		rts
; ===========================================================================

loc_DA3C:
		tst.b	4(a0)
		bpl.s	OPL_MakeItem
		bset	#7,2(a2,d2.w)
		beq.s	OPL_MakeItem
		addq.w	#6,a0
		moveq	#0,d0
		rts
; ===========================================================================

OPL_MakeItem:
		bsr.s	FindFreeObj
		bne.s	locret_DA8A
		move.w	(a0)+,obX(a1)
		move.w	(a0)+,d0
		move.w	d0,d1
		andi.w	#$FFF,d0
		move.w	d0,obY(a1)
		rol.w	#2,d1
		andi.b	#3,d1
		move.b	d1,obRender(a1)
		move.b	d1,obStatus(a1)
		move.b	(a0)+,d0
		bpl.s	loc_DA80
		andi.b	#$7F,d0
		move.b	d2,obRespawnNo(a1)

loc_DA80:
		move.b	d0,0(a1)
		move.b	(a0)+,obSubtype(a1)
		moveq	#0,d0

locret_DA8A:
		rts

		include	"_incObj\sub FindFreeObj.asm"
		include	"_incObj\41 Springs.asm"
		include	"_anim\Springs.asm"
Map_Spring:	include	"_maps\Springs.asm"

		include	"_incObj\42 Newtron.asm"
		include	"_anim\Newtron.asm"
Map_Newt:	include	"_maps\Newtron.asm"

		include	"_incObj\44 GHZ Edge Walls.asm"
Map_Edge:	include	"_maps\GHZ Edge Walls.asm"

		include	"_incObj\0D Signpost.asm" ; includes "GotThroughAct" subroutine
		include	"_anim\Signpost.asm"
Map_Sign:	include	"_maps\Signpost.asm"

		include	"_incObj\40 Moto Bug.asm" ; includes "_incObj\sub RememberState.asm"
		include	"_anim\Moto Bug.asm"
Map_Moto:	include	"_maps\Moto Bug.asm"

		include	"_incObj\sub SolidObject.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 01 - Sonic
; ---------------------------------------------------------------------------

SonicPlayer:
		tst.w	(v_debuguse).w	; is debug mode	being used?
		beq.s	Sonic_Normal	; if not, branch
		jmp	(DebugMode).l
; ===========================================================================

Sonic_Normal:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		move.w	Sonic_Index(pc,d0.w),d1
		jmp	Sonic_Index(pc,d1.w)
; ===========================================================================
Sonic_Index:	dc.w Sonic_Main-Sonic_Index
		dc.w Sonic_Control-Sonic_Index
		dc.w Sonic_Hurt-Sonic_Index
		dc.w Sonic_Death-Sonic_Index
		dc.w Sonic_ResetLevel-Sonic_Index
; ===========================================================================

Sonic_Main:	; Routine 0
		addq.b	#2,obRoutine(a0)
		move.b	#$13,obHeight(a0)
		move.b	#9,obWidth(a0)
		move.l	#Map_Sonic,obMap(a0)
		move.w	#$780,obGfx(a0)
		move.b	#2,obPriority(a0)
		move.b	#$18,obActWid(a0)
		move.b	#4,obRender(a0)
		move.w	#$600,(v_sonspeedmax).w ; Sonic's top speed
		move.w	#$C,(v_sonspeedacc).w ; Sonic's acceleration
		move.w	#$80,(v_sonspeeddec).w ; Sonic's deceleration

Sonic_Control:	; Routine 2
		tst.w	(f_debugmode).w	; is debug cheat enabled?
		beq.s	loc_12C58	; if not, branch
		btst	#bitB,(v_jpadpress1).w ; is button B pressed?
		beq.s	loc_12C58	; if not, branch
		move.w	#1,(v_debuguse).w ; change Sonic into a ring/item
		clr.b	(f_lockctrl).w
		rts
; ===========================================================================

loc_12C58:
		tst.b	(f_lockctrl).w	; are controls locked?
		bne.s	loc_12C64	; if yes, branch
		move.w	(v_jpadhold1).w,(v_jpadhold2).w ; enable joypad control

loc_12C64:
		btst	#0,(f_lockmulti).w ; are controls locked?
		bne.s	loc_12C7E	; if yes, branch
		moveq	#0,d0
		move.b	obStatus(a0),d0
		andi.w	#6,d0
		move.w	Sonic_Modes(pc,d0.w),d1
		jsr	Sonic_Modes(pc,d1.w)

loc_12C7E:
		bsr.s	Sonic_Display
		bsr.w	Sonic_RecordPosition
		move.b	(v_anglebuffer).w,$36(a0)
		move.b	($FFFFF76A).w,$37(a0)
		bsr.w	Sonic_Animate
		tst.b	(f_lockmulti).w
		bmi.s	loc_12CB6
		jsr	(ReactToItem).l

loc_12CB6:
		bsr.w	Sonic_Loops
		bra.w	Sonic_LoadGfx
; ===========================================================================
Sonic_Modes:	dc.w Sonic_MdNormal-Sonic_Modes
		dc.w Sonic_MdJump-Sonic_Modes
		dc.w Sonic_MdRoll-Sonic_Modes
		dc.w Sonic_MdJump-Sonic_Modes
; ---------------------------------------------------------------------------
; Music	to play	after invincibility wears off
; ---------------------------------------------------------------------------
MusicList2:
		dc.b bgm_GHZ
		even

		include	"_incObj\Sonic Display.asm"
		include	"_incObj\Sonic RecordPosition.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Modes	for controlling	Sonic
; ---------------------------------------------------------------------------

Sonic_MdNormal:
		bsr.w	Sonic_Jump
		bsr.w	Sonic_SlopeResist
		bsr.w	Sonic_Move
		bsr.w	Sonic_Roll
		bsr.w	Sonic_LevelBound
		jsr	(SpeedToPos).l
		bsr.w	Sonic_AnglePos
		bsr.w	Sonic_SlopeRepel
		rts
; ===========================================================================

Sonic_MdJump:
		bsr.w	Sonic_JumpHeight
		bsr.w	Sonic_JumpDirection
		bsr.w	Sonic_LevelBound
		jsr	(ObjectFall).l
		btst	#6,obStatus(a0)
		beq.s	loc_12E5C
		subi.w	#$28,obVelY(a0)

loc_12E5C:
		bsr.w	Sonic_JumpAngle
		bsr.w	Sonic_Floor
		rts
; ===========================================================================

Sonic_MdRoll:
		bsr.w	Sonic_Jump
		bsr.w	Sonic_RollRepel
		bsr.w	Sonic_RollSpeed
		bsr.w	Sonic_LevelBound
		jsr	(SpeedToPos).l
		bsr.w	Sonic_AnglePos
		bsr.w	Sonic_SlopeRepel
		rts

		include	"_incObj\Sonic Move.asm"
		include	"_incObj\Sonic RollSpeed.asm"
		include	"_incObj\Sonic JumpDirection.asm"
		include	"_incObj\Sonic LevelBound.asm"
		include	"_incObj\Sonic Roll.asm"
		include	"_incObj\Sonic Jump.asm"
		include	"_incObj\Sonic JumpHeight.asm"
		include	"_incObj\Sonic SlopeResist.asm"
		include	"_incObj\Sonic RollRepel.asm"
		include	"_incObj\Sonic SlopeRepel.asm"
		include	"_incObj\Sonic JumpAngle.asm"
		include	"_incObj\Sonic Floor.asm"
		include	"_incObj\Sonic ResetOnFloor.asm"
		include	"_incObj\Sonic (part 2).asm"
		include	"_incObj\Sonic Loops.asm"
		include	"_incObj\Sonic Animate.asm"
		include	"_anim\Sonic.asm"
		include	"_incObj\Sonic LoadGfx.asm"

		include	"_incObj\38 Shield and Invincibility.asm"
		include	"_anim\Shield and Invincibility.asm"
Map_Shield:	include	"_maps\Shield and Invincibility.asm"

		include	"_incObj\Sonic AnglePos.asm"

		include	"_incObj\sub FindNearestTile.asm"
		include	"_incObj\sub FindFloor.asm"
		include	"_incObj\sub FindWall.asm"


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_WalkSpeed:
		move.l	obX(a0),d3
		move.l	obY(a0),d2
		move.w	obVelX(a0),d1
		ext.l	d1
		asl.l	#8,d1
		add.l	d1,d3
		move.w	obVelY(a0),d1
		ext.l	d1
		asl.l	#8,d1
		add.l	d1,d2
		swap	d2
		swap	d3
		move.b	d0,(v_anglebuffer).w
		move.b	d0,($FFFFF76A).w
		move.b	d0,d1
		addi.b	#$20,d0
		bpl.s	loc_14D1A
		move.b	d1,d0
		bpl.s	loc_14D14
		subq.b	#1,d0

loc_14D14:
		addi.b	#$20,d0
		bra.s	loc_14D24
; ===========================================================================

loc_14D1A:
		move.b	d1,d0
		bpl.s	loc_14D20
		addq.b	#1,d0

loc_14D20:
		addi.b	#$1F,d0

loc_14D24:
		andi.b	#$C0,d0
		beq.w	loc_14DF0
		cmpi.b	#$80,d0
		beq.w	loc_14F7C
		andi.b	#$38,d1
		bne.s	loc_14D3C
		addq.w	#8,d2

loc_14D3C:
		cmpi.b	#$40,d0
		beq.w	loc_1504A
		bra.w	loc_14EBC

; End of function Sonic_WalkSpeed


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_14D48:
		move.b	d0,(v_anglebuffer).w
		move.b	d0,($FFFFF76A).w
		addi.b	#$20,d0
		andi.b	#$C0,d0
		cmpi.b	#$40,d0
		beq.w	loc_14FD6
		cmpi.b	#$80,d0
		beq.w	Sonic_DontRunOnWalls
		cmpi.b	#$C0,d0
		beq.w	sub_14E50

; End of function sub_14D48

; ---------------------------------------------------------------------------
; Subroutine to	make Sonic land	on the floor after jumping
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_HitFloor:
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obHeight(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	obWidth(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(v_anglebuffer).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$D,d5
		bsr.w	FindFloor
		move.w	d1,-(sp)
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obHeight(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	obWidth(a0),d0
		ext.w	d0
		sub.w	d0,d3
		lea	($FFFFF76A).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$D,d5
		bsr.w	FindFloor
		move.w	(sp)+,d0
		move.b	#0,d2

loc_14DD0:
		move.b	($FFFFF76A).w,d3
		cmp.w	d0,d1
		ble.s	loc_14DDE
		move.b	(v_anglebuffer).w,d3
		exg	d0,d1

loc_14DDE:
		btst	#0,d3
		beq.s	locret_14DE6
		move.b	d2,d3

locret_14DE6:
		rts

; End of function Sonic_HitFloor

; ===========================================================================

loc_14DF0:
		addi.w	#$A,d2
		lea	(v_anglebuffer).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$E,d5
		bsr.w	FindFloor
		move.b	#0,d2

loc_14E0A:
		move.b	(v_anglebuffer).w,d3
		btst	#0,d3
		beq.s	locret_14E16
		move.b	d2,d3

locret_14E16:
		rts

		include	"_incObj\sub ObjFloorDist.asm"


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_14E50:
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obWidth(a0),d0
		ext.w	d0
		sub.w	d0,d2
		move.b	obHeight(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(v_anglebuffer).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$E,d5
		bsr.w	FindWall
		move.w	d1,-(sp)
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obWidth(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	obHeight(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	($FFFFF76A).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$E,d5
		bsr.w	FindWall
		move.w	(sp)+,d0
		move.b	#-$40,d2
		bra.w	loc_14DD0

; End of function sub_14E50


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_14EB4:
		move.w	obY(a0),d2
		move.w	obX(a0),d3

loc_14EBC:
		addi.w	#$A,d3
		lea	(v_anglebuffer).w,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$E,d5
		bsr.w	FindWall
		move.b	#-$40,d2
		bra.w	loc_14E0A

; End of function sub_14EB4

; ---------------------------------------------------------------------------
; Subroutine to	detect when an object hits a wall to its right
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ObjHitWallRight:
		add.w	obX(a0),d3
		move.w	obY(a0),d2
		lea	(v_anglebuffer).w,a4
		move.b	#0,(a4)
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$E,d5
		bsr.w	FindWall
		move.b	(v_anglebuffer).w,d3
		btst	#0,d3
		beq.s	locret_14F06
		move.b	#-$40,d3

locret_14F06:
		rts

; End of function ObjHitWallRight

; ---------------------------------------------------------------------------
; Subroutine preventing	Sonic from running on walls and	ceilings when he
; touches them
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_DontRunOnWalls:
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obHeight(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	obWidth(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	(v_anglebuffer).w,a4
		movea.w	#-$10,a3
		move.w	#$1000,d6
		moveq	#$E,d5
		bsr.w	FindFloor
		move.w	d1,-(sp)
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obHeight(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	obWidth(a0),d0
		ext.w	d0
		sub.w	d0,d3
		lea	($FFFFF76A).w,a4
		movea.w	#-$10,a3
		move.w	#$1000,d6
		moveq	#$E,d5
		bsr.w	FindFloor
		move.w	(sp)+,d0
		move.b	#-$80,d2
		bra.w	loc_14DD0
; End of function Sonic_DontRunOnWalls

; ===========================================================================

loc_14F7C:
		subi.w	#$A,d2
		eori.w	#$F,d2
		lea	(v_anglebuffer).w,a4
		movea.w	#-$10,a3
		move.w	#$1000,d6
		moveq	#$E,d5
		bsr.w	FindFloor
		move.b	#-$80,d2
		bra.w	loc_14E0A

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ObjHitCeiling:
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obHeight(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		lea	(v_anglebuffer).w,a4
		movea.w	#-$10,a3
		move.w	#$1000,d6
		moveq	#$E,d5
		bsr.w	FindFloor
		move.b	(v_anglebuffer).w,d3
		btst	#0,d3
		beq.s	locret_14FD4
		move.b	#-$80,d3

locret_14FD4:
		rts
; End of function ObjHitCeiling

; ===========================================================================

loc_14FD6:
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obWidth(a0),d0
		ext.w	d0
		sub.w	d0,d2
		move.b	obHeight(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	(v_anglebuffer).w,a4
		movea.w	#-$10,a3
		move.w	#$800,d6
		moveq	#$E,d5
		bsr.w	FindWall
		move.w	d1,-(sp)
		move.w	obY(a0),d2
		move.w	obX(a0),d3
		moveq	#0,d0
		move.b	obWidth(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	obHeight(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	($FFFFF76A).w,a4
		movea.w	#-$10,a3
		move.w	#$800,d6
		moveq	#$E,d5
		bsr.w	FindWall
		move.w	(sp)+,d0
		move.b	#$40,d2
		bra.w	loc_14DD0

; ---------------------------------------------------------------------------
; Subroutine to	stop Sonic when	he jumps at a wall
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_HitWall:
		move.w	obY(a0),d2
		move.w	obX(a0),d3

loc_1504A:
		subi.w	#$A,d3
		eori.w	#$F,d3
		lea	(v_anglebuffer).w,a4
		movea.w	#-$10,a3
		move.w	#$800,d6
		moveq	#$E,d5
		bsr.w	FindWall
		move.b	#$40,d2
		bra.w	loc_14E0A
; End of function Sonic_HitWall

; ---------------------------------------------------------------------------
; Subroutine to	detect when an object hits a wall to its left
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ObjHitWallLeft:
		add.w	obX(a0),d3
		move.w	obY(a0),d2
		eori.w	#$F,d3
		lea	(v_anglebuffer).w,a4
		move.b	#0,(a4)
		movea.w	#-$10,a3
		move.w	#$800,d6
		moveq	#$E,d5
		bsr.w	FindWall
		move.b	(v_anglebuffer).w,d3
		btst	#0,d3
		beq.s	locret_15098
		move.b	#$40,d3

locret_15098:
		rts
; End of function ObjHitWallLeft

; ===========================================================================

		include	"_incObj\79 Lamppost.asm"
Map_Lamp:	include	"_maps\Lamppost.asm"
		include	"_incObj\7D Hidden Bonuses.asm"
Map_Bonus:	include	"_maps\Hidden Bonuses.asm"

		include	"_incObj\3D Boss - Green Hill (part 1).asm"

; ---------------------------------------------------------------------------
; Defeated boss	subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


BossDefeated:
		move.b	(v_vbla_byte).w,d0
		andi.b	#7,d0
		bne.s	locret_178A2
		jsr	(FindFreeObj).l
		bne.s	locret_178A2
		move.b	#id_ExplosionBomb,0(a1)	; load explosion object
		move.w	obX(a0),obX(a1)
		move.w	obY(a0),obY(a1)
		jsr	(RandomNumber).l
		move.w	d0,d1
		moveq	#0,d1
		move.b	d0,d1
		lsr.b	#2,d1
		subi.w	#$20,d1
		add.w	d1,obX(a1)
		lsr.w	#8,d0
		lsr.b	#3,d0
		add.w	d0,obY(a1)

locret_178A2:
		rts
; End of function BossDefeated

; ---------------------------------------------------------------------------
; Subroutine to	move a boss
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


BossMove:
		move.w	obVelX(a0),d0
		ext.l	d0
		lsl.l	#8,d0
		add.l	d0,$30(a0)
		move.w	obVelY(a0),d0
		ext.l	d0
		lsl.l	#8,d0
		add.l	d0,$38(a0)
		rts
; End of function BossMove

; ===========================================================================

		include	"_incObj\3D Boss - Green Hill (part 2).asm"
		include	"_incObj\48 Eggman's Swinging Ball.asm"
		include	"_anim\Eggman.asm"
Map_Eggman:	include	"_maps\Eggman.asm"
Map_BossItems:	include	"_maps\Boss Items.asm"

		include	"_incObj\3E Prison Capsule.asm"
		include	"_anim\Prison Capsule.asm"
Map_Pri:	include	"_maps\Prison Capsule.asm"

		include	"_incObj\sub ReactToItem.asm"

		include	"_inc\AnimateLevelGfx.asm"

		include	"_incObj\21 HUD.asm"
Map_HUD:	include	"_maps\HUD.asm"

; ---------------------------------------------------------------------------
; Add points subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


AddPoints:
		move.b	#1,(f_scorecount).w ; set score counter to update
		lea     (v_score).w,a3
		add.l   d0,(a3)
		move.l  #999999,d1
		cmp.l   (a3),d1 ; is score below 999999?
		bhi.s   @belowmax ; if yes, branch
		move.l  d1,(a3) ; reset score to 999999
@belowmax:
		move.l  (a3),d0
		cmp.l   (v_scorelife).w,d0 ; has Sonic got 50000+ points?
		blo.s   @noextralife ; if not, branch

		addi.l  #5000,(v_scorelife).w ; increase requirement by 50000
		tst.b   (v_megadrive).w
		bmi.s   @noextralife ; branch if Mega Drive is Japanese
		addq.b  #1,(v_lives).w ; give extra life
		addq.b  #1,(f_lifecount).w
		move.w	#bgm_ExtraLife,d0
		jmp	(PlaySound).l

@noextralife:
		rts
; End of function AddPoints

		include	"_inc\HUD_Update.asm"

		include	"_inc\HUD (part 2).asm"

Art_Hud:	incbin	"artunc\HUD Numbers.bin" ; 8x16 pixel numbers on HUD
		even
Art_LivesNums:	incbin	"artunc\Lives Counter Numbers.bin" ; 8x8 pixel numbers on lives counter
		even

		include	"_incObj\DebugMode.asm"
		include	"_inc\DebugList.asm"
		include	"_inc\LevelHeaders.asm"
		include	"_inc\Pattern Load Cues.asm"

Nem_SegaLogo:	incbin	"artnem\Sega Logo.nem" ; large Sega logo
		even
Eni_SegaLogo:	incbin	"tilemaps\Sega Logo.eni" ; large Sega logo (mappings)
		even
Eni_Title:	incbin	"tilemaps\Title Screen.eni" ; title screen foreground (mappings)
		even
Nem_TitleFg:	incbin	"artnem\Title Screen Foreground.nem"
		even
Nem_TitleSonic:	incbin	"artnem\Title Screen Sonic.nem"
		even
Nem_TitleTM:	incbin	"artnem\Title Screen TM.nem"
		even

Map_Sonic:	include	"_maps\Sonic.asm"
SonicDynPLC:	include	"_maps\Sonic - Dynamic Gfx Script.asm"

; ---------------------------------------------------------------------------
; Uncompressed graphics	- Sonic
; ---------------------------------------------------------------------------
Art_Sonic:	incbin	"artunc\Sonic.bin"	; Sonic
		even
; ---------------------------------------------------------------------------
; Compressed graphics - various
; ---------------------------------------------------------------------------
Nem_Shield:	incbin	"artnem\Shield.nem"
		even
Nem_Stars:	incbin	"artnem\Invincibility Stars.nem"
		even
; ---------------------------------------------------------------------------
; Compressed graphics - GHZ stuff
; ---------------------------------------------------------------------------
Nem_Stalk:	incbin	"artnem\GHZ Flower Stalk.nem"
		even
Nem_Swing:	incbin	"artnem\GHZ Swinging Platform.nem"
		even
Nem_Bridge:	incbin	"artnem\GHZ Bridge.nem"
		even
Nem_Ball:	incbin	"artnem\GHZ Giant Ball.nem"
		even
Nem_Spikes:	incbin	"artnem\Spikes.nem"
		even
Nem_SpikePole:	incbin	"artnem\GHZ Spiked Log.nem"
		even
Nem_PplRock:	incbin	"artnem\GHZ Purple Rock.nem"
		even
Nem_GhzWall1:	incbin	"artnem\GHZ Breakable Wall.nem"
		even
Nem_GhzWall2:	incbin	"artnem\GHZ Edge Wall.nem"
		even
; ---------------------------------------------------------------------------
; Compressed graphics - enemies
; ---------------------------------------------------------------------------
Nem_Crabmeat:	incbin	"artnem\Enemy Crabmeat.nem"
		even
Nem_Buzz:	incbin	"artnem\Enemy Buzz Bomber.nem"
		even
Nem_Chopper:	incbin	"artnem\Enemy Chopper.nem"
		even
Nem_Motobug:	incbin	"artnem\Enemy Motobug.nem"
		even
Nem_Newtron:	incbin	"artnem\Enemy Newtron.nem"
		even
; ---------------------------------------------------------------------------
; Compressed graphics - various
; ---------------------------------------------------------------------------
Nem_TitleCard:	incbin	"artnem\Title Cards.nem"
		even
Nem_Hud:	incbin	"artnem\HUD.nem"	; HUD (rings, time, score)
		even
Nem_Lives:	incbin	"artnem\HUD - Life Counter Icon.nem"
		even
Nem_Ring:	incbin	"artnem\Rings.nem"
		even
Nem_Monitors:	incbin	"artnem\Monitors.nem"
		even
Nem_Explode:	incbin	"artnem\Explosion.nem"
		even
Nem_Points:	incbin	"artnem\Points.nem"	; points from destroyed enemy or object
		even
Nem_GameOver:	incbin	"artnem\Game Over.nem"	; game over / time over
		even
Nem_HSpring:	incbin	"artnem\Spring Horizontal.nem"
		even
Nem_VSpring:	incbin	"artnem\Spring Vertical.nem"
		even
Nem_SignPost:	incbin	"artnem\Signpost.nem"	; end of level signpost
		even
Nem_Lamp:	incbin	"artnem\Lamppost.nem"
		even
Nem_BigFlash:	incbin	"artnem\Giant Ring Flash.nem"
		even
Nem_Bonus:	incbin	"artnem\Hidden Bonuses.nem" ; hidden bonuses at end of a level
		even
; ---------------------------------------------------------------------------
; Compressed graphics - animals
; ---------------------------------------------------------------------------
Nem_Rabbit:	incbin	"artnem\Animal Rabbit.nem"
		even
Nem_Chicken:	incbin	"artnem\Animal Chicken.nem"
		even
Nem_BlackBird:	incbin	"artnem\Animal Blackbird.nem"
		even
Nem_Seal:	incbin	"artnem\Animal Seal.nem"
		even
Nem_Pig:	incbin	"artnem\Animal Pig.nem"
		even
Nem_Flicky:	incbin	"artnem\Animal Flicky.nem"
		even
Nem_Squirrel:	incbin	"artnem\Animal Squirrel.nem"
		even
; ---------------------------------------------------------------------------
; Compressed graphics - primary patterns and block mappings
; ---------------------------------------------------------------------------
Blk16_GHZ:	incbin	"map16\GHZ.eni"
		even
Nem_GHZ_1st:	incbin	"artnem\8x8 - GHZ1.nem"	; GHZ primary patterns
		even
Nem_GHZ_2nd:	incbin	"artnem\8x8 - GHZ2.nem"	; GHZ secondary patterns
		even
Blk256_GHZ:	incbin	"map256\GHZ.kos"
		even
; ---------------------------------------------------------------------------
; Compressed graphics - bosses and ending sequence
; ---------------------------------------------------------------------------
Nem_Eggman:	incbin	"artnem\Boss - Main.nem"
		even
Nem_Weapons:	incbin	"artnem\Boss - Weapons.nem"
		even
Nem_Prison:	incbin	"artnem\Prison Capsule.nem"
		even
Nem_Exhaust:	incbin	"artnem\Boss - Exhaust Flame.nem"
		even
; ---------------------------------------------------------------------------
; Collision data
; ---------------------------------------------------------------------------
AngleMap:	incbin	"collide\Angle Map.bin"
		even
CollArray1:	incbin	"collide\Collision Array (Normal).bin"
		even
CollArray2:	incbin	"collide\Collision Array (Rotated).bin"
		even
Col_GHZ:	incbin	"collide\GHZ.bin"	; GHZ index
		even
; ---------------------------------------------------------------------------
; Animated uncompressed graphics
; ---------------------------------------------------------------------------
Art_GhzWater:	incbin	"artunc\GHZ Waterfall.bin"
		even
Art_GhzFlower1:	incbin	"artunc\GHZ Flower Large.bin"
		even
Art_GhzFlower2:	incbin	"artunc\GHZ Flower Small.bin"
		even

; ---------------------------------------------------------------------------
; Level	layout index
; ---------------------------------------------------------------------------
Level_Index:
		; GHZ
		dc.w Level_GHZ1-Level_Index, Level_GHZbg-Level_Index, byte_68F88-Level_Index
		dc.w Level_GHZ2-Level_Index, Level_GHZbg-Level_Index, byte_68F88-Level_Index
		dc.w Level_GHZ3-Level_Index, Level_GHZbg-Level_Index, byte_68F88-Level_Index
		dc.w byte_68F88-Level_Index, byte_68F88-Level_Index, byte_68F88-Level_Index

Level_GHZ1:	incbin	"levels\ghz1.bin"
		even
Level_GHZ2:	incbin	"levels\ghz2.bin"
		even
Level_GHZ3:	incbin	"levels\ghz3.bin"
		even
Level_GHZbg:	incbin	"levels\ghzbg.bin"
		even
byte_68F88:	dc.l 0

Art_BigRing:	incbin	"artunc\Giant Ring.bin"
		even

; ---------------------------------------------------------------------------
; Sprite locations index
; ---------------------------------------------------------------------------
ObjPos_Index:
		; GHZ
		dc.w ObjPos_GHZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_GHZ2-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_GHZ3-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_GHZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.b $FF, $FF, 0, 0, 0,	0
ObjPos_GHZ1:	incbin	"objpos\ghz1.bin"
		even
ObjPos_GHZ2:	incbin	"objpos\ghz2.bin"
		even
ObjPos_GHZ3:	incbin	"objpos\ghz3.bin"
		even
ObjPos_Null:	dc.b $FF, $FF, 0, 0, 0,	0

SoundDriver:	include "s1.sounddriver.asm"

; end of 'ROM'
		even
EndOfRom:


		END
