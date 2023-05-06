module register #(
  parameter W=10,
  parameter [W-1:0] TRIPLICATE=10'b0101010101, RESET_VAL=0
)(
  input  wire clk, rstn, en, 
  input  wire [W-1:0] d,
  output wire [W-1:0] q
);
  genvar i;
  generate
    for (i=0; i<W; i=i+1) begin: T
      tmr #(
        .TRIPLICATE (TRIPLICATE[i]),
        .RESET_VAL  (RESET_VAL [i])
      ) TR (
        .clk  (clk ),
        .rstn (rstn),
        .en   (en  ),
        .d    (d[i]),
        .q    (q[i])
      );
    end
  endgenerate

endmodule