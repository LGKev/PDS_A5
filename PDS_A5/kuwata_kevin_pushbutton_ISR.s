	.include "address_map_nios2.s"
	.extern	PATTERN					# externally defined variables
	.extern	SHIFT_DIR
	.extern	SHIFT_EN
	
	
.equ	LEFT,		0
.equ	RIGHT,		1

.equ	DISABLE,	0
.equ	ENABLE,		1
	
/*******************************************************************************
 * Pushbutton - Interrupt Service Routine
 *
 * This routine checks which KEY has been pressed and updates the global
 * variables as required.
 ******************************************************************************/
	.global	PUSHBUTTON_ISR
PUSHBUTTON_ISR:
	subi	sp, sp, 20				# reserve space on the stack
	stw		ra, 0(sp)
	stw		r10, 4(sp)
	stw		r11, 8(sp)
	stw		r12, 12(sp)
	stw		r13, 16(sp)

	movia	r10, KEY_BASE			# base address of pushbutton KEY parallel port
	ldwio	r11, 0xC(r10)			# read edge capture register, store it we will compare later.
	stwio	r11, 0xC(r10)			# clear the interrupt, again any "WRITE" to edge capture clears the interrupt

CHECK_KEY0:
	andi	r13, r11, 0b0001		# check KEY0, refer to figure 6 if confused. 
	beq		r13, zero, CHECK_KEY1	#will be a 1 if interrupt triggered, this is the "flag"

	
	#this is where we would speed up
	
	movia r16, TIMER_BASE		#0xFF202000 TIMER 1
	 #stop the timer. 
	movi 	r15, 0b1011 #bit4 at base + 0x04 is the stop bit. 1 for stop, bit 3 is start bit 
	sthio	r15, 4(r16) #timer is now stopped with continuous mode and interrupts.
	
	#make new timer count down START value, was 5 Million, lets make it 9 million. (slower timer).
	movia r12, 9000000
	sthio r12, 8(r16)		#high half into TIMER_BASE + 0x08
	srli  r12, r12, 16		#shift over 16 bits right, to get the top half word bits
	sthio r12, 0xC(r16)		#store the second half into the counter register. base + 12 bit offset.
	
	#get ready to start timer by setting bits3,2,1 (yes were off by one index, sure but you know what I mean). bit0 in this instance is bit 1 ok?
	movi r15, 0b0111	#bit3 is the start bit, 1 and 2 are the continuous mode and interrupt enable.
	sthio r15, 4(r16)		#start the timer again


CHECK_KEY1:
	andi	r13, r11, 0b0010		# check KEY1
	beq		r13, zero, END_PUSHBUTTON_ISR #so no interrupt happened, this probably won't occur.
	
	movia r16, TIMER_BASE		#0xFF202000 TIMER 1
	 #stop the timer. 
	movi 	r15, 0b1011 #bit4 at base + 0x04 is the stop bit. 1 for stop, bit 3 is start bit 
	sthio	r15, 4(r16) #timer is now stopped with continuous mode and interrupts.
	
	#make new timer count down START value, was 5 Million, lets make it 9 million. (slower timer).
	movia r12, 2500000
	sthio r12, 8(r16)		#high half into TIMER_BASE + 0x08
	srli  r12, r12, 16		#shift over 16 bits right, to get the top half word bits
	sthio r12, 0xC(r16)		#store the second half into the counter register. base + 12 bit offset.
	
	#get ready to start timer by setting bits3,2,1 (yes were off by one index, sure but you know what I mean). bit0 in this instance is bit 1 ok?
	movi r15, 0b0111	#bit3 is the start bit, 1 and 2 are the continuous mode and interrupt enable.
	sthio r15, 4(r16)		#start the timer again
	
	
	#this has to be called to return to the main loop, and to clean up the stack and restore values.
END_PUSHBUTTON_ISR:
	ldw		ra,  0(sp)				# Restore all used register to previous
	ldw		r10, 4(sp)		
	ldw		r11, 8(sp)
	ldw		r12, 12(sp)
	ldw		r13, 16(sp)
	addi	sp,  sp, 20

	ret
	.end	
