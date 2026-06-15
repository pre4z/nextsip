import RPi.GPIO as GPIO
from RPLCD.i2c import CharLCD
from time import sleep, time
import board
import busio
from digitalio import DigitalInOut
from adafruit_pn532.spi import PN532_SPI

import db

# DATABASE
db.init_db()

# NFC / PN532 SETUP
spi = busio.SPI(board.SCK, board.MOSI, board.MISO)
cs_pin = DigitalInOut(board.D5)
pn532 = PN532_SPI(spi, cs_pin, debug=False)
pn532.SAM_configuration()


def read_card_uid(timeout=0.3):
    """Laeser UID for det paalagte kort som hex-string, eller None."""
    try:
        uid = pn532.read_passive_target(timeout=timeout)
    except RuntimeError:
        return None
    if uid is None:
        return None
    return db.uid_to_str(uid)


# GPIO SETUP
BUTTON_PIN = 16
RELAY_PIN = 26

GPIO.setmode(GPIO.BCM)

# Knap
GPIO.setup(BUTTON_PIN, GPIO.IN, pull_up_down=GPIO.PUD_UP)

# Relae
# HIGH = fra
# LOW = TIL
GPIO.setup(RELAY_PIN, GPIO.OUT)
GPIO.output(RELAY_PIN, GPIO.HIGH)

# LCD SETUP
lcd = CharLCD('PCF8574', 0x27)


MENU = [
    {"type": "drink", "name": "Tasting", "price": 5, "pump_time": 2},
    {"type": "drink", "name": "Mellem glas", "price": 20, "pump_time": 5},
    {"type": "drink", "name": "Fuld glas", "price": 35, "pump_time": 8},
    {"type": "balance", "name": "Se saldo"},
]
selected_index = 0

# menu
HOME_SCREENS = [
    ("Velkommen!", "Kort tryk: menu"),
    ("Kort tryk:", "skift valg"),
    ("Langt tryk (3s):", "vaelg/betal"),
    ("Se dit saldo", "i menuen"),
]

IDLE_TIMEOUT = 10          # sek. uden tryk -> tilbage til forsiden
HOME_SCREEN_INTERVAL = 3   # sek. mellem hver infoskaerm


def lcd_show(line1="", line2=""):
    lcd.clear()
    lcd.write_string(line1[:16])
    if line2:
        lcd.cursor_pos = (1, 0)
        lcd.write_string(line2[:16])


def show_menu():
    item = MENU[selected_index]
    if item["type"] == "drink":
        lcd_show(f"> {item['name']}", f"Pris: {item['price']} kr")
    else:
        lcd_show(f"> {item['name']}", "(langt tryk)")


def pump_on():
    GPIO.output(RELAY_PIN, GPIO.LOW)


def pump_off():
    GPIO.output(RELAY_PIN, GPIO.HIGH)


def wait_for_card(timeout=5):
    """Venter op til 'timeout' sekunder paa et kort.
    Returnerer UID-string eller None"""
    start = time()
    while time() - start < timeout:
        uid_str = read_card_uid()
        if uid_str is not None:
            return uid_str
        sleep(0.1)
    return None


def dispense(item):
    name = item["name"]
    price = item["price"]
    pump_time = item["pump_time"]

    lcd_show("Laeg kort paa", "for at betale")

    uid_str = wait_for_card()
    if uid_str is None:
        lcd_show("Intet kort", "fundet")
        sleep(2)
        return

    # Opretter kortet med saldo 0 i backend, hvis det er nyt
    try:
        db.ensure_card(uid_str)
    except Exception:
        lcd_show("Serverfejl", "Proev igen")
        sleep(2)
        return

    lcd_show("Skaenker...", name)
    pump_on()
    sleep(pump_time)
    pump_off()

    try:
        new_balance = db.add_to_balance(uid_str, name, price)
    except Exception:
        # Drikken er allerede skaenket, men kunne ikke bogfoeres -
        # vis en advarsel saa personalet kan rette det manuelt.
        lcd_show("Drik givet,", "ikke booket!")
        sleep(3)
        return

    lcd_show("Faerdig!", f"Saldo:{new_balance}kr")
    sleep(2)


def show_balance():
    lcd_show("Laeg kort paa", "for at se saldo")

    uid_str = wait_for_card()
    if uid_str is None:
        lcd_show("Intet kort", "fundet")
        sleep(2)
        return

    try:
        balance = db.get_balance(uid_str)
    except Exception:
        lcd_show("Serverfejl", "Proev igen")
        sleep(2)
        return

    lcd_show("Dit saldo:", f"{balance} kr")
    sleep(2)


def show_home_screen():
    global home_screen_index, last_home_change
    line1, line2 = HOME_SCREENS[home_screen_index]
    lcd_show(line1, line2)
    home_screen_index = (home_screen_index + 1) % len(HOME_SCREENS)
    last_home_change = time()



# Sstartskaerm
lcd_show("NextSip", "Starter...")
sleep(2)

home_screen_index = 0
last_home_change = time()
last_interaction = time()
state = "HOME"

show_home_screen()

# HOVEDLOOP
try:
    while True:
        if GPIO.input(BUTTON_PIN) == GPIO.LOW:
            press_start = time()
            while GPIO.input(BUTTON_PIN) == GPIO.LOW:
                sleep(0.05)
            press_duration = time() - press_start

            if press_duration >= 3:
                item = MENU[selected_index]
                if item["type"] == "drink":
                    dispense(item)
                else:
                    show_balance()
                show_menu()
            else:
                selected_index = (selected_index + 1) % len(MENU)
                show_menu()

            state = "MENU"
            last_interaction = time()
            sleep(0.2)
        else:
            if state == "MENU" and (time() - last_interaction) > IDLE_TIMEOUT:
                state = "HOME"
                home_screen_index = 0
                show_home_screen()
            elif state == "HOME" and (time() - last_home_change) > HOME_SCREEN_INTERVAL:
                show_home_screen()
            sleep(0.05)
except KeyboardInterrupt:
    pass
finally:
    pump_off()
    lcd.clear()
    GPIO.cleanup()
