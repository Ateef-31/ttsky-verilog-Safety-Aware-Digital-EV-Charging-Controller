`default_nettype none
 
module tt_um_EV_Charging_CTRL(
  input  wire [7:0] ui_in,    // Dedicated inputs
  output wire [7:0] uo_out,   // Dedicated outputs
  input  wire [7:0] uio_in,   // IOs: Input path
  output wire [7:0] uio_out,  // IOs: Output path
  output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
  input  wire       ena,      // always 1 when the design is powered, so you can ignore it
  input  wire       clk,      // clock
  input  wire       rst_n     // reset_n - low to reset
);
 
  // EV Charging Controller Signals
  // wire plug_detect,battery_full,auth,precharge_ready,over_voltage,over_current,over_temperature,emergency_stop;
  wire [2:0] state;
  wire [7:0] stable_input;
 
  // VGA signals
  wire hsync;
  wire vsync;
  reg [1:0] R;
  reg [1:0] G;
  reg [1:0] B;
  wire video_active;
  wire [9:0] pix_x;
  wire [9:0] pix_y;

  localparam IDLE      = 3'd0;
  localparam AUTH      = 3'd2;
  localparam PRECHARGE = 3'd3;
  localparam CHARGING  = 3'd4;
  localparam CONNECTED = 3'd1;
  localparam COMPLETE  = 3'd5;
  localparam FAULT     = 3'd6;
 
  // TinyVGA PMOD
  assign uo_out = {hsync, B[0], G[0], R[0], vsync, B[1], G[1], R[1]};
 
  // Unused outputs assigned to 0.
  assign uio_out = 0;
  assign uio_oe  = 0;
 
  // Suppress unused signals warning
  wire _unused_ok = &{ena, uio_in};

  function [7:0] status_char;
        input [2:0] status;
        input [3:0] idx;
        begin
            status_char = " ";
            case (status)

                IDLE: begin
                    case (idx)
                        0: status_char = "I";
                        1: status_char = "D";
                        2: status_char = "L";
                        3: status_char = "E";
                        default: status_char = " ";
                    endcase
                end

                AUTH: begin
                    case (idx)
                        0: status_char = "A";
                        1: status_char = "U";
                        2: status_char = "T";
                        3: status_char = "H";
                        default: status_char = " ";
                    endcase
                end

                PRECHARGE: begin
                    case (idx)
                        0: status_char = "P";
                        1: status_char = "R";
                        2: status_char = "E";
                        3: status_char = "C";
                        4: status_char = "H";
                        5: status_char = "A";
                        6: status_char = "R";
                        7: status_char = "G";
                        8: status_char = "E";
                        default: status_char = " ";
                    endcase
                end

                CHARGING: begin
                    case (idx)
                        0: status_char = "C";
                        1: status_char = "H";
                        2: status_char = "A";
                        3: status_char = "R";
                        4: status_char = "G";
                        5: status_char = "I";
                        6: status_char = "N";
                        7: status_char = "G";
                        default: status_char = " ";
                    endcase
                end

                CONNECTED: begin
                    case (idx)
                        0: status_char = "C";
                        1: status_char = "O";
                        2: status_char = "N";
                        3: status_char = "N";
                        4: status_char = "E";
                        5: status_char = "C";
                        6: status_char = "T";
                        7: status_char = "E";
                        8: status_char = "D";
                        default: status_char = " ";
                    endcase
                end

                COMPLETE: begin
                    case (idx)
                        0: status_char = "C";
                        1: status_char = "O";
                        2: status_char = "M";
                        3: status_char = "P";
                        4: status_char = "L";
                        5: status_char = "E";
                        6: status_char = "T";
                        7: status_char = "E";
                        default: status_char = " ";
                    endcase
                end

                FAULT: begin
                    case (idx)
                        0: status_char = "F";
                        1: status_char = "A";
                        2: status_char = "U";
                        3: status_char = "L";
                        4: status_char = "T";
                        default: status_char = " ";
                    endcase
                end

                default: status_char = " ";

            endcase
        end
    endfunction

    // 5 x 7 FONT ROM
    function [4:0] font_row;
        input [7:0] ch;
        input [2:0] row;
        begin
            font_row = 5'b00000;

            case (ch)

                "A": case (row)
                    0: font_row = 5'b01110;
                    1: font_row = 5'b10001;
                    2: font_row = 5'b10001;
                    3: font_row = 5'b11111;
                    4: font_row = 5'b10001;
                    5: font_row = 5'b10001;
                    6: font_row = 5'b10001;
                    default: font_row = 5'b00000;
                endcase

                "C": case (row)
                    0: font_row = 5'b01110;
                    1: font_row = 5'b10001;
                    2: font_row = 5'b10000;
                    3: font_row = 5'b10000;
                    4: font_row = 5'b10000;
                    5: font_row = 5'b10001;
                    6: font_row = 5'b01110;
                    default: font_row = 5'b00000;
                endcase

                "D": case (row)
                    0: font_row = 5'b11110;
                    1: font_row = 5'b10001;
                    2: font_row = 5'b10001;
                    3: font_row = 5'b10001;
                    4: font_row = 5'b10001;
                    5: font_row = 5'b10001;
                    6: font_row = 5'b11110;
                    default: font_row = 5'b00000;
                endcase

                "E": case (row)
                    0: font_row = 5'b11111;
                    1: font_row = 5'b10000;
                    2: font_row = 5'b10000;
                    3: font_row = 5'b11110;
                    4: font_row = 5'b10000;
                    5: font_row = 5'b10000;
                    6: font_row = 5'b11111;
                    default: font_row = 5'b00000;
                endcase

                "F": case (row)
                    0: font_row = 5'b11111;
                    1: font_row = 5'b10000;
                    2: font_row = 5'b10000;
                    3: font_row = 5'b11110;
                    4: font_row = 5'b10000;
                    5: font_row = 5'b10000;
                    6: font_row = 5'b10000;
                    default: font_row = 5'b00000;
                endcase

                "G": case (row)
                    0: font_row = 5'b01110;
                    1: font_row = 5'b10001;
                    2: font_row = 5'b10000;
                    3: font_row = 5'b10111;
                    4: font_row = 5'b10001;
                    5: font_row = 5'b10001;
                    6: font_row = 5'b01110;
                    default: font_row = 5'b00000;
                endcase

                "H": case (row)
                    0: font_row = 5'b10001;
                    1: font_row = 5'b10001;
                    2: font_row = 5'b10001;
                    3: font_row = 5'b11111;
                    4: font_row = 5'b10001;
                    5: font_row = 5'b10001;
                    6: font_row = 5'b10001;
                    default: font_row = 5'b00000;
                endcase

                "I": case (row)
                    0: font_row = 5'b11111;
                    1: font_row = 5'b00100;
                    2: font_row = 5'b00100;
                    3: font_row = 5'b00100;
                    4: font_row = 5'b00100;
                    5: font_row = 5'b00100;
                    6: font_row = 5'b11111;
                    default: font_row = 5'b00000;
                endcase

                "L": case (row)
                    0: font_row = 5'b10000;
                    1: font_row = 5'b10000;
                    2: font_row = 5'b10000;
                    3: font_row = 5'b10000;
                    4: font_row = 5'b10000;
                    5: font_row = 5'b10000;
                    6: font_row = 5'b11111;
                    default: font_row = 5'b00000;
                endcase

                "M": case (row)
                    0: font_row = 5'b10001;
                    1: font_row = 5'b11011;
                    2: font_row = 5'b10101;
                    3: font_row = 5'b10101;
                    4: font_row = 5'b10001;
                    5: font_row = 5'b10001;
                    6: font_row = 5'b10001;
                    default: font_row = 5'b00000;
                endcase

                "N": case (row)
                    0: font_row = 5'b10001;
                    1: font_row = 5'b11001;
                    2: font_row = 5'b10101;
                    3: font_row = 5'b10101;
                    4: font_row = 5'b10101;
                    5: font_row = 5'b10011;
                    6: font_row = 5'b10001;
                    default: font_row = 5'b00000;
                endcase

                "O": case (row)
                    0: font_row = 5'b01110;
                    1: font_row = 5'b10001;
                    2: font_row = 5'b10001;
                    3: font_row = 5'b10001;
                    4: font_row = 5'b10001;
                    5: font_row = 5'b10001;
                    6: font_row = 5'b01110;
                    default: font_row = 5'b00000;
                endcase

                "P": case (row)
                    0: font_row = 5'b11110;
                    1: font_row = 5'b10001;
                    2: font_row = 5'b10001;
                    3: font_row = 5'b11110;
                    4: font_row = 5'b10000;
                    5: font_row = 5'b10000;
                    6: font_row = 5'b10000;
                    default: font_row = 5'b00000;
                endcase

                "R": case (row)
                    0: font_row = 5'b11110;
                    1: font_row = 5'b10001;
                    2: font_row = 5'b10001;
                    3: font_row = 5'b11110;
                    4: font_row = 5'b10100;
                    5: font_row = 5'b10010;
                    6: font_row = 5'b10001;
                    default: font_row = 5'b00000;
                endcase

                "T": case (row)
                    0: font_row = 5'b11111;
                    1: font_row = 5'b00100;
                    2: font_row = 5'b00100;
                    3: font_row = 5'b00100;
                    4: font_row = 5'b00100;
                    5: font_row = 5'b00100;
                    6: font_row = 5'b00100;
                    default: font_row = 5'b00000;
                endcase

                "U": case (row)
                    0: font_row = 5'b10001;
                    1: font_row = 5'b10001;
                    2: font_row = 5'b10001;
                    3: font_row = 5'b10001;
                    4: font_row = 5'b10001;
                    5: font_row = 5'b10001;
                    6: font_row = 5'b01110;
                    default: font_row = 5'b00000;
                endcase

                default: font_row = 5'b00000;
            endcase
        end
    endfunction

    // LARGE STATUS HEADING WITH AUTOMATIC CENTERING
    localparam [9:0] SCALE  = 10'd6;
    localparam [9:0] CHAR_W = 10'd36;
    localparam [9:0] CHAR_H = 10'd42;

    reg [3:0] status_length;

    always @* begin
        case (state)
            IDLE:      status_length = 4'd4;
            AUTH:      status_length = 4'd4;
            PRECHARGE: status_length = 4'd9;
            CHARGING:  status_length = 4'd8;
            CONNECTED: status_length = 4'd9;
            COMPLETE:  status_length = 4'd8;
            FAULT:     status_length = 4'd5;
            default:   status_length = 4'd0;
        endcase
    end

    wire [9:0] text_width;
    wire [9:0] text_x;
    wire [9:0] text_y;

    assign text_width = status_length * CHAR_W;
    assign text_x = (10'd640 - text_width) / 2;
    assign text_y = 10'd50;

    wire [9:0] rel_x;
    wire [9:0] rel_y;

    wire [3:0] char_index;
    wire [2:0] glyph_col;
    wire [2:0] glyph_row;

    wire [7:0] current_char;
    wire [4:0] current_font_row;
    wire text_pixel;
    wire text_area;

    assign text_area =
        (status_length != 0) &&
        (pix_x >= text_x) &&
        (pix_x < text_x + text_width) &&
        (pix_y >= text_y) &&
        (pix_y < text_y + CHAR_H);

    assign rel_x = pix_x - text_x;
    assign rel_y = pix_y - text_y;

    assign char_index = rel_x / CHAR_W;
    assign glyph_col  = (rel_x % CHAR_W) / SCALE;
    assign glyph_row  = rel_y / SCALE;

    assign current_char =
        status_char(state, char_index);

    assign current_font_row =
        font_row(current_char, glyph_row);

    assign text_pixel =
        video_active &&
        text_area &&
        (char_index < status_length) &&
        (glyph_col < 5) &&
        current_font_row[4-glyph_col];
 
  EV_controller dut(
  .system_clock(clk),
  .system_resetn(rst_n),
  .plug_detect(stable_input[0]),
  .auth(stable_input[1]),
  .precharge_ready(stable_input[2]),
  .emergency_stop(stable_input[3]),
  .battery_full(stable_input[4]),
  .over_voltage(stable_input[5]),
  .over_current(stable_input[6]),
  .over_temperature(stable_input[7]),
  .state(state)
  );

 two_ff_synchronizer #(
  .MAX_COUNT(517_500)
 ) two_FF (
  .clk(clk),
  .rst_n(rst_n),
  .noisy_in(ui_in),
  .clean_out(stable_input)
 );
 
  hvsync_generator hvsync_gen(
    .clk(clk),
    .reset(~rst_n),
    .hsync(hsync),
    .vsync(vsync),
    .display_on(video_active),
    .hpos(pix_x),
    .vpos(pix_y)
  );
  reg [9:0] counter;
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
      counter <= 10'd0;
      {R, G, B} <= 6'b00_00_00;
    end else begin
      if(count==1&& (state==CHARGING || state == COMPLETE || state == FAULT)) counter <= (counter <= 610) ? counter+1 : 30;
      {R, G, B} <= 6'b00_00_00;
      if(video_active) {R, G, B} <= 6'b01_01_10;
      if((pix_y >= 200 && pix_y <= 260) && pix_x >= 20 && pix_x <= 620) {R, G, B} <= 6'b00_00_00;
      if((pix_y >= 215 && pix_y <= 245) && pix_x >= 20 && pix_x <= 630) {R, G, B} <= 6'b00_00_00;
      if((pix_y >= 150 && pix_y <= 180) && pix_x >= 40 && pix_x <= 80) {R, G, B} <= (state==0)? 6'b11_11_11:6'b00_00_00;
 
      if((pix_y >= 150 && pix_y <= 180) && pix_x >= 200 && pix_x <= 240) {R, G, B} <= (state==1) ? 6'b11_11_11 : 6'b00_00_00;
 
 
      if((pix_y >= 150 && pix_y <= 180) && pix_x >= 360 && pix_x <= 400)  {R, G, B} <= (state==2) ? 6'b11_11_11 : 6'b00_00_00;
 
      if((pix_y >= 150 && pix_y <= 180) && pix_x >= 520 && pix_x <= 560)  {R, G, B} <= (state==3) ? 6'b11_11_11 : 6'b00_00_00;
      if(state==FAULT && pix_y >= 210 && pix_y <= 250 && pix_x >= 30 && pix_x <= 610 && counter%100 <= 50) {R, G, B} <= 6'b11_00_00;
      else if(state==CHARGING && pix_y >= 210 && pix_y <= 250 && pix_x >= 30 && pix_x <= counter) {R, G, B} <= 6'b00_11_00;
      else if(state==COMPLETE && pix_y >= 210 && pix_y <= 250 && pix_x >= 30 && pix_x <= 610 && counter%100 <= 50) {R, G, B} <= 6'b00_11_00;
      // White status heading
      if (text_pixel) {R, G, B} <= 6'b11_11_11;

      // Blanking outside visible display
      if (!video_active) {R, G, B} <= 6'b00_00_00;

     
    end
  end
  reg [16:0] count;
  always@(posedge clk) begin
    if(state==CHARGING || state == COMPLETE || state == FAULT)
    count <= count +1;
    else count <= 0;
  end 
endmodule
