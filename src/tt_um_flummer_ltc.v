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

    wire settime_no;
    wire settime;
    wire [31:0] set_time;
    wire [31:0] cur_time;
    wire [39:0] ltc_cfg;

    wire [7:0] rb_address;
    wire [7:0] rb_data_write_to_reg;
    wire [7:0] rb_data_read_from_reg;
    wire rb_reg_en;
    wire rb_write_en;
    wire [1:0] streamSt_mon;

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
        .streamSt_mon   (streamSt_mon)
    );

    rb_ltc rb_ltc_inst(
        .clk            (clk),
        .resetb         (rst_n),
        .address        (rb_address),
        .data_write_in  (rb_data_write_to_reg),
        .data_read_out  (rb_data_read_from_reg),
        .reg_en         (rb_reg_en),
        .write_en       (rb_write_en),
        .updatetime     (settime),
	    .set_time_cfg   (set_time),
    	.cur_time_cfg   (cur_time),
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
        .updatetime     (settime),
        .timetoset      (set_time),
        // outputs
        .currenttime    (cur_time),
        .timecode       (timecode)
    );

    // temp
    assign settime_no = 1'b0;

    // Bidirectional input / output 

    // I2C to circuit - client and input is only input (No strech mode imp.)
    assign i2c_sdai   = uio_in[0];
    assign uio_oe[0]  = (i2c_sdao == 1'b0) ? 1'b1 : 1'b0;
    assign uio_out[0] = i2c_sdao; 

    assign i2c_scl    = uio_in[1];
    assign uio_oe[1]  = 1'b0;
    assign uio_out[1] = 1'b0; 

    // LTC Timecode out
    assign uio_oe[7]  = 1'b1;
    assign uio_out[7] = timecode;

    // misc config register
    assign use_reg_conf = ltc_cfg[7];
    assign framerate = (use_reg_conf == 1'b1) ? ltc_cfg[6:5] : ui_in[3:2];
    assign dropframe = (use_reg_conf == 1'b1) ? ltc_cfg[4] : ui_in[4];
    assign colorframe = (use_reg_conf == 1'b1) ? ltc_cfg[3] : ui_in[5];
    assign bgf[0] = (use_reg_conf == 1'b1) ? ltc_cfg[0] : ui_in[6];
    assign bgf[1] = (use_reg_conf == 1'b1) ? ltc_cfg[1] : ui_in[7];
    assign bgf[2] = (use_reg_conf == 1'b1) ? ltc_cfg[2] : 1'b0;

    // userbits
    assign userbits = ltc_cfg[39:8];
    assign uio_oe[5:4] = 2'b11;

    // debug out
    // show decimal point lit, if using register config for framerate
    assign uo_out[7] = use_reg_conf;
    // try to indicate framerate: 4 = 24fps, 5 = 25fps, 3 = 30fps
    assign uo_out[6:0] = (framerate == 2'b00) ? 'b1100110
                       : (framerate == 2'b01) ? 'b1101101
                       : (framerate == 2'b10) ? 'b1100111
                       : (framerate == 2'b11) ? 'b1001111
                       : 'b0000000;

    assign uio_out[4] = settime;
    assign uio_out[5] = streamSt_mon[1];

    // list all unused inputs to prevent warnings
    wire _unused = &{ena, ui_in[1:0], uio_in[7:2]};

    // set unused io pins to inputs
    assign uio_oe[3:2] = 2'b0;
    assign uio_oe[6] = 1'b0;
    assign uio_out[3:2] = 2'b0;
    assign uio_out[6] = 1'b0;

endmodule
