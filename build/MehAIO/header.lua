-- Change autoUpdate to false if you wish to not receive auto updates.
-- Change silentUpdate to true if you wish not to receive any message regarding updates
local autoUpdate   = true
local silentUpdate = false

local version = 0.013

local scriptName = "MehAIO"

--[[

     ▄▄▄       ██▓     ██▓        ██▓ ███▄    █     ▒█████   ███▄    █ ▓█████ 
    ▒████▄    ▓██▒    ▓██▒       ▓██▒ ██ ▀█   █    ▒██▒  ██▒ ██ ▀█   █ ▓█   ▀ 
    ▒██  ▀█▄  ▒██░    ▒██░       ▒██▒▓██  ▀█ ██▒   ▒██░  ██▒▓██  ▀█ ██▒▒███   
    ░██▄▄▄▄██ ▒██░    ▒██░       ░██░▓██▒  ▐▌██▒   ▒██   ██░▓██▒  ▐▌██▒▒▓█  ▄ 
     ▓█   ▓██▒░██████▒░██████▒   ░██░▒██░   ▓██░   ░ ████▓▒░▒██░   ▓██░░▒████▒
     ▒▒   ▓▒█░░ ▒░▓  ░░ ▒░▓  ░   ░▓  ░ ▒░   ▒ ▒    ░ ▒░▒░▒░ ░ ▒░   ▒ ▒ ░░ ▒░ ░
      ▒   ▒▒ ░░ ░ ▒  ░░ ░ ▒  ░    ▒ ░░ ░░   ░ ▒░     ░ ▒ ▒░ ░ ░░   ░ ▒░ ░ ░  ░
      ░   ▒     ░ ░     ░ ░       ▒ ░   ░   ░ ░    ░ ░ ░ ▒     ░   ░ ░    ░   

    All In One - Well, at least some champs in one script :D

    People who helped me:
        Apple  - Multi champ framework setup
        Zikkah - Packet help (Blitzcrank Q)

]]

local champions = {
    ["Blitzcrank"]   = true,
    ["Brand"]        = true,
    ["Orianna"]      = true,
    ["Xerath"]       = true
}

if not champions[player.charName] then autoUpdate = nil silentUpdate = nil version = nil scriptName = nil champions = nil collectgarbage() return end

--[[ Updater and library downloader ]]

local sourceLibFound = true
if FileExist(LIB_PATH .. "SourceLib.lua") then
    require "SourceLib"
else
    sourceLibFound = false
    DownloadFile("https://raw.github.com/TheRealSource/public/master/common/SourceLib.lua", LIB_PATH .. "SourceLib.lua", function() print("<font color=\"#6699ff\"><b>" .. scriptName .. ":</b></font> <font color=\"#FFFFFF\">SourceLib downloaded! Please reload!</font>") end)
end

if not sourceLibFound then return end

if autoUpdate then
    SourceUpdater(scriptName, version, "raw.github.com", "/Hellsing/public/master/" .. scriptName .. ".lua", SCRIPT_PATH .. GetCurrentEnv().FILE_NAME, "/Hellsing/public/master/version/" .. scriptName .. ".version"):SetSilent(silentUpdate):CheckUpdate()
end

local libDownloader = Require(scriptName)
libDownloader:Add("Prodiction",  "https://bitbucket.org/Klokje/public-klokjes-bol-scripts/raw/master/Test/Prodiction/Prodiction.lua")
libDownloader:Add("VPrediction", "https://raw.github.com/Hellsing/BoL/master/common/VPrediction.lua")
libDownloader:Add("SOW",         "https://raw.github.com/Hellsing/BoL/master/common/SOW.lua")
libDownloader:Check()

if libDownloader.downloadNeeded then return end

--[[ Class initializing ]]

for k, _ in pairs(champions) do
    local className = k:gsub("%s+", "")
    class(className)
    champions[k] = _G[className]
end

--[[ Static Variables ]]--


--[[ Script Variables ]]--

local champ = champions[player.charName]
local menu  = nil
local VP    = nil
local OW    = nil
local STS   = nil
local DM    = nil
local DLib  = nil

local spellData = {}

local spells   = {}
local circles  = {}
local AAcircle = nil

local champLoaded = true
local skip        = false

local skinNumber = nil

local __colors = {
    { current = 255, step = 1, min = 0, max = 255, mode = -1 },
    { current = 255, step = 2, min = 0, max = 255, mode = -1 },
    { current = 255, step = 3, min = 0, max = 255, mode = -1 },
}

--[[ General Callbacks ]]--

function OnLoad()

    -- Load dependencies
    VP   = VPrediction()
    OW   = SOW(VP)
    STS  = SimpleTS()
    DM   = DrawManager()
    DLib = DamageLib()

    -- Load champion
    champ = champ()

    -- Prevent errors
    if not champ then print("There was an error while loading " .. player.charName .. ", please report the shown error to Hellsing, thanks!") champLoaded = false return end

    -- Auto attack range circle
    AAcircle = DM:CreateCircle(player, OW:MyRange(), 3)

    -- Load menu
    loadMenu()

    --if true then champLoaded = false return end

    -- Regular callbacks registering
    if champ.OnUnload       then AddUnloadCallback(function()                     champ:OnUnload()                  end) end
    if champ.OnExit         then AddExitCallback(function()                       champ:OnExit()                    end) end
    if champ.OnDraw         then AddDrawCallback(function()                       champ:OnDraw()                    end) end
    if champ.OnReset        then AddResetCallback(function()                      champ:OnReset()                   end) end
    if champ.OnSendChat     then AddChatCallback(function(text)                   champ:OnSendChat(text)            end) end
    if champ.OnRecvChat     then AddRecvChatCallback(function(text)               champ:OnRecvChat(text)            end) end
    if champ.OnWndMsg       then AddMsgCallback(function(msg, wParam)             champ:OnWndMsg(msg, wParam)       end) end
    --if champ.OnCreateObj    then AddCreateObjCallback(function(obj)               champ:OnCreateObj(object)         end) end
    if champ.OnDeleteObj    then AddDeleteObjCallback(function(obj)               champ:OnDeleteObj(object)         end) end
    if champ.OnProcessSpell then AddProcessSpellCallback(function(unit, spell)    champ:OnProcessSpell(unit, spell) end) end
    if champ.OnSendPacket   then AddSendPacketCallback(function(p)                champ:OnSendPacket(p)             end) end
    if champ.OnRecvPacket   then AddRecvPacketCallback(function(p)                champ:OnRecvPacket(p)             end) end
    if champ.OnBugsplat     then AddBugsplatCallback(function()                   champ:OnBugsplat()                end) end
    if champ.OnAnimation    then AddAnimationCallback(function(object, animation) champ:OnAnimation()               end) end
    if champ.OnNotifyEvent  then AddNotifyEventCallback(function(event, unit)     champ:OnNotify(event, unit)       end) end
    if champ.OnParticle     then AddParticleCallback(function(unit, particle)     champ:OnParticle(unit, particle)  end) end

    -- Advanced callbacks registering
    if champ.OnGainBuff     then AdvancedCallback:bind('OnGainBuff',   function(unit, buff) champ:OnGainBuff(unit, buff)   end) end
    if champ.OnUpdateBuff   then AdvancedCallback:bind('OnUpdateBuff', function(unit, buff) champ:OnUpdateBuff(unit, buff) end) end
    if champ.OnLoseBuff     then AdvancedCallback:bind('OnLoseBuff',   function(unit, buff) champ:OnLoseBuff(unit, buff)   end) end

end

function OnTick()

    -- Prevent error spamming
    if not champLoaded then return end

    if champ.OnTick then
        champ:OnTick()
    end

    -- Skip combo once
    if skip then
        skip = false
        return
    end

    if champ.OnCombo and menu.combo and menu.combo.active then
        champ:OnCombo()
    elseif champ.OnHarass and menu.harass and menu.harass.active then
        champ:OnHarass()
    end

end

function OnDraw()

    -- Prevent error spamming
    if not champLoaded then return end

    __mixColors()
    AAcircle.color[2] = __colors[1].current
    AAcircle.color[3] = __colors[2].current
    AAcircle.color[4] = __colors[3].current
    AAcircle.range    = OW:MyRange() 

    -- Skin changer
    if menu.skin then
        for i = 1, skinNumber do
            if menu.skin["skin"..i] then
                menu.skin["skin"..i] = false
                GenModelPacket(player.charName, i - 1)
            end
        end
    end

end

-- Spudgy please...
function OnCreateObj(object) if champ.OnCreateObj then champ:OnCreateObj(object) end end

--[[ Other Functions ]]--

function loadMenu()
    menu = MenuWrapper("[" .. scriptName .. "] " .. player.charName, "unique" .. player.charName:gsub("%s+", ""))

    -- Skin changer
    if champ.GetSkins then
        menu:GetHandle():addSubMenu("Skin Changer", "skin")
        for i, name in ipairs(champ:GetSkins()) do
            menu:GetHandle().skin:addParam("skin"..i, name, SCRIPT_PARAM_ONOFF, false)
        end
        skinNumber = #champ:GetSkins()
    end

    menu:SetTargetSelector(STS)
    menu:SetOrbwalker(OW)

    -- Apply menu as normal script config
    menu = menu:GetHandle()

    -- Prediction
    menu:addSubMenu("Prediction", "prediction")
        menu.prediction:addParam("predictionType", "Prediction Type", SCRIPT_PARAM_LIST, 1, { "VPrediction", "Prodiction" })
        _G.srcLib.spellMenu =  menu.prediction

    -- Combo
    if champ.OnCombo then
    menu:addSubMenu("Combo", "combo")
        menu.combo:addParam("active", "Combo active", SCRIPT_PARAM_ONKEYDOWN, false, 32)
    end

    -- Harass
    if champ.OnHarass then
    menu:addSubMenu("Harass", "harass")
        menu.harass:addParam("active", "Harass active", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
    end

    -- Apply champ menu values
    if champ.ApplyMenu then champ:ApplyMenu() end
end

function initializeSpells()
    -- Create spells and circles
    for id, data in pairs(spellData) do
        -- Range
        local range = type(data.range) == "number" and data.range or data.range[1]
        -- Spell
        local spell = Spell(id, range)
        if data.skillshotType then
            spell:SetSkillshot(VP, data.skillshotType, data.width, data.delay, data.speed, data.collision)
        end
        table.insert(spells, id, spell)
        -- Circle
        local circle = DM:CreateCircle(player, range):LinkWithSpell(spell)
        circle:SetDrawCondition(function() return spell:GetLevel() > 0 end)
        table.insert(circles, id, circle)
    end
end

function getBestTarget(range, condition)
    condition = condition or function() return true end
    local target = STS:GetTarget(range)
    if not target or not condition(target) then
        target = nil
        for _, enemy in ipairs(GetEnemyHeroes()) do
            if ValidTarget(enemy, range) and condition(enemy) then
                if not target or enemy.health < target.health then
                    target = enemy
                end
            end
        end
    end
    return target
end

function skipCombo()
    skip = true
end

function __mixColors()
    for i = 1, #__colors do
        local color = __colors[i]
        color.current = color.current + color.mode * color.step
        if color.current < color.min then
            color.current = color.min
            color.mode = 1
        elseif color.current > color.max then
            color.current = color.max
            color.mode = -1
        end
    end
end

-- Credits to shalzuth for this!
function GenModelPacket(champ, skinId)
    p = CLoLPacket(0x97)
    p:EncodeF(player.networkID)
    p.pos = 1
    t1 = p:Decode1()
    t2 = p:Decode1()
    t3 = p:Decode1()
    t4 = p:Decode1()
    p:Encode1(t1)
    p:Encode1(t2)
    p:Encode1(t3)
    p:Encode1(bit32.band(t4,0xB))
    p:Encode1(1)--hardcode 1 bitfield
    p:Encode4(skinId)
    for i = 1, #champ do
        p:Encode1(string.byte(champ:sub(i,i)))
    end
    for i = #champ + 1, 64 do
        p:Encode1(0)
    end
    p:Hide()
    RecvPacket(p)
end

function GetPredictedPos(unit, delay, speed, source)
    if menu.prediction.predictionType == 1 then
        return VP:GetPredictedPos(unit, delay, speed, source)
    elseif menu.prediction.predictionType == 2 then
        return Prodiction.GetPrediction(unit, math.huge, speed, delay, 1, source)
    end
end

function CountAllyHeroInRange(range, point)
    local n = 0
    for i, ally in ipairs(GetAllyHeroes()) do
        if ValidTarget(ally, math.huge, false) and GetDistanceSqr(point, ally) <= range * range then
            n = n + 1
        end
    end
    return n
end

function GetDistanceToClosestAlly(p)
    local d = GetDistance(p, myHero)
    for i, ally in ipairs(GetAllyHeroes()) do
        if ValidTarget(ally, math.huge, false) then
            local dist = GetDistance(p, ally)
            if dist < d then
                d = dist
            end
        end
    end
    return d
end