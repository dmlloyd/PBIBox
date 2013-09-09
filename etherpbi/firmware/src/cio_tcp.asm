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

    .segment "CIO_TCP"

    ; CIO N: operations
    ;   Open types:
    ;     TCP socket:
    ;       unbound:
    ;         OPEN #1,12,0,"T:"
    ;       bound, random src port, unconnected:
    ;         OPEN #1,12,0,"T:":REM CREATE
    ;         XIO 48,#1,0,0,"":REM BIND TO RANDOM PORT
    ;       bound & connected, random src port:
    ;         OPEN #1,12,0,"T:WWW.FLURG.COM:80"
    ;         OPEN #1,12,0,"T:!";CHR$(192);CHR$(168);CHR$(0);CHR$(1);CHR$(0);CHR$(80):REM 192.168.1.1:80
    ;       bound & connected, specified src port:
    ;         OPEN #1,12,0,"T:":REM CREATE
    ;         XIO 48,#1,4,210,"":REM BIND TO SRC PORT (1234 = 4*256+210)
    ;         XIO 49,#1,0,0,"T:WWW.FLURG.COM:80":REM CONNECT
    ;       existing socket attach:
    ;         OPEN #1,4+8+16,ID,"T:"
    ;       server:
    ;         OPEN #1,0,0,"T:":REM CREATE LISTENER
    ;         XIO 48,#1,0,0,"T:80":REM BIND
    ;         XIO 50,#1,0,2,"T:":REM LISTEN, BACKLOG OF 2
    ;         OPEN #2,28,1,"T:":REM ACCEPT FROM #1
    ;         XIO 38,#2,208,ASC("?"),"T:":REM TRANSLATE
    ;         PRINT #2;"HTTP/1.0 200 OK"
    ;         PRINT #2;"Content-Type: text/html"
    ;         PRINT #2;""
    ;         PRINT #2;"<html><body>TEST!</body></html>"
    ;         CLOSE #2


    ; OPEN TCP
    ;   ICAX1 values:
    ;     bit 0: 0
    ;     bit 1: 0
    ;     bit 2: Read
    ;     bit 3: Write
    ;     bit 4: Accept (listener IOCB specified in AX2)
    ;     bit 5: Non-blocking Read/Accept Mode
    ;     bit 6: Non-blocking Write Mode
    ;   ICAX2 = IOCB of server socket to accept from
    ;

    ; State variables:
    ;   ICAX5 = copy of original ICAX1
    ;   ICAX6 = state
    ;       $00 = unbound
    ;       $1x = bound on socket x
    ;       $2x = listening on socket x
    ;       $3x = connect-mode on socket x



TCP_BANK:
    .org $DC00

    ;
    ; Main command vector table
    ;
    .word TCP_OPEN
    .word TCP_CLOSE
    .word TCP_READ
    .word TCP_WRITE
    .word TCP_STATUS
    ;
    ; Special command ID table, first entry is cmd $0E
    ;
    .byte $26
    .word TCP_TRANSLATE - 1

    .byte $30
    .word TCP_BIND - 1

    .byte $31
    .word TCP_CONNECT - 1

    .byte $32
    .word TCP_LISTEN - 1

    .byte $00 ; end of table

IDX_TAB:
    .byte $00, $10, $20, $30, $40, $50, $60, $70

    ; Overall status
    SOCK_STATE = PIAUX1
    .enum
        S_OPEN = 0
        S_BOUND
        S_LISTENING
        S_CONNECTED
    .endenum

    ; Socket bank # for connected sockets
    SOCK_IDX = PIAUX2

    ; Read/write state for connected sockets
    SOCK_READ_STATE = PIAUX3
    .enum
        RS_INIT = 0
        RS_READING
        RS_GOTCR
        RS_ODD
        RS_GOTCRODD
    .endenum

    SOCK_WRITE_STATE = PIAUX4
    .enum
        WS_INIT = 0

    .endenum

    ;
    ; TCP_OPEN - Open a TCP channel
    ;
    ; In:   ZIOCB populated, X = IOCB index * 16
    ; Out:  Carry = 1, Y reg. = status (1 = ok), N flag = 1 for error
    ;
TCP_OPEN:
    lda ICAX1Z
    and #%10000011  ; check for unsupported flags
    beq @no_unsup
@badmode:
    ldy #EBADMOD    ; not supported yet
    sec
    rts
@no_unsup:
    lda ICAX1Z
    and #%00000110  ; READ & WRITE - not valid to open TCP otherwise
    cmp #%00000110
    bne @badmode
    lda ICAX1Z
    and #%00010000
    beq @noaccept
    ; Accept a connection immediately
    ldy ICAX2Z      ; Get the server socket IOCB from AUX2
    cpy #8
    bcs @badmode    ; IOCB # must be less than 8
    lda IDX_TAB,y   ; multiply by 16 to get canonical index
    tay
    lda ICHID,y     ; Get its handler ID
    cmp ICHIDZ      ; Compare against ours
    bne @badmode    ; Not our IOCB, can't accept from it
    lda PIBANK,y    ; Get the CIO handler bank for that IOCB
    cmp PIBANK,x    ; Compare it to ours (TCP device driver)
    bne @badmode    ; It's got our handler ID, but it's not the right handler type (somehow)
    ; TODO complete ACCEPT code...
    ldy #EBADXIO
    sec
    rts

@noaccept:
    ; it's not an accept
    lda ICAX1Z
    and #%11101111
    sta PIOAUX1,x   ; cache original ICAX1 (minus accept flag)

    lda #S_OPEN
    sta SOCK_STATE,x
    lda #RS_INIT
    sta SOCK_READ_STATE,x
    lda #WS_INIT
    sta SOCK_WRITE_STATE,x


    ; Find an unused socket
    ldy #0

@try:
    sta W5300_BANK_SOCK,y
    lda W5300_REG_SOCK_SSR
    beq @found
    iny
    cpy #8
    bne @try
    ldy #ENFILE
    sec
    rts

@found:
    ; Store socket number in aux5
    tya
    sta ICAX5,x

    ; Connect?
    ; first - skip handler name byte
    ldy #1
    ; check byte, should be [DIGITS] ':'
@next:
    lda (ICBAHZ),y
    iny
    beq @bad_name
    cmp #':'
    beq @parse_host
    ; is it a 0-9?  if so, allow (and ignore) it
    bcs @bad_name   ; 9 = ':' - 1, so if A > ':', fail
    cmp #'0'
    bcs @next       ; if A < '0', fail
@bad_name:
    ldy #EBADNAM
    sec
    rts
@parse_host:
    ; Update ICBALZ/ICBAHZ to point at the start of the host name
    tya
    clc
    adc ICBALZ
    sta ICBALZ
    inc ICBAHZ
    ldy #0
    lda (ICBAHZ),y
    cmp #155    ; EOL?
    beq @just_open  ; no host name, just open
@next_host_char:
    iny
    beq @bad_name   ; host name too long
    lda (ICBAHZ),y
    cmp #155    ; EOL?
    beq @bad_name   ; need a port # too
    cmp #':'
    bne @next_host_char
    sty ICBLLZ
    ldy #0
    sty ICBLHZ
    jsr NSLOOKUP    ; put result into IPADDR1 - longjmp return if failed
    ldy ICBLLZ
    iny
    lda (ICBAHZ),y
    cmp #155    ; EOL?
    ; beq ????


@just_open:
    ; Open socket
    lda #0
    sta W5300_REG_SOCK_MR0
    ; TCP, no delayed ACK, MAC Filter
    lda #%01100001
    sta W5300_REG_SOCK_MR1
    ; Open socket
    lda #$01
    sta W5300_REG_SOCK_CR


    lda #CIO_TCP_BANK
    sta PIBANK,x
    rts

FIND_SOCK:
    ldy #0
@check:
    sta W5300_BANK_SOCK,y
    lda W5300_REG_SOCK_SSR
    bne @nope
    lda W5300_REG_SOCK_PORTR0
    bne @nope
    lda W5300_REG_SOCK_PORTR1
    bne @nope
    sty SOCK_IDX
    rts
@nope:
    iny
    cpy #8
    bne @check
    ; longjmp return
    ldx ICSPRZ
    txs
    ldx ICIDNO
    ldy #ENFILE
    rts

DO_BIND_RANDOM:
    jsr FIND_SOCK


    beq DO_BIND_RANDOM

DO_BIND:


TCP_BIND:
    lda SOCK_STATE
    cmp #S_OPEN
    bne BAD_STATE
@do_bind:

    ldy #1
    rts

BAD_STATE:
    ; restore AUX1
    lda PIOAUX1,x
    sta ICAX1Z
    ldy #ESTATE
    sec
    rts

    ; Connect to a remote TCP host.
    ;
    ; In:   Socket state = OPEN or BOUND
    ;       ICBA*Z = host name, EOL terminated
    ; Out:  CIO return
TCP_CONNECT:
    lda SOCK_STATE
    cmp #S_BOUND
    beq @do_connect
    cmp #S_OPEN
    bne BAD_STATE
    ; Need to bind first
    jsr DO_BIND_RANDOM
@do_connect:



TCP_STATUS:

TCP_WRITE:

TCP_READ:

TCP_CLOSE:
