module model_tb;

  localparam XD=64, XB=11, YD=16, YB=10;

  logic clk=0, rstn=1, en=0;
  logic [XD-1:0][XB-1:0] x;
  logic [YD-1:0][YB-1:0] y;

  model model (.*);

  initial forever #5ns clk = !clk;

  int fd, status;
  localparam DIR = "D:/research/tritonRTL/test/vectors/";
  initial begin
    fd = $fopen({DIR,"x.txt"}, "r");
    for (int xn=0; xn<XD; xn++)
      status = $fscanf(fd, "%d", x[xn]);
    $fclose(fd);

    @(posedge clk) #1ns;
    en = 1;
    @(posedge clk) #1ns;
    en = 0;

    @(posedge clk);

    // fd = $fopen({DIR,"y2_sim.txt"}, "w");
    // for (int yn=0; yn<CONV2_YD; yn++)
    //   $fdisplay(fd, "%d", $signed(model.conv2_y[yn]));
    // $fclose(fd);

    // fd = $fopen({DIR,"y3_sim.txt"}, "w");
    // for (int yn=0; yn<ACT3_D; yn++)
    //   $fdisplay(fd, "%d", model.act3_y[yn]);
    // $fclose(fd);

    // fd = $fopen({DIR,"y5_sim.txt"}, "w");
    // for (int yn=0; yn<DENSE5_YD; yn++)
    //   $fdisplay(fd, "%d", $signed(model.dense5_y[yn]));
    // $fclose(fd);

    fd = $fopen({DIR,"y6_sim.txt"}, "w");
    for (int yn=0; yn<YD; yn++)
      $fdisplay(fd, "%d", model.act6_y[yn]);
    $fclose(fd);
  end
endmodule