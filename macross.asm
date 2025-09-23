;***************************************************************************
;*
;* TASM extensions for structured code
;*
;* (c) Copyright 1990 Graeme Devine
;*
;* Author: Graeme Devine
;*
;***************************************************************************


;;	smart

depth	=0
mktemp	=0

$assign macro	gnam, tnum
	gnam    =tnum
endm

$inc    macro	gnam
	$assign gnam, gnam+1
endm

$dec    macro	gnam
	$assign gnam, gnam-1
endm

$get    macro	gnam, array, index
	$assign gnam, array&index
endm

$put	macro	array, index, val
	$assign	array&index, val
endm

$push	macro	tnum
	$put    gstak, %depth, tnum
	$inc	depth
endm

$pop    macro	gnam
	$dec	depth
	$get    gnam, gstak, %depth
endm

$mktemp macro	gnam
	$assign gnam, %mktemp
	$inc	mktemp
endm

.if	macro	cond1, cond2, cond3
	IFNB	<cond2>
		$mktemp ccase
		$assign	ecase, ccase
		$mtest	cond2, cond1, cond3, L$&%ccase
		$push	%ecase
		$push	%ccase
	ELSE
		$mktemp	ccase
		$assign	ecase, ccase
		$&cond1	L$&%ccase
		$push	%ecase
		$push	%ccase
	ENDIF
endm

$mtest	macro	cond, op1, op2, label
	cmp	op1,op2
	maxfoo = 0
	IFIDN	<cond>, <greaterthanorequal>
		jnae	label
		maxfoo = 1
	ENDIF
	IFIDN	<cond>, <greaterthan>
		jna	label
		maxfoo = 1
	ENDIF
	IFIDN	<cond>, <lessthan>
		jnb	label
		maxfoo = 1
	ENDIF
	IFIDN	<cond>, <lessthanorequal>
		jnbe	label
		maxfoo = 1
	ENDIF
	IFIDN	<cond>, <equals>
		jne	label
		maxfoo = 1
	ENDIF
	IFIDN	<cond>, <notequal>
		je	label
		maxfoo = 1
	ENDIF

	ERRIFE	maxfoo
endm

$zero	macro	label
	jnz	label
endm

$notzero	macro	label
	jz	label
endm

$carry		macro	label
	jnc	label
endm

$nocarry	macro	label
	jc	label
endm

$minus		macro	label
	jns	label
endm

$notminus	macro	label
	js	label
endm

$plus		macro	label
	js	label
endm

$notplus	macro	label
	jns	label
endm

$equal		macro	label
	jne	label
endm

$notequal	macro	label
	je	label
endm

.endif	macro
	$pop	ccase
	$pop	ecase
if	ccase eq ecase
else
	$label	%ccase
endif
	$label	%ecase
endm

$label	macro	tnum
L$&tnum:
endm

$jump	macro	label
	jmp	label
endm

.else	macro
	$pop	ccase
	$pop	ecase
if	ccase eq ecase
	$mktemp	ecase
endif
	$jump	L$&%ecase
	$label	%ccase
	$assign	ccase, ecase
	$push	ecase
	$push	ccase

endm

.elseif	macro	cond
	$pop	ccase
	$pop	ecase
if	ccase eq ecase
	$mktemp	ecase
endif
	$jump	L$&%ecase
	$label	%ccase
	$mktemp	ccase
	$&cond	L$&%ccase
	$push	ecase
	$push	ccase
endm

;$storage        macro	gnam
;	$assign stgstak, gnam
;endm
;
;$gstak  macro	gnam, glen
;	$assign gnam, stgstak
;	$assign stgstak, stgstak+glen
;endm

.do	macro
	$mktemp	lcase
	$label	%lcase
	$push	lcase
endm

.while	macro	cond
	$pop	lcase
	$m&cond	L$&%lcase
endm

$mzero		macro	label
	jz	label
endm

$mnotzero	macro	label
	jnz	label
endm

$mcarry		macro	label
	jc	label
endm

$mnocarry	macro	label
	jnc	label
endm

$mminus		macro	label
	js	label
endm

$mnotminus	macro	label
	jns	label
endm

$mplus		macro	label
	jns	label
endm

$mnotplus	macro	label
	js	label
endm

$mequal		macro	label
	je	label
endm

$mnotequal	macro	label
	jne	label
endm


