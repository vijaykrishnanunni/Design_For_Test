module scan_ff (
    input  wire clk,
    input  wire rst_n,
    input  wire scan_en,
    input  wire si,
    input  wire d,
    output reg  q, 
    output wire so
);

    wire d_mux;

    assign d_mux = (scan_en) ? si : d;
    assign so    = q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            q <= 1'b0;
        else
            q <= d_mux;
    end

endmodule
