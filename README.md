# FileIntoByteArray

Program created using RARS - RISC-V assembler and runtime simualtor.

Program converts any given file into C language file representing the content of the original one as an array of bytes.

For readeability of the array contents the array is formated in the following way:
  - 16 bytes per line
  - Offsets in comments before each 16 lines
  - Total size in final comment

the output file is named: byte_array.c
