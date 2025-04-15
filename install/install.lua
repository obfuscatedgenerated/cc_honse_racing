local load_ccif = assert(loadstring(http.get("https://ccif.obfuscatedgenerated.workers.dev/?v=1.0.1").readAll())); ccif = {print=print,printError=printError,pairs=pairs,http=http,fs=fs,os=os,shell=shell}; setfenv(load_ccif, ccif); load_ccif()

ccif.add_file("/lib/obsi2.lua", "https://github.com/simadude/obsi2/releases/download/v2.0.2/obsi-bundled.lua")

local repo = "https://github.com/obfuscatedgenerated/cc_honse_racing/raw/refs/heads/main/"
ccif.add_file("/honse/init.lua", repo .. "init.lua")
ccif.add_file("/honse/bb.lua", repo .. "bb.lua")
ccif.add_file("/honse/field.lua", repo .. "field.lua")
ccif.add_file("/honse/field.orli", repo .. "field.orli")
ccif.add_file("/honse/game_loop.lua", repo .. "game_loop.lua")
ccif.add_file("/honse/game_state.lua", repo .. "game_state.lua")
ccif.add_file("/honse/honse.lua", repo .. "honse.lua")
ccif.add_file("/honse/install.lua", repo .. "install/meta.lua")
ccif.add_file("/honse/honse_template.nfp", repo .. "honse_template.nfp")

local success = ccif.execute()

if success then
  print("")
  print("Reinstall/update with honse/install")
  print("Run with honse/init")
end
