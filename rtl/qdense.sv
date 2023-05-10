module qdense #(
    parameter YD=8, XD=8, XB=8, KB=8,
    localparam DEPTH = $clog2(XD+1),
               MB = XB + KB,
               YB = MB + DEPTH
  )(  
    input  logic [XD-1:0][YD-1:0][KB-1:0] k,
    input  logic         [YD-1:0][KB-1:0] b,
    input  logic         [XD-1:0][XB-1:0] x, 
    output logic         [YD-1:0][YB-1:0] y
  );

  // Padding
  localparam XD_PAD = 2**$clog2(XD);
  logic [YD-1:0][XD_PAD-1:0][MB-1:0] mul;

  wire  [XD_PAD-1:0]        [XB-1:0] x_pad = {'0, x};
  logic [XD_PAD-1:0][YD-1:0][KB-1:0] k_pad;      

  always_comb begin
    k_pad = '0;
    for (int yn=0; yn<YD; yn=yn+1)
      for (int xn=0; xn<XD; xn=xn+1) begin
        k_pad[xn][yn] = k[xn][yn];
        mul  [yn][xn] = $signed(x_pad[xn]) * $signed(k_pad[xn][yn]);
      end
  end

  genvar yn;
  for (yn=0; yn<YD; yn=yn+1)
    add #(.N(XD+1), .BI(MB)) ADD (.x({mul[yn], MB'($signed(b[yn]))}), .y(y[yn]));
    
endmodule