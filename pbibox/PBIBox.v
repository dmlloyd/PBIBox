`timescale 1ns / 1ps

module PBIBox(
    input [15:0] Addr,
    input DMA_in,
    output DMA_out,
    input EXTSEL_in,
    output EXTSEL_out,
    input EXTCPU,
    input EXTMEM,
    output D1FF,
    output D1XX,
    output D6XX,
    output D8XX
    );

assign D1FF = (Addr == 'hD1FF) ? 'b0 : 'bz;
assign D1XX = (Addr[15:8] == 'hD1) && (Addr[7:0] != 'hFF) ? 'b0 : 'bz;
assign D6XX = (Addr[15:9] == ('hD6 >> 1)) ? 'b0 : 'bz;
assign D8XX = (Addr[15:11] == ('hD8 >> 3)) ? 'b0 : 'bz;

assign DMA_out = (!DMA_in || !EXTCPU) ? 'b0 : 'bz;

assign EXTSEL_out = (!EXTSEL_in || !EXTMEM) ? 'b0 : 'bz;

endmodule
