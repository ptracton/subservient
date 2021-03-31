/* serving_arbiter.v : I/D arbiter for the serving SoC
 *  Relies on the fact that not both masters are active at the same time
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

module subservient_debug_switch
  (input wire i_debug_mode,
   
   input wire [31:0]  i_wb_dbg_adr,
   input wire [31:0]  i_wb_dbg_dat,
   input wire [3:0]   i_wb_dbg_sel,
   input wire 	      i_wb_dbg_we,
   input wire 	      i_wb_dbg_stb,
   output wire [31:0] o_wb_dbg_rdt,
   output wire 	      o_wb_dbg_ack,

   input wire [31:0]  i_wb_dbus_adr,
   input wire [31:0]  i_wb_dbus_dat,
   input wire [3:0]   i_wb_dbus_sel,
   input wire 	      i_wb_dbus_we,
   input wire 	      i_wb_dbus_stb,
   output wire [31:0] o_wb_dbus_rdt,
   output wire 	      o_wb_dbus_ack,

   output wire [31:0] o_wb_mux_adr,
   output wire [31:0] o_wb_mux_dat,
   output wire [3:0]  o_wb_mux_sel,
   output wire 	      o_wb_mux_we,
   output wire 	      o_wb_mux_stb,
   input wire [31:0]  i_wb_mux_rdt,
   input wire 	      i_wb_mux_ack);

   assign o_wb_dbg_rdt  = i_wb_mux_rdt;
   assign o_wb_dbg_ack  = i_wb_mux_ack & i_debug_mode;

   assign o_wb_dbus_rdt = i_wb_mux_rdt;
   assign o_wb_dbus_ack = i_wb_mux_ack & !i_debug_mode;

   assign o_wb_mux_adr = i_debug_mode ? i_wb_dbg_adr : i_wb_dbus_adr;
   assign o_wb_mux_dat = i_debug_mode ? i_wb_dbg_dat : i_wb_dbus_dat;
   assign o_wb_mux_sel = i_debug_mode ? i_wb_dbg_sel : i_wb_dbus_sel;
   assign o_wb_mux_we  = i_debug_mode ? i_wb_dbg_we  : i_wb_dbus_we ;
   assign o_wb_mux_stb = i_debug_mode ? i_wb_dbg_stb : i_wb_dbus_stb;


endmodule
