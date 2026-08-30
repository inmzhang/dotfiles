-- Use F9 as Print Screen on keyboards without a dedicated key.
hl.unbind("F9") -- Omarchy default: push-to-talk dictation
o.bind("F9", "Screenshot", "omarchy-capture-screenshot")
o.bind("ALT + F9", "Screenrecording", "omarchy-capture-screenrecording --stop-recording || omarchy-menu toggle trigger.capture.screenrecord")
o.bind("SUPER + F9", "Color picker", "pkill hyprpicker || hyprpicker -a")
o.bind("SUPER + CTRL + F9", "Extract text (OCR) from screenshot", "omarchy-capture-text")
