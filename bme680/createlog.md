https://www.bosch-sensortec.com/media/boschsensortec/downloads/datasheets/bst-bme680-ds001.pdf

https://zenn.dev/k_takata/books/d5c77046e634bb/viewer/05_i2c_bme680

校正用の値の取得、一気にやっているのが気になる。
データシートの memory map (p28) を見ると、校正用の値の場所は特に書いてないように見える。

LSB, MSBってなんだ？
調べてもよくわからんかった

https://github.com/boschsensortec/BME68x_SensorAPI/blob/80ea120a8b8ac987d7d79eb68a9ed796736be845/bme68x.c#L1791-L1836
caliblation 用コード



校正用パラメータのアドレス

0xEA par_t1_MSB
0xE9 par_t1_LSB
0xE8 par_h7
0xE7 par_h6
0xE6 par_h5
0xE5 par_h4
0xE4 par_h3
0xE3 par_h1_MSB
0xE2<3:0> par_h1_LSB
0xE2<7:4> par_h2_LSB
0xE1 par_h2


0xA0 par_p10
0x9F par_p9_MSB
0x9E par_p9_LSB
0x9D par_p8_MSB
0x9C par_p8_LSB
0x99 par_p6
0x98 par_p7
0x97 par_p5_MSB
0x96 par_p5_LSB
0x95 par_p4_MSB
0x94 par_p4_LSB
0x92 par_p3
0x91 par_p2_MSB
0x90 par_p2_LSB
0x8F par_p1_MSB
0x8E par_p1_LSB
0x8C par_t3
0x8B par_t2_MSB
0x8A par_t2_LSB
