package alu_pkg;

	typedef enum logic[3:0]{
        	ALU_ADD  = 4'b0_000,
        	ALU_SUB  = 4'b1_000,
        	ALU_AND  = 4'b0_111,
        	ALU_OR   = 4'b0_110,
        	ALU_XOR  = 4'b0_100,
        	ALU_SLL  = 4'b0_001,   // shift left logical
        	ALU_SRL  = 4'b0_101,   // shift right logical
        	ALU_SRA  = 4'b1_101,   // shift right arithmetic
        	ALU_SLT  = 4'b0_010,   // set less than signed
        	ALU_SLTU = 4'b0_011    // set less than unsigned
	} alu_op_t;

endpackage