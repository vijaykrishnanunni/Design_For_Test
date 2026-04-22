`timescale 1ns/1ps

module lbist_status_reg (
    input  wire clk,
    input  wire rst_n,
    input  wire latch_en,
    input  wire bist_pass_in,
    input  wire bist_fail_in,
    output reg  bist_pass,
    output reg  bist_fail
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bist_pass <= 1'b0;
            bist_fail <= 1'b0;
        end
        else if (latch_en) begin
            bist_pass <= bist_pass_in;
            bist_fail <= bist_fail_in;
        end
    end

endmodule
