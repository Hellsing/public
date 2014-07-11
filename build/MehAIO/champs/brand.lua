--[[
    ██████╗ ██████╗  █████╗ ███╗   ██╗██████╗ 
    ██╔══██╗██╔══██╗██╔══██╗████╗  ██║██╔══██╗
    ██████╔╝██████╔╝███████║██╔██╗ ██║██║  ██║
    ██╔══██╗██╔══██╗██╔══██║██║╚██╗██║██║  ██║
    ██████╔╝██║  ██║██║  ██║██║ ╚████║██████╔╝
    ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═════╝ 
]]

function Brand:__init()

    spellData = {
        [_Q] = { range = 1100, skillshotType = SKILLSHOT_LINEAR,   width = 60,  delay = 0.25, speed = 1600,      collision = true },
        [_W] = { range = 900,  skillshotType = SKILLSHOT_CIRCULAR, width = 240, delay = 1,    speed = math.huge, collision = false },
        [_E] = { range = 625 },
        [_R] = { range = 750 },
    }
    initializeSpells()

    -- Finetune spells
    spells[_W]:SetAOE(true)
    spells[_E].VP = VP

    -- Minions
    self.enemyMinions  = minionManager(MINION_ENEMY,  spells[_Q].range, player, MINION_SORT_MAXHEALTH_DEC)
    self.jungleMinions = minionManager(MINION_JUNGLE, spells[_Q].range, player, MINION_SORT_MAXHEALTH_DEC)

    self.mainCombo   = { ItemManager:GetItem("DFG"):GetId(), _AA, _Q, _W, _E, _R, _PASIVE, _IGNITE }
    self.bounceCombo = { ItemManager:GetItem("DFG"):GetId(), _AA, _Q, _W, _E, _R, _R, _R, _PASIVE, _IGNITE }

    -- Register damage sources
    DLib:RegisterDamageSource(_Q, _MAGIC, 40, 40,  _MAGIC, _AP, 0.65, function() return spells[_Q]:IsReady() end)
    DLib:RegisterDamageSource(_W, _MAGIC, 30, 45,  _MAGIC, _AP, 0.60, function() return spells[_W]:IsReady() end, function(target) return self:IsAblazed(target) and (player.ap * 0.15 + spells[_W]:GetLevel() * 15) or 0 end)
    DLib:RegisterDamageSource(_E, _MAGIC, 35, 35,  _MAGIC, _AP, 0.55, function() return spells[_E]:IsReady() end)
    DLib:RegisterDamageSource(_R, _MAGIC, 50, 100, _MAGIC, _AP, 0.5,  function() return spells[_R]:IsReady() end)
    DLib:RegisterDamageSource(_PASIVE, _MAGIC, 0, 0, _MAGIC, _AP, 0, nil, function(target) return 0.08 * target.maxHealth end)

end

function Brand:GetSkins()
    return {
        "Classic",
        "Apocalyptic",
        "Vandal",
        "Cryocore",
        "Zombie"
    }
end

function Brand:IsAblazed(target)
    return HasBuff(target, "brandablaze")
end

function Brand:OnTick()

    OW:EnableAttacks()

    -- Forced ult cast
    if menu.ult.castR and spells[_R]:IsReady() then
        local target = STS:GetTarget(spells[_R].range)
        spells[_R]:Cast(target)
    end

    -- Farming
    if menu.farm.freeze or menu.farm.lane then
        self:OnFarm()
    end

    -- Jungle farming
    if menu.jfarm.active then
        self:OnJungleFarm()
    end

    -- Misc stuff
    for _, enemy in ipairs(GetEnemyHeroes()) do
        if ValidTarget(enemy) and _GetDistanceSqr(enemy) < spells[_Q].rangeSqr then

            if menu.misc.autoStunQ and spells[_Q]:IsReady() then
                local status = spells[_E]:CastIfImmobile(enemy)
                if status ~= SPELLSTATE_TRIGGERED then
                    spells[_Q]:CastIfImmobile(enemy)
                end
            end

            if menu.misc.autoGapQ and spells[_Q]:IsReady() then
                local status = spells[_E]:CastIfDashing(enemy)
                if status ~= SPELLSTATE_TRIGGERED then
                    spells[_Q]:CastIfDashing(enemy)
                end
            end

            if menu.misc.autoStunW and spells[_W]:IsReady() and _GetDistanceSqr(enemy) < (spells[_W].range + spells[_W].width)^2 then
                spells[_W]:CastIfImmobile(enemy)
            end
        end
    end

    -- Auto cast ult
    if menu.ult.autoR ~= 1 then
        for _, enemy in ipairs(GetEnemyHeroes()) do
            if not menu.ult.targets[enemy.charName] and ValidTarget(enemy) and _GetDistanceSqr(enemy) < spells[_R].rangeSqr then
                local targets = SelectUnits(GetEnemyHeroes(), function(t) return ValidTarget(t) and _GetDistanceSqr(t, enemy) < 202500 end)
                if #targets > (menu.ult.autoR -1) then
                    spells[_R]:Cast(enemy)
                end
            end
        end
    end

end

function Brand:OnCombo()

    if not spells[_Q]:IsReady() and not spells[_W]:IsReady() and not spells[_E]:IsReady() and not spells[_R]:IsReady() then
        OW:EnableAttacks()
        return
    end
    
    local targets = {
        [_Q] = STS:GetTarget(spells[_Q].range),
        [_W] = STS:GetTarget(spells[_W].range),
        [_E] = STS:GetTarget(spells[_E].range),
        [_R] = STS:GetTarget(spells[_R].range),
    }
    local status = nil
    local spellTriggered = nil

    OW:DisableAttacks()

    if targets[_W] and DLib:IsKillable(targets[_W], self.mainCombo) then
        ItemManager:CastOffensiveItems(targets[_W])
    end

    if menu.combo.useQ and targets[_Q] and spells[_Q]:IsReady() then
        if self:IsAblazed(targets[_Q]) or not menu.misc.ablazed or DLib:IsKillable(targets[_Q], {_Q, _PASIVE}) then
            if not menu.combo.useE or not targets[_E] or not spells[_E]:IsReady() then
                if not menu.combo.useW or not targets[_W] or not spells[_W]:IsReady() then
                    status = spells[_Q]:Cast(targets[_Q])
                end
            end
        end
    end

    if menu.combo.useW and targets[_W] and spells[_W]:IsReady() then
        if not menu.combo.useE or not targets[_E] or not spells[_E]:IsReady() then
            if not status or status == SPELLSTATE_COLLISION then
                spellTriggered = spellTriggered or spells[_W]:Cast(targets[_W]) == SPELLSTATE_TRIGGERED
            end
        end
    end

    if menu.combo.useE and targets[_E] and spells[_E]:IsReady() and (DLib:IsKillable(targets[_E], self.mainCombo) or (spells[_Q]:IsReady() or spells[_W]:IsReady())) then
        spellTriggered = spellTriggered or spells[_E]:Cast(targets[_E]) == SPELLSTATE_TRIGGERED
    end

    if menu.combo.ignite and _IGNITE then
        local igniteTarget = STS:GetTarget(600)
        if igniteTarget and DLib:IsKillable(igniteTarget, self.mainCombo) then
            CastSpell(_IGNITE, igniteTarget)
        end
    end

    if menu.combo.useR and targets[_R] and spells[_R]:IsReady() then
        if not menu.ult.targets[targets[_R].charName] then
            -- Regular kill
            if (not spells[_Q]:IsReady() or not status or status == SPELLSTATE_COLLISION) and DLib:IsKillable(targets[_R], self.mainCombo) then
                if spells[_E]:IsReady() and _GetDistanceSqr(targets[_R]) <= spells[_E].rangeSqr then
                    spellTriggered = spellTriggered or spells[_E]:Cast(targets[_R]) == SPELLSTATE_TRIGGERED
                end
                spellTriggered = spellTriggered or spells[_R]:Cast(targets[_R]) == SPELLSTATE_TRIGGERED
            end
            -- Bounce kill
            self.enemyMinions:update()
            local enemies = SelectUnits(MergeTables(self.enemyMinions.objects, GetEnemyHeroes()), function(t) return ValidTarget(t) and _GetDistanceSqr(t, targets[_R]) < 202500 end)
            if #enemies > 1 and DLib:IsKillable(targets[_R], self.bounceCombo) then
                if not self:IsAblazed(targets[_R]) and spells[_E]:IsReady() and _GetDistanceSqr(targets[_R]) < spells[_E].rangeSqr then
                    if spells[_E]:Cast(targets[_R]) ~= SPELLSTATE_TRIGGERED then OW:EnableAttacks() return end
                end
                spellTriggered = spellTriggered or spells[_R]:Cast(targets[_R]) == SPELLSTATE_TRIGGERED
            end
        end
    end

    if not spellTriggered or status ~= SPELLSTATE_TRIGGERED then
        OW:EnableAttacks()
    end

end

function Brand:OnHarass()

    if menu.harass.mana > (player.mana / player.maxMana) * 100 then return end

    local targets = {
        [_Q] = STS:GetTarget(spells[_Q].range),
        [_W] = STS:GetTarget(spells[_W].range),
        [_E] = STS:GetTarget(spells[_E].range)
    }

    if menu.harass.useQ and targets[_Q] and spells[_Q]:IsReady() then
        spells[_Q]:Cast(targets[_Q])
    end

    if menu.harass.useW and targets[_W] and spells[_W]:IsReady() then
        spells[_W]:Cast(targets[_W])
    end

    if menu.harass.useE and targets[_E] and spells[_E]:IsReady() then
        spells[_E]:Cast(targets[_E])
    end

end

function Brand:OnFarm()

    if menu.farm.mana > (player.mana / player.maxMana) * 100 then return end

    self.enemyMinions:update()

    local minion = self.enemyMinions.objects[1]

    if minion then
        local useQ = spells[_Q]:IsReady() and (menu.farm.lane and (menu.farm.useQ >= 3) or (menu.farm.useQ == 2))
        local useW = spells[_W]:IsReady() and (menu.farm.lane and (menu.farm.useW >= 3) or (menu.farm.useW == 2))
        local useE = spells[_E]:IsReady() and (menu.farm.lane and (menu.farm.useE >= 3) or (menu.farm.useE == 2))

        if useQ then
            spells[_Q]:Cast(minion)
        end

        if useE then
            if menu.farm.lane then
                for _, minion in ipairs(self.enemyMinions.objects) do
                    if _GetDistanceSqr(minion) < spells[_E].rangeSqr and self:IsAblazed(minion) then
                        spells[_E]:Cast(minion)
                    end
                end
                if DLib:IsKillable(minion, {_E}) then
                    spells[_E]:Cast(minion)
                end
            else
                if not OW:InRange(minion) and DLib:IsKillable(minion, {_E}) then
                    spells[_E]:Cast(minion)
                end
            end 
        end

        if useW then
            local casterMinions = SelectUnits(self.enemyMinions.objects, function(t) return (t.charName:lower():find("wizard") or t.charName:lower():find("caster")) and ValidTarget(t) end)
            casterMinions = GetPredictedPositionsTable(VP, casterMinions, spells[_W].delay, spells[_W].width, spells[_W].range, math.huge, player, false)

            local castPosition, hitNumber = GetBestCircularFarmPosition(spells[_W].range, spells[_W].width, casterMinions)
            if hitNumber > 2 then
                spells[_W]:Cast(castPosition.x, castPosition.z)
                return
            end

            local allMinions = SelectUnits(self.enemyMinions.objects, function(t) return ValidTarget(t) end)
            allMinions = GetPredictedPositionsTable(VP, allMinions, spells[_W].delay, spells[_W].width, spells[_W].range, math.huge, player, false)

            local castPosition, hitNumber = GetBestCircularFarmPosition(spells[_W].range, spells[_W].width, allMinions)
            if hitNumber > 2 then
                spells[_W]:Cast(castPosition.x, castPosition.z)
                return
            end
        end
    end

end

function Brand:OnJungleFarm()

    self.jungleMinions:update()

    local minion = self.jungleMinions.objects[1]

    if minion then
        local useQ = menu.jfarm.useQ and spells[_Q]:IsReady()
        local useW = menu.jfarm.useW and spells[_W]:IsReady()
        local useE = menu.jfarm.useE and spells[_E]:IsReady()


        if useQ and (not useW and not useE or self:IsAblazed(minion)) then
            spells[_Q]:Cast(minion)
        end
        if useW then
            local castPosition = GetBestCircularFarmPosition(spells[_W].range, spells[_W].width, self.jungleMinions.objects)
            spells[_W]:Cast(castPosition.x, castPosition.z)
        end
        if useE and (not useW or self:IsAblazed(minion)) then
            spells[_E]:Cast(minion)
        end
    end

end

function Brand:ApplyMenu()

    menu.combo:addParam("sep",    "",           SCRIPT_PARAM_INFO, "")
    menu.combo:addParam("useQ",   "Use Q",      SCRIPT_PARAM_ONOFF, true)
    menu.combo:addParam("useW",   "Use W",      SCRIPT_PARAM_ONOFF, true)
    menu.combo:addParam("useE",   "Use E",      SCRIPT_PARAM_ONOFF, true)
    menu.combo:addParam("useR",   "Use R",      SCRIPT_PARAM_ONOFF, true)
    menu.combo:addParam("sep",    "",           SCRIPT_PARAM_INFO, "")
    menu.combo:addParam("ignite", "Use ignite", SCRIPT_PARAM_ONOFF, true)

    menu.harass:addParam("sep",  "",                         SCRIPT_PARAM_INFO, "")
    menu.harass:addParam("useQ", "Use Q",                    SCRIPT_PARAM_ONOFF, true)
    menu.harass:addParam("useW", "Use W",                    SCRIPT_PARAM_ONOFF, true)
    menu.harass:addParam("useE", "Use E",                    SCRIPT_PARAM_ONOFF, true)
    menu.harass:addParam("sep",  "",                         SCRIPT_PARAM_INFO, "")
    menu.harass:addParam("mana", "Don't harass if mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)

    menu:addSubMenu("Farm", "farm")
        menu.farm:addParam("freeze", "Farm Freezing",          SCRIPT_PARAM_ONKEYDOWN, false, string.byte("C"))
        menu.farm:addParam("lane",   "Farm Lane-Clear",        SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
        menu.farm:addParam("sep",    "",                       SCRIPT_PARAM_INFO, "")
        menu.farm:addParam("useQ",   "Use Q",                  SCRIPT_PARAM_LIST, 1, { "No", "Freeze", "LaneClear", "Both" }) 
        menu.farm:addParam("useW",   "Use W",                  SCRIPT_PARAM_LIST, 3, { "No", "Freeze", "LaneClear", "Both" })
        menu.farm:addParam("useE",   "Use E",                  SCRIPT_PARAM_LIST, 4, { "No", "Freeze", "LaneClear", "Both" })
        menu.farm:addParam("sep",    "",                       SCRIPT_PARAM_INFO, "")
        menu.farm:addParam("mana",   "Don't farm if mana < %", SCRIPT_PARAM_SLICE, 0, 0, 100)

    menu:addSubMenu("JungleFarm", "jfarm")
        menu.jfarm:addParam("active", "Farm!", SCRIPT_PARAM_ONKEYDOWN, false, string.byte("V"))
        menu.jfarm:addParam("sep",    "",      SCRIPT_PARAM_INFO, "")
        menu.jfarm:addParam("useQ",   "Use Q", SCRIPT_PARAM_ONOFF, false)
        menu.jfarm:addParam("useW",   "Use W", SCRIPT_PARAM_ONOFF, true)
        menu.jfarm:addParam("useE",   "Use E", SCRIPT_PARAM_ONOFF, true)

    menu:addSubMenu("Ultimate", "ult")
        menu.ult:addSubMenu("Don't use R on", "targets")
        for _, enemy in ipairs(GetEnemyHeroes()) do
            menu.ult.targets:addParam(enemy.charName, enemy.charName, SCRIPT_PARAM_ONOFF, false)
        end
        menu.ult:addParam("ablazed", "Only R if target ablazed/killable", SCRIPT_PARAM_ONOFF, true)
        menu.ult:addParam("autoR",   "Auto R if it will hit: ",           SCRIPT_PARAM_LIST, 1, { "No", ">0 targets", ">1 targets", ">2 targets", ">3 targets", ">4 targets" })
        menu.ult:addParam("castR",   "Force ultimate cast",               SCRIPT_PARAM_ONKEYDOWN, false, string.byte("J"))

    menu:addSubMenu("Misc", "misc")
        menu.misc:addParam("ablazed",    "Respect ablazed for comboing",  SCRIPT_PARAM_ONOFF, true)
        menu.misc:addParam("autoGapQ",   "Auto EQ on gapclosing targets", SCRIPT_PARAM_ONOFF, true)
        menu.misc:addParam("autoStunQ",  "Auto EQ on stunned targets",    SCRIPT_PARAM_ONOFF, true)
        menu.misc:addParam("autoStunW",  "Auto W on stunned targets",     SCRIPT_PARAM_ONOFF, true)

    menu:addSubMenu("Drawing", "drawing")
    AAcircle:AddToMenu(menu.drawing, "AA Range", false, true, true)
    for spell, circle in pairs(circles) do
        circle:AddToMenu(menu.drawing, SpellToString(spell).." range", true, true, true)
    end
    DLib:AddToMenu(menu.drawing, self.mainCombo)

end