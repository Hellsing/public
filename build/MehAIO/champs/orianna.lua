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
    spells[_E].SetSkillshot(VP, SKILLSHOT_LINEAR, spellData[_E].width, spellData[_E].delay, spellData[_E].speed, false)
    spells[_E].skillshotType = nil
    spells[_W].packetCast = true
    spells[_R].packetCast = true

    -- Circle customization
    circles[_Q].color = { 255, 255, 100, 0 }
    circles[_Q].width = 2
    circles[_W].SetEnabled(false)
    circles[_E]:SetEnabled(false)
    circles[_R]:SetEnabled(false)

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

    self.ballCircles = {
        DM:CreateCircle(ballPos, 50, 2, { 255, 200, 0, 0 }):SetDrawCondition(function() return not self.ballMoving end),
        DM:CreateCircle(ballPos, spellData[_W].width, 2, { 200, 200, 0, 255 }):SetDrawCondition(function() return not self.ballMoving and spells[_W]:IsReady() end):SetEnabled(false),
        DM:CreateCircle(ballPos, spellData[_R].width, 2, { 255, 200, 0, 255 }):SetDrawCondition(function() return not self.ballMoving and spells[_R]:IsReady() end):SetEnabled(false)
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
        ["Vi"]         = { { spellName = "ViQ",                  displayName = "Vi - Vault Breaker (Q)"           },
                           { spellName = "ViR",                  displayName = "Vi - Assault and Battery (R)"     } },
        ["Malphite"]   = { { spellName = "Landslide",            displayName = "Malphite - Unstoppable Force (R)" } },
        ["Nocturne"]   = { { spellName = "NocturneParanoia",     displayName = "Nocturne - Paranoia (R)"          } },
        ["Zac"]        = { { spellName = "ZacE",                 displayName = "Zac - Elastic Slingshot (E)"      } },
        ["MonkeyKing"] = { { spellName = "MonkeyKingNimbus",     displayName = "Wukong - Nimbus Strike (E)"       },
                           { spellName = "MonkeyKingSpinToWin",  displayName = "Wukong - Cyclone (R)"             },
                           { spellName = "SummonerFlash",        displayName = "Wukong - Flash"                   } },
        ["Shyvana"]    = { { spellName = "ShyvanaTransformCast", displayName = "Shyvana - Dragon\'s Descent (R)"  } },
        ["Thresh"]     = { { spellName = "threshqleap",          displayName = "Thresh - Death Leap (Q2)"         } },
        ["Aatrox"]     = { { spellName = "AatroxQ",              displayName = "Aatrox - Dark Flight (Q)"         } },
        ["Renekton"]   = { { spellName = "RenektonSliceAndDice", displayName = "Renekton - Slice & Dice (E)"      } },
        ["Kennen"]     = { { spellName = "KennenLightningRush",  displayName = "Kennen - Lightning Rush (E)"      },
                           { spellName = "SummonerFlash",        displayName = "Kennen - Flash"                   } },
        ["Olaf"]       = { { spellName = "OlafRagnarok",         displayName = "Olaf - Ragnarok (R)"              } },
        ["Udyr"]       = { { spellName = "UdyrBearStance",       displayName = "Udyr - Bear Stance (E)"           } },
        ["Volibear"]   = { { spellName = "VolibearQ",            displayName = "Volibear - Rolling Thunder (Q)"   } },
        ["Talon"]      = { { spellName = "TalonCutthroat",       displayName = "Talon - Cutthroat (E)"            } },
        ["JarvanIV"]   = { { spellName = "JarvanIVDragonStrike", displayName = "Jarvan IV - Dragon Strike (Q)"    } },
        ["Warwick"]    = { { spellName = "InfiniteDuress",       displayName = "Warwick - Infinite Duress (R)"    } },
        ["Jax"]        = { { spellName = "JaxLeapStrike",        displayName = "Jax - Leap Strike (Q)"            } },
        ["Yasuo"]      = { { spellName = "YasuoRKnockUpComboW",  displayName = "Yasuo - Last Breath (R)"          } },
        ["Diana"]      = { { spellName = "DianaTeleport",        displayName = "Diana - Lunar Rush (R)"           } },
        ["LeeSin"]     = { { spellName = "BlindMonkQTwo",        displayName = "Lee Sin - Resonating Strike (Q2)" } },
        ["Shen"]       = { { spellName = "ShenShadowDash",       displayName = "Shen - Shadow Dash (E)"           } },
        ["Alistar"]    = { { spellName = "Headbutt",             displayName = "Alistar - Headbutt (W)"           } },
        ["Amumu"]      = { { spellName = "BandageToss",          displayName = "Amumu - Bandage Toss (Q)"         } },
        ["Urgot"]      = { { spellName = "UrgotSwap2",           displayName = "Urgot - HK Position Reverser (R)" } },
        ["Rengar"]     = { { spellName = "RengarR",              displayName = "Rengar - Thrill of the Hunt (R)"  } },
        ["Katarina"]   = { { spellName = "KatarinaE",            displayName = "Katarina - Shunpo (E)"            } },
        ["Leona"]      = { { spellName = "LeonaZenithBlade",     displayName = "Leona - Zenith Blade (E)"         } },
        ["Maokai"]     = { { spellName = "MaokaiUnstableGrowth", displayName = "Maokai - Twisted Advance (W)"     } },
        ["XinZhao"]    = { { spellName = "XenZhaoSweep",         displayName = "Xin Zhao - Audacious Charge (E)"  } }
    }

    self.interruptList = {
        ["Katarina"] = "KatarinaR",
        ["Malzahar"] = "AlZaharNetherGrasp",
        ["Warwick"]  = "InfiniteDuress",
        ["Velkoz"]   = "VelkozR"
    }

    self.farDistance = 1.3

    PacketHandler:HookOutgoingPacket(Packet.headers.S_CAST, function(p) self:OnCastSpell(p) end)

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

    -- Auto W
    if menu.misc.autoW > 1 and spells[_W]:IsReady() then
        local hitNum = self:GetEnemiesHitByW()
        if hitNum >= menu.misc.autoW - 1 then
            spells[_W]:Cast()
        end     
    end
    
    -- Auto R
    if menu.misc.autoR > 1 and spells[_R]:IsReady() then
        local hitNum = self:GetEnemiesHitByR()()
        if hitNum >= menu.misc.autoR - 1 and self:GetDistanceToClosestAlly(self.ballPos) < spells[_Q].rangeSqr * (self.farDistance ^ 2) then
            spells[_R]:Cast()
        end     
    end
    
    -- Auto E initiators
    if menu.misc.autoE.active and spells[_E]:IsReady() then
        for _, ally in ipairs(GetAllyHeroes()) do
            if _GetDistanceSqr(ally) < spells[_E].rangeSqr then
                for champion in pairs(self.initiatorList) do
                    if self.lastSpellUsed[ally.networkID] and self.lastSpellUsed[ally.networkID].spellName ~= nil and menu.misc.autoE[champion .. self.lastSpellUsed[ally.networkID].spellName] and (os.clock() - self.lastSpellUsed[ally.networkID].time < 1.5) then
                        spells[_E]:Cast(ally)
                    end
                end
            end
        end
    end

    -- Auto R interrupt
    if menu.misc.interrupt then
        for _, enemy in ipairs(GetEnemyHeroes()) do
            for champion, spell in pairs(self.interruptList) do
                if _GetDistanceSqr(enemy) < spells[_Q].rangeSqr and self.lastSpellUsed[enemy.networkID] and spell == self.lastSpellUsed[enemy.networkID].spellName and (os.clock() - self.lastSpellUsed[enemy.networkID].time < 1) then
                    spells[_Q]:Cast(enemy.x, enemy.z)
                    if _GetDistanceSqr(self.ballPos, enemy) < spells[_R].width ^ 2 then
                        spells[_R]:Cast()
                    end
                end
            end
        end
    end

end

function Orianna:OnCombo()
end

function Orianna:OnHarass()
end

function Orianna:OnFarm()

    if menu.farm.mana > (player.mana / player.maxMana) * 100 then return end

    self.enemyMinions:update()

    local useQ = spells[_Q]:IsReady() and (menu.farm.lane and (menu.farm.useQ >= 3) or (menu.farm.useQ == 2))
    local useW = spells[_W]:IsReady() and (menu.farm.lane and (menu.farm.useW >= 3) or (menu.farm.useW == 2))
    local useE = spells[_E]:IsReady() and (menu.farm.lane and (menu.farm.useE >= 3) or (menu.farm.useE == 2))
    
    if useQ then
        if useW then
            local hitNum = 0
            local castPosition = 0
            for _, minion in ipairs(self.enemyMinions.objects) do
                if _GetDistanceSqr(minion) < spells[_Q].rangeSqr then
                    local minionPosition = GetPredictedPos(minion, spells[_Q].delay, spells[_Q].speed, self.ballPos)
                    local minionHits = CountObjectsNearPos(minion, nil, spellData[_W].width, self.enemyMinions.objects)
                    if minionHits >= hitNum then
                        hitNum = minionHits
                        castPosition = minionPosition
                    end
                end
            end
            if hitNum > 0 and castPosition then
                spells[_Q]:Cast(castPosition.x, castPosition.z)
            end
        else
            for _, minion in ipairs(self.enemyMinions.objects) do
                if DLib:IsKillable(minion, {_Q}) and not OW:InRange(minion) then
                    local minionPosition = GetPredictedPos(minion, spells[_Q].delay, spells[_Q].speed, self.ballPos)
                    spells[_Q]:Cast(minionPosition.x, minionPosition.z)
                    break
                end
            end
        end
    end

    if useW then
        local minionHits = CountObjectsNearPos(self.ballPos, nil, spellData[_W].width, self.enemyMinions.objects)
        if minionHits >= 3 then
            spells[_W]:Cast()
        end
    end

    if useE and not useW then
        local minionHits = self:GetMinionsHitE()
        if minionHits >= 3 then
            spells[_E]:Cast(player)
        end
    end

end

function Orianna:OnJungleFarm()

    self.jungleMinions:update()

    local useQ = menu.jfarm.useQ and spells[_Q]:IsReady()
    local useW = menu.jfarm.useW and spells[_W]:IsReady()
    local useE = menu.jfarm.useE and spells[_E]:IsReady()
    
    local minion = self.jungleMinions.objects[1]
    
    if minion then
        if useQ then
            local position = GetPredictedPos(minion, spells[_Q].delay, BallSpeed, BallPos)
            CastSpell(_Q, position.x, position.z)
        end
        
        if useW and _GetDistanceSqr(self.ballPos, minion) < spells[_W].width ^ 2 then
            spells[_W]:Cast()
        end
        
        if useE and not useW and _GetDistanceSqr(minion) < 700 ^ 2 then
            local target = player
            local distance = _GetDistanceSqr(minion)
            for _, ally in ipairs(GetAllyHeroes()) do
                local dist = _GetDistanceSqr(ally, minion)
                if ValidTarget(ally, spells[_E].range, false) and dist < distance then
                    distance = dist
                    target = ally
                end
            end
            spells[_E]:Cast(target)
        end
    end

end

function Orianna:GetEnemiesHitByW()

    local enemies = {}
    for _, enemy in ipairs(GetEnemyHeroes()) do
        local position = GetPredictedPos(enemy, spellData[_W].delay)
        if ValidTarget(enemy) and _GetDistanceSqr(position, self.ballPos) < spellData[_W].width ^ 2 and _GetDistanceSqr(enemy, self.ballPos) < spellData[_W].width ^ 2 then
            table.insert(enemies, enemy)
        end
    end
    return #enemies, enemies

end

function Orianna:GetEnemiesHitByE(destination)

    local enemies = {}
    local sourcePoint = Vector(self.ballPos.x, 0, self.ballPos.z)
    local destPoint = Vector(destination.x, 0, destination.z)
    spells[_E].range = math.huge
    spells[_E].skillshotType = SKILLSHOT_LINEAR
    spells[_E]:SetSourcePosition(sourcePoint)
    for _, enemy in ipairs(GetEnemyHeroes()) do
        local _, _, position = spells[_E]:GetPrediction(enemy)
        if position then
            local pointInLine, _, isOnSegment = VectorPointProjectionOnLineSegment(sourcePoint, destPoint, position)
            if ValidTarget(enemy) and isOnSegment and _GetDistanceSqr(pointInLine, position) < (spells[_E].width + VP:GetHitBox(enemy)) ^ 2 and _GetDistanceSqr(pointInLine, enemy) < (spells[_E].width * 2 + 30) ^ 2 then
                table.insert(enemies, enemy)
            end
        end
    end
    spells[_E].skillshotType = nil
    spells[_E].range = spellData[_E].range
    return #enemies, enemies

end

function Orianna:GetEnemiesHitByR()

    local enemies = {}
    for _, enemy in ipairs(GetEnemyHeroes()) do
        local position = GetPredictedPos(enemy, spellData[_R].delay)
        if ValidTarget(enemy) and _GetDistanceSqr(position, self.ballPos) < spellData[_R].width ^ 2 and _GetDistanceSqr(enemy, self.ballPos) < (1.25 * spellData[_R].width) ^ 2  then
            table.insert(enemies, enemy)
        end
    end
    return #enemies, enemies

end

function Orianna:GetMinionsHitE()

    local minions = {}
    local sourcePoint = Vector(self.ballPos.x, 0, self.ballPos.z)
    local destPoint = Vector(player.x, 0, player.z)
    for _, minion in ipairs(EnemyMinions.objects) do
        local position = Vector(minion.x, 0, minion.z)
        local pointInLine = VectorPointProjectionOnLineSegment(sourcePoint, destPoint, position)
        if _GetDistanceSqr(pointInLine, position) < spells[_E].width ^ 2 then
            table.insert(minions, minion)
        end
    end
    return #minions, minions

end

function Orianna:GetDistanceToClosestAlly(point)

    local distance = _GetDistanceSqr(point, player)
    for _, ally in ipairs(GetAllyHeroes()) do
        if ValidTarget(ally, math.huge, false) then
            local dist = _GetDistanceSqr(point, ally)
            if dist < distance then
                distance = dist
            end
        end
    end
    return distance

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
            DelayAction(function(p) self.ballPos = Vector(p) end, GetDistance(spell.endPos, self.ballPos) / spells[_Q].speed - GetLatency()/1000 - 0.35, { Vector(spell.endPos) })
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

function Orianna:OnCastSpell(p)

    if menu.misc.blockR then
        if Packet(p):get('spellId') == _R then
            local hitNum = self:GetEnemiesHitByR()
            if hitNum == 0 then
                p:Block()
            end
        end
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
        menu.farm:addParam("useQ",   "Use Q",                  SCRIPT_PARAM_LIST, 4, { "No", "Freeze", "LaneClear", "Both" })
        menu.farm:addParam("useW",   "Use W",                  SCRIPT_PARAM_LIST, 3, { "No", "Freeze", "LaneClear", "Both" })
        menu.farm:addParam("useE",   "Use E",                  SCRIPT_PARAM_LIST, 3, { "No", "Freeze", "LaneClear", "Both" })
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