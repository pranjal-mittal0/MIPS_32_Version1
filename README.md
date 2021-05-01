MIPS:- Microprocessor without Interlocked Pipelined Stages is a 32 bit
RISC ISA. In this project, I have implemented a 5 stage Pipelined Processor
processing various instruction at a single clock Cycle. Only a small set of
instruction is implemented.
Characteristics:
1) 32, 32 bit GPRs,R0-R31
2) A special purpose 32 bit PC
3) No Flags Registers
4) Addressing modes- Register, immediate and register indexed
5) Only load and store instructions can access memory
6) Memory word size is 32 bits and is word addressable.
7) One Read and two Write Port
Instruction Subset:
1) Load and Store Instructions
2) Arithmetic and logic instruction(only register operands and
Immediate operand)
1) ADD R1,R2,R0 // R1 = R2 + 0
2) SUB R12,R10,R8 // R12 = R10 – R8
3) AND R20,R1,R5 // R20 = R1 & R5
4) OR R11,R5,R6 // R11 = R5 | R6
5) MUL R5,R6,R7
// R5 = R6 * R7
6) SLT R5,R11,R12
7) ADDI R1,R2,25
8) SUBI R5,R1,150
9) SLTI R2,R10,10
3) Branch Instructions
Academic Report
21) BEQZ R1,Loop
2) BNEQZ R5,Label
4) Miscellaneous Instruction
1) HLT


To know more please refer this link:-" https://drive.google.com/file/d/1M3elHzYxrQsOYWBfFgzjtk69ndPGDvMS/view?usp=sharing"