# Program to perform Bresenham Algorithm for circle drawing in BMP file
# Copyright Julita Oltusek 2016-04-10

	.data 
file_name:	.space	100
BM:		.space 	4
buf0:		.space	200
buf:		.asciiz	"test3.bmp"

msg: .asciiz "Type the parameters of the circle (r, xc, yc)\n"
message1:	.asciiz "Podaj nazwe pliku do ktorego chcesz wczytac BMP: "
message2:	.asciiz	"Podaj ilosc iteracji: "
message3:	.asciiz	"Plik o podanej nazwie nie istnieje. Program konczy swoje dzialanie."

	.text
	.globl main

#sp holds a starting point of a heap
#s7 bit correction in width ( additional bits in each row )	padding
#s6 height correction
#s5 width correction
#s4 holds height of BMP
#s3 holds width of BMP
#s2 number of bytes in map of pixels
#s1 holds value of logical shift after multiplication
#s0 number of iterations

main:
	
############## I/O OPERATIONS ##############
	
	#read file name
	li $v0, 4
	la $a0, message1
	syscall
	
	li $v0, 8
	la $a0, file_name
	li $a1, 99
	syscall
	
	li $t5, 0
	li $t4, 100
	la $t3, file_name
	addi $t3, $t3, -1
	
trim_string:

	addiu $t3, $t3, 1
	addiu $t5, $t5, 1
	beq $t5, $t4, skip
	lb $t4, 0($t3)
	bne $t4, $zero, trim_string
	sb $zero, -1($t3)
	
skip:
	
######### BMP FILE OPERATIONS ############
	#opening a file for reading a header
	li $v0, 13
	la $a0, file_name
	li $a1, 0
	li $a2, 0
	syscall
	
	#file opened incorrectly?
	li $t5, -1
	beq $v0, $t5, program_ended_without_file
		
	move $t6, $v0	#saving file descriptor
	
	#check if file was opened correctly
	#li $v0, 1
	#move $a0, $t7
	#syscall
	
	#read BM
	li $v0, 14
	move $a0, $t6 #file descriptor
	la $a1, BM
	li $a2, 2
	syscall
	
	#read header
	li $v0, 14
	move $a0, $t6 #file descriptor
	la $a1, buf0 #input buffer
	li $a2, 52
	syscall
	
	#load width and height
	la $t3, buf0 
	lw $s3, 16($t3)
	lw $s4, 20($t3)	
	#lw $s5, 8($t0)
	#lw $s6, 12($t0)
	#break
	
	#close file after reading
	li $v0, 16
	move $a0, $t6
	syscall
	
######## PADDING #######
	
	li $t5, 4
	#add padding to fill to 4 bytes a row
	mul $t3, $s3, 3 # 3*width
	move $t4, $t3
	andi $t3, $t3, 0x0003 # (3*width)%4 
	beqz $t3, padding_not_needed
	sub $t4, $t4, $t3
	addi $t4, $t4, 4 #total width
	sub $t3, $t5, $t3
	
padding_not_needed:	#skip those instructions if pixels are even numbers	
	
	mul $s2, $t4, $s4 #no of bytes in bmp
	move $s7, $t3 #padding
	
	#dynamic allocation of space needed for BMP writing
	li $v0, 9
	la $a0, ($s2)
	syscall
	move $s6, $v0
	#sub $v0, $v0, $t7 	#we want bytes to be written on growing adresses	
	#addiu $sp, $sp, -4
	#sw $v0, 0($sp)

	
######### Bresenham start ############
	
	#sw $ra, -4($sp)
	
#t0 = r  //circle radius
#t1 = xc //horizontal position of the circle centre
#t2 = yc //vertical position of the circle centre
#t3 = x
#t4 = y
#t5 = d
#t6 = xx //horizontal pozition of the pixel
#t7 = yy //vertical position of the pixel
#t8 = color
#t9 = beginning of a heap


#t3, t4, t5 not used yet, I use it temporarily

########### WHITE BMP ###########

	sw $ra, -4($sp)
	move $t9, $v0 #heap pointer
	li $t8, 0xff
	
	move $t3, $t9 #temp to color in white all pixels
	#addiu $t3, $t3, 1 ??
	li $t4, 0 #iterator
	
loop:
	
	beq $t4, $s2, start_bresenham
	sb $t8, 0($t3)
	addiu $t3, $t3, 1
	addiu $t4, $t4, 1
	b loop
	
#############################
#	li $t7, 0
	
#loop1:	

#	bgt $t7, $s4, start_bresenham 
#	addiu $t6, $t6, 1
#	li $t6, 0
#
#loop2:	
#
#	addiu $t6, $t6, 1 
#	j white
#	
#white:
#	sb $t8, 0($t9)
#	sb $t8, 1($t9)
#	sb $t8, 2($t9)
#	addiu $t9, $t9, 3
#	bne $t6, $s3, loop2
##############	
	

#################################
	
########### BRESENHAM ###########
	
# x=0;
# y=r;
# d=3-2*r;
	
start_bresenham:

######### Read r, xc, yc #########
	li $v0, 4
	la $a0, msg
	syscall
	
	li $v0, 5 
	syscall
	move $t0, $v0
	
	li $v0, 5
	syscall
	move $t1, $v0

	li $v0, 5
	syscall
	move $t2, $v0
	
##################################

	li $t3, 0
	move $t4, $t0  		#r
	sll $s0, $t0, 1 	#2*r
	li $s1, 3
	subu $t5, $s1, $s0
	
#	putpixel(xc+x,yc+y,5);
#	putpixel(xc-y,yc-x,5);
#	putpixel(xc+y,yc-x,5);
#	putpixel(xc-y,yc+x,5);
#	putpixel(xc+y,yc+x,5);
#	putpixel(xc-x,yc-y,5);
#	putpixel(xc+x,yc-y,5);
#	putpixel(xc-x,yc+y,5);	

main_loop: 
	
	bgt $t3, $t4, end_bresenham  # x > y
	
	addu $t6, $t1, $t3
	addu $t7, $t2, $t4
	jal draw_pixel
	
	subu $t6, $t1, $t4
	addu $t7, $t2, $t3
	jal draw_pixel
	
	addu $t6, $t1, $t4
	subu $t7, $t2, $t3
	jal draw_pixel
	
	subu $t6, $t1, $t4
	addu $t7, $t2, $t3
	jal draw_pixel
	
	addu $t6, $t1, $t4
	addu $t7, $t2, $t3
	jal draw_pixel
	
	subu $t6, $t1, $t3
	subu $t7, $t2, $t4
	jal draw_pixel
	
	addu $t6, $t1, $t3
	subu $t7, $t2, $t4
	jal draw_pixel
	
	subu $t6, $t1, $t3
	addu $t7, $t2, $t4
	jal draw_pixel
	
	blez $t5, d1
	bgtz $t5, d2

	# d = d + 4*x + 6;
	# x = x + 1;
d1:
	sll $s0, $t3, 2
	li $s1, 6
	addu $t5, $t5, $s0
	addu $t5, $t5, $s1
	addiu $t3, $t3, 1
	b main_loop
	
	# d = d + 4*x - 4*y + 10;
	# y = y - 1;
	# x = x + 1;
d2:	
	sll $s0, $t3, 2
	sll $s1, $t4, 2
	li $a3, 10
	addu $t5, $t5, $s0
	subu $t5, $t5, $s1
	addu $t5, $t5, $a3
	addiu $t4, $t4, -1
	addiu $t3, $t3, 1
	b main_loop
	
draw_pixel:

	mul $t6, $t6, 3 	# horisontal position
	mul $a3, $s3, 3 	# width*3
	add $a3, $a3, $s7 	# add padding
	mul $t7, $t7, $a3 	# multiply by height, vertical position
	add $t7, $t7, $t6 	# number of byte to color
	add $t6, $t9, $t7	# address of byte to color
	sb $t8, 0($t6)
	sb $t8, 1($t6)
	sb $t8, 2($t6)
	
	jr $ra
	
end_bresenham:

	#changing s0 to file descriptor
	#open file for write
	li $v0, 13	
	la $a0, file_name
	li $a1, 1
	li $a2, 0
	syscall
	move $s0, $v0
	
	#write BM
	li $v0, 15
	move $a0, $s0
	la $a1, BM
	li $a2, 2
	syscall
	
	#write header
	li $v0, 15
	move $a0, $s0
	la $a1, buf0
	li $a2, 52
	syscall
	
	#get number of bytes
	mul $t2, $s3, 3
	add $t1, $t2, $s7
	mul $t1, $t1, $s4
	move $t0, $s6
	
	#write allocated bmp
	li $v0, 15
	move $a0, $s0
	la $a1, ($t0)
	la $a2, ($t1)
	syscall
	
	li $v0, 16	#close file
	move $a0, $s0
	syscall	
	
	li $v0, 10
	syscall
	
program_ended_without_file:
	li $v0, 4
	la $a0, message3
	syscall
	
	li $v0, 10
	syscall

	