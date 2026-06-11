
`timescale 1ns/1ps

module jtag_ir #(
    parameter IR_WIDTH = 4 
)(
    input  wire                  tck,
    input  wire                  trst_n,
    input  wire                  tdi,

    input  wire                  capture_ir,
    input  wire                  shift_ir,
    input  wire                  update_ir,

    output wire                  ir_tdo,
    output reg  [IR_WIDTH-1:0]   instruction
);

    localparam [IR_WIDTH-1:0] IDCODE = 4'b0001;

    reg [IR_WIDTH-1:0] ir_shift;

    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            ir_shift    <= IDCODE;
            instruction <= IDCODE;
        end
        else begin
            if (capture_ir) begin
                ir_shift <= IDCODE;
            end
            else if (shift_ir) begin
                ir_shift <= {tdi, ir_shift[IR_WIDTH-1:1]};
            end
            else if (update_ir) begin
                instruction <= ir_shift;
            end
        end
    end

    assign ir_tdo = ir_shift[0];

endmodule
