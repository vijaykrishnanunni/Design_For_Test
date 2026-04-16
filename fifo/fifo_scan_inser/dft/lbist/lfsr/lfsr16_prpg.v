`timescale 1ns/1ps

module lfsr16_prpg (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        enable,
    input  wire        load_seed,
    input  wire [15:0] seed,
    output wire        prpg_bit,
    output wire [15:0] prpg_word
);

    reg [15:0] lfsr_reg;
    wire feedback;

    assign feedback  = lfsr_reg[15] ^ lfsr_reg[13] ^ lfsr_reg[12] ^ lfsr_reg[10];
    assign prpg_word = lfsr_reg;
    assign prpg_bit  = lfsr_reg[15];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            lfsr_reg <= 16'hACE1;
        else if (load_seed)
            lfsr_reg <= (seed != 16'h0000) ? seed : 16'hACE1;
        else if (enable)
            lfsr_reg <= {lfsr_reg[14:0], feedback};
    end

endmodule
