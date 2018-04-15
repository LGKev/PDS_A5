	.include "address_map_nios2.s"
	.extern	LetterArray					# externally defined variables
	.extern LetterArraySize
	
/*******************************************************************************
 * Interval timer - Interrupt Service Routine
 *
 * Shifts a PATTERN being displayed. The shift direction is determined by the 
 * external variable SHIFT_DIR. Whether the shifting occurs or not is determined
 * by the external variable SHIFT_ON.
 ******************************************************************************/
	.global INTERVAL_TIMER_ISR
INTERVAL_TIMER_ISR:					
	subi	sp,  sp, 28 # reserve space on the stack
	stw		ra, 0(sp)
	stw		r10, 20(sp)
	stw		r20, 24(sp)
	

	movia	r10, TIMER_BASE			# interval timer base address
	sthio	r0,  0(r10)				# any "WRITE" to status clears any interrupts

	movia	r20, HEX3_HEX0_BASE		# HEX3_HEX0 base address
	#movia	r23, LetterArraySize	#keep track of index.

	ldw		r6, 0(r22)				# load the pattern
	stwio	r6, 0(r20)				# store to HEX3 ... HEX0
	
	
	#ldw		r4, 0(r23)				# check if the pattern should be shifted
	#movi	r8, ENABLE				# code to check if shifting is enabled
	
	
	#bne		r4, r8, END_INTERVAL_TIMER_ISR

SHIFT_L:
	slli	r6, r6, 8		#shift the H now
	addi 	r21, r21, 4		#move the index to next element.
	ldw		r7, 0(r21)		#load value at that address at r6, load into r7, for keeping, add to r9
	add		r6, r7, r6		
	subi	r19, r19, 1

	beq 	r19, r0, RESET


STORE_PATTERN:
	stw		r6, 0(r22)				# store display pattern
	#this is actually changing the r21 base pattern which we don't want!

br END_INTERVAL_TIMER_ISR

RESET:
	movia	r21, LetterArray
	movia 	r20, LetterArraySize
	ldw		r19, 0(r20)

END_INTERVAL_TIMER_ISR:
	ldw		ra, 0(sp)				# restore registers
	ldw		r10, 20(sp)
	ldw		r20, 24(sp)
	addi	sp,  sp, 28				# release the reserved space on the stack

	ret
	.end	
