//Copyright (C)2014-2023 Gowin Semiconductor Corporation.
//All rights reserved.
//File Title: IP file
//Tool Version: V1.9.9 (64-bit)
//Part Number: GW5AST-LV138FPG676AES
//Device: GW5AST-138B
//Device Version: B
//Created Time: Thu Dec 28 20:57:42 2023

module gowin_dpb_menu (douta, doutb, clka, ocea, cea, reseta, wrea, clkb, oceb, ceb, resetb, wreb, ada, dina, adb, dinb);

output [7:0] douta;
output [7:0] doutb;
input clka;
input ocea;
input cea;
input reseta;
input wrea;
input clkb;
input oceb;
input ceb;
input resetb;
input wreb;
input [10:0] ada;
input [7:0] dina;
input [10:0] adb;
input [7:0] dinb;

wire [7:0] dpb_inst_0_douta_w;
wire [7:0] dpb_inst_0_doutb_w;
wire gw_gnd;

assign gw_gnd = 1'b0;

DPB dpb_inst_0 (
    .DOA({dpb_inst_0_douta_w[7:0],douta[7:0]}),
    .DOB({dpb_inst_0_doutb_w[7:0],doutb[7:0]}),
    .CLKA(clka),
    .OCEA(ocea),
    .CEA(cea),
    .RESETA(reseta),
    .WREA(wrea),
    .CLKB(clkb),
    .OCEB(oceb),
    .CEB(ceb),
    .RESETB(resetb),
    .WREB(wreb),
    .BLKSELA({gw_gnd,gw_gnd,gw_gnd}),
    .BLKSELB({gw_gnd,gw_gnd,gw_gnd}),
    .ADA({ada[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIA({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dina[7:0]}),
    .ADB({adb[10:0],gw_gnd,gw_gnd,gw_gnd}),
    .DIB({gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,gw_gnd,dinb[7:0]})
);

defparam dpb_inst_0.READ_MODE0 = 1'b0;
defparam dpb_inst_0.READ_MODE1 = 1'b0;
defparam dpb_inst_0.WRITE_MODE0 = 2'b00;
defparam dpb_inst_0.WRITE_MODE1 = 2'b00;
defparam dpb_inst_0.BIT_WIDTH_0 = 8;
defparam dpb_inst_0.BIT_WIDTH_1 = 8;
defparam dpb_inst_0.BLK_SEL_0 = 3'b000;
defparam dpb_inst_0.BLK_SEL_1 = 3'b000;
defparam dpb_inst_0.RESET_MODE = "SYNC";
defparam dpb_inst_0.INIT_RAM_00 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_01 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_02 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_03 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_04 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_05 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_06 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_07 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_08 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_09 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_0A = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_0B = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_0C = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_0D = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_0E = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_0F = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_10 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_11 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_12 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_13 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_14 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_15 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_16 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_17 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_18 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_19 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_1A = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_1B = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_1C = 256'h381CE0700000000000381CE0700000000001FF1FEFF00000000001FF0FCFE000;    // LOGO: generated from src/assets/logo.py
defparam dpb_inst_0.INIT_RAM_1D = 256'h000E3B8CFE1C3CE7B0001C6719C0387FE3B0001CE739CC383FE030000FC3F8F8;    // \
defparam dpb_inst_0.INIT_RAM_1E = 256'h0000000000001FC719FC183FF3E0000F338CE70C3CF7F0000E3B8CFF1C3CF630;    // |
defparam dpb_inst_0.INIT_RAM_1F = 256'h000000000000000000000007E0000000000000000E60000000000000001C0000;    // /
defparam dpb_inst_0.INIT_RAM_20 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_21 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_22 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_23 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_24 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_25 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_26 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_27 = 256'h0000000000000000000000000000000000000000000000000000000000000000;
defparam dpb_inst_0.INIT_RAM_28 = 256'h0036367F367F3636000000000000363600180018183C3C180000000000000000;
defparam dpb_inst_0.INIT_RAM_29 = 256'h0000000000030606006E333B6E1C361C0063660C18336300000C1F301E033E0C;
defparam dpb_inst_0.INIT_RAM_2A = 256'h00000C0C3F0C0C000000663CFF3C660000060C1818180C0600180C0606060C18;
defparam dpb_inst_0.INIT_RAM_2B = 256'h000103060C183060000C0C0000000000000000003F000000060C0C0000000000;
defparam dpb_inst_0.INIT_RAM_2C = 256'h001E33301C30331E003F33061C30331E003F0C0C0C0C0E0C003E676F7B73633E;
defparam dpb_inst_0.INIT_RAM_2D = 256'h000C0C0C1830333F001E33331F03061C001E3330301F033F0078307F33363C38;
defparam dpb_inst_0.INIT_RAM_2E = 256'h060C0C00000C0C00000C0C00000C0C00000E18303E33331E001E33331E33331E;
defparam dpb_inst_0.INIT_RAM_2F = 256'h000C000C1830331E00060C1830180C0600003F00003F000000180C0603060C18;
defparam dpb_inst_0.INIT_RAM_30 = 256'h003C66030303663C003F66663E66663F0033333F33331E0C001E037B7B7B633E;
defparam dpb_inst_0.INIT_RAM_31 = 256'h007C66730303663C000F06161E16467F007F46161E16467F001F36666666361F;
defparam dpb_inst_0.INIT_RAM_32 = 256'h006766361E366667001E333330303078001E0C0C0C0C0C1E003333333F333333;
defparam dpb_inst_0.INIT_RAM_33 = 256'h001C36636363361C006363737B6F67630063636B7F7F7763007F66460606060F;
defparam dpb_inst_0.INIT_RAM_34 = 256'h001E33380E07331E006766363E66663F00381E3B3333331E000F06063E66663F;
defparam dpb_inst_0.INIT_RAM_35 = 256'h0063777F6B636363000C1E3333333333003F333333333333001E0C0C0C0C2D3F;
defparam dpb_inst_0.INIT_RAM_36 = 256'h001E06060606061E007F664C1831637F001E0C0C1E3333330063361C1C366363;
defparam dpb_inst_0.INIT_RAM_37 = 256'hFF000000000000000000000063361C08001E18181818181E00406030180C0603;
defparam dpb_inst_0.INIT_RAM_38 = 256'h001E3303331E0000003B66663E060607006E333E301E00000000000000180C0C;
defparam dpb_inst_0.INIT_RAM_39 = 256'h1F303E33336E0000000F06060F06361C001E033F331E0000006E33333E303038;
defparam dpb_inst_0.INIT_RAM_3A = 256'h0067361E366606071E33333030300030001E0C0C0C0E000C006766666E360607;
defparam dpb_inst_0.INIT_RAM_3B = 256'h001E3333331E000000333333331F000000636B7F7F330000001E0C0C0C0C0C0E;
defparam dpb_inst_0.INIT_RAM_3C = 256'h001F301E033E0000000F06666E3B000078303E33336E00000F063E66663B0000;
defparam dpb_inst_0.INIT_RAM_3D = 256'h00367F7F6B630000000C1E3333330000006E33333333000000182C0C0C3E0C08;
defparam dpb_inst_0.INIT_RAM_3E = 256'h00380C0C070C0C38003F260C193F00001F303E33333300000063361C36630000;
defparam dpb_inst_0.INIT_RAM_3F = 256'h00000000000000000000000000003B6E00070C0C380C0C070018181800181818;

endmodule //gowin_dpb_menu
