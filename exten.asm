;***************************************************************************
;*
;* TASM extensions for structured code
;*
;* (c) Copyright 1990 Graeme Devine
;*
;* Author: Graeme Devine
;*
;***************************************************************************

dos	macro	value
	mov	ax,value
	int	21h
endm
bios	macro	value
	mov	ax,value
	int	10h
endm
go320x200	macro
	mov	ah,0fh
	int	10h
	cmp	al,13h
	.if	notzero
		bios	13h
	.endif
endm
doskeyboard	macro
	mov	dl,0ffh
	dos	0600h
endm
.ifkeyboard	macro
	doskeyboard
	.if	notzero
endm
load	macro	to, wi, what, use, who
	IFDIF	<wi>, <with>
		ERR
	endif
	IFB	<use>
		IRP	v,<to>
			mov	v, what
		endm
	else
		mov	who, what
		IRP	v,<to>
			mov	v,who
		endm
	endif
endm
.switch	macro	point
	$assign casepoint, point
	$assign	incase, 0
	$mktemp	ccase
	$push	%ccase
endm
.case	macro	case
	if	incase
		$pop	ecase
		$pop	ccase
		$jump	L$&%ccase
		$label	%ecase
		$push	ccase
	endif
	cmp	casepoint,case
	$mktemp	ecase
	$equal	L$&%ecase
	$push	%ecase
	$assign incase, 1
endm
.default	macro
	if	incase
		$pop	ecase
		$pop	ccase
		$jump	L$&%ccase
		$label	%ecase
		$push	ccase
	endif
	$assign	incase, 0
endm
.endcase	macro
	if	incase
		$pop	ecase
		$label	%ecase
	endif
	$pop	ccase
	$label	%ccase
endm
reset	macro	field
	IRP	fi,<field>
		mov	fi,0
	endm
endm
inci	=	1
stepi	=	2
.for	macro	sub1, sub1a, sub2, sub3, sub4, sub5, sub6
IFIDN	<sub3>, <to>
	IFIDN	<sub5>, <step>
		mov	sub1, sub2 - sub6
		$assign	foract, stepi
		$assign forinc, sub6
	ELSE
		mov	sub1, sub2 - 1
		$assign	foract, inci
		$assign forinc, 1
	ENDIF
	$assign forcmp, sub1
	$assign foreqr, sub4
	$mktemp	ccase
	$push	%ccase
	$label	%ccase
	$doact	foract, forcmp, forinc
	$push	foreqr
	$push	forcmp
	$push	foract
	$push	forinc
ENDIF
endm
$doact	macro	type, what, with
IFE	type-inci
	inc	what
ELSE
	IFE	type-stepi
		add	what, with
	ENDIF
ENDIF
endm
.next	macro
	$pop	forinc
	$pop	foract
	$pop	forcmp
	$pop	foreqr
	$pop	ccase
	cmp	forcmp, foreqr
	$equal	L$%ccase
endm
.seterror	macro	name
	mov	ax,offset name
	call	set_strerror
endm
INPUT_STATUS_1 	equ 	03dah 		;input status 1 register port
WaitVEdge	macro
local	wait1, wait2
	push	dx
	mov	dx,INPUT_STATUS_1
	.do				;wait to be out of vertical sync
		in	al,dx
		and	al,08h
		jmp	wait1
wait1:
	.while	notzero
	.do
		in	al,dx
		and	al,08h
		jmp	wait2
wait2:
	.while	zero
	pop	dx
endm

WaitaTick	macro
	mov	ax,clock[bp]
	.do
		cmp	ax, clock[bp]
	.while	zero
endm

updateswap	macro
	call	swapupdate
endm

swapppy	macro
	cmp	si,chunkswap+14*1024
	.if	nocarry
		push	ax
		mov	ax,current_page[bp]
		.if	ax lessthan nopage[bp]
			mov	bx,jump_table[bp]
			call	ss:[bx].swapping
		.endif
		pop	ax
	.endif
endm

guilt	macro
ife	shareware
		mov	dx,offset guilttext
		dos	0900h
		mov	dl,24h
		dos	0200h
		mov	dx,offset guilt2
		dos	0900h
endif
endm
.calloninit	macro	name
XIB	segment word public 'DATA'	; these segments contain a list of
XIB	ENDS
XI	segment word public 'DATA'	;  procedure addresses that the
	IRP	entry,<name>
		dw	entry
	ENDM
XI	ENDS				;  start-up code calls before main
XIE	segment word public 'DATA'
XIE	ENDS
endm
.callonexit	macro	name
XPB	segment word public 'DATA'	; these segments contain a list of
XPB	ENDS
XP	segment word public 'DATA'	;  procedure addresses that the
	IRP	entry,<name>
		dw	entry
	ENDM
XP	ENDS				;  are called when leaving
XPE	segment word public 'DATA'
XPE	ENDS
endm
.callonterm	macro	name
XCB	segment word public 'DATA'	; these segments contain a list of
XCB	ENDS
XC	segment word public 'DATA'	;  procedure addresses that the
	IRP	entry,<name>
		dw	entry
	ENDM
XC	ENDS				;  quick exit uses
XCE	segment word public 'DATA'
XCE	ENDS
endm
.gdata	macro
	.data
endm

.gcode	macro
	.code
endm

print	macro	what
	push	ds
	mov	dx,ax
	mov	ax,@data
	mov	ds,ax
	dos	0900h
	pop	ds
endm
	
debug	macro	who
;	push	dx
;	push	ax
;	mov	dx,03c8h
;	xor	ax,ax
;	out	dx,al
;	mov	ax,who
;	inc	dx
;	out	dx,al
;	out	dx,al
;	out	dx,al
;	pop	ax
;	pop	dx
endm

cproc	macro	where, name
	sa = 0
	IRP	entry,<name>
		push	entry
		sa = sa + 2
	ENDM
	call	where
	if	sa
		add	sp,sa
	endif
endm
	
loopcx	macro	where
	dec	cx
	jnz	where
	endm

	
lodsb32	macro
	mov	al,[si]
	inc	si
	endm

lodsw32	macro
	mov	ax,[si]
	add	si, 2
	endm

apush	macro	where
	mov	ax, where
	push	ax
	endm

apop	macro	where
	pop	ax
	mov	where, ax
	endm
