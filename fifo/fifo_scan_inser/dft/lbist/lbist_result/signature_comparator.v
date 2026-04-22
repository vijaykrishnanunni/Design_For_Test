`timescale 1ns/1ps

module signature_comparator #(
    parameter WIDTH = 16
)(
    input  wire [WIDTH-1:0] misr_sig,
    input  wire [WIDTH-1:0] golden_sig,
    input  wire             compare_en,
    output reg              match,
    output reg              mismatch,
    output reg              bist_pass,
    output reg              bist_fail
);

    always @(*) begin
        if (compare_en) begin
            if (misr_sig == golden_sig) begin
                match     = 1'b1;
                mismatch  = 1'b0;
                bist_pass = 1'b1;
                bist_fail = 1'b0;
            end
            else begin
                match     = 1'b0;
                mismatch  = 1'b1;
                bist_pass = 1'b0;
                bist_fail = 1'b1;
            end
        end
        else begin
            match     = 1'b0;
            mismatch  = 1'b0;
            bist_pass = 1'b0;
            bist_fail = 1'b0;
        end
    end

endmodule
