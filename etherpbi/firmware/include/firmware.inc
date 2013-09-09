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
;;    D100-D17F: Firmware ROM high bank select. 1K window, up to 128 banks.
;;    D180-D1BF: W5300 access area, 64 bytes
;;    D1C0-D1CF: W5300 uses 1K (10 bit) address space, mapped in 16 64-byte (6-bit) pieces.
;;        Read/write D1C0 to select bank 0, D1C1 to select bank 1 etc.
;;    D1D0-D1DF: SPI access registers
;;        D1D0:
;;    D1E0-D1FE: RAM high bank select, 256 byte window, up to 31 banks.
;;    D1FF: PBI select/interrupt register
;; D600-D6FF (256 bytes): RAM low bank (fixed = bank 1F)
;; D700-D7FF (256 bytes): RAM high bank (selectable)
;;
;; FLASH ROM area: CAT28F512 or equivalent
;;    D800-DBFF (1024 bytes): PBP Program memory bank 0 (fixed)
;;    DC00-DFFF (1024 bytes): PBP Program memory bank 1 (selectable)


;;;
;;; I/O
;;;

;;
;; Config memory definitions

.scope CONFIG
    BASE            = $80

    ; IP address mode
    ;   bit 0: Use DHCP for IP assignment
    ;   bit 1: Use DHCP for DNS addresses (ignored if bit 0 is clear)
    ;   bit 2-7: reserved
    IPMODE          = BASE + $00
    ; Configured IP address
    IPADDR          = BASE + $01
    IPADDR_LEN      = 4
    ; Configured IP netmask length
    IPADDR_BITS     = BASE + $05
    ; Configured DNS host
    DNS             = BASE + $06
    DNS_LEN         = 4
    ; Configured default router
    IPGW            = BASE + $0A
    IPGW_LEN        = 4

    ; FIRST_FREE    = BASE + $0E

    ; LAST          = BASE + $7F
.endscope ; CONFIG

;;
;; W5300 definitions
;;

.scope W5300
    BASE            = $D180

    .scope BANK
        ; Common bank
        COMMON0     = $D1C0
        ; PPP and other config bank
        COMMON1     = $D1C1
        ; Socket banks (4..12, add socket number to W5300::BANK::SOCK)
        SOCK        = $D1C4
    .endscope

    .scope REG
        .scope COM0
            ; Bank 0: Common regs (first half)

            ; Mode register 0
            ;   Bit 7: Data bus width (0 = 8-bit)
            ;   Bit 6: MAC layer pause frame (0 = normal, 1 = pause)
            ;   Bit 3-5: Write data fetch time (NxPLL_CLK, default 111)
            ;   Bit 2: Read data hold time (0 = none, 1 = 2xPLL_CLK, default 0)
            ;   Bit 1: reserved (set 0)
            ;   Bit 0: FIFO swap (0 = big-endian FIFO, 1 = little-endian FIFO)
            MR0         = BASE

            .scope MR0
                DBW     = 7
                MPF     = 6
                WDF     = 3
                RDH     = 2
                FS      = 0
            .endscope ; MR0

            ; Mode register 1
            ;   Bit 7: Software reset (1 = reset)
            ;   Bit 6: reserved (set 0)
            ;   Bit 5: Memory test (1 = enable; leave 0)
            ;   Bit 4: Ping block (0 = reply to ping when ICMP sock is not open; 1 = do not reply)
            ;   Bit 3: PPPoE enable (leave 0)
            ;   Bit 2: Data bus swap (1 = swapped data bus)
            ;   Bit 1: reserved (set 0)
            ;   Bit 0: Indirect bus mode (1 = indirect bus; set 0)
            MR1         = BASE + 1

            .scope MR1
                RST     = 7
                MT      = 5
                PB      = 4
                PPPoE   = 3
                DBS     = 2
                IND     = 0
            .endscope ; MR1

            ; Interrupt register 0 (Write a 1 to clear the corresponding interrupt, read for status)
            ;   Bit 7: 1 = IP conflict detect
            ;   Bit 6: 1 = Port unreachable (see UIPR, UPORTR)
            ;   Bit 5: 1 = PPPoE terminated
            ;   Bit 4: 1 = ICMP Fragment MTU packet received (see FMTUR)
            ;   Bit 0-3: reserved (0)
            IR0         = BASE + 2

            .scope IR0
                IPCF    = 7
                DPUR    = 6
                PPPT    = 5
                FMTU    = 4
            .endscope ; IR0

            ; Interrupt register 1 (Write a 1 to clear the corresponding interrupt, read for status)
            ;   Bits 0-7: Interrupt on socket N where N = bit #
            IR1         = BASE + 3

            ; Interrupt mask register 0 (R/W, write 1 to enable, 0 to disable)
            ;   Bit 7: 1 = IP conflict detect
            ;   Bit 6: 1 = Port unreachable (see UIPR, UPORTR)
            ;   Bit 5: 1 = PPPoE terminated
            ;   Bit 4: 1 = ICMP Fragment MTU packet received (see FMTUR)
            ;   Bit 0-3: reserved (0)
            IMR0        = BASE + 4

            .scope IMR0
                IPCF    = 7
                DPUR    = 6
                PPPT    = 5
                FMTU    = 4
            .endscope ; IMR0

            ; Interrupt mask register 1 (R/W, write 1 to enable, 0 to disable)
            ;   Bits 0-7: Interrupt on socket N where N = bit #
            IMR1        = BASE + 5

            ; Source hardware address, network order, 6 bytes
            SHAR        = BASE + 8
            SHAR_LEN    = 6

            ; Gateway (default route next hop) address, network order, 4 bytes
            GAR         = BASE + $10
            GAR_LEN     = 4

            ; Subnet mask register, network order, 4 bytes
            SUBR        = BASE + $14
            SUBR_LEN    = 4

            ; Source IP address register, network order, 4 bytes
            SIPR        = BASE + $18
            SIPR_LEN    = 4

            ; Retransmit timeout register; units of 100us, MSB first (big-endian), 2 bytes
            RTR         = BASE + $1C
            RTR_LEN     = 2

            ; Retransmit retry count register, 1 byte
            RCR         = BASE + $1F
            RCR_LEN     = 1

            ; !! Sum of all transmit/receive memory reg should be 128 !!
            ; Transmit memory size register, socket 0-7, one byte per socket, units of 1KB
            TMSR        = BASE + $20
            TMSR_LEN    = 8

            ; Receive memory size register, socket 0-7, one byte per socket, units of 1KB
            RMSR        = BASE + $28
            RMSR_LEN    = 8

            ; Memory type register; sets type of each of the 16 8KB memory blocks; 2 bytes
            ;   Bits 0-7 configure blocks 8-15
            ;   Bits 8-15 configure blocks 0-7
            ;   Bit X = 0 for receive, 1 for transmit
            MTYPER      = BASE + $30
            MTYPER_LEN  = 2

            ; PPPoE authentication register; 2 bytes
            PATR        = BASE + $32
            PATR_LEN    = 2

            ; PPP LCP request timer register; 1 byte
            PTIMER      = BASE + $37

            ; PPP LCP magic number register; 1 byte
            PMAGICR     = BASE + $39

            ; PPP Session ID register; 2 bytes
            PSIDR       = BASE + $3C
            PSIDR_LEN   = 2

        .endscope ; COM0

        .scope COM1
            ; Bank 1: Common regs (second half)

            ; PPP Destination hardware address register; network order, 6 bytes
            PDHAR       = BASE
            PDHAR_LEN   = 6

            ; Unreachable IP address register, set when IR(dest port unreachable) or IR(fragment MTU) is set
            UIPR        = BASE + 8
            UIPR_LEN    = 4

            ; Unreachable TCP port register, set when IR(dest port unreachable) is set
            UPORTR      = BASE + $0C
            UPORTR_LEN  = 2

            ; Fragment MTU register, set when IR(fragment MTU) is set; copy value to SOCK::MSSR to proceed; network order, 2 bytes
            FMTUR       = BASE + $0E
            FMTUR_LEN   = 2

        .endscope ; COM1

        .scope SOCK
            ; Mode register 0
            ;   Bit 7: Align TCP (set to 0 to disable)
            ;   Bit 0-6: reserved (set 0)
            MR0         = BASE

            .scope MR0
                ALIGN   = 7
            .endscope ; MR0

            ; Mode register 1
            ;   Bit 7: Muilticast (only valid for UDP) (1 = enable, 0 = disable); set DIPR/DPORT before OPEN cmd
            ;   Bit 6: MAC filter (only valid for MACRAW) (1 = normal, 0 = capture all packets)
            ;   Bit 5: TCP mode: No delayed ack (1 = no delayed ack [default], 0 = wait for RTR time always)
            ;          UDP+MULTI: IGMP version (0 = v2, 1 = v1)
            ;   Bit 4: reserved (0)
            ;   Bit 0-3: Protocol
            MR1         = BASE + 1

            .scope MR1
                MULTI   = 7
                MF      = 6
                ND      = 5
                IGMPv   = 5
            .endscope ; MR1

            .scope PROT
                CLOSE   = %0000
                TCP     = %0001
                UDP     = %0010
                IPRAW   = %0011
                MACRAW  = %0100
                PPPoE   = %0101
            .endscope ; PROT

            ; Command register
            CR          = BASE + 3
            .scope CMD
                ; Open the socket; the protocol should be set first in MR1
                ;   In TCP mode, SSR <- INIT
                ;   In UDP mode, SSR <- UDP
                ;   In IPRAW mode, SSR <- IPRAW
                ;   In MACRAW mode, SSR <- MACRAW
                ;   In PPPoE mode, SSR <- PPPoE
                OPEN        = $01
                ; Listen for incoming connection (only valid in TCP mode)
                LISTEN      = $02
                ; Initiate an outbound connection (TCP only)
                ;   On completion, SOCK::IR(0) <- 1 and SSR <- ESTABLISHED
                ;   On fail, SSR <- CLOSED
                CONNECT     = $04
                ; Disconnect a TCP socket
                ;   Active close: send FIN
                ;   Passive close: send FIN when FIN is received
                ;   On completion (FIN/ACK received), SSR <- CLOSED
                ;   On failure, IR(3) <- 1 and SSR <- CLOSED
                DISCON      = $08
                ; Close a TCP socket (does not send FIN)
                ;   SSR <- CLOSED
                CLOSE       = $10
                ; Send a packet of TX::WRSR size (must be written to TX::FIFOR first)
                ;   In TCP/UDP, if WRSR > MSS, packet is divided; not in IPRAW/MACRAW.
                ;   On completion (ACK received):
                ;       IR(4) <- 1 (once this is set, host can send again; 0 means wait)
                ;       TX::FSR <- FSR + size
                ;   On failure (timeout):
                ;       IR(3) <- 1 (timeout)
                ;       SSR <- CLOSED
                SEND        = $20
                ; Send a packet directly to DHAR address (UDP or IPRAW only) (skips ARP)
                SEND_MAC    = $21
                ; Send a keep-alive packet to the peer; only send after >= 1 comm is processed
                ;   Only available if SOCK::KPALVTR = 0 (else it's automatic)
                ;   On completion (KA/ACK received):
                ;       SSR maintains ESTABLISHED
                ;   On failure (timeout):
                ;       IR(3) <- 1 (timeout)
                ;       SSR <- CLOSED
                SEND_KEEP   = $22
                ; Acknowledge receipt of a packet (host should read from RX::FIFOR first)
                RECV        = $40
                ;
                ; PPPoE-specific commands (SOCKET0 only, PROT::PPPoE only)
                ;
                PCON        = $23
                PDISCON     = $24
                PCR         = $25
                PCN         = $26
                PCJ         = $27
            .endscope ; CMD

            ; Interrupt mode register; set each bit to 1 to enable the interrupt for this socket
            ; Use IR::* constants
            ;   Bit 7: PPPoE receive
            ;   Bit 6: PPPoE fail
            ;   Bit 5: PPPoE next
            ;   Bit 4: Send OK
            ;   Bit 3: Timeout
            ;   Bit 2: Receive data
            ;   Bit 1: Disconnect
            ;   Bit 0: Connect
            IMR         = BASE + 5

            ; Interrupt register; write 1 to clear bit, read 1 if condition is set
            ; If all bits are cleared, REG::IR(n) is cleared automatically
            ;   Bit 7: PPPoE receive
            ;   Bit 6: PPPoE fail
            ;   Bit 5: PPPoE next
            ;   Bit 4: Send OK (command is completed)
            ;   Bit 3: Timeout (ARP or TCP timed out)
            ;   Bit 2: Receive data
            ;   Bit 1: Disconnect (FIN or FIN/ACK received)
            ;   Bit 0: Connect (connection established)
            IR          = BASE + 7

            .scope IR
                PRECV   = 7
                PFAIL   = 6
                PNEXT   = 5
                SENDOK  = 4
                TIMEOUT = 3
                RECV    = 2
                DISCON  = 1
                CON     = 0
            .endscope ; IR

            ; Socket status register
            SSR         = BASE + 9

            .scope SSR
                ; Released/available socket
                ;   next cmd: OPEN
                CLOSED      = 0
                ; Open in TCP mode but not connected
                ;   next cmd: LISTEN, CONNECT, CLOSE
                INIT        = $13
                ; Open for listen
                ;   next cmd: CLOSE
                LISTEN      = $14
                ; Connection established
                ;   next cmd: SEND, RECV, CLOSE, DISCON (active close)
                ESTABLISHED = $15
                ; FIN received but connection still established
                ;   next cmd: SEND, RECV, CLOSE, DISCON (passive close)
                CLOSE_WAIT  = $1C
                ; Socket in UDP mode
                UDP         = $22
                ; Socket in IP Raw mode
                IPRAW       = $32
                ; Socket in MAC Raw mode
                MACRAW      = $42
                ; Socket in PPPoE mode
                PPPoE       = $5F
                ;; temp statuses
                SYN_SENT    = $15
                SYN_RECV    = $16
                FIN_WAIT    = $18
                TIME_WAIT   = $1B
                LAST_ACK    = $1D
                ARP         = $01
            .endscope ; SSR

            ; Source port register; network order, 2 bytes (TCP/UDP only)
            PORTR       = BASE + $0A
            PORTR_LEN   = 2

            ; Destination hardware (MAC) address; network order, 6 bytes
            ;   initialized by ARP
            DHAR        = BASE + $0C
            DHAR_LEN    = 6

            ; Destination port; network order, 2 bytes (TCP/UDP only)
            DPORTR      = BASE + $12
            DPORTR_LEN  = 2

            ; Destination IP address; network order, 4 bytes
            DIPR        = BASE + $14
            DIPR_LEN    = 4

            ; MSS register (TCP/UDP only); network order, 2 bytes
            MSSR        = BASE + $18
            MSSR_LEN    = 2

            ; Keep-alive timer (TCP only); 1 byte, 5 second increments
            KPALVTR     = BASE + $1A

            ; Protocol number register (IPRAW only); 1 byte
            PROTOR      = BASE + $1B

            ; IP TOS register (set before OPEN for TCP); 1 byte
            TOSR        = BASE + $1D

            ; IP TTL register (set before OPEN for TCP); 1 byte
            TTLR        = BASE + $1E

            ; Fragment field of IP header (set before OPEN for TCP); 1 byte
            ; !! do not configure !!
            FRAGR       = BASE + $2D

            .scope TX
                ; Transmit write size register (1 bit + 2 bytes, MSb first then MSB/LSB)
                WRSR        = BASE + $21
                WRSR_LEN    = 3

                ; Free size register (read-only) (1 bit + 2 bytes, MSb first then MSB/LSB)
                FSR         = BASE + $25
                FSR_LEN     = 3

                ; FIFO register (normally write-only); write even bytes to FIFOR and odd to FIFOR+1, write dummy odd byte if needed
                FIFOR       = BASE + $2E
                FIFOR_LEN   = 2
            .endscope ; TX

            .scope RX
                ; Received size register (read-only) (1 bit + 2 bytes, MSb first then MSB/LSB)
                RSR         = BASE + $28
                RSR_LEN     = 3

                ; FIFO register (normally read-only); read even bytes from FIFOR and odd from FIFOR+1, read odd byte if needed
                FIFOR       = BASE + $30
                FIFOR_LEN   = 2
            .endscope ; RX
        .endscope ; SOCK
    .endscope ; REG
.endscope ; W5300

;;;
;;; ROM control
;;;

.scope ROM

    BANK        = $D100

    .scope BANK

        CIO         = BANK + 0
        .scope CIO
            ; first device bank
            MIN     = BANK + 1
            ; N: device
            NET     = MIN + 0
            ; R: device
            RS232   = MIN + 1
            ; H: device
            CIOTCP  = MIN + 2

            ; last device bank
            MAX     = CIOTCP
            COUNT   = MAX - MIN + 1
        .endscope ; CIO

        SIO         = BANK + 8
        .scope SIO
            SIOUDP  = BANK + 9
            SIOMAP  = BANK + 10
        .endscope ; SIO

    .endscope ; BANK
.endscope ; ROM

;;;
;;; RAM control
;;;

.scope RAM

    ; fixed RAM base
    BASE        = $D600
    ; RAM bank select registers
    BANK        = $D1E0

    .scope BANK
        BASE        = $D700
        IOCB        = BANK + $00 ; one bank for each IOCB - but at offsets of 16
        ; IOCB0     = BANK + $00
        ; IOCB1     = BANK + $10
        ; ...
        ; IOCB7     = BANK + $70
        SOCK        = BANK + $01 ; one bank for each socket
        ; SOCK0     = BANK + $01
        ; SOCK1     = BANK + $02
        ; ...
        ; SOCK7     = BANK + $08
        SIO         = BANK + $09 ; single bank for SIO operation
    .endscope ; BANK

    ; CONFIG RAM area
    .scope CONFIG
        BASE        = ::RAM::BASE
        ; IP address mode
        ;   bit 0: Use DHCP for IP assignment
        ;   bit 1: Use DHCP for DNS addresses (ignored if bit 0 is clear)
        ;   bit 2-7: reserved
        IPMODE          = BASE + $00
        ; Configured IP address
        IPADDR          = BASE + $01
        IPADDR_LEN      = 4
        ; Configured IP netmask length
        IPADDR_BITS     = BASE + $05
        ; Configured DNS host
        DNS             = BASE + $06
        DNS_LEN         = 4
        ; Configured default router
        IPGW            = BASE + $0A
        IPGW_LEN        = 4
    .endscope ; CONFIG

    ; SOCK banks memory layout
    .scope SOCK
        BASE        = BANK::BASE
        ; IOCB number times 16
        IOCB        = BASE + 0

        ; Socket software status
        STAT        = BASE + 1

        .scope STAT ; even values only
            ; Socket is not open
            CLOSED  = 0
            ; Performing DNS lookup
            DNS     = 2
            ; In TCP socket mode
            TCP     = 4
            ; In UDP socket mode
            UDP     = 6
        .endscope ; STAT
    .endscope ; SOCK

    ; IOCB banks memory layout
    .scope IOCB
        BASE        = BASE::BANK

        ; IOCB index (number times 16) (init at start)
        IOCB_IDX    = BASE + 0

        ; unused    = BASE + 1

        ; Socket ID, 0-7, for this IOCB
        SOCK        = BASE + 2
        ; IOCB status
        ;   0 = not open, or open by someone else
        ;   $80 = open (by us)
        STAT        = BASE + 3
        ; CIO driver ROM bank index
        CIO_BANK    = BASE + 4
    .endscope ; IOCB


.endscope ; RAM

;;;
;;; CIO
;;;

.scope CIO
    .scope JMPTAB
        BASE        = $DC00
        OPEN        = BASE + 0
        CLOSE       = BASE + 3
        READ        = BASE + 6
        WRITE       = BASE + 9
        STATUS      = BASE + 12
        SPECIAL     = BASE + 15
        LAST        = SPECIAL
        LEN         = LAST - BASE
    .endscope ; JMPTAB

    .scope N
        .scope AUX1
            CONC        = %00000001
            ; unused    = %00000010
            READ        = %00000100
            WRITE       = %00001000


.endscope


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


