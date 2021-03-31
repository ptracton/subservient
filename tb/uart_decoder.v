module uart_decoder
  (input wire [31:0] baud_rate,
   input wire 	     rx);

   integer i;
   reg [7:0] ch;

   real t;

   initial begin

      @(posedge rx);
      t = 1000000000/baud_rate;

      forever begin
	 @(negedge rx);
	 #(t/2) ch = 0;
	 for (i=0;i<8;i=i+1)
	   #t ch[i] = rx;
	 $write("%c",ch);
	 $fflush;
      end
   end
endmodule
