module i2c_top_tb;

    reg clk;
    reg rst;
    reg mem_valid;
    reg [31:0] mem_addr;
    reg [31:0] mem_wdata;
    reg [3:0] mem_wstrb;
    wire [31:0] mem_rdata;
    wire mem_ready;
    wire i2c_sda;
    wire i2c_scl;

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

    initial begin
        clk = 0;
        forever #10 clk = ~clk; // Ajustar el tiempo del reloj para una simulación más lenta
    end

    initial begin
        $dumpfile("i2c_top_tb.vcd");
        $dumpvars(0, i2c_top_tb);

        // Inicialización del sistema
        rst = 1; mem_valid = 0; mem_addr = 0; mem_wdata = 0; mem_wstrb = 0;
        #40 rst = 0;

        // Configuración inicial del bitrate
        write_register(32'h1C, 32'd500000); // Configurar bitrate
        #20;

        // Enviar dirección del periférico
        write_register(32'h1D, 8'hAA); // Dirección + R/W
        #20;

        // Enviar comando para iniciar transmisión (START + dirección)
        write_register(32'h1F, 8'b01010000);
        #200; // Tiempo extendido para observar claramente las señales

        // Cambiar valor del registro para enviar el dato
        write_register(32'h1D, 8'h55); // Dato a enviar
        #20;

        // Enviar dato al periférico
        write_register(32'h1F, 8'b01001000);
        #200; // Tiempo extendido para observar el envío del dato

        // Generar condición de parada (STOP)
        write_register(32'h1F, 8'b00100000);
        #200; // Tiempo extendido para observar la condición STOP

        $finish; // Finaliza la simulación
    end

    task write_register(input [31:0] addr, input [31:0] data);
        begin
            mem_valid = 1; mem_addr = addr; mem_wdata = data; mem_wstrb = 4'b1111;
            #20 mem_valid = 0; // Ajustar tiempo para mantener el registro activado
        end
    endtask
endmodule
