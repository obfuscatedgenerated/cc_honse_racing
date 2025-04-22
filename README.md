# ComputerCraft Honse Racing

> [That horse racing you see on Twitter](https://x.com/snakesandrews) but in ComputerCraft!

Depends on the great [OBSI2 library](https://github.com/simadude/obsi2) to be installed into the `/lib/` directory [(or use the installer!)](#installer)

Run with `honse/init` or write your custom logic with `local game_loop = require "honse/game_loop"`, where you can [add hooks](game_loop.lua) and then [run the loop](init.lua)

`init_with_events.lua` is an example of event hooking (not included with installer).

Designed for an advanced 8x4 monitor cluster (largest approximately widescreen cluster). You can also remove some monitors from the right to form a 4:3 shape if the right column messages are not required (depends if you wish to add custom overlays and behaviour with hooks or just leave the game as a thing to look at).

## Installer

`wget run https://github.com/obfuscatedgenerated/cc_honse_racing/raw/refs/heads/main/install/install.lua`

or `git clone https://github.com/obfuscatedgenerated/cc_honse_racing.git honse` and manually add OBSI2 to the `/lib/` directory.

![image](https://github.com/user-attachments/assets/657e4aef-e772-4995-a871-8e4de941af22)
