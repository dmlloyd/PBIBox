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

    .segment "SOCKET"

SOCK_SELECT_PORT:
    asl
    asl
    asl
    asl
    sta t1
    lda SEED
    eor RANDOM
    sta SEED
    bne @tcp
@try:
    jsr DO_RANDOM_PORT
    ldy #7
@next:
    sta W5300_BANK_SOCK,y
    lda W5300_REG_SOCK_SSR
    and #$F0
    cmp t1    ; UDP?
    beq @check_port
    dey
    bpl @next
    rts
@check_port:
    lda W5300_REG_SOCK_PORTR
    cmp PORT1
    lda W5300_REG_SOCK_PORTR+1
    sbc PORT1+1
    beq @try
    bne @next
    ; not reached

DO_RANDOM_PORT:
    jsr RANDOM_BYTE
    ; Random ports are $8000-$FFFF
    ora #$80
    sta PORT1
    jsr RANDOM_BYTE
    sta PORT1+1
    rts

RANDOM_BYTE:
    ; Use Lee Davidson's PRNG code.  http://members.lycos.co.uk/leeedavison/6502/code/prng.html
    lda SEED
    and #$B8
    ldx #$05
    ldy #$00
@f_loop:
    asl
    bcc @bit_clr
    iny
@bit_clr:
    dex
    bne @f_loop
@no_clr:
    tya
    lsr
    lda SEED
    rol
    sta SEED
    rts

SOCK_OPEN:
    pha
    cmp #$03
    bcs @got_port   ; not TCP/UDP so port doesn't matter
    lda PORT1
    bne @got_port
    lda PORT1+1
    bne @got_port
    jsr SOCK_SELECT_PORT
@got_port:
    ldy #7
@next:
    sta W5300_BANK_SOCK,y
    lda W5300_REG_SOCK_SSR
    beq DO_OPEN_CURRENT
    dey
    bpl @next
    pla
    ldy #ENFILE
    rts
DO_OPEN_CURRENT:
    pla
    cmp #$03
    bcs @skip_port
    ldy PORT1
    sty W5300_REG_SOCK_PORTR
    ldy PORT1+1
    sty W5300_REG_SOCK_PORTR+1
@skip_port:
    cmp #$01    ; TCP?
    beq @tcp_mod
    ora #%01000000
    bne @cont   ; always true
@tcp_mod:
    ora #%01100000
@cont:
    sta W5300_REG_SOCK_MR
    lda #$01    ; open socket
    sta W5300_REG_SOCK_CR
    ; N flag is clear from lda
    rts

SOCK_OPEN_CURRENT:
    pha
    lda W5300_REG_SOCK_SSR
    beq DO_OPEN_CURRENT
    ldy #EISOPEN
    rts

SOCK_CLOSE:
    sta W5300_BANK_SOCK,y
SOCK_CLOSE_CURRENT:
    lda #$10    ; close socket
    sta W5300_REG_SOCK_CR
    rts

SOCK_WRITE:
    ldy #0
    ldx BFENHI
    beq @lastpage
@loop1:
    lda (BUFRHI),y
    sta W5300_REG_SOCK_TX_FIFOR0
    iny
    lda (BUFRHI),y
    sta W5300_REG_SOCK_TX_FIFOR1
    iny
    bne @loop1
    dex
    bne @loop1
    tya
    tax
    bne @lastpage
    rts
@lastpage:
    lda (BUFRHI),y
    sta W5300_REG_SOCK_TX_FIFOR0
    iny
    dex
    bne @odd
    stx W5300_REG_SOCK_TX_FIFOR1    ; == stz
    rts
@odd:
    lda (BUFRHI),y
    sta W5300_REG_SOCK_TX_FIFOR0
    iny
    dex
    bne @lastpage
    rts

SOCK_READ:
    ldy #0
    ldx BFENHI
    beq @lastpage
@loop1:
    lda W5300_REG_SOCK_RX_FIFOR0
    sta (BUFRHI),y
    iny
    lda W5300_REG_SOCK_RX_FIFOR1
    sta (BUFRHI),y
    iny
    bne @loop1
    dex
    bne @loop1
    tya
    tax
    bne @lastpage
    rts
@lastpage:
    lda W5300_REG_SOCK_RX_FIFOR0
    sta (BUFRHI),y
    iny
    dex
    bne @odd
    bit W5300_REG_SOCK_RX_FIFOR1    ; consume odd byte
    rts
@odd:
    lda W5300_REG_SOCK_TX_FIFOR0
    sta (BUFRHI),y
    iny
    dex
    bne @lastpage
    rts
