pragma solidity 0.8.1;

abstract contract AbstractRewardMultiplier {

    mapping(uint256 => uint256) internal _weekToMultiplier;

    function _initRewardMultiplier() internal {
        _weekToMultiplier[1] = 1.0 ether;
        _weekToMultiplier[2] = 1.01 ether;
        _weekToMultiplier[3] = 1.02 ether;
        _weekToMultiplier[4] = 1.03 ether;
        _weekToMultiplier[5] = 1.05 ether;
        _weekToMultiplier[6] = 1.06 ether;
        _weekToMultiplier[7] = 1.08 ether;
        _weekToMultiplier[8] = 1.09 ether;
        _weekToMultiplier[9] = 1.11 ether;
        _weekToMultiplier[10] = 1.13 ether;
        _weekToMultiplier[11] = 1.14 ether;
        _weekToMultiplier[12] = 1.16 ether;
        _weekToMultiplier[13] = 1.18 ether;
        _weekToMultiplier[14] = 1.2 ether;
        _weekToMultiplier[15] = 1.22 ether;
        _weekToMultiplier[16] = 1.24 ether;
        _weekToMultiplier[17] = 1.26 ether;
        _weekToMultiplier[18] = 1.29 ether;
        _weekToMultiplier[19] = 1.31 ether;
        _weekToMultiplier[20] = 1.33 ether;
        _weekToMultiplier[21] = 1.35 ether;
        _weekToMultiplier[22] = 1.38 ether;
        _weekToMultiplier[23] = 1.4 ether;
        _weekToMultiplier[24] = 1.43 ether;
        _weekToMultiplier[25] = 1.45 ether;
        _weekToMultiplier[26] = 1.48 ether;
        _weekToMultiplier[27] = 1.5 ether;
        _weekToMultiplier[28] = 1.53 ether;
        _weekToMultiplier[29] = 1.56 ether;
        _weekToMultiplier[30] = 1.58 ether;
        _weekToMultiplier[31] = 1.61 ether;
        _weekToMultiplier[32] = 1.64 ether;
        _weekToMultiplier[33] = 1.67 ether;
        _weekToMultiplier[34] = 1.7 ether;
        _weekToMultiplier[35] = 1.73 ether;
        _weekToMultiplier[36] = 1.75 ether;
        _weekToMultiplier[37] = 1.78 ether;
        _weekToMultiplier[38] = 1.81 ether;
        _weekToMultiplier[39] = 1.84 ether;
        _weekToMultiplier[40] = 1.87 ether;
        _weekToMultiplier[41] = 1.91 ether;
        _weekToMultiplier[42] = 1.94 ether;
        _weekToMultiplier[43] = 1.97 ether;
        _weekToMultiplier[44] = 2.0 ether;
        _weekToMultiplier[45] = 2.03 ether;
        _weekToMultiplier[46] = 2.06 ether;
        _weekToMultiplier[47] = 2.1 ether;
        _weekToMultiplier[48] = 2.13 ether;
        _weekToMultiplier[49] = 2.16 ether;
        _weekToMultiplier[50] = 2.2 ether;
        _weekToMultiplier[51] = 2.23 ether;
        _weekToMultiplier[52] = 2.26 ether;
        _weekToMultiplier[53] = 2.3 ether;
        _weekToMultiplier[54] = 2.33 ether;
        _weekToMultiplier[55] = 2.37 ether;
        _weekToMultiplier[56] = 2.4 ether;
        _weekToMultiplier[57] = 2.44 ether;
        _weekToMultiplier[58] = 2.47 ether;
        _weekToMultiplier[59] = 2.51 ether;
        _weekToMultiplier[60] = 2.54 ether;
        _weekToMultiplier[61] = 2.58 ether;
        _weekToMultiplier[62] = 2.62 ether;
        _weekToMultiplier[63] = 2.65 ether;
        _weekToMultiplier[64] = 2.69 ether;
        _weekToMultiplier[65] = 2.73 ether;
        _weekToMultiplier[66] = 2.76 ether;
        _weekToMultiplier[67] = 2.8 ether;
        _weekToMultiplier[68] = 2.84 ether;
        _weekToMultiplier[69] = 2.88 ether;
        _weekToMultiplier[70] = 2.91 ether;
        _weekToMultiplier[71] = 2.95 ether;
        _weekToMultiplier[72] = 2.99 ether;
        _weekToMultiplier[73] = 3.03 ether;
        _weekToMultiplier[74] = 3.07 ether;
        _weekToMultiplier[75] = 3.11 ether;
        _weekToMultiplier[76] = 3.15 ether;
        _weekToMultiplier[77] = 3.19 ether;
        _weekToMultiplier[78] = 3.23 ether;
        _weekToMultiplier[79] = 3.27 ether;
        _weekToMultiplier[80] = 3.31 ether;
        _weekToMultiplier[81] = 3.35 ether;
        _weekToMultiplier[82] = 3.39 ether;
        _weekToMultiplier[83] = 3.43 ether;
        _weekToMultiplier[84] = 3.47 ether;
        _weekToMultiplier[85] = 3.51 ether;
        _weekToMultiplier[86] = 3.55 ether;
        _weekToMultiplier[87] = 3.6 ether;
        _weekToMultiplier[88] = 3.64 ether;
        _weekToMultiplier[89] = 3.68 ether;
        _weekToMultiplier[90] = 3.72 ether;
        _weekToMultiplier[91] = 3.76 ether;
        _weekToMultiplier[92] = 3.81 ether;
        _weekToMultiplier[93] = 3.85 ether;
        _weekToMultiplier[94] = 3.89 ether;
        _weekToMultiplier[95] = 3.94 ether;
        _weekToMultiplier[96] = 3.98 ether;
        _weekToMultiplier[97] = 4.02 ether;
        _weekToMultiplier[98] = 4.07 ether;
        _weekToMultiplier[99] = 4.11 ether;
        _weekToMultiplier[100] = 4.15 ether;
        _weekToMultiplier[101] = 4.2 ether;
        _weekToMultiplier[102] = 4.24 ether;
        _weekToMultiplier[103] = 4.29 ether;
        _weekToMultiplier[104] = 4.33 ether;
        _weekToMultiplier[105] = 4.38 ether;
        _weekToMultiplier[106] = 4.42 ether;
        _weekToMultiplier[107] = 4.47 ether;
        _weekToMultiplier[108] = 4.51 ether;
        _weekToMultiplier[109] = 4.56 ether;
        _weekToMultiplier[110] = 4.61 ether;
        _weekToMultiplier[111] = 4.65 ether;
        _weekToMultiplier[112] = 4.7 ether;
        _weekToMultiplier[113] = 4.74 ether;
        _weekToMultiplier[114] = 4.79 ether;
        _weekToMultiplier[115] = 4.84 ether;
        _weekToMultiplier[116] = 4.88 ether;
        _weekToMultiplier[117] = 4.93 ether;
        _weekToMultiplier[118] = 4.98 ether;
        _weekToMultiplier[119] = 5.02 ether;
        _weekToMultiplier[120] = 5.07 ether;
        _weekToMultiplier[121] = 5.12 ether;
        _weekToMultiplier[122] = 5.17 ether;
        _weekToMultiplier[123] = 5.22 ether;
        _weekToMultiplier[124] = 5.26 ether;
        _weekToMultiplier[125] = 5.31 ether;
        _weekToMultiplier[126] = 5.36 ether;
        _weekToMultiplier[127] = 5.41 ether;
        _weekToMultiplier[128] = 5.46 ether;
        _weekToMultiplier[129] = 5.51 ether;
        _weekToMultiplier[130] = 5.56 ether;
        _weekToMultiplier[131] = 5.6 ether;
        _weekToMultiplier[132] = 5.65 ether;
        _weekToMultiplier[133] = 5.7 ether;
        _weekToMultiplier[134] = 5.75 ether;
        _weekToMultiplier[135] = 5.8 ether;
        _weekToMultiplier[136] = 5.85 ether;
        _weekToMultiplier[137] = 5.9 ether;
        _weekToMultiplier[138] = 5.95 ether;
        _weekToMultiplier[139] = 6.0 ether;
        _weekToMultiplier[140] = 6.05 ether;
        _weekToMultiplier[141] = 6.1 ether;
        _weekToMultiplier[142] = 6.15 ether;
        _weekToMultiplier[143] = 6.21 ether;
        _weekToMultiplier[144] = 6.26 ether;
        _weekToMultiplier[145] = 6.31 ether;
        _weekToMultiplier[146] = 6.36 ether;
        _weekToMultiplier[147] = 6.41 ether;
        _weekToMultiplier[148] = 6.46 ether;
        _weekToMultiplier[149] = 6.51 ether;
        _weekToMultiplier[150] = 6.57 ether;
        _weekToMultiplier[151] = 6.62 ether;
        _weekToMultiplier[152] = 6.67 ether;
        _weekToMultiplier[153] = 6.72 ether;
        _weekToMultiplier[154] = 6.77 ether;
        _weekToMultiplier[155] = 6.83 ether;
        _weekToMultiplier[156] = 6.88 ether;
        _weekToMultiplier[157] = 6.93 ether;
        _weekToMultiplier[158] = 6.99 ether;
        _weekToMultiplier[159] = 7.04 ether;
        _weekToMultiplier[160] = 7.09 ether;
        _weekToMultiplier[161] = 7.15 ether;
        _weekToMultiplier[162] = 7.2 ether;
        _weekToMultiplier[163] = 7.25 ether;
        _weekToMultiplier[164] = 7.31 ether;
        _weekToMultiplier[165] = 7.36 ether;
        _weekToMultiplier[166] = 7.41 ether;
        _weekToMultiplier[167] = 7.47 ether;
        _weekToMultiplier[168] = 7.52 ether;
        _weekToMultiplier[169] = 7.58 ether;
        _weekToMultiplier[170] = 7.63 ether;
        _weekToMultiplier[171] = 7.69 ether;
        _weekToMultiplier[172] = 7.74 ether;
        _weekToMultiplier[173] = 7.8 ether;
        _weekToMultiplier[174] = 7.85 ether;
        _weekToMultiplier[175] = 7.91 ether;
        _weekToMultiplier[176] = 7.96 ether;
        _weekToMultiplier[177] = 8.02 ether;
        _weekToMultiplier[178] = 8.07 ether;
        _weekToMultiplier[179] = 8.13 ether;
        _weekToMultiplier[180] = 8.18 ether;
        _weekToMultiplier[181] = 8.24 ether;
        _weekToMultiplier[182] = 8.3 ether;
        _weekToMultiplier[183] = 8.35 ether;
        _weekToMultiplier[184] = 8.41 ether;
        _weekToMultiplier[185] = 8.46 ether;
        _weekToMultiplier[186] = 8.52 ether;
        _weekToMultiplier[187] = 8.58 ether;
        _weekToMultiplier[188] = 8.63 ether;
        _weekToMultiplier[189] = 8.69 ether;
        _weekToMultiplier[190] = 8.75 ether;
        _weekToMultiplier[191] = 8.81 ether;
        _weekToMultiplier[192] = 8.86 ether;
        _weekToMultiplier[193] = 8.92 ether;
        _weekToMultiplier[194] = 8.98 ether;
        _weekToMultiplier[195] = 9.04 ether;
        _weekToMultiplier[196] = 9.09 ether;
        _weekToMultiplier[197] = 9.15 ether;
        _weekToMultiplier[198] = 9.21 ether;
        _weekToMultiplier[199] = 9.27 ether;
        _weekToMultiplier[200] = 9.33 ether;
        _weekToMultiplier[201] = 9.38 ether;
        _weekToMultiplier[202] = 9.44 ether;
        _weekToMultiplier[203] = 9.5 ether;
        _weekToMultiplier[204] = 9.56 ether;
        _weekToMultiplier[205] = 9.62 ether;
        _weekToMultiplier[206] = 9.68 ether;
        _weekToMultiplier[207] = 9.74 ether;
        _weekToMultiplier[208] = 9.8 ether;
        _weekToMultiplier[209] = 9.85 ether;
        _weekToMultiplier[210] = 9.91 ether;
        _weekToMultiplier[211] = 9.97 ether;
        _weekToMultiplier[212] = 10.03 ether;
        _weekToMultiplier[213] = 10.09 ether;
        _weekToMultiplier[214] = 10.15 ether;
        _weekToMultiplier[215] = 10.21 ether;
        _weekToMultiplier[216] = 10.27 ether;
        _weekToMultiplier[217] = 10.33 ether;
        _weekToMultiplier[218] = 10.39 ether;
        _weekToMultiplier[219] = 10.45 ether;
        _weekToMultiplier[220] = 10.51 ether;
        _weekToMultiplier[221] = 10.57 ether;
        _weekToMultiplier[222] = 10.64 ether;
        _weekToMultiplier[223] = 10.7 ether;
        _weekToMultiplier[224] = 10.76 ether;
        _weekToMultiplier[225] = 10.82 ether;
        _weekToMultiplier[226] = 10.88 ether;
        _weekToMultiplier[227] = 10.94 ether;
        _weekToMultiplier[228] = 11.0 ether;
        _weekToMultiplier[229] = 11.06 ether;
        _weekToMultiplier[230] = 11.12 ether;
        _weekToMultiplier[231] = 11.19 ether;
        _weekToMultiplier[232] = 11.25 ether;
        _weekToMultiplier[233] = 11.31 ether;
        _weekToMultiplier[234] = 11.37 ether;
        _weekToMultiplier[235] = 11.43 ether;
        _weekToMultiplier[236] = 11.5 ether;
        _weekToMultiplier[237] = 11.56 ether;
        _weekToMultiplier[238] = 11.62 ether;
        _weekToMultiplier[239] = 11.68 ether;
        _weekToMultiplier[240] = 11.75 ether;
        _weekToMultiplier[241] = 11.81 ether;
        _weekToMultiplier[242] = 11.87 ether;
        _weekToMultiplier[243] = 11.93 ether;
        _weekToMultiplier[244] = 12.0 ether;
        _weekToMultiplier[245] = 12.06 ether;
        _weekToMultiplier[246] = 12.12 ether;
        _weekToMultiplier[247] = 12.19 ether;
        _weekToMultiplier[248] = 12.25 ether;
        _weekToMultiplier[249] = 12.31 ether;
        _weekToMultiplier[250] = 12.38 ether;
        _weekToMultiplier[251] = 12.44 ether;
        _weekToMultiplier[252] = 12.51 ether;
        _weekToMultiplier[253] = 12.57 ether;
        _weekToMultiplier[254] = 12.63 ether;
        _weekToMultiplier[255] = 12.7 ether;
        _weekToMultiplier[256] = 12.76 ether;
        _weekToMultiplier[257] = 12.83 ether;
        _weekToMultiplier[258] = 12.89 ether;
        _weekToMultiplier[259] = 12.96 ether;
        _weekToMultiplier[260] = 13.02 ether;
        _weekToMultiplier[261] = 13.09 ether;
        _weekToMultiplier[262] = 13.15 ether;
        _weekToMultiplier[263] = 13.22 ether;
        _weekToMultiplier[264] = 13.28 ether;
        _weekToMultiplier[265] = 13.35 ether;
        _weekToMultiplier[266] = 13.41 ether;
        _weekToMultiplier[267] = 13.48 ether;
        _weekToMultiplier[268] = 13.54 ether;
        _weekToMultiplier[269] = 13.61 ether;
        _weekToMultiplier[270] = 13.67 ether;
        _weekToMultiplier[271] = 13.74 ether;
        _weekToMultiplier[272] = 13.8 ether;
        _weekToMultiplier[273] = 13.87 ether;
        _weekToMultiplier[274] = 13.94 ether;
        _weekToMultiplier[275] = 14.0 ether;
        _weekToMultiplier[276] = 14.07 ether;
        _weekToMultiplier[277] = 14.14 ether;
        _weekToMultiplier[278] = 14.2 ether;
        _weekToMultiplier[279] = 14.27 ether;
        _weekToMultiplier[280] = 14.33 ether;
        _weekToMultiplier[281] = 14.4 ether;
        _weekToMultiplier[282] = 14.47 ether;
        _weekToMultiplier[283] = 14.54 ether;
        _weekToMultiplier[284] = 14.6 ether;
        _weekToMultiplier[285] = 14.67 ether;
        _weekToMultiplier[286] = 14.74 ether;
        _weekToMultiplier[287] = 14.8 ether;
        _weekToMultiplier[288] = 14.87 ether;
        _weekToMultiplier[289] = 14.94 ether;
        _weekToMultiplier[290] = 15.01 ether;
        _weekToMultiplier[291] = 15.07 ether;
        _weekToMultiplier[292] = 15.14 ether;
        _weekToMultiplier[293] = 15.21 ether;
        _weekToMultiplier[294] = 15.28 ether;
        _weekToMultiplier[295] = 15.35 ether;
        _weekToMultiplier[296] = 15.41 ether;
        _weekToMultiplier[297] = 15.48 ether;
        _weekToMultiplier[298] = 15.55 ether;
        _weekToMultiplier[299] = 15.62 ether;
        _weekToMultiplier[300] = 15.69 ether;
        _weekToMultiplier[301] = 15.76 ether;
        _weekToMultiplier[302] = 15.82 ether;
        _weekToMultiplier[303] = 15.89 ether;
        _weekToMultiplier[304] = 15.96 ether;
        _weekToMultiplier[305] = 16.03 ether;
        _weekToMultiplier[306] = 16.1 ether;
        _weekToMultiplier[307] = 16.17 ether;
        _weekToMultiplier[308] = 16.24 ether;
        _weekToMultiplier[309] = 16.31 ether;
        _weekToMultiplier[310] = 16.38 ether;
        _weekToMultiplier[311] = 16.45 ether;
        _weekToMultiplier[312] = 16.52 ether;
        _weekToMultiplier[313] = 16.59 ether;
        _weekToMultiplier[314] = 16.66 ether;
        _weekToMultiplier[315] = 16.73 ether;
        _weekToMultiplier[316] = 16.8 ether;
        _weekToMultiplier[317] = 16.87 ether;
        _weekToMultiplier[318] = 16.94 ether;
        _weekToMultiplier[319] = 17.01 ether;
        _weekToMultiplier[320] = 17.08 ether;
        _weekToMultiplier[321] = 17.15 ether;
        _weekToMultiplier[322] = 17.22 ether;
        _weekToMultiplier[323] = 17.29 ether;
        _weekToMultiplier[324] = 17.36 ether;
        _weekToMultiplier[325] = 17.43 ether;
        _weekToMultiplier[326] = 17.5 ether;
        _weekToMultiplier[327] = 17.57 ether;
        _weekToMultiplier[328] = 17.64 ether;
        _weekToMultiplier[329] = 17.71 ether;
        _weekToMultiplier[330] = 17.78 ether;
        _weekToMultiplier[331] = 17.86 ether;
        _weekToMultiplier[332] = 17.93 ether;
        _weekToMultiplier[333] = 18.0 ether;
        _weekToMultiplier[334] = 18.07 ether;
        _weekToMultiplier[335] = 18.14 ether;
        _weekToMultiplier[336] = 18.21 ether;
        _weekToMultiplier[337] = 18.28 ether;
        _weekToMultiplier[338] = 18.36 ether;
        _weekToMultiplier[339] = 18.43 ether;
        _weekToMultiplier[340] = 18.5 ether;
        _weekToMultiplier[341] = 18.57 ether;
        _weekToMultiplier[342] = 18.64 ether;
        _weekToMultiplier[343] = 18.72 ether;
        _weekToMultiplier[344] = 18.79 ether;
        _weekToMultiplier[345] = 18.86 ether;
        _weekToMultiplier[346] = 18.93 ether;
        _weekToMultiplier[347] = 19.01 ether;
        _weekToMultiplier[348] = 19.08 ether;
        _weekToMultiplier[349] = 19.15 ether;
        _weekToMultiplier[350] = 19.22 ether;
        _weekToMultiplier[351] = 19.3 ether;
        _weekToMultiplier[352] = 19.37 ether;
        _weekToMultiplier[353] = 19.44 ether;
        _weekToMultiplier[354] = 19.52 ether;
        _weekToMultiplier[355] = 19.59 ether;
        _weekToMultiplier[356] = 19.66 ether;
        _weekToMultiplier[357] = 19.74 ether;
        _weekToMultiplier[358] = 19.81 ether;
        _weekToMultiplier[359] = 19.88 ether;
        _weekToMultiplier[360] = 19.96 ether;
        _weekToMultiplier[361] = 20.03 ether;
        _weekToMultiplier[362] = 20.11 ether;
        _weekToMultiplier[363] = 20.18 ether;
        _weekToMultiplier[364] = 20.25 ether;
        _weekToMultiplier[365] = 20.33 ether;
        _weekToMultiplier[366] = 20.4 ether;
        _weekToMultiplier[367] = 20.48 ether;
        _weekToMultiplier[368] = 20.55 ether;
        _weekToMultiplier[369] = 20.62 ether;
        _weekToMultiplier[370] = 20.7 ether;
        _weekToMultiplier[371] = 20.77 ether;
        _weekToMultiplier[372] = 20.85 ether;
        _weekToMultiplier[373] = 20.92 ether;
        _weekToMultiplier[374] = 21.0 ether;
        _weekToMultiplier[375] = 21.07 ether;
        _weekToMultiplier[376] = 21.15 ether;
        _weekToMultiplier[377] = 21.22 ether;
        _weekToMultiplier[378] = 21.3 ether;
        _weekToMultiplier[379] = 21.37 ether;
        _weekToMultiplier[380] = 21.45 ether;
        _weekToMultiplier[381] = 21.52 ether;
        _weekToMultiplier[382] = 21.6 ether;
        _weekToMultiplier[383] = 21.68 ether;
        _weekToMultiplier[384] = 21.75 ether;
        _weekToMultiplier[385] = 21.83 ether;
        _weekToMultiplier[386] = 21.9 ether;
        _weekToMultiplier[387] = 21.98 ether;
        _weekToMultiplier[388] = 22.05 ether;
        _weekToMultiplier[389] = 22.13 ether;
        _weekToMultiplier[390] = 22.21 ether;
        _weekToMultiplier[391] = 22.28 ether;
        _weekToMultiplier[392] = 22.36 ether;
        _weekToMultiplier[393] = 22.43 ether;
        _weekToMultiplier[394] = 22.51 ether;
        _weekToMultiplier[395] = 22.59 ether;
        _weekToMultiplier[396] = 22.66 ether;
        _weekToMultiplier[397] = 22.74 ether;
        _weekToMultiplier[398] = 22.82 ether;
        _weekToMultiplier[399] = 22.89 ether;
        _weekToMultiplier[400] = 22.97 ether;
        _weekToMultiplier[401] = 23.05 ether;
        _weekToMultiplier[402] = 23.13 ether;
        _weekToMultiplier[403] = 23.2 ether;
        _weekToMultiplier[404] = 23.28 ether;
        _weekToMultiplier[405] = 23.36 ether;
        _weekToMultiplier[406] = 23.43 ether;
        _weekToMultiplier[407] = 23.51 ether;
        _weekToMultiplier[408] = 23.59 ether;
        _weekToMultiplier[409] = 23.67 ether;
        _weekToMultiplier[410] = 23.74 ether;
        _weekToMultiplier[411] = 23.82 ether;
        _weekToMultiplier[412] = 23.9 ether;
        _weekToMultiplier[413] = 23.98 ether;
        _weekToMultiplier[414] = 24.06 ether;
        _weekToMultiplier[415] = 24.13 ether;
        _weekToMultiplier[416] = 24.21 ether;
        _weekToMultiplier[417] = 24.29 ether;
        _weekToMultiplier[418] = 24.37 ether;
        _weekToMultiplier[419] = 24.45 ether;
        _weekToMultiplier[420] = 24.52 ether;
        _weekToMultiplier[421] = 24.6 ether;
        _weekToMultiplier[422] = 24.68 ether;
        _weekToMultiplier[423] = 24.76 ether;
        _weekToMultiplier[424] = 24.84 ether;
        _weekToMultiplier[425] = 24.92 ether;
        _weekToMultiplier[426] = 25.0 ether;
        _weekToMultiplier[427] = 25.08 ether;
        _weekToMultiplier[428] = 25.15 ether;
        _weekToMultiplier[429] = 25.23 ether;
        _weekToMultiplier[430] = 25.31 ether;
        _weekToMultiplier[431] = 25.39 ether;
        _weekToMultiplier[432] = 25.47 ether;
        _weekToMultiplier[433] = 25.55 ether;
        _weekToMultiplier[434] = 25.63 ether;
        _weekToMultiplier[435] = 25.71 ether;
        _weekToMultiplier[436] = 25.79 ether;
        _weekToMultiplier[437] = 25.87 ether;
        _weekToMultiplier[438] = 25.95 ether;
        _weekToMultiplier[439] = 26.03 ether;
        _weekToMultiplier[440] = 26.11 ether;
        _weekToMultiplier[441] = 26.19 ether;
        _weekToMultiplier[442] = 26.27 ether;
        _weekToMultiplier[443] = 26.35 ether;
        _weekToMultiplier[444] = 26.43 ether;
        _weekToMultiplier[445] = 26.51 ether;
        _weekToMultiplier[446] = 26.59 ether;
        _weekToMultiplier[447] = 26.67 ether;
        _weekToMultiplier[448] = 26.75 ether;
        _weekToMultiplier[449] = 26.83 ether;
        _weekToMultiplier[450] = 26.91 ether;
        _weekToMultiplier[451] = 26.99 ether;
        _weekToMultiplier[452] = 27.07 ether;
        _weekToMultiplier[453] = 27.15 ether;
        _weekToMultiplier[454] = 27.23 ether;
        _weekToMultiplier[455] = 27.31 ether;
        _weekToMultiplier[456] = 27.39 ether;
        _weekToMultiplier[457] = 27.48 ether;
        _weekToMultiplier[458] = 27.56 ether;
        _weekToMultiplier[459] = 27.64 ether;
        _weekToMultiplier[460] = 27.72 ether;
        _weekToMultiplier[461] = 27.8 ether;
        _weekToMultiplier[462] = 27.88 ether;
        _weekToMultiplier[463] = 27.96 ether;
        _weekToMultiplier[464] = 28.05 ether;
        _weekToMultiplier[465] = 28.13 ether;
        _weekToMultiplier[466] = 28.21 ether;
        _weekToMultiplier[467] = 28.29 ether;
        _weekToMultiplier[468] = 28.37 ether;
        _weekToMultiplier[469] = 28.45 ether;
        _weekToMultiplier[470] = 28.54 ether;
        _weekToMultiplier[471] = 28.62 ether;
        _weekToMultiplier[472] = 28.7 ether;
        _weekToMultiplier[473] = 28.78 ether;
        _weekToMultiplier[474] = 28.87 ether;
        _weekToMultiplier[475] = 28.95 ether;
        _weekToMultiplier[476] = 29.03 ether;
        _weekToMultiplier[477] = 29.11 ether;
        _weekToMultiplier[478] = 29.19 ether;
        _weekToMultiplier[479] = 29.28 ether;
        _weekToMultiplier[480] = 29.36 ether;
        _weekToMultiplier[481] = 29.44 ether;
        _weekToMultiplier[482] = 29.53 ether;
        _weekToMultiplier[483] = 29.61 ether;
        _weekToMultiplier[484] = 29.69 ether;
        _weekToMultiplier[485] = 29.77 ether;
        _weekToMultiplier[486] = 29.86 ether;
        _weekToMultiplier[487] = 29.94 ether;
        _weekToMultiplier[488] = 30.02 ether;
        _weekToMultiplier[489] = 30.11 ether;
        _weekToMultiplier[490] = 30.19 ether;
        _weekToMultiplier[491] = 30.27 ether;
        _weekToMultiplier[492] = 30.36 ether;
        _weekToMultiplier[493] = 30.44 ether;
        _weekToMultiplier[494] = 30.52 ether;
        _weekToMultiplier[495] = 30.61 ether;
        _weekToMultiplier[496] = 30.69 ether;
        _weekToMultiplier[497] = 30.78 ether;
        _weekToMultiplier[498] = 30.86 ether;
        _weekToMultiplier[499] = 30.94 ether;
        _weekToMultiplier[500] = 31.03 ether;
        _weekToMultiplier[501] = 31.11 ether;
        _weekToMultiplier[502] = 31.2 ether;
        _weekToMultiplier[503] = 31.28 ether;
        _weekToMultiplier[504] = 31.36 ether;
        _weekToMultiplier[505] = 31.45 ether;
        _weekToMultiplier[506] = 31.53 ether;
        _weekToMultiplier[507] = 31.62 ether;
        _weekToMultiplier[508] = 31.7 ether;
        _weekToMultiplier[509] = 31.79 ether;
        _weekToMultiplier[510] = 31.87 ether;
        _weekToMultiplier[511] = 31.96 ether;
        _weekToMultiplier[512] = 32.04 ether;
        _weekToMultiplier[513] = 32.13 ether;
        _weekToMultiplier[514] = 32.21 ether;
        _weekToMultiplier[515] = 32.3 ether;
        _weekToMultiplier[516] = 32.38 ether;
        _weekToMultiplier[517] = 32.47 ether;
        _weekToMultiplier[518] = 32.55 ether;
        _weekToMultiplier[519] = 32.64 ether;
        _weekToMultiplier[520] = 32.72 ether;
    }

}