module i2c_top(
    input wire clk,
    input wire rst,
    input wire mem_valid,
    input wire [31:0] mem_addr,
    input wire [31:0] mem_wdata,
    input wire [3:0] mem_wstrb,
    output wire [31:0] mem_rdata,
    output wire mem_ready,
    inout wire i2c_sda,
    inout wire i2c_scl
);

    wire [31:0] i2c_bitrate;
    wire [7:0] i2c_data_out;
    wire [7:0] i2c_data_in;
    wire [7:0] i2c_ctrl_wire;  
    reg [7:0] i2c_ctrl_reg;    

    wire [6:0] addr = i2c_data_out[7:1];
    wire rw = i2c_data_out[0];
    wire enable = i2c_ctrl_wire[6];

    i2c_registers u_i2c_registers (
        .clk(clk),
        .rst(rst),
        .mem_valid(mem_valid),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_wstrb(mem_wstrb),
        .mem_rdata(mem_rdata),
        .mem_ready(mem_ready),
        .i2c_bitrate(i2c_bitrate),
        .i2c_data_out(i2c_data_out),
        .i2c_data_in(i2c_data_in),
        .i2c_ctrl(i2c_ctrl_wire)
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            i2c_ctrl_reg <= 8'd0;
        end else begin
            i2c_ctrl_reg <= i2c_ctrl_wire;
        end
    end

    i2c_controller u_i2c_controller (
        .clk(clk),
        .rst(rst),
        .addr(addr),
        .data_in(i2c_data_out),
        .enable(enable),
        .rw(rw),
        .data_out(i2c_data_in),
        .i2c_sda(i2c_sda),
        .i2c_scl(i2c_scl)
    );
endmodule
