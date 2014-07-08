--[[
     ██████╗ ██████╗ ██╗ █████╗ ███╗   ██╗███╗   ██╗ █████╗ 
    ██╔═══██╗██╔══██╗██║██╔══██╗████╗  ██║████╗  ██║██╔══██╗
    ██║   ██║██████╔╝██║███████║██╔██╗ ██║██╔██╗ ██║███████║
    ██║   ██║██╔══██╗██║██╔══██║██║╚██╗██║██║╚██╗██║██╔══██║
    ╚██████╔╝██║  ██║██║██║  ██║██║ ╚████║██║ ╚████║██║  ██║
     ╚═════╝ ╚═╝  ╚═╝╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝  ╚═══╝╚═╝  ╚═╝
]]

function Orianna:__init()

    spellData = {
        [_Q] = { range = 825, skillshotType = SKILLSHOT_LINEAR, width = 80,  delay = 0,    speed = 1200, radius = 145, collision = false },
        [_W] = { range = -1,                                    width = 245, delay = 0.25 },
        [_E] = { range = 1095,                                  width = 80,  delay = 0.25, speed = 1700 },
        [_R] = { range = -1,                                    width = 380, delay = 0.6  },
    }
    initializeSpells()

    -- Finetune spells
    spells[_Q]:SetAOE(true, spellData[_Q].radius)
    spells[_W].packetCast = true
    spells[_R].packetCast = true

    -- TODO: circle colors

    -- Minions
    self.enemyMinions  = minionManager(MINION_ENEMY,  spells[_Q].range, player, MINION_SORT_MAXHEALTH_DEC)
    self.jungleMinions = minionManager(MINION_JUNGLE, spells[_Q].range, player, MINION_SORT_MAXHEALTH_DEC)

    self.mainCombo = { _AA, _AA, _Q, _W, _R, _Q, _IGNITE }

    -- Register damage sources
    DLib:RegisterDamageSource(_Q, _MAGIC, 60,  30, _MAGIC, _AP, 0.5, function() return spells[_Q]:IsReady() end)
    DLib:RegisterDamageSource(_W, _MAGIC, 70,  45, _MAGIC, _AP, 0.7, function() return spells[_W]:IsReady() end)
    DLib:RegisterDamageSource(_E, _MAGIC, 60,  30, _MAGIC, _AP, 0.3, function() return spells[_E]:IsReady() end)
    DLib:RegisterDamageSource(_R, _MAGIC, 150, 75, _MAGIC, _AP, 0.7, function() return spells[_R]:IsReady() end)
    DLib:RegisterDamageSource(_PASIVE, _MAGIC, 0, 0, _MAGIC, _AP, 0.15, nil, function(target) return 10 + (player.level > 3 and (math.floor((player.level - 1) / 3) * 8) or 0) end)

    self.ballPos = player.visionPos
    self.ballMoving = false
    self.ballSpeed = {
        [_Q] = 1200,
        [_E] = 1700
    }

    self.ballCircles = {
        DM:CreateCircle(ballPos, 50, 2):SetDrawCondition(function() return not self.ballMoving end),                  -- TODO: color
        DM:CreateCircle(ballPos, spellData[_W].width, 2):SetDrawCondition(function() return not self.ballMoving end), -- TODO: color
        DM:CreateCircle(ballPos, spellData[_R].width, 2):SetDrawCondition(function() return not self.ballMoving end)  -- TODO: color
    }

    -- Auto update ball circles
    TickLimiter(function()
        for i = 1, #self.ballCircles do
            self.ballCircles[i].position = self.ballPos
        end
    end, 10)

    -- Used for initiator shielding
    self.lastSpellUsed = {}

    self.initiatorList = {
        ["Vi"] =         { { spellName = "ViQ",                  displayName = "Vi - Vault Breaker (Q)",           channelTime = 0.5 },
                           { spellName = "ViR",                  displayName = "Vi - Assault and Battery (R)",     channelTime = 1 } },
        ["Malphite"] =   { { spellName = "Landslide",            displayName = "Malphite - Unstoppable Force (R)", channelTime = 0 } },
        ["Nocturne"] =   { { spellName = "NocturneParanoia",     displayName = "Nocturne - Paranoia (R)",          channelTime = 0 } },
        ["Zac"] =        { { spellName = "ZacE",                 displayName = "Zac - Elastic Slingshot (E)",      channelTime = 0.5 } },
        ["MonkeyKing"] = { { spellName = "MonkeyKingNimbus",     displayName = "Wukong - Nimbus Strike (E)",       channelTime = 0 },
                           { spellName = "MonkeyKingSpinToWin",  displayName = "Wukong - Cyclone (R)",             channelTime = 0 },
                           { spellName = "SummonerFlash",        displayName = "Wukong - Flash",                   channelTime = 0 } },
        ["Shyvana"] =    { { spellName = "ShyvanaTransformCast", displayName = "Shyvana - Dragon\'s Descent (R)",  channelTime = 0 } },
        ["Thresh"] =     { { spellName = "threshqleap",          displayName = "Thresh - Death Leap (Q2)",         channelTime = 1 } },
        ["Aatrox"] =     { { spellName = "AatroxQ",              displayName = "Aatrox - Dark Flight (Q)",         channelTime = 0 } },
        ["Renekton"] =   { { spellName = "RenektonSliceAndDice", displayName = "Renekton - Slice & Dice (E)",      channelTime = 0 } },
        ["Kennen"] =     { { spellName = "KennenLightningRush",  displayName = "Kennen - Lightning Rush (E)",      channelTime = 0 },
                           { spellName = "SummonerFlash",        displayName = "Kennen - Flash",                   channelTime = 0 } },
        ["Olaf"] =       { { spellName = "OlafRagnarok",         displayName = "Olaf - Ragnarok (R)",              channelTime = 0 } },
        ["Udyr"] =       { { spellName = "UdyrBearStance",       displayName = "Udyr - Bear Stance (E)",           channelTime = 1 } },
        ["Volibear"] =   { { spellName = "VolibearQ",            displayName = "Volibear - Rolling Thunder (Q)",   channelTime = 1 } },
        ["Talon"] =      { { spellName = "TalonCutthroat",       displayName = "Talon - Cutthroat (E)",            channelTime = 0 } },
        ["JarvanIV"] =   { { spellName = "JarvanIVDragonStrike", displayName = "Jarvan IV - Dragon Strike (Q)",    channelTime = 0 } },
        ["Warwick"] =    { { spellName = "InfiniteDuress",       displayName = "Warwick - Infinite Duress (R)",    channelTime = 1.5 } },
        ["Jax"] =        { { spellName = "JaxLeapStrike",        displayName = "Jax - Leap Strike (Q)",            channelTime = 0 } },
        ["Yasuo"] =      { { spellName = "YasuoRKnockUpComboW",  displayName = "Yasuo - Last Breath (R)",          channelTime = 1.5 } },
        ["Diana"] =      { { spellName = "DianaTeleport",        displayName = "Diana - Lunar Rush (R)",           channelTime = 0 } },
        ["LeeSin"] =     { { spellName = "BlindMonkQTwo",        displayName = "Lee Sin - Resonating Strike (Q2)", channelTime = 0 } },
        ["Shen"] =       { { spellName = "ShenShadowDash",       displayName = "Shen - Shadow Dash (E)",           channelTime = 0 } },
        ["Alistar"] =    { { spellName = "Headbutt",             displayName = "Alistar - Headbutt (W)",           channelTime = 0 } },
        ["Amumu"] =      { { spellName = "BandageToss",          displayName = "Amumu - Bandage Toss (Q)",         channelTime = 0.5 } },
        ["Urgot"] =      { { spellName = "UrgotSwap2",           displayName = "Urgot - HK Position Reverser (R)", channelTime = 0 } },
        ["Rengar"] =     { { spellName = "RengarR",              displayName = "Rengar - Thrill of the Hunt (R)",  channelTime = 1 } },
        ["Katarina"] =   { { spellName = "KatarinaE",            displayName = "Katarina - Shunpo (E)",            channelTime = 0 } },
        ["Leona"] =      { { spellName = "LeonaZenithBlade",     displayName = "Leona - Zenith Blade (E)",         channelTime = 1 } },
        ["Maokai"] =     { { spellName = "MaokaiUnstableGrowth", displayName = "Maokai - Twisted Advance (W)",     channelTime = 1 } },
        ["XinZhao"] =    { { spellName = "XenZhaoSweep",         displayName = "Xin Zhao - Audacious Charge (E)",  channelTime = 0 } }
    }

    -- TODO: Add interrupter

end

function Orianna:GetSkins()
    return {
        "Classic",
        "Gothic",
        "Swen Chaos",
        "Bladecraft",
        "TPA"
    }
end

function Orianna:OnTick()

    OnTickChecks()

    OW:EnableAttacks()
    OW:ForceTarget()

    local target = GetBestTarget(Qrange + Qradius)
    if not target then
        target = GetBestTarget(Qrange + Qradius * 2)
    end
    if Menu.Combo.Enabled then
        Combo(target)
    elseif (Menu.Harass.Enabled or Menu.Harass.Enabled2) and (Menu.Harass.ManaCheck <= (myHero.mana / myHero.maxMana * 100)) then
        Harass(target)
    end

    if Menu.Farm.Freeze or Menu.Farm.LaneClear then
        local Mode = Menu.Farm.Freeze and "Freeze" or "LaneClear"
        if Menu.Farm.ManaCheck >= (myHero.mana / myHero.maxMana * 100) then
            Mode = "Freeze"
        end

        Farm(Mode)
    end
    
    if Menu.JungleFarm.Enabled then
        FarmJungle()
    end

end

function Orianna:OnCombo()
end

function Orianna:OnHarass()
end

function Orianna:OnFarm()
end

function Orianna:OnJungleFarm()
end

function Orianna:OnDraw()
end

function Orianna:OnCreateObj(object)

    -- Validating
    if not object or not object.name then return end

    -- Ball to pos
    if object.name:lower():find("yomu_ring_green") then
        self.ballPos = object
        self.ballMoving = false
    -- Ball to hero
    elseif object.name:lower():find("orianna_ball_flash_reverse") then
        self.ballPos = player.visionPos
        self.ballMoving = false
    end

end

function Orianna:OnProcessSpell(unit, spell)

    -- Validating
    if not unit or not unit.valid or not spell or not spell.name then return end

    if unit.isMe then
        -- Orianna Q
        if spell.name:lower():find("orianaizunacommand") then
            self.ballMoving = true
            DelayAction(function(p) self.ballPos = Vector(p) end, GetDistance(spell.endPos, self.ballPos) / self.ballSpeed[_Q] - GetLatency()/1000 - 0.35, { Vector(spell.endPos) })
        -- Orianna E
        elseif spell.name:lower():find("orianaredactcommand") then
            self.ballPos = spell.target
            self.ballMoving = true
        end
    end

    -- Initiator helper
    if unit.type == player.type then
        self.lastSpellUsed[unit.networkID] = { spellName = spell.name, time = os.clock() }
    end
end

function OnGainBuff(unit, buff)

    -- Validating
    if not unit or not unit.valid or not unit.team or not buff or not buff.name then return end

    -- Ball applying to ally
    if unit.team == player.team and buff.name:lower():find("orianaghostself") then
        self.ballPos = unit.visionPos
        self.ballMoving = false
    end

end

function Orianna:ApplyMenu()

    menu.combo:addParam("sep",    "",                        SCRIPT_PARAM_INFO, "")
    menu.combo:addParam("useQ",   "Use Q",                   SCRIPT_PARAM_ONOFF, true)
    menu.combo:addParam("useW",   "Use W",                   SCRIPT_PARAM_ONOFF, true)
    menu.combo:addParam("useE",   "Use E",                   SCRIPT_PARAM_ONOFF, true)
    menu.combo:addParam("useR",   "Use R",                   SCRIPT_PARAM_ONOFF, true)
    menu.combo:addParam("sep",    "",                        SCRIPT_PARAM_INFO, "")
    menu.combo:addParam("numR",   "Use R on",                SCRIPT_PARAM_LIST, 1, { "1+ target", "2+ targets", "3+ targets", "4+ targets" , "5+ targets" })
    menu.combo:addParam("sep",    "",                        SCRIPT_PARAM_INFO, "")
    menu.combo:addParam("ignite", "Use Ignite",              SCRIPT_PARAM_ONOFF, true)

    menu.harass:addParam("sep",  "",                         SCRIPT_PARAM_INFO, "")
    menu.harass:addParam("useQ", "Use Q",                    SCRIPT_PARAM_ONOFF, true)
    menu.harass:addParam("useW", "Use W",                    SCRIPT_PARAM_ONOFF, false)
    menu.harass:addParam("sep",  "",                         SCRIPT_PARAM_INFO, "")
    menu.harass:addParam("mana", "Don't harass if mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)

    menu:addSubMenu("Misc", "misc")
        menu.misc:addSubMenu("Auto E on initiators", "autoE")
        local added = false
        for champion, spells in pairs(self.initiatorList) do
            if table.contains(GetAllyHeroes(), champion) then
                for _, data in ipairs(spells) do
                    added = true
                    menu.misc.autoE:addParam(champion..data.spellName, data.displayName, SCRIPT_PARAM_ONOFF, true)
                end
            end
        end
        if not added then
            menu.misc.autoE:addParam("info", "No supported initiators found!", SCRIPT_PARAM_INFO, "")
        else
            menu.misc.autoE:addParam("sep",    "",       SCRIPT_PARAM_INFO, "")
            menu.misc.autoE:addParam("active", "Active", SCRIPT_PARAM_ONOFF, true)
        end
        menu.misc:addParam("autoW",     "Auto W on",                         SCRIPT_PARAM_LIST, 1, { "Nope", "1+ target", "2+ targets", "3+ targets", "4+ targets", "5+ targets" })
        menu.misc:addParam("autoR",     "Auto R on",                         SCRIPT_PARAM_LIST, 1, { "Nope", "1+ target", "2+ targets", "3+ targets", "4+ targets", "5+ targets" })
        menu.misc:addParam("EQ",        "Use E + Q if tEQ < %x * tQ",        SCRIPT_PARAM_SLICE, 100, 0, 200)
        menu.misc:addParam("interrupt", "Auto interrupt important spells",   SCRIPT_PARAM_ONOFF, true)
        menu.misc:addParam("blockR",    "Block R if it is not going to hit", SCRIPT_PARAM_ONOFF, true)

    menu:addSubMenu("Farm", "farm")
        menu.farm:addParam("freeze", "Farm Freezing",          SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
        menu.farm:addParam("lane",   "Farm LaneClear",         SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
        menu.farm:addParam("sep",    "",                       SCRIPT_PARAM_INFO, "")
        menu.farm:addParam("useQ",   "Use Q",                  SCRIPT_PARAM_LIST, 4, { "No", "Freezing", "LaneClear", "Both" })
        menu.farm:addParam("useW",   "Use W",                  SCRIPT_PARAM_LIST, 3, { "No", "Freezing", "LaneClear", "Both" })
        menu.farm:addParam("useE",   "Use E",                  SCRIPT_PARAM_LIST, 3, { "No", "Freezing", "LaneClear", "Both" })
        menu.farm:addParam("sep",    "",                       SCRIPT_PARAM_INFO, "")
        menu.farm:addParam("mana",   "Don't farm if mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)

    menu:addSubMenu("JungleFarm", "jfarm")
        menu.jfarm:addParam("active", "Farm!",                 SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
        menu.jfarm:addParam("sep",    "",                      SCRIPT_PARAM_INFO, "")
        menu.jfarm:addParam("useQ",   "Use Q",                 SCRIPT_PARAM_ONOFF, true)
        menu.jfarm:addParam("useW",   "Use W",                 SCRIPT_PARAM_ONOFF, true)
        menu.jfarm:addParam("useE",   "Use E",                 SCRIPT_PARAM_ONOFF, true)

    menu:addSubMenu("Drawing", "drawing")
        AAcircle:AddToMenu(menu.drawing,            "AA Range", false, true, true)
        circles[_Q]:AddToMenu(menu.drawing,         "Q range", true, true, true)
        self.ballCircles[2]:AddToMenu(menu.drawing, "W width", true, true, true)
        self.ballCircles[3]:AddToMenu(menu.drawing, "R width", true, true, true)
        self.ballCircles[1]:AddToMenu(menu.drawing, "Ball position", true, true, true)
        DLib:AddToMenu(menu.drawing, self.mainCombo)

end