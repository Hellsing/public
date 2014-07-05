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

function Xerath:GetSkins()
    return {
        "Classic",
        "Runeborn",
        "Battlecast",
        "Scorched Earth"
    }
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