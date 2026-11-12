package pipeline_pkg;

    import alu_pkg::*;

    // IF/ID
    typedef struct packed {
        logic [31:0] pc;
        logic [31:0] pc_plus_4;
        logic [31:0] instr;
        logic        valid;
    } if_id_reg_t;

    //ID/EX
    typedef struct packed {
        logic [31:0] pc;
        logic [31:0] pc_plus_4;
        logic [4:0] rs1_addr;
        logic [4:0] rs2_addr;
        logic [4:0] rd_addr;
        logic [31:0] imm;
        logic [31:0] rs1_data;
        logic [31:0] rs2_data;
        logic [2:0]  funct3;

        // control signals decoded in ID, needed from EX onward
        logic        reg_write;
        logic        mem_read;
        logic        mem_write;
        logic        branch;
        logic        jump;
        logic        jalr;
        logic [1:0]  ALUsrc_1;
        logic        ALUsrc_2;
        alu_op_t     ALU_op;
        logic [1:0]  result_src;
        logic       valid;
    }id_ex_reg_t;

    //EX/MEM
    typedef struct packed{
        logic [31:0] pc_plus_4;
        logic [31:0] alu_result;
        logic [31:0] rs2_data;
        logic [4:0]  rd_addr;
        logic        reg_write;
        logic        mem_read;
        logic        mem_write;
        logic [1:0]  result_src;
        logic        valid; 
    }ex_mem_reg_t;


    //MEM/WB
    typedef struct packed { 
        logic [31:0] pc_plus_4;
        logic [31:0] alu_result;
        logic [31:0] mem_read_data;
        logic [4:0] rd_addr;
        logic       reg_write;
        logic [1:0] result_src;
        logic       valid;
    }mem_wb_reg_t;

endpackage