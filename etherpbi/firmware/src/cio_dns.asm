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

.include "firmware.inc"
.include "sysequ.inc"

.segment "CIO_DNS"

.scope CIO
.scope DNS

    ;
    ; Resolve the host name in the ZIOCB buffer using the currently-selected (closed) socket.
    ;
    .proc RESOLVE
        lda W5300::SOCK::SSR
        ; cmp #W5300::SOCK::SSR::CLOSED == 0
        beq start
    derror:
        ldy #EDERROR
        rts

    start:
        ; get DNS host
        lda RAM::CONFIG::DNS
        sta W5300::SOCK::DIPR
        lda RAM::CONFIG::DNS+1
        sta W5300::SOCK::DIPR+1
        lda RAM::CONFIG::DNS+2
        sta W5300::SOCK::DIPR+2
        lda RAM::CONFIG::DNS+3
        sta W5300::SOCK::DIPR+3

        ; DNS on port 53 (network order)
        lda #0
        sta W5300::SOCK::DPORTR
        lda #53
        sta W5300::SOCK::DPORTR+1

        ; source port
        ; todo: select random source port routine
        ; choose a source port between 32768-65535 incl.; low three bits match socket # to avoid conflict
        lda SYS::RANDOM
        ora #%10000000
        sta W5300::SOCK::SIPR ;high byte first
        lda SYS::RANDOM
        and #%11111000
        ora RAM::IOCB::SOCK
        sta W5300::SOCK::SIPR+1 ;low byte

        ; open the socket

        lda #W5300::SOCK::PROT::UDP
        sta W5300::SOCK::MR1
        lda #W5300::SOCK::CMD::OPEN
        sta W5300::SOCK::CR

        ; write the DNS request

        ; id # (hi)
        lda SYS::RANDOM
        sta RAM::DNS::ID
        sta W5300::SOCK::RX::FIFOR
        lda SYS::RANDOM
        sta RAM::DNS::ID+1
        sta W5300::SOCK::RX::FIFOR+1
        ; recursion
        lda #%10000000
        sta W5300::SOCK::RX::FIFOR
        ldy #0
        sty W5300::SOCK::RX::FIFOR+1
        ; one record
        lda #1
        sta W5300::SOCK::RX::FIFOR
        sty W5300::SOCK::RX::FIFOR+1
        ; zeros
        sty W5300::SOCK::RX::FIFOR
        sty W5300::SOCK::RX::FIFOR+1
        sty W5300::SOCK::RX::FIFOR
        sty W5300::SOCK::RX::FIFOR+1
        sty W5300::SOCK::RX::FIFOR
        sty W5300::SOCK::RX::FIFOR+1
        ; length of host name
        sec
        lda SYS::ICBLLZ


    .endproc ; RESOLVE

.endscope ; DNS
.endscope ; CIO
