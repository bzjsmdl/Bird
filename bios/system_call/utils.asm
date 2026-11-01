bits 32
wait_inbuf_empty:
	in al, 0x64
	test al, 2
	jnz wait_inbuf_empty
	ret
	
wait_outbuf_full:
	in al, 0x64
	test al, 1
	jz wait_outbuf_full
	ret