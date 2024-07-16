# GBTang - GB for Sipeed Tang FPGA Boards 

<p align="right">
  <a title="Releases" href="https://github.com/fjpolo/GBTang/releases"><img src="https://img.shields.io/github/commits-since/nand2mario/nestang/latest.svg?longCache=true&style=flat-square&logo=git&logoColor=fff"></a>
</p>

GBTang is an open source project to recreate the Nintendo GameBoy (GB) with Sipeed [Tang Nano 20K](https://wiki.sipeed.com/hardware/en/tang/tang-nano-20k/nano-20k.html) FPGA board.

Main features:
- 720p HDMI output with sound.
- Cycle accurate gameplay quality has been achieved since the GB circuits have been almost entirely replicated.
- Rom loading from MicroSD cards with an easy-to-use menu system, powered by a RISC-V softcore.
- Extensive mapper support including MMC5, Namco and more.
- NES/SNES controllers, or DS2 controllers.

## Getting the parts

You need either the Sipeed Tang Nano 20K FPGA board to run the latest GBTang.

* We suggest the [Tang Nano 20K Retro Gaming Kit](https://www.amazon.com/GW2AR-18-Computer-Debugger-Multiple-Emulator/dp/B0C5XLBQ6C), as it contains the necessary controllers and adapters.

## Installation

A [step-by-step instructions](https://github.com/nand2mario/snestang/blob/main/doc/installation.md) is available. Here are quick instructions for the more experienced,

* Assemble the board and modules: [result for the primer 25k](https://github.com/nand2mario/snestang/raw/main/doc/images/primer25k_setup.jpg), and [nano 20k](https://github.com/nand2mario/snestang/raw/main/doc/images/nano20k_setup.jpg).
* Download a GBTang release from [github](https://github.com/fjpolo/GBTang/releases). The bitstream (`gbtang_*.fs`) should be written to flash at address 0. The firmware (`firmware.bin`) should be written to 0x500000 (5MB). See this [screenshot](https://github.com/nand2mario/snestang/blob/main/doc/images/programmer_firmware.png) for how to do it.
* Put your ROM files onto a MicroSD Card (exFAT or FAT32 file system). Insert the card, connect an HDMI monitor or TV, and enjoy your games.

## Development

If you want to generate the bitstream from source, see [Build Instructions](https://nand2mario.github.io/nestang-doc/dev/build_bitstream/). Make sure you use the Gowin IDE version 1.9.9 commercial (requires a free license).

## Next steps

See GBTang [changes.md](CHANGES.md) and [CHANGELOG.md](CHANGELOG.md).

## Special Thanks

* [NESTang](https://github.com/nand2mario/nestang) by nand2mario.
* [SNESTang](https://github.com/nand2mario/snestang) by nand2mario.
* [Gameboy_MiSTer](https://github.com/MiSTer-devel/Gameboy_MiSTer) by MiSTer community.

nand2mario  (`nand2mario at outlook.com`)
fjpolo      (`fjpolo at gmail.com`)

Since 2024
