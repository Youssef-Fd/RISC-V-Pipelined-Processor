module datapath_single_cycle(
    input logic        clk,
    input logic        rst_n
);

    import riscv_opcodes_pkg::*;
    import alu_pkg::*;

    //Instruction Fields
    logic [31:0] instruction;
    logic [6:0]  opcode;
    logic [2:0]  funct3;
    logic [6:0]  funct7;

    //Register File
    logic [4:0]  rs1_addr;
    logic [4:0]  rs2_addr;
    logic [4:0]  rd_addr;
    logic [31:0] rd_data;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;

    //Program counter signals 
    logic [31:0] pc;
    logic [31:0] pc_next;
    logic [31:0] pc_plus_4;
    logic [31:0] pc_target;
 
    logic branch_taken;

    //ALU signals
    logic [31:0] alu_input_a, alu_input_b;
    logic [31:0] alu_result;

    // memory
    logic [31:0] mem_read_data;

    //Control signals
    logic       reg_write, mem_read, mem_write, branch, jump, jalr;
    logic [1:0] ALUsrc_1;
    logic       ALUsrc_2;
    alu_op_t    ALUop;
    logic [1:0] result_src;
    logic       uses_rs1, uses_rs2;

    // Sign-extended immediate
    logic [31:0] imm_ext;

    branch_resolve u_branch_resolve(
        .funct3(funct3),
        .rs1(rs1_data),
        .rs2(rs2_data),
        .branch_taken(branch_taken)
    );

    assign opcode = instruction[6:0];
    assign funct3 = instruction[14:12];
    assign funct7 = instruction[31:25];

    assign rs1_addr = instruction[19:15];
    assign rs2_addr = instruction[24:20];
    assign rd_addr  = instruction[11:7];

    assign pc_plus_4 = pc + 32'd4;
    assign pc_target = {alu_result[31:1], 1'b0};
    assign pc_next   = ((branch && branch_taken) || jump)  ? pc_target : pc_plus_4;

    always_ff @(posedge clk or posedge rst_n) begin
        if(rst_n) begin
            pc <= 32'd0;
        end else begin
            pc <= pc_next;
        end
    end

    I_mem u_i_mem(
        .addr(pc),
        .instr(instruction)
    );

    control_unit u_control_unit(
        .opcode (opcode),
        .funct3 (funct3),
        .funct7 (funct7),
        .reg_write (reg_write),
        .mem_read (mem_read),
        .mem_write (mem_write),
        .branch (branch),
        .jump (jump),
        .jalr (), // unused for now
        .ALUsrc_1 (ALUsrc_1),
        .ALUsrc_2 (ALUsrc_2),
        .ALU_op (ALUop),
        .result_src (result_src)
    ); 

    imm_gen u_imm_gen(
        .instr (instruction),
        .imm (imm_ext)
    );

    regfile u_register_file(
        .clk (clk),
        .we (reg_write),
        .rs1_addr (rs1_addr),
        .rs2_addr (rs2_addr),
        .rd_addr (rd_addr),
        .rd_data (rd_data), // write back from ALU result
        .rs1_data (rs1_data),
        .rs2_data (rs2_data)
    );

    assign alu_input_b = (ALUsrc_2) ? imm_ext : rs2_data;

    always @(*) begin
        case(ALUsrc_1)
            2'b00: alu_input_a = rs1_data;
            2'b01: alu_input_a = pc;
            2'b10: alu_input_a = 32'b0;
            default: alu_input_a = rs1_data; // should not happen
        endcase
    end

    alu u_alu(
        .alu_a(alu_input_a),
        .alu_b(alu_input_b),
        .alu_op(ALUop),
        .alu_out(alu_result),
        .alu_zero() 
    );

    D_mem u_d_mem(  
        .clk (clk),
        .mem_read (mem_read),
        .mem_write (mem_write),
        .addr (alu_result),
        .write_data (rs2_data),
        .read_data (mem_read_data)
    );

    always @(*) begin
        case (result_src)
            2'b00: rd_data = alu_result;
            2'b01: rd_data = mem_read_data;
            2'b10: rd_data = pc_plus_4;
            default: rd_data = alu_result;
        endcase
    end

endmodule


