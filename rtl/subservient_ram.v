/* subservient_ram.v : Shared RF I/D SRAM for the subservient SoC
 *
 * ISC License
 *
 * Copyright (C) 2020 Olof Kindgren <olof.kindgren@gmail.com>
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

`default_nettype none
module subservient_ram
  #(//Memory parameters
    parameter depth = 256,
    parameter aw    = $clog2(depth))
   (input wire 		 i_clk,
    input wire 		 i_rst,
    input wire [aw-1:0]  i_waddr,
    input wire [7:0] 	 i_wdata,
    input wire 		 i_wen,
    input wire [aw-1:0]  i_raddr,
    output wire [7:0] 	 o_rdata,
    input wire 		 i_ren,

    output wire [aw-1:0] o_sram_waddr,
    output wire [7:0] 	 o_sram_wdata,
    output wire 	 o_sram_wen,
    output wire [aw-1:0] o_sram_raddr,
    input wire [7:0] 	 i_sram_rdata,
    output wire 	 o_sram_ren,

    input wire [aw-1:2]  i_wb_adr,
    input wire [31:0] 	 i_wb_dat,
    input wire [3:0] 	 i_wb_sel,
    input wire 		 i_wb_we,
    input wire 		 i_wb_stb,
    output wire [31:0] 	 o_wb_rdt,
    output reg 		 o_wb_ack);

   reg [1:0] 		bsel;

   wire 		wb_en = i_wb_stb & !i_wen & !o_wb_ack;

   wire 		wb_we = i_wb_we & i_wb_sel[bsel];

   assign o_sram_waddr = wb_en ? {i_wb_adr[aw-1:2],bsel} : i_waddr;
   assign o_sram_wdata = wb_en ? i_wb_dat[bsel*8+:8]     : i_wdata;
   assign o_sram_wen   = wb_en ? wb_we : i_wen;
   assign o_sram_raddr = wb_en ? {i_wb_adr[aw-1:2],bsel} : i_raddr;
   assign o_sram_ren   = wb_en ? !i_wb_we : i_ren;

   reg [23:0] 		wb_rdt;
   assign o_wb_rdt = {i_sram_rdata, wb_rdt};

   reg 			regzero;
   always @(posedge i_clk) begin
      if (wb_en) bsel <= bsel + 2'd1;
      o_wb_ack <= wb_en & &bsel;
      if (bsel == 2'b01) wb_rdt[7:0]   <= i_sram_rdata;
      if (bsel == 2'b10) wb_rdt[15:8]  <= i_sram_rdata;
      if (bsel == 2'b11) wb_rdt[23:16] <= i_sram_rdata;
      if (i_rst) begin
	 bsel <= 2'd0;
	 o_wb_ack <= 1'b0;
      end
      regzero <= &i_raddr[aw-1:2];
   end

   assign o_rdata = regzero ? 8'd0 : i_sram_rdata;

endmodule
