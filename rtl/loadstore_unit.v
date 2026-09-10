

module loadstore_unit(
    input clk,
    input [31:0] pc_i,
    input [1:0] ls_ctrl_i,
    input [2:0] funct3,

    input [31:0] rs1_i,
    input [31:0] rs2_i,
    input [31:0] immediate_i,

    output reg mem_valid,



    output reg [31:0] value_o // başka isim gelmedi aklıma. son değeri atıyor dışarı


);



// isimlendirme konusunda korkuncum
reg [31:0] addr; // alignment kısmını ram hallediyor
reg [31:0] wdata;
reg [3:0] byte_enable;






// ls_ctrl_i
// 00 fetch
// 01 load
// 10 store
// 11 boş geçsin bari

always @(*) begin
    mem_req = 0;
    byte_enable = 0;
    value_o = 32'd0;
    addr = 32'd0;
    wdata = 32'd0;

    case (ls_ctrl_i)
    2'd0: begin
        addr = pc_i;
        mem_req = 1;
        value_o = rdata_o;
    end
    2'd1: begin
        // ayrı bir address generator yerine aluya almayı düşünüyorum.
        // eğer üşenmezsem
        addr = rs1_i + immediate_i; //addr_i;
        mem_req = 1;

        case (funct3)
            3'b000: value_o = {{24{rdata_o[7]}},  rdata_o[7:0]};    // lb
            3'b001: value_o = {{16{rdata_o[15]}},  rdata_o[15:0]};  // lh
            3'b010: value_o = rdata_o;                              // lw
            3'b100: value_o = {24'b0, rdata_o[7:0]};                // lbu
            3'b101: value_o = {16'b0, rdata_o[15:0]};               // lhu
            default $finish;
        endcase

    end
    2'd2: begin

        addr = rs1_i + immediate_i;
        mem_req = 1;
        wdata = rs2_i;

        case (funct3)
            3'b000: byte_enable = 4'b0001;
            3'b001: byte_enable = 4'b0011;
            3'b010: byte_enable = 4'b1111;
            default byte_enable = 4'b0000;
        endcase
    end
    2'd3: begin end
    endcase
end



reg mem_req;

wire [31:0] rdata_o;


// böyle dursun. ram anında veriyor bu durumda
always @(posedge clk) begin
    mem_valid <= mem_req;
end

mem memory (
    .clk(clk),
    .addr_i(addr),
    .wdata_i(wdata),
    .byte_enable_i(byte_enable),

    .rdata_o(rdata_o)
);




endmodule
