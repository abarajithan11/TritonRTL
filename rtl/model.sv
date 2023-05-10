module model #(
  localparam  
    CONV2_XN=1, CONV2_XH=8, CONV2_XW=8, CONV2_XC=1,
    CONV2_KH=3, CONV2_KW=3,
    CONV2_SH=2, CONV2_SW=2,
    CONV2_YC=8,
    CONV2_XB=11, CONV2_KB=6,
    CONV2_YN=CONV2_XN, CONV2_YH=CONV2_XH/CONV2_SH, CONV2_YW=CONV2_XW/CONV2_SW,
    CONV2_YB=CONV2_XB+CONV2_KB + $clog2(CONV2_KH*CONV2_KW*CONV2_XC+1),
    CONV2_XD=CONV2_XN*CONV2_XH*CONV2_XW*CONV2_XC,
    CONV2_KD=CONV2_KH*CONV2_KW*CONV2_XC*CONV2_YC,
    CONV2_BD=CONV2_YC,
    CONV2_YD=CONV2_YN*CONV2_YH*CONV2_YW*CONV2_YC,
  localparam 
    ACT3_XBF=11, ACT3_YB=12, ACT3_YBI=3,
    ACT3_NEGATIVE_SLOPE = 0,
    ACT3_YB_OUT=ACT3_YB+(ACT3_NEGATIVE_SLOPE==0), ACT3_D=CONV2_YD, ACT3_XB=CONV2_YB,
  localparam
    DENSE5_YD=16, DENSE5_KB=6,
    DENSE5_XD=ACT3_D, DENSE5_XB=ACT3_YB_OUT, DENSE5_YB=DENSE5_XB + DENSE5_KB + $clog2(DENSE5_XD+1),
    DENSE5_KD=DENSE5_XD*DENSE5_YD, DENSE5_BD=DENSE5_YD,
  localparam 
    ACT6_XBF=13, ACT6_YB=9, ACT6_YBI=1,
    ACT6_NEGATIVE_SLOPE = 0,
    ACT6_YB_OUT=ACT6_YB+(ACT6_NEGATIVE_SLOPE==0), ACT6_D=DENSE5_YD, ACT6_XB  = DENSE5_YB

)(
  input  logic [CONV2_XD-1:0] [CONV2_XB-1:0] x,
  output logic [ACT6_D -1:0][ACT6_YB-1:0] y
);

  // Conv 2

  logic [CONV2_XD-1:0] [CONV2_XB-1:0] conv2_x;
  logic [CONV2_KD-1:0] [CONV2_KB-1:0] conv2_k;
  logic [CONV2_BD-1:0] [CONV2_KB-1:0] conv2_b;
  logic [CONV2_YD-1:0] [CONV2_YB-1:0] conv2_y;

  qconv2d #(
    .XN(CONV2_XN), .XH(CONV2_XH), .XW(CONV2_XW), .XC(CONV2_XC), .KH(CONV2_KH), .KW(CONV2_KW), .SH(CONV2_SH), .SW(CONV2_SW), .YC(CONV2_YC), .XB(CONV2_XB), .KB(CONV2_KB)
    ) CONV2 (
    .x(conv2_x),
    .k(conv2_k),
    .b(conv2_b),
    .y(conv2_y)
  );

  // Relu 3 

  wire [ACT3_D-1:0][ACT3_XB    -1:0] act3_x = conv2_y;
  wire [ACT3_D-1:0][ACT3_YB_OUT-1:0] act3_y;
  qact #(.N(ACT3_D), .XB(ACT3_XB), .XBF(ACT3_XBF), .YB(ACT3_YB), .YBI(ACT3_YBI), .NEGATIVE_SLOPE(ACT3_NEGATIVE_SLOPE)
    ) ACT3 (
    .x(act3_x),
    .y(act3_y)
  );

  // Dense 4

  logic [DENSE5_KD-1:0][DENSE5_KB-1:0] dense5_k;
  logic [DENSE5_BD-1:0][DENSE5_KB-1:0] dense5_b;
  wire  [DENSE5_XD-1:0][DENSE5_XB-1:0] dense5_x = act3_y; 
  wire  [DENSE5_YD-1:0][DENSE5_YB-1:0] dense5_y;
  qdense #(.YD(DENSE5_YD), .XD(DENSE5_XD), .XB(DENSE5_XB), .KB(DENSE5_KB)
    ) DENSE5 (  
    .k(dense5_k),
    .b(dense5_b),
    .x(dense5_x), 
    .y(dense5_y)
  );

  wire [ACT6_D-1:0][ACT6_XB    -1:0] act6_x = dense5_y;
  wire [ACT6_D-1:0][ACT6_YB_OUT-1:0] act6_y;
  qact #(.N(ACT6_D), .XB(ACT6_XB), .XBF(ACT6_XBF), .YB(ACT6_YB), .YBI(ACT6_YBI), .NEGATIVE_SLOPE(ACT6_NEGATIVE_SLOPE)
    ) ACT6 (
    .x(act6_x),
    .y(act6_y)
  );
  // assign x = conv2_x;
  // assign y = act3_y;

  int fd, status;
  localparam DIR = "D:/research/tritonRTL/test/vectors/";
  initial begin
    fd = $fopen({DIR,"x.txt"}, "r");
    for (int xn=0; xn<CONV2_XD; xn++)
      status = $fscanf(fd, "%d", conv2_x[xn]);
    $fclose(fd);
    
    fd = $fopen({DIR,"k2.txt"}, "r");
    for (int kn=0; kn<CONV2_KD; kn++)
      status = $fscanf(fd, "%d", conv2_k[kn]);
    $fclose(fd);

    fd = $fopen({DIR,"b2.txt"}, "r");
    for (int bn=0; bn<CONV2_BD; bn++)
      status = $fscanf(fd, "%d", conv2_b[bn]);
    $fclose(fd);

    fd = $fopen({DIR,"k5.txt"}, "r");
    for (int kn=0; kn<DENSE5_KD; kn++)
      status = $fscanf(fd, "%d", dense5_k[kn]);
    $fclose(fd);

    fd = $fopen({DIR,"b5.txt"}, "r");
    for (int bn=0; bn<DENSE5_BD; bn++)
      status = $fscanf(fd, "%d", dense5_b[bn]);
    $fclose(fd);

    #(100ns);

    fd = $fopen({DIR,"y2_sim.txt"}, "w");
    for (int yn=0; yn<CONV2_YD; yn++)
      $fdisplay(fd, "%d", $signed(conv2_y[yn]));
    $fclose(fd);

    fd = $fopen({DIR,"y3_sim.txt"}, "w");
    for (int yn=0; yn<ACT3_D; yn++)
      $fdisplay(fd, "%d", act3_y[yn]);
    $fclose(fd);

    fd = $fopen({DIR,"y5_sim.txt"}, "w");
    for (int yn=0; yn<DENSE5_YD; yn++)
      $fdisplay(fd, "%d", $signed(dense5_y[yn]));
    $fclose(fd);

    fd = $fopen({DIR,"y6_sim.txt"}, "w");
    for (int yn=0; yn<ACT6_D; yn++)
      $fdisplay(fd, "%d", act6_y[yn]);
    $fclose(fd);
  end

endmodule