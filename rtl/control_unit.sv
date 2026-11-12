// control_unit.sv -- RV32I Control Unit
// Purely combinational. Decodes opcode/funct3/funct7 into every
// control signal the rest of the datapath needs.

module control_unit (
    input  logic [6:0] opcode,
    input  logic [2:0] funct3,
    input  logic [6:0] funct7,

    output logic       jump,
    output logic       jalr,
    output logic       branch,
    output logic       mem_read,
    output logic [1:0] result_src,  
    output alu_pkg::alu_op_t ALU_op,
    output logic       mem_write,
    output logic [1:0] ALUsrc_1,
    output logic       ALUsrc_2,
    output logic       reg_write,
    output logic       uses_rs1,
    output logic       uses_rs2
);

    import riscv_opcodes_pkg::*;
    import alu_pkg::*;

    always @(*) begin

        // Default values
        jump        = 1'b0;
        jalr        = 1'b0;
        branch      = 1'b0;
        mem_read    = 1'b0;
        result_src  = 2'b00;  
        ALU_op       = ALU_ADD;
        mem_write   = 1'b0;
        ALUsrc_1    = 2'b00;
        ALUsrc_2    = 1'b0;
        reg_write   = 1'b0;
        uses_rs1    = 1'b0;
        uses_rs2    = 1'b0;

        case (opcode_t'(opcode))
            
            // R-type instructions
            OPC_OP: begin
                reg_write  = 1'b1;
                uses_rs1   = 1'b1;
                uses_rs2   = 1'b1;
                ALUsrc_1   = 2'b00; // rs1
                ALUsrc_2   = 1'b0;     // rs2
                result_src = 2'b00; // ALU result

                case (funct3)
                    3'b000: if (funct7[5] == 0) ALU_op = ALU_ADD; else ALU_op = ALU_SUB; // add/sub
                    3'b001: ALU_op = ALU_SLL; // sll
                    3'b010: ALU_op = ALU_SLT; // slt
                    3'b011: ALU_op = ALU_SLTU; // sltu
                    3'b100: ALU_op = ALU_XOR; // xor
                    3'b101: if (funct7[5] == 0) ALU_op = ALU_SRL ; else ALU_op = ALU_SRA; // srl/sra
                    3'b110: ALU_op = ALU_OR; // or
                    3'b111: ALU_op = ALU_AND; // and
                    default: ALU_op = ALU_ADD; // default to add
                endcase
            end

            //I-type instructions
            OPC_OP_IMM: begin
                reg_write  = 1'b1;
                uses_rs1   = 1'b1;
                ALUsrc_1   = 2'b00; // rs1
                ALUsrc_2   = 1'b1;     // immediate
                result_src = 2'b00; // ALU result

                case (funct3)
                    3'b000: ALU_op = ALU_ADD; // addi
                    3'b001: ALU_op = ALU_SLL; // slli
                    3'b010: ALU_op = ALU_SLT; // slti
                    3'b011: ALU_op = ALU_SLTU; // sltiu
                    3'b100: ALU_op = ALU_XOR; // xori
                    3'b101: if (funct7[5] == 0) ALU_op = ALU_SRL ; else ALU_op = ALU_SRA;
                    3'b110: ALU_op = ALU_OR; // ori
                    3'b111: ALU_op = ALU_AND; // andi
                    default: ALU_op = ALU_ADD; // default to addi
                endcase
            end

            // Load instructions
            OPC_LOAD: begin
                reg_write  = 1'b1;
                mem_read   = 1'b1;
                uses_rs1   = 1'b1;
                ALUsrc_1   = 2'b00; // rs1
                ALUsrc_2   = 1'b1;  //immediate 
                ALU_op      = ALU_ADD; 
                result_src = 2'b01; // memory data
            end

            // Store instructions
            OPC_STORE: begin
                mem_write  = 1'b1;
                uses_rs1   = 1'b1;
                uses_rs2   = 1'b1;
                ALUsrc_1   = 2'b00; // rs1
                ALUsrc_2   = 1'b1;  // immediate (address = rs1 + imm)
                ALU_op      = ALU_ADD; // address calculation
            end

            // Branch instructions
            OPC_BRANCH: begin
                branch     = 1'b1;
                uses_rs1   = 1'b1;
                uses_rs2   = 1'b1;
                ALUsrc_1   = 2'b01; // pc
                ALUsrc_2   = 1'b1;  // immediate 
                ALU_op      = ALU_ADD;
            end

            // JAL instruction: unconditional jump
            // rd <- pc  + 4 / pc = pc + imm
            OPC_JAL: begin
                jump       = 1'b1;
                reg_write  = 1'b1; // write return address to rd
                ALUsrc_1   = 2'b01; // pc
                ALUsrc_2   = 1'b1;  // immediate 
                ALU_op      = ALU_ADD; // calculate return address
                result_src = 2'b10; // return address (pc + 4)
            end

            // JALR instruction: jump and link register
            // rd <- pc + 4 / pc = rs1 + imm
            OPC_JALR: begin
                jump       = 1'b1;
                jalr       = 1'b1;
                reg_write  = 1'b1; // write return address to rd
                ALUsrc_1   = 2'b00; // rs1
                ALUsrc_2   = 1'b1;  // immediate
                ALU_op      = ALU_ADD; 
                result_src = 2'b10; // return address (pc + 4)
                uses_rs1   = 1'b1; 
            end

            // LUI instruction: load upper immediate
            // rd <- imm (imm << 12 already done in imm_gen)
            OPC_LUI: begin
                reg_write  = 1'b1;
                ALUsrc_1   = 2'b10; // zero
                ALUsrc_2   = 1'b1;  // immediate
                ALU_op      = ALU_ADD; 
                result_src = 2'b00; // ALU result
            end

            // AUIPC instruction: add upper immediate to pc
            // rd <- pc  + imm
            OPC_AUIPC: begin
                reg_write  = 1'b1;
                ALUsrc_1   = 2'b01; // pc
                ALUsrc_2   = 1'b1;  // immediate
                ALU_op      = ALU_ADD; 
                result_src = 2'b00; // ALU result
            end

            default: ;
        endcase
        
    end

endmodule