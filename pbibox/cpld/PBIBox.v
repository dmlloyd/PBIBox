`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Copyright (C) 2013, David M. Lloyd
//
// This file is part of the PBIBox suite.
// 
// PBIBox is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// PBIBox is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with PBIBox.  If not, see <http://www.gnu.org/licenses/>.
//
//////////////////////////////////////////////////////////////////////////////////

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
