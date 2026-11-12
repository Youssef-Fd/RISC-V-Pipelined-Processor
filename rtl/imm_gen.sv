 module imm_gen
(
    input  logic [31:0] instr,
    output logic [31:0] imm
);

    import riscv_opcodes_pkg::*;

    opcode_t opcode;
    assign opcode = opcode_t'(instr[6:0]);

    always @(*) begin
        case (opcode)

            OPC_LOAD, OPC_OP_IMM, OPC_JALR: begin
                // I-type: imm[11:0] lives in instr[31:20] with sign extended
                imm = {{20{instr[31]}}, instr[31:20]};
            end

            OPC_STORE: begin
                // S-type: imm[11:5] in instr[31:25], imm[4:0] in instr[11:7] with sign extended
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end

            OPC_BRANCH: begin
                // B-type: immediate encodes a branch offset, this exact bit order is per the RISC-V spec
                //   imm[12]   -> instr[31]
                //   imm[11]   -> instr[7]
                //   imm[10:5] -> instr[30:25]
                //   imm[4:1]  -> instr[11:8]
                //   imm[0]    -> always 0
                imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            end

            OPC_LUI, OPC_AUIPC: begin
                // U-type: immediate occupies the top 20 bits directly, bottom 12 bits are zero
                imm = {instr[31:12], 12'b0};
            end

            OPC_JAL: begin
                // J-type: 
                //   imm[20]    -> instr[31]
                //   imm[19:12] -> instr[19:12]
                //   imm[11]    -> instr[20]
                //   imm[10:1]  -> instr[30:21]
                //   imm[0]     -> always 0
                imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            end

            default: imm = 32'b0; 

        endcase
    end

endmodule




            