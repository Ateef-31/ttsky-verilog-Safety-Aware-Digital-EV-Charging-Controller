module two_ff_synchronizer #(
    parameter MAX_COUNT = 517_500 
)(
    input wire clk,
    input wire rst_n,
    input wire [7:0] noisy_in,
    output reg [7:0] clean_out
);

    reg [7:0] sync_0;
    reg [7:0] sync_1;
    reg [19:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_0    <= 8'b0;
            sync_1    <= 8'b0;
            clean_out <= 8'b0;
            count     <= 0;
        end else begin
            // 2-stage synchronizer to prevent metastability
            sync_0 <= noisy_in;
            sync_1 <= sync_0;

            // Debounce timer
            if (sync_1 != clean_out) begin
                if (count == MAX_COUNT - 1) begin
                    clean_out <= sync_1;
                    count     <= 0;
                end else begin
                    count <= count + 1;
                end
            end else begin
                count <= 0;
            end
        end
    end
endmodule
