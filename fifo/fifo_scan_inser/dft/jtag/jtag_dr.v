`timescale 1ns/1ps

module jtag_dr #(
    parameter IR_WIDTH     = 4,
    parameter IDCODE_VALUE = 32'h1234_ABCD
)(
    input  wire                  tck,
    input  wire                  trst_n,
    input  wire                  tdi,

    input  wire                  capture_dr,
    input  wire                  shift_dr,
    input  wire                  update_dr,

    input  wire [IR_WIDTH-1:0]   instruction,

    output wire                  scan_en_wr,
    output wire                  scan_en_rd,

    output wire                  scan_in_wr,
    output wire                  scan_in_rd,

    input  wire                  scan_out_wr,
    input  wire                  scan_out_rd,

    output reg                   lbist_start,
    output reg  [15:0]           pattern_count,
    output reg  [15:0]           lbist_seed,

    input  wire                  lbist_active,
    input  wire                  lbist_done,
    input  wire                  bist_pass,
    input  wire                  bist_fail,
    input  wire [15:0]           misr_signature,

    output reg                   dr_tdo
);

    localparam [IR_WIDTH-1:0] BYPASS       = 4'b1111;
    localparam [IR_WIDTH-1:0] IDCODE       = 4'b0001;
    localparam [IR_WIDTH-1:0] SCAN_WR      = 4'b0010;
    localparam [IR_WIDTH-1:0] SCAN_RD      = 4'b0011;
    localparam [IR_WIDTH-1:0] LBIST_CTRL   = 4'b0100;
    localparam [IR_WIDTH-1:0] LBIST_STATUS = 4'b0101;

    reg        bypass_reg;
    reg [31:0] idcode_shift;

    reg [33:0] lbist_ctrl_shift;
    reg [33:0] lbist_ctrl_reg;

    reg [19:0] lbist_status_shift;

    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            bypass_reg         <= 1'b0;
            idcode_shift       <= IDCODE_VALUE;

            lbist_ctrl_shift   <= 34'd0;
            lbist_ctrl_reg     <= 34'd0;

            lbist_status_shift <= 20'd0;

            lbist_start        <= 1'b0;
            pattern_count      <= 16'd0;
            lbist_seed         <= 16'hACE1;
        end
        else begin

            lbist_start <= 1'b0;

            if (capture_dr) begin
                case (instruction)

                    BYPASS: begin
                        bypass_reg <= 1'b0;
                    end

                    IDCODE: begin
                        idcode_shift <= IDCODE_VALUE;
                    end

                    LBIST_CTRL: begin
                        lbist_ctrl_shift <= lbist_ctrl_reg;
                    end

                    LBIST_STATUS: begin
                        lbist_status_shift <= {
                            bist_fail,
                            bist_pass,
                            lbist_done,
                            lbist_active,
                            misr_signature
                        };
                    end

                    default: begin
                        bypass_reg <= 1'b0;
                    end

                endcase
            end

            else if (shift_dr) begin
                case (instruction)

                    BYPASS: begin
                        bypass_reg <= tdi;
                    end

                    IDCODE: begin
                        idcode_shift <= {tdi, idcode_shift[31:1]};
                    end

                    LBIST_CTRL: begin
                        lbist_ctrl_shift <= {tdi, lbist_ctrl_shift[33:1]};
                    end

                    LBIST_STATUS: begin
                        lbist_status_shift <= {tdi, lbist_status_shift[19:1]};
                    end

                    default: begin
                        bypass_reg <= tdi;
                    end

                endcase
            end

            else if (update_dr) begin
                if (instruction == LBIST_CTRL) begin
                    lbist_ctrl_reg <= lbist_ctrl_shift;

                    lbist_start   <= lbist_ctrl_shift[0];
                    pattern_count <= lbist_ctrl_shift[16:1];
                    lbist_seed    <= lbist_ctrl_shift[32:17];
                end
            end
        end
    end

    assign scan_en_wr = shift_dr && (instruction == SCAN_WR);
    assign scan_en_rd = shift_dr && (instruction == SCAN_RD);

    assign scan_in_wr = tdi;
    assign scan_in_rd = tdi;

    always @(*) begin
        case (instruction)

            BYPASS:
                dr_tdo = bypass_reg;

            IDCODE:
                dr_tdo = idcode_shift[0];

            SCAN_WR:
                dr_tdo = scan_out_wr;

            SCAN_RD:
                dr_tdo = scan_out_rd;

            LBIST_CTRL:
                dr_tdo = lbist_ctrl_shift[0];

            LBIST_STATUS:
                dr_tdo = lbist_status_shift[0];

            default:
                dr_tdo = bypass_reg;

        endcase
    end

endmodule
