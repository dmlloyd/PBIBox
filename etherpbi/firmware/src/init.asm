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

.segment "INIT"

; One-time init code

.scope INIT

;=============================================================================================================

    .proc INIT
        ; First, find the E: device, if any
        lda #0
    loop:
        lda SYS::HATABS,x
        bne notfound
        cmp #'E'
        beq found
        inx
        inx
        inx
        cpx #35
        bne loop

    notfound:
        jmp skipprint

    found:
        ; copy the handler address into ICSPRZ
        lda SYS::HATABS+1,x
        sta SYS::ICSPRZ
        lda SYS::HATABS+2,x
        sta SYS::ICSPRZ+1
        ; get the 6th and 7th bytes (put char) and put into RAM PUTB vector
        ldy #6
        lda (SYS::ICSPRZ),y
        sta RAM::PUTB
        iny
        lda (SYS::ICSPRZ),y
        sta RAM::PUTB+1
        ; now add 1 to it to make it JMPable
        inc RAM::PUTB
        bne skip_inc
        inc RAM::PUTB+1

    skip_inc:

        ; now print greeting msg
        jsr PRINTLINE
        .byte "EtherPBI v0.0.0 (c) 2013 David M. Lloyd", 155



    skipprint:
        sec
        rts
    .endproc ; INIT

;=============================================================================================================

    ; print character in accumulator
    .proc PRINTCH
        jmp (RAM::PUTB)
    .endproc

;=============================================================================================================

    .proc PRINTLINE
        pla                 ; low return address
        sta SYS::ICSPRZ
        pla                 ; high return address
        sta SYS::ICSPRZ+1

        ldy #0
        inc SYS::ICSPRZ
        bne skip1
        inc SYS::ICSPRZ+1

    skip1:

        jmp (SYS::ICSPRZ)   ; return manually


    .endproc ; PRINTLINE

;=============================================================================================================

.endscope ; INIT

