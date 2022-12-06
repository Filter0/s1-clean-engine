; ---------------------------------------------------------------------------
; Pattern load cues
; ---------------------------------------------------------------------------
ArtLoadCues:

ptr_PLC_Main:		dc.w PLC_Main-ArtLoadCues
ptr_PLC_Main2:		dc.w PLC_Main2-ArtLoadCues
ptr_PLC_Explode:	dc.w PLC_Explode-ArtLoadCues
ptr_PLC_GameOver:	dc.w PLC_GameOver-ArtLoadCues
PLC_Levels:
ptr_PLC_GHZ:		dc.w PLC_GHZ-ArtLoadCues
ptr_PLC_GHZ2:		dc.w PLC_GHZ2-ArtLoadCues

ptr_PLC_TitleCard:	dc.w PLC_TitleCard-ArtLoadCues
ptr_PLC_Boss:		dc.w PLC_Boss-ArtLoadCues
ptr_PLC_Signpost:	dc.w PLC_Signpost-ArtLoadCues
PLC_Animals:
ptr_PLC_GHZAnimals:	dc.w PLC_GHZAnimals-ArtLoadCues

plcm:	macro gfx,vram
	dc.l gfx
	dc.w vram
	endm

; ---------------------------------------------------------------------------
; Pattern load cues - standard block 1
; ---------------------------------------------------------------------------
PLC_Main:	dc.w ((PLC_Mainend-PLC_Main-2)/6)-1
		plcm	Nem_Lamp, $F400		; lamppost
		plcm	Nem_Hud, $D940		; HUD
		plcm	Nem_Lives, $FA80	; lives	counter
		plcm	Nem_Ring, $F640 	; rings
		plcm	Nem_Points, $F2E0	; points from enemy
	PLC_Mainend:
; ---------------------------------------------------------------------------
; Pattern load cues - standard block 2
; ---------------------------------------------------------------------------
PLC_Main2:	dc.w ((PLC_Main2end-PLC_Main2-2)/6)-1
		plcm	Nem_Monitors, $D000	; monitors
		plcm	Nem_Shield, $A820	; shield
		plcm	Nem_Stars, $AB80	; invincibility	stars
	PLC_Main2end:
; ---------------------------------------------------------------------------
; Pattern load cues - explosion
; ---------------------------------------------------------------------------
PLC_Explode:	dc.w ((PLC_Explodeend-PLC_Explode-2)/6)-1
		plcm	Nem_Explode, $B400	; explosion
	PLC_Explodeend:
; ---------------------------------------------------------------------------
; Pattern load cues - game/time	over
; ---------------------------------------------------------------------------
PLC_GameOver:	dc.w ((PLC_GameOverend-PLC_GameOver-2)/6)-1
		plcm	Nem_GameOver, $ABC0	; game/time over
	PLC_GameOverend:
; ---------------------------------------------------------------------------
; Pattern load cues - Green Hill
; ---------------------------------------------------------------------------
PLC_GHZ:	dc.w ((PLC_GHZ2-PLC_GHZ-2)/6)-1
		plcm	Nem_Stalk, $6B00	; flower stalk
		plcm	Nem_PplRock, $7A00	; purple rock
		plcm	Nem_Crabmeat, $8000	; crabmeat enemy
		plcm	Nem_Buzz, $8880		; buzz bomber enemy
		plcm	Nem_Chopper, $8F60	; chopper enemy
		plcm	Nem_Newtron, $9360	; newtron enemy
		plcm	Nem_Motobug, $9E00	; motobug enemy
		plcm	Nem_Spikes, $A360	; spikes
		plcm	Nem_HSpring, $A460	; horizontal spring
		plcm	Nem_VSpring, $A660	; vertical spring

PLC_GHZ2:	dc.w ((PLC_GHZ2end-PLC_GHZ2-2)/6)-1
		plcm	Nem_Swing, $7000	; swinging platform
		plcm	Nem_Bridge, $71C0	; bridge
		plcm	Nem_SpikePole, $7300	; spiked pole
		plcm	Nem_Ball, $7540		; giant	ball
		plcm	Nem_GhzWall1, $A1E0	; breakable wall
		plcm	Nem_GhzWall2, $6980	; normal wall
	PLC_GHZ2end:
; ---------------------------------------------------------------------------
; Pattern load cues - title card
; ---------------------------------------------------------------------------
PLC_TitleCard:	dc.w ((PLC_TitleCardend-PLC_TitleCard-2)/6)-1
		plcm	Nem_TitleCard, $B000
	PLC_TitleCardend:
; ---------------------------------------------------------------------------
; Pattern load cues - act 3 boss
; ---------------------------------------------------------------------------
PLC_Boss:	dc.w ((PLC_Bossend-PLC_Boss-2)/6)-1
		plcm	Nem_Eggman, $8000	; Eggman main patterns
		plcm	Nem_Weapons, $8D80	; Eggman's weapons
		plcm	Nem_Prison, $93A0	; prison capsule
		plcm	Nem_Exhaust, $A540	; exhaust flame
	PLC_Bossend:
; ---------------------------------------------------------------------------
; Pattern load cues - act 1/2 signpost
; ---------------------------------------------------------------------------
PLC_Signpost:	dc.w ((PLC_Signpostend-PLC_Signpost-2)/6)-1
		plcm	Nem_SignPost, $D000	; signpost
		plcm	Nem_Bonus, $96C0	; hidden bonus points
		plcm	Nem_BigFlash, $8C40	; giant	ring flash effect
	PLC_Signpostend:
; ---------------------------------------------------------------------------
; Pattern load cues - GHZ animals
; ---------------------------------------------------------------------------
PLC_GHZAnimals:	dc.w ((PLC_GHZAnimalsend-PLC_GHZAnimals-2)/6)-1
		plcm	Nem_Rabbit, $B000	; rabbit
		plcm	Nem_Flicky, $B240	; flicky
	PLC_GHZAnimalsend:
		even

; ---------------------------------------------------------------------------
; Pattern load cue IDs
; ---------------------------------------------------------------------------
plcid_Main:		equ (ptr_PLC_Main-ArtLoadCues)/2	; 0
plcid_Main2:		equ (ptr_PLC_Main2-ArtLoadCues)/2	; 1
plcid_Explode:		equ (ptr_PLC_Explode-ArtLoadCues)/2	; 2
plcid_GameOver:		equ (ptr_PLC_GameOver-ArtLoadCues)/2	; 3
plcid_GHZ:		equ (ptr_PLC_GHZ-ArtLoadCues)/2		; 4
plcid_GHZ2:		equ (ptr_PLC_GHZ2-ArtLoadCues)/2	; 5
plcid_LZ:		equ (ptr_PLC_LZ-ArtLoadCues)/2		; 6
plcid_LZ2:		equ (ptr_PLC_LZ2-ArtLoadCues)/2		; 7
plcid_MZ:		equ (ptr_PLC_MZ-ArtLoadCues)/2		; 8
plcid_MZ2:		equ (ptr_PLC_MZ2-ArtLoadCues)/2		; 9
plcid_SLZ:		equ (ptr_PLC_SLZ-ArtLoadCues)/2		; $A
plcid_SLZ2:		equ (ptr_PLC_SLZ2-ArtLoadCues)/2	; $B
plcid_SYZ:		equ (ptr_PLC_SYZ-ArtLoadCues)/2		; $C
plcid_SYZ2:		equ (ptr_PLC_SYZ2-ArtLoadCues)/2	; $D
plcid_SBZ:		equ (ptr_PLC_SBZ-ArtLoadCues)/2		; $E
plcid_SBZ2:		equ (ptr_PLC_SBZ2-ArtLoadCues)/2	; $F
plcid_TitleCard:	equ (ptr_PLC_TitleCard-ArtLoadCues)/2	; $10
plcid_Boss:		equ (ptr_PLC_Boss-ArtLoadCues)/2	; $11
plcid_Signpost:		equ (ptr_PLC_Signpost-ArtLoadCues)/2	; $12
plcid_Warp:		equ (ptr_PLC_Warp-ArtLoadCues)/2	; $13
plcid_SpecialStage:	equ (ptr_PLC_SpecialStage-ArtLoadCues)/2 ; $14
plcid_GHZAnimals:	equ (ptr_PLC_GHZAnimals-ArtLoadCues)/2	; $15
plcid_LZAnimals:	equ (ptr_PLC_LZAnimals-ArtLoadCues)/2	; $16
plcid_MZAnimals:	equ (ptr_PLC_MZAnimals-ArtLoadCues)/2	; $17
plcid_SLZAnimals:	equ (ptr_PLC_SLZAnimals-ArtLoadCues)/2	; $18
plcid_SYZAnimals:	equ (ptr_PLC_SYZAnimals-ArtLoadCues)/2	; $19
plcid_SBZAnimals:	equ (ptr_PLC_SBZAnimals-ArtLoadCues)/2	; $1A
plcid_SSResult:		equ (ptr_PLC_SSResult-ArtLoadCues)/2	; $1B
plcid_Ending:		equ (ptr_PLC_Ending-ArtLoadCues)/2	; $1C
plcid_TryAgain:		equ (ptr_PLC_TryAgain-ArtLoadCues)/2	; $1D
plcid_EggmanSBZ2:	equ (ptr_PLC_EggmanSBZ2-ArtLoadCues)/2	; $1E
plcid_FZBoss:		equ (ptr_PLC_FZBoss-ArtLoadCues)/2	; $1F