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

.segment "CIO_N"

;
; N: device base segment
;

.scope CIO
.scope N

    .scope JMPTAB

        OPENV:          jmp OPEN
        CLOSEV:         jmp CLOSE
        READV:          jmp READ
        WRITEV:         jmp WRITE
        STATUSV:        jmp STATUS
        SPECIALV:       jmp SPECIAL

    .endscope

    ; CIO OPEN command for N: TCP subdevice
    ; Entry:
    ;   RAM bank = RAM::BANK::IOCB + X
    ;   X = IOCB index * 16
    ;   SYS::ICHIDZ = 'N' (or something else)
    ;   ZIOCB buffer = ?x:host name:port, ?x:ip string:port, or Nx:
    ; Exit:
    ;   Y = status (1 = ok, 128+ = error)
    ;   C = 1 if handled by us, 0 otherwise
    .proc OPEN
        ; check for "N" device first
        lda SYS::ICHIDZ
        cmp #'N'
        bne wrong_dev

        ; next check to see if it's open in TCP mode; if not, try next handler
        lda SYS::ICAX1Z
        and #%11110000
        bne wrong_dev

        ; next make sure that it's our device, not the next on the chain
        lda SYS::ICDNOZ
        ; if less than 2 aka less-than-or-equal-to 1, it's ours
        cmp #2
        bcc OK
        ; nope, not for us, decrement for the next guy to check
        dec SYS::ICDNOZ

    wrong_dev:
        clc
        rts
    OK:
        ; first, allocate and open a socket


        ; now decide if we need to resolve a host name
        lda SYS::ICBAHZ
        bne RESOLVE
        lda SYS::ICBALZ
        cmp #3 ; if less than 3, no host name was given
        bcs RESOLVE

        ldy #1 ; open
        sec
        rts
    RESOLVE:
        ; resolve a host name / IP address for connect
    CONNECT:
        ; connect
    LISTEN:
        ; listen
    .endproc ; OPEN


.endscope ; N
.endscope ; CIO
