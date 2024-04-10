とりあえず以下のブログに従ってやってみたが、require しても undefined constant と言われた
https://broad-deep.com/gadget/pc/prk-oled-with-require/

なんかだめぽいので、requre せずに実行してみた。

```
Failed to compile keymap.rb
```

と言われた。while の式のところが怪しいので変えた。
html エスケープっぽい感じになってたので、普通の不等式に変えたら一応動いたけど、なんか変。真っ黒になってほしいのに横縞になっとる

以下のサイトを参考にした
[OLED SSD01306 (I2C接続)](http://try3dcg.world.coocan.jp/note/i2c/ssd1306.html)

コマンドは3パターンあるが、I2Cアドレス送信後、次の送信で何を送るかで3パターンのコマンドが決まる。
- 1byte 命令タグ(0x80)
- 複数byte 命令タグ(0x80)
- 複数byte データタグ(0x80)

all_clear 外側のループで行っているのは以下の命令
第一引数はアドレス、第2引数の1つ目は 0x80 なので、1byte命令であることがわかる。2つ目は`0xb0 | i` で、描画ページ指定(0xb0~0xb7)
描画ページを指定しているのがわかる
```rb
@i2c.write(0x3C, [0b10000000, 0xB0 | i])
```

つぎに、その中の命令を見る
1行目は複数命令
https://akizukidenshi.com/goodsaffix/ssd1306.pdf
データシートの30ページ目に書いてある、カラムアドレスの指定っぽい。
```rb
while j<128 do
	@i2c.write(0x3C, [0x00, 0x21, 0x00 | j, 0x00 | j+1])
	@i2c.write(0x3C, [0b01000000, 0x55])
	j=j+1
end
```

