module i2c_controller(
    input wire clk,
    input wire rst,
    input wire [6:0] addr,
    input wire [7:0] data_in,
    input wire enable,
    input wire rw,
    output reg [7:0] data_out,
    inout wire i2c_sda,
    inout wire i2c_scl
);

    localparam IDLE = 0;
    localparam START = 1;
    localparam ADDRESS = 2;
    localparam ACK = 3;
    localparam DATA = 4;
    localparam WAIT_ACK_DATA = 5;
    localparam STOP = 6;

    reg [2:0] state;
    reg [7:0] shift_reg;
    reg [3:0] bit_counter;

    reg scl_out, sda_out, sda_oe;
    reg scl_enable;

    assign i2c_sda = sda_oe ? sda_out : 1'b1; // SDA en alto por defecto en vez de 'z'
    assign i2c_scl = scl_enable ? scl_out : 1'b1;

    // Generación de reloj para i2c_scl
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            scl_out <= 1;
            scl_enable <= 0;
        end else begin
            if (state != IDLE) scl_enable <= 1; // Activa SCL solo si no está en IDLE
            else scl_enable <= 0;
            scl_out <= ~scl_out; // Alterna el reloj
        end
    end

    // FSM para control del bus I2C
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            sda_out <= 1; // SDA en alto por defecto
            sda_oe <= 1;  // Mantener SDA en alto inicialmente
            bit_counter <= 0;
        end else begin
            case (state)
                IDLE: begin
                    scl_out <= 1; // Mantén SCL en alto por defecto
                    sda_out <= 1; // SDA permanece en alto
                    sda_oe <= 1;  // SDA en alto, no en alta impedancia
                    if (enable) begin
                        state <= START; // Solo inicia transmisión si enable está activo
                    end
                end
                START: begin
                    sda_out <= 0; // Generar condición START
                    sda_oe <= 1; // Habilitar SDA como salida
                    if (scl_out) begin
                        state <= ADDRESS; // Ir al siguiente estado
                        shift_reg <= {addr, rw}; // Cargar dirección + bit R/W
                        bit_counter <= 7;
                    end
                end
                ADDRESS: begin
                    if (!scl_out) begin
                        sda_out <= shift_reg[bit_counter]; // Envía bits de dirección
                        sda_oe <= 1; // Habilitar SDA
                        if (bit_counter == 0) state <= ACK; // Termina dirección
                        else bit_counter <= bit_counter - 1;
                    end
                end
                ACK: begin
                    sda_oe <= 0; // Liberar SDA para leer ACK
                    if (!i2c_sda) begin // ACK recibido
                        shift_reg <= data_in; // Cargar datos para escribir
                        bit_counter <= 7;
                        state <= DATA;
                    end else begin
                        state <= STOP; // NACK recibido
                    end
                end
                DATA: begin
                    if (!scl_out) begin
                        sda_out <= shift_reg[bit_counter]; // Escribir datos
                        sda_oe <= 1; // Controlar SDA
                        if (bit_counter == 0) state <= WAIT_ACK_DATA;
                        else bit_counter <= bit_counter - 1;
                    end
                end
                WAIT_ACK_DATA: begin
                    sda_oe <= 0; // Liberar SDA para leer ACK
                    if (!i2c_sda) begin // ACK recibido
                        state <= STOP;
                    end else begin
                        state <= STOP; // NACK recibido
                    end
                end
                STOP: begin
                    scl_out <= 1; // Asegura que SCL termine en alto
                    sda_out <= 1; // Generar condición STOP (SDA pasa a alto)
                    sda_oe <= 1; // Mantener SDA en alto
                    if (!enable) begin
                        state <= IDLE; // Si enable está desactivado, vuelve a IDLE
                    end
                end
            endcase
        end
    end
endmodule