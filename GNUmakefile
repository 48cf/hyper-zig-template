# Nuke built-in rules and variables.
MAKEFLAGS += -rR
.SUFFIXES:

# Target architecture to build for. Default to x86_64.
ARCH := x86_64

# Default user flags for the Zig compiler.
ZIGFLAGS := -Doptimize=ReleaseSafe

# Default user QEMU flags.
QEMUFLAGS := -m 2G

override IMAGE_NAME := template

.PHONY: all
all: $(IMAGE_NAME).iso

.PHONY: all-hdd
all-hdd: $(IMAGE_NAME).hdd

.PHONY: run
run: run-$(ARCH)

.PHONY: run-hdd
run-hdd: run-hdd-$(ARCH)

.PHONY: run-bios
run-x86_64: $(IMAGE_NAME).iso
	qemu-system-x86_64 -M q35 -m 2G -cdrom $(IMAGE_NAME).iso -boot d $(QEMUFLAGS)

.PHONY: run-hdd-bios
run-hdd-x86_64: $(IMAGE_NAME).hdd
	qemu-system-x86_64 -M q35 -m 2G -hda $(IMAGE_NAME).hdd $(QEMUFLAGS)

hyper/installer/hyper_install:
	rm -rf hyper
	git clone --depth 1 --recursive https://github.com/UltraOS/Hyper.git hyper
	cd hyper && ./build.py --arch i686 --platform bios && ./build.py --arch amd64 --platform uefi

.PHONY: kernel
kernel:
	cd kernel && zig build $(ZIGFLAGS) -Darch=$(ARCH)

$(IMAGE_NAME).iso: hyper/installer/hyper_install kernel
	rm -rf iso_root
	mkdir -p iso_root/boot
	cp -v kernel/zig-out/bin/kernel iso_root/boot/
	mkdir -p iso_root/boot/hyper
	cp -v hyper.cfg iso_root/boot/hyper/
	cp -v hyper/build-clang-i686-bios/loader/hyper_bios iso_root/boot/hyper/
	cp -v hyper/build-clang-i686-bios/loader/hyper_iso_boot iso_root/boot/hyper/
	mkdir -p iso_root/EFI/BOOT
	cp -v hyper/build-clang-amd64-uefi/loader/hyper_uefi iso_root/EFI/BOOT/BOOTX64.EFI
	xorriso -as mkisofs -b boot/hyper/hyper_iso_boot \
		-no-emul-boot -boot-load-size 4 -boot-info-table \
		--efi-boot EFI/BOOT/BOOTX64.EFI -efi-boot-part --efi-boot-image \
		--protective-msdos-label iso_root -o $(IMAGE_NAME).iso
	hyper/installer/hyper_install $(IMAGE_NAME).iso
	rm -rf iso_root

# Installing to GPT images is currently not supported.
$(IMAGE_NAME).hdd: hyper/installer/hyper_install kernel
	rm -f $(IMAGE_NAME).hdd
	dd if=/dev/zero bs=1M count=0 seek=64 of=$(IMAGE_NAME).hdd
	PATH=$$PATH:/usr/sbin:/sbin sgdisk $(IMAGE_NAME).hdd -n 1:2048 -t 1:ef00
	hyper/installer/hyper_install $(IMAGE_NAME).hdd
	mformat -i $(IMAGE_NAME).hdd@@1M
	mmd -i $(IMAGE_NAME).hdd@@1M ::/EFI ::/EFI/BOOT ::/boot ::/boot/hyper
	mcopy -i $(IMAGE_NAME).hdd@@1M kernel/zig-out/bin/kernel ::/boot
	mcopy -i $(IMAGE_NAME).hdd@@1M hyper.cfg ::/boot/hyper
	mcopy -i $(IMAGE_NAME).hdd@@1M hyper/build-clang-i686-bios/loader/hyper_bios ::/boot/hyper
	mcopy -i $(IMAGE_NAME).hdd@@1M hyper/build-clang-amd64-uefi/loader/hyper_uefi ::/EFI/BOOT/BOOTX64.EFI

.PHONY: clean
clean:
	rm -rf iso_root $(IMAGE_NAME).iso $(IMAGE_NAME).hdd
	rm -rf kernel/.zig-cache kernel/zig-cache kernel/zig-out

.PHONY: distclean
distclean: clean
	rm -rf hyper
