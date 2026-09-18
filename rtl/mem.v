

module mem(
    input clk,
    input [31:0] addr_i,
    input [31:0] wdata_i,
    input [3:0] byte_enable_i, //madem byte korunması gerek böyle olsun

    output reg [31:0] rdata_o
);

reg [31:0] mem [0:4096]; // bu syntaxa tam aşina değilim. değişik geliyor

initial $readmemh("derleyici/out.hex", mem);


always @(posedge clk) begin

    // alignment burada hallediliyor
    // byte enabil
    if(byte_enable_i[0]) mem[addr_i[31:2]][7:0] <= wdata_i[7:0];
    if(byte_enable_i[1]) mem[addr_i[31:2]][15:8] <= wdata_i[15:8];
    if(byte_enable_i[2]) mem[addr_i[31:2]][23:16] <= wdata_i[23:16];
    if(byte_enable_i[3]) mem[addr_i[31:2]][31:24] <= wdata_i[31:24];

    // byte_enable = 000 -> write enable false gibi
end

always @(*) begin
    // byte enable koymuyorum read'e
    rdata_o = mem[addr_i[31:2]];
end





endmodule
