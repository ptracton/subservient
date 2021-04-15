`default_nettype none
module subservient_tb;

   parameter memfile = "";
   parameter memsize = 8192;
   parameter with_csr = 0;

   reg wb_clk = 1'b0;
   reg wb_rst = 1'b1;

   wire q;

   always  #5 wb_clk <= !wb_clk;
   initial #62 wb_rst <= 1'b0;

   vlog_tb_utils vtu();

   integer baudrate = 0;
   initial begin
      if ($value$plusargs("uart_baudrate=%d", baudrate))
	$display("UART decoder using baud rate %d", baudrate);
      else
	forever
	  @(q) $display("%0t output o_gpio is %s", $time, q ? "ON" : "OFF");

   end

   uart_decoder #(57600) uart_decoder (q & |baudrate);

   subservient_sim
     #(.memfile  (memfile),
       .memsize  (memsize),
       .with_csr (with_csr))
   dut(wb_clk, wb_rst, q);

endmodule
