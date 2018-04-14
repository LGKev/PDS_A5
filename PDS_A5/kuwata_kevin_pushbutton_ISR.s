	.include "address_map_nios2.s"
	.extern	PATTERN					# externally defined variables
	.extern	SHIFT_DIR			#TODO delete later, we can use this register since we don't care
	.extern	SHIFT_EN			#TODO delete later			
	.extern SPEED_VALUE
	
/*******************************************************************************
 * Pushbutton - Interrupt Service Routine
 *
 * This routine checks which KEY has been pressed and updates the global
 * variables as required.
 ******************************************************************************/
	.global	PUSHBUTTON_ISR
PUSHBUTTON_ISR:
	subi	sp, sp, 48				# reserve space on the stack
	stw		ra, 0(sp)
	stw		r10, 4(sp) 		#keybase
	stw		r11, 8(sp)		#key1 capture register
	stw		r12, 12(sp)		#timer counter
	stw		r13, 16(sp)		#key2 capture register
	
	stw 	r1, 20(sp)		#slower III
	stw		r2, 24(sp)		#slower II
	stw		r3, 28(sp)		#slower 
	stw		r4, 32(sp)		#default
	stw		r5, 36(sp)		#faster
	stw		r6, 40(sp)		#faster II
	stw		r7, 44(sp)		#faster III
	
	
	movia r16, TIMER_BASE		#0xFF202000 TIMER 1
	 #stop the timer. 
	movi 	r15, 0b1011 #bit4 at base + 0x04 is the stop bit. 1 for stop, bit 3 is start bit 
	sthio	r15, 4(r16) #timer is now stopped with continuous mode and interrupts.


	#get the current value thats in speed. 
	movia r22, SPEED_VALUE #point to address
	ldw  r21, 0(r22)		#get the current speed and put into r21
	
	#NOW NEED TO DECIDE WHAT TO DO: higher or lower the speed.

	movia	r10, KEY_BASE			# base address of pushbutton KEY parallel port
	ldwio	r11, 0xC(r10)			# read edge capture register, store it we will compare later.
	stwio	r11, 0xC(r10)			# clear the interrupt, again any "WRITE" to edge capture clears the interrupt

CHECK_KEY0:
	andi	r13, r11, 0b0001		# check KEY0, refer to figure 6 if confused. 
	beq		r13, zero, CHECK_KEY1	#will be a 1 if interrupt triggered, this is the "flag"
	
	#if this key is pressed we want to speed up. because its higher on the board, like a natural up arrow.
	
	addi r21, r21, 1 		#increment by 1
	br SET_SPEED

CHECK_KEY1:
	andi	r13, r11, 0b0010		# check KEY1
	subi r21, r21, 1 		#decrement by 1
	
	br SET_SPEED
	
	
/* ============================================================  */
/* ============================================================  */
/*
	movia r16, TIMER_BASE		#0xFF202000 TIMER 1
	 #stop the timer. 
	movi 	r15, 0b1011 #bit4 at base + 0x04 is the stop bit. 1 for stop, bit 3 is start bit 
	sthio	r15, 4(r16) #timer is now stopped with continuous mode and interrupts.
	
	#make new timer count down START value, was 5 Million, lets make it 9 million. (slower timer).
	movia r12, 9000000
	
	
	#get ready to start timer by setting bits3,2,1 (yes were off by one index, sure but you know what I mean). bit0 in this instance is bit 1 ok?
	movi r15, 0b0111	#bit3 is the start bit, 1 and 2 are the continuous mode and interrupt enable.
	sthio r15, 4(r16)		#start the timer again
	
	*/
/* ============================================================  */
br END_PUSHBUTTON_ISR
#Determine what speed -- change the counter for the timer. 
SET_SPEED:
	movi	r1, 0x01
	movi 	r2, 0x02
	movi 	r3, 0x03
	movi 	r4, 0x04
	movi 	r5, 0x05
	movi	r6, 0x06
	movi 	r7, 0x07


	beq	r21, r1, SLOW_III
	beq	r21, r2, SLOW_II
	beq	r21, r3, SLOW
	
	beq r21, r4, DEFAULT_SPEED
	
	beq r21, r5, FASTER
	beq r21, r6, FASTER_I
	beq r22, r7, FASTER_II

	#if we come down here we are either too small or too large so we don't change, and exit isr.
	#start up the timer again.
	movi r15, 0b0111	#bit3 is the start bit, 1 and 2 are the continuous mode and interrupt enable.
	sthio r15, 4(r16)		#start the timer again
br END_PUSHBUTTON_ISR 


SLOW:
	movia r12, 10000000
	br SET_TIMER

SLOW_II:
	movia r12, 15000000
		br SET_TIMER


SLOW_III:
	movia r12, 20000000
	br SET_TIMER

DEFAULT_SPEED:
movia r12, 10000000
	br SET_TIMER

	FASTER:
	movia r12, 10000000
	br SET_TIMER

	FASTER_I:
	movia r12, 8000000
	br SET_TIMER

FASTER_II:
	movia r12, 50000000
	br SET_TIMER

SET_TIMER:
	sthio r12, 8(r16)		#high half into TIMER_BASE + 0x08
	srli  r12, r12, 16		#shift over 16 bits right, to get the top half word bits
	sthio r12, 0xC(r16)		#store the second half into the counter register. base + 12 bit offset.
#get ready to start timer by setting bits3,2,1 (yes were off by one index, sure but you know what I mean). bit0 in this instance is bit 1 ok?
	movi r15, 0b0111	#bit3 is the start bit, 1 and 2 are the continuous mode and interrupt enable.
	sthio r15, 4(r16)		#start the timer again
	stw	r21, 0(r22)			#store the SPEED_VALUE into global

	
	#this has to be called to return to the main loop, and to clean up the stack and restore values.
END_PUSHBUTTON_ISR:
	ldw		ra,  0(sp)				# Restore all used register to previous
	ldw		r10, 4(sp)		
	ldw		r11, 8(sp)
	ldw		r12, 12(sp)
	ldw		r13, 16(sp)
	ldw		r1, 20(sp)
	ldw		r2, 24(sp)
	ldw		r3, 28(sp)
	ldw		r4, 32(sp)
	ldw		r5, 36(sp)
	ldw		r6, 40(sp)
	ldw		r7, 44(sp)
	addi	sp,  sp, 48

	ret
	.end	
