/*** asmFmax.s   ***/
#include <xc.h>
.syntax unified

@ Declare the following to be in data memory
.data  
.align

@ Define the globals so that the C code can access them

/* create a string */
.global nameStr
.type nameStr,%gnu_unique_object
    
/*** STUDENTS: Change the next line to your name!  **/
nameStr: .asciz "Edward Guerra Ramirez"  
 
.align

/* initialize a global variable that C can access to print the nameStr */
.global nameStrPtr
.type nameStrPtr,%gnu_unique_object
nameStrPtr: .word nameStr   /* Assign the mem loc of nameStr to nameStrPtr */

.global f0,f1,fMax,signBitMax,storedExpMax,realExpMax,mantMax
.type f0,%gnu_unique_object
.type f1,%gnu_unique_object
.type fMax,%gnu_unique_object
.type sbMax,%gnu_unique_object
.type storedExpMax,%gnu_unique_object
.type realExpMax,%gnu_unique_object
.type mantMax,%gnu_unique_object

.global sb0,sb1,storedExp0,storedExp1,realExp0,realExp1,mant0,mant1
.type sb0,%gnu_unique_object
.type sb1,%gnu_unique_object
.type storedExp0,%gnu_unique_object
.type storedExp1,%gnu_unique_object
.type realExp0,%gnu_unique_object
.type realExp1,%gnu_unique_object
.type mant0,%gnu_unique_object
.type mant1,%gnu_unique_object
 
.align
@ use these locations to store f0 values
f0: .word 0
sb0: .word 0
storedExp0: .word 0  /* the unmodified 8b exp value extracted from the float */
realExp0: .word 0
mant0: .word 0
 
@ use these locations to store f1 values
f1: .word 0
sb1: .word 0
realExp1: .word 0
storedExp1: .word 0  /* the unmodified 8b exp value extracted from the float */
mant1: .word 0
 
@ use these locations to store fMax values
fMax: .word 0
sbMax: .word 0
storedExpMax: .word 0
realExpMax: .word 0
mantMax: .word 0

.global nanValue 
.type nanValue,%gnu_unique_object
nanValue: .word 0x7FFFFFFF            

@ Tell the assembler that what follows is in instruction memory    
.text
.align

/********************************************************************
 function name: initVariables
    input:  none
    output: initializes all f0*, f1*, and *Max varibales to 0
********************************************************************/
.global initVariables
 .type initVariables,%function
initVariables:
    /* YOUR initVariables CODE BELOW THIS LINE! Don't forget to push and pop! */

    
   /*
   This routine **initializes (or resets) all floating-point-related global variables** 
   to zero. It is likely intended to be called before performing any floating-point 
   analysis or comparisons to ensure a clean state.
 
   Specifically, it zeroes out:
     - f0, f1:        Raw float values
     - sb0, sb1:      Sign bits
     - storedExp0, storedExp1: Stored exponents from IEEE 754 encoding
     - realExp0, realExp1:     Adjusted (real) exponents after bias removal
     - mant0, mant1:  Mantissas (fractional parts)
     - fMax:          The maximum of f0 and f1
     - sbMax, storedExpMax, realExpMax, mantMax: Components of the maximum float
  
   After execution, all float-related global storage is cleared, avoiding stale data.
   */

    PUSH {lr}                     

    LDR r0, =f0                   /* Clears f0 */
    MOV r1, #0
    STR r1, [r0]

    LDR r0, =sb0                  /* Clears the sign bit of f0 */
    STR r1, [r0]
    LDR r0, =storedExp0           /* Clears the stored exponent of f0 */
    STR r1, [r0]
    LDR r0, =realExp0             /* Clears the real exponent of f0 */
    STR r1, [r0]
    LDR r0, =mant0                /* Clears the mantissa of f0 */
    STR r1, [r0]

    LDR r0, =f1                   /* Clears the f1 */
    STR r1, [r0]
    LDR r0, =sb1                  /* Clears the sign bit of f1 */
    STR r1, [r0]
    LDR r0, =storedExp1           /* Clears the stored exponent of f1 */
    STR r1, [r0]
    LDR r0, =realExp1             /* Clears the real exponent of f1 */
    STR r1, [r0]
    LDR r0, =mant1                /* Clears the mantissa of f1 */
    STR r1, [r0]

    LDR r0, =fMax                 /* Clears the max float value */
    STR r1, [r0]
    LDR r0, =sbMax                /* Clears the sign bit of max */
    STR r1, [r0]
    LDR r0, =storedExpMax         /* Clears the stored exponent of max */
    STR r1, [r0]
    LDR r0, =realExpMax           /* Clears the real exponent of max */
    STR r1, [r0]
    LDR r0, =mantMax              /* Clears the mantissa of max */
    STR r1, [r0]

    POP {lr}                      /* Restores the return address */
    BX lr                         /* Returns from the routine */
    
    
    /* YOUR initVariables CODE ABOVE THIS LINE! Don't forget to push and pop! */

    
/********************************************************************
 function name: getSignBit
    input:  r0: address of mem containing 32b float to be unpacked
            r1: address of mem to store sign bit (bit 31).
                Store a 1 if the sign bit is negative,
                Store a 0 if the sign bit is positive
                use sb0, sb1, or signBitMax for storage, as needed
    output: [r1]: mem location given by r1 contains the sign bit
********************************************************************/
.global getSignBit
.type getSignBit,%function
getSignBit:
    /* YOUR getSignBit CODE BELOW THIS LINE! Don't forget to push and pop! */

    PUSH {lr}         /* Saves the link register (lr) to the stack to preserve the return address */

    LDR r2, [r0]      /* Loads the value at the address stored in register r0 (a pointer to a float) into register r2 */
    LSR r2, r2, #31   /* Logical shift right (LSR) the value in r2 by 31 bits. This moves the sign bit of the float to the least significant bit (LSB) */
    STR r2, [r1]      /* Stores the result in r2 (which now contains only the sign bit) into the memory location pointed to by r1 */

    POP {lr}          /* Restores the link register (lr) from the stack to return to the caller */
    BX lr             /* Branches to the address in the link register, effectively returning from the function */
    
    /* YOUR getSignBit CODE ABOVE THIS LINE! Don't forget to push and pop! */
    

    
/********************************************************************
 function name: getExponent
    input:  r0: address of mem containing 32b float to be unpacked
      
    output: r0: contains the unpacked original STORED exponent bits,
                shifted into the lower 8b of the register. Range 0-255.
            r1: always contains the REAL exponent, equal to r0 - 127.
                It is a signed 32b value. This function doesn't
                check for +/-Inf or +/-0, so r1 always contains
                r0 - 127.
                
********************************************************************/
.global getExponent
.type getExponent,%function
getExponent:
    /* YOUR getExponent CODE BELOW THIS LINE! Don't forget to push and pop! */
    
    PUSH {lr}      /* Saves the link register (lr) to the stack to preserve the return address */

    LDR r2, [r0]       /* Loads the 4-byte floating-point value from the memory address pointed to by r0 into register r2 */
    LSL r2, r2, #1     /* Logical shift left by 1 bit. This removes the sign bit of the floating-point number, leaving the exponent and mantissa */
    LSR r0, r2, #24    /* Logical shift right by 24 bits. This extracts the exponent part (bits 30-23) from the modified value and stores it in r0 */

    MOV r2, #127       /* Loads the constant 127 into register r2. This represents the bias used in IEEE 754 single-precision floating-point format */
    SUB r1, r0, r2     /* Subtract 127 from the exponent value in r0 to compute the "real" exponent. 
		      This adjustment accounts for the bias in the floating-point representation */

    POP {lr}           /* Restores the link register (lr) from the stack, returning the program counter to its previous value */
    BX lr              /* Branches to the address stored in lr, effectively returning from the function */
    
    /* YOUR getExponent CODE ABOVE THIS LINE! Don't forget to push and pop! */
   

    
/********************************************************************
 function name: getMantissa
    input:  r0: address of mem containing 32b float to be unpacked
      
    output: r0: contains the mantissa WITHOUT the implied 1 bit added
                to bit 23. The upper bits must all be set to 0.
            r1: contains the mantissa WITH the implied 1 bit added
                to bit 23. Upper bits are set to 0. 
********************************************************************/
.global getMantissa
.type getMantissa,%function
getMantissa:
    /* YOUR getMantissa CODE BELOW THIS LINE! Don't forget to push and pop! */
    
    PUSH {lr}

    LDR r2, [r0]           /* Loads a 32-bit value from the memory address in r0 into register r2.
                            This value is assumed to be a floating-point number in IEEE 754 format. */
    LDR r3, =0x007FFFFF    /* Loads the immediate value 0x007FFFFF into r3.
                              This value represents a bitmask to extract only the mantissa
                              (fractional part) of a 32-bit float (bits 0-22). */
    AND r0, r2, r3         /* Performs a bitwise AND between r2 and the mantissa mask in r3.
                              This clears all bits except the 23-bit mantissa, storing the result in r0. */

    MOV r1, r0		   /* Copies the mantissa into r1 for further modification or use. */
    MOV r3, #(1 << 23)     /* Loads the value 0x00800000 into r3.
                              This represents the implicit leading 1 in normalized floats,
                              which is not stored in the mantissa but is assumed to be there. */
    ORR r1, r1, r3         /* Set the 24th bit in r1 to reconstruct the full significand
                              (1.mantissa format) for normalized floating-point numbers. */
    
    POP {lr}
    BX lr
    
    /* YOUR getMantissa CODE ABOVE THIS LINE! Don't forget to push and pop! */
   


    
/********************************************************************
 function name: asmIsZero
    input:  r0: address of mem containing 32b float to be checked
                for +/- 0
      
    output: r0:  0 if floating point value is NOT +/- 0
                 1 if floating point value is +0
                -1 if floating point value is -0
      
********************************************************************/
.global asmIsZero
.type asmIsZero,%function
asmIsZero:
    /* YOUR asmIsZero CODE BELOW THIS LINE! Don't forget to push and pop! */
    
    PUSH {lr}                  

    /* Loads the 32-bit value pointed to by r0 into r1.
    This value is assumed to be a floating-point number
    represented in IEEE 754 format (as a raw bit pattern). */
    LDR r1, [r0]

    /* Compares the value to 0x00000000 */
    CMP r1, #0
    BEQ is_positive_zero   /* If it's equal, it's +0; branch to handle it */

    /* Loads 0x80000000 into r2. this represents -0 in IEEE 754,
    where only the sign bit is set and all others are 0 */
    LDR r2, =0x80000000

    /* Compares the value to 0x80000000 */
    CMP r1, r2
    BEQ is_negative_zero   /* If it's equal, it's -0; branch to handle it */

    /* If it's neither +0 nor -0, return 0 to indicate it's not a zero value */
    MOV r0, #0
    POP {lr}
    BX lr                      

    /* Case: positive zero */
    is_positive_zero:
    MOV r0, #1                 /* Returns 1 to indicate +0 */
    POP {lr}
    BX lr                      /* Returns to the function */

    /* Case: negative zero */
    is_negative_zero:
    MOV r0, #-1                /* Returns -1 to indicate -0 */
    POP {lr}
    BX lr                      /* Returns to the function */
    
    /* YOUR asmIsZero CODE ABOVE THIS LINE! Don't forget to push and pop! */
   


    
/********************************************************************
 function name: asmIsInf
    input:  r0: address of mem containing 32b float to be checked
                for +/- infinity
      
    output: r0:  0 if floating point value is NOT +/- infinity
                 1 if floating point value is +infinity
                -1 if floating point value is -infinity
      
********************************************************************/
.global asmIsInf
.type asmIsInf,%function
asmIsInf:
    /* YOUR asmIsInf CODE BELOW THIS LINE! Don't forget to push and pop! */

    PUSH {lr}                      

    /* Loads the 32-bit value from the memory address in r0 into r1.
    This value is treated as a raw IEEE 754 single-precision float. */
    LDR r1, [r0]

    /* Loads the bit pattern for positive infinity (0x7F800000) into r2.
    In IEEE 754, this pattern represents +Inf:
     - Sign bit: 0
     - Exponent: all 1s (255)
     - Mantissa: 0 */
    LDR r2, =0x7F800000

    CMP r1, r2                  /* Compares the loaded float to +Inf */
    BEQ is_pos_inf              /* If it equals, branch to positive infinity handler */

    /* Loads the bit pattern for negative infinity (0xFF800000) into r2.
    In IEEE 754, this pattern represents -Inf:
    - Sign bit: 1
    - Exponent: all 1s
    - Mantissa: 0 */
    LDR r2, =0xFF800000

    CMP r1, r2                   /* Compares the value to -Inf */
    BEQ is_neg_inf		 /* If it equals, branch to negative infinity handler */

    /* If the value is neither +Inf nor -Inf, return 0 to indicate it's finite or NaN */
    MOV r0, #0
    POP {lr}
    BX lr                        /* Returns to the function */

    /* Handler: positive infinity */
    is_pos_inf:
    MOV r0, #1                  /* Returns 1 to indicate +Inf */
    POP {lr}
    BX lr                       /* Returns it to the function */

    /* Handler: negative infinity */
    is_neg_inf:
    MOV r0, #-1                 /* Returns -1 to indicate -Inf */
    POP {lr}
    BX lr                       /* Returns it to the function */
    
    /* YOUR asmIsInf CODE ABOVE THIS LINE! Don't forget to push and pop! */
   


    
/********************************************************************
function name: asmFmax
function description:
     max = asmFmax ( f0 , f1 )
     
where:
     f0, f1 are 32b floating point values passed in by the C caller
     max is the ADDRESS of fMax, where the greater of (f0,f1) must be stored
     
     if f0 equals f1, return either one
     notes:
        "greater than" means the most positive number.
        For example, -1 is greater than -200
     
     The function must also unpack the greater number and update the 
     following global variables prior to returning to the caller:
     
     signBitMax: 0 if the larger number is positive, otherwise 1
     realExpMax: The REAL exponent of the max value, adjusted for
                 (i.e. the STORED exponent - (127 o 126), see lab instructions)
                 The value must be a signed 32b number
     mantMax:    The lower 23b unpacked from the larger number.
                 If not +/-INF and not +/- 0, the mantissa MUST ALSO include
                 the implied "1" in bit 23! (So the student's code
                 must make sure to set that bit).
                 All bits above bit 23 must always be set to 0.     

********************************************************************/    
.global asmFmax
.type asmFmax,%function
asmFmax:   

    /* YOUR asmFmax CODE BELOW THIS LINE! VVVVVVVVVVVVVVVVVVVVV  */
    
    /*
    This routine compares two floating-point values passed in r0 and r1,
    stores both for reference, and determines which one is larger.
      
    The larger value is stored in `fMax`, and its components?sign bit,
    exponent (both stored and real), and mantissa?are extracted using
    helper functions: `getSignBit`, `getExponent`, and `getMantissa`.
 
    These components are saved in memory for further use:
    - Sign bit ? sbMax
    - Stored exponent ? storedExpMax
    - Real exponent ? realExpMax
    - Mantissa ? mantMax
 
    If the values are equal, the function still performs the same
    extraction and storage process using either value.
 
    The function returns with r0 holding the address of the selected
    maximum value (`fMax`).
    */

    PUSH {lr}                       /* Saves return address */

    LDR r2, =f0                     /* Store first float in global f0 */
    STR r0, [r2]
    LDR r2, =f1                     /* Store second float in global f1 */
    STR r1, [r2]

    CMP r0, r1                      /* Compares the two float values */
    BGT f0_larger                   /* Branches if f0 > f1 */
    BEQ either_equal                /* Branches if f0 == f1 */

    /* f1 is larger */
    LDR r2, =fMax                   /* Stores f1 as max value */
    STR r1, [r2]
    LDR r0, =f1
    LDR r1, =sbMax
    BL getSignBit                  /* Extracts and store sign bit */

    LDR r0, =f1
    BL getExponent                 /* Extracts the stored and real exponents */
    LDR r2, =storedExpMax
    STR r0, [r2]
    LDR r2, =realExpMax
    STR r1, [r2]

    LDR r0, =f1
    BL getMantissa                 /* Extracts the mantissa */
    LDR r2, =mantMax
    STR r1, [r2]

    LDR r0, =fMax                  /* Returns pointer to max float */
    BX lr

    f0_larger:
    LDR r2, =fMax
    STR r0, [r2]                   /* Stores f0 as max value */
    LDR r1, =sbMax
    BL getSignBit

    BL getExponent
    LDR r2, =storedExpMax
    STR r0, [r2]
    LDR r2, =realExpMax
    STR r1, [r2]

    BL getMantissa
    LDR r2, =mantMax
    STR r1, [r2]

    LDR r0, =fMax
    BX lr

    either_equal:
    LDR r2, =fMax
    STR r0, [r2]                   /* Treats either as max since equal */
    LDR r1, =sbMax
    BL getSignBit

    BL getExponent
    LDR r2, =storedExpMax
    STR r0, [r2]
    LDR r2, =realExpMax
    STR r1, [r2]

    BL getMantissa
    LDR r2, =mantMax
    STR r1, [r2]

    LDR r0, =fMax
    BX lr

    
    /* YOUR asmFmax CODE ABOVE THIS LINE! ^^^^^^^^^^^^^^^^^^^^^  */

   

/**********************************************************************/   
.end  /* The assembler will not process anything after this directive!!! */
           



