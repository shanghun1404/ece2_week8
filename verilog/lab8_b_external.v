module lab8_b_external(
    input wire clk, btn_reset,
    output wire LCD_E, LCD_RS, LCD_RW,
    output wire [7:0] LCD_DATA, LED_out
);
    (* ASYNC_REG = "TRUE" *) reg [1:0] reset_release = 0;
    always @(posedge clk or posedge btn_reset)
        if (btn_reset) reset_release <= 0;
        else reset_release <= {reset_release[0], 1'b1};
    wire nrst = reset_release[1];
    text_lcd_external U0(clk,nrst,LCD_E,LCD_RS,LCD_RW,LCD_DATA,LED_out);
endmodule

module text_lcd_external(
    input wire clk, nrst,
    output wire LCD_E,
    output reg LCD_RS = 0,
    output wire LCD_RW,
    output reg [7:0] LCD_DATA = 0,
    output reg [7:0] LED_out
);
    localparam [3:0] DELAY=0, FUNCTION_SET=1, ENTRY_MODE=2,
        DISP_ONOFF=3, LINE1=4, LINE2=5, DELAY_T=6, CLEAR_DISP=7;
    localparam [127:0] ROW1 = "HELLO WORLD!    ";
    localparam [127:0] ROW2 = "2025440099 LSH  ";
    reg [3:0] state = DELAY;
    reg [6:0] cnt = 0;
    reg [6:0] last_count;
    reg valid, command_rs;
    reg [7:0] command_data;
    reg enable_latched = 0;
    assign LCD_RW = 0;
    assign LCD_E = clk && enable_latched && nrst;
    always @* begin
        last_count = 4;
        case (state)
            DELAY: last_count = 69;
            LINE1,LINE2: last_count = 16;
            default: last_count = 4;
        endcase
        case (state)
            DELAY: LED_out=8'h80;
            FUNCTION_SET: LED_out=8'h40;
            DISP_ONOFF: LED_out=8'h20;
            ENTRY_MODE: LED_out=8'h10;
            LINE1: LED_out=8'h08;
            LINE2: LED_out=8'h04;
            DELAY_T: LED_out=8'h02;
            default: LED_out=8'h01;
        endcase
        valid=0; command_rs=0; command_data=0;
        case (state)
            FUNCTION_SET: begin valid=(cnt==0); command_data=8'h38; end
            DISP_ONOFF: begin valid=(cnt==0); command_data=8'h0c; end
            ENTRY_MODE: begin
                valid=(cnt==0 || cnt==2);
                command_data=(cnt==0) ? 8'h06 : 8'h01;
            end
            LINE1: begin
                valid=1; command_rs=(cnt!=0);
                command_data=(cnt==0) ? 8'h80 : ROW1[127-(cnt-1)*8 -: 8];
            end
            LINE2: begin
                valid=1; command_rs=(cnt!=0);
                command_data=(cnt==0) ? 8'hc0 : ROW2[127-(cnt-1)*8 -: 8];
            end
            CLEAR_DISP: begin valid=(cnt==0); command_data=8'h01; end
            default: valid=0;
        endcase
        if (!nrst) begin valid=0; LED_out=8'h80; end
    end
    // Prepare RS/data while E is low, half a clock before its rising edge.
    // XDC also enforces 10 ns output hold after the forwarded E falls.
    always @(negedge clk or negedge nrst) begin
        if (!nrst) begin enable_latched<=0; LCD_RS<=0; LCD_DATA<=0; end
        else begin
            enable_latched<=valid;
            if (valid) begin LCD_RS<=command_rs; LCD_DATA<=command_data; end
        end
    end
    always @(posedge clk or negedge nrst) begin
        if (!nrst) begin state<=DELAY; cnt<=0; end
        else if (cnt==last_count) begin
            cnt<=0;
            case (state)
                DELAY: state<=FUNCTION_SET;
                FUNCTION_SET: state<=DISP_ONOFF;
                DISP_ONOFF: state<=ENTRY_MODE;
                ENTRY_MODE: state<=LINE1;
                LINE1: state<=LINE2;
                LINE2: state<=DELAY_T;
                DELAY_T: state<=CLEAR_DISP;
                default: state<=LINE1;
            endcase
        end else cnt<=cnt+1'b1;
    end
endmodule
