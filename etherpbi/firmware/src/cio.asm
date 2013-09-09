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

.scope CIO

    ; Select the bank to use.
    ;
    ; In:  ZIOCB = populated
    ;
    ; Out: Handler ROM bank selected
    ;      IOCB RAM bank selected
    ;      X = IOCB #
    ;      ZIOCB = populated
    ;      Flags = N Z C I D V
    ;              0 0 0 - - -
    ;
    ; Err: Calling subroutine is exited
    ;      Y = ENONDEV
    ;      Flags = N Z C I D V
    ;              1 0 1 - - -
    ;

    .proc FIND_OPEN
        ; select the RAM IOCB bank
        sta RAM::BANK::IOCB,x
        ; see if the device is open by us
        lda RAM::IOCB::STAT
        bpl FOUND
        sec
        rts
    FOUND:
        ; get the ROM bank to use
        ldy RAM::IOCB::CIO_BANK
        ; select it
        sta ROM::BANK::CIO,y
        ; done
        rts
    .endproc ; FIND_OPEN


    .proc OPEN
        jsr FIND_OPEN
        jmp ROM::

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

.endscope ; CIO
