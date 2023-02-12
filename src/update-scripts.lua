---
--- Created by jjprices, ep9630.
--- DateTime: 2/4/23 6:58 PM
---

local baseRepoUrl = "https://raw.githubusercontent.com/jjprices/cc-scripts/master/src/"

local function replaceFile(filename)
    shell.run("delete", filename)
    shell.run("wget", baseRepoUrl..filename)
end

replaceFile("automine.lua")
replaceFile("update-scripts.lua")
replaceFile("check-slots.lua")
replaceFile("spruce-tree.lua")