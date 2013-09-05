    ;;
    ;; Copyright (C) 2013, David M. Lloyd
    ;;
    ;; This file is part of the PBIBox suite.
    ;;
    ;; PBIBox is free software: you can redistribute it and/or modify
    ;; it under the terms of the GNU General Public License as published by
    ;; the Free Software Foundation, either version 3 of the License, or
    ;; (at your option) any later version.
    ;;
    ;; PBIBox is distributed in the hope that it will be useful,
    ;; but WITHOUT ANY WARRANTY; without even the implied warranty of
    ;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    ;; GNU General Public License for more details.
    ;;
    ;; You should have received a copy of the GNU General Public License
    ;; along with PBIBox.  If not, see <http://www.gnu.org/licenses/>.
    ;;

    ;; Include this file to put the bit tables into the current segment.
    ;; The tables are as described.

    ;
    ; Netmask/Hostmask tables.
    ;
    ; Find a byte starting in the fourth row of either
    ; table and read that byte plus the three bytes *above* it
    ; to get the mask bits.
    ;
    ; To get the netmask for each byte, put the netmask bits in X and do:
    ; (for byte 0): lda NETMASK_TABLE,x         lda HOSTMASK_TABLE,x
    ; (for byte 1): lda NETMASK_TABLE-8,x       lda HOSTMASK_TABLE-8,x
    ; (for byte 2): lda NETMASK_TABLE-16,x      lda HOSTMASK_TABLE-16,x
    ; (for byte 3): lda NETMASK_TABLE-24,x      lda HOSTMASK_TABLE-24,x
    ;
    ; To get the broadcast address, use ORA against HOSTMASK_TABLE.
    ; To get the network address, use AND against NETMASK_TABLE.
    ;
    ; Note: don't let this cross a page boundary else there will
    ; be a one-cycle penalty...
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00
NETMASK_TABLE:
    .byte $00, $80, $C0, $E0, $F0, $F8, $FC, $FE
    ; These bytes are duplicated in the next table, so
    ; just merge the tables...
    ;.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    ;.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    ;.byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    ;.byte $FF
    .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
    .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF
HOSTMASK_TABLE:
    .byte $FF, $7F, $3F, $1F, $0F, $07, $03, $01
    .byte $00
    ; These bytes are duplicated in the next table, so
    ; just merge the tables...
    ;.byte $00, $00, $00, $00, $00, $00, $00, $00
    ;.byte $00, $00, $00, $00, $00, $00, $00, $00
    ;.byte $00, $00, $00, $00, $00, $00, $00, $00

    ;
    ; Bit index table.
    ;
    ; If the bit index is in X, get the corresponding bit via:
    ; lda BIT_TABLE,x       ; for byte 0
    ; lda BIT_TABLE-8,x     ; for byte 1
    ; lda BIT_TABLE-16,x    ; for byte 2
    ; lda BIT_TABLE-24,x    ; for byte 3
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00
BIT_TABLE:
    .byte $01, $02, $04, $08, $10, $20, $40, $80
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00
    .byte $00, $00, $00, $00, $00, $00, $00, $00
