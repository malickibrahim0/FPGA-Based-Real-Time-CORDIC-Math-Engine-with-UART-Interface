module cordic_top (
    input  wire clk,
    input  wire reset,  // active high reset
    input  wire rx,
    output wire tx
);

    // === UART RX ===
    wire [7:0] rx_byte;
    wire       rx_dv;

    UART_RX uart_rx_inst (
        .i_Clock(clk),
        .i_RX_Serial(rx),
        .o_RX_DV(rx_dv),
        .o_RX_Byte(rx_byte)
    );

    // === UART TX ===
    reg        tx_start;
    reg [7:0]  tx_byte;
    wire       tx_done;
    wire       tx_active;
    wire       tx_serial;

    UART_TX uart_tx_inst (
        .i_Rst_L(~reset),
        .i_Clock(clk),
        .i_TX_DV(tx_start),
        .i_TX_Byte(tx_byte),
        .o_TX_Active(tx_active),
        .o_TX_Serial(tx_serial),
        .o_TX_Done(tx_done)
    );

    assign tx = tx_serial;

    // === CORDIC ===
    reg [2:0] rx_count;
    reg [9:0] x_in, y_in;
    reg [13:0] phase_in;
    reg        cordic_enable;
    reg        aux_in;

    wire signed [9:0] x_out, y_out;
    wire              aux_out;

    Cordic_Algoo cordic_inst (
        .i_clk(clk),
        .i_reset(reset),
        .i_enable(cordic_enable),
        .i_xcord(x_in),
        .i_ycord(y_in),
        .i_phase(phase_in),
        .i_aux(aux_in),
        .o_xcord(x_out),
        .o_ycord(y_out),
        .o_aux(aux_out)
    );

    // === Input collection (4 UART bytes → x/y/phase) ===
    reg [31:0] rx_shift;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            rx_count <= 0;
            cordic_enable <= 0;
        end else begin
            cordic_enable <= 0;
            if (rx_dv) begin
                rx_shift <= {rx_shift[23:0], rx_byte};
                rx_count <= rx_count + 1;
            end
            if (rx_count == 3) begin
                x_in <= rx_shift[31:22];
                y_in <= rx_shift[21:12];
                phase_in <= rx_shift[11:0];
                aux_in <= 1;
                cordic_enable <= 1;
                rx_count <= 0;
            end
        end
    end

    // === Output state machine (3 UART bytes from x_out, y_out) ===
    reg [1:0] tx_state;
    reg       tx_start_pending;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            tx_state <= 0;
            tx_start <= 0;
            tx_start_pending <= 0;
        end else begin
            tx_start <= 0;

            case (tx_state)
                0: if (aux_out && ~tx_active && ~tx_start_pending) begin
                    tx_byte <= x_out[9:2];
                    tx_start <= 1;
                    tx_start_pending <= 1;
                    tx_state <= 1;
                end

                1: if (tx_done) begin
                    tx_byte <= {x_out[1:0], y_out[9:4]};
                    tx_start <= 1;
                    tx_state <= 2;
                end

                2: if (tx_done) begin
                    tx_byte <= {y_out[3:0], 4'b0};
                    tx_start <= 1;
                    tx_state <= 3;
                end

                3: if (tx_done) begin
                    tx_state <= 0;
                    tx_start_pending <= 0;
                end
            endcase
        end
    end

endmodule
