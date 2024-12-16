module i2c_registers(
    input wire clk,
    input wire rst,
    input wire mem_valid,
    input wire [31:0] mem_addr,
    input wire [31:0] mem_wdata,
    input wire [3:0] mem_wstrb,
    output reg [31:0] mem_rdata,
    output reg mem_ready,

    // Conexiones a los registros para el controlador I2C
    output reg [31:0] i2c_bitrate,
    output reg [7:0] i2c_data_out,
    input wire [7:0] i2c_data_in,
    output reg [7:0] i2c_ctrl
);

    localparam ADDR_I2C_BITRATE = 32'h1C;
    localparam ADDR_I2C_DATA_OUT = 32'h1D;
    localparam ADDR_I2C_DATA_IN = 32'h1E;
    localparam ADDR_I2C_CTRL = 32'h1F;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            i2c_bitrate <= 32'd0;
            i2c_data_out <= 8'd0;
            i2c_ctrl <= 8'd0;
            mem_ready <= 1'b0;
            mem_rdata <= 32'd0;
        end else begin
            mem_ready <= 1'b0;

            if (mem_valid) begin
                mem_ready <= 1'b1;

                if (|mem_wstrb) begin
                    case (mem_addr)
                        ADDR_I2C_BITRATE: begin
                            if (mem_wstrb[3]) i2c_bitrate[31:24] <= mem_wdata[31:24];
                            if (mem_wstrb[2]) i2c_bitrate[23:16] <= mem_wdata[23:16];
                            if (mem_wstrb[1]) i2c_bitrate[15:8] <= mem_wdata[15:8];
                            if (mem_wstrb[0]) i2c_bitrate[7:0] <= mem_wdata[7:0];
                        end
                        ADDR_I2C_DATA_OUT: if (mem_wstrb[0]) i2c_data_out <= mem_wdata[7:0];
                        ADDR_I2C_CTRL: if (mem_wstrb[0]) i2c_ctrl <= mem_wdata[7:0];
                    endcase
                end else begin
                    case (mem_addr)
                        ADDR_I2C_BITRATE: mem_rdata <= i2c_bitrate;
                        ADDR_I2C_DATA_OUT: mem_rdata <= {24'd0, i2c_data_out};
                        ADDR_I2C_DATA_IN: mem_rdata <= {24'd0, i2c_data_in};
                        ADDR_I2C_CTRL: mem_rdata <= {24'd0, i2c_ctrl};
                        default: mem_rdata <= 32'd0;
                    endcase
                end
            end
        end
    end
endmodule
