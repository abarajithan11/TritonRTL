module model_tb;

  localparam
    DIR = "D:/research/tritonRTL/test/vectors/",
    XN = 64,
    YN = 128,
    KN = 72,
    BN = 8,
    XB = 11,
    KB = 6,
    YB = XB+KB + $clog2(3*3*1+1);

  logic [XN-1:0][XB-1:0] x;
  logic [KN-1:0][KB-1:0] k;
  logic [BN-1:0][KB-1:0] b;
  logic [YN-1:0][YB-1:0] y;

  qconv2d model (.*);

  int fd, status;

  initial begin
    fd = $fopen({DIR,"x.txt"}, "r");
    for (int xn=0; xn<XN; xn++)
      status = $fscanf(fd, "%d", x[xn]);
    $fclose(fd);
    
    fd = $fopen({DIR,"k.txt"}, "r");
    for (int kn=0; kn<KN; kn++)
      status = $fscanf(fd, "%d", k[kn]);
    $fclose(fd);

    fd = $fopen({DIR,"b.txt"}, "r");
    for (int bn=0; bn<BN; bn++)
      status = $fscanf(fd, "%d", b[bn]);
    $fclose(fd);

    #(100ns);

    fd = $fopen({DIR,"y.txt"}, "w");
    for (int yn=0; yn<YN; yn++)
      $fdisplay(fd, "%d", $signed(y[yn]));
    $fclose(fd);
  end
endmodule