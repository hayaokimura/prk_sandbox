# 21番ピンに接続されたLEDを22番ピンに接続したスイッチで点灯させるプログラム
led_pin = GPIO.new(16, GPIO::OUT)
switch_pin = GPIO.new(17, GPIO::IN)

led_pin.write(1)
sleep 1
if switch_pin.read == 1
  led_pin.write(1)
else
  led_pin.write(0)
end
