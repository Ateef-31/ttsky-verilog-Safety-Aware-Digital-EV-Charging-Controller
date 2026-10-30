module EV_controller #(parameter CLK_FREQUENCY = 25_175_000)(
    input wire system_clock,
    input wire system_resetn,
    input wire plug_detect,
    input wire battery_full,
    input wire auth,
    input wire precharge_ready,
    input wire over_voltage,
    input wire over_current,
    input wire over_temperature,
    input wire emergency_stop,
    output reg [2:0] state
    );
    localparam IDLE = 3'b000,
               CONNECTED = 3'b001,
               AUTH = 3'b010,
               PRECHARGE = 3'b011,
               CHARGING = 3'b100,
               COMPLETE = 3'b101,
               FAULT= 3'b110;
    reg [2:0] current_state , next_state;
    wire count_en = (current_state == FAULT);
    reg [$clog2(CLK_FREQUENCY*2)-1:0] counter;    
    wire safety_fault = over_voltage || over_current || over_temperature || !plug_detect;
    always@(posedge system_clock or negedge system_resetn) begin
        if(!system_resetn) begin
            current_state <= IDLE;
        end
        else begin
            current_state <= next_state;
            if(count_en) begin
                if(counter < (CLK_FREQUENCY*2) - 1)
                    counter <= counter + 1;
            end
            else
                counter <= 0;        
        end
    end
    always@(*) begin
        case(current_state)
            IDLE: begin
                if(plug_detect) begin
                    next_state = CONNECTED;
                end
                else begin
                    next_state = IDLE;
                end
            end
            CONNECTED: begin
                if(safety_fault) begin
                    next_state = FAULT;
                end
                else if(auth) begin
                    next_state = AUTH;
                end
                else begin
                    next_state = CONNECTED;
                end
            end
            AUTH: begin
                if(safety_fault) begin
                    next_state = FAULT;
                end
                else if(auth) begin
                    next_state = PRECHARGE;
                end
                else begin
                    next_state = CONNECTED;
                end
            end
            PRECHARGE: begin
                if(safety_fault) begin
                    next_state = FAULT;
                end
                else if(precharge_ready) begin
                    next_state = CHARGING;
                end
                else begin
                    next_state = PRECHARGE;
                end
            end
             CHARGING: begin
                if(emergency_stop || safety_fault) begin
                    next_state = FAULT;
                end
                else if(battery_full) begin
                    next_state = COMPLETE;
                end
                else begin
                    next_state = CHARGING;
                end
            end
             COMPLETE: begin
                if(!plug_detect) begin
                    next_state = IDLE;
                end
                else begin
                    next_state = COMPLETE;
                end
            end
            FAULT: begin
                if(counter == ((CLK_FREQUENCY*2) - 1) && !plug_detect) begin
                    next_state = IDLE;
                end
                else begin
                    next_state = FAULT;
                end
            end
             default: begin
                    next_state = IDLE;
                end
            endcase
        end
 
        always@(*) begin
            state = current_state;
        end    
endmodule