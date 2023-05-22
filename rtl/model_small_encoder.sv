
module model #(

  localparam
    DENSE3_XD=16, DENSE3_YD=16, DENSE3_KB=8, DENSE3_XB=10,
    DENSE3_YB=DENSE3_XB + DENSE3_KB + $clog2(DENSE3_XD+1),
    DENSE3_KD=DENSE3_XD*DENSE3_YD, DENSE3_BD=DENSE3_YD,
  localparam
    ACT4_XB=DENSE3_YB, ACT4_XBF=12, ACT4_YBQ=16, ACT4_YBI=3, ACT4_D=16, 
    ACT4_NEGATIVE_SLOPE=0,
    ACT4_YB=ACT4_YBQ+(ACT4_NEGATIVE_SLOPE==0),
  localparam
    DENSE5_XD=16, DENSE5_YD=16, DENSE5_KB=8, DENSE5_XB=ACT4_YB,
    DENSE5_YB=DENSE5_XB + DENSE5_KB + $clog2(DENSE5_XD+1),
    DENSE5_KD=DENSE5_XD*DENSE5_YD, DENSE5_BD=DENSE5_YD,
  localparam
    ACT6_XB=DENSE5_YB, ACT6_XBF=19, ACT6_YBQ=16, ACT6_YBI=3, ACT6_D=16, 
    ACT6_NEGATIVE_SLOPE=0,
    ACT6_YB=ACT6_YBQ+(ACT6_NEGATIVE_SLOPE==0),
  localparam
    XD=DENSE3_XD, XB=DENSE3_XB, 
    YD=ACT6_D, YB=ACT6_YB,
    WEIGHTS_B = 10496
)(
  input  logic clk, rstn, copy, k,
  input  logic [XD-1:0][XB-1:0] x,
  output logic [YD-1:0][YB-1:0] y
);
  // TMR Weights
  
  wire [WEIGHTS_B-1:0] weights_q;
  register #(.W(WEIGHTS_B)) TMR_REG (.clk(clk), .rstn(rstn), .en(copy), .d({k, weights_q[WEIGHTS_B-1:1]}), .q(weights_q));
  
  // Dense 3

  logic [DENSE3_KD-1:0][DENSE3_KB-1:0] dense3_k;
  logic [DENSE3_BD-1:0][DENSE3_KB-1:0] dense3_b;
  logic [DENSE3_XD-1:0][DENSE3_XB-1:0] dense3_x; 
  logic [DENSE3_YD-1:0][DENSE3_YB-1:0] dense3_y;
  qdense #(.YD(DENSE3_YD), .XD(DENSE3_XD), .XB(DENSE3_XB), .KB(DENSE3_KB)
    ) DENSE3 (  
    .k(dense3_k),
    .b(dense3_b),
    .x(dense3_x), 
    .y(dense3_y)
  );
        
  // Act 4

  logic [ACT4_D-1:0][ACT4_XB-1:0] act4_x;
  logic [ACT4_D-1:0][ACT4_YB-1:0] act4_y;
  qact #(.N(ACT4_D), .XB(ACT4_XB), .XBF(ACT4_XBF), .YBQ(ACT4_YBQ), .YBI(ACT4_YBI), .NEGATIVE_SLOPE(ACT4_NEGATIVE_SLOPE)
    ) ACT4 (
    .x(act4_x),
    .y(act4_y)
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
        
  assign {dense5_b, dense5_k, dense3_b, dense3_k} = weights_q;
  
  assign dense3_x = x;
  assign act4_x = dense3_y;
  assign dense5_x = act4_y;
  assign act6_x = dense5_y;
  always_ff @(posedge clk) 
    y <= act6_y;

endmodule