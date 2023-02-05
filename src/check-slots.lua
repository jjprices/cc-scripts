---
--- Created by jjprices, ep9630.
--- DateTime: 2/4/23 7:29 PM
---

for i = 1,15 do
    local blockInfo = turtle.getItemDetail(i)
    local blockName = "<empty>"
    if blockInfo then
        blockName = blockInfo.name
    end
    print(tostring(i)..":"..blockName)
end