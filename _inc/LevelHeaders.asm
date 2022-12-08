; ---------------------------------------------------------------------------
; Level Headers
; ---------------------------------------------------------------------------

LevelHeaders:

lhead:	macro plc1,lvlgfx,plc2,sixteen,twofivesix,pal
	dc.l (plc1<<24)+lvlgfx
	dc.l (plc2<<24)+sixteen
	dc.l twofivesix
	dc.b pal
	endm

; 1st PLC, level gfx, 2nd PLC, 16x16 data, 256x256 data, palette

;		1st PLC				2nd PLC				256x256 data	palette
;				level gfx*			16x16 data

	lhead	plcid_GHZ,	Nem_GHZ_2nd,	plcid_GHZ2,	Blk16_GHZ,	Blk256_GHZ,	palid_GHZ	; Green Hill
	even