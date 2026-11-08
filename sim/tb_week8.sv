`timescale 1us/1ns
module lcd_checker #(
    parameter integer MODE = 0,
    parameter integer COLUMN = 0,
    parameter integer ONE_LINE = 0,
    parameter integer SCROLL_ROWS = 0
)(input wire clk, input wire nrst, input wire LCD_E,
  input wire LCD_RS, input wire LCD_RW, input wire [7:0] LCD_DATA,
  output integer frames = 0, output integer shifts = 0);
    localparam [127:0] ROW1 = "HELLO WORLD!    ";
    localparam [127:0] ROW2 = "2025440099 LSH  ";
    localparam [159:0] MARQUEE1 = "HELLO WORLD!        ";
    localparam [159:0] MARQUEE2 = "2025440099 LSH      ";
    localparam integer ROW_LENGTH = SCROLL_ROWS ? 40 : 16;
    integer transaction = 0;
    integer row_count = 0;
    integer column_count = 0;
    integer clears = 0;
    reg [7:0] expected;
    reg [7:0] observed_rows [0:79];
    integer window_pos, model_offset;
    reg visible1, visible2;
    realtime high_start, last_write, rs_change, data_change;
    realtime reset_start = 0;
    reg had_write = 0;
    always @(LCD_RS) rs_change = $realtime;
    always @(LCD_DATA) data_change = $realtime;
    always @(negedge nrst) begin
        reset_start = $realtime;
        transaction = 0; row_count = 0; column_count = 0;
        frames = 0; shifts = 0; clears = 0; had_write = 0;
    end
    always @(posedge LCD_E) begin
        high_start = $realtime;
        #0.001;
        if (nrst && ($realtime-rs_change < 0.040 || $realtime-data_change < 0.080))
            $fatal(1,"FAIL: RS/data setup before E rising edge");
    end
    always @(negedge LCD_E) if (nrst) begin
        if (LCD_RW !== 0) $fatal(1,"FAIL: write mode");
        if ($realtime-high_start < 400) $fatal(1,"FAIL: E pulse too short");
        if ($realtime-data_change < 400 || $realtime-rs_change < 400)
            $fatal(1,"FAIL: data/RS stability before E falling edge");
        if (had_write && $realtime-last_write < 900)
            $fatal(1,"FAIL: instruction spacing");
        had_write = 1; last_write = $realtime;
        case (transaction)
            0: begin
                if ($realtime-reset_start < 70000) $fatal(1,"FAIL: startup wait");
                expected = ONE_LINE ? 8'h30 : 8'h38;
            end
            1: expected = 8'h0c;
            2: expected = 8'h06;
            3: expected = 8'h01;
            default: expected = 8'h00;
        endcase
        if (transaction < 4) begin
            if (LCD_RS !== 0 || LCD_DATA !== expected)
                $fatal(1,"FAIL: setup command %0d got %h expected %h",transaction,LCD_DATA,expected);
            $display("SETUP mode=%0d t=%0t cmd=%h",MODE,$time,LCD_DATA);
        end else if (LCD_RS == 0) begin
            if (LCD_DATA == 8'h80+COLUMN) begin
                if (row_count != 0 && column_count != ROW_LENGTH) $fatal(1,"FAIL: incomplete previous row");
                row_count = 1; column_count = 0;
            end else if (LCD_DATA == 8'hc0+COLUMN) begin
                if (row_count != 1 || column_count != ROW_LENGTH) $fatal(1,"FAIL: first row length");
                row_count = 2; column_count = 0;
            end else if (LCD_DATA == 8'h01) begin
                if (MODE == 4) $fatal(1,"FAIL: clear during scrolling");
                if (row_count != 2 || column_count != ROW_LENGTH) $fatal(1,"FAIL: clear before completed rows");
                clears = clears+1;
            end else if (LCD_DATA == 8'h18) begin
                if (MODE != 4 || row_count != 2 || column_count != ROW_LENGTH)
                    $fatal(1,"FAIL: unexpected display shift");
                shifts = shifts+1;
                if (SCROLL_ROWS) begin
                    visible1 = 0; visible2 = 0;
                    for (window_pos=0; window_pos<16; window_pos=window_pos+1) begin
                        model_offset = (shifts+window_pos)%40;
                        if (observed_rows[model_offset] != 8'h20) visible1 = 1;
                        if (observed_rows[40+model_offset] != 8'h20) visible2 = 1;
                    end
                    if (!visible1 || !visible2) $fatal(1,"FAIL: entire marquee row becomes blank");
                end
            end else $fatal(1,"FAIL: unexpected command %h",LCD_DATA);
        end else begin
            if (row_count == 0 || column_count >= ROW_LENGTH) $fatal(1,"FAIL: unexpected character");
            if (SCROLL_ROWS)
                expected = row_count == 1 ? MARQUEE1[159-(column_count%20)*8 -: 8] : MARQUEE2[159-(column_count%20)*8 -: 8];
            else expected = row_count == 1 ? ROW1[127-column_count*8 -: 8] : ROW2[127-column_count*8 -: 8];
            if (LCD_DATA !== expected)
                $fatal(1,"FAIL: row%0d col%0d got %h expected %h",row_count,column_count,LCD_DATA,expected);
            if (SCROLL_ROWS) observed_rows[(row_count-1)*40+column_count] = LCD_DATA;
            column_count = column_count+1;
            if (row_count == 2 && column_count == ROW_LENGTH) begin
                frames = frames+1;
                $display("FRAME_PASS mode=%0d t=%0t",MODE,$time);
            end
        end
        transaction = transaction+1;
    end
endmodule

module tb_week8;
    reg clk = 0;
    reg nrst = 0;
    always #0.5 clk = ~clk;
    wire [3:0] e,rs,rw;
    wire [7:0] d[0:3];
    wire [7:0] leds[0:3];
    wire [31:0] frames[0:3], shifts[0:3];
    text_lcd basic(.clk(clk),.nrst(nrst),.LCD_E(e[0]),.LCD_RS(rs[0]),.LCD_RW(rw[0]),.LCD_DATA(d[0]),.LED_out(leds[0]));
    text_lcd #(.ONE_LINE(1)) single_line(.clk(clk),.nrst(nrst),.LCD_E(e[1]),.LCD_RS(rs[1]),.LCD_RW(rw[1]),.LCD_DATA(d[1]),.LED_out(leds[1]));
    text_lcd #(.START_COLUMN(3)) offset_line(.clk(clk),.nrst(nrst),.LCD_E(e[2]),.LCD_RS(rs[2]),.LCD_RW(rw[2]),.LCD_DATA(d[2]),.LED_out(leds[2]));
    text_lcd #(.SCROLL(1),.HOLD_TICKS(20)) scroll(.clk(clk),.nrst(nrst),.LCD_E(e[3]),.LCD_RS(rs[3]),.LCD_RW(rw[3]),.LCD_DATA(d[3]),.LED_out(leds[3]));
    lcd_checker #(.MODE(0)) c0(clk,nrst,e[0],rs[0],rw[0],d[0],frames[0],shifts[0]);
    lcd_checker #(.MODE(1),.ONE_LINE(1)) c1(clk,nrst,e[1],rs[1],rw[1],d[1],frames[1],shifts[1]);
    lcd_checker #(.MODE(2),.COLUMN(3)) c2(clk,nrst,e[2],rs[2],rw[2],d[2],frames[2],shifts[2]);
    lcd_checker #(.MODE(4)) c3(clk,nrst,e[3],rs[3],rw[3],d[3],frames[3],shifts[3]);
    integer state_mask = 0;
    reg fast_done = 0;
    always @(posedge clk) if (nrst) state_mask = state_mask | (1 << basic.state);
    initial begin
        #10; nrst = 1;
        #1250000;
        if (frames[0] < 2 || frames[1] < 2 || frames[2] < 2)
            $fatal(1,"FAIL: frame repetition");
        if ((state_mask & 255) != 255) $fatal(1,"FAIL: state coverage");
        if (shifts[3] < 40 || frames[3] != 1) $fatal(1,"FAIL: continuous scroll");
        $display("FAST_PASS states=%h frames=%0d shifts=%0d",state_mask,frames[0],shifts[3]);
        fast_done = 1;
    end
    initial begin
        #1300000;
        if (!fast_done) $fatal(1,"FAIL: incomplete fast tests");
        // Verify asynchronous reset can immediately lower an active E pulse.
        nrst = 0; #10; nrst = 1;
        @(posedge e[0]); #50; nrst = 0; #0.1;
        if (e !== 0 || basic.state !== 0 || basic.cnt !== 0)
            $fatal(1,"FAIL: asynchronous reset");
        #10; nrst = 1;
        #120000;
        if (frames[0] != 1) $fatal(1,"FAIL: restart after reset");
        $display("WEEK8_PASS setup text states one-line offset continuous-scroll reset");
        $finish;
    end
    initial begin #2000000; $fatal(1,"FAIL: timeout"); end
endmodule
