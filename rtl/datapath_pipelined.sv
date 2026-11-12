module datapath_pipelined(
    input  logic        clk,
    input  logic        rst_n,

    output logic [31:0] debug_out,
    output logic        debug_valid,
    output logic [31:0] debug_pc,
    output logic [31:0] debug_instr,
    output logic [31:0] debug_alu
);

    import riscv_opcodes_pkg::*;
    import alu_pkg::*;
    import pipeline_pkg::*;

    if_id_reg_t  if_id,  if_id_next;
    id_ex_reg_t  id_ex,  id_ex_next;
    ex_mem_reg_t ex_mem, ex_mem_next;
    mem_wb_reg_t mem_wb, mem_wb_next;


    //----------------INSTRUCTION FETCH------------------//
    logic [31:0] pc;
    logic [31:0] pc_plus_4;
    logic [31:0] pc_next;

    logic [31:0] if_instruction;

    logic [31:0] ex_redirect_target;
    logic        ex_redirect_valid;

    logic        stall;

    assign pc_plus_4 = pc + 32'd4;
    assign pc_next = ex_redirect_valid ? ex_redirect_target : pc_plus_4;

    always @(posedge clk, posedge rst_n) begin
        if(rst_n) begin
            pc <= 32'd0;
        end else if(!stall) begin
            pc <= pc_next;
        end
    end

    I_mem #(
        .DEPTH_WORDS(256),
        .IMEM_INIT_FILE("prog_pipeline.mem")
    ) u_i_mem(
        .addr(pc),
        .instr(if_instruction)
    );

    //if_id pipeline register
    logic flush_id;
    assign flush_id = ex_redirect_valid;

    always @(*) begin
        if_id_next.pc        = pc;
        if_id_next.pc_plus_4 = pc_plus_4;
        if_id_next.instr     = if_instruction;
        if_id_next.valid     = 1'b1;
    end

    always_ff @(posedge clk, posedge rst_n) begin
        if(rst_n) begin
            if_id <= '0;
        end else if(flush_id) begin
            if_id <= '0;
        end else if(!stall) begin
            if_id <= if_id_next;
        end
    end

    //-----------------INSTRUCTION DECODE---------------//
    logic [6:0]  opcode;
    logic [2:0]  funct3;
    logic [6:0]  funct7;

    logic [4:0]  rs1_addr;
    logic [4:0]  rs2_addr;
    logic [4:0]  rd_addr;
    logic [31:0] rd_data;
    logic [31:0] rs1_data;
    logic [31:0] rs2_data;
    logic [31:0] wb_data;

    logic       reg_write, mem_read, mem_write, branch, jump, jalr;
    logic [1:0] ALUsrc_1;
    logic       ALUsrc_2;
    alu_op_t    ALUop;
    logic [1:0] result_src;
    logic       uses_rs1, uses_rs2;

    assign opcode   = if_id.instr[6:0];
    assign rd_addr  = if_id.instr[11:7];
    assign funct3   = if_id.instr[14:12];
    assign rs1_addr = if_id.instr[19:15];
    assign rs2_addr = if_id.instr[24:20];
    assign funct7   = if_id.instr[31:25];

    control_unit u_control_unit(
        .opcode (opcode),
        .funct3 (funct3),
        .funct7 (funct7),
        .reg_write (reg_write),
        .mem_read (mem_read),
        .mem_write (mem_write),
        .branch (branch),
        .jump (jump),
        .jalr (jalr),
        .ALUsrc_1 (ALUsrc_1),
        .ALUsrc_2 (ALUsrc_2),
        .ALU_op (ALUop),
        .result_src (result_src),
        .uses_rs1(uses_rs1),
        .uses_rs2(uses_rs2)
    ); 

    regfile u_register_file(
        .clk (clk),

        // Comming from wb stage
        .we (mem_wb.reg_write),
        .rd_addr (mem_wb.rd_addr),
        .rd_data (wb_data),

        // Coming from if/id stage
        .rs1_addr (rs1_addr),
        .rs2_addr (rs2_addr),
        .rs1_data (rs1_data),
        .rs2_data (rs2_data)
    );

    logic [31:0] imm_ext;

    imm_gen u_imm_gen(
        .instr (if_id.instr),
        .imm (imm_ext)
    );

    //hazard detection
    hazard_unit u_hazard_unit(
        .id_ex_mem_read(id_ex.mem_read),
        .id_ex_rd_addr(id_ex.rd_addr),
        .id_rs1_addr(rs1_addr),
        .id_rs2_addr(rs2_addr),
        .id_uses_rs1(uses_rs1),
        .id_uses_rs2(uses_rs2),
        .stall(stall)
    );
    
    logic flush_ex;
    assign flush_ex = ex_redirect_valid || stall;

    always @(*) begin
        id_ex_next.pc         = if_id.pc;
        id_ex_next.pc_plus_4  = if_id.pc_plus_4;  
        id_ex_next.rs1_data   = rs1_data;
        id_ex_next.rs2_data   = rs2_data;
        id_ex_next.imm        = imm_ext;
        id_ex_next.rs1_addr   = rs1_addr;
        id_ex_next.rs2_addr   = rs2_addr;
        id_ex_next.rd_addr    = rd_addr;
        id_ex_next.funct3     = funct3;
        id_ex_next.reg_write  = reg_write;
        id_ex_next.mem_read   = mem_read;
        id_ex_next.mem_write  = mem_write;
        id_ex_next.branch     = branch;
        id_ex_next.jump       = jump;
        id_ex_next.ALUsrc_1   = ALUsrc_1;
        id_ex_next.ALUsrc_2   = ALUsrc_2;
        id_ex_next.ALU_op     = ALUop;
        id_ex_next.result_src = result_src;
        id_ex_next.valid      = if_id.valid; 
    end

    always_ff @(posedge clk, posedge rst_n) begin
        if(rst_n) begin
            id_ex <= '0;
        end else if(flush_ex) begin
            id_ex <= '0;
        end else begin
            id_ex <= id_ex_next;
        end
    end

    //------------------EXECUTE--------------//
    logic [1:0] forward_a, forward_b;
    forwarding_unit u_forwarding_unit (
        .id_ex_rs1_addr   (id_ex.rs1_addr),
        .id_ex_rs2_addr   (id_ex.rs2_addr),
        .ex_mem_rd_addr   (ex_mem.rd_addr),
        .ex_mem_reg_write (ex_mem.reg_write),
        .mem_wb_rd_addr   (mem_wb.rd_addr),
        .mem_wb_reg_write (mem_wb.reg_write),
        .forward_a        (forward_a),
        .forward_b        (forward_b)
    );

    logic [31:0] forwarded_rs1, forwarded_rs2;
    logic [31:0] ex_mem_forward_value;
    logic [31:0] mem_read_data;

    assign ex_mem_forward_value = ex_mem.mem_read ? mem_read_data : ex_mem.alu_result;

    always @(*) begin
        case(forward_a)
            2'b00: forwarded_rs1 = id_ex.rs1_data;
            2'b01: forwarded_rs1 = wb_data;
            2'b10: forwarded_rs1 = ex_mem_forward_value;
            default: forwarded_rs1 = id_ex.rs1_data;
        endcase

        case(forward_b) 
            2'b00: forwarded_rs2 = id_ex.rs2_data;
            2'b01: forwarded_rs2 = wb_data;
            2'b10: forwarded_rs2 = ex_mem_forward_value;
            default: forwarded_rs2 = id_ex.rs2_data;
        endcase
    end

    logic [31:0] alu_op_a, alu_op_b;

    always @(*) begin
        case (id_ex.ALUsrc_1)
            2'b00: alu_op_a = forwarded_rs1;
            2'b01: alu_op_a = id_ex.pc;
            2'b10: alu_op_a = 32'd0;
            default: alu_op_a = forwarded_rs1;
        endcase
        case (id_ex.ALUsrc_2)
            1'b0: alu_op_b = forwarded_rs2;
            1'b1: alu_op_b = id_ex.imm;
            default: alu_op_b = forwarded_rs2;
        endcase
    end

    logic [31:0] alu_result;
    alu u_alu (
        .alu_a(alu_op_a),
        .alu_b(alu_op_b),
        .alu_op(id_ex.ALU_op),
        .alu_out(alu_result),
        .alu_zero()
        
    );

    //branch resolve
    logic branch_taken;

    branch_resolve u_branch_resolve (
        .funct3       (id_ex.funct3),
        .rs1          (forwarded_rs1),
        .rs2          (forwarded_rs2),
        .branch_taken (branch_taken)
    );

    assign ex_redirect_valid  = id_ex.valid && (id_ex.jump || (id_ex.branch && branch_taken));
    assign ex_redirect_target = {alu_result[31:1], 1'b0};

     always @(*) begin
        ex_mem_next.pc_plus_4  = id_ex.pc_plus_4;
        ex_mem_next.alu_result = alu_result;
        ex_mem_next.rs2_data   = forwarded_rs2;   // for store instruction
        ex_mem_next.rd_addr    = id_ex.rd_addr;
        ex_mem_next.reg_write  = id_ex.reg_write;
        ex_mem_next.mem_read   = id_ex.mem_read;
        ex_mem_next.mem_write  = id_ex.mem_write;
        ex_mem_next.result_src = id_ex.result_src;
        ex_mem_next.valid      = id_ex.valid;
    end

    always_ff @(posedge clk, posedge rst_n) begin
        if(rst_n) begin
            ex_mem <= '0;
        end else begin
            ex_mem <= ex_mem_next;
        end
    end

    //--------------MEMORY ACCESS-------------//
    D_mem #(
        .DEPTH_WORDS (256),
        .PRELOAD     (1'b0)
    ) u_d_mem (
        .clk        (clk),
        .mem_read   (ex_mem.mem_read),
        .mem_write  (ex_mem.mem_write),
        .addr       (ex_mem.alu_result),
        .write_data (ex_mem.rs2_data),
        .read_data  (mem_read_data)
    );

    // MEM/WB Pipeline Register
    always @(*) begin
        mem_wb_next.pc_plus_4     = ex_mem.pc_plus_4;
        mem_wb_next.alu_result    = ex_mem.alu_result;
        mem_wb_next.mem_read_data = mem_read_data;
        mem_wb_next.rd_addr       = ex_mem.rd_addr;
        mem_wb_next.reg_write     = ex_mem.reg_write;
        mem_wb_next.result_src    = ex_mem.result_src;
        mem_wb_next.valid         = ex_mem.valid;
    end

    always_ff @(posedge clk or posedge rst_n) begin
        if (rst_n) begin
            mem_wb <= '0;
        end else begin
            mem_wb <= mem_wb_next;
        end 
    end

    //-----------------WRITE BACK---------------//
    always @(*) begin
        case(mem_wb.result_src)
            2'b00: wb_data = mem_wb.alu_result;
            2'b01: wb_data = mem_wb.mem_read_data;
            2'b10: wb_data = mem_wb.pc_plus_4;
            default: wb_data = mem_wb.alu_result;
        endcase
    end

    assign debug_out   = wb_data;
    assign debug_pc    = pc;
    assign debug_instr = if_id.instr;
    assign debug_alu   = alu_result;

endmodule
