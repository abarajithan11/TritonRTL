module register #(
  parameter W=12, DIV=16,
  parameter [W-1:0] TRIPLICATE=10'b0101010101, RESET_VAL=0
)(
  input  wire clk, rstn, en, 
  input  wire [W-1:0] d,
  output wire [W-1:0] q
);
  genvar n1, n2;
  generate
    for (n1=0; n1<DIV; n1=n1+1) begin:N1
      for (n2=0; n2<W/DIV; n2=n2+1) begin:N2
        localparam i = n1*(W/DIV) + n2;
        tmr #(
          // .TRIPLICATE (TRIPLICATE[i]),
          .RESET_VAL  (RESET_VAL [i])
        ) TR (
          .clk  (clk ),
          .rstn (rstn),
          .en   (en  ),
          .d    (d[i]),
          .q    (q[i])
        );
      end 
    end
  endgenerate

endmodule