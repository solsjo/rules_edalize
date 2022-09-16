module counter
  #(parameter width = 8)
   (input wire i_clk,
    input wire 		   i_rst,
    output reg [width-1:0] q);

   always @(posedge i_clk) begin
      q <= q + 1;
      if (i_rst)
	q <= {width{1'b0}};
   end
endmodule
