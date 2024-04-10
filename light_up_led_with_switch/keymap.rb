# 21番ピンに接続されたLEDを22番ピンに接続したスイッチで点灯させるプログラム
led_pin = GPIO.new(16, GPIO::OUT)
switch_pin = GPIO.new(17, GPIO::IN)

loop do
  if switch_pin.read == 0
    led_pin.write(1)
  else
    led_pin.write(0)
  end
end
