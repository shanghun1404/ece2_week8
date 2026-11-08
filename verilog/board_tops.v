module lab8_a_basic(
    input wire clk, btn_reset,
    output wire LCD_E, LCD_RS, LCD_RW,
    output wire [7:0] LCD_DATA, LED_out
);
    // SM9 is active high. Assert nrst asynchronously, release on clk.
    (* ASYNC_REG = "TRUE" *) reg [1:0] reset_release = 0;
    always @(posedge clk or posedge btn_reset)
        if (btn_reset) reset_release <= 0;
        else reset_release <= {reset_release[0], 1'b1};
    wire nrst = reset_release[1];
    text_lcd U0(
        .clk(clk), .nrst(nrst), .LCD_E(LCD_E), .LCD_RS(LCD_RS),
        .LCD_RW(LCD_RW), .LCD_DATA(LCD_DATA), .LED_out(LED_out));
endmodule

module lab8_b_slow(
    input wire clk, btn_reset,
    output wire LCD_E, LCD_RS, LCD_RW,
    output wire [7:0] LCD_DATA, LED_out
);
    // SM9 is active high. Assert nrst asynchronously, release on clk.
    (* ASYNC_REG = "TRUE" *) reg [1:0] reset_release = 0;
    always @(posedge clk or posedge btn_reset)
        if (btn_reset) reset_release <= 0;
        else reset_release <= {reset_release[0], 1'b1};
    wire nrst = reset_release[1];
    text_lcd #(.EXTERNAL_CLOCK(1), .HOLD_TICKS(5)) U0(
        .clk(clk), .nrst(nrst), .LCD_E(LCD_E), .LCD_RS(LCD_RS),
        .LCD_RW(LCD_RW), .LCD_DATA(LCD_DATA), .LED_out(LED_out));
endmodule

module lab8_c_single(
    input wire clk, btn_reset,
    output wire LCD_E, LCD_RS, LCD_RW,
    output wire [7:0] LCD_DATA, LED_out
);
    // SM9 is active high. Assert nrst asynchronously, release on clk.
    (* ASYNC_REG = "TRUE" *) reg [1:0] reset_release = 0;
    always @(posedge clk or posedge btn_reset)
        if (btn_reset) reset_release <= 0;
        else reset_release <= {reset_release[0], 1'b1};
    wire nrst = reset_release[1];
    text_lcd #(.ONE_LINE(1)) U0(
        .clk(clk), .nrst(nrst), .LCD_E(LCD_E), .LCD_RS(LCD_RS),
        .LCD_RW(LCD_RW), .LCD_DATA(LCD_DATA), .LED_out(LED_out));
endmodule

module lab8_d_offset(
    input wire clk, btn_reset,
    output wire LCD_E, LCD_RS, LCD_RW,
    output wire [7:0] LCD_DATA, LED_out
);
    // SM9 is active high. Assert nrst asynchronously, release on clk.
    (* ASYNC_REG = "TRUE" *) reg [1:0] reset_release = 0;
    always @(posedge clk or posedge btn_reset)
        if (btn_reset) reset_release <= 0;
        else reset_release <= {reset_release[0], 1'b1};
    wire nrst = reset_release[1];
    text_lcd #(.START_COLUMN(3)) U0(
        .clk(clk), .nrst(nrst), .LCD_E(LCD_E), .LCD_RS(LCD_RS),
        .LCD_RW(LCD_RW), .LCD_DATA(LCD_DATA), .LED_out(LED_out));
endmodule

module lab8_e_scroll(
    input wire clk, btn_reset,
    output wire LCD_E, LCD_RS, LCD_RW,
    output wire [7:0] LCD_DATA, LED_out
);
    // SM9 is active high. Assert nrst asynchronously, release on clk.
    (* ASYNC_REG = "TRUE" *) reg [1:0] reset_release = 0;
    always @(posedge clk or posedge btn_reset)
        if (btn_reset) reset_release <= 0;
        else reset_release <= {reset_release[0], 1'b1};
    wire nrst = reset_release[1];
    text_lcd #(.SCROLL(1), .HOLD_TICKS(300)) U0(
        .clk(clk), .nrst(nrst), .LCD_E(LCD_E), .LCD_RS(LCD_RS),
        .LCD_RW(LCD_RW), .LCD_DATA(LCD_DATA), .LED_out(LED_out));
endmodule
