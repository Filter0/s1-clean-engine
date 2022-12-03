; ---------------------------------------------------------------------------
; Palette pointers
; ---------------------------------------------------------------------------

palp:	macro paladdress,ramaddress,colours
	dc.l paladdress
	dc.w ramaddress, (colours>>1)-1
	endm

PalPointers:

; palette address, RAM address, colours

ptr_Pal_SegaBG:		palp	Pal_SegaBG,v_pal_dry,$40		; 0 - Sega logo
ptr_Pal_Title:		palp	Pal_Title,v_pal_dry,$40		; 1 - title screen
ptr_Pal_LevelSel:	palp	Pal_LevelSel,v_pal_dry,$40		; 2 - level select
ptr_Pal_Sonic:		palp	Pal_Sonic,v_pal_dry,$10		; 3 - Sonic
Pal_Levels:
ptr_Pal_GHZ:		palp	Pal_GHZ,v_pal_dry+$20, $30		; 4 - GHZ
			even


palid_SegaBG:		equ (ptr_Pal_SegaBG-PalPointers)/8
palid_Title:		equ (ptr_Pal_Title-PalPointers)/8
palid_LevelSel:		equ (ptr_Pal_LevelSel-PalPointers)/8
palid_Sonic:		equ (ptr_Pal_Sonic-PalPointers)/8
palid_GHZ:		equ (ptr_Pal_GHZ-PalPointers)/8
palid_LZ:		equ (ptr_Pal_LZ-PalPointers)/8
palid_MZ:		equ (ptr_Pal_MZ-PalPointers)/8
palid_SLZ:		equ (ptr_Pal_SLZ-PalPointers)/8
palid_SYZ:		equ (ptr_Pal_SYZ-PalPointers)/8
palid_SBZ1:		equ (ptr_Pal_SBZ1-PalPointers)/8
palid_Special:		equ (ptr_Pal_Special-PalPointers)/8
palid_LZWater:		equ (ptr_Pal_LZWater-PalPointers)/8
palid_SBZ3:		equ (ptr_Pal_SBZ3-PalPointers)/8
palid_SBZ3Water:	equ (ptr_Pal_SBZ3Water-PalPointers)/8
palid_SBZ2:		equ (ptr_Pal_SBZ2-PalPointers)/8
palid_LZSonWater:	equ (ptr_Pal_LZSonWater-PalPointers)/8
palid_SBZ3SonWat:	equ (ptr_Pal_SBZ3SonWat-PalPointers)/8
palid_SSResult:		equ (ptr_Pal_SSResult-PalPointers)/8
palid_Continue:		equ (ptr_Pal_Continue-PalPointers)/8
palid_Ending:		equ (ptr_Pal_Ending-PalPointers)/8
