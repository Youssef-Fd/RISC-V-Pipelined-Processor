module DE1_top (
    input  logic       CLOCK_50,
    input  logic [3:0] KEY,
    input  logic [9:0] SW,

    output logic [9:0] LEDR,
    output logic [7:0] LEDG,
    output logic [6:0] HEX0,
    output logic [6:0] HEX1,
    output logic [6:0] HEX2,
    output logic [6:0] HEX3
);

    // reset
    logic sync_reset;

    reset_sync u_reset_sync (
        .clk           (CLOCK_50),
        .async_reset_n (KEY[0]),
        .sync_reset    (sync_reset)
    );

 
    logic [31:0] debug_wb, debug_alu, debug_instr;//keeps the whole CPU from being optimized away 
    logic        debug_valid;

    datapath_pipelined u_datapath_pipeline (
        .clk         (CLOCK_50),
        .rst_n       (sync_reset),
        .debug_out   (debug_wb),
        .debug_valid (debug_valid),
        .debug_alu   (debug_alu),
        .debug_instr (debug_instr),
        .debug_pc()
    );


    logic seen_done;
    always_ff @(posedge CLOCK_50 or posedge sync_reset) begin
        if (sync_reset)
            seen_done <= 1'b0;
        else if (debug_valid)
            seen_done <= 1'b1;
    end


    seg7_decoder u_hex0 (
        .hex_in (debug_instr[3:0]),
        .blank  (1'b0),
        .seg_out(HEX0)
    );

    seg7_decoder u_hex1 (
        .hex_in (debug_instr[7:4]),
        .blank  (1'b0),
        .seg_out(HEX1)
    );

    seg7_decoder u_hex2 (
        .hex_in (debug_instr[11:8]),
        .blank  (1'b0),
        .seg_out(HEX2)
    );

    seg7_decoder u_hex3 (
        .hex_in (debug_instr[15:12]),
        .blank  (1'b0),
        .seg_out(HEX3)
    );
    

    // assign LEDR[0]   = debug_wb[0];
    // assign LEDR[9:1] = debug_wb[9:1];

    assign LEDR[9:0] = {1'b1, debug_instr[8:0]};

    assign LEDG[0] = debug_valid;
    assign LEDG[1] = seen_done;
    assign LEDG[2] = sync_reset;
    assign LEDG[7:3] = 5'b0;

    // assign HEX0 = 7'h0;
    // assign HEX1 = 7'h7F;
    // assign HEX2 = 7'h7F;
    // assign HEX3 = 7'h7F;

endmodule