////////dummy golden reference
`timescale 1ns/1ps

module golden_signature_mem #(
    parameter WIDTH = 16,
    parameter [WIDTH-1:0] GOLDEN_SIG = 16'hA5C3
)(
    input  wire                  read_en,
    output reg  [WIDTH-1:0]      golden_sig
);

    always @(*) begin
        if (read_en)
            golden_sig = GOLDEN_SIG;
        else
            golden_sig = {WIDTH{1'b0}};
    end

endmodule
