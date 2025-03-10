/*
 * Copyright (c) 2025 Thomas Flummer
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_flummer_ltc (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
    );

    // All output pins must be assigned. If not used, assign to 0.
    assign uo_out[7:0] = 8'b0;

    assign uio_out[6:0] = 7'b0;
    assign uio_oe  = 8'b10000000;

    wire timecode;
    assign uio_out[7] = timecode;

    // List all unused inputs to prevent warnings
    wire _unused = &{ena};

    ltc ltc (
    .clk        (clk), 
    .reset_n    (rst_n),
    // inputs
    .framerate  (ui_in[3:2]),
    .inc_hrs    (ui_in[5]),
    .inc_min    (ui_in[6]),
    .inc_sec    (ui_in[7]),
    // outputs
    .timecode      (timecode)
    );

endmodule
