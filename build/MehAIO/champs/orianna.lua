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
        [_W] = { range = -1,                                    width = 235, delay = 0.25 },
        [_E] = { range = 1095,                                  width = 80,  delay = 0.25, speed = 1700 },
        [_R] = { range = -1,                                    width = 380, delay = 0.6  },
    }
    initializeSpells()

    -- Finetune spells
    spells[_E]:SetSkillshot(VP, SKILLSHOT_LINEAR, spellData[_E].width, spellData[_E].delay, spellData[_E].speed, false)
    spells[_E].skillshotType = nil
    spells[_W].packetCast = true
    spells[_R].packetCast = true

    -- Circle customization
    circles[_Q].color = { 255, 255, 100, 0 }
    circles[_Q].width = 2
    circles[_W].enabled = false
    circles[_E].enabled = false
    circles[_R].enabled = false

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

    self.ballPos = player
    self.ballMoving = false

    self.ballCircles = {
        DM:CreateCircle(self.ballPos, 50, 5, { 255, 200, 0, 0 }):SetDrawCondition(function() return not self.ballMoving and (not self.ballPos.networkID or self.ballPos.networkID ~= player.networkID) end),
        DM:CreateCircle(self.ballPos, spellData[_W].width, 1, { 200, 200, 0, 255 }):SetDrawCondition(function() return not self.ballMoving and spells[_W]:IsReady() end),
        DM:CreateCircle(self.ballPos, spellData[_R].width, 1, { 255, 200, 0, 255 }):SetDrawCondition(function() return not self.ballMoving and spells[_R]:IsReady() end)
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

    -- Precise packet hooks
    PacketHandler:HookOutgoingPacket(Packet.headers.S_CAST, function(p) self:OnCastSpell(p) end)

    -- Other helper values
    self.nearEnemyHeroes = false
    self.farRange = 1.3

end

-- Not working with Orianna, sorry guys :/
--[[function Orianna:GetSkins()
    return {
        "Classic",
        "Gothic",
        "Swen Chaos",
        "Bladecraft",
        "TPA"
    }
end]]

function Orianna:OnTick()

    -- Enemy check
    self.nearEnemyHeroes = CountEnemyHeroInRange(spells[_Q].range + spellData[_R].width)

    OW:EnableAttacks()
    OW:ForceTarget()

    -- Disable spellcasting attempts while ball is moving
    if self.ballMoving then skipCombo() return end

    -- Lane farm
    if menu.farm.freeze or menu.farm.lane then
        self:OnFarm()
    end
    
    -- Jungle farm
    if menu.jfarm.active then
        self:OnJungleFarm()
    end

    -- Auto E initiators
    if menu.misc.autoE.active and spells[_E]:IsReady() then
        for _, ally in ipairs(GetAllyHeroes()) do
            if _GetDistanceSqr(ally) < spells[_E].rangeSqr then
                local data = self.initiatorList[ally.charName]
                if data then
                    for _, spell in ipairs(data) do
                        if self.lastSpellUsed[ally.networkID] and menu.misc.autoE[spell.spellName .. self.lastSpellUsed[ally.networkID].spellName] and (os.clock() - self.lastSpellUsed[ally.networkID].time < 1.5) then
                            spells[_E]:Cast(ally)
                        end
                    end
                end
            end
        end
    end

    -- No checks when no enemies around
    if self.nearEnemyHeroes == 0 then return end

    -- Auto W
    if menu.misc.autoW > 1 and spells[_W]:IsReady() then
        local hitNum = self:GetEnemiesHitByW()
        if hitNum >= menu.misc.autoW - 1 then
            spells[_W]:Cast()
        end
    end
    
    -- Auto R
    if menu.misc.autoR > 1 and spells[_R]:IsReady() then
        local hitNum = self:GetEnemiesHitByR()
        if hitNum >= menu.misc.autoR - 1 and self:GetDistanceToClosestAlly(self.ballPos) < spells[_Q].rangeSqr * self.farRange then
            spells[_R]:Cast()
        end     
    end

    -- Auto R interrupt
    if menu.misc.interrupt then
        for _, enemy in ipairs(GetEnemyHeroes()) do
            for champion, spell in pairs(self.interruptList) do
                if _GetDistanceSqr(enemy) < spells[_Q].rangeSqr and self.lastSpellUsed[enemy.networkID] and spell == self.lastSpellUsed[enemy.networkID].spellName and (os.clock() - self.lastSpellUsed[enemy.networkID].time < 1) then
                    spells[_Q]:Cast(enemy.x, enemy.z)
                    if _GetDistanceSqr(self.ballPos, enemy) < spellData[_R].width ^ 2 then
                        spells[_R]:Cast()
                    end
                end
            end
        end
    end

    -- Harass toggle
    if not skip and not menu.harass.active and not menu.combo.active and menu.harass.toggle then
        self:OnHarass()
    end

end

function Orianna:OnCombo()

    -- Fighting a single target
    if self.nearEnemyHeroes == 1 then

        local target = STS:GetTarget(spells[_Q].range + spells[_Q].width)

        -- No target found, return
        if not target then return end

        -- Disable autoattacks due to danger or target being too close
        if ((_GetDistanceSqr(target) < 300 * 300) or ((player.health / player.maxHealth < 0.25) and (player.health / player.maxHealth < target.health / target.maxHealth))) then
            OW:DisableAttacks()
        end

        -- Cast Q
        if menu.combo.useQ and spells[_Q]:IsReady() then
            self:PredictCastQ(target)
        end

        -- Cast ult if target is killable
        if menu.combo.useR and spells[_R]:IsReady() and CountEnemyHeroInRange(1000, target) >= CountAllyHeroInRange(1000, target)  then
            if DLib:IsKillable(target, self.mainCombo) and GetDistanceToClosestAlly(self.ballPos) < spells[_Q].range * self.farRange then
                if self:GetEnemiesHitByR() >= menu.combo.numR then
                    spells[_R]:Cast()
                end
            end
        end

        -- Cast W if it will hit
        if menu.combo.useW and spells[_W]:IsReady() then
            if self:GetEnemiesHitByW() > 0 then
                spells[_W]:Cast()
            end
        end
        
        -- Cast E
        if menu.combo.useE and spells[_E]:IsReady() then
            -- Cast E on ally for gap closing
            for _, ally in ipairs(GetAllyHeroes()) do
                if ValidTarget(ally, spells[_E].range, false) and CountEnemyHeroInRange(400, ally) > 0 and _GetDistanceSqr(ally, target) < 400 * 400 then
                    spells[_E]:Cast(ally)
                    return
                end
            end
            -- Cast E on self for damaging target
            if self:GetEnemiesHitByE(player) > 0 then
                spells[_E]:Cast(player)
            end
        end

        if menu.combo.ignite and _IGNITE then
            local igniteTarget = STS:GetTarget(600)
            if igniteTarget and DLib:IsKillable(igniteTarget, self.mainCombo) then
                CastSpell(_IGNITE, igniteTarget)
            end
        end

    -- Fighting multiple targets
    elseif self.nearEnemyHeroes > 1 then

        local target = STS:GetTarget(spells[_Q].range + spells[_Q].width)

        -- No target found, return
        if not target then return end

        -- Disable attacks due to danger mode or target too close
        for _, enemy in ipairs(GetEnemyHeroes()) do
            if ValidTarget(enemy, 300) and (player.health / player.maxHealth < 0.25) then
                OW:DisableAttacks()
            end
        end

        -- Cast Q on best location
        if menu.combo.useQ and spells[_Q]:IsReady() then
            local castPosition, hitNum = self:GetBestPositionQ(target)
            
            if castPosition and hitNum > 1 then
                spells[_Q]:Cast(castPosition.x, castPosition.z)
            else
                self:PredictCastQ(target)
            end
        end

        -- Cast R on best location
        if menu.combo.useR and spells[_R]:IsReady() then
            if CountEnemyHeroInRange(800, self.ballPos) > 1 then
                local hitNum, enemiesHit = self:GetEnemiesHitByR()
                local potentialKills, kills = 0, 0
                if hitNum >= 2 then
                    for _, enemy in ipairs(enemiesHit) do
                        if enemy.health - DLib:CalcComboDamage(enemy, self.mainCombo) < 0.4 * enemy.maxHealth or (DLib:CalcComboDamage(enemy, self.mainCombo) >= 0.4 * enemy.maxHealth) then
                            potentialKills = potentialKills + 1
                        end
                        if DLib:IsKillable(enemy, self.mainCombo) then
                            kills = kills + 1
                        end
                    end
                end
                if ((GetDistanceToClosestAlly(self.ballPos) < spells[_Q].range * self.farRange and hitNum >= CountEnemyHeroInRange(800, self.ballPos) or potentialKills > 1) or kills > 0) and hitNum >= menu.combo.numR then
                    spells[_R]:Cast()
                end
            elseif menu.combo.numR == 1 then
                if self:GetEnemiesHitByR() > 0 and DLib:IsKillable(target, {_Q, _W, _R}) and GetDistanceToClosestAlly(self.ballPos) < spells[_Q].range * self.farRange then
                    spells[_R]:Cast()
                end
            end
        end
        
        -- Cast W if it will hit
        if menu.combo.useW and spells[_W]:IsReady() then
            if self:GetEnemiesHitByW() > 0 then
                spells[_W]:Cast()
            end
        end

        -- Force the new target
        if OW:InRange(target) then
            OW:ForceTarget(target)
        end
        
        -- Cast E
        if menu.combo.useE and spells[_E]:IsReady() then
            -- Cast on self for damaging enemies
            if CountEnemyHeroInRange(800, self.ballPos) < 3 then
                if self:GetEnemiesHitByE(player) > 0 then
                    spells[_E]:Cast(player)
                    return
                end
            else
                if self:GetEnemiesHitByE(player) > 1 then
                    spells[_E]:Cast(player)
                    return
                end
            end
            -- Cast on allies for gap closing
            for _, ally in ipairs(GetAllyHeroes()) do
                if ValidTarget(ally, spells[_E].range, false) and CountEnemyHeroInRange(300, ally) > 2 and _GetDistanceSqr(ally, target) < 300 * 300 then
                    spells[_E]:Cast(ally)
                    return
                end
            end
        end

        if menu.combo.ignite and _IGNITE then
            local igniteTarget = STS:GetTarget(600)
            if igniteTarget and DLib:IsKillable(igniteTarget, self.mainCombo) then
                CastSpell(_IGNITE, igniteTarget)
            end
        end
    end

end

function Orianna:OnHarass()

    if menu.harass.mana > (player.mana / player.maxMana) * 100 then return end

    if menu.harass.useQ and spells[_Q]:IsReady() then
        self:PredictCastQ(STS:GetTarget(spells[_Q].range + spells[_Q].width))
    end

    if menu.harass.useW and spells[_W]:IsReady() then
        if self:GetEnemiesHitByW() > 0 then
            spells[_W]:Cast()
        end
    end

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
            local position = GetPredictedPos(minion, spells[_Q].delay, spells[_Q].speed, self.ballPos)
            CastSpell(_Q, position.x, position.z)
        end
        
        if useW and _GetDistanceSqr(self.ballPos, minion) < spellData[_W].width ^ 2 then
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

function Orianna:PredictCastQ(target)

    -- No target found, return
    if not target then return end

    -- Helpers
    local castPoint = nil

    spells[_Q]:SetSourcePosition(self.ballPos)
    spells[_Q]:SetRange(math.huge)
    local castPosition, hitChance, position = spells[_Q]:GetPrediction(target)
    spells[_Q]:SetRange(spellData[_Q].range)

    -- Update castPoint
    castPoint = castPosition

    -- Hitchance too low, return
    if hitChance < 2 then return end

    -- Main target out of range, getting new target
    if _GetDistanceSqr(position) > spells[_Q].rangeSqr + (spellData[_W].width + VP:GetHitBox(target)) ^ 2 then
        target2 = STS:GetTarget(spells[_Q].range + spellData[_W].width + 250, 2)
        if target2 then
            spells[_Q]:SetRange(math.huge)
            castPoint = spells[_Q]:GetPrediction(target2)
            spells[_Q]:SetRange(spellData[_Q].range)
        else return end
    end

    -- Second target out of range aswell, return
    if _GetDistanceSqr(position) > spells[_Q].rangeSqr + (spellData[_W].width + VP:GetHitBox(target)) ^ 2 then
        do return end
    end

    -- EQ calculation for faster Q on target, only if enabled in menu
    if spells[_E]:IsReady() and menu.misc.EQ ~= 0 then
        local travelTime = _GetDistanceSqr(self.ballPos, castPoint) / (spells[_Q].speed ^ 2)
        local minTravelTime = _GetDistanceSqr(castPoint) / (spells[_Q].speed ^ 2) + _GetDistanceSqr(self.ballPos) / (spells[_E].speed ^ 2)
        local target = player

        for _, ally in ipairs(GetAllyHeroes()) do
            if ally.networkID ~= player.networkID and ValidTarget(ally, spells[_E].range, false) then
                local time = _GetDistanceSqr(ally, castPoint) / (spells[_Q].speed ^ 2) + _GetDistanceSqr(ally, self.ballPos) / (spells[_E].speed ^ 2)
                if time < minTravelTime then
                    minTravelTime = time
                    target = ally
                end
            end
        end

        if minTravelTime < (menu.misc.EQ / 100) * travelTime and (not target.isMe or _GetDistanceSqr(self.ballPos) > 100 * 100) and _GetDistanceSqr(target) < _GetDistanceSqr(castPoint) then
            spells[_E]:Cast(target)
            return
        end
    end

    -- Cast point adjusting if it's slightly out of range
    if _GetDistanceSqr(castPoint) > spells[_Q].rangeSqr then
        castPoint = Vector(player.visionPos) + spells[_Q].range * (Vector(castPoint) - Vector(player.visionPos)):normalized()
    end

    -- Cast Q
    spells[_Q]:Cast(castPoint.x, castPoint.z)

end

function Orianna:GetBestPositionQ(target)

    local points = {}
    local targets = {}
    
    spells[_Q]:SetSourcePosition(self.ballPos)
    local castPosition, hitChance, position = spells[_Q]:GetPrediction(target)

    table.insert(points, position)
    table.insert(targets, target)
    
    for _, enemy in ipairs(GetEnemyHeroes()) do
        if ValidTarget(enemy, spells[_Q].range + spellData[_R].width) and enemy.networkID ~= target.networkID then
            castPosition, hitChance, position = spells[_Q]:GetPrediction(enemy)
            table.insert(points, position)
            table.insert(targets, enemy)
        end
    end
    
    for o = 1, 5 do
        local circle = MEC(points):Compute()
        
        if circle.radius <= spellData[_R].width and #points >= 3 and spells[_R]:IsReady() then
            return circle.center, 3
        end
    
        if circle.radius <= spellData[_W].width and #points >= 2 and spells[_W]:IsReady() then
            return circle.center, 2
        end
        
        if #points == 1 then
            return circle.center, 1
        elseif circle.radius <= spellData[_Q].radius and #points >= 1 then
            return circle.center, 2
        end
        
        local distance = -1
        local mainPoint = points[1]
        local index = 0
        
        for i = 2, #points do
            if _GetDistanceSqr(points[i], mainPoint) > distance then
                distance = _GetDistanceSqr(points[i], mainPoint)
                index = i
            end
        end
        if index > 0 then
            table.remove(points, index)
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
    for _, minion in ipairs(self.enemyMinions.objects) do
        local position = Vector(minion.x, 0, minion.z)
        local pointInLine = VectorPointProjectionOnLineSegment(sourcePoint, destPoint, position)
        if _GetDistanceSqr(pointInLine, position) < spells[_E].width ^ 2 then
            table.insert(minions, minion)
        end
    end
    return #minions, minions

end

function Orianna:GetDistanceToClosestAlly(point)

    local distance = _GetDistanceSqr(point)
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
        self.ballPos = Vector(object)
        self.ballMoving = false
    -- Ball to hero
    elseif object.name:lower():find("orianna_ball_flash_reverse") then
        self.ballPos = player
        self.ballMoving = false
    end

end

function Orianna:OnProcessSpell(unit, spell)

    -- Validating
    if not unit or not spell or not spell.name then return end

    if unit.isMe then
        -- Orianna Q
        if spell.name:lower():find("orianaizunacommand") then
            self.ballMoving = true
            DelayAction(function(p) self.ballPos = Vector(p) end, GetDistance(spell.endPos, self.ballPos) / spells[_Q].speed - GetLatency()/1000 - 0.35, { Vector(spell.endPos) })
        -- Orianna E
        elseif spell.name:lower():find("orianaredactcommand") and (not self.ballPos.networkID or self.ballPos.networkID ~= spell.target.networkID) then
            self.ballPos = spell.target
            self.ballMoving = true
        end
    end

    -- Initiator helper
    if unit.type == player.type and unit.team == player.team then
        self.lastSpellUsed[unit.networkID] = { spellName = spell.name, time = os.clock() }
        -- Instant shield
        if _GetDistanceSqr(unit) < spells[_E].rangeSqr then
            local data = self.initiatorList[unit.charName]
            if data then
                for _, spell in ipairs(data) do
                    if spell.spellName == spell.name then
                        spells[_E]:Cast(unit)
                    end
                end
            end
        end
    end

end

function Orianna:OnGainBuff(unit, buff)

    -- Validating
    if not unit or not unit.team or not buff or not buff.name then return end

    -- Ball applying to unit
    if unit.team == player.team and (buff.name:lower():find("orianaghostself") or buff.name:lower():find("orianaghost")) then
        self.ballPos = unit
        self.ballMoving = false
    end

end

function Orianna:OnCastSpell(p)

    if menu.misc.blockR then
        if Packet(p):get('spellId') == _R then
            if self:GetEnemiesHitByR() == 0 then
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
    menu.combo:addParam("ignite", "Use ignite",              SCRIPT_PARAM_ONOFF, true)

    menu.harass:addParam("toggle", "Harass toggle",            SCRIPT_PARAM_ONKEYTOGGLE, false, string.byte("L"))
    menu.harass:addParam("sep",    "",                         SCRIPT_PARAM_INFO, "")
    menu.harass:addParam("useQ",   "Use Q",                    SCRIPT_PARAM_ONOFF, true)
    menu.harass:addParam("useW",   "Use W",                    SCRIPT_PARAM_ONOFF, false)
    menu.harass:addParam("sep",    "",                         SCRIPT_PARAM_INFO, "")
    menu.harass:addParam("mana",   "Don't harass if mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)

    menu:addSubMenu("Misc", "misc")
        menu.misc:addSubMenu("Auto E on initiators", "autoE")
        local added = false
        for _, ally in ipairs(GetAllyHeroes()) do
            local data = self.initiatorList[ally.charName]
            if data then
                for _, spell in ipairs(data) do
                    added = true
                    menu.misc.autoE:addParam(ally.charName..spell.spellName, spell.displayName, SCRIPT_PARAM_ONOFF, true)
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