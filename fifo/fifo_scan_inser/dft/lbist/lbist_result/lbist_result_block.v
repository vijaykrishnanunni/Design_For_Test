`timescale 1ns/1ps

module lbist_result_block #(
    parameter WIDTH = 16,
    parameter [WIDTH-1:0] GOLDEN_SIG = 16'hA5C3
)(
    input  wire             clk,
    input  wire             rst_n,
    input  wire [WIDTH-1:0] misr_sig,
    input  wire             result_en,

    output wire [WIDTH-1:0] golden_sig,
    output wire             match,
    output wire             mismatch,
    output wire             bist_pass,
    output wire             bist_fail
);

    wire bist_pass_comb;
    wire bist_fail_comb;

    golden_signature_mem #(
        .WIDTH(WIDTH),
        .GOLDEN_SIG(GOLDEN_SIG)
    ) u_golden_signature_mem (
        .read_en(result_en),
        .golden_sig(golden_sig)
    );

    signature_comparator #(
        .WIDTH(WIDTH)
    ) u_signature_comparator (
        .misr_sig(misr_sig),
        .golden_sig(golden_sig),
        .compare_en(result_en),
        .match(match),
        .mismatch(mismatch),
        .bist_pass(bist_pass_comb),
        .bist_fail(bist_fail_comb)
    );

    lbist_status_reg u_lbist_status_reg (
        .clk(clk),
        .rst_n(rst_n),
        .latch_en(result_en),
        .bist_pass_in(bist_pass_comb),
        .bist_fail_in(bist_fail_comb),
        .bist_pass(bist_pass),
        .bist_fail(bist_fail)
    );

endmodule
