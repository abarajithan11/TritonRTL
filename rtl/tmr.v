module tmr #(
  parameter TRIPLICATE=1, 
            RESET_VAL=0
)(
  input  wire clk, rstn, en, d,
  output reg  q
);
  generate
    if (TRIPLICATE) begin: T

      reg [2:0] triple;
      always @(posedge clk)
        if (!rstn)   triple <= {3{RESET_VAL}};
        else if (en) triple <= {3{d}};
      
      always @* q = (triple[0] && triple[1]) || (triple[1] && triple[2]) || (triple[2] && triple[0]);

    end else begin
      always @(posedge clk) 
        if (!rstn)   q <= RESET_VAL;
        else if (en) q <= d;
    end
  endgenerate

endmodule