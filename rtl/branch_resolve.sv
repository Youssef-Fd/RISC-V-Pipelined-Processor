module branch_resolve(
    input  logic [2:0] funct3,
    input  logic [31:0] rs1,
    input  logic [31:0] rs2,
    output logic branch_taken 
);

    always @(*) begin
        case (funct3)
            3'h0: branch_taken = (rs1 == rs2); // beq
            3'h1: branch_taken = (rs1 != rs2); // bne
            3'h4: branch_taken = ($signed(rs1) < $signed(rs2)); // blt
            3'h5: branch_taken = ($signed(rs1) >= $signed(rs2)); // bge
            3'h6: branch_taken = (rs1 < rs2); // bltu
            3'h7: branch_taken = (rs1 >= rs2); // bgeu
        endcase
    end

endmodule
