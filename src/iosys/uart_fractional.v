// UART RX with fractional clock divider.
// Baud rate = frequency of `clk` / (DIV_NUM / DIV_DEN)
//
// Author: nand2mario, Feb 2025
module uart_rx_fractional #(
    parameter DIV_NUM = 25,
    parameter DIV_DEN = 1
)(
    input clk,
    input resetn,
    input rx,
    output reg [7:0] data,
    output reg valid
);

reg [1:0] state;
reg [$clog2(DIV_NUM+DIV_DEN+1)-1:0] cnt;
reg [2:0] bit_index;
reg [7:0] rx_data;

localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;

always @(posedge clk) begin
    reg [$clog2(DIV_NUM+DIV_DEN+1)-1:0] cnt_next;
    if (!resetn) begin
        state <= 0;
        valid <= 0;
        data <= 0;
    end else begin
        cnt_next = cnt + DIV_DEN;
        valid <= 0;
        if (state != IDLE)
            cnt <= cnt_next;    // increment counter by default

        case (state)
            IDLE: begin         // Idle
                if (!rx) begin
                    state <= START;
                    cnt <= DIV_DEN/2; // start at half cycle
                    bit_index <= 0;
                    rx_data <= 0;
                end
            end
            START: begin        // Start bit, wait half a bit time
                if (cnt_next >= DIV_NUM/2) begin
                    state <= DATA;
                    cnt <= cnt_next - DIV_NUM/2;
                end
            end
            DATA: begin         // Data bits
                if (cnt_next >= DIV_NUM) begin
                    rx_data[bit_index] <= rx;
                    if (bit_index == 7) 
                        state <= STOP;
                    else 
                        bit_index <= bit_index + 1;
                    cnt <= cnt_next - DIV_NUM;
                end
            end
            STOP: begin         // Stop bit
                if (cnt_next >= DIV_NUM) begin
                    valid <= 1;
                    data <= rx_data;
                    state <= IDLE;
                end
            end
        endcase
        
    end
end

endmodule 

module uart_tx_fractional #(
    parameter DIV_NUM = 25,
    parameter DIV_DEN = 1
)(
    input clk,
    input resetn,
    input [7:0] data,
    input valid,
    output reg tx,
    output ready
);

reg [3:0] state;
reg [$clog2(DIV_NUM+DIV_DEN+1)-1:0] cnt;
reg [2:0] bit_index;
reg [7:0] tx_data;

localparam IDLE = 0, START = 1, DATA = 2, STOP = 3;

assign ready = (state == IDLE);

always @(posedge clk) begin
    reg [$clog2(DIV_NUM+DIV_DEN+1)-1:0] cnt_next;
    if (!resetn) begin
        state <= 0;
        tx <= 1;
        cnt <= 0;
    end else begin
        cnt_next = cnt + DIV_DEN;
        if (state != IDLE)
            cnt <= cnt_next;

        case (state)
            IDLE: begin // Idle
                if (valid) begin
                    tx_data <= data;
                    state <= START;
                    tx <= 0; // Start bit
                    cnt <= 0;
                end
            end
            START: begin // Start bit
                if (cnt_next >= DIV_NUM) begin
                    state <= DATA;
                    bit_index <= 0;
                    tx <= tx_data[0];
                    cnt <= cnt_next - DIV_NUM;
                end
            end
            DATA: begin // Data bits
                if (cnt_next >= DIV_NUM) begin
                    if (bit_index == 7) begin
                        state <= STOP;
                        tx <= 1; // Stop bit
                    end else begin
                        bit_index <= bit_index + 1;
                        tx <= tx_data[bit_index + 1];
                    end
                    cnt <= cnt_next - DIV_NUM;
                end
            end
            STOP: begin // Stop bit
                if (cnt_next >= DIV_NUM) 
                    state <= IDLE;
            end
        endcase
    end
end

endmodule 