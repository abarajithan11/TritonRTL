
module model #(

  localparam
    CONV2_XB=10, CONV2_KB=5,
    CONV2_XH=8, CONV2_XW=8, CONV2_XC=1, CONV2_YC=32,
    CONV2_KH=5, CONV2_KW=5, CONV2_SH=2, CONV2_SW=2,
    CONV2_YH=CONV2_XH/CONV2_SH, CONV2_YW=CONV2_XW/CONV2_SW,
    CONV2_YB=CONV2_XB+CONV2_KB + $clog2(CONV2_KH*CONV2_KW*CONV2_XC+1),
    CONV2_XD=CONV2_XH*CONV2_XW*CONV2_XC,
    CONV2_KD=CONV2_KH*CONV2_KW*CONV2_XC*CONV2_YC, CONV2_BD=CONV2_YC,
    CONV2_YD=CONV2_YH*CONV2_YW*CONV2_YC,
  localparam
    ACT3_XB=CONV2_YB, ACT3_XBF=9, ACT3_YBQ=11, ACT3_YBI=3, ACT3_D=512, 
    ACT3_NEGATIVE_SLOPE=0,
    ACT3_YB=ACT3_YBQ+(ACT3_NEGATIVE_SLOPE==0),
  localparam
    DENSE5_XD=512, DENSE5_YD=16, DENSE5_KB=7, DENSE5_XB=ACT3_YB,
    DENSE5_YB=DENSE5_XB + DENSE5_KB + $clog2(DENSE5_XD+1),
    DENSE5_KD=DENSE5_XD*DENSE5_YD, DENSE5_BD=DENSE5_YD,
  localparam
    ACT6_XB=DENSE5_YB, ACT6_XBF=13, ACT6_YBQ=13, ACT6_YBI=3, ACT6_D=16, 
    ACT6_NEGATIVE_SLOPE=0,
    ACT6_YB=ACT6_YBQ+(ACT6_NEGATIVE_SLOPE==0),
  localparam
    XD=CONV2_XD, XB=CONV2_XB, 
    YD=ACT6_D, YB=ACT6_YB,
    WEIGHTS_B = 61616
)(
  input  logic clk, rstn, copy, k,
  input  logic [XD-1:0][XB-1:0] x,
  output logic [YD-1:0][YB-1:0] y
);
  // TMR Weights
  
  wire [WEIGHTS_B-1:0] weights_q;
  register #(.W(WEIGHTS_B)) TMR_REG (.clk(clk), .rstn(rstn), .en(copy), .d({k, weights_q[WEIGHTS_B-1:1]}), .q(weights_q));
  
  // Conv 2

  logic [CONV2_XD-1:0] [CONV2_XB-1:0] conv2_x;
  logic [CONV2_KD-1:0] [CONV2_KB-1:0] conv2_k;
  logic [CONV2_BD-1:0] [CONV2_KB-1:0] conv2_b;
  logic [CONV2_YD-1:0] [CONV2_YB-1:0] conv2_y;

  qconv2d #(
    .XN(1), .XH(CONV2_XH), .XW(CONV2_XW), .XC(CONV2_XC), .KH(CONV2_KH), .KW(CONV2_KW), .SH(CONV2_SH), .SW(CONV2_SW), .YC(CONV2_YC), .XB(CONV2_XB), .KB(CONV2_KB)
    ) CONV2 (
    .x(conv2_x),
    .k(conv2_k),
    .b(conv2_b),
    .y(conv2_y)
  );
        
  // Act 3

  logic [ACT3_D-1:0][ACT3_XB-1:0] act3_x;
  logic [ACT3_D-1:0][ACT3_YB-1:0] act3_y;
  qact #(.N(ACT3_D), .XB(ACT3_XB), .XBF(ACT3_XBF), .YBQ(ACT3_YBQ), .YBI(ACT3_YBI), .NEGATIVE_SLOPE(ACT3_NEGATIVE_SLOPE)
    ) ACT3 (
    .x(act3_x),
    .y(act3_y)
  );
        
  // Dense 5

  logic [DENSE5_KD-1:0][DENSE5_KB-1:0] dense5_k;
  logic [DENSE5_BD-1:0][DENSE5_KB-1:0] dense5_b;
  logic [DENSE5_XD-1:0][DENSE5_XB-1:0] dense5_x; 
  logic [DENSE5_YD-1:0][DENSE5_YB-1:0] dense5_y;
  qdense #(.YD(DENSE5_YD), .XD(DENSE5_XD), .XB(DENSE5_XB), .KB(DENSE5_KB)
    ) DENSE5 (  
    .k(dense5_k),
    .b(dense5_b),
    .x(dense5_x), 
    .y(dense5_y)
  );
        
  // Act 6

  logic [ACT6_D-1:0][ACT6_XB-1:0] act6_x;
  logic [ACT6_D-1:0][ACT6_YB-1:0] act6_y;
  qact #(.N(ACT6_D), .XB(ACT6_XB), .XBF(ACT6_XBF), .YBQ(ACT6_YBQ), .YBI(ACT6_YBI), .NEGATIVE_SLOPE(ACT6_NEGATIVE_SLOPE)
    ) ACT6 (
    .x(act6_x),
    .y(act6_y)
  );
        
  assign {dense5_b, dense5_k, conv2_b, conv2_k} = weights_q;
  
  assign conv2_x = x;
  assign act3_x = conv2_y;
  assign dense5_x = act3_y;
  assign act6_x = dense5_y;
  always_ff @(posedge clk) 
    y <= act6_y;

endmodule