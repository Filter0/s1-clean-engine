; ---------------------------------------------------------------------------
; Subroutine to display Sonic and set music
; ---------------------------------------------------------------------------

Sonic_Display:
		move.w	flashtime(a0),d0
		beq.s	@display
		subq.w	#1,flashtime(a0)
		lsr.w	#3,d0
		bcc.s	@chkinvincible

	@display:
		jsr	DisplaySprite(pc)

	@chkinvincible:
		tst.b	(v_invinc).w	; does Sonic have invincibility?
		beq.s	@chkshoes	; if not, branch
		tst.w	invtime(a0)	; check	time remaining for invinciblity
		beq.s	@chkshoes	; if no	time remains, branch
		subq.w	#1,invtime(a0)	; subtract 1 from time
		bne.s	@chkshoes
		tst.b	(f_lockscreen).w
		bne.s	@removeinvincible
		cmpi.w	#$C,(v_air).w
		bcs.s	@removeinvincible
		moveq	#0,d0
		move.b	(v_zone).w,d0
		lea	MusicList2(pc),a1
		move.b	(a1,d0.w),d0
		bsr.w	PlaySound	; play normal music

	@removeinvincible:
		clr.b	(v_invinc).w ; cancel invincibility

	@chkshoes:
		tst.b	(v_shoes).w	; does Sonic have speed	shoes?
		beq.s	@exit		; if not, branch
		tst.w	shoetime(a0)	; check	time remaining
		beq.s	@exit
		subq.w	#1,shoetime(a0)	; subtract 1 from time
		bne.s	@exit
		move.w	#$600,(v_sonspeedmax).w ; restore Sonic's speed
		move.w	#$C,(v_sonspeedacc).w ; restore Sonic's acceleration
		move.w	#$80,(v_sonspeeddec).w ; restore Sonic's deceleration
		clr.b	(v_shoes).w	; cancel speed shoes
		move.w	#bgm_Slowdown,d0
		bra.w	PlaySound	; run music at normal speed

	@exit:
		rts	