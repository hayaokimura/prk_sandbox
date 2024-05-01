require 'pwm'
# 21番ピンに接続されたLEDを22番ピンに接続したスイッチで点灯させるプログラム
switch_pin = GPIO.new(17, GPIO::IN)
pin = GPIO.new(25, GPIO::OUT)
pin.write(1)
pwm = PWM.new(16, frequency: 100000, duty: 100)

loop do
  if switch_pin.read == 1
    pwm.duty(25)
  else
    pwm.duty(100)
  end
end
