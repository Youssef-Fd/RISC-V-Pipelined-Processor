package riscv_opcodes_pkg;
    
    typedef enum logic [6:0] 
    {
        OPC_OP     = 7'b0110011, // R-type: add, sub, and, or, xor, sll, srl, sra, slt, sltu
        OPC_LOAD   = 7'b0000011, // I-type: lb, lh, lw, lbu, lhu
        OPC_OP_IMM = 7'b0010011, // I-type: addi, andi, ori, xori, slli, srli, srai, slti, sltiu
        OPC_STORE  = 7'b0100011, // S-type: sb, sh, sw
        OPC_BRANCH = 7'b1100011, // B-type: beq, bne, blt, bge, bltu, bgeu 
        OPC_JALR   = 7'b1100111, // I-type: jalr 
        OPC_LUI    = 7'b0110111, // U-type: lui
        OPC_AUIPC  = 7'b0010111, // U-type: auipc
        OPC_JAL    = 7'b1101111  // J-type: jal
    } opcode_t;

endpackage 