module qconv2d #(
  parameter
    XN=1, XH=8, XW=8, XC=1,
    KH=3, KW=3,
    SH=2, SW=2,
    YC=8,
    XB=11,
    KB=6,
  localparam 
    YN= XN, YH=XH/SH, YW=XW/SW,
    MB= XB+KB,
    YB= MB + $clog2(KH*KW*XC+1)
)(
  input  logic [XN-1:0][XH-1:0][XW-1:0][XC-1:0] [XB-1:0] x,
  input  logic [KH-1:0][KW-1:0][XC-1:0][YC-1:0] [KB-1:0] k,
  input  logic                         [YC-1:0] [KB-1:0] b,
  output logic [YN-1:0][YH-1:0][YW-1:0][YC-1:0] [YB-1:0] y
);

  // Padding eqn: https://www.tensorflow.org/api_docs/python/tf/nn#notes_on_padding_2
  localparam  XH_PAD = XH + KH-SH,
              XW_PAD = XW + KW-SW,
              PH    = (XH % SH) ? KH-(XH%SH) : KH-SH,
              PW    = (XW % SW) ? KW-(XW%SW) : KW-SW;

  logic [XN-1:0][XH_PAD-1:0][XW_PAD-1:0][XC-1:0] [XB-1:0] x_pad;

  always_comb begin
    x_pad = '0;
    for (int xn=0; xn<XN; xn++)
      for (int xh=0; xh<XH; xh++)
        for (int xw=0; xw<XW; xw++)
          for (int xc=0; xc<XC; xc++)
            x_pad[xn][xh+PH/2][xw+PW/2][xc] = x[xn][xh][xw][xc];
  end

  // Conv eqn: https://www.tensorflow.org/api_docs/python/tf/nn/conv2d
  logic [YN-1:0][YH-1:0][YW-1:0][YC-1:0]  [KH-1:0][KW-1:0][XC-1:0]  [MB-1:0] mul;
  genvar xn, yh, yw, yc, kh, kw, xc;
  for (xn=0; xn<XN; xn++)
    for (yh=0; yh<YH; yh++)
      for (yw=0; yw<YW; yw++)
        for (yc=0; yc<YC; yc++) begin

          for (kh=0; kh<KH; kh++)
            for (kw=0; kw<KW; kw++)
              for (xc=0; xc<XC; xc++)
                assign mul[xn][yh][yw][yc] [kh][kw][xc] =  $signed(x_pad[xn][SH * yh + kh][SW * yw + kw][xc]) * $signed(k[kh][kw][xc][yc]);

          add #(.N(KH*KW*XC+1), .BI(MB)) ADD (.x({mul[xn][yh][yw][yc], MB'(b[yc])}), .y(y[xn][yh][yw][yc]));
        end
endmodule