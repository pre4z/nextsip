# test button
import RPi.GPIO as GPIO
from time import sleep

BUTTON_PIN = 16

GPIO.setmode(GPIO.BCM)
GPIO.setup(BUTTON_PIN, GPIO.IN, pull_up_down=GPIO.PUD_UP)


try:
    while True:
        print("Button:", GPIO.input(BUTTON_PIN))
        sleep(0.8)
except KeyboardInterrupt:
    GPIO.cleanup()
