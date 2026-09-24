if {$argc == 0} {
    puts "Usage: $argv0 <device> \[<controller>\]"
    puts "          device: gbtang_nano20k, nano20k, primer25k"
    puts "      controller: snes, ds2  (only for nano20k/primer25k)"
    exit 1
}

set dev [lindex $argv 0]
if {$argc == 2} {
    set controller [lindex $argv 1]
} else {
    set controller ""
}

# -----------------------------------------------------------------------
# GBTang on Tang Nano 20K (VerilogBoy + NESTang framework + OSTang iosys)
# -----------------------------------------------------------------------
if {$dev eq "gbtang_nano20k"} {
    set_device GW2AR-LV18QN88C8/I7 -device_version C
    add_file src/nano20k/config.v
    add_file -type cst "src/nano20k/nestang.cst"
    add_file -type sdc "src/nano20k/nestang.sdc"
    add_file -type verilog "src/nano20k/gowin_pll_gb.v"
    add_file -type verilog "src/nano20k/gowin_pll_hdmi.v"
    set_option -output_base_name gbtang_nano20k
    set_option -top_module gbtang_top

    # VerilogBoy Game Boy core
    foreach f {alu boy brom clk_div common control cpu dma edgedet mbc5
               ppu regfile serial singleport_ram singlereg sound
               sound_channel_mix sound_length_ctr sound_noise sound_square
               sound_vol_env sound_wave timer} {
        add_file -type verilog "VerilogBoy/rtl/${f}.v"
    }

    # GBTang video converter (Game Boy LCD -> 720p HDMI)
    add_file -type verilog "src/gameboy2hdmi.sv"

    # OSTang iosys (PicoRV32 firmware with CORE_GB=3 support)
    add_file -type verilog "OSTang/src/iosys/gowin_dpb_menu.v"
    add_file -type verilog "OSTang/src/iosys/iosys.v"
    add_file -type verilog "OSTang/src/iosys/picorv32.v"
    add_file -type verilog "OSTang/src/iosys/simplespimaster.v"
    add_file -type verilog "OSTang/src/iosys/simpleuart.v"
    add_file -type verilog "OSTang/src/iosys/spi_master.v"
    add_file -type verilog "OSTang/src/iosys/spiflash.v"
    add_file -type verilog "OSTang/src/iosys/textdisp.v"

} elseif {$dev eq "nano20k"} {
# -----------------------------------------------------------------------
# Original NESTang on Tang Nano 20K
# -----------------------------------------------------------------------
    set_device GW2AR-LV18QN88C8/I7 -device_version C
    add_file src/nano20k/config.v
    add_file -type cst "src/nano20k/nestang.cst"
    add_file -type verilog "src/nano20k/gowin_pll_hdmi.v"
    add_file -type verilog "src/nano20k/gowin_pll_nes.v"
    # nano20k supports both controllers simultaneously
    set_option -output_base_name nestang_${dev}
    set_option -top_module nestang_top

} elseif {$dev eq "primer25k"} {
# -----------------------------------------------------------------------
# NESTang on Tang Primer 25K
# -----------------------------------------------------------------------
    set_device GW5A-LV25MG121NC1/I0 -device_version A
    if {$controller eq "snes"} {
        add_file src/primer25k/config_snescontroller.v
        add_file -type cst "src/primer25k/nestang_snescontroller.cst"
    } elseif {$controller eq "ds2"} {
        add_file src/primer25k/config.v
        add_file -type cst "src/primer25k/nestang.cst"
    } else {
        error "Unknown controller $controller"
    }
    add_file -type verilog "src/primer25k/gowin_pll_27.v"
    add_file -type verilog "src/primer25k/gowin_pll_hdmi.v"
    add_file -type verilog "src/primer25k/gowin_pll_nes.v"
    set_option -output_base_name nestang_${dev}_${controller}
    set_option -top_module nestang_top

} elseif {$dev eq "gbtang_console60k" || $dev eq "console60k" || $dev eq "console60k_bl616"} {
# -----------------------------------------------------------------------
# GBTang on Tang Console 60K (GW5AT-LV60PG484AC1/I0)
# -----------------------------------------------------------------------
    set_device GW5AT-LV60PG484AC1/I0 -device_version B
    add_file src/console60k/config.v
    add_file -type cst "src/console60k/console60k.cst"
    add_file -type sdc "src/console60k/console60k.sdc"
    add_file -type verilog "src/console60k/gowin_pll_27.v"
    add_file -type verilog "src/console60k/gowin_pll_gb.v"
    add_file -type verilog "src/console60k/gowin_pll_hdmi.v"
    set_option -output_base_name gbtang_console60k
    set_option -top_module gbtang_top

    # VerilogBoy Game Boy core
    foreach f {alu boy brom clk_div common control cpu dma edgedet mbc5
               ppu regfile serial singleport_ram singlereg sound
               sound_channel_mix sound_length_ctr sound_noise sound_square
               sound_vol_env sound_wave timer} {
        add_file -type verilog "VerilogBoy/rtl/${f}.v"
    }

    # GBTang video converter (Game Boy LCD -> 720p HDMI)
    add_file -type verilog "src/gameboy2hdmi.sv"

    if {$controller eq "bl616" || $dev eq "console60k_bl616"} {
        # TangCore Companion Mode: BL616 MCU interface
        add_file -type verilog "src/bl616/iosys_bl616.v"
        add_file -type verilog "src/bl616/uart_fixed.v"
        add_file -type verilog "src/bl616/textdisp.v"
        add_file -type verilog "OSTang/src/iosys/gowin_dpb_menu.v"
    } else {
        # Standalone Mode: OSTang iosys with internal PicoRV32 softcore
        add_file -type verilog "OSTang/src/iosys/gowin_dpb_menu.v"
        add_file -type verilog "OSTang/src/iosys/iosys.v"
        add_file -type verilog "OSTang/src/iosys/picorv32.v"
        add_file -type verilog "OSTang/src/iosys/simplespimaster.v"
        add_file -type verilog "OSTang/src/iosys/simpleuart.v"
        add_file -type verilog "OSTang/src/iosys/spi_master.v"
        add_file -type verilog "OSTang/src/iosys/spiflash.v"
        add_file -type verilog "OSTang/src/iosys/textdisp.v"
    }

} else {
    error "Unknown device $dev"
}

# -----------------------------------------------------------------------
# Common source files (shared by all targets except gbtang targets
# which use OSTang iosys instead)
# -----------------------------------------------------------------------
if {$dev ne "gbtang_nano20k" && $dev ne "gbtang_console60k" && $dev ne "console60k" && $dev ne "console60k_bl616"} {
    add_file -type verilog "src/apu.v"
    add_file -type verilog "src/iosys/gowin_dpb_menu.v"
    add_file -type verilog "src/iosys/iosys.v"
    add_file -type verilog "src/iosys/picorv32.v"
    add_file -type verilog "src/iosys/simplespimaster.v"
    add_file -type verilog "src/iosys/simpleuart.v"
    add_file -type verilog "src/iosys/spi_master.v"
    add_file -type verilog "src/iosys/spiflash.v"
    add_file -type verilog "src/iosys/textdisp.v"
    add_file -type verilog "src/mappers/generic.sv"
    add_file -type verilog "src/mappers/iir_filter.v"
    add_file -type verilog "src/mappers/JYCompany.sv"
    add_file -type verilog "src/mappers/misc.sv"
    add_file -type verilog "src/mappers/MMC1.sv"
    add_file -type verilog "src/mappers/MMC2.sv"
    add_file -type verilog "src/mappers/MMC3.sv"
    add_file -type verilog "src/mappers/MMC5.sv"
    add_file -type verilog "src/mappers/Namco.sv"
    add_file -type verilog "src/mappers/Sachen.sv"
    add_file -type verilog "src/mappers/Sunsoft.sv"
    add_file -type verilog "src/nes.v"
    add_file -type verilog "src/nes2hdmi.sv"
    add_file -type verilog "src/nestang_top.sv"
    add_file -type verilog "src/ppu.v"
    add_file -type verilog "src/sdram_nes.v"
    add_file -type verilog "src/t65/T65.v"
    add_file -type verilog "src/t65/T65_ALU.v"
    add_file -type verilog "src/t65/T65_MCode.v"
    add_file -type verilog "src/t65/T65_Pack.v"
}

# Files for NES targets only
if {$dev ne "gbtang_nano20k" && $dev ne "gbtang_console60k" && $dev ne "console60k" && $dev ne "console60k_bl616"} {
    add_file -type verilog "src/autofire.v"
    add_file -type verilog "src/cart.sv"
    add_file -type verilog "src/compat.v"
    add_file -type verilog "src/dpram.v"
}
add_file -type verilog "src/controller_snes.v"
add_file -type verilog "src/controller_ds2.sv"
add_file -type verilog "src/dualshock_controller.v"
add_file -type verilog "src/EEPROM_24C0x.sv"
add_file -type verilog "src/game_loader.v"
add_file -type verilog "src/hw_uart.v"
add_file -type verilog "src/hdmi2/audio_clock_regeneration_packet.sv"
add_file -type verilog "src/hdmi2/audio_info_frame.sv"
add_file -type verilog "src/hdmi2/audio_sample_packet.sv"
add_file -type verilog "src/hdmi2/auxiliary_video_information_info_frame.sv"
add_file -type verilog "src/hdmi2/hdmi.sv"
add_file -type verilog "src/hdmi2/packet_assembler.sv"
add_file -type verilog "src/hdmi2/packet_picker.sv"
add_file -type verilog "src/hdmi2/serializer.sv"
add_file -type verilog "src/hdmi2/source_product_description_info_frame.sv"
add_file -type verilog "src/hdmi2/tmds_channel.sv"
add_file -type verilog "src/sdram_gb.v"
add_file -type verilog "src/uart_tx_V2.v"
add_file -type verilog "src/usb_hid_host.v"
add_file -type verilog "src/usb_hid_host_rom.v"

# GBTang-specific files (only when building gbtang target)
if {$dev eq "gbtang_nano20k" || $dev eq "gbtang_console60k" || $dev eq "console60k" || $dev eq "console60k_bl616"} {
    add_file -type verilog "src/gbtang_top.sv"
}

set_option -synthesis_tool gowinsynthesis
set_option -verilog_std sysv2017
if {$dev ne "gbtang_nano20k" && $dev ne "gbtang_console60k" && $dev ne "console60k" && $dev ne "console60k_bl616"} {
    set_option -rw_check_on_ram 1
} else {
    set_option -rw_check_on_ram 0
}
set_option -use_mspi_as_gpio 1
set_option -use_ready_as_gpio 1
set_option -use_done_as_gpio 1
set_option -use_i2c_as_gpio 1
set_option -use_cpu_as_gpio 1
set_option -use_sspi_as_gpio 1
set_option -multi_boot 1

run all
