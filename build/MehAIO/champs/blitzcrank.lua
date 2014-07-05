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

function Blitzcrank:GetSkins()
    return {
        "Classic",
        "Rusty",
        "Goalkeeper",
        "Boom Boom",
        "Piltover Customs",
        "Definitely Not Blitzcrank",
        "iBlitzcrank",
        "Riot"
    }
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
    if p.header == 0xB5 then
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
    elseif p.header == 0x26 then
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