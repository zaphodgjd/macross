
;***************************************************************************
;*
;* LZSS File System
;*
;* (c) Copyright 1990 Graeme Devine
;*
;* Author: Graeme Devine
;*
;***************************************************************************


	.model	small,c

	include	macross.asm

	include	exten.asm

	include	global.inc

	jumps

	.data

	.386


cache_handle   	dw	?
mcache_handle   dw	?
vcache_handle   dw	?

lzss_handle	dw	?
lzss_rehold	dw	?
lzss_hold	dw	?
lzss_realname	db	"01234567.012"
lzss_soff	dd	?
lzss_flen	dd	?
lzss_rlen	dd	?
lzss_offs	dw	?
lzss_soff2	dd	?
lzss_readlen	dw	?
lzss_readgot	dw	?
lzss_leftlen	dw	?
lzss_dxat	dw	?
lzss_blen	dw	?
lzss_atleast	dw	0

indir_name	db	INPDIR,"alan.gjd",0
index_name	db	INPDIR,"dave.gjd",0
cache_name	db	INDDIR,"lori.gjd",0

mindex_name	db	INPDIR,"dianne.gjd",0
mcache_name	db	INPDIR,"john.gjd",0

lzss_leftover	db	256 dup(?)

	.code
	.386
;
; **************************************************************************
; *
; * fseek on a stream to dx:cx
; *
; **************************************************************************
;

lzss_fseek	macro

	xor	ax,ax
	mov	bx,cache_handle[bp]
	dos	4200h

	endm

open_file	proc

	call	expand_filename

	dos	3d00h

	.if	nocarry
		mov	bx,ax
		xor	ax,ax
	.else
		mov	ax,-1
	.endif

	ret
open_file	endp

close_file	proc
	mov	bx,cache_handle[bp]
	dos	3e00h
	ret
close_file	endp

read_data	macro	to, length
	push	ds
	mov	ax,seg to
	mov	ds,ax
	mov	dx,offset to 
	mov	cx,length
	call	read_file
	pop	ds
endm

read_file	proc
	mov	bx,cache_handle[bp]
	dos	3f00h
	ret

read_file	endp
	
;
; **************************************************************************
; *
; * get to the lzss file referenced by ax
; *
; **************************************************************************
;
lzss_mfopen	proc

	pusha
	push	ds
	push 	ax

	mov	ax, @data
	mov	ds, ax
	mov	dx, offset mindex_name	

	call	expand_filename
		
	dos	3d00h				; file open

	.if	nocarry
		mov	lzss_handle[bp], ax
	.else
		mov	ax,offset error12
		jmp	exit_out
	.endif

	mov	ax, mcache_handle[bp]
	mov	cache_handle[bp], ax
	jmp	lzss_same

lzss_mfopen	endp

;
; **************************************************************************
; *
; * get to the lzss file referenced by dx and open it
; *
; **************************************************************************
;
lzss_findopen	proc
	pusha
	push	ds
	push	es

	mov	si, dx

	mov	ax, @data
	mov	ds, ax
	mov	es, ax
	mov	dx, offset indir_name	
	call	expand_filename

	dos	3d00h				; file open

	.if	nocarry
		mov	lzss_handle[bp], ax
	.else
		mov	ax,offset error15
		jmp	exit_out
	.endif
	mov	ax, vcache_handle[bp]
	mov	cache_handle[bp], ax

	mov	ax, lzss_atleast[bp]		; mothers little helper
	mov	cx, 26
	mul	cx
	mov	cx, dx
	mov	dx, ax				; get seek address

	mov	bx, lzss_handle[bp]
	xor	ax, ax
	dos	4200h				; file seek

find_name:	
	mov	dx, offset lzss_realname
	mov	cx, 26
	mov	bx, lzss_handle[bp]
	dos	3f00h				; read data
	.if	ax equals 0
		mov	di, offset error14
		mov	ax, rfardata
		mov	es, ax
		mov	cx, 12
		rep	movsb
		mov	ax, offset error14	; read in 0 bytes
		jmp	exit_out		; probably EOF
	.endif
	
	mov	ax, word ptr lzss_soff[bp]
	push	ax
	mov	word ptr lzss_soff[bp], 0
	mov	di, offset lzss_realname
	call	strcmpi
	pop	ax
	mov	word ptr lzss_soff[bp], ax
	jne	find_name
						; now we have the file
	pop	es
       	pop	ds

	mov	bx, lzss_handle[bp]
	dos	3e00h				; close file

	jmp	lzss_r_same

lzss_findopen	endp
	
;
; **************************************************************************
; *
; * get to the lzss file referenced by ax
; *
; **************************************************************************
;
lzss_fopen	proc

	pusha
	push	ds
	push 	ax

	mov	ax, @data
	mov	ds, ax
	mov	dx, offset index_name	

	call	expand_filename
		
	dos	3d00h				; file open

	.if	nocarry
		mov	lzss_handle[bp],ax
	.else
		mov	ax,offset error11
		jmp	exit_out
	.endif
	mov	ax, vcache_handle[bp]
	mov	cache_handle[bp], ax
lzss_same:
	pop	ax
	mov	cx, 14
	mul	cx
	mov	dx, ax
	xor	cx, cx				; get seek addr

	mov	bx, lzss_handle[bp]
	xor	ax, ax
	dos	4200h				; file seek

	mov	dx, offset lzss_soff
	mov	cx, 14				; change to 18 for soff2
	mov	bx, lzss_handle[bp]
	dos	3f00h				; read data
	mov	bx, lzss_handle[bp]
	dos	3e00h				; close file

	pop	ds

lzss_r_same:

	mov	dx,word ptr lzss_soff[ bp + 0 ]
	mov	cx,word ptr lzss_soff[ bp + 2 ]
				        
	lzss_fseek

	mov	ax,word ptr lzss_flen[ bp + 2 ]
	and	ax,ax
	.if	notzero
		push	ds

		mov	ax, lzss_stream
		mov	ds, ax
		xor	dx, dx
		mov	cx, 32768
		mov	bx, cache_handle[bp]
		dos	3f00h

		mov	dx, 32768
		mov	cx, 32768
		mov	bx, cache_handle[bp]
		dos	3f00h
		
		pop	ds

		mov	ecx, 10000h

	.else
		push	ds

		mov	ax, lzss_stream
		mov	ds, ax
		xor	dx, dx
		mov	cx, word ptr lzss_flen[bp]
		mov	bx, cache_handle[bp]
		dos	3f00h

		pop	ds
		mov	ecx, lzss_flen[bp]
	.endif

	sub	lzss_flen[bp], ecx

	mov	lzss_hold[bp], 0
	mov	lzss_handle[bp], 1
	mov	lzss_leftlen[bp], 0
	mov	lzss_dxat[bp], 0
	
	mov	ax, lzss_offs[bp]
	mov	cl, ah
	mov	byte ptr cs:[lzss_shr],ah
	mov	byte ptr cs:[lzss_and],al
	mov	ax, 0ffffh
	shr	ax, cl

	mov	lzss_blen[bp], ax

	popa

	ret

lzss_fopen	endp

;
; **************************************************************************
; *
; * Read and decode the lzss stream for length cx to ds:dx
; *  - return ax (actual number of bytes read)
; *  - and a carry flag
; *
; **************************************************************************
;
lzss_fread	proc
	push	ds
	push	es
	pusha

	xor	eax,eax
	mov	ax,cx
	.if	eax greaterthan lzss_rlen[bp]
		mov	ecx, lzss_rlen[bp]
	.endif

	mov	lzss_readlen[bp],cx
	mov	lzss_readgot[bp],0
	mov	bx,lzss_offs[bp]

	.if	lzss_rlen[bp] notequal 0	
		mov	ax,ds
		mov	es,ax
	
		mov	di,dx
	
		.if	lzss_leftlen[bp] notequal 0
			mov	si,offset lzss_leftover
			mov	cx,lzss_leftlen[bp]
			.if	cx greaterthan lzss_readlen[bp]
				mov	cx,lzss_readlen[bp]
			.endif
			mov	lzss_readgot[bp],cx
			mov	ax,@data
			mov	ds,ax
			rep	movsb
			mov	lzss_leftlen[bp],0
		.endif
	
		mov	si, lzss_hold[bp]
		mov	lzss_rehold[bp], si
	
		.if	lzss_readlen[bp] notequal 0
			mov	ax,lzss_stream
			mov	ds,ax
			mov	bx,lzss_readgot[bp]
			mov	dx,lzss_dxat[bp]
			and	dx,dx
			.if	zero
				call	lzss_decode
			.else
				call	lzss_renter
			.endif
		.endif
		xor	eax,eax
		mov	ax,lzss_readgot[bp]
		sub	lzss_rlen[bp],eax
		.if	carry
			mov	lzss_rlen[bp],0
		.endif
	.endif

	popa
	mov	ax,lzss_readgot[bp]

	pop	es
	pop	ds
	ret
		
lzss_fread	endp

;
; **************************************************************************
; *
; * close the lzss stream file
; *
; **************************************************************************
;
lzss_fclose	proc

	mov	lzss_handle[bp], 0
	ret

lzss_fclose	endp

;
; **************************************************************************
; *
; * close the lzss stream file
; *
; **************************************************************************
;
lzss_mfclose	proc

	mov	ax, vcache_handle[ bp ]
	mov	cache_handle[ bp ], ax
	mov	lzss_handle[bp], 0
	ret

lzss_mfclose	endp

lzss_init	proc
	mov	ax,@data
	mov	ds,ax
;
; **************************************************************************
; *
; * Read the directory index (just one seek per open.......coooool)
; *
; **************************************************************************
;
	mov	lzss_handle,0
;
; **************************************************************************
; *
; * open the cache file
; *
; **************************************************************************
;
	mov	dx,offset cache_name
	call	open_file
	.if	ax equals -1
		mov	ax,offset error11
		jmp	exit_out
	.endif
	mov	vcache_handle, bx
	
	mov	dx,offset mcache_name
	call	open_file
	.if	ax equals -1
		mov	ax,offset error12
		jmp	exit_out
	.endif
	mov	mcache_handle, bx
	
	ret	
	
lzss_init	endp
	

;
; **************************************************************************
; *
; * LZSS_DECODE - unpacks a file packed by lzss. This version gets its
; * input from DS:SI and sends the output to ES:DI. 
; *
; * INPUT:
; * DS:SI - points to input packed data stream
; * ES:DI - points to buffer to store unpacked data
; * bl    - offset bit size
; * bh	- length bit size
; *
; **************************************************************************
;

lzss_decode	proc
	lodsb
	mov	dl, al

	mov	dh, 8

	.do
		shr	dl, 1
		.if	carry
			movsb			;copy byte verbatim to output stream
			inc	bx
		.else
			lodsw			;get offset and length info

			and	ax, ax
			jz	@1		;=> offset & length == 0, we're done

			mov	cl, al
			db	0c1h, 0e8h
lzss_shr:		db	0		; shr ax,n

			db	083h, 0e1h
lzss_and:		db	0
			add	cx, 3		; CX = n bit length info + 3

			push	ds
			push	si

			mov	si, di
			sub	si, ax		;SI -> to prev stream to copy from
			push	es
			pop	ds
						;move CX bytes from DS:SI to ES:DI
			mov	ax, cx
			add	ax, bx
			.if	ax lessthanorequal lzss_readlen[bp]
				mov	bx, ax
				rep	movsb
			.else
				sub	ax, lzss_readlen[bp]
				sub	cx, ax
				add	bx, cx
				rep	movsb			; do part
				mov	cx, ax
				mov	lzss_leftlen[bp], ax
				mov	ax, @data
				mov	es, ax
				mov	ax, di
				mov	di, offset lzss_leftover				
				.do
					movsb
					.if	si equals ax
						mov	si,offset lzss_leftover
						push	es
						pop	ds
					.endif
					dec	cx
				.while	notzero
			.endif
odd_out:		pop	si
			pop	ds
		.endif
		.if	bx equals lzss_readlen[bp]
			mov	lzss_dxat[bp],dx
			mov	lzss_hold[bp],si
			jmp	@2
		.endif
lzss_renter:
		dec	dh
	.while	notzero

	jmp	lzss_decode
;
; **************************************************************************
; *
; * load in more data if neccesary before returning
; *
; **************************************************************************
;
@2:
	mov	lzss_readgot[bp], bx
	.if	lzss_flen[bp] notequal 0
		xor    	ecx, ecx	
		mov	cx, lzss_hold[bp]
		sub	cx, lzss_rehold[bp]
		mov	dx, lzss_rehold[bp]
	
		sub	lzss_flen[bp],ecx
		.if	notplus
			add	ecx, lzss_flen[bp]
			mov	lzss_flen[bp],0
		.endif

		mov	ax,dx
		add	ax,cx
		.if	carry
			push	ax
			sub	cx,ax
			mov	bx,cache_handle[bp]
			dos	3f00h
			.if	carry
				mov	ax, offset error13
				jmp	exit_out
			.endif
			pop	cx
			xor	dx,dx
		.endif
		mov	bx,cache_handle[bp]
		dos	3f00h
		.if	carry
			mov	ax, offset error13
			jmp	exit_out
		.endif
	.endif		
@1:
	ret

lzss_decode	endp

lzss_stream	segment para public 'lzss'

lzss_data	db 65535 dup(0)

lzss_stream	ends

rfardata	segment para public 'FAR'	; data that's a long way away

error11		db	"file system error - aborting",13,10,"$"
error12		db	"xmi file system error - aborting",13,10,"$"
error13		db	"a serious CD File System error has occurred",13,10,"$"
error14		db	"01234567.012 - file not found",13,10,"$"
error15		db	"extended file system error - aborting",13,10,"$"

rfardata	ends

	end

