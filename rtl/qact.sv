module qact #(
  parameter 
    N  = 1,
    XB = 8, 
    XBF= 1,
    YB = 8, 
    YBI = 0,
    NEGATIVE_SLOPE=0,
    YB_OUT = YB + (NEGATIVE_SLOPE==0)
)(
  input  logic [N-1:0][XB    -1:0] x,
  output logic [N-1:0][YB_OUT-1:0] y
);

  localparam
    YBU = YB-(NEGATIVE_SLOPE!=0),
    YBF = YBU - YBI,
    HALF = 2**(XBF-YBF-1);

  logic [N-1:0][XB-1:0] clip_min;
  logic [N-1:0][XB  :0] round, shift;
  logic [N-1:0][YB-1:0] clip_max;

  always_comb
    for (int n=0; n<N; n++) begin:g

      clip_min[n] = $signed(x[n]) < $signed(0) ? '0 : $signed(x[n]);
      round   [n] = clip_min[n] + HALF;
      shift   [n] = round[n] >> (XBF-YBF);
      // clip_max[n] = shift[n] > (2**YBU-1) ? (2**YBU-1) : shift[n];
      clip_max[n] = shift[n][XB-1:YBU] != 0 ? '1 : shift[n][YB-1:0];

      y[n]        = clip_max[n];
    end
endmodule