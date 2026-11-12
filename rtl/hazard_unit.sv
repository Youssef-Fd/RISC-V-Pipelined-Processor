// hazard_unit.sv -- Load-use hazard detection
module hazard_unit(
    input logic [4:0] id_rs1_addr,
    input logic [4:0] id_rs2_addr,
    input logic [4:0] id_ex_rd_addr,
    input logic id_ex_mem_read,
    input logic id_uses_rs1, id_uses_rs2,
    output logic stall
);

    always @(*) begin
        stall = id_ex_mem_read &&
                id_ex_rd_addr != 5'd0 && (
                ((id_ex_rd_addr == id_rs1_addr ) && id_uses_rs1) || 
                ((id_ex_rd_addr == id_rs2_addr) && id_uses_rs2));
    
    end

endmodule 