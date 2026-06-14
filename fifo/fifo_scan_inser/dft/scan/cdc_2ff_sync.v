`timescale 1ns/1ps
// Generic 2-flop synchronizer for level / quasi-static signals.
//
// Use for signals that are stable for several destination-clock
// cycles before/after they change (status flags, config registers
// such as pattern_count / lbist_seed, signatures, etc).
//
// NOT suitable for single-cycle pulses crossing into a slower clock
// domain unless the pulse is guaranteed to be wide enough to be
// sampled - use cdc_pulse_sync for that case.

module cdc_2ff_sync #(
    parameter WIDTH = 1
)(
    input  wire             dst_clk,
    input  wire             dst_rst_n,
    input  wire [WIDTH-1:0] din,
    output reg  [WIDTH-1:0] dout
);

    reg [WIDTH-1:0] stage1;

    always @(posedge dst_clk or negedge dst_rst_n) begin
        if (!dst_rst_n) begin
            stage1 <= {WIDTH{1'b0}};
            dout   <= {WIDTH{1'b0}};
        end
        else begin
            stage1 <= din;
            dout   <= stage1;
        end
    end

endmodule
