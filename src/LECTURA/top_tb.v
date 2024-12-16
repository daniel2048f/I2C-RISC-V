`timescale 1ns / 1ps

module i2c_top_tb;

    // Señales del banco de pruebas
    reg clk;
    reg rst;
    reg mem_valid;
    reg [31:0] mem_addr;
    reg [31:0] mem_wdata;
    reg [3:0] mem_wstrb;
    wire [31:0] mem_rdata;
    wire mem_ready;
    tri i2c_sda; // Línea de datos bidireccional
    wire i2c_scl; // Línea de reloj

    // Instancia del módulo `i2c_top`
    i2c_top uut (
        .clk(clk),
        .rst(rst),
        .mem_valid(mem_valid),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata),
        .mem_ready(mem_ready),
        .i2c_sda(i2c_sda),
        .i2c_scl(i2c_scl)
    );

    // Generación de reloj
    initial begin
        clk = 0;
        forever #10 clk = ~clk; // Período del reloj: 20 ns
    end

    // Secuencia de prueba
    initial begin
        // Configuración para volcado de simulación
        $dumpfile("i2c_top_tb.vcd"); // Archivo de salida para GTKWave
        $dumpvars(0, i2c_top_tb);    // Volcar todas las variables del módulo testbench

        // Inicialización
        rst = 1;
        mem_valid = 0;
        mem_addr = 0;
        mem_wdata = 0;
        mem_wstrb = 0;
        #50 rst = 0; // Desactiva el reset después de 50 ns

        // Configuración inicial del bitrate
        write_register(32'h1C, 32'd500000); // Configurar bitrate
        #20;

        // Lectura desde el periférico
        write_register(32'h1D, 8'b10101001); // Dirección del esclavo + RW (lectura)
        #20;
        write_register(32'h1F, 8'b01010000); // Generar START y enviar dirección
        #200;

        // Leer el dato recibido desde el esclavo
        read_register(32'h1E); // Leer dato desde el registro i2c_data_in
        #200;

        $finish; // Finaliza la simulación
    end

    // Tareas para escritura y lectura en los registros
    task write_register(input [31:0] addr, input [31:0] data);
        begin
            mem_valid = 1;
            mem_addr = addr;
            mem_wdata = data;
            mem_wstrb = 4'b1111;
            #20 mem_valid = 0; // Desactiva mem_valid después de un ciclo
        end
    endtask

    task read_register(input [31:0] addr);
        begin
            mem_valid = 1;
            mem_addr = addr;
            mem_wstrb = 4'b0000; // No se realiza escritura
            #20 mem_valid = 0; // Desactiva mem_valid después de un ciclo
            $display("Dato leído en la dirección %h: %h", addr, mem_rdata);
        end
    endtask

endmodule
