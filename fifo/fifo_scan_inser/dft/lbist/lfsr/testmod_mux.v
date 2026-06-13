`timescale 1ns/1ps
// Selects between functional user inputs and LBIST-generated
// stimulus on the FIFO write port.
//
//   lbist_active = 0  -> user_wr_en / user_wr_data pass through
//   lbist_active = 1  -> prpg_wr_en / prpg_wr_data override (from lbist_top)
//

module test_mode_mux #(
    parameter DATA_WIDTH = 16
)(
    input  wire                    lbist_active,

    // Functional inputs
    input  wire                    user_wr_en,
    input  wire [DATA_WIDTH-1:0]   user_wr_data,

    // LBIST inputs (from lbist_top)
    input  wire                    prpg_wr_en,
    input  wire [DATA_WIDTH-1:0]   prpg_wr_data,

    // To asy_fifo_scan write port
    output wire                    fifo_wr_en,
    output wire [DATA_WIDTH-1:0]   fifo_wr_data
);
    assign fifo_wr_en   = lbist_active ? prpg_wr_en   : user_wr_en;
    assign fifo_wr_data = lbist_active ? prpg_wr_data : user_wr_data;
endmodule
