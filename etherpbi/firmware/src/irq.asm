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

    .segment "IRQ"


    ;
    ; Handle IRQ.
    ;
    ; In:   IRQ context
    ;       A saved on stack
    ;       D flag = clear
    ;       I flag = set
    ; Out:  PLA + RTI
    ;
IRQ:
    txa
    pha
    tya
    pha



    pla
    tay
    pla
    tax
    pla
    rti

