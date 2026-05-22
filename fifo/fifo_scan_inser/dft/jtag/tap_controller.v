
`timescale 1ns/1ps

module tap_controller (
    input  wire tck,
    input  wire trst_n,
    input  wire tms,

    output reg  test_logic_reset,
    output reg  run_test_idle,

    output reg  capture_dr,
    output reg  shift_dr,
    output reg  update_dr,

    output reg  capture_ir,
    output reg  shift_ir,
    output reg  update_ir
);

    localparam TEST_LOGIC_RESET = 4'd0;
    localparam RUN_TEST_IDLE    = 4'd1;

    localparam SELECT_DR_SCAN   = 4'd2;
    localparam CAPTURE_DR       = 4'd3;
    localparam SHIFT_DR         = 4'd4;
    localparam EXIT1_DR         = 4'd5;
    localparam PAUSE_DR         = 4'd6;
    localparam EXIT2_DR         = 4'd7;
    localparam UPDATE_DR        = 4'd8;

    localparam SELECT_IR_SCAN   = 4'd9;
    localparam CAPTURE_IR       = 4'd10;
    localparam SHIFT_IR         = 4'd11;
    localparam EXIT1_IR         = 4'd12;
    localparam PAUSE_IR         = 4'd13;
    localparam EXIT2_IR         = 4'd14;
    localparam UPDATE_IR        = 4'd15;

    reg [3:0] state;
    reg [3:0] next_state;

    always @(posedge tck or negedge trst_n) begin
        if (!trst_n)
            state <= TEST_LOGIC_RESET;
        else
            state <= next_state;
    end

    always @(*) begin
        case (state)

            TEST_LOGIC_RESET:
                next_state = tms ? TEST_LOGIC_RESET : RUN_TEST_IDLE;

            RUN_TEST_IDLE:
                next_state = tms ? SELECT_DR_SCAN : RUN_TEST_IDLE;

            SELECT_DR_SCAN:
                next_state = tms ? SELECT_IR_SCAN : CAPTURE_DR;

            CAPTURE_DR:
                next_state = tms ? EXIT1_DR : SHIFT_DR;

            SHIFT_DR:
                next_state = tms ? EXIT1_DR : SHIFT_DR;

            EXIT1_DR:
                next_state = tms ? UPDATE_DR : PAUSE_DR;

            PAUSE_DR:
                next_state = tms ? EXIT2_DR : PAUSE_DR;

            EXIT2_DR:
                next_state = tms ? UPDATE_DR : SHIFT_DR;

            UPDATE_DR:
                next_state = tms ? SELECT_DR_SCAN : RUN_TEST_IDLE;

            SELECT_IR_SCAN:
                next_state = tms ? TEST_LOGIC_RESET : CAPTURE_IR;

            CAPTURE_IR:
                next_state = tms ? EXIT1_IR : SHIFT_IR;

            SHIFT_IR:
                next_state = tms ? EXIT1_IR : SHIFT_IR;

            EXIT1_IR:
                next_state = tms ? UPDATE_IR : PAUSE_IR;

            PAUSE_IR:
                next_state = tms ? EXIT2_IR : PAUSE_IR;

            EXIT2_IR:
                next_state = tms ? UPDATE_IR : SHIFT_IR;

            UPDATE_IR:
                next_state = tms ? SELECT_DR_SCAN : RUN_TEST_IDLE;

            default:
                next_state = TEST_LOGIC_RESET;

        endcase
    end

    always @(*) begin
        test_logic_reset = (state == TEST_LOGIC_RESET);
        run_test_idle    = (state == RUN_TEST_IDLE);

        capture_dr       = (state == CAPTURE_DR);
        shift_dr         = (state == SHIFT_DR);
        update_dr        = (state == UPDATE_DR);

        capture_ir       = (state == CAPTURE_IR);
        shift_ir         = (state == SHIFT_IR);
        update_ir        = (state == UPDATE_IR);
    end

endmodule
