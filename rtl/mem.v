

module mem(
    input clk,
    input [31:0] addr_i,
    input [31:0] wdata_i,
    input [3:0] byte_enable_i, //madem byte korunması gerek böyle olsun
    input mem_req,

    output reg mem_valid,

    output reg [31:0] rdata_o
);


// BRAM ile REQP-1962 hatası veriyodu (boşta addres pinleri varmış)
localparam ADDR_W = 17;  //2^17 = 131072 word

reg [31:0] mem [0:(1<<ADDR_W) - 1];

wire [ADDR_W-1:0] word_addr = addr_i[ADDR_W+1:2];


// cocotb için
//initial $readmemh("../derleyici/out.hex", mem);

//	düz verilog testi için
initial $readmemh("/home/ersan/rv32i_core/derleyici/out.hex", mem);


always @(posedge clk) begin

    // alignment burada hallediliyor
    // byte enabil
    if(byte_enable_i[0]) mem[word_addr][7:0] <= wdata_i[7:0];
    if(byte_enable_i[1]) mem[word_addr][15:8] <= wdata_i[15:8];
    if(byte_enable_i[2]) mem[word_addr][23:16] <= wdata_i[23:16];
    if(byte_enable_i[3]) mem[word_addr][31:24] <= wdata_i[31:24];

    // byte_enable = 000 -> write enable false gibi
end


// BRAM kullansın diye. zamanlamayı bozuyor mu emin değilim daha :D
always @(posedge clk) begin
    // byte enable koymuyorum read'e
    if (mem_req) begin
    	rdata_o <= mem[word_addr];
     	mem_valid <= 1;
    end else begin
        mem_valid <= 0;
    end
end

/*
always @(*) begin
    // byte enable koymuyorum read'e
    rdata_o = mem[addr_i[31:2]];
end
*/





endmodule
