`timescale 1ns/1ps
//=====================================================================
// dft_top
//
// Top-level integration of:
//   - jtag_top        (TCK domain: TAP, IR/DR, LBIST control & status,
//                       scan chain shift control)
//   - cdc_pulse_sync  (TCK -> wr_clk : lbist_start)
//   - cdc_2ff_sync    (TCK -> wr_clk : pattern_count, lbist_seed)
//   - lbist_top       (wr_clk domain: LBIST FSM, PRPG, MISR, result)
//   - cdc_2ff_sync    (wr_clk -> TCK : lbist_active/done/pass/fail/sig)
//   - test_mode_mux   (wr_clk domain: selects functional vs LBIST
//                       stimulus onto the FIFO write port)
//   - asy_fifo_scan   (the DUT: dual-clock FIFO with scan-insertion)
//
// This module provides the two genuine top-level functional write
// ports (user_wr_en / user_wr_data) that were previously dangling /
// undriven, and connects every other DFT sub-block that already
// existed in the repository but was never instantiated together.
//
//          External Functional Logic
//                  |
//                  +--> user_wr_en, user_wr_data
//                              |
//                              v
//                       test_mode_mux  <---- prpg_wr_en/data (lbist_top)
//                              |
//                              v
//                       asy_fifo_scan
//
// All scan_en_*/scan_in_*/scan_out_* signals are sourced from / sunk
// to jtag_top exactly as defined by the existing jtag_dr.v interface
// (SCAN_WR / SCAN_RD instructions). scan_out_wr additionally feeds
// lbist_top.misr_data_in for response compaction during LBIST RUN.
//=====================================================================

module dft_top #(
    parameter DATA_WIDTH         = 16,
    parameter ADDR_WIDTH         = 4,
    parameter PATTERN_COUNT_WIDTH = 16,
    parameter MISR_WIDTH         = 16,
    parameter [15:0] MISR_POLY   = 16'hB400,
    parameter [15:0] GOLDEN_SIG  = 16'hA5C3,
    parameter IR_WIDTH           = 4,
    parameter IDCODE_VALUE       = 32'h1234_ABCD
)(
    //-----------------------------------------------------------
    // Functional write domain (wr_clk)
    //-----------------------------------------------------------
    input  wire                    wr_clk,
    input  wire                    wr_rst_n,

    // Genuine top-level functional write port (previously missing)
    input  wire                    user_wr_en,
    input  wire [DATA_WIDTH-1:0]   user_wr_data,

    output wire                    full,

    //-----------------------------------------------------------
    // Functional read domain (rd_clk)
    //-----------------------------------------------------------
    input  wire                    rd_clk,
    input  wire                    rd_rst_n,

    input  wire                    rd_en,
    output wire [DATA_WIDTH-1:0]   rd_data,

    output wire                    empty,

    //-----------------------------------------------------------
    // JTAG (TCK domain)
    //-----------------------------------------------------------
    input  wire                    tck,
    input  wire                    trst_n,
    input  wire                    tms,
    input  wire                    tdi,
    output wire                    tdo
);

    //=================================================================
    // 1. JTAG TAP / IR / DR
    //=================================================================

    // Scan-chain control (driven by jtag_dr, consumed by asy_fifo_scan)
    wire scan_en_wr, scan_in_wr, scan_out_wr;
    wire scan_en_rd, scan_in_rd, scan_out_rd;

    // LBIST control, TCK domain (from jtag_dr, must be synced to wr_clk)
    wire                           lbist_start_tck;
    wire [PATTERN_COUNT_WIDTH-1:0] pattern_count_tck;
    wire [MISR_WIDTH-1:0]          lbist_seed_tck;

    // LBIST status, TCK domain (synced from wr_clk for jtag_dr)
    wire                  lbist_active_tck;
    wire                  lbist_done_tck;
    wire                  bist_pass_tck;
    wire                  bist_fail_tck;
    wire [MISR_WIDTH-1:0] misr_signature_tck;

    jtag_top #(
        .IR_WIDTH     (IR_WIDTH),
        .IDCODE_VALUE (IDCODE_VALUE)
    ) u_jtag_top (
        .tck            (tck),
        .trst_n         (trst_n),
        .tms            (tms),
        .tdi            (tdi),
        .tdo            (tdo),

        .scan_en_wr     (scan_en_wr),
        .scan_in_wr     (scan_in_wr),
        .scan_out_wr    (scan_out_wr),

        .scan_en_rd     (scan_en_rd),
        .scan_in_rd     (scan_in_rd),
        .scan_out_rd    (scan_out_rd),

        .lbist_start    (lbist_start_tck),
        .pattern_count  (pattern_count_tck),
        .lbist_seed     (lbist_seed_tck),

        .lbist_active   (lbist_active_tck),
        .lbist_done     (lbist_done_tck),
        .bist_pass      (bist_pass_tck),
        .bist_fail      (bist_fail_tck),
        .misr_signature (misr_signature_tck)
    );

    //=================================================================
    // 2. CDC: TCK -> wr_clk  (LBIST control)
    //=================================================================

    wire                           lbist_start_wr;
    wire [PATTERN_COUNT_WIDTH-1:0] pattern_count_wr;
    wire [MISR_WIDTH-1:0]          lbist_seed_wr;

    // lbist_start is a single TCK-cycle pulse (update_dr strobe) -> use
    // a toggle-based pulse synchronizer so it survives the crossing
    // into wr_clk regardless of the TCK/wr_clk frequency relationship.
    cdc_pulse_sync u_cdc_lbist_start (
        .src_clk   (tck),
        .src_rst_n (trst_n),
        .src_pulse (lbist_start_tck),

        .dst_clk   (wr_clk),
        .dst_rst_n (wr_rst_n),
        .dst_pulse (lbist_start_wr)
    );

    // pattern_count / lbist_seed are quasi-static config values that
    // are written via JTAG and held stable before lbist_start fires ->
    // plain 2-flop synchronizers are sufficient.
    cdc_2ff_sync #(
        .WIDTH (PATTERN_COUNT_WIDTH)
    ) u_cdc_pattern_count (
        .dst_clk   (wr_clk),
        .dst_rst_n (wr_rst_n),
        .din       (pattern_count_tck),
        .dout      (pattern_count_wr)
    );

    cdc_2ff_sync #(
        .WIDTH (MISR_WIDTH)
    ) u_cdc_lbist_seed (
        .dst_clk   (wr_clk),
        .dst_rst_n (wr_rst_n),
        .din       (lbist_seed_tck),
        .dout      (lbist_seed_wr)
    );

    //=================================================================
    // 3. LBIST (wr_clk domain)
    //=================================================================

    wire lbist_active_wr;
    wire lbist_done_wr;
    wire bist_pass_wr;
    wire bist_fail_wr;
    wire [MISR_WIDTH-1:0] misr_signature_wr;

    wire [DATA_WIDTH-1:0] prpg_wr_data;
    wire                  prpg_wr_en;

    lbist_top #(
        .PATTERN_COUNT_WIDTH (PATTERN_COUNT_WIDTH),
        .DATA_WIDTH          (DATA_WIDTH),
        .MISR_WIDTH          (MISR_WIDTH),
        .MISR_POLY           (MISR_POLY),
        .GOLDEN_SIG          (GOLDEN_SIG)
    ) u_lbist_top (
        .clk            (wr_clk),
        .rst_n          (wr_rst_n),

        .lbist_start    (lbist_start_wr),
        .pattern_count  (pattern_count_wr),
        .lbist_seed     (lbist_seed_wr),

        .lbist_active   (lbist_active_wr),
        .lbist_done     (lbist_done_wr),
        .bist_pass      (bist_pass_wr),
        .bist_fail      (bist_fail_wr),
        .misr_signature (misr_signature_wr),

        .fifo_wr_data   (prpg_wr_data),
        .fifo_wr_en     (prpg_wr_en),

        // Serial scan response from the write-domain scan chain feeds
        // the MISR for signature compaction during LBIST RUN.
        .misr_data_in   (scan_out_wr)
    );

    //=================================================================
    // 4. CDC: wr_clk -> TCK  (LBIST status)
    //=================================================================

    cdc_2ff_sync #(
        .WIDTH (4 + MISR_WIDTH)
    ) u_cdc_lbist_status (
        .dst_clk   (tck),
        .dst_rst_n (trst_n),
        .din       ({bist_fail_wr, bist_pass_wr, lbist_done_wr, lbist_active_wr, misr_signature_wr}),
        .dout      ({bist_fail_tck, bist_pass_tck, lbist_done_tck, lbist_active_tck, misr_signature_tck})
    );

    //=================================================================
    // 5. Functional / LBIST mux onto FIFO write port (wr_clk domain)
    //=================================================================

    wire                  fifo_wr_en;
    wire [DATA_WIDTH-1:0] fifo_wr_data;

    test_mode_mux #(
        .DATA_WIDTH (DATA_WIDTH)
    ) u_test_mode_mux (
        .lbist_active  (lbist_active_wr),

        .user_wr_en    (user_wr_en),
        .user_wr_data  (user_wr_data),

        .prpg_wr_en    (prpg_wr_en),
        .prpg_wr_data  (prpg_wr_data),

        .fifo_wr_en    (fifo_wr_en),
        .fifo_wr_data  (fifo_wr_data)
    );

    //=================================================================
    // 6. Scan-inserted asynchronous FIFO (the DUT)
    //=================================================================

    asy_fifo_scan #(
        .DATA_WIDTH (DATA_WIDTH),
        .ADDR_WIDTH (ADDR_WIDTH)
    ) u_asy_fifo_scan (
        .wr_clk      (wr_clk),
        .wr_rst_n    (wr_rst_n),
        .wr_en       (fifo_wr_en),
        .wr_data     (fifo_wr_data),

        .rd_clk      (rd_clk),
        .rd_rst_n    (rd_rst_n),
        .rd_en       (rd_en),
        .rd_data     (rd_data),

        .full        (full),
        .empty       (empty),

        .scan_en_wr  (scan_en_wr),
        .scan_in_wr  (scan_in_wr),
        .scan_out_wr (scan_out_wr),

        .scan_en_rd  (scan_en_rd),
        .scan_in_rd  (scan_in_rd),
        .scan_out_rd (scan_out_rd)
    );

endmodule
