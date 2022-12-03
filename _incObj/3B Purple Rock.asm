; ---------------------------------------------------------------------------
; Object 3B - purple rock (GHZ)
; ---------------------------------------------------------------------------

PurpleRock:
		moveq	#0,d0
		move.b	obRoutine(a0),d0
		jmp	Rock_Index(pc,d0.w)
; ===========================================================================
Rock_Index:	bra.w   Rock_Main
		bra.w   Rock_Solid
; ===========================================================================

Rock_Main:	; Routine 0
		addq.b	#4,obRoutine(a0)
		move.l	#Map_PRock,obMap(a0)
		move.w	#$63D0,obGfx(a0)
		move.b	#4,obRender(a0)
		move.b	#$13,obActWid(a0)
		move.b	#4,obPriority(a0)

Rock_Solid:	; Routine 2
		moveq	#$1B,d1
		moveq	#$10,d2
		moveq	#$10,d3
		move.w	obX(a0),d4
		bsr.w	SolidObject
		out_of_range.w	DeleteObject
		bra.w	DisplaySprite