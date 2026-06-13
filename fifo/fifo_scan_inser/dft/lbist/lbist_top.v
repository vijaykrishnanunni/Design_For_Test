`timescale 1ns/1ps

//   PRPG word[15:0] ----> fifo_wr_data  (stimulus to DUT write port)
//   prpg_enable     ----> fifo_wr_en
//   scan_out_wr     ----> misr.data_in  (serial response compaction)
//   misr.signature  ----> lbist_result_block ----> bist_pass / bist_fail
//
// All ports on wr_clk domain.
// lbist_start input must already be synchronised to wr_clk by the caller.

module lbist_top #(
    parameter PATTERN_COUNT_WIDTH = 16,
    parameter DATA_WIDTH          = 16,
    parameter MISR_WIDTH          = 16,
    parameter [15:0] MISR_POLY    = 16'hB400,
    parameter [15:0] GOLDEN_SIG   = 16'hA5C3
)(
    // Clock / reset  (write domain)
    input  wire                              clk,
    input  wire                              rst_n,

    // LBIST control  (synchronised to wr_clk before entry)
    input  wire                              lbist_start,
    input  wire [PATTERN_COUNT_WIDTH-1:0]    pattern_count,
    input  wire [MISR_WIDTH-1:0]             lbist_seed,

    // LBIST status  (wr_clk domain; dft_top syncs back to tck for JTAG)
    output wire                              lbist_active,
    output wire                              lbist_done,
    output wire                              bist_pass,
    output wire                              bist_fail,
    output wire [MISR_WIDTH-1:0]             misr_signature,

    // Stimulus to FIFO write port  (connect to test_mode_mux)
    output wire [DATA_WIDTH-1:0]             fifo_wr_data,
    output wire                              fifo_wr_en,

    // Response from FIFO scan chain  (connect to asy_fifo_scan.scan_out_wr)
    input  wire                              misr_data_in
);

    wire prpg_enable;
    wire misr_enable;
    wire compare_enable;

    // INIT state: lbist_active=1 AND prpg_enable=0  -> load seed into LFSR
    wire load_seed = lbist_active & ~prpg_enable;

    // 1. FSM
    lbist_controller #(
        .PATTERN_COUNT_WIDTH (PATTERN_COUNT_WIDTH)
    ) u_lbist_controller (
        .clk            (clk),
        .rst_n          (rst_n),
        .lbist_start    (lbist_start),
        .pattern_count  (pattern_count),
        .lbist_active   (lbist_active),
        .prpg_enable    (prpg_enable),
        .misr_enable    (misr_enable),
        .compare_enable (compare_enable),
        .lbist_done     (lbist_done)
    );

    // 2. PRPG
    wire [MISR_WIDTH-1:0] prpg_word;

    lfsr16_prpg u_lfsr16_prpg (
        .clk        (clk),
        .rst_n      (rst_n),
        .enable     (prpg_enable),
        .load_seed  (load_seed),
        .seed       (lbist_seed),
        .prpg_bit   (),          // unused; MISR fed from scan_out_wr
        .prpg_word  (prpg_word)
    );

    assign fifo_wr_data = prpg_word;
    assign fifo_wr_en   = prpg_enable;

    // 3. MISR
    misr #(
        .WIDTH (MISR_WIDTH),
        .POLY  (MISR_POLY)
    ) u_misr (
        .clk       (clk),
        .rst_n     (rst_n),
        .enable    (misr_enable),
        .data_in   (misr_data_in),
        .signature (misr_signature)
    );

    // 4. Result block
    wire [MISR_WIDTH-1:0] golden_sig_nc;
    wire                  match_nc, mismatch_nc;

    lbist_result_block #(
        .WIDTH      (MISR_WIDTH),
        .GOLDEN_SIG (GOLDEN_SIG)
    ) u_lbist_result_block (
        .misr_sig   (misr_signature),
        .result_en  (compare_enable),
        .golden_sig (golden_sig_nc),
        .match      (match_nc),
        .mismatch   (mismatch_nc),
        .bist_pass  (bist_pass),
        .bist_fail  (bist_fail)
    );

endmodule
