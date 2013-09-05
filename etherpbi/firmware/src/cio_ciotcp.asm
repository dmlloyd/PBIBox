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

    ;
    ; Client->Server Protocol
    ;
    ; PROTO:
    ;       OPEN CMDS
    ;
    ; OPEN:
    ;       DeviceName(1) UnitNumber(1) AuxBytes(6) BufLen(2) Buf(n) ReceiveSpecialInfo(0)
    ;
    ; CMDS:
    ;       CMD CMDS
    ;     | Eof(end-of-input)
    ;
    ; CMD:
    ;       DeviceName(1) UnitNumber(1) AuxBytes(6)
    ; ---
    ; Server->Client Messages:
    ;
    ; SPECIAL_INFO:
    ;       Count(1) SPECIAL_CMD_INFO(n)
    ;
    ; SPECIAL_CMD_INFO:
    ;       Command(1) Flags(1)
    ;
    ; ---
    ; DeviceName(1): the one-byte ATASCII device name
    ; UnitNumber(1): the one-byte unit # (1-9)
    ; AuxBytes(6): the six aux bytes
    ; BufLen(2): the length of incoming buffer data
    ; Buf(n): the buffer data
    ; ReceiveSpecialInfo(0): wait to receive SPECIAL_INFO from the server
    ; Eof: physical end-of-input from client
    ;
