/* subservient.v : Tech-agnostic toplevel for the subservient SoC
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
module subservient
  #(//Memory parameters
    parameter memsize = 512,
    parameter aw    = $clog2(memsize))
  (
   input wire 		i_clk,
   input wire 		i_rst,

   //SRAM interface
   output wire [aw-1:0] o_sram_waddr,
   output wire [7:0] 	o_sram_wdata,
   output wire 		o_sram_wen,
   output wire [aw-1:0] o_sram_raddr,
   input wire [7:0] 	i_sram_rdata,
   output wire 		o_sram_ren,

   //Debug interface
   input wire 		i_debug_mode,
   input wire [31:0] 	i_wb_dbg_adr,
   input wire [31:0] 	i_wb_dbg_dat,
   input wire [3:0] 	i_wb_dbg_sel,
   input wire 		i_wb_dbg_we ,
   input wire 		i_wb_dbg_stb,
   output wire [31:0] 	o_wb_dbg_rdt,
   output wire 		o_wb_dbg_ack,

   //External I/O
   output wire 		o_gpio);

   parameter WITH_CSR = 0;

   wire [31:0] 	wb_core_adr;
   wire [31:0] 	wb_core_dat;
   wire [3:0] 	wb_core_sel;
   wire 	wb_core_we;
   wire 	wb_core_stb;
   wire [31:0] 	wb_core_rdt;
   wire 	wb_core_ack;

   wire 	wb_gpio_rdt;
   assign wb_core_rdt = {31'd0, wb_gpio_rdt};

   subservient_gpio gpio
     (.i_wb_clk (i_clk),
      .i_wb_rst (i_rst),
      .i_wb_dat (wb_core_dat[0]),
      .i_wb_we  (wb_core_we),
      .i_wb_stb (wb_core_stb),
      .o_wb_rdt (wb_gpio_rdt),
      .o_wb_ack (wb_core_ack),
      .o_gpio   (o_gpio));

   subservient_core
     #(.memsize (memsize),
       .WITH_CSR (WITH_CSR))
   core
     (.i_clk       (i_clk),
      .i_rst       (i_rst),
      .i_timer_irq (1'b0),

      //SRAM interface
      .o_sram_waddr (o_sram_waddr),
      .o_sram_wdata (o_sram_wdata),
      .o_sram_wen   (o_sram_wen),
      .o_sram_raddr (o_sram_raddr),
      .i_sram_rdata (i_sram_rdata),
      .o_sram_ren   (o_sram_ren),

      //Debug interface
      .i_debug_mode (i_debug_mode),
      .i_wb_dbg_adr (i_wb_dbg_adr),
      .i_wb_dbg_dat (i_wb_dbg_dat),
      .i_wb_dbg_sel (i_wb_dbg_sel),
      .i_wb_dbg_we  (i_wb_dbg_we ),
      .i_wb_dbg_stb (i_wb_dbg_stb),
      .o_wb_dbg_rdt (o_wb_dbg_rdt),
      .o_wb_dbg_ack (o_wb_dbg_ack),

      //Peripheral interface
      .o_wb_adr (wb_core_adr),
      .o_wb_dat (wb_core_dat),
      .o_wb_sel (wb_core_sel),
      .o_wb_we  (wb_core_we) ,
      .o_wb_stb (wb_core_stb),
      .i_wb_rdt (wb_core_rdt),
      .i_wb_ack (wb_core_ack));

endmodule
