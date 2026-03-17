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

    wire i2c_scl;
    wire i2c_sdai;
    wire i2c_sdao;

    wire [23:0] time_cfg;
    wire [39:0] ltc_cfg;

    wire [7:0] rb_address;
    wire [7:0] rb_data_write_to_reg;
    wire [7:0] rb_data_read_from_reg;
    wire rb_reg_en;
    wire rb_write_en;
    wire [1:0] rb_streamSt_mon;

    wire use_reg_conf;
    wire [1:0] framerate;
    wire [2:0] bgf;
    wire dropframe;
    wire colorframe;
    wire [31:0] userbits;

    wire timecode;

    i2c_if i2c_inst(
        .clk            (clk),
        .resetb         (rst_n),
        .sdaIn          (i2c_sdai),
        .sdaOut         (i2c_sdao),
        .scl            (i2c_scl),
        .address        (rb_address),
        .data_write_to_reg(rb_data_write_to_reg),
        .data_read_from_reg(rb_data_read_from_reg),
        .reg_en         (rb_reg_en),
        .write_en       (rb_write_en),
        .streamSt_mon   (rb_streamSt_mon)
    );

    rb_ltc rb_ltc_inst(
        .clk            (clk),
        .resetb         (rst_n),
        .address        (rb_address),
        .data_write_in  (rb_data_write_to_reg),
        .data_read_out  (rb_data_read_from_reg),
        .reg_en         (rb_reg_en),
        .write_en       (rb_write_en),
        .time_cfg       (time_cfg),
        .ltc_cfg        (ltc_cfg)
    );

    ltc ltc (
        .clk            (clk), 
        .reset_n        (rst_n),
        // inputs
        .framerate      (framerate),
        .bgf            (bgf),
        .dropframe      (dropframe),
        .colorframe     (colorframe),
        .userbits       (userbits),
        // outputs
        .timecode       (timecode)
    );

    // Bidirectional input / output 

    // I2C to circuit - client and input is only input (No strech mode imp.)
    assign i2c_scl    = uio_in[0];
    assign uio_oe[0]  = 1'b0;
    assign uio_out[0] = 1'b0; 

    assign i2c_sdai   = uio_in[1];
    assign uio_oe[1]  = (i2c_sdao == 1'b0) ? 1'b1 : 1'b0;
    assign uio_out[1] = i2c_sdao; 

    // LTC Timecode out
    assign uio_oe[7]  = 1'b1;
    assign uio_out[7] = timecode;

    // misc config register
    assign use_reg_conf = ltc_cfg[7];
    assign framerate = (use_reg_conf == 1'b1) ? ltc_cfg[6:5] : ui_in[3:2];
    assign dropframe = ltc_cfg[4];
    assign colorframe = ltc_cfg[3];
    assign bgf = ltc_cfg[2:0];

    // userbits
    assign userbits = ltc_cfg[39:8];

    // debug out
    // show decimal point lit, if using register config for framerate
    assign uo_out[7] = use_reg_conf;
    // try to indicate framerate: 4 = 24fps, 5 = 25fps, 3 = 30fps
    assign uo_out[6:0] = (framerate == 2'b00) ? 'b1100110
                       : (framerate == 2'b01) ? 'b1101101
                       : (framerate == 2'b11) ? 'b1001111
                       : 'b0000000;

    // List all unused inputs to prevent warnings
    wire _unused = &{ena, uio_in[7]};

    // just simple logic to use IO and have something very simple
    //assign uo_out[0] = ui_in[7] & ui_in[6] & ui_in[5] & ui_in[4] & ui_in[1] & ui_in[0];
    //assign uo_out[7:1] = uio_in[6:0];
    //assign uio_out[6:0] = 7'b0;



endmodule
