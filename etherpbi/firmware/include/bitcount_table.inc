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

    ;; Include this file to put a bitcount table into the current segment.
    ;; The bitcount table is called "BITCOUNT_TABLE" and will be aligned to a page boundary

    .align $100

BITCOUNT_TABLE:
    .byte $00, $01, $01, $02, $01, $02, $02, $03
    .byte $01, $02, $02, $03, $02, $03, $03, $04
    .byte $01, $02, $02, $03, $02, $03, $03, $04
    .byte $02, $03, $03, $04, $03, $04, $04, $05
    .byte $01, $02, $02, $03, $02, $03, $03, $04
    .byte $02, $03, $03, $04, $03, $04, $04, $05
    .byte $02, $03, $03, $04, $03, $04, $04, $05
    .byte $03, $04, $04, $05, $04, $05, $05, $06
    .byte $01, $02, $02, $03, $02, $03, $03, $04
    .byte $02, $03, $03, $04, $03, $04, $04, $05
    .byte $02, $03, $03, $04, $03, $04, $04, $05
    .byte $03, $04, $04, $05, $04, $05, $05, $06
    .byte $02, $03, $03, $04, $03, $04, $04, $05
    .byte $03, $04, $04, $05, $04, $05, $05, $06
    .byte $03, $04, $04, $05, $04, $05, $05, $06
    .byte $04, $05, $05, $06, $05, $06, $06, $07
    .byte $01, $02, $02, $03, $02, $03, $03, $04
    .byte $02, $03, $03, $04, $03, $04, $04, $05
    .byte $02, $03, $03, $04, $03, $04, $04, $05
    .byte $03, $04, $04, $05, $04, $05, $05, $06
    .byte $02, $03, $03, $04, $03, $04, $04, $05
    .byte $03, $04, $04, $05, $04, $05, $05, $06
    .byte $03, $04, $04, $05, $04, $05, $05, $06
    .byte $04, $05, $05, $06, $05, $06, $06, $07
    .byte $02, $03, $03, $04, $03, $04, $04, $05
    .byte $03, $04, $04, $05, $04, $05, $05, $06
    .byte $03, $04, $04, $05, $04, $05, $05, $06
    .byte $04, $05, $05, $06, $05, $06, $06, $07
    .byte $03, $04, $04, $05, $04, $05, $05, $06
    .byte $04, $05, $05, $06, $05, $06, $06, $07
    .byte $04, $05, $05, $06, $05, $06, $06, $07
    .byte $05, $06, $06, $07, $06, $07, $07, $08
