# MACROSS.ASM
# Structured Programming Macros for x86 Assembly Code

## Overview

MACROSS.ASM provides structured programming constructs for x86 assembly language, originally developed by me in 1980s while writing Ballblazer for the ZX Spectrum. Basically
Dave Levine (the author of the original Ballblazer) sat with me and told me this was an
important concept to get into the assembler before I could even start on the game port.

Turns out he was right!

### History

This macro system was inspired by Lucasfilm's MACROSS 6502 assembler and was developed as part of the progression from 6502 to Z80 to x86 assembly programming. I use it on every game between
Ballblazer and The 11th Hour (including The 7th Guest).

## Installation

Include the macro file at the beginning of your assembly source:

```asm
include macross.asm
```
### Structured Programming Constructs

#### Conditional Statements (.if/.else/.elseif/.endif)

**Basic Syntax:**
```asm
.if condition
    ; code if true
.endif

.if condition
    ; code if true
.else
    ; code if false
.endif

.if condition1
    ; code for condition1
.elseif condition2
    ; code for condition2
.else
    ; default code
.endif
```

**Comparison Syntax:**
```asm
.if ax, equals, bx
    ; executed if ax == bx
.endif

.if cx, greaterthan, dx
    ; executed if cx > dx
.endif
```

**Supported Comparison Operators:**
- `equals` - Equal comparison (je)
- `notequal` - Not equal comparison (jne)
- `greaterthan` - Greater than comparison (ja)
- `greaterthanorequal` - Greater than or equal (jae)
- `lessthan` - Less than comparison (jb)
- `lessthanorequal` - Less than or equal (jbe)

**Flag-Based Conditions:**
```asm
.if zero
    ; executed if zero flag is set
.endif

.if carry
    ; executed if carry flag is set
.endif
```

**Supported Flag Conditions:**
- `zero` / `notzero` - Zero flag conditions
- `carry` / `nocarry` - Carry flag conditions
- `minus` / `notminus` - Sign flag conditions
- `plus` / `notplus` - Sign flag conditions
- `equal` / `notequal` - Zero flag conditions (aliases)

#### Loop Constructs (.do/.while)

**Basic Loop:**
```asm
.do
    ; loop body
    dec cx
.while notzero
```

**Example - String Processing:**
```asm
.do
    lodsb                ; load next character
    .if al equals 0      ; check for null terminator
        jmp done
    .endif
    ; process character
.while true
```

## Core Features

### Stack-Based Control Flow Management

You don't need to worry about these, but some details on how this works internally:

The macro system uses an internal stack mechanism to track nested control structures:
- `depth` - Current nesting level
- `mktemp` - Temporary label counter
- Internal stack operations maintain proper structure nesting

## Macro Reference

### Variable and Array Macros

#### $assign
Assigns a value to a variable.
```asm
$assign varname, 100
```

#### $inc
Increments a variable by 1.
```asm
$inc counter
```

#### $dec
Decrements a variable by 1.
```asm
$dec counter
```

#### $get
Retrieves a value from an array.
```asm
$get result, myarray, 5  ; result = myarray[5]
```

#### $put
Stores a value in an array.
```asm
$put myarray, 5, 42     ; myarray[5] = 42
```

#### $push
Pushes a value onto the internal stack.
```asm
$push value
```

#### $pop
Pops a value from the internal stack.
```asm
$pop destination
```

#### $mktemp
Creates a unique temporary label number.
```asm
$mktemp mylabel
```

### Control Flow Support Macros

#### $label
Creates a label with a given number.
```asm
$label 123  ; creates L$123:
```

#### $jump
Generates an unconditional jump.
```asm
$jump L$123
```

### Condition Testing Macros

The system includes inverted condition macros for loop constructs:
- `$mzero` / `$mnotzero`
- `$mcarry` / `$mnocarry`
- `$mminus` / `$mnotminus`
- `$mplus` / `$mnotplus`
- `$mequal` / `$mnotequal`

## Usage Examples

### Example 1: Simple Conditional
```asm
mov ax, [user_input]
.if ax, equals, 1
    call option_one
.elseif ax, equals, 2
    call option_two
.else
    call default_option
.endif
```

### Example 2: Nested Conditions
```asm
.if ax, greaterthan, 0
    .if ax, lessthan, 100
        ; ax is between 1 and 99
        call process_valid_range
    .else
        ; ax is 100 or greater
        call process_overflow
    .endif
.else
    ; ax is 0 or negative
    call process_underflow
.endif
```

### Example 3: Loop with Early Exit
```asm
mov cx, 100
.do
    call process_item
    .if carry
        ; error occurred, exit loop
        jmp error_handler
    .endif
    dec cx
.while notzero
```

### Example 4: String Processing (from s.asm)
```asm
mov bx, offset GTL_extension
push di
.do
    mov al, es:[di].data_suffix
    mov ss:[bx], al
    inc bx
    inc di
    and al, al
.while notzero
pop di
```

### Example 5: Complex State Checking
```asm
.do
    call AIL_sequence_status C, mhandle[bp], mseq[bp]
    cmp ax, 1
.while zero
```

## Implementation Notes

1. **Label Generation**: The macros automatically generate unique labels for jumps, preventing naming conflicts in complex nested structures.

2. **Stack Management**: The internal stack tracking ensures proper nesting of control structures. The `depth` variable tracks the current nesting level.

3. **Optimization**: The generated code is optimized for the specific conditions being tested, using the most efficient jump instructions.

4. **Compatibility**: Works with both TASM and MASM assemblers. The `.386` directive should be used for 80386+ specific code.

## Best Practices

1. **Indentation**: Use consistent indentation to show nesting levels, similar to high-level languages.

2. **Comments**: Document complex conditions and loop purposes.

3. **Testing**: Always test boundary conditions in loops and conditionals.

4. **Stack Balance**: Ensure all `.if` statements have matching `.endif` statements.

## Limitations

1. The internal stack has a finite depth (determined by the number of pre-allocated stack variables).

2. Condition testing in `.if` statements with comparisons requires exactly three parameters.

3. Some complex compound conditions may need to be broken into nested `.if` statements.

## License

Copyright 1990 Graeme Devine

## Acknowledgments

- Inspired by Lucasfilm's MACROSS 6502 assembler
- Originally developed for Lucasfilm Games
- Used in the development of The 7th Guest and other classic games
