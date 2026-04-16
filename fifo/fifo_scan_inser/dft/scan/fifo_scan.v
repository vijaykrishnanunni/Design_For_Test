`timescale 1ns/1ps

module asy_fifo_scan #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 4
)(
    input  wire wr_clk,
    input  wire wr_rst_n,
    input  wire wr_en,
    input  wire [DATA_WIDTH-1:0] wr_data,

    input  wire rd_clk,
    input  wire rd_rst_n,
    input  wire rd_en,
    output wire [DATA_WIDTH-1:0] rd_data,

    output wire full,
    output wire empty,
// --------------------------------------------------------------------------------------------------------------------
    // Write-domain scan chain
    input  wire scan_en_wr,
    input  wire scan_in_wr,
    output wire scan_out_wr,

    // Read-domain scan chain
    input  wire scan_en_rd,
    input  wire scan_in_rd,
    output wire scan_out_rd
  // --------------------------------------------------------------------------------------------------------------------
);

localparam DEPTH = (1 << ADDR_WIDTH);

// Memory array remains non-scan
reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

// DUT state registers now implemented through scan FF replacement
wire [ADDR_WIDTH:0] wr_bin;
wire [ADDR_WIDTH:0] wr_gray;

wire [ADDR_WIDTH:0] rd_bin;
wire [ADDR_WIDTH:0] rd_gray;

wire [ADDR_WIDTH:0] wr_gray_sync1;
wire [ADDR_WIDTH:0] wr_gray_sync2;
wire [ADDR_WIDTH:0] rd_gray_sync1;
wire [ADDR_WIDTH:0] rd_gray_sync2;

wire [DATA_WIDTH-1:0] rd_data_int;
assign rd_data = rd_data_int;

// Gray conversion
function [ADDR_WIDTH:0] bin2gray;
    input [ADDR_WIDTH:0] bin;
    begin
        bin2gray = (bin >> 1) ^ bin;
    end
endfunction


// Functional next-state logic
wire [ADDR_WIDTH:0] wr_bin_next;
wire [ADDR_WIDTH:0] wr_gray_next;
wire [ADDR_WIDTH:0] rd_bin_next;
wire [ADDR_WIDTH:0] rd_gray_next;

assign wr_bin_next  = wr_bin + (wr_en & ~full);
assign wr_gray_next = bin2gray(wr_bin_next);

assign rd_bin_next  = rd_bin + (rd_en & ~empty);
assign rd_gray_next = bin2gray(rd_bin_next);


// Write memory (memory itself not scan-replaced)

always @(posedge wr_clk) begin
    if (wr_en && !full)
        mem[wr_bin[ADDR_WIDTH-1:0]] <= wr_data;
end


// Read data next-state

wire [DATA_WIDTH-1:0] rd_data_next;
assign rd_data_next = (rd_en && !empty) ? mem[rd_bin[ADDR_WIDTH-1:0]] : rd_data_int;


// Status logic

assign empty = (rd_gray == wr_gray_sync2);

assign full =
    (wr_gray_next ==
     {~rd_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1],
       rd_gray_sync2[ADDR_WIDTH-2:0]});

// --------------------------------------------------------------------------------------------------------------------
  
// WRITE DOMAIN SCAN CHAIN
// Chain order:
// wr_bin -> wr_gray -> rd_gray_sync1 -> rd_gray_sync2
// -----------------------------
localparam WR_CHAIN_LEN = 4 * (ADDR_WIDTH + 1);
wire [WR_CHAIN_LEN:0] wr_scan_chain;

assign wr_scan_chain[0] = scan_in_wr;
assign scan_out_wr      = wr_scan_chain[WR_CHAIN_LEN];

genvar i;

// wr_bin
generate
    for (i = 0; i <= ADDR_WIDTH; i = i + 1) begin : GEN_WR_BIN_SCAN
        scan_ff u_wr_bin_ff (
            .clk(wr_clk),
            .rst_n(wr_rst_n),
            .scan_en(scan_en_wr),
            .si(wr_scan_chain[i]),
            .d(wr_bin_next[i]),
            .q(wr_bin[i]),
            .so(wr_scan_chain[i+1])
        );
    end
endgenerate

// wr_gray
generate
    for (i = 0; i <= ADDR_WIDTH; i = i + 1) begin : GEN_WR_GRAY_SCAN
        scan_ff u_wr_gray_ff (
            .clk(wr_clk),
            .rst_n(wr_rst_n),
            .scan_en(scan_en_wr),
            .si(wr_scan_chain[(ADDR_WIDTH+1) + i]),
            .d(wr_gray_next[i]),
            .q(wr_gray[i]),
            .so(wr_scan_chain[(ADDR_WIDTH+1) + i + 1])
        );
    end
endgenerate

// rd_gray_sync1
generate
    for (i = 0; i <= ADDR_WIDTH; i = i + 1) begin : GEN_RD_GRAY_SYNC1_SCAN
        scan_ff u_rd_gray_sync1_ff (
            .clk(wr_clk),
            .rst_n(wr_rst_n),
            .scan_en(scan_en_wr),
            .si(wr_scan_chain[2*(ADDR_WIDTH+1) + i]),
            .d(rd_gray[i]),
            .q(rd_gray_sync1[i]),
            .so(wr_scan_chain[2*(ADDR_WIDTH+1) + i + 1])
        );
    end
endgenerate

// rd_gray_sync2
generate
    for (i = 0; i <= ADDR_WIDTH; i = i + 1) begin : GEN_RD_GRAY_SYNC2_SCAN
        scan_ff u_rd_gray_sync2_ff (
            .clk(wr_clk),
            .rst_n(wr_rst_n),
            .scan_en(scan_en_wr),
            .si(wr_scan_chain[3*(ADDR_WIDTH+1) + i]),
            .d(rd_gray_sync1[i]),
            .q(rd_gray_sync2[i]),
            .so(wr_scan_chain[3*(ADDR_WIDTH+1) + i + 1])
        );
    end
endgenerate

// -----------------------------
// READ DOMAIN SCAN CHAIN
// Chain order:
// rd_bin -> rd_gray -> wr_gray_sync1 -> wr_gray_sync2 -> rd_data
// -----------------------------
localparam RD_CHAIN_LEN = 4 * (ADDR_WIDTH + 1) + DATA_WIDTH;
wire [RD_CHAIN_LEN:0] rd_scan_chain;

assign rd_scan_chain[0] = scan_in_rd;
assign scan_out_rd      = rd_scan_chain[RD_CHAIN_LEN];

// rd_bin
generate
    for (i = 0; i <= ADDR_WIDTH; i = i + 1) begin : GEN_RD_BIN_SCAN
        scan_ff u_rd_bin_ff (
            .clk(rd_clk),
            .rst_n(rd_rst_n),
            .scan_en(scan_en_rd),
            .si(rd_scan_chain[i]),
            .d(rd_bin_next[i]),
            .q(rd_bin[i]),
            .so(rd_scan_chain[i+1])
        );
    end
endgenerate

// rd_gray
generate
    for (i = 0; i <= ADDR_WIDTH; i = i + 1) begin : GEN_RD_GRAY_SCAN
        scan_ff u_rd_gray_ff (
            .clk(rd_clk),
            .rst_n(rd_rst_n),
            .scan_en(scan_en_rd),
            .si(rd_scan_chain[(ADDR_WIDTH+1) + i]),
            .d(rd_gray_next[i]),
            .q(rd_gray[i]),
            .so(rd_scan_chain[(ADDR_WIDTH+1) + i + 1])
        );
    end
endgenerate

// wr_gray_sync1
generate
    for (i = 0; i <= ADDR_WIDTH; i = i + 1) begin : GEN_WR_GRAY_SYNC1_SCAN
        scan_ff u_wr_gray_sync1_ff (
            .clk(rd_clk),
            .rst_n(rd_rst_n),
            .scan_en(scan_en_rd),
            .si(rd_scan_chain[2*(ADDR_WIDTH+1) + i]),
            .d(wr_gray[i]),
            .q(wr_gray_sync1[i]),
            .so(rd_scan_chain[2*(ADDR_WIDTH+1) + i + 1])
        );
    end
endgenerate

// wr_gray_sync2
generate
    for (i = 0; i <= ADDR_WIDTH; i = i + 1) begin : GEN_WR_GRAY_SYNC2_SCAN
        scan_ff u_wr_gray_sync2_ff (
            .clk(rd_clk),
            .rst_n(rd_rst_n),
            .scan_en(scan_en_rd),
            .si(rd_scan_chain[3*(ADDR_WIDTH+1) + i]),
            .d(wr_gray_sync1[i]),
            .q(wr_gray_sync2[i]),
            .so(rd_scan_chain[3*(ADDR_WIDTH+1) + i + 1])
        );
    end
endgenerate

// rd_data
generate
    for (i = 0; i < DATA_WIDTH; i = i + 1) begin : GEN_RD_DATA_SCAN
        scan_ff u_rd_data_ff (
            .clk(rd_clk),
            .rst_n(rd_rst_n),
            .scan_en(scan_en_rd),
            .si(rd_scan_chain[4*(ADDR_WIDTH+1) + i]),
            .d(rd_data_next[i]),
            .q(rd_data_int[i]),
            .so(rd_scan_chain[4*(ADDR_WIDTH+1) + i + 1])
        );
    end
endgenerate

endmodule
