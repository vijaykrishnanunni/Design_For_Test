`timescale 1ns/1ps

module lbist_controller #(
    parameter PATTERN_COUNT_WIDTH = 16
)(
    input  wire                         clk,
    input  wire                         rst_n,

    input  wire                         lbist_start,
    input  wire [PATTERN_COUNT_WIDTH-1:0] pattern_count,

    output reg                          lbist_active,
    output reg                          prpg_enable,
    output reg                          misr_enable,
    output reg                          compare_enable,
    output reg                          lbist_done
);

    localparam IDLE    = 3'd0;
    localparam INIT    = 3'd1;
    localparam RUN     = 3'd2;
    localparam COMPARE = 3'd3;
    localparam DONE    = 3'd4;

    reg [2:0] state;
    reg [2:0] next_state;

    reg [PATTERN_COUNT_WIDTH-1:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        case (state)

            IDLE: begin
                if (lbist_start)
                    next_state = INIT;
                else
                    next_state = IDLE;
            end

            INIT: begin
                next_state = RUN;
            end

            RUN: begin
                if (count == pattern_count)
                    next_state = COMPARE;
                else
                    next_state = RUN;
            end

            COMPARE: begin
                next_state = DONE;
            end

            DONE: begin
                if (!lbist_start)
                    next_state = IDLE;
                else
                    next_state = DONE;
            end

            default: begin
                next_state = IDLE;
            end

        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= {PATTERN_COUNT_WIDTH{1'b0}};
        end
        else begin
            case (state)

                IDLE: begin
                    count <= {PATTERN_COUNT_WIDTH{1'b0}};
                end

                INIT: begin
                    count <= {PATTERN_COUNT_WIDTH{1'b0}};
                end

                RUN: begin
                    if (count < pattern_count)
                        count <= count + 1'b1;
                    else
                        count <= count;
                end

                default: begin
                    count <= count;
                end

            endcase
        end
    end

    always @(*) begin
        lbist_active   = 1'b0;
        prpg_enable    = 1'b0;
        misr_enable    = 1'b0;
        compare_enable = 1'b0;
        lbist_done     = 1'b0;

        case (state)

            IDLE: begin
                lbist_active   = 1'b0;
                prpg_enable    = 1'b0;
                misr_enable    = 1'b0;
                compare_enable = 1'b0;
                lbist_done     = 1'b0;
            end

            INIT: begin
                lbist_active   = 1'b1;
                prpg_enable    = 1'b0;
                misr_enable    = 1'b0;
                compare_enable = 1'b0;
                lbist_done     = 1'b0;
            end

            RUN: begin
                lbist_active   = 1'b1;
                prpg_enable    = 1'b1;
                misr_enable    = 1'b1;
                compare_enable = 1'b0;
                lbist_done     = 1'b0;
            end

            COMPARE: begin
                lbist_active   = 1'b1;
                prpg_enable    = 1'b0;
                misr_enable    = 1'b0;
                compare_enable = 1'b1;
                lbist_done     = 1'b0;
            end

            DONE: begin
                lbist_active   = 1'b0;
                prpg_enable    = 1'b0;
                misr_enable    = 1'b0;
                compare_enable = 1'b0;
                lbist_done     = 1'b1;
            end

            default: begin
                lbist_active   = 1'b0;
                prpg_enable    = 1'b0;
                misr_enable    = 1'b0;
                compare_enable = 1'b0;
                lbist_done     = 1'b0;
            end

        endcase
    end

endmodule
