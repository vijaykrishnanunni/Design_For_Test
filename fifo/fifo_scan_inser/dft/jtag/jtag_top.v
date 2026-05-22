
`timescale 1ns/1ps

module jtag_top #(
    parameter IR_WIDTH     = 4,
    parameter IDCODE_VALUE = 32'h1234_ABCD
)(
    input  wire        tck,
    input  wire        trst_n,
    input  wire        tms,
    input  wire        tdi,
    output wire        tdo,

    output wire        scan_en_wr,
    output wire        scan_in_wr,
    input  wire        scan_out_wr,

    output wire        scan_en_rd,
    output wire        scan_in_rd,
    input  wire        scan_out_rd,

    output wire        lbist_start,
    output wire [15:0] pattern_count,
    output wire [15:0] lbist_seed,

    input  wire        lbist_active,
    input  wire        lbist_done,
    input  wire        bist_pass,
    input  wire        bist_fail,
    input  wire [15:0] misr_signature
);

    wire test_logic_reset;
    wire run_test_idle;

    wire capture_dr;
    wire shift_dr;
    wire update_dr;

    wire capture_ir;
    wire shift_ir;
    wire update_ir;

    wire [IR_WIDTH-1:0] instruction;

    wire ir_tdo;
    wire dr_tdo;

    tap_controller u_tap_controller (
        .tck              (tck),
        .trst_n           (trst_n),
        .tms              (tms),

        .test_logic_reset (test_logic_reset),
        .run_test_idle    (run_test_idle),

        .capture_dr       (capture_dr),
        .shift_dr         (shift_dr),
        .update_dr        (update_dr),

        .capture_ir       (capture_ir),
        .shift_ir         (shift_ir),
        .update_ir        (update_ir)
    );

    jtag_ir #(
        .IR_WIDTH(IR_WIDTH)
    ) u_jtag_ir (
        .tck         (tck),
        .trst_n      (trst_n),
        .tdi         (tdi),

        .capture_ir  (capture_ir),
        .shift_ir    (shift_ir),
        .update_ir   (update_ir),

        .ir_tdo      (ir_tdo),
        .instruction (instruction)
    );

    jtag_dr #(
        .IR_WIDTH     (IR_WIDTH),
        .IDCODE_VALUE (IDCODE_VALUE)
    ) u_jtag_dr (
        .tck               (tck),
        .trst_n            (trst_n),
        .tdi               (tdi),

        .capture_dr        (capture_dr),
        .shift_dr          (shift_dr),
        .update_dr         (update_dr),

        .instruction       (instruction),

        .scan_en_wr        (scan_en_wr),
        .scan_en_rd        (scan_en_rd),

        .scan_in_wr        (scan_in_wr),
        .scan_in_rd        (scan_in_rd),

        .scan_out_wr       (scan_out_wr),
        .scan_out_rd       (scan_out_rd),

        .lbist_start       (lbist_start),
        .pattern_count     (pattern_count),
        .lbist_seed        (lbist_seed),

        .lbist_active      (lbist_active),
        .lbist_done        (lbist_done),
        .bist_pass         (bist_pass),
        .bist_fail         (bist_fail),
        .misr_signature    (misr_signature),

        .dr_tdo            (dr_tdo)
    );

    assign tdo = shift_ir ? ir_tdo :
                 shift_dr ? dr_tdo :
                 1'b0;

endmodule
