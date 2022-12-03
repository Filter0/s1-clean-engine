; ---------------------------------------------------------------------------
; Sonic start location array
; ---------------------------------------------------------------------------

		incbin	"startpos\ghz1.bin"
		incbin	"startpos\ghz2.bin"
		incbin	"startpos\ghz3.bin"
		dc.w	$80,$A8

		even
