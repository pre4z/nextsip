# test om displayet virker
from RPLCD.i2c import CharLCD
from time import sleep

ADDRESS = 0x27

lcd = CharLCD('PCF8574', ADDRESS)

lcd.clear()
lcd.write_string("Hello World!")
lcd.cursor_pos = (1, 0)
lcd.write_string("LCD Test OK")

try:
    while True:
        sleep(1)
except KeyboardInterrupt:
    lcd.clear()
