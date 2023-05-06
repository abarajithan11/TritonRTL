module add #(
  parameter N=1, BI=8, 
  localparam BO= BI + $clog2(N)
)(
  input  logic [N-1:0][BI-1:0] x,
  output logic        [BO-1:0] y
);

  always_comb begin
    y = '0;
    for (int n=0; n<N; n++)
      y = $signed(y) + $signed(x[n]);
  end

endmodule