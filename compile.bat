cd D:/nes_work/

cc65/bin/ca65 "C:/Bufo_bufo/override_failed/cart.s" -o "C:/Bufo_bufo/override_failed/cart.o" -t nes
cc65/bin/ld65 "C:/Bufo_bufo/override_failed/cart.o" -o "C:/Bufo_bufo/override_failed/cart.nes" -t nes

cd C:/Bufo_bufo/override_failed/

