`timescale 1ns / 1ps

module i2c_slave_controller(
    inout sda,  // Línea de datos SDA bidireccional
    inout scl   // Línea de reloj SCL
);

    // Dirección fija del esclavo
    localparam ADDRESS = 7'b0101010;

    // Definición de estados
    localparam READ_ADDR = 0;
    localparam SEND_ACK = 1;
    localparam READ_DATA = 2;
    localparam WRITE_DATA = 3;
    localparam SEND_ACK2 = 4;

    // Registros internos
    reg [7:0] addr;           // Dirección recibida
    reg [7:0] counter;        // Contador de bits de transferencia
    reg [2:0] state = 0;      // Estado actual de la FSM
    reg [7:0] data_in = 0;    // Datos recibidos del maestro
    reg [7:0] data_out = 8'b11001100; // Datos a enviar al maestro
    reg sda_out = 0;          // Valor de salida en SDA
    reg sda_oe = 0;           // Habilita la escritura en SDA
    reg start = 0;            // Indica detección de condición `START`

    // Debugging: Estado de la FSM
    output wire [2:0] debug_state;
    assign debug_state = state;

    // Conexión bidireccional de SDA
    assign sda = sda_oe ? sda_out : 1'bz;

    // Detectar condición `START`
    always @(negedge sda) begin
        if (!start && scl) begin
            start <= 1;
            state <= READ_ADDR; // Inicia en `READ_ADDR`
            counter <= 7;       // Reinicia contador de bits
        end
    end

    // Detectar condición `STOP`
    always @(posedge sda) begin
        if (start && scl) begin
            start <= 0;
            state <= READ_ADDR; // Reinicia FSM tras `STOP`
            sda_oe <= 0;        // Libera SDA
        end
    end

    // FSM para comunicación I2C
    always @(posedge scl) begin
        if (start) begin
            case (state)
                READ_ADDR: begin
                    addr[counter] <= sda; // Recibe dirección bit a bit
                    if (counter == 0) begin
                        state <= SEND_ACK; // Envía ACK tras recibir dirección
                    end else begin
                        counter <= counter - 1;
                    end
                end
                SEND_ACK: begin
                    if (addr[7:1] == ADDRESS) begin
                        counter <= 7; // Reinicia contador de bits
                        sda_oe <= 1; // Habilita SDA para enviar ACK
                        sda_out <= 0; // ACK (SDA = 0)
                        if (addr[0] == 0) begin
                            state <= READ_DATA; // Escritura
                        end else begin
                            state <= WRITE_DATA; // Lectura
                        end
                    end else begin
                        state <= READ_ADDR; // Dirección incorrecta
                    end
                end
                READ_DATA: begin
                    data_in[counter] <= sda; // Almacena bits recibidos
                    if (counter == 0) begin
                        state <= SEND_ACK2; // ACK tras recepción de datos
                    end else begin
                        counter <= counter - 1;
                    end
                end
                WRITE_DATA: begin
                    sda_out <= data_out[counter]; // Envía datos al maestro
                    sda_oe <= 1; // Habilita SDA para transmisión
                    if (counter == 0) begin
                        state <= READ_ADDR; // Vuelve a dirección
                    end else begin
                        counter <= counter - 1;
                    end
                end
                SEND_ACK2: begin
                    sda_out <= 0; // ACK tras datos
                    sda_oe <= 1;
                    state <= READ_ADDR; // Vuelve a esperar dirección
                end
            endcase
        end
    end
endmodule
