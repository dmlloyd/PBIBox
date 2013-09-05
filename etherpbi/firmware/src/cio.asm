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

    .segment "CIO"

    DEV_BANK = $DC00
    DEV_OPENV = DEV_BANK + 0
    DEV_CLOSEV = DEV_BANK + 2
    DEV_READV = DEV_BANK + 4
    DEV_WRITEV = DEV_BANK + 6
    DEV_STATUSV = DEV_BANK + 8
    DEV_SPECIAL_TAB = DEV_BANK + 10

    ; Select the bank to use.
    ;
    ; In:  ZIOCB = populated
    ;
    ; Out: Handler bank selected
    ;      X = IOCB #
    ;      ZIOCB = populated
    ;      Flags = N Z C I D V
    ;              0 0 - - - -
    ;
    ; Err: Calling subroutine is exited
    ;      Y = ENONDEV
    ;      Flags = N Z C I D V
    ;              1 0 0 - - -
    ;
DO_SELECT:
    ; Save original SP in ICSRPZ
    tsx
    ; minus caller
    inx
    inx
    stx ICSPRZ
    ; Save accumulator in X
    tax
    ; First locate the device name
    ldy ICHIDZ
    lda HATABS,y
    tay
    lda CIO_MAP,y
    bne @ok
    ; FAR return
    ldx ICSPRZ
    txs
    ldy #ENONDEV
    sec
    rts
@ok:
    tay
    ; Select the correct bank
    sta CIO_BANK,y
    txa
    ; Restore IOCB # to X
    ldx ICIDNO
    rts

RTSX:
    rts

CIO_OPEN:
    jsr DO_SELECT
    jmp (DEV_OPENV)

CIO_CLOSE:
    jsr DO_SELECT
    jmp (DEV_CLOSEV)

CIO_READ:
    jsr DO_SELECT
    jmp (DEV_READV)

CIO_WRITE:
    jsr DO_SELECT
    jmp (DEV_WRITEV)

CIO_STATUS:
    jsr DO_SELECT
    jmp (DEV_STATUSV)

CIO_SPECIAL:
    jsr DO_SELECT
    ldy #0
@loop:
    lda DEV_SPECIAL_TAB,y
    beq @nomatch
    cmp ICCOMZ
    beq @match
    iny
    iny
    iny
    bne @loop
    ; UNLIKELY to be reached, unless a handler table is buggy (no terminating 0)
@nomatch:
    ldy #EBADXIO
    rts
@match:
    ; Jump to vector
    lda DEV_SPECIAL_TAB+2,y
    pha
    lda DEV_SPECIAL_TAB+1,y
    pha
    rts
