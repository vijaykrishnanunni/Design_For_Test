module asy_fifo #(
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
    output reg  [DATA_WIDTH-1:0] rd_data,

    output wire full,
    output wire empty
);

localparam DEPTH = (1 << ADDR_WIDTH);

reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

// pointers
reg [ADDR_WIDTH:0] wr_bin, wr_gray;
reg [ADDR_WIDTH:0] rd_bin, rd_gray;

// synchronizers
reg [ADDR_WIDTH:0] wr_gray_sync1, wr_gray_sync2;
reg [ADDR_WIDTH:0] rd_gray_sync1, rd_gray_sync2;

//Gray conversion
function [ADDR_WIDTH:0] bin2gray;
    input [ADDR_WIDTH:0] bin;
    begin
        bin2gray = (bin >> 1) ^ bin;
    end
endfunction

// WRITE SIDE 
wire [ADDR_WIDTH:0] wr_bin_next  = wr_bin + (wr_en & ~full);
wire [ADDR_WIDTH:0] wr_gray_next = bin2gray(wr_bin_next);

always @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n) begin
        wr_bin  <= 0;
        wr_gray <= 0;
    end else begin
        wr_bin  <= wr_bin_next;
        wr_gray <= wr_gray_next;
    end
end

always @(posedge wr_clk)
    if (wr_en && !full)
        mem[wr_bin[ADDR_WIDTH-1:0]] <= wr_data;

// sync read pointer → write domain
always @(posedge wr_clk or negedge wr_rst_n) begin
    if (!wr_rst_n) begin
        rd_gray_sync1 <= 0;
        rd_gray_sync2 <= 0;
    end else begin
        rd_gray_sync1 <= rd_gray;
        rd_gray_sync2 <= rd_gray_sync1;
    end
end

// READ SIDE 
wire [ADDR_WIDTH:0] rd_bin_next  = rd_bin + (rd_en & ~empty);
wire [ADDR_WIDTH:0] rd_gray_next = bin2gray(rd_bin_next);

always @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n) begin
        rd_bin  <= 0;
        rd_gray <= 0;
        rd_data <= 0;
    end else begin
        rd_bin  <= rd_bin_next;
        rd_gray <= rd_gray_next;

        if (rd_en && !empty)
            rd_data <= mem[rd_bin[ADDR_WIDTH-1:0]];
    end
end

// sync write pointer → read domain
always @(posedge rd_clk or negedge rd_rst_n) begin
    if (!rd_rst_n) begin
        wr_gray_sync1 <= 0;
        wr_gray_sync2 <= 0;
    end else begin
        wr_gray_sync1 <= wr_gray;
        wr_gray_sync2 <= wr_gray_sync1;
    end
end

// STATUS 
assign empty = (rd_gray == wr_gray_sync2);

assign full =
    (wr_gray_next ==
     {~rd_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1],
       rd_gray_sync2[ADDR_WIDTH-2:0]});

endmodule
