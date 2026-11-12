module alu(
    input  logic [31:0] alu_a,
    input  logic [31:0] alu_b,
    input  alu_pkg::alu_op_t alu_op,
    output logic [31:0] alu_out,
    output logic alu_zero
);

   import alu_pkg::*;

   always @(*) begin
       
        case (alu_op)
            ALU_ADD: alu_out = alu_a + alu_b;
            ALU_SUB: alu_out = alu_a - alu_b;
            ALU_AND: alu_out = alu_a & alu_b;
            ALU_OR:  alu_out = alu_a | alu_b;
            ALU_XOR: alu_out = alu_a ^ alu_b;
            ALU_SLL: alu_out = alu_a << alu_b[4:0];
            ALU_SRL: alu_out = alu_a >> alu_b[4:0];
            ALU_SRA: alu_out = $signed(alu_a) >>> alu_b[4:0];
            ALU_SLT: alu_out = ($signed(alu_a) < $signed(alu_b)) ? 32'b1 : 32'b0;        
            ALU_SLTU: alu_out = (alu_a < alu_b) ? 32'b1 : 32'b0;
            default: alu_out = 32'b0;
        endcase

    end

    assign alu_zero = (alu_out == 32'b0) ? 1'b1 : 1'b0;

endmodule
