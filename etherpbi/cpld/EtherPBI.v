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
module EtherPBI(
    inout tri [15:0] SysAddr,
    input wire Phi2,
    output tri MPD,
    inout tri RdWr,
    output wire OE,
    output wire RamCS,
    output wire RomCS,
    output wire [13:8] RamAddrOut,
    output wire [15:10] RomAddrOut,
    inout tri [7:0] Data,
    inout tri Dx,
    output tri IRQ,
    output DmaReqOut,
    input wire Halt,
    input wire Reset,
    input wire SpiDI,
    output wire SpiDO,
    output wire SpiCK,
    output wire SpiCS,
    output wire DeviceWr,
    output wire DeviceRd,
    output wire DeviceCS,
    output tri EXTSEL,
    input wire DeviceInt,
    output wire [9:0] DeviceAddr
    );

reg [13:8] RamAddr;
reg [15:10] RomAddr;
reg [3:0] DeviceBank;
reg [15:0] DmaAddr;
reg [15:0] DmaCount;
reg DmaReq;
reg DmaCycle;
reg DmaRead; /* Read from device, write to RAM if 1, Write to device, read from RAM if 0 */
reg DmaOdd;
reg DmaOddPickup; /* Blank read/write to align FIFO access */
reg Selected;
reg SpiBit;
reg SpiSel;
reg SpiClkSig;

reg [7:0] DataOut;
reg [9:0] DeviceAddrOut;

initial begin
    DeviceBank = 0;
    DmaAddr = 0;
    DmaCount = 0;
    DmaCycle = 0;
    RamAddr = 0;
    RomAddr = 0;
    Selected = 0;
    DmaReq = 0;
    SpiBit = 0;
    SpiSel = 0;
end

always @(negedge Phi2) begin
    if (Reset == 1'b0) begin
        DeviceBank <= 0;
        DmaAddr <= 0;
        DmaCount <= 0;
        DmaCycle <= 0;
        RamAddr <= 0;
        RomAddr <= 0;
        Selected <= 0;
        DmaReq <= 0;
        SpiBit <= 0;
        SpiSel <= 0;
    end else begin
        if ((DmaReq & !Halt) == 1'b1) begin
            /* Just *starting* a DMA cycle */
            DmaCycle <= 1'b1;
            if (DmaOddPickup == 1'b1 || DmaCount == 16'h1 && DmaOdd == 1'b0) begin
                /* Will be the last cycle */
                DmaReq <= 0;
            end
        end else begin
            DmaCycle <= 1'b0;
        end
        if (DmaCycle == 1'b1) begin
            /* Just *finishing* a DMA cycle */
            if (DmaOddPickup == 1'b0) begin
                /* actual cycle */
                if (DmaCount == 16'h1) begin
                    /* Last DMA cycle (maybe) */
                    if (DmaOdd == 1'b1) begin
                        /* One more cycle to align */
                        DmaOdd <= 0;
                        DmaOddPickup <= 1'b1;
                    end else begin
                        /* Next cycle is the last DMA cycle */
                        DmaRead <= 0;
                        DmaReq <= 0;
                    end
                end
                DmaAddr <= DmaAddr + 1;
                DmaCount <= DmaCount - 1;
            end
        end else if ((Selected & RdWr) == 1'b0) begin
            /* Just *finishing* a non-DMA cycle */
            /* register loads */
            if (SysAddr[15:6] == ('hD100 >> 6)) begin
                RamAddr[13:8] <= SysAddr[5:0];
            end else if (SysAddr[15:6] == ('hD140 >> 6)) begin
                RomAddr[15:10] <= SysAddr[5:0];
            // D180..D1BF = W5300 access
            end else if (SysAddr[15:4] == ('hD1E0 >> 4)) begin
                DeviceBank[3:0] <= SysAddr[3:0];
            end else if (SysAddr == 'hD1F7) begin
                DmaAddr[7:0] <= Data[7:0];
            end else if (SysAddr == 'hD1F8) begin
                DmaAddr[15:8] <= Data[7:0];
            end else if (SysAddr == 'hD1F9) begin
                DmaCount[7:0] <= Data[7:0];
            end else if (SysAddr == 'hD1FA) begin
                DmaCount[15:8] <= Data[7:0];
            end else if (SysAddr == 'hD1FB) begin
                // initiate DMA transfer, bit 0 = R/!W
                DmaRead <= Data[0];
                DmaOddPickup <= 0;
                DmaOdd <= DmaCount[0];
                DmaReq <= 1'b1;
            // D1FC = /HALT detect (read only)
            end else if (SysAddr == 'hD1FD) begin
                SpiSel <= Data[0]; // Write 1 to select SPI, 0 to deselect
            end else if (SysAddr == 'hD1FE) begin
                SpiBit <= Data[7]; // MSB first, left shift to empty register
                SpiClkSig <= 1'b1;
            end else if (SysAddr == 'hD1FF) begin
                Selected <= Dx;
            end
        end
    end
    if (SpiBit == 1'b1) begin
        SpiBit <= 0;
    end
    if (SpiClkSig == 1'b1) begin
        SpiClkSig <= 0;
    end
end

always
begin
    if ((Selected & Phi2 & RdWr) == 1'b1) begin
        if (SysAddr[15:0] == 'hD1F7) begin
            DataOut <= DmaAddr[7:0];
        end else if (SysAddr[15:0] == 'hD1F8) begin
            DataOut <= DmaAddr[15:8];
        end else if (SysAddr[15:0] == 'hD1F9) begin
            DataOut <= DmaCount[7:0];
        end else if (SysAddr[15:0] == 'hD1FA) begin
            DataOut <= DmaCount[15:8];
        // D1FB = DMA initiate (write only)
        end else if (SysAddr == 'hD1FC) begin
            DataOut <= {Halt, 7'b0000000};
        // D1FD = SPI select (write only)
        end else if (SysAddr == 'hD1FE) begin
            DataOut <= {7'b0000000, SpiDI};
        end else if (SysAddr == 'hD1FF) begin
            DataOut <= 8'bzzzzzzzz;
        end else if (SysAddr[15:8] == 'hD1) begin
            DataOut <= 8'b00000000;
        end else begin
            DataOut <= 8'bzzzzzzzz;
        end
    end else begin
        DataOut <= 8'bzzzzzzzz;
    end
end

always
begin
    if (DmaCycle == 1'b1) begin
        if (DmaRead == 1'b1) begin
            DeviceAddrOut <= {DeviceBank, 5'b10111, DmaOdd^DmaCount[0]};
        end else begin
            DeviceAddrOut <= {DeviceBank, 5'b11000, DmaOdd^DmaCount[0]};
        end
    end else begin
        DeviceAddrOut <= {DeviceBank, SysAddr[5:0]};
    end
end

assign SpiCK = Phi2 & (SpiClkSig | (Selected & RdWr & (SysAddr == 'hD197)));
assign SpiCS = SpiSel;
assign SpiDO = SpiBit;

assign IRQ = DeviceInt ? 1'b0 : 1'bz;
assign MPD = Selected ? 1'b0 : 1'bz;
assign OE = ~(Selected & RdWr);
assign RamAddrOut = SysAddr[8] ? RamAddr : 0;
assign RomAddrOut = SysAddr[10] ? RomAddr : 0;
assign DmaReqOut = DmaReq ? 1'b0 : 1'bz;
assign EXTSEL = DmaOddPickup | Selected & (SysAddr[15:11] == ('hD800 >> 11) || SysAddr[15:9] == ('hD600 >> 9) || SysAddr[15:8] == ('hD100 >> 8)) ? 1'b0 : 1'bz;
assign Dx = (Selected & (SysAddr == 'hD1FF) & RdWr) ? ~DeviceInt : 1'bz;
assign RomCS = ~(Selected & Phi2 & (SysAddr[15:11] == ('hD800 >> 11)));
assign RamCS = ~(Selected & Phi2 & (SysAddr[15:9] == ('hD600 >> 9)));

/* HALT and SPI read registers */
assign Data[7:0] = DataOut[7:0];

assign DeviceAddr = DeviceAddrOut;
assign SysAddr = DmaCycle ? DmaAddr : 16'bz;
assign DeviceWr = ~(DmaCycle ? ~DmaRead : ~DeviceCS & ~RdWr);
assign DeviceRd = ~(DmaCycle ?  DmaRead : ~DeviceCS &  RdWr);
assign DeviceCS = ~(Phi2 & (DmaCycle | Selected & (SysAddr[15:6] == ('hD180 >> 6))));
assign RdWr = DmaCycle ? DmaRead : 1'bz;

endmodule
