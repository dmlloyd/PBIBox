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


    ;
    ; Protocol
    ;
    ; Byte 0 - Message Type - $50 = COMMAND
    ; Byte 1 - Request ID
    ; Byte 2 - SIO Device ID + unit # (DDEVIC + DUNIT - 1)
    ; Byte 3 - SIO Command (DCOMND)
    ; Byte 4 - SIO Flags (DSTATS)   |W|R|0|0|0|0|0|0|  W = Send data present, R = Received data expected
    ; Byte 5 - SIO Timeout in 64 frames (DTIMLO)
    ; Byte 6 - SIO Aux1
    ; Byte 7 - SIO Aux2
    ; Byte 8 - SIO Aux3 (TIMER1)
    ; Byte 9 - SIO Aux4 (TIMER1+1)
    ; Byte 10 - Unused (0)
    ; Byte 11 - SIO UNUSE (KMK Aux3)
    ; Byte 12 - SIO Expected Reply length H (if R is set, else 0)
    ; Byte 13 - SIO Expected Reply length L (if R is set, else 0)
    ; Byte 14+ - Data (if any)
    ;
    ; Byte 0 - Message Type - $51 = COMMAND COMPLETE
    ; Byte 1 - Request ID
    ; Byte 2 - Request Status 'N' = NAK, 'C' = Complete, 'E' = Error
    ; Byte 3 - Reserved (0)
    ; Byte 4+ - Data (if any)
    ;
    ; Read (e.g. sector)
    ; 1) CLIENT send COMMAND $52 (READ)
    ; 2) SERVER receive COMMAND
    ; 3) SERVER send COMMAND COMPLETE status 'C', data is sector data (128, 256, 512, 1024 bytes)
    ; 4) CLIENT receive COMMAND COMPLETE
    ;
    ; Write (w/ or w/o verify)
    ; 1) CLIENT send COMMAND $57 or $50 (WRITE), data is sector data (N bytes)
    ; 2) SERVER receive COMMAND
    ; 3) SERVER send COMMAND COMPLETE status 'C', no data
    ; 4) CLIENT receive COMMAND COMPLETE
    ;

    SIOUDP_PORT = $1983

    .include "etherpbi.inc"
    .include "w5300.inc"
    .include "sysequ.inc"
    .include "sock.inc"
    .include "regs.inc"

    .segment "SIOUDP"

    .org $DC00
    php
    sei
    lda #0
    sta PORT1
    sta PORT1+1
    lda #$02    ; UDP
    jsr SOCK_OPEN
    bpl @ok
    ; error, exit
    plp
    clc     ; we handled it
    rts

@ok:
    jsr DO_CALC_TIMEOUT
    lda #<@timeout_expired
    sta CDTMA1
    lda #>@timeout_expired
    sta CDTMA1+1
    lda #1 ; timer 1
    jsr SETVBV

    lda #0
    sta TIMFLG ; this is our "timed out" flag - bit 6 = resend due, bit 7 = timeout
    ldx #0
    ldy #1 ; initial timeout
    sty t3
    lda #<@resend_expired
    sta CDTMA2
    lda #>@resend_expired
    sta CDTMA2+1

@resend:
    lda #2 ; timer 2
    jsr SETVBV
    jsr DO_SEND_COMMAND

    ; Poll for reply-or-timeout.
@poll:
    ldx W5300_REG_SOCK_RSR0
    bne @receive
    bit TIMFLG
    bmi @timeout
    bvc @poll
    ; resend due... re-arm timer
    ldx #0
    stx TIMFLG  ; clear resend flag
    lda t3
    lsr
    bcc @poll_next
    lda #$80

@poll_next:
    sta t3
    tay
    bne @resend     ; always
    ; not reached

@timeout:
    jsr SOCK_CLOSE_CURRENT
    plp
    ldy #ETIMOUT
    clc
    rts

@receive:
    ; todo - extract DEST IP for status info?
    lda W5300_REG_SOCK_RX_FIFOR0
    lda W5300_REG_SOCK_RX_FIFOR1
    lda W5300_REG_SOCK_RX_FIFOR0
    lda W5300_REG_SOCK_RX_FIFOR1
    ; todo - extract DEST PORT
    lda W5300_REG_SOCK_RX_FIFOR0
    lda W5300_REG_SOCK_RX_FIFOR1
    ; extract length (MSB first)
    lda W5300_REG_SOCK_RX_FIFOR0
    sta BFENHI
    lda W5300_REG_SOCK_RX_FIFOR1
    sta BFENLO
    cmp #4
    lda BFENHI
    sbc #0
    bcc @skip_packet    ; Runt - less than 4 bytes

    ; Check first byte - if it's not COMMAND_COMPLETE, skip it
    lda W5300_REG_SOCK_RX_FIFOR0
    ldx W5300_REG_SOCK_RX_FIFOR1 ; grab request ID too...
    cmp #$51
    beq @recv_command_complete

@skip_packet:
    lda #$40    ; RECV
    sta W5300_REG_SOCK_CR
    bne @poll   ; always

@recv_command_complete:
    cpx t4  ; our request ID
    bne @skip_packet ; not our request
    lda W5300_REG_SOCK_RX_FIFOR0 ; request status
    bit W5300_REG_SOCK_RX_FIFOR1 ; consume byte
    cmp #'N'
    bne @check_complete

@nak:
    ldy #EDNACK
    sty DSTATS
    bne @recv_done

@check_complete:
    cmp #'C'
    beq @recv_reply
    ldy #EDERROR
    sty DSTATS
    bne @recv_done    ; always

@recv_reply:
    ; first test DSTATS to see whether we ignore the incoming data
    bit DSTATS
    bvc @recv_ok

@read_reply_data:
    sec
    ; subtract header...
    lda BFENLO
    sbc #$04
    sta BFENLO
    lda BFENHI
    sbc #$00
    sta BFENHI
    beq @recv_done
    ; load data into buffer
    lda DBUFHI
    sta BUFRHI
    lda DBUFLO
    sta BUFRLO
    ; compare user buffer to remaining packet
    ; if user buffer is smaller, use that length instead
    lda DBYTLO
    cmp BFENLO
    lda DBYTHI
    sbc BFENHI
    bcs @do_read ; DBYT* >= BFEN*
    ; DBYT* < BFEN*, truncate
    lda DBYTLO
    sta BFENLO
    lda DBYTHI
    sta BFENHI
@do_read:
    ; read the data
    jsr SOCK_READ
    ; report the bytes read
    lda BFENLO
    sta DBYTLO
    lda BFENHI
    sta DBYTHI

@recv_ok:
    ldy #1
    sty DSTATS

@recv_done:
    lda #$40    ; RECV
    sta W5300_REG_SOCK_CR
    ldx #0
    ldy #0
    lda #1
    jsr SETVBV  ; disable timer
    ldx #0
    ldy #0
    lda #2
    jsr SETVBV  ; disable timer

@done:
    jsr SOCK_CLOSE_CURRENT
    plp
    ldy DSTATS
    clc
    rts

@timeout_expired:
    lda TIMFLG
    ora #%10000000
    sta TIMFLG

@rts:
    rts

@resend_expired:
    lda TIMFLG
    ora #%01000000
    sta TIMFLG
    rts

    ; Return timeout in frames in X (high) and Y (low)
DO_CALC_TIMEOUT:
    lda DTIMLO
    ror
    ror
    tay
    and #%00111111
    tax ; high
    tya
    ror
    and #%11000000
    tay ; low
    rts

DO_SEND_COMMAND:
    ; set DHAR to FF:FF:FF:FF:FF:FF (broadcast)
    lda #$FF
    ldx #0

@dhar_next:
    sta W5300_REG_SOCK_DHAR,x
    inx
    cpx #6
    bne @dhar_next
    ; set DIPR to 255.255.255.255 (broadcast)
    ldx #4

@dipr_next:
    sta W5300_REG_SOCK_DIPR,x
    inx
    cpx #4
    bne @dipr_next
    ; set DPORTR to SIOUDP_PORT
    lda #>SIOUDP_PORT
    sta W5300_REG_SOCK_DPORTR
    lda #<SIOUDP_PORT
    sta W5300_REG_SOCK_DPORTR+1
    ; write SIO header
    lda #$50    ; COMMAND
    sta W5300_REG_SOCK_TX_FIFOR0
    jsr RANDOM_BYTE ; request ID
    sta t4
    sta W5300_REG_SOCK_TX_FIFOR1
    lda DDEVIC
    clc
    adc DUNIT
    adc #$FF
    sta W5300_REG_SOCK_TX_FIFOR0
    lda DCOMND
    sta W5300_REG_SOCK_TX_FIFOR1
    lda DSTATS
    and #%11000000
    sta W5300_REG_SOCK_TX_FIFOR0
    lda DTIMLO
    sta W5300_REG_SOCK_TX_FIFOR1
    lda DAUX1
    sta W5300_REG_SOCK_TX_FIFOR0
    lda DAUX2
    sta W5300_REG_SOCK_TX_FIFOR1
    lda DAUX3
    sta W5300_REG_SOCK_TX_FIFOR0
    lda DAUX4
    sta W5300_REG_SOCK_TX_FIFOR1
    lda #0
    sta W5300_REG_SOCK_TX_FIFOR0
    lda DAUXH
    sta W5300_REG_SOCK_TX_FIFOR1
    bit DSTATS
    bvc @write_zeros
    lda DBYTHI
    sta W5300_REG_SOCK_TX_FIFOR0
    lda DBYTLO
    sta W5300_REG_SOCK_TX_FIFOR1
    bvs @write_payload  ; always

@write_zeros:
    lda #0
    sta W5300_REG_SOCK_TX_FIFOR0
    sta W5300_REG_SOCK_TX_FIFOR1

@write_payload:
    ; now, the data payload (if any)
    bit DSTATS
    bpl @no_data
    ; todo - check buffer length against socket buffer size
    ; Copy buffer addr and length to ZP locations BUFRHI/LO/BFENHI/LO
    lda DBUFHI
    sta BUFRHI
    lda DBUFLO
    sta BUFRLO
    lda DBYTHI
    sta BFENHI
    lda DBYTLO
    sta BFENLO
    ; write data
    jsr SOCK_WRITE

@done_write:
    ; write packet length
    lda #0
    sta W5300_REG_SOCK_WRSR0
    clc
    lda DBYTLO
    adc #$08    ; header length
    tax         ; stash low byte in X
    lda DBYTHI
    adc #$00    ; add in carry flag
    sta W5300_REG_SOCK_WRSR1
    stx W5300_REG_SOCK_WRSR2

@no_data:
    ; execute send
    lda #$21    ; SEND_MAC
    sta W5300_REG_SOCK_CR
    rts
