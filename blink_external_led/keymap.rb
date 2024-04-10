# 21番ピンに接続されたLEDを点滅させるプログラム
pin = GPIO.new(16, GPIO::OUT)

loop do
  pin.write(1)
  sleep 1
  pin.write(0)
  sleep 1
end
