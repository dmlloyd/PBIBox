
ASMFILES=$(sort $(wildcard src/*.asm))
OFILES=$(ASMFILES:.asm=.obj)

all: firmware.img

firmware.img: $(OFILES) linker.cfg
	@echo '     [ ld65 ] ' $< '->' $@
	@ld65 -vm -m firmware.map -C linker.cfg --dbgfile firmware.dbg -o firmware.img $(OFILES)

.asm.obj:
	@echo '     [ ca65 ] ' $< '->' $@
	@ca65 -Iinclude $< -l -g -o $@

.SUFFIXES: .asm .obj .c .o

clean:
	rm -rf *.img */*.obj *.map *.dbg */*.lst
