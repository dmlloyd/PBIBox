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
    // 28Mhz (phi2 times 16)
    input wire CLK1,
    // ignored for now
    input wire CLK2,
    // always 1
    output wire S0,
    // always 0
    output wire S1,
    output tri MPD,
    inout tri RdWr,
    output wire OE,
    output wire RamCS,
    output wire RomCS,
    // Addr 0-9 on W5300; bank address 0-4 on RAM and 0-7 on ROM
    output wire [9:0] AddrOut,
    inout tri [7:0] Data,
    input wire [2:0] ID,
    output tri IRQ,
    output tri DmaReqOut,
    input wire DmaAckIn,
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
    input wire DeviceInt
    );

reg [3:0] ClkPhase;

reg [2:0] DevID;

reg [5:0] RamBank;
reg [7:0] RomBank;
reg [3:0] DeviceBank;

reg [15:0] DmaAddr;
reg [15:0] DmaCount;

reg DmaReq;
reg DmaCycle;
reg DmaRead; /* Read from device, write to RAM if 1, Write to device, read from RAM if 0 */
reg DmaOdd;
reg DmaOddPickup; /* Blank read/write to align FIFO access */

reg ReadWrite; /* 1 = read, 0 = write, latched */
reg W5300Sel;  /* 1 = selected */
reg RamSel;    /* 1 = selected */
reg RomSel;    /* 1 = selected */

reg Selected;

reg SpiBit;
reg SpiSel;
reg SpiClkSig;

// There are three parts of the clock we care about
// 1: Start of phase 1 (negative edge phi2) - all input data should be sampled at this time
// 2: Phase 1 plus 35 nS - all latched or held output data should be dropped at this time
// 8: Start of phase 2 (positive edge phi2) - addresses should be sampled at this time, and chip selects enabled
// 15: Just before start of phase 1 (negative edge phi2) - update DmaCycle latch

always @(negedge CLK1) begin
    if (Reset == 1'b0) begin
        /* sync clock */
        if (Phi2 == 1'b0 && ClkPhase[3] != 1'b0) begin
            ClkPhase <= {Phi2,3'b0};
        end
        /* Reset! */
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
        DevID <= ID;

    end else begin
        /* next clock phase */
        ClkPhase <= ClkPhase + 1;

        /* test current clock phase */
        if (ClkPhase == 4'b0000) begin
            if (DmaCycle) begin
                
                if (DmaRead == 1'b0) begin
                    if (DmaCount == 1) begin
                        DmaCount <= 0;
                        if (DmaOdd) begin
                            // one dummy cycle needed
                            DmaOdd <= 0;
                        end else begin
                            // last cycle
                            DmaReq <= 0;
                        end
                    end else begin
                        DmaOdd <= ! DmaOdd;
                        DmaCount <= DmaCount - 1;
                        DmaAddr <= DmaAddr + 1;
                    end
                end
            end else if (ReadWrite == 1'b0) begin
                // sample inputs and perform write operation
                if (SysAddr[15:7] == 9'b110100010 && Selected) begin // First 127 bytes
                    RomBank[7:0] <= SysAddr[7:0];
                end else if (SysAddr[15:4] == 12'b110100011100     && Selected) begin // D1Cx
                    DeviceBank[3:0] <= SysAddr[3:0];
                end else if (SysAddr[15:3] == 13'b1101000111010    && Selected) begin // D1D0-7
                    SpiBit <= Data[SysAddr[2:0]];
                end else if (SysAddr[15:0] == 16'b1101000111010100 && Selected) begin // D1D8
                    DmaAddr[7:0] <= Data[7:0];
                end else if (SysAddr[15:0] == 16'b1101000111010101 && Selected) begin // D1D9
                    DmaAddr[15:8] <= Data[7:0];
                end else if (SysAddr[15:0] == 16'b1101000111010110 && Selected) begin // D1DA
                    DmaCount[7:0] <= Data[7:0];
                end else if (SysAddr[15:0] == 16'b1101000111010111 && Selected) begin // D1DB
                    DmaCount[15:8] <= Data[7:0];
                end else if (SysAddr[15:1] == 15'b110100011101100  && Selected) begin // D1DC-DD
                    // Start DMA
                    DmaReq <= 1;
                    DmaRead <= SysAddr[0];
                    DmaOdd <= DmaCount[0];
                end else if (SysAddr[15:1] == 15'b110100011101101  && Selected) begin // D1DE-DF
                    SpiClkSig <= SysAddr[0];
                end else if (SysAddr[15:0] == 16'b1101000111111111) begin
                    Selected <= Data == 8'b1 << DevID; // disable on conflict
                end else if (SysAddr[15:5] == 11'b11010001111      && Selected) begin // D1E0-D1FE
                    RamBank[4:0] <= SysAddr[4:0];
                end
            end                
        end else if (ClkPhase == 4'b0001 && ReadWrite == 1'b1) begin
            // clear holds from read operation
            W5300Sel <= 0;
            RamSel <= 0;
            RomSel <= 0;
        end else if (ClkPhase == 4'b1000) begin
            // Sample all address info and enable read operation
            ReadWrite <= RdWr;
        end else if (ClkPhase == 4'b1111) begin
            // Check if the next cycle will be a DMA cycle
            DmaCycle <= DmaReq && DmaAckIn && Halt;
        end
    end      
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

endmodule
