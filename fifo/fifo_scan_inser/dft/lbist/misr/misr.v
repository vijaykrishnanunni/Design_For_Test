`timescale 1ns/1ps

module misr #( 
    parameter WIDTH = 16,
    parameter [WIDTH-1:0] POLY = 16'hB400
)(
    input  wire             clk,
    input  wire             rst_n,
    input  wire             enable,
    input  wire             data_in,
    output reg  [WIDTH-1:0] signature
);

    integer i;
    reg feedback;
    reg [WIDTH-1:0] next_signature;

    always @(*) begin
        feedback = signature[WIDTH-1];

        next_signature[0] = feedback ^ data_in;

        for (i = 1; i < WIDTH; i = i + 1) begin
            if (POLY[i])
                next_signature[i] = signature[i-1] ^ feedback;
            else
                next_signature[i] = signature[i-1];
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            signature <= {WIDTH{1'b0}};
        else if (enable)
            signature <= next_signature;
    end

endmodule
