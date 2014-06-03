-- Change autoUpdate to false if you wish to not receive auto updates.
-- Change silentUpdate to true if you wish not to receive any message regarding updates
local autoUpdate   = true
local silentUpdate = false

local version = 0.004

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

    All In One - Honda7's scripts reworked and merged into one, badass, script.

    People who helped me:
        Apple  - Multi champ framework setup
        Zikkah - Packet help (Blitzcrank Q)

]]

local champions = {
    ["Blitzcrank"]   = true,
    --["Brand"]        = true,
    --["Cassiopeia"]   = true,
    --["Orianna"]      = true,
    --["Shaco"]        = true,
    --["Syndra"]       = true,
    --["Twisted Fate"] = true,
    --["Veigar"]       = true,
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
    AAcircle = DM:CreateCircle(player, OW:MyRange() + 50, 3)

    -- Load menu
    loadMenu()

    -- Regular callbacks registering
    if champ.OnUnload       then AddUnloadCallback(function()                     champ:OnUnload()                  end) end
    if champ.OnExit         then AddExitCallback(function()                       champ:OnExit()                    end) end
    if champ.OnDraw         then AddDrawCallback(function()                       champ:OnDraw()                    end) end
    if champ.OnReset        then AddResetCallback(function()                      champ:OnReset()                   end) end
    if champ.OnSendChat     then AddChatCallback(function(text)                   champ:OnSendChat(text)            end) end
    if champ.OnRecvChat     then AddRecvChatCallback(function(text)               champ:OnRecvChat(text)            end) end
    if champ.OnWndMsg       then AddMsgCallback(function(msg, wParam)             champ:OnWndMsg(msg, wParam)       end) end
    if champ.OnCreateObj    then AddCreateObjCallback(function(obj)               champ:OnCreateObj(object)         end) end
    if champ.OnDeleteObj    then AddDeleteObjCallback(function(obj)               champ:OnDeleteObj(object)         end) end
    if champ.OnProcessSpel  then AddProcessSpellCallback(function(unit, spell)    champ:OnProcessSpell(unit, spell) end) end
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

end

--[[ Other Functions ]]--

function loadMenu()
    menu = MenuWrapper("[" .. scriptName .. "] " .. player.charName, "unique" .. player.charName:gsub("%s+", ""))

    menu:SetTargetSelector(STS)
    menu:SetOrbwalker(OW)

    -- Apply menu as normal script config
    menu = menu:GetHandle()

    -- Prediction
    menu:addSubMenu("Prediction", "prediction")

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
        local spell = Spell(id, range, nil, menu.prediction)
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

--[[
    ██████╗ ██╗     ██╗████████╗███████╗ ██████╗██████╗  █████╗ ███╗   ██╗██╗  ██╗
    ██╔══██╗██║     ██║╚══██╔══╝╚══███╔╝██╔════╝██╔══██╗██╔══██╗████╗  ██║██║ ██╔╝
    ██████╔╝██║     ██║   ██║     ███╔╝ ██║     ██████╔╝███████║██╔██╗ ██║█████╔╝ 
    ██╔══██╗██║     ██║   ██║    ███╔╝  ██║     ██╔══██╗██╔══██║██║╚██╗██║██╔═██╗ 
    ██████╔╝███████╗██║   ██║   ███████╗╚██████╗██║  ██║██║  ██║██║ ╚████║██║  ██╗
    ╚═════╝ ╚══════╝╚═╝   ╚═╝   ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝
]]

function Blitzcrank:__init()

    spellData = {
        [_Q] = { range = 1000, skillshotType = SKILLSHOT_LINEAR, width = 70, delay = 0.25, speed = 1800, collision = true },
        [_W] = { range = -1 },
        [_E] = { range = -1 },
        [_R] = { range = 600 },
    }
    initializeSpells()

    self.stats = { numCasted = 0, numLanded = 0, numLandedChamps = 0, numLandedMinions = 0, landedOnChamps = {} }
    self.projectileId = 0
    self.projectileTime = 0

    self.combo = { _AA, _Q, _R }

    --Register damage sources
    DLib:RegisterDamageSource(_Q, _MAGIC, 80,  55,  _MAGIC, _AP, 1, function() return spells[_Q]:IsReady() end)
    DLib:RegisterDamageSource(_R, _MAGIC, 250, 125, _MAGIC, _AP, 1, function() return spells[_R]:IsReady() end)

end

function Blitzcrank:CheckHeroCollision(pos)

    for i, enemy in ipairs(GetEnemyHeroes()) do
        if ValidTarget(enemy) and _GetDistanceSqr(enemy) < math.pow(spells[_Q].range * 1.5, 2) and menu.targets[enemy.charName] == 1 then
            local proj1, pointLine, isOnSegment = VectorPointProjectionOnLineSegment(Vector(player), pos, Vector(enemy))
            if (_GetDistanceSqr(enemy, proj1) <= math.pow(VP:GetHitBox(enemy) * 2 + spells[_Q].width, 2)) then
                return true
            end
        end
    end
    return false

end

function Blitzcrank:GetLeastHealthAround()

    local leastHealthAround = player.health / player.maxHealth * 100
    for i, ally in ipairs(GetAllyHeroes()) do
        local mp = ally.health / ally.maxHealth * 100
        if mp <= leastHealthAround and not ally.dead and _GetDistanceSqr(ally) < 700 * 700 then
            leastHealthAround = mp
        end
    end
    return leastHealthAround

end

function Blitzcrank:OnCombo()

    local target = getBestTarget(spells[_Q].range, function(enemy) return menu.targets[enemy.charName] > 1 end)
    if target then
        spells[_Q]:Cast(target)
    end

end

function Blitzcrank:OnTick()

    -- Killsteal
    if menu.killsteal and spells[_R]:IsReady() then
        local target = getBestTarget(spells[_R].range, function(enemy) return enemy.health <= DLib:CalcSpellDamage(enemy, _R) end)
        if target then
            spells[_R]:Cast()
            return
        end
    end

    -- Don't grab on low health
    if Blitzcrank:GetLeastHealthAround() < menu.autoGrab.lowHealth then return end

    -- AutoGrab
    for _, enemy in ipairs(GetEnemyHeroes()) do
        if ValidTarget(enemy, 1500) and menu.targets[enemy.charName] == 3 then
            local castPosition, hitChance = spells[_Q]:GetPrediction(enemy)
            
            if hitChance == 5 and menu.autoGrab.dashing and _GetDistanceSqr(castPosition) < spells[_Q].rangeSqr then
                if not self:CheckHeroCollision(castPosition) then
                    spells[_Q]:Cast(castPosition.x, castPosition.z)
                    return
                end
            elseif hitChance == 4 and menu.autoGrab.immobile and _GetDistanceSqr(castPosition) < spells[_Q].rangeSqr then
                if _GetDistanceSqr(castPosition) > 300 * 300 and not self:CheckHeroCollision(castPosition) then
                    spells[_Q]:Cast(castPosition.x, castPosition.z)
                    return
                end
            end
        end
    end

end

function Blitzcrank:OnTargetInterruptable(unit, spell)
    -- Don't grab on low health
    if Blitzcrank:GetLeastHealthAround() < menu.autoGrab.lowHealth then return end

    if spells[_R]:IsReady() and spells[_R]:IsInRange(unit) then
        spells[_R]:Cast(unit)
    end
end

function Blitzcrank:OnTargetGapclosing(unit, spell)
    -- Don't grab on low health
    if Blitzcrank:GetLeastHealthAround() < menu.autoGrab.lowHealth then return end

    if spells[_Q]:IsReady() then
        spells[_Q]:Cast(unit)
    end
end

function Blitzcrank:OnRecvPacket(p)

    -- Casted Q
    if p.header == 0xB4 then
        p.pos = 1
        local nwid = p:DecodeF()
        if nwid == player.networkID then
            p.pos = 65
            local n = p:Decode1()
            local spellid = -1
            if n == 1 then
                p.pos = 104
                spellid=p:Decode1()
            else
                p.pos = 87
                spellid=p:Decode1()
            end
            if spellid == 44 then
                self.stats.numCasted = self.stats.numCasted + 1
                p.pos = 37
                self.projectileId = p:DecodeF()
                self.projectileTime = os.clock()
            end
        end
    -- Landed Q
    elseif p.header == 0x25 then
        p.pos = 1
        local pr = p:DecodeF()
        if pr == self.projectileId and (os.clock() - self.projectileTime) < 2 then
            p.pos = p.pos + 2
            local h = objManager:GetObjectByNetworkId(p:DecodeF())
            if h and h.valid then
                self.stats.numLanded = self.stats.numLanded + 1
                if h.type == player.type then
                    if menu.autoE and spells[_E]:IsReady() then
                        spells[_E]:Cast()
                    end
                    self.stats.numLandedChamps = self.stats.numLandedChamps + 1
                    self.stats.landedOnChamps[h.charName] = (self.stats.landedOnChamps[h.charName] and self.stats.landedOnChamps[h.charName] or 0 ) + 1
                else
                    self.stats.numLandedMinions = self.stats.numLandedMinions + 1
                end
            end
        end
    end

end

function Blitzcrank:OnDraw()

    if menu.drawing.stats and self.stats.numCasted > 0 then
        DrawText("Stats", 17, 10, 10, ARGB(255,225,255,255))
        local Ratio = self.stats.numLandedChamps / self.stats.numCasted

        DrawText("Landed Q's (Total): "     .. self.stats.numLanded        .. "/" .. self.stats.numCasted .. " " .. math.floor(self.stats.numLanded / self.stats.numCasted * 100)        .. "%", 13, 10, 30, ARGB(255,255,255,255))
        DrawText("Landed Q's (Champions): " .. self.stats.numLandedChamps  .. "/" .. self.stats.numCasted .. " " .. math.floor(self.stats.numLandedChamps / self.stats.numCasted * 100)  .. "%", 13, 10, 45, ARGB(255,255,255,255))
        DrawText("Landed Q's (Minions): "   .. self.stats.numLandedMinions .. "/" .. self.stats.numCasted .. " " .. math.floor(self.stats.numLandedMinions / self.stats.numCasted * 100) .. "%", 13, 10, 60, ARGB(255,255,255,255))

        local i = 1
        for name, times in pairs(self.stats.landedOnChamps) do
            DrawText("Landed Q's (" .. name .. "): " .. times, 13, 10, 60 + i * 15, ARGB(255,255,255,255))
            i = i + 1
        end
    end

end

function Blitzcrank:ApplyMenu()

    menu:addSubMenu("Auto-Interrupt", "interrupt")
        Interrupter(menu.interrupt, self.OnTargetInterruptable)

    menu:addSubMenu("Auto-Grab", "autoGrab")
        menu.autoGrab:addSubMenu("Anti-Gapclosers", "antiGapcloser")
            AntiGapcloser(menu.autoGrab.antiGapcloser, self.OnTargetGapclosing)
        menu.autoGrab:addParam("dashing",   "Auto-Grab dashing enemies",        SCRIPT_PARAM_ONOFF, true)
        menu.autoGrab:addParam("immobile",  "Auto-Grab immobile enemies",       SCRIPT_PARAM_ONOFF, true)
        menu.autoGrab:addParam("sep",       "",                                 SCRIPT_PARAM_INFO, "")
        menu.autoGrab:addParam("lowHealth", "Don't auto grab if my health < %", SCRIPT_PARAM_SLICE, 0, 0, 100)

    menu:addSubMenu("Targets", "targets")
        for i, enemy in ipairs(GetEnemyHeroes()) do
            menu.targets:addParam(enemy.charName, enemy.charName, SCRIPT_PARAM_LIST, 3, {"Don't grab", "Normal grab", "Normal + Auto-grab"})
        end

    menu:addSubMenu("Drawing", "drawing")
        AAcircle:SetEnabled(false)
        circles[_Q]:AddToMenu(menu.drawing, "Q Range", true, true, true)
        circles[_R]:AddToMenu(menu.drawing, "R Range", true, true, true)
        menu.drawing:addParam("sep",   "",                       SCRIPT_PARAM_INFO, "")
        menu.drawing:addParam("stats", "Draw stats on the side", SCRIPT_PARAM_ONOFF, true)
        DLib:AddToMenu(menu.drawing, self.combo)

    menu:addParam("sep",       "",                  SCRIPT_PARAM_INFO, "")
    menu:addParam("autoE",     "Auto-E after grab", SCRIPT_PARAM_ONOFF, true)
    menu:addParam("killsteal", "Killsteal with R",  SCRIPT_PARAM_ONOFF, false)

end


--[[
    ██╗  ██╗███████╗██████╗  █████╗ ████████╗██╗  ██╗
    ╚██╗██╔╝██╔════╝██╔══██╗██╔══██╗╚══██╔══╝██║  ██║
     ╚███╔╝ █████╗  ██████╔╝███████║   ██║   ███████║
     ██╔██╗ ██╔══╝  ██╔══██╗██╔══██║   ██║   ██╔══██║
    ██╔╝ ██╗███████╗██║  ██║██║  ██║   ██║   ██║  ██║
    ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝
]]

function Xerath:__init()

    spellData = {
        [_Q] = { range = 750, rangeMax = 1550, skillshotType = SKILLSHOT_LINEAR,   width = 100, delay = 0.7,  speed = math.huge, collision = false },
        [_W] = { range = 1100,                 skillshotType = SKILLSHOT_CIRCULAR, width = 200, delay = 0.7,  speed = math.huge, collision = false },
        [_E] = { range = 1050,                 skillshotType = SKILLSHOT_LINEAR,   width = 60,  delay = 0.25, speed = 1400,      collision = true  },
        [_R] = { range = {3200, 4400, 5600},   skillshotType = SKILLSHOT_CIRCULAR, width = 200, delay = 0.9,  speed = math.huge, collision = false },
    }
    initializeSpells()

    -- Finetune spells
    spells[_Q]:SetCharged("xeratharcanopulsechargeup", 3, spellData[_Q].rangeMax, 1.5, function() return spells[_Q]:GetCooldown(true) > 0 end)
    spells[_Q]:SetAOE(true)
    spells[_W]:SetAOE(true)
    spells[_R]:TrackCasting({"XerathLocusOfPower2", "xerathlocuspulse"})
    spells[_R]:RegisterCastCallback(function(spell) self:OnCastUlt(spell) end)

    -- Circle customization
    circles[_Q].color = { 255, 0x0F, 0x37, 0xFF }
    circles[_Q].width = 2
    circles[_W].color = { 255, 0x65, 0x05, 0xFF }
    circles[_W].width = 2
    circles[_E]:SetEnabled(false)
    circles[_R]:SetEnabled(false)

    -- Minions
    self.enemyMinions  = minionManager(MINION_ENEMY,  spellData[_Q].rangeMax, player, MINION_SORT_MAXHEALTH_DEC)
    self.jungleMinions = minionManager(MINION_JUNGLE, spellData[_Q].rangeMax, player, MINION_SORT_MAXHEALTH_DEC)

    self.ultData = {
        mode           = 0,
        castTime       = 0,
        lastChargeTime = 0,
        chargesUsed    = 0,
        waitTime       = 0,
        currentTarget  = nil,
        allPressTime   = 0,
        tapPressTime   = 0,
    }

    self.lastPing = 0

    self.passiveUp = HasBuff(player, "xerathascended2onhit")

    self.ultCombo = { _R, _R, _R }
    self.mainCombo = { _IGNITE, _Q, _W, _E, _R, _R, _R }

    --Register damage sources
    DLib:RegisterDamageSource(_Q, _MAGIC, 40,  40, _MAGIC, _AP, 0.75, function() return spells[_Q]:IsReady() end)
    DLib:RegisterDamageSource(_W, _MAGIC, 30,  30, _MAGIC, _AP, 0.6,  function() return spells[_W]:IsReady() end)
    DLib:RegisterDamageSource(_E, _MAGIC, 50,  30, _MAGIC, _AP, 0.45, function() return spells[_E]:IsReady() end)
    DLib:RegisterDamageSource(_R, _MAGIC, 135, 55, _MAGIC, _AP, 0.43, function() return spells[_R]:IsReady() end)

    TickLimiter(function()
        -- Update R range
        spells[_R]:SetRange(spellData[_R].range[math.max(spells[_R]:GetLevel(), 1)])
        -- Reset ult values
        if not self:IsCastingUlt() then
            self.ultData.mode           = 0
            self.ultData.castTime       = 0
            self.ultData.lastChargeTime = 0
            self.ultData.chargesUsed    = 0
            self.ultData.waitTime       = 0
            self.ultData.currentTarget  = nil
        end
    end, 1)

end

function Xerath:OnCombo()

    local targets = {
        [_Q] = STS:GetTarget(spellData[_Q].rangeMax),
        [_W] = STS:GetTarget(spells[_W].range + spells[_W].width),
        [_E] = STS:GetTarget(menu.combo.rangeE)
    }

    local AAtarget = OW:GetTarget()
    OW:DisableAttacks()

    -- AA only when passive up or enemy health below 200
    if (AAtarget and AAtarget.health < menu.aa) or self.passiveUp then
        OW:EnableAttacks()
    end

    if spells[_Q]:IsReady() and targets[_Q] and menu.combo.useQ then
        if spells[_Q]:IsCharging() then
            local castPosition, hitChance, nTargets = spells[_Q]:GetPrediction(targets[_Q])
            if spells[_Q].range ~= spellData[_Q].rangeMax and _GetDistanceSqr(castPosition) < math.pow(spells[_Q].range - 200, 2) or spells[_Q].range == spellData[_Q].rangeMax and _GetDistanceSqr(castPosition) < math.pow(spells[_Q].range, 2) then
                spells[_Q]:Cast(castPosition.x, castPosition.z)
            end
        else
            spells[_Q]:Charge()
        end
    end

    if spells[_W]:IsReady() and targets[_W] and menu.combo.useW then
        if menu.misc.centerW then
            spells[_W].width = 50
        else
            spells[_W].width = spellData[_W].width
        end
        local property = VP.ShotAtMaxRange
        VP.ShotAtMaxRange = menu.misc.maxRangeW
        spells[_W]:Cast(targets[_W])
        VP.ShotAtMaxRange = property
    end

    if spells[_E]:IsReady() and targets[_E] and menu.combo.useE then
        spells[_E]:Cast(targets[_E])
    end

end

function Xerath:OnHarass()

    -- Don't harass when Q not ready
    if not spells[_Q]:IsReady() or not menu.harass.useQ then return end

    -- Don't harass on not enough mana
    if (player.mana / player.maxMana * 100) < menu.harass.mana then return end

    local target = STS:GetTarget(spellData[_Q].rangeMax)

    if target then
        if spells[_Q]:IsCharging() then
            local castPosition, hitChance, nTargets = spells[_Q]:GetPrediction(target)
            if spells[_Q].range ~= spellData[_Q].rangeMax and _GetDistanceSqr(castPosition) < math.pow(spells[_Q].range - 200, 2) or spells[_Q].range == spellData[_Q].rangeMax and _GetDistanceSqr(castPosition) < math.pow(spells[_Q].range, 2) then
                spells[_Q]:Cast(castPosition.x, castPosition.z)
            end
        else
            spells[_Q]:Charge()
        end
    end

end

function Xerath:OnFarm()

    local minionsUpdated = false

    if menu.farm.useQ and spells[_Q]:IsReady() then

        -- Save performance, update minions within here
        self.enemyMinions:update()
        minionsUpdated = true

        if not spells[_Q]:IsCharging() then
            if #self.enemyMinions.objects > 1 then
                spells[_Q]:Charge()
            end
        else
            local maxRange = spells[_Q].range == spellData[_Q].rangeMax
            local continue = maxRange
            local minions  = SelectUnits(self.enemyMinions.objects, function(t) return ValidTarget(t) and _GetDistanceSqr(t) < spells[_Q].rangeSqr end)
            if not maxRange then
                local maxRangeMinions = SelectUnits(self.enemyMinions.objects, function(t) return ValidTarget(t) and _GetDistanceSqr(t) < math.pow(spellData[_Q].rangeMax, 2) end)
                continue = #maxRangeMinions == #minions
            end
            if continue then
                minions = GetPredictedPositionsTable(VP, minions, spells[_Q].delay, spells[_Q].width, spells[_Q].range, math.huge, player, false)
                local castPosition = GetBestLineFarmPosition(spells[_Q].range, spells[_Q].width, minions)
                if castPosition then
                    spells[_Q]:Cast(castPosition.x, castPosition.z)
                end
            end
        end
    end

    if menu.farm.useW and spells[_W]:IsReady() then

        -- Update minions
        if not minionsUpdated then self.enemyMinions:update() end

        local casted = false
        local casterMinions = SelectUnits(self.enemyMinions.objects, function(t) return (t.charName:lower():find("wizard") or t.charName:lower():find("caster")) and ValidTarget(t) and _GetDistanceSqr(t) < spells[_W].rangeSqr end)
        
        -- Caster minions
        if #casterMinions > 1 then
            casterMinions = GetPredictedPositionsTable(VP, casterMinions, spells[_W].delay, spells[_W].width, spells[_W].range + spells[_W].width, math.huge, player, false)
            local castPosition, hitNumber = GetBestCircularFarmPosition(spells[_W].range + spells[_W].width, spells[_W].width, casterMinions)
            if castPosition and hitNumber > 1 then
                spells[_W]:Cast(castPosition.x, castPosition.z)
                casted = true
            end
        end

        -- ALl minions
        if not casted then
            local minions = SelectUnits(self.enemyMinions.objects, function(t) return ValidTarget(t) and _GetDistanceSqr(t) < spells[_E].rangeSqr end)
            -- Don't waste W on 1 minion
            if #minions > 1 then
                minions = GetPredictedPositionsTable(VP, minions, spells[_W].delay, spells[_W].width, spells[_W].range + spells[_W].width, math.huge, player, false)
                castPosition, hitNumber = GetBestCircularFarmPosition(spells[_W].range + spells[_W].width, spells[_W].width, minions)
                if castPosition and hitNumber > 1 then
                    spells[_W]:Cast(castPosition.x, castPosition.z)
                end
            end
        end
    end

end

function Xerath:OnJungleFarm()

    self.jungleMinions:update()

    if #self.jungleMinions.objects > 0 then
        if menu.jfarm.useQ and spells[_Q]:IsReady() then
            if not spells[_Q]:IsCharging() then
                spells[_Q]:Charge()
            end
            if _GetDistanceSqr(self.jungleMinions.objects[1]) <= spells[_Q].rangeSqr then
                spells[_Q]:Cast(self.jungleMinions.objects[1].x, self.jungleMinions.objects[1].z)
            end
        end

        if menu.jfarm.useW and spells[_W]:IsReady() then
            spells[_W]:Cast(self.jungleMinions.objects[1].x, self.jungleMinions.objects[1].z)
        end
    end

end

function Xerath:OnTargetGapclosing(unit, spell)
    if spells[_E]:IsReady() then
        spells[_E]:Cast(unit)
    end
end

function Xerath:OnTick()

    -- Ping alert snipeable
    if menu.snipe.alerter.ping and spells[_R]:IsReady() and (os.clock() - self.lastPing > 30) then
        for _, enemy in ipairs(GetEnemyHeroes()) do
            if ValidTarget(enemy, spells[_R].range) and DLib:IsKillable(enemy, self.ultCombo) then
                for i = 1, 3 do
                    DelayAction(PingClient,  1000 * 0.3 * i/1000, { enemy.x, enemy.z })
                end
                self.lastPing = os.clock()
                break
            end
        end
    end

    OW:EnableAttacks()

    -- Handle ult casting
    if self:IsCastingUlt() then
        OW:DisableAttacks()
        skipCombo()
        self:HandleUlt()
        return
    end

    -- Single cast E
    if menu.combo.castE and spells[_E]:IsReady() then
        local target = STS:GetTarget(spells[_E].range)
        if target then
            spells[_E]:Cast(target)
        end
    end

    if not menu.combo.active then
        -- Farming
        if menu.farm.active and ((player.mana / player.maxMana * 100) >= menu.farm.mana or spells[_Q]:IsCharging()) then
            self:OnFarm()
        end
        -- Jungle farming
        if menu.jfarm.active then
            self:OnJungleFarm()
        end
    end

    if menu.misc.autoEDashing then
        for _, target in ipairs(SelectUnits(GetEnemyHeroes(), function(t) return ValidTarget(t, spells[_E].range * 1.5) end)) do
            spells[_E]:CastIfDashing(target)
        end
    end

    if menu.misc.autoEImmobile then
        for _, target in ipairs(SelectUnits(GetEnemyHeroes(), function(t) return ValidTarget(t, spells[_E].range * 1.5) end)) do
            spells[_E]:CastIfDashing(target)
        end
    end

end

function Xerath:GetBestUltTarget()

    local target = nil
    -- Near mouse (1000)
    if menu.snipe.targetMode == 1 then
        target = STS:GetTarget(1000, 1, STS_NEARMOUSE)
        if target and _GetDistanceSqr(target) > spells[_R].rangeSqr then target = nil end
        if target == nil then
            -- Forced best target
            target = getBestTarget(spells[_R].range)
        end
    -- Most killable
    else
        target = getBestTarget(spells[_R].range)
    end
    return target

end

function Xerath:HandleUlt()

    -- Decide mode
    if self.ultData.mode == 0 then
        if os.clock() - self.ultData.allPressTime < 0.5 then
            -- Use all charges
            self.ultData.mode = 1
        elseif os.clock() - self.ultData.tapPressTime < 0.5 then
            -- Use one charge
            self.ultData.mode = 2
        end
        -- Still no mode (maybe tap?), returning
        if self.ultData.mode == 0 then return end
    end

    -- Check if target is about to die
    if self.ultData.mode == 1 then
        if self.ultData.waitTime ~= 0 then
            if os.clock() - self.ultData.waitTime > 0 then
                self.ultData.waitTime = 0
            else
                return -- Wait, target might die
            end
        end
    -- Check if tap key was pressed on tap mode
    elseif self.ultData.mode == 2 then
        if os.clock() - self.ultData.tapPressTime < 0.5 then
            self.ultData.tapPressTime = 0
        else
            return
        end
    end

    -- Get best target available
    if self.ultData.currentTarget == nil then self.ultData.currentTarget = self:GetBestUltTarget() end

    -- No target found
    if self.ultData.currentTarget == nil then return end

    -- Target changing
    if not ValidTarget(self.ultData.currentTarget) then
        -- Switch target
        local newTarget = self:GetBestUltTarget()
        if newTarget and (not menu.snipe.advanced.delay or (os.clock() - self.ultData.lastChargeTime) > GetDistance(newTarget, self.ultData.currentTarget) / 5000) then
            self.ultData.currentTarget = newTarget
            -- Still no target, wait longer...
            if self.ultData.currentTarget == nil then return end
        -- Wait, target might appear
        else
            -- TODO: FoW shooting to last known location
            return
        end
    end

    -- Cast the charge
    spells[_R].packetCast = menu.snipe.advanced.packets
    spells[_R]:Cast(self.ultData.currentTarget)

end

function Xerath:OnCastUlt(spell)

    -- Initializing
    if spell.name == "XerathLocusOfPower2" then
        self.ultData.castTime    = os.clock()
        self.ultData.chargesUsed = 0
    end
    -- Using charge
    if spell.name == "xerathlocuspulse" then
        self.ultData.chargesUsed    = self.ultData.chargesUsed + 1
        self.ultData.lastChargeTime = os.clock()

        -- Predicted death on mode 1
        if self.ultData.waitTime == 0 and self.ultData.mode == 1 and self.ultData.currentTarget then
            if DLib:IsKillable(self.ultData.currentTarget, { _R }) then
                self.ultData.waitTime = os.clock() + spells[_R].delay
            end
        end

        -- Ult finished
        if self.ultData.chargesUsed == 3 then
            self.ultData.castTime    = 0
            self.ultData.chargesUsed = 0
        end
    end

end

function Xerath:IsCastingUlt()
    return ((os.clock() - self.ultData.castTime) < 10 and (spells[_R]:GetCooldown(true) < 10))
end

function Xerath:OnSendPacket(p)
    
    if p.header == Packet.headers.S_MOVE then
        -- Block auto-attack while charging
        if spells[_Q]:IsCharging() then
            local packet = Packet(p)
            if packet:get("type") ~= 2 then
                Packet('S_MOVE', { x = mousePos.x, y = mousePos.z }):send()
                p:Block()
            end
        -- Block moving while casting R
        elseif self:IsCastingUlt() then
            p:Block()
        end
    end

end

function Xerath:OnWndMsg(msg, key)
    if msg == 256 then
        if key == menu.snipe._param[self.tapMenu].key then
            self.ultData.tapPressTime = os.clock()
        elseif key == menu.snipe._param[self.allMenu].key then
            self.ultData.allPressTime = os.clock()
        end
    end
end

function Xerath:OnGainBuff(unit, buff) 
    if unit and unit.isMe and buff and buff.name == "xerathascended2onhit" then
        self.passiveUp = true
    end
end

function Xerath:OnLoseBuff(unit, buff)
    if unit and unit.isMe and buff and buff.name then
        if buff.name == "xerathascended2onhit" then
            self.passiveUp = false
        end
        if buff.name == "xerathrshots" then
            self.ultData.castTime = 0
        end
    end
end

function Xerath:OnDraw()

    -- Snipe text
    if menu.snipe.alerter.print and spells[_R]:GetLevel() > 0 then
        for i, enemy in ipairs(GetEnemyHeroes()) do
            if ValidTarget(enemy, spells[_R].range) and DLib:IsKillable(enemy, self.ultCombo) then
                local pos = WorldToScreen(D3DXVECTOR3(enemy.x, enemy.y, enemy.z))
                DrawText("Snipe!", 17, pos.x, pos.y, ARGB(255,0,255,0))
            end
        end
    end

end

function Xerath:ApplyMenu()

    -- Combo
    menu.combo:addParam("sep",    "",        SCRIPT_PARAM_INFO, "")
    menu.combo:addParam("useQ",   "Use Q",   SCRIPT_PARAM_ONOFF , true)
    menu.combo:addParam("useW",   "Use W",   SCRIPT_PARAM_ONOFF, true)
    menu.combo:addParam("useE",   "Use E",   SCRIPT_PARAM_ONOFF, true)
    menu.combo:addParam("sep",    "",        SCRIPT_PARAM_INFO, "")
    menu.combo:addParam("rangeE", "E range", SCRIPT_PARAM_SLICE, spells[_E].range, 50, spells[_E].range, 1)
    menu.combo:addParam("castE",  "Use E!",  SCRIPT_PARAM_ONKEYDOWN, false, string.byte("O"))
    
    -- Harass
    menu.harass:addParam("sep",  "",                         SCRIPT_PARAM_INFO, "")
    menu.harass:addParam("useQ", "Use Q",                    SCRIPT_PARAM_ONOFF , true)
    menu.harass:addParam("mana", "Don't harass if mana < %", SCRIPT_PARAM_SLICE, 10, 0, 100)
    
    -- R-Snipe
    menu:addSubMenu("R-Snipe", "snipe")
        menu.snipe:addSubMenu("Alerter", "alerter")
            menu.snipe.alerter:addParam("print", "Draw \"Snipe\" on killable enemies", SCRIPT_PARAM_ONOFF , true)
            menu.snipe.alerter:addParam("ping",  "Ping if an enemy is killable",       SCRIPT_PARAM_ONOFF , true)
        menu.snipe:addSubMenu("Advanced", "advanced")
            menu.snipe.advanced:addParam("delay",   "Wait before changing target",     SCRIPT_PARAM_ONOFF, true)
            menu.snipe.advanced:addParam("packets", "Use packet casting",              SCRIPT_PARAM_ONOFF, false)
        menu.snipe:addParam("sep",        "",                   SCRIPT_PARAM_INFO, "")
        menu.snipe:addParam("auto",       "Use all charges",    SCRIPT_PARAM_ONKEYDOWN, false, string.byte("R"))
        self.allMenu = #menu.snipe._param
        menu.snipe:addParam("tap",        "Use 1 charge (tap)", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("T"))
        self.tapMenu = #menu.snipe._param
        menu.snipe:addParam("jsteal",     "Jungle Steal",       SCRIPT_PARAM_ONKEYDOWN, false, string.byte("J"))
        menu.snipe:addParam("sep",        "",                   SCRIPT_PARAM_INFO, "")
        menu.snipe:addParam("targetMode", "Targetting mode: ",  SCRIPT_PARAM_LIST, 2, { "Near mouse (1000)", "Most killable" })

    -- Farming
    menu:addSubMenu("Farming", "farm")
        menu.farm:addParam("active", "Farming active",         SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
        menu.farm:addParam("sep",    "",                       SCRIPT_PARAM_INFO, "")
        menu.farm:addParam("useQ",   "Use Q",                  SCRIPT_PARAM_ONOFF, true)
        menu.farm:addParam("useW",   "Use W",                  SCRIPT_PARAM_ONOFF, false)
        menu.farm:addParam("sep",    "",                       SCRIPT_PARAM_INFO, "")
        menu.farm:addParam("mana",   "Don't farm if mana < %", SCRIPT_PARAM_SLICE, 10, 0, 100)
    
    -- Jungle farming
    menu:addSubMenu("Jungle-Farming", "jfarm")
        menu.jfarm:addParam("active", "Jungle-Farming active", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
        menu.jfarm:addParam("sep",    "",                      SCRIPT_PARAM_INFO, "")
        menu.jfarm:addParam("useQ",   "Use Q",                 SCRIPT_PARAM_ONOFF, true)
        menu.jfarm:addParam("useW",   "Use W",                 SCRIPT_PARAM_ONOFF, true)

    -- Misc
    menu:addSubMenu("Misc", "misc")
        menu.misc:addSubMenu("Anti-Gapclosers", "AG")
            AntiGapcloser(menu.misc.AG, self.OnTargetGapclosing)
        menu.misc:addParam("centerW",       "Cast W centered",            SCRIPT_PARAM_ONOFF, false)
        menu.misc:addParam("maxRangeW",     "Cast W at max range",        SCRIPT_PARAM_ONOFF, false)
        menu.misc:addParam("autoEDashing",  "Auto E on dashing enemies",  SCRIPT_PARAM_ONOFF, true)
        menu.misc:addParam("autoEImmobile", "Auto E on immobile enemies", SCRIPT_PARAM_ONOFF, true)

    -- Drawing
    menu:addSubMenu("Drawing", "drawing")
        AAcircle:AddToMenu(menu.drawing, "AA Range", false, true, true)
        for spell, circle in pairs(circles) do
            circle:AddToMenu(menu.drawing, SpellToString(spell).." Range", true, true, true)
        end
        DM:CreateCircle(player, 1337):LinkWithSpell(spells[_R]):SetMinimap():AddToMenu(menu.drawing, "R Range (minimap)", true, true, true)
        DLib:AddToMenu(menu.drawing, self.mainCombo)

    -- General
    menu:addParam("sep", "",                          SCRIPT_PARAM_INFO, "")
    menu:addParam("aa",  "Don't AA when enemy above", SCRIPT_PARAM_SLICE, 200, 100, 1000, 1)

end
