	.eqv	SYS_EXIT0, 10
	.eqv	PRINT_STRING, 4
	.eqv	READ_STRING, 8
	.eqv	FLAG_READ, 0
	.eqv	FLAG_WRITE, 1
	.eqv	FILE_CLOSE, 57
	.eqv	FILE_READ, 63
	.eqv	FILE_WRITE, 64
	.eqv	FILE_OPEN, 1024
	.eqv	BUFFSIZE, 512
	
	.data
file_out:		.asciz "byte_array.c"			# Out file directory
prompt:			.asciz "File to convert: "
input_stream:	.space BUFFSIZE
output_stream:	.space BUFFSIZE
integer:		.space BUFFSIZE
hexadecimal:	.space BUFFSIZE
file:			.space BUFFSIZE

	.text	
main:
	###### Getting directory of file from the user ######
	la		a0, prompt
	li		a7, PRINT_STRING
	ecall
	la		a0, file
	li		a1, BUFFSIZE
	li		a7, READ_STRING
	ecall
	li		t4, ' '
	la		t5, file
	addi	t5, t5, -1
	###### Replacing \n with \0 in the given string ######
correcting_string:
	addi	t5, t5, 1
	lb		t6, (t5)
	bgeu	t6, t4, correcting_string
	li		t4, 0
	sb		t4, (t5)	
	###### Opening/Creating files ######
	li		a7, FILE_OPEN
	###### Opening file to read ######
	la		a0, file
	li		a1, FLAG_READ
	ecall
	mv		s0, a0				# Saving file's decriptor
	###### Creating .c file to write into ######
	la		a0, file_out		# file name: byte_array.c
	li		a1, FLAG_WRITE
	ecall
	mv		s1, a0				# Saving created file's decriptor
	la		s2, input_stream
	la		s3, output_stream
	li		t2, 0				# Counter of written currently bytes into output stream
	li		t4, 0				# Total bytes counter
	li		t1, 0				# No. of bytes left to read in buffer
	###### Writing opening of the array ######
	jal		text_initialize_array	# unsigned char var[]={
	bltz	s0, closing
	###### Begining of the read/process/write loop ######
output_filling:
	jal		getc				# Getting next bytes
	bltz	t0, closing			# Ending if we recieved negative value
	mv		s8, t0
	andi	t3, t4, 255
	beqz	t3, offset			# Checking if we are at end of 16-nth line
	andi	t3, t4, 15
	beqz	t3, newline			# Checking if we are ending line
	b		get_byte
offset: 						# Offset before each 16-nth line
	jal		end_line			# CRLF
	jal		comment				# //
	jal		text_0x				# 0x
	###### Converting no. of bytes into hexadecimal number ######
	mv		t0, t4
	la		t5, hexadecimal
offset_hex:
	mv		s6, t0
	jal		convert_hex_digit		
	sb		s6, (t5)
	addi	t5, t5, 1
	srli	t0, t0, 4
	bnez	t0, offset_hex
	la		t6, hexadecimal
	###### Puting converted offset into outputstream ######
fill_offset:
	addi 	t5, t5, -1
	lb		t0, (t5)
	jal		putc
	bne		t5, t6, fill_offset	
newline: 
	jal		end_line			# CRLF
	li		t3, 0
get_byte:
	###### Converting byte to hexadecimal ######
	jal		text_0x				# 0x
	mv		s6, s8
	jal		convert_hex_digit
	mv		t3, s6
	srli	s8, s8, 4
	mv		s6, s8
	jal		convert_hex_digit
	mv		t0, s6
	jal		putc				#
	mv		t0, t3				# Inputing, converted to hexadecimal, byte
	jal		putc				#
	addi	t4, t4, 1
	li		t0, ','
	jal		putc
	li		t0, ' '				# ', ' between two bytes
	jal		putc	
	b		output_filling		# Puting bytes into output till we hadn't got every byte from input stream
closing:
	###### Closing array & Writing number of bytes in the given file ######
	jal		text_bytes			# //Bytes: (no. of bytes)
	###### Converting int to string ######
	la		t5, integer
convert_decimal:
	li		t6, 10
	remu	t3, t4, t6
	addi	t3, t3, '0'
	sb		t3, (t5)
	addi	t5, t5, 1
	div		t4, t4, t6	
	bnez	t4, convert_decimal
	la		t6, integer
	###### Actual writing of number of bytes ######	
filling_int:
	addi	t5, t5, -1
	lb		t0, (t5)
	jal		putc
	bne		t5, t6, filling_int
	jal		write				# Wrtiing reamining bytes
fin:
	###### Closing files ######
	li		a7, FILE_CLOSE
	###### Closing given file ######
	mv		a0, s0
	ecall
	###### Closing created file ######
	mv		a0, s1
	ecall
	li		a7, SYS_EXIT0
	ecall
		
	######### FUNCTIONS: #########
	
getc:	###### getc fucntion, gets next single char from the input stream and stores it into t0 register ######
	bgtz	t1, get				# If we need we will read new 512 bytes from the file
	la		s2, input_stream
	mv		a0, s0
	la		a1, input_stream
	li		a2, BUFFSIZE
	li		a7, FILE_READ
	ecall
	mv		t1, a0				# Length read	
get:
	beqz	a0, return_negative
	lbu		t0, (s2)
	addi	t1, t1, -1
	addi	s2, s2, 1	
	ret
return_negative:
	li		t0, -1
	ret

putc:	###### putc function, inputs single char on the next space in the output stream from the t0 register ######
	sb		t0, (s3)
	addi	s3, s3, 1
	addi	t2, t2, 1
	andi	s5, t2, 511			# If bufffer is filled 
	beqz	s5, write			# we will write it into the file
	ret	

write:	###### Wrtie function, resets counter and address of output stream ######
	mv		a0, s1
	la		a1, output_stream
	mv		a2, t2
	li		a7, FILE_WRITE
	ecall	
	li		t2, 0
	la		s3, output_stream 	
	ret

end_line:
	addi	sp, sp, -4
	sw		ra, 0(sp)
	li		t0, 13
	jal		putc
	li		t0, 10
	jal		putc
	lw		ra, 0(sp)
	addi	sp, sp, 4
	ret	

convert_hex_digit: ###### Obtains hexadecimal digit from s6 to s6 ######
	andi	s6, s6, 15
	addi	s6, s6, '0'
	li		t6, '9'
	bleu	s6, t6, hex_upper
	addi	s6, s6, 7
hex_upper:
	ret

text_initialize_array:
	addi	sp, sp, -4
	sw		ra, 0(sp)
	li		t0, 'u'
	jal		putc
	li		t0, 'n'
	jal		putc
	li		t0, 's'
	jal		putc
	li		t0, 'i'
	jal		putc
	li		t0, 'g'
	jal		putc
	li		t0, 'n'
	jal		putc
	li		t0, 'e'
	jal		putc
	li		t0, 'd'
	jal		putc
	li		t0, ' '
	jal		putc
	li		t0, 'c'
	jal		putc
	li		t0, 'h'
	jal		putc
	li		t0, 'a'
	jal		putc
	li		t0, 'r'
	jal		putc
	li		t0, ' '
	jal		putc
	li		t0, 'v'
	jal		putc
	li		t0, 'a'
	jal		putc
	li		t0, 'r'
	jal		putc
	li		t0, '['
	jal		putc
	li		t0, ']'
	jal		putc
	li		t0, '='
	jal		putc
	li		t0, '{'
	jal		putc
	lw		ra, 0(sp)
	addi	sp, sp, 4
	ret

text_bytes:
	addi	sp, sp, -4
	sw		ra, 0(sp)
	jal		end_line
	li		t0, '}'
	jal		putc
	li		t0, ';'
	jal		putc
	jal		end_line
	jal		comment
	li		t0, 'B'
	jal		putc
	li		t0, 'y'
	jal		putc
	li		t0, 't'
	jal		putc
	li		t0, 'e'
	jal		putc
	li		t0, 's'
	jal		putc
	li		t0, ':'
	jal		putc
	li		t0, ' '
	jal		putc
	lw		ra, 0(sp)
	addi	sp, sp, 4
	ret

text_0x:
	addi	sp, sp, -4
	sw		ra, 0(sp)
	li		t0, '0'
	jal		putc
	li		t0, 'x'
	jal		putc
	lw		ra, 0(sp)
	addi	sp, sp, 4
	ret

comment:
	addi	sp, sp, -4
	sw		ra, 0(sp)
	li		t0, '/'
	jal		putc
	jal		putc
	lw		ra, 0(sp)
	addi	sp, sp, 4
	ret
