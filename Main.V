// Copyright (c) 1st May Pranjal Mittal
//-------------------------------------------------------------------
//File name: MIPS32
//TYPE: Module
//Author Name: Pranjal Mittal
//Author email ID: pranjal.mittal1999@gmail.com
//-------------------------------------------------------------------
//Release History
// Version Date Author Description
// 1.0 1.05.21  Pranjal Mittal Final version
//-------------------------------------------------------------------
//keywords:- RISC, MIPS32
//PURPOSE: ACADEMIC PURPOSE
// Extra: The pdf is needed to be refered to understand it all

module pipe_MIOPS32( clk1, clk2);      // two input to the processor
    input clk1, clk2;                // Two phase clock 

    // stage wise we are defining the variables that will be the part of inter-stage latch and variable naming convention is described in the pdf

    reg[31:0] PC, IF_ID_IR, IF_ID_NPC; //latch variable for IF safestage

    reg[31:0] ID_EX_IR, ID_EX_NPC, ID_EX_A, ID_EX_B, ID_EX_Imm; //latch variable for ID stage

    reg[2:0] ID_EX_type, EX_MEM_type, MEM_WB_type; // defining the type of instruction after decoding register-register, register-memory,load, store, branch and halt.
                                                   // defined as "parameter RR_ALU=3'b000, RM_ALU=3'b001, LOAD=3'b010, STORE=3'b011, BRANCH=3'b100, HALT=3'b101 ;"
                                                   // so each stage after decoding will have a type variable of three bits to accomodate 6 type

    reg[31:0] EX_MEM_IR, EX_MEM_ALUOut, EX_MEM_B;  //latch variable for EX stage
    reg     EX_MEM_cond;   // //latch variable for EX stage. single bit for branch condition checking

    reg [31:0] MEM_WB_IR, MEM_WB_ALUOut, MEM_WB_LMD; //latch variable for MEM stage. LMD= Load Memory Data for load instruction

    reg[31:0] Reg[0:31];   //Register Bank [32*32]
    reg[31:0] Mem [0:1023];  // 1024*32 memory 

    
    parameter ADD=6'b000000, SUB=6'b000001, AND=6'b000010, OR=6'b000011, SLT=6'b000100, MUL=6'b000101, HLT=6'b111111, 
              LW=6'b001000, SW=6'b001001, ADDI=6'b0010101, SUBI=6'b001011, SLTI=6'b001100, BNEQZ=6'b001101, BEQZ=6'b001110;
              // defining the 6 bit opcode that are discussed in pdf
    parameter RR_ALU=3'b000, RM_ALU=3'b001, LOAD=3'b010, STORE=3'b011, BRANCH=3'b100, HALT=3'b101 ; //type of instruction.

    reg HALTED; // sets after a hlt inst. executes adn reached the WB stage

    reg TAKEN_BRANCH; //set after the decision to take a branch is known. Required to disable the instructions that have already entered the pipeline
                      // from making any stages. only set after ex stage. all writes will be disables


// Different stages of instruction

//-----------------------------------------------------------------------------------------------------------------------

    always @(posedge clk1)             // IF stage // triggered by clk 1
        if (HALTED==0)             // if halt flag is not set
            begin
                if (((EX_MEM_IR[31:26] == BEQZ) && (EX_MEM_cond==1))/* these values are calculated in ex stage of previous instruction*/ || 
                   ((EX_MEM_IR[31:26] == BNEQZ && (EX_MEM_cond ==0)))) 
                                                                      // checking wether the branch is being taken
                    begin   // if brach taken
                        IF_ID_IR <= #2 Mem[EX_MEM_ALUOut]; // we dont fetch IR from PC but the address in EX_MEM_ALUOut
                        TAKEN_BRANCH <= #2 1'b1;         // brach taken
                        IF_ID_NPC <= #2 EX_MEM_ALUOut + 1;  // next PC will be EX_MEM_ALUOut+1
                        PC <= #2 EX_MEM_ALUOut + 1;
                        
                    end
                else   // if not taken
                    begin
                        IF_ID_IR <= #2 Mem[PC];    // fetch IR from PC
                        IF_ID_NPC <= #2 PC + 1;    
                        PC <=PC + 1;
                    end
            end


//--------------------------------------------------------------------------------------------------------------------------
    always @(posedge clk2)      // ID stage // triggered by clk 2
        if (HALTED == 0)            
        // decoding will be done by case statements
        begin
            if(IF_ID_IR[25:21] == 5'b000000) // if rs of opcode is R0 then assign A to 0 as R0 is always zero. no need to access register bank
                ID_EX_A<=0;
            else 
                ID_EX_A       <= #2 Reg[IF_ID_IR[25:21]] ; // "rs" is loaded

            if (IF_ID_IR[20:16] == 5'b00000)  // if rt of opcode is R0 then assign A to 0 as R0 is always zero. no need to access register bank
                ID_EX_B <= 0;
            else 
                ID_EX_B <= #2 Reg[IF_ID_IR[20:16]];  // "rt" is loaded

            // then normal things
            ID_EX_NPC <= #2 IF_ID_NPC; // forwarding of NPC
            ID_EX_Ir <= #2 IF_ID_IR;   // forwarding of IR
            ID_EX_Imm <= #2 {{{16{IF_ID_IR[15]}}} /*16 time replication of sign bit*/, {IF_ID_IR[15:0]}};   // sign extension 
             
            case (IF_ID_IR[31:26])  // setting the type of opcode
                ADD,SUB,AND,OR,SLT,MUL: ID_EX_type <= #2 RR_ALU;
                ADDI,SUBI,SLTI:         ID_EX_type <= #2 RM_ALU;
                LW:                     ID_EX_type <= #2 LOAD;
                SW:                     ID_EX_type <= #2 STORE;
                BNEQZ,BEQZ:             ID_EX_type <= #2 BRANCH;
                HLT:                    ID_EX_type <= #2 HALT;
                default:                ID_EX_type <= #2 HALT;    // invalid opcode
                // these type will be forwarded with each cycle
            endcase
        end

///----------------------------------------------------------------------------------------------------------------------------------
    always @ (posedge clk1)  // EX stage // triggered by clk1
        if (HALTED ==0)
            begin
                EX_MEM_type <= #2 ID_EX_type; // type is forwarded
                EX_MEM_IR <= #2 ID_EX_IR;     // IR is forwarded
                TAKEN_BRANCH <= #2 0;         // taken branch is set to 0 as this flag was set in IF stage if branch taken. as from next instruction PC will be updated
                                              // and now we need to reset the flag.
                case (ID_EX_type)             // this is type of decoding here using case statement as we need not to decode it in ID stage. we just declared type.
                    RR_ALU:       // register register ALU
                        begin
                            case ( ID_EX_IR[31:26]) //"opcode"
                                ADD: EX_MEM_ALUOut <= #2 ID_EX_A+ID_EX_B;
                                SUB: EX_MEM_ALUOut <= #2 ID_EX_B - ID_EX_B;
                                AND: EX_MEM_ALUOut <= #2 ID_EX_A & ID_EX_B;
                                OR:  EX_MEM_ALUOut <= #2 ID_EX_A | ID_EX_B;
                                SLT: EX_MEM_ALUOut <= #2 ID_EX_A < ID_EX_B;       // true then 1 is stored in ALUOut else 0
                                MUL: EX_MEM_ALUOut <= #2 ID_EX_A * ID_EX_B;
                                default: EX_MEM_ALUOut <= #2 32'hxxxxxxxx;
                            endcase
                        end
                    RM_ALU:       // Register memory ALU i.e immediate
                        begin
                            case (ID_EX_IR[31:26]) //opcode
                                ADDI: EX_MEM_ALUOut <= #2 ID_EX_A+ ID_EX_Imm;
                                SUBI: EX_MEM_ALUOut <= #2 ID_EX_A - ID_EX_Imm;
                                SLTI: EX_MEM_ALUOut<= #2 ID_EX_A < ID_EX_Imm;
                                default: EX_MEM_ALUOut <= #2 32'hxxxxxxxx
                            endcase
                        end
                    LOAD, STORE:   // load and store instruction
                        begin
                            EX_MEM_ALUOut <= #2 ID_EX_A + ED_EX_Imm;         // address is calculated
                            EX_MEM_B      <= #2 ID_EX_B;       // address is forwarded.
                        end
                    BRANCH:              // branch instruction
                        begin
                            EX_MEM_ALUOut <= #2 ID_EX_NPC + ID_EX_Imm;   // calculation of branch address.
                            EX_MEM_cond   <= #2 (ID_EX_A== 0);           //evaluating cond...and we will use this value in next instruction's IF stage to take the branch
                                                                         // "EX_MEM_IR[31:26] == BEQZ) && (EX_MEM_cond==1)"
                        end
                endcase
            end
//-------------------------------------------------------------------------------------------------------------------------------------
    always @(posedge clk2)              // MEM stage
        if (HALTED == 0)
            begin
                MEM_WB_type <= #2 EX_MEM_type;          // type is forwarded
                MEM_WB_IR   <= #2 EX_MEM_IR;         //IR is forwarded

                case (EX_MEM_type)
                    RR_ALU, RM_ALU:    //register-register or register-memory 
                        MEM_WB_ALUOut    <= #2 EX_MEM_ALUOut;     //just forward the value
                    LOAD:     // if load
                        MEM_WB_LMD      <= #2 MEM[EX_MEM_ALUOut];       // access memory address calculated in ex stage and store in LMD
                    STORE:     // if store
                        if(TAKEN_BRANCH==0) //Disable write if branch is taken**************
                            Mem[EX_MEM_ALUOut] <= #2 EX_MEM_B; // if no brach taken write the data to memory.
                endcase 

            end
//------------------------------------------------------------------------------------------------------------------------------------------
    always @ (posedge clk1) // WB stage
        begin
            if(TAKEN_BRANCH == 0)  // only do when branch is not taken...if taken disable writes
                case (MEM_WB_type)
                    RR_ALU:
                        Reg[MEM_WB_IR[15:11]] <= #2 MEM_WB_ALUOut; //rd is destination reg
                    RM_ALU:
                        Reg[MEM_WB_IR[20:16]] <= #2 MEM_WB_ALUOut; //rt is destination reg
                    LOAD: 
                        Reg[MEM_WB_IR[20:16]] <= #2 MEM_WB_LMD;    //rt is destination reg
                    HALT:
                        HALTED <= #2 1'b1;  //now here we are halting the machine if it is halt instruction.
                endcase
        end
endmodule