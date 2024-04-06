# ラズパイピコでは、GPIOの25番が
# ボード上のLEDにつながっている
pin = GPIO.new(25, GPIO::OUT)

loop do
  pin.write(1)
  sleep 1
  pin.write(0)
  sleep 1
end

# GPIO_OUT = 1
# GPIO_IN  = 0
# HI = 1
# LO = 0
#
# # ラズパイピコでは、GPIOの25番が
# # ボード上のLEDにつながっている
# pin = 25
# # そのピンを初期化
# gpio_init(pin)
# # そのピンを出力ピンとして設定
# gpio_set_dir(pin, GPIO_OUT)
# # 無限ループ
# while true
#   # 出力をハイに（電圧をかける）
#   gpio_put(pin, HI)
#   # 1秒休み
#   sleep 1
#   # 出力をローに（電圧をゼロにする）
#   gpio_put(pin, LO)
#   # 1秒休み
#   sleep 1
# end
