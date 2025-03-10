/*
 * Copyright (c) 2025 Thomas Flummer
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module ltc (
    input wire clk, 
    input wire reset_n,
    input wire [1:0] framerate,
    input wire inc_hrs,
    input wire inc_min,
    input wire inc_sec,
    output reg timecode
	);

	wire reset = !reset_n;

    reg [3:0] frm_u;
    reg [1:0] frm_d;
	reg [3:0] sec_u;
    reg [2:0] sec_d;
    reg [3:0] min_u;
    reg [2:0] min_d;
    reg [3:0] hrs_u;
    reg [1:0] hrs_d;
    reg [23:0] frm_counter;
    reg [15:0] btn_counter;
    reg [11:0] bit_counter;

    reg [79:0] output_buffer;

	always @(posedge sys_clk) begin
        if(reset) begin
            frm_u <= 0;
            frm_d <= 0;
            sec_u <= 0;
            sec_d <= 0;
            min_u <= 0;
            min_d <= 0;
            hrs_u <= 0;
            hrs_d <= 0;
            frm_counter <= 0;
            btn_counter <= 0;
            bit_counter <= 0;
            bit_clk <= 1'b0;
            but_clk_en <= 1'b0;
            output_buffer <= 0;
            timecode <= 0;
        end else begin
            if(frm_u == 10) begin
                frm_u <= 0;
                frm_d <= frm_d + 1;
            end
            if((framerate == 2'b00 && frm_d == 2 && frm_u == 4) || (framerate == 2'b01 && frm_d == 2 && frm_u == 5) || (framerate == 2'b11 && frm_d == 3 && frm_u == 0)) begin
                frm_u <= 0;
                frm_d <= 0;
                sec_u <= sec_u + 1;
            end
            if(sec_u == 10) begin
                sec_u <= 0;
                sec_d <= sec_d + 1;
            end
            if(sec_d == 6) begin
                sec_d <= 0;
                min_u <= min_u + 1;
            end
            if(min_u == 10) begin
                min_u <= 0;
                min_d <= min_d + 1;
            end
            if(min_d == 6) begin
                min_d <= 0;
                hrs_u <= hrs_u + 1;
            end
            if(hrs_u == 10) begin
                hrs_u <= 0;
                hrs_d <= hrs_d + 1;
            end
            if(hrs_d == 2 && hrs_u == 4) begin
                hrs_u <= 0;
                hrs_d <= 0;
            end

            // frame counter
            // 12MHz: 25 fps: 480000, 24 fps: 500000, 30 fps: 400000
            frm_counter <= frm_counter + 1;
            if((framerate == 2'b00 && frm_counter + 1 == 500_000) || (framerate == 2'b01 && frm_counter + 1 == 480_000) || (framerate == 2'b11 && frm_counter + 1 == 400_000)) begin
                frm_u <= frm_u + 1;
                frm_counter <= 0;

                output_buffer[79] <= frm_u[0];
                output_buffer[78] <= frm_u[1];
                output_buffer[77] <= frm_u[2];
                output_buffer[76] <= frm_u[3];
                output_buffer[75:72] <= 4'b0; // user bits field 1
                output_buffer[71] <= frm_d[0];
                output_buffer[70] <= frm_d[1];
                output_buffer[69] <= 1'b0; // drop frame flag, 1 = dropframe, 0 = non drop frame
                output_buffer[68] <= 1'b0; // color frame flag
                output_buffer[67:64] <= 4'b0; // user bits field 2
                output_buffer[63] <= sec_u[0];
                output_buffer[62] <= sec_u[1];
                output_buffer[61] <= sec_u[2];
                output_buffer[60] <= sec_u[3];
                output_buffer[59:56] <= 4'b0; // user bits field 3
                output_buffer[55] <= sec_d[0];
                output_buffer[54] <= sec_d[1];
                output_buffer[53] <= sec_d[2];
                output_buffer[52] <= 1'b0; // flag (bit 27)
                output_buffer[51:48] <= 4'b0; // user bits field 4
                output_buffer[47] <= min_u[0];
                output_buffer[46] <= min_u[1];
                output_buffer[45] <= min_u[2];
                output_buffer[44] <= min_u[3];
                output_buffer[43:40] <= 4'b0; // user bits field 5
                output_buffer[39] <= min_d[0];
                output_buffer[38] <= min_d[1];
                output_buffer[37] <= min_d[2];
                output_buffer[36] <= 1'b0; // flag (bit 43)
                output_buffer[35:32] <= 4'b0; // user bits field 6
                output_buffer[31] <= hrs_u[0];
                output_buffer[30] <= hrs_u[1];
                output_buffer[29] <= hrs_u[2];
                output_buffer[28] <= hrs_u[3];
                output_buffer[27:24] <= 4'b0; // user bits field 7
                output_buffer[23] <= hrs_d[0];
                output_buffer[22] <= hrs_d[1];
                output_buffer[21] <= 1'b0; // clock flag
                output_buffer[20] <= 1'b0; // flag (bit 59)
                output_buffer[19:16]  <= 4'b0; // user bits field 8
                output_buffer[15:0] <= 16'b0011111111111101; // sync word, fixed pattern

                if(framerate == 2'b00 || framerate == 2'b11) begin // 24 or 30 fps
                    output_buffer[52] = ~^output_buffer[79:16];
                end
                if(framerate == 2'b01) begin // 25 fps
                    output_buffer[20] = ~^output_buffer[79:16];
                end
            end

            // 80 bits per frame
            bit_counter <= bit_counter + 1;
            if((framerate == 2'b00 && bit_counter + 1 == 3_125) || (framerate == 2'b01 && bit_counter + 1 == 3_000) || (framerate == 2'b11 && bit_counter + 1 == 2_500)) begin
                bit_clk <= ~bit_clk;
            end

            // button pulse enable counter
            // 12MHz: 100 Hz/10ms: 60000 for a half period
            btn_counter <= btn_counter + 1;
            if(btn_counter + 1 == 60_000) begin
                but_clk_en <= ~but_clk_en;
                btn_counter <= 0;
            end

            // increment buttons
            if(inc_sec_pulse)
                sec_u <= sec_u + 1;
            if(inc_min_pulse)
                min_u <= min_u + 1;
            if(inc_hrs_pulse)
                hrs_u <= hrs_u + 1;
        end
    end

    // every bit needs a transition on the output
	always @(posedge bit_clk) begin
        timecode <= ~timecode;
    end

    // only bits that are set needs an extra transition
	always @(negedge bit_clk) begin
        if(output_buffer[79] == 1'b1)
            timecode <= ~timecode;
        output_buffer <= (output_buffer<<1);
    end

    // button handling
	wire inc_sec_pulse, inc_min_pulse, inc_hrs_pulse;

    // want button_clk_en to be about 10ms
    reg but_clk_en;

    localparam MAX_BUT_RATE = 16;
    localparam DEC_COUNT = 1;
    localparam MIN_COUNT = 2;

    button_pulse #(.MIN_COUNT(MIN_COUNT), .DEC_COUNT(DEC_COUNT), .MAX_COUNT(MAX_BUT_RATE)) 
        pulse_sec (.clk(sys_clk), .clk_en(but_clk_en), .button(inc_sec), .pulse(inc_sec_pulse), .reset(reset));
    button_pulse #(.MIN_COUNT(MIN_COUNT), .DEC_COUNT(DEC_COUNT), .MAX_COUNT(MAX_BUT_RATE)) 
        pulse_min (.clk(sys_clk), .clk_en(but_clk_en), .button(inc_min), .pulse(inc_min_pulse), .reset(reset));
    button_pulse #(.MIN_COUNT(MIN_COUNT), .DEC_COUNT(DEC_COUNT), .MAX_COUNT(MAX_BUT_RATE)) 
        pulse_hrs (.clk(sys_clk), .clk_en(but_clk_en), .button(inc_hrs), .pulse(inc_hrs_pulse), .reset(reset));

	wire sys_clk;
    assign sys_clk = clk;

	reg bit_clk;

endmodule

`default_nettype wire