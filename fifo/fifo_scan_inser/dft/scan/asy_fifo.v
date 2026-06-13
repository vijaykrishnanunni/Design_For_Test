`timescale 1ns/1ps

module asy_fifo #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 4
)(
    input  wire                  wr_clk,
    input  wire                  wr_rst_n,
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] wr_data,

    input  wire                  rd_clk,
    input  wire                  rd_rst_n,
    input  wire                  rd_en,
    output reg  [DATA_WIDTH-1:0] rd_data,

    output wire                  full,
    output wire                  empty
);

    localparam DEPTH = (1 << ADDR_WIDTH);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Binary and Gray pointers
    reg [ADDR_WIDTH:0] wr_bin,  wr_gray;
    reg [ADDR_WIDTH:0] rd_bin,  rd_gray;

    // 2-FF synchronisers
    reg [ADDR_WIDTH:0] wr_gray_sync1, wr_gray_sync2; // wr_gray -> rd domain
    reg [ADDR_WIDTH:0] rd_gray_sync1, rd_gray_sync2; // rd_gray -> wr domain

    // Registered flags (FIX: no combinational loop)
    reg full_r;
    reg empty_r;

    assign full  = full_r;
    assign empty = empty_r;

    // Gray conversion
    function [ADDR_WIDTH:0] bin2gray;
        input [ADDR_WIDTH:0] b;
        begin bin2gray = (b >> 1) ^ b; end
    endfunction

    // Next pointers use registered flags -> no loop
    wire [ADDR_WIDTH:0] wr_bin_next  = wr_bin + (wr_en & ~full_r);
    wire [ADDR_WIDTH:0] wr_gray_next = bin2gray(wr_bin_next);

    wire [ADDR_WIDTH:0] rd_bin_next  = rd_bin + (rd_en & ~empty_r);
    wire [ADDR_WIDTH:0] rd_gray_next = bin2gray(rd_bin_next);

    // ------------------------------------------------------------------
    // WRITE DOMAIN
    // ------------------------------------------------------------------

    // Write pointers
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            wr_bin  <= {(ADDR_WIDTH+1){1'b0}};
            wr_gray <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            wr_bin  <= wr_bin_next;
            wr_gray <= wr_gray_next;
        end
    end

    // Memory write
    always @(posedge wr_clk) begin
        if (wr_en && !full_r)
            mem[wr_bin[ADDR_WIDTH-1:0]] <= wr_data;
    end

    // Sync rd_gray -> write domain
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            rd_gray_sync1 <= {(ADDR_WIDTH+1){1'b0}};
            rd_gray_sync2 <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            rd_gray_sync1 <= rd_gray;
            rd_gray_sync2 <= rd_gray_sync1;
        end
    end

    // Full flag register (FIX: registered, uses only registered signals)
    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n)
            full_r <= 1'b0;
        else
            full_r <= (wr_gray_next ==
                       {~rd_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1],
                         rd_gray_sync2[ADDR_WIDTH-2:0]});
    end

    // ------------------------------------------------------------------
    // READ DOMAIN
    // ------------------------------------------------------------------

    // Read pointers + rd_data
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_bin  <= {(ADDR_WIDTH+1){1'b0}};
            rd_gray <= {(ADDR_WIDTH+1){1'b0}};
            rd_data <= {DATA_WIDTH{1'b0}};
        end else begin
            rd_bin  <= rd_bin_next;
            rd_gray <= rd_gray_next;
            if (rd_en && !empty_r)
                rd_data <= mem[rd_bin[ADDR_WIDTH-1:0]];
        end
    end

    // Sync wr_gray -> read domain
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            wr_gray_sync1 <= {(ADDR_WIDTH+1){1'b0}};
            wr_gray_sync2 <= {(ADDR_WIDTH+1){1'b0}};
        end else begin
            wr_gray_sync1 <= wr_gray;
            wr_gray_sync2 <= wr_gray_sync1;
        end
    end

    // Empty flag register (FIX: registered, uses only registered signals)
    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n)
            empty_r <= 1'b1;
        else
            empty_r <= (rd_gray_next == wr_gray_sync2);
    end

endmodule
