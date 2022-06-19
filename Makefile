ARCH				:=arm
CROSS_COMPILE		:=arm-none-linux-gnueabihf-
OUTPUT_DIR			:=$(PWD)/output
V					?=0
TFTP_DIR			:=/tftpboot
NFS_DIR				:=/nfsroot
INSTALL_MOD_PATH	:=/$(NFS_DIR)/00_rpi3_rootfs

all:

PHONY+=u-boot-defconfig
u-boot-defconfig:
	$(MAKE) -C u-boot CROSS_COMPILE=$(CROSS_COMPILE) rpi_2_defconfig O=$(OUTPUT_DIR)/u-boot

PHONY+=u-boot
u-boot: u-boot-defconfig
	$(MAKE) -C u-boot CROSS_COMPILE=$(CROSS_COMPILE) O=$(OUTPUT_DIR)/u-boot V=$(V)

PHONY+=linux-defconfig
linux-defconfig:
	$(MAKE) -C linux ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) KERNEL=kernel7 bcm2709_defconfig O=$(OUTPUT_DIR)/linux

PHONY+=linux
linux: linux-defconfig
	$(MAKE) -C linux ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) KERNEL=kernel7 O=$(OUTPUT_DIR)/linux zImage dtbs modules V=$(V) -j8

PHONY+=install-linux-module
install-linux-module: linux
	$(MAKE) -C linux ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) KERNEL=kernel7 O=$(OUTPUT_DIR)/linux INSTALL_MOD_PATH=$(INSTALL_MOD_PATH) modules_install V=$(V) -j8

PHONY+=buildroot-defconfig
buildroot-defconfig:
	$(MAKE) -C buildroot O=$(OUTPUT_DIR)/buildroot raspberrypi2_defconfig

PHONY+=buildroot-menuconfig
buildroot-menuconfig: buildroot-defconfig
	$(MAKE) -C buildroot O=$(OUTPUT_DIR)/buildroot menuconfig

PHONY+=buildroot
buildroot: buildroot-defconfig
	$(MAKE) -C buildroot O=$(OUTPUT_DIR)/buildroot -j8
	tar -xvf $(OUTPUT_DIR)/buildroot/images/rootfs.tar -C /$(NFS_DIR)/00_rpi3_rootfs

PHONY+=clean_u-boot
clean_u-boot:
	$(MAKE) -C u-boot CROSS_COMPILE=$(CROSS_COMPILE) O=$(OUTPUT_DIR)/u-boot clean

PHONY+=clean_linux
clean_linux:
	$(MAKE) -C linux ARCH=$(ARCH) CROSS_COMPILE=$(CROSS_COMPILE) KERNEL=kernel7 O=$(OUTPUT_DIR)/linux clean

PHONY+=clean_buildroot
clean_buildroot:
	$(MAKE) -C ubuildroot O=$(OUTPUT_DIR)/buildroot clean

PHONY+=install_tftp
install_tftp:
	cp -a $(OUTPUT_DIR)/u-boot/u-boot.bin $(TFTP_DIR)/
	cp -a $(OUTPUT_DIR)/linux/arch/arm/boot/Image $(TFTP_DIR)/
	cp -a $(OUTPUT_DIR)/linux/arch/arm/boot/zImage $(TFTP_DIR)/
	cp -a $(OUTPUT_DIR)/linux/arch/arm/boot/dts/*.dtb $(TFTP_DIR)/

.PHONY: $(PHONY)
