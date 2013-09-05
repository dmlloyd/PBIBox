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
    ; EtherPBI Hardware Description
    ;

    ;; Memory map:
    ;; D100-D1FF (256 bytes): I/O area
    ;;    D100-D17F: Firmware bank 1 select. 1K window, up to 128 banks.
    ;;    D180-D1BF: W5300 access area, 64 bytes
    ;;    D1C0-D1CF: W5300 uses 1K (10 bit) address space, mapped in 16 64-byte (6-bit) pieces.
    ;;        Read/write D1C0 to select bank 0, D1C1 to select bank 1 etc.
    ;;    D1D0-D1D3: Settings bank select
    ;;    D1D4-D1DF: RAM bank select
    ;;    D1E0-D1FE: Unused
    ;;    D1FF: PBI select/interrupt register
    ;; RAM: 8kB SRAM
    ;;    D600-D6FF (256 bytes): Settings bank
    ;;    D700-D7FF (256 bytes): RAM bank
    ;; FLASH memory: CAT28F512 or equivalent
    ;;    D800-DBFF (1024 bytes): PBP Program memory bank 0 (fixed)
    ;;    DC00-DFFF (1024 bytes): PBP Program memory bank 1 (selectable)

    ;; NVRAM map
    ;;
    ;; 00000-003FF: Firmware Bank 0
    ;; 00400-007FF: Firmware Bank 1

    ;; 00800-00FFF: Firmware Bank 1
    ;; 01000-017FF: Firmware Bank 2
    ;; 01800-01FFF: Firmware Bank 3
    ;; 02000-027FF: Firmware Bank 4
    ;; 02800-02FFF: Firmware Bank 5
    ;; 03000-037FF: Firmware Bank 6
    ;; 03800-03FFF: Firmware Bank 7
    ;; 04000-047FF: Firmware Bank 8
    ;; 04800-04FFF: Firmware Bank 9
    ;; 05000-057FF: Firmware Bank 10
    ;; 05800-05FFF: Firmware Bank 11
    ;; 06000-067FF: Firmware Bank 12
    ;; 06800-06FFF: Firmware Bank 13
    ;; 07000-077FF: Firmware Bank 14
    ;; 07800-07FFF: Firmware Bank 15
    ;; 08000-087FF: Firmware Bank 16
    ;; 08800-08FFF: Firmware Bank 17
    ;; 09000-097FF: Firmware Bank 18
    ;; 09800-09FFF: Firmware Bank 19
    ;; 0A000-0A7FF: Firmware Bank 20
    ;; 0A800-0AFFF: Firmware Bank 21
    ;; 0B000-0B7FF: Firmware Bank 22
    ;; 0B800-0BFFF: Firmware Bank 23
    ;; 0C000-0C7FF: Firmware Bank 24
    ;; 0C800-0CFFF: Firmware Bank 25
    ;; 0D000-0D7FF: Firmware Bank 26
    ;; 0D800-0DFFF: Firmware Bank 27
    ;; 0E000-0E7FF: Firmware Bank 28
    ;; 0E800-0EFFF: Firmware Bank 29
    ;; 0F000-0F0FF: Settings Bank 0
    ;; 0F100-0F1FF: Settings Bank 1
    ;; 0F200-0F2FF: Settings Bank 2
    ;; 0F300-0F3FF: Settings Bank 3
    ;; 0F400-0F4FF: RAM Bank 0
    ;; 0F500-0F5FF: RAM Bank 1
    ;; 0F600-0F6FF: RAM Bank 2
    ;; 0F700-0F7FF: RAM Bank 3
    ;; 0F800-0F8FF: RAM Bank 4
    ;; 0F900-0F9FF: RAM Bank 5
    ;; 0FA00-0FAFF: RAM Bank 6
    ;; 0FB00-0FBFF: RAM Bank 7
    ;; 0FC00-0FCFF: RAM Bank 8
    ;; 0FD00-0FDFF: RAM Bank 9
    ;; 0FE00-0FEFF: RAM Bank 10
    ;; 0FF00-0FFFF: RAM Bank 11

    ; W5300 register access area
    W5300_BASE      = $D180

    ; Program bank 1 select
    PROG_BANK       = $D100

    CIO_BANK        = PROG_BANK + 0
    CIO_TCP_BANK    = CIO_BANK + 0
    CIO_UDP_BANK    = CIO_BANK + 1
    CIO_RAWIP_BANK  = CIO_BANK + 2
    CIO_RS232_BANK  = CIO_BANK + 3
    CIO_CIOTCP_BANK = CIO_BANK + 4

    SIO_BANK        = PROG_BANK + 8
    SIO_SIOUDP_BANK = SIO_BANK + 0
    SIO_SIOMAP_BANK = SIO_BANK + 1

    ; W5300 bank select - 16 bytes
    W5300_BANK      = $D1C0

    ; RAM bank select
    RAM_BANK        = $D1E0

    ; PBI Control/Interrupt
    PBI_REG         = $D1FF

    RAM_LO          = $D500
    RAM_HI          = $D600

    ROM_LO          = $D800
    ROM_HI          = $DC00


    ;;
    ;; Bank 0 entry points
    ;;
    .global CIO_OPEN
    .global CIO_CLOSE
    .global CIO_READ
    .global CIO_WRITE
    .global CIO_STATUS
    .global CIO_SPECIAL

    ;;
    ;; Bank N entry points
    ;;
    OPENV           = $DC00
    CLOSEV          = $DC03
    READV           = $DC06
    WRITEV          = $DC09
    STATUSV         = $DC0C
    SPECIALV        = $DC0F

    ;; CIO data

    ; Map of CIO device name to handler #.
    ; Key is any char from 'A' ($40) through 'z' ($7A) (58 bytes).
    CIO_MAP         = RAM_HI
    CIO_PARAM1      = RAM_HI + 64
    CIO_PARAM2      = RAM_HI + 128
    CIO_PARAM3      = RAM_HI + 192
    CIO_PARAM4      = RAM_HI + 256
    CIO_PARAM5      = RAM_HI + 320
    CIO_PARAM6      = RAM_HI + 384
    CIO_PARAM7      = RAM_HI + 448

    ; OPEN RS232
    ;   ICAX1 values:
    ;     bit 0: Concurrent mode emulation
    ;     bit 1: 0
    ;     bit 2: Read
    ;     bit 3: Write
    ;     bit 4-7: 0

    ;; XIO operations

    ; RS232 compat
    XIO_RS232_SPBL  = $20 ; RS232 send partial block

    XIO_RS232_CNTRL = $22 ; RTS,XMT,DTR
    ; ICAX1:
        ; bit 0: force XMT to SPACE (0) or MARK (1)
        ; bit 1: XMT control enable (1 = enabled)
        ; bit 2-3: unused
        ; bit 4: Force RTS value
        ; bit 5: RTS control (1 = force, 0 = default)
        ; bit 6: Force DTR value
        ; bit 7: DTR control (1 = force, 0 = default)
    ; in atari800, turning off DTR drops connection

    XIO_RS232_RATE  = $24 ; Baud rate, stop bits, word size
    ; ICAX1:
        ; bit 0-3: bit rate
        ;   0000 = 300
        ;   0001 = 57600 in emu, 45.5 in 850
        ;   0010 = 50
        ;   0011 = 115200 in emu, 56.875 in 850
        ;   0100 = 75
        ;   0101 = 110
        ;   0110 = 134.5
        ;   0111 = 150
        ;   1000 = 300
        ;   1001 = 600
        ;   1010 = 1200
        ;   1011 = 1800
        ;   1100 = 2400
        ;   1101 = 4800
        ;   1110 = 9600
        ;   1111 = 19200
        ; bit 4-5: word size
        ;   00 = 8 bits
        ;   01 = 7 bits
        ;   10 = 6 bits
        ;   11 = 5 bits
        ; bit 6: in emu, selects 230400 bps
        ; bit 7: stop bits
        ;   0 = 1 stop bit
        ;   1 = 2 stop bits
    ; ICAX2: set concurrent mode handshake line check for DSR/CTS/CD
        ; bit 0: CD
        ; bit 1: CTS
        ; bit 2: DSR
        ; XIO 40 returns ERROR-139 if the named lines are not set

    ; Set translation mode
    XIO_XLATION     = $26 ; Set translation mode
    ; ICAX1:
        ; bits 0-1: RS232 output parity spec (ignored)
        ;   00 = no change
        ;   01 = set to odd
        ;   10 = set to even
        ;   11 = set to one
        ; bits 2-3: RS232 input parity spec (ignored)
        ;   00 = no change
        ;   01 = set to odd
        ;   10 = set to even
        ;   11 = no parity
        ; bit 4: translation mode
        ;   0 = light translation (strip bit 8 and translate 13<->155)
        ;   1 = heavy translation (light + control chars are filtered)
        ; bit 5: translation enable
        ;   0 = enable translation
        ;   1 = disable translation
        ; bit 6: CRLF output mode
        ;   0 = no LF
        ;   1 = append LF after CR
        ; bit 7: LF input mode (unused on R:)
        ;   0 = pass thru
        ;   1 = consume LF after CR
    ; ICAX2:
        ; replacement char for translation

    XIO_CONCURRENT  = $28 ; RS232 concurrent mode start
    ; ICAX1-2: output buffer address $0000 = default
    ; ICAX3-4?: input buffer address $0000 = default

    XIO_BLOCKING    = $2A ; Set blocking mode.
    ; ICAX1:
    ;   bit 0: Input/accept blocking; 0 = blocking, 1 = nonblocking
    ;       * Non-blocking input does not support "READ RECORD"
    ;   bit 1: Output blocking; 0 = blocking, 1 = nonblocking
    ;

    ; Bind to the given IP address.
    ; Text arg format: [xxx.xxx.xxx.xxx[:port]]
    ; Buffer format:
    ;     bytes 0-3: IP address in network order, 0 for *
    ;     bytes 4-5: Port in network order, 0 to select
    XIO_SOCK_BIND   = $30

    ; Connect an unconnected socket to a remote host.
    ; Socket is bound to *:0 if it is not already bound.
    XIO_SOCK_CONN   = $31

    ; Listen on an unconnected socket.
    ; Socket is bound to *:0 if it is not already bound.
    XIO_SOCK_LISTEN = $32

    ; Set iface IP address.
    ; Buffer format:
    ;     bytes 0-3: IP address in network order
    ;     byte 4: Netmask length in bits
    XIO_IP_SET_ADDR = $50

    XIO_IP_SET_GW   = $51

    XIO_MAC_SET_ADDR    = $52

    ; Select on non-blocking IOCB channels.
    ; ICAX1 = IOCB READABLE bit mask.
    ; ICAX2 = IOCB WRITABLE bit mask.
    ; out:
    ; ICAX1 = READABLE channels
    ; ICAX2 = WRITABLE channels
    XIO_SELECT      = $7F

    ; AUX1 codes.
    ; Accept the argument from the filename field in text format rather than from the data buffer.
    ; Not supported for all operations.
    XIO_AX1_TEXT_IN     = $01
    ; Produce output in text format rather than binary.
    ; Not supported for all operations.  Default mode for directories.
    XIO_AX1_TEXT_OUT    = $02

    ;; Dynamically allocated registers.

    .global IPADDR1 ; 4 bytes, big-endian
    .global PORT1   ; 2 bytes, big-endian

    ; PRNG seed
    .global SEED    ; 1 byte

    ; Temp regs
    .global t1
    .global t2
    .global t3
    .global t4

    ; Private IOCB area
    ; (always present)
    .global PIOCB           ; Private IOCB area
    .global PIBANK          ; CIO handler bank (0 = not open)
    .global PIOAUX1         ; Original AUX1 from open

    ; Per-handler usage
    .global PIAUX1
    .global PIAUX2
    .global PIAUX3
    .global PIAUX4
    .global PIAUX5
    .global PIAUX6
    .global PIAUX7
    .global PIAUX8


    ;; Socket API

    ;
    ; RANDOM_BYTE - get a random byte
    ;
    ; In:   SEED = old seed
    ;
    ; Out:  A = SEED = random number
    ;
    .global RANDOM_BYTE

    ;
    ; SOCK_SELECT_PORT - select a random, unused source port #
    ;
    ; In:   A = mode:   $01 = TCP
    ;                   $02 = UDP
    ;
    ; Out:  PORT1 = port #
    ;       t1 = mode << 4
    ;       SEED = updated
    ;
    .global SOCK_SELECT_PORT

    ;
    ; SOCK_OPEN - open a W5300 socket
    ;
    ; In:   A = mode:   $01 = TCP
    ;                   $02 = UDP
    ;                   $03 = Raw IP
    ;                   $04 = Raw MAC
    ;       PORT1 = port # (TCP/UDP only), 0 = select random port
    ;
    ; Out:  Y = Socket ID (0-7)
    ;       Socket bank selected
    ;       N flag clear
    ;
    ; Err:  Y = Error code ENFILE (no socket available)
    ;       N flag set
    ;
    .global SOCK_OPEN

    ;
    ; SOCK_OPEN_CURRENT - open currently selected socket
    ;
    ; In:   A = mode:   $01 = TCP
    ;                   $02 = UDP
    ;                   $03 = Raw IP
    ;                   $04 = Raw MAC
    ;       PORT1 = port # (TCP/UDP only)
    ;
    ; Out:  Y = 1
    ;       N flag clear
    ;
    ; Err:  Y = Error code EISOPEN
    ;       N flag set
    ;
    .global SOCK_OPEN_CURRENT

    ;
    ; SOCK_CLOSE - close a socket
    ;
    ; In:   Y = Socket ID (0-7)
    ;
    ; Out:  Socket bank selected
    ;       Socket closed
    ;
    .global SOCK_CLOSE

    ;
    ; Close the current socket.
    ;
    ; In:   Socket bank selected
    ;
    ; Out:  Socket bank selected
    ;       Socket closed
    ;
    .global SOCK_CLOSE_CURRENT

    ;
    ; Write bytes to the current socket, starting with even byte, padding to word boundary.
    ;
    ; In:   BUFRHI/BUFRLO = buffer address
    ;       BFENHI/BFENLO = buffer length
    ;       Current socket selected
    ;
    ; Out:  Data written, padded to 16 bits
    ;       BUFRHI/BUFRLO = buffer address (unchanged)
    ;       BFENHI/BFENLO = buffer length (unchanged)
    ;       A, X, Y = clobbered
    ;
    .global SOCK_WRITE

    ;
    ; Read bytes from the current socket, starting with the even byte, padding to word boundary.
    ;
    ; In:   BUFRHI/BUFRLO = buffer address
    ;       BFENHI/BFENLO = buffer length
    ;       Current socket selected
    ;
    ; Out:  Data read into buffer, padded to 16 bits
    ;       BUFRHI/BUFRLO = buffer address (unchanged)
    ;       BFENHI/BFENLO = buffer length (unchanged)
    ;       A, X, Y = clobbered
    ;
    .global SOCK_READ

    ;;
    ;; W5300 definitions
    ;;

    ; Bank 0: Init, common regs
    W5300_BANK_COMMON   = W5300_BANK + $0

    ; Mode Register
    W5300_REG_MR0       = W5300_BASE + $00
    W5300_REG_MR1       = W5300_BASE + $01

    ; Interrupt Register
    W5300_REG_IR0       = W5300_BASE + $02
    W5300_REG_IR1       = W5300_BASE + $03

    ; Interrupt Mask Register
    W5300_REG_IMR0      = W5300_BASE + $04
    W5300_REG_IMR1      = W5300_BASE + $05

    ; Source Hardware Address Register
    W5300_REG_SHAR      = W5300_BASE + $08
    W5300_REG_SHAR0     = W5300_REG_SHAR + 0
    W5300_REG_SHAR1     = W5300_REG_SHAR + 1
    W5300_REG_SHAR2     = W5300_REG_SHAR + 2
    W5300_REG_SHAR3     = W5300_REG_SHAR + 3
    W5300_REG_SHAR4     = W5300_REG_SHAR + 4
    W5300_REG_SHAR5     = W5300_REG_SHAR + 5

    ; Gateway Address Register
    W5300_REG_GAR       = W5300_BASE + $10
    W5300_REG_GAR0      = W5300_REG_GAR + 0
    W5300_REG_GAR1      = W5300_REG_GAR + 1
    W5300_REG_GAR2      = W5300_REG_GAR + 2
    W5300_REG_GAR3      = W5300_REG_GAR + 3

    ; Subnet Mask Register
    W5300_REG_SUBR      = W5300_BASE + $14
    W5300_REG_SUBR0     = W5300_REG_SUBR + 0
    W5300_REG_SUBR1     = W5300_REG_SUBR + 1
    W5300_REG_SUBR2     = W5300_REG_SUBR + 2
    W5300_REG_SUBR3     = W5300_REG_SUBR + 3

    ; Source IP Address Register
    W5300_REG_SIPR      = W5300_BASE + $18
    W5300_REG_SIPR0     = W5300_REG_SIPR + 0
    W5300_REG_SIPR1     = W5300_REG_SIPR + 1
    W5300_REG_SIPR2     = W5300_REG_SIPR + 2
    W5300_REG_SIPR3     = W5300_REG_SIPR + 3

    ; Retransmission Timeout Register
    W5300_REG_RTR       = W5300_BASE + $1C
    W5300_REG_RTR0      = W5300_REG_RTR + 0
    W5300_REG_RTR1      = W5300_REG_RTR + 1

    ; Retransmission Retry-count Register
    W5300_REG_RCR       = W5300_BASE + $1F

    ; Transmit memory size register, socket 0-7
    W5300_REG_TMSR      = W5300_BASE + $20
    W5300_REG_TMSR0     = W5300_REG_TMSR + 0
    W5300_REG_TMSR1     = W5300_REG_TMSR + 1
    W5300_REG_TMSR2     = W5300_REG_TMSR + 2
    W5300_REG_TMSR3     = W5300_REG_TMSR + 3
    W5300_REG_TMSR4     = W5300_REG_TMSR + 4
    W5300_REG_TMSR5     = W5300_REG_TMSR + 5
    W5300_REG_TMSR6     = W5300_REG_TMSR + 6
    W5300_REG_TMSR7     = W5300_REG_TMSR + 7

    ; Receive Memory Size Register, socket 0-7
    W5300_REG_RMSR      = W5300_BASE + $28
    W5300_REG_RMSR0     = W5300_REG_RMSR + 0
    W5300_REG_RMSR1     = W5300_REG_RMSR + 1
    W5300_REG_RMSR2     = W5300_REG_RMSR + 2
    W5300_REG_RMSR3     = W5300_REG_RMSR + 3
    W5300_REG_RMSR4     = W5300_REG_RMSR + 4
    W5300_REG_RMSR5     = W5300_REG_RMSR + 5
    W5300_REG_RMSR6     = W5300_REG_RMSR + 6
    W5300_REG_RMSR7     = W5300_REG_RMSR + 7

    ; Memory Block Type Register
    W5300_REG_MTYPER    = W5300_BASE + $30
    W5300_REG_MTYPER0   = W5300_REG_MTYPER + 0
    W5300_REG_MTYPER1   = W5300_REG_MTYPER + 1

    ; PPPoE Authentication Register
    W5300_REG_PATR      = W5300_BASE + $32
    W5300_REG_PATR0     = W5300_REG_PATR + 0
    W5300_REG_PATR1     = W5300_REG_PATR + 1

    ; PPP LCP Request Time Register
    W5300_REG_PTIMER    = W5300_BASE + $37

    ; PPP LCP Magic Number Register
    W5300_REG_PMAGICR   = W5300_BASE + $39

    ; PPP Session ID Register
    W5300_REG_PSIDR     = W5300_BASE + $3C
    W5300_REG_PSIDR0    = W5300_REG_PSIDR + 0
    W5300_REG_PSIDR1    = W5300_REG_PSIDR + 1

    ; START OF BANK 1
    W5300_BANK_PPP      = W5300_BANK + 1

    ; PPP Destination Hardware Address Register
    W5300_REG_PDHAR     = W5300_BASE + $00
    W5300_REG_PDHAR0    = W5300_REG_PDHAR + 0
    W5300_REG_PDHAR1    = W5300_REG_PDHAR + 1
    W5300_REG_PDHAR2    = W5300_REG_PDHAR + 2
    W5300_REG_PDHAR3    = W5300_REG_PDHAR + 3
    W5300_REG_PDHAR4    = W5300_REG_PDHAR + 4
    W5300_REG_PDHAR5    = W5300_REG_PDHAR + 5

    ; Unreachable IP Address Register
    W5300_REG_UIPR      = W5300_BASE + $08
    W5300_REG_UIPR0     = W5300_REG_UIPR + 0
    W5300_REG_UIPR1     = W5300_REG_UIPR + 1
    W5300_REG_UIPR2     = W5300_REG_UIPR + 2
    W5300_REG_UIPR3     = W5300_REG_UIPR + 3

    ; Unreachable Port Number Register
    W5300_REG_UPORTR    = W5300_BASE + $0C
    W5300_REG_UPORTR0   = W5300_REG_UPORTR + 0
    W5300_REG_UPORTR1   = W5300_REG_UPORTR + 1

    ; Fragment MTU Register
    W5300_REG_FMTUR     = W5300_BASE + $0E
    W5300_REG_FMTUR0    = W5300_REG_FMTUR + 0
    W5300_REG_FMTUR1    = W5300_REG_FMTUR + 1

    ; BRDY Configure/Depth Registers (n/a)

    ; START OF BANKS 4-12
    W5300_BANK_SOCK     = W5300_BANK + $04

    ; Socket Mode Register
    W5300_REG_SOCK_MR   = W5300_BASE + $00
    W5300_REG_SOCK_MR0  = W5300_REG_SOCK_MR + 0
    W5300_REG_SOCK_MR1  = W5300_REG_SOCK_MR + 1

    ; Socket Command Register
    W5300_REG_SOCK_CR   = W5300_BASE + $03

    ; Socket Interrupt Mask Register
    W5300_REG_SOCK_IMR  = W5300_BASE + $05

    ; Socket Interrupt Register
    W5300_REG_SOCK_IR   = W5300_BASE + $07

    ; Socket Status Register
    W5300_REG_SOCK_SSR  = W5300_BASE + $09

    ; Socket Source Port Register
    W5300_REG_SOCK_PORTR    = W5300_BASE + $0A
    W5300_REG_SOCK_PORTR0   = W5300_REG_SOCK_PORTR + 0
    W5300_REG_SOCK_PORTR1   = W5300_REG_SOCK_PORTR + 1

    ; Socket Destination Hardware Address Register
    W5300_REG_SOCK_DHAR     = W5300_BASE + $0C
    W5300_REG_SOCK_DHAR0    = W5300_REG_SOCK_DHAR + 0
    W5300_REG_SOCK_DHAR1    = W5300_REG_SOCK_DHAR + 1
    W5300_REG_SOCK_DHAR2    = W5300_REG_SOCK_DHAR + 2
    W5300_REG_SOCK_DHAR3    = W5300_REG_SOCK_DHAR + 3
    W5300_REG_SOCK_DHAR4    = W5300_REG_SOCK_DHAR + 4
    W5300_REG_SOCK_DHAR5    = W5300_REG_SOCK_DHAR + 5

    ; Socket Destination Port Register
    W5300_REG_SOCK_DPORTR   = W5300_BASE + $12
    W5300_REG_SOCK_DPORTR0  = W5300_REG_SOCK_DPORTR + 0
    W5300_REG_SOCK_DPORTR1  = W5300_REG_SOCK_DPORTR + 1

    ; Socket Destination IP Register
    W5300_REG_SOCK_DIPR     = W5300_BASE + $14
    W5300_REG_SOCK_DIPR0    = W5300_REG_SOCK_DIPR + 0
    W5300_REG_SOCK_DIPR1    = W5300_REG_SOCK_DIPR + 1
    W5300_REG_SOCK_DIPR2    = W5300_REG_SOCK_DIPR + 2
    W5300_REG_SOCK_DIPR3    = W5300_REG_SOCK_DIPR + 3

    ; Socket MSS Register
    W5300_REG_SOCK_MSSR     = W5300_BASE + $18
    W5300_REG_SOCK_MSSR0    = W5300_REG_SOCK_MSSR + 0
    W5300_REG_SOCK_MSSR1    = W5300_REG_SOCK_MSSR + 1

    ; Socket Keep-Alive Time Register
    W5300_REG_SOCK_KPALVTR  = W5300_BASE + $1A

    ; Socket Protocol Number Register
    W5300_REG_SOCK_PROTOR   = W5300_BASE + $1B

    ; Socket TOS Register
    W5300_REG_SOCK_TOS      = W5300_BASE + $1D

    ; Socket TTL Register
    W5300_REG_SOCK_TTL      = W5300_BASE + $1F

    ; Socket Tx Write Size Register
    W5300_REG_SOCK_WRSR     = W5300_BASE + $21
    W5300_REG_SOCK_WRSR0    = W5300_REG_SOCK_WRSR + 0
    W5300_REG_SOCK_WRSR1    = W5300_REG_SOCK_WRSR + 1
    W5300_REG_SOCK_WRSR2    = W5300_REG_SOCK_WRSR + 2

    ; Socket Tx Free Size Register
    W5300_REG_SOCK_FSR      = W5300_BASE + $25
    W5300_REG_SOCK_FSR0     = W5300_REG_SOCK_FSR + 0
    W5300_REG_SOCK_FSR1     = W5300_REG_SOCK_FSR + 1
    W5300_REG_SOCK_FSR2     = W5300_REG_SOCK_FSR + 2

    ; Socket Rx Read Size Register
    W5300_REG_SOCK_RSR      = W5300_BASE + $29
    W5300_REG_SOCK_RSR0     = W5300_REG_SOCK_RSR + 0
    W5300_REG_SOCK_RSR1     = W5300_REG_SOCK_RSR + 1
    W5300_REG_SOCK_RSR2     = W5300_REG_SOCK_RSR + 2

    ; Socket Fragment Register
    W5300_REG_SOCK_FRAGR    = W5300_BASE + $2D

    ; Socket Tx FIFO Register
    W5300_REG_SOCK_TX_FIFOR = W5300_BASE + $2E
    W5300_REG_SOCK_TX_FIFOR0    = W5300_REG_SOCK_TX_FIFOR + 0
    W5300_REG_SOCK_TX_FIFOR1    = W5300_REG_SOCK_TX_FIFOR + 1

    ; Socket Rx FIFO Register
    W5300_REG_SOCK_RX_FIFOR = W5300_BASE + $2E
    W5300_REG_SOCK_RX_FIFOR0 = W5300_REG_SOCK_RX_FIFOR + 0
    W5300_REG_SOCK_RX_FIFOR1 = W5300_REG_SOCK_RX_FIFOR + 1

