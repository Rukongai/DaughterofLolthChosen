---@diagnostic disable: undefined-global

-- Ext.Require("Helpers/EdenDebug.lua")

PersistentVars = {}
PersistentVars['dolcpdebug'] = 0
PersistentVars['dllogging'] = 0
Minthy = "S_GOB_DrowCommander_25721313-0c15-4935-8176-9f134385451b"
_P("Mod Loaded: Daughter of Lolth - Chosen Path - v2.0.7")

Ext.Osiris.RegisterListener("SavegameLoaded", 0, "after", function ()
    if (Ext.Mod.IsModLoaded("5c9122aa-8140-4b2d-8300-94405a0e0776")) then
        _P("Detected Daughter of Lolth - Minthara Ring mod installed. Please remove this mod before continuing")
        MessageBox("You currently have 'Daughter of Lolth - Minthara' installed. These two mods are incompatible and may not be run together. This mod will be disabled. Please remove one or the other.")
        return
    end
    ModInit()
end)

Ext.Events.ResetCompleted:Subscribe(function()
    if PersistentVars['dolcpdebug'] == 1 or PersistentVars['dllogging'] ==  1 then
        ModInit()
    end
end)

--@Check for pvars and do bug checks
function ModInit()
    if PersistentVars['Act2Started'] == nil then
        local act2 = Osi.DB_GlobalFlag:Get("VISITEDREGION_SCL_Main_A_f6e72539-9bc6-42e1-a20f-390f3a17ad8d")
        if next(act2) then
            PersistentVars['Act2Started'] = 1
            Doldb("Act 2 set on Load")
        end
    end
    if PersistentVars['DenVictoryFlag'] == nil then
        PersistentVars['DenVictoryFlag'] = Osi.GetFlag("DEN_AttackOnDen_State_DenVictory_71c7f23e-3ff1-c9b8-3ef5-d75fa1b42c8d", GetHostCharacter())
        Doldb("DenVictoryFlag set on load to " .. PersistentVars['DenVictoryFlag'])
    end
    if PersistentVars['MinRecruited'] ~= 1 then
        if Osi.DB_PartOfTheTeam:Get(Minthy) == Minthy then
            PersistentVars['MinRecruited'] = 1
            Doldb("Minthara set team on load")
        else
            PersistentVars['MinRecruited'] = 0
            Doldb("Minthara set offteam on load")
        end
    end
    if PersistentVars['dolcpdebug'] == 1 then
        GodMode()
    end
    if PersistentVars['dllogging'] == 1 then
        Flagdump()
    end
    BugChecks()
end

function MessageBox(message)
    Osi.OpenMessageBox(Osi.GetHostCharacter(), message)
end

function Flagdump()
    local minthyppd = Osi.DB_PreventPermaDefeated:Get(Minthy)
    local minthypermadead = Osi.DB_PermaDefeated:Get(Minthy)
    local minthydead = Osi.DB_Dead:Get(Minthy)
    Doldb("====Persistent Variables====")
    Doldb("Persistent DenVictoryFlag set to " .. tostring(PersistentVars['DenVictoryFlag']))
    Doldb("Actual DenVictory Flag: " .. tostring(Osi.GetFlag("DEN_AttackOnDen_State_DenVictory_71c7f23e-3ff1-c9b8-3ef5-d75fa1b42c8d", GetHostCharacter())))
    Doldb("Ketheric Left Audience: " .. tostring(PersistentVars['kethericdone']))
    Doldb("Minthara Recruited: " .. tostring(PersistentVars['MinRecruited']))
    Doldb("Act 2: " .. tostring(PersistentVars['Act2Started']))
    Doldb("=============================")
    if next(minthypermadead) then Doldb("Minthara in PermaDefeated DB") end
    if not next(minthypermadead) then Doldb("Minthara not in PermaDefeated DB") end
    if next(minthyppd) then Doldb("Minthara in Prevent PermaDefeat DB") end
    if not next(minthyppd) then Doldb("Minthara not in Prevent PermaDefeat DB") end
    if next(minthydead) then Doldb("Minthara in Dead DB") end
    if not next(minthydead) then Doldb("Minthara not in Dead DB") end
end

function DoLPatchCheck()
    if Osi.QRY_BG3_SaveGameIsOlderThan("Release Patch 1") then
        Doldb("Save File older than Patch 1")
       return true
    else return false
    end
end

function BugChecks()
    local deadgobs = Osi.DB_GlobalFlag:Get("GOB_State_LeadersAreDead_a1c5b01f-4b7f-47ab-82b0-d24d9c6d8bc6")
    if Osi.CanFight(Minthy) == 0 then Osi.SetCanFight(Minthy, 1); Doldb("Fixing Minthara Can Fight") end
    if Osi.CanJoinCombat(Minthy) == 0 then Osi.SetCanJoinCombat(Minthy, 1) ; Doldb("Fixing Minthara Can Join Combat") end
    if Osi.IsInteractionDisabled(Minthy) == 1 then Osi.SetCanInteract(Minthy, 1); Doldb("Fixing Interaction Disabled") end
    if PersistentVars['MinRecruited'] == 1 then; Doldb("Minthara recruited") return end
    if PersistentVars['MinthyRan'] == 1 and not next(deadgobs) then AlreadyDead(); Doldb("Fixing stuck Minthara quest state") end
    if next(Osi.DB_PermaDefeated:Get(Minthy)) and next(deadgobs) and PersistentVars['Act2Started'] ~= 1 then AlreadyDead(); Doldb("Minthara already dead in Act 1, doin magic") end
    if PersistentVars['dolcpdebug'] ~= 1 then; FixPixieBuff(); end
    if PersistentVars['Act2Started'] then YouSawNothing() end
    StuckQuest()
end

function StuckQuest()
    local leaders = {
        "S_GOB_DrowCommander_25721313-0c15-4935-8176-9f134385451b",
        "S_GOB_GoblinKing_11337af0-6a57-426b-a820-c4b00923dd54",
        "S_GOB_GoblinPriest_b983c336-9a14-4e9b-adb9-4689e7e0afa9",
    }
    if not next(Osi.DB_GlobalFlag:Get("GLO_GoblinHunt_Quest_CampEntered_58d47a99-0e37-4fe8-a5ff-d47f069a3886")) then
        Doldb("Goblin Hunt hasn't begun")
        return
    end
    if next(Osi.DB_GlobalFlag:Get("GOB_State_LeadersAreDead_a1c5b01f-4b7f-47ab-82b0-d24d9c6d8bc6")) then
        Doldb("Goblin Leaders are dead")
        return
    end
    if next(Osi.DB_GlobalFlag:Get("GOB_DrowCommander_Event_RaidersLeftForAttack_ce12e8de-2922-4a2b-843b-0494833b8480")) then
        Doldb("Minthara left for raid")
        return
    end
    for _, j in ipairs(leaders) do
        local region = Osi.DB_InRegion:Get(j, nil)
        local counters = Osi.DB_GLO_DefeatCounter_State:Get(j, "GOB_GoblinHunt_Leaders", "Active")
        if next(counters) and not next(region) then
            if j == Minthy then
                Purgatory()
                return
            end
            -- Osi.die(j)
        end
    end
end

function GodMode()
    Osi.DB_GlobalFlag("GLO_Pixie_State_ShieldActive_1225b030-2183-4033-8bcd-819be1bb9e61")
end

--@Debug I'm an idiot
function FixPixieBuff()
    local pixiecheck = Osi.DB_GlobalFlag:Get("SCL_Drider_State_StopPixieCallingForHelp_86f63aa8-84bc-45b7-a7e2-0501a359c14b")
    if not next(pixiecheck) then
        Osi.DB_GlobalFlag:Delete("GLO_Pixie_State_ShieldActive_1225b030-2183-4033-8bcd-819be1bb9e61")
        local squadies = Osi.DB_PartOfTheTeam:Get(nil)
        for _, k in pairs(squadies) do
            if Osi.HasActiveStatus(table.unpack(k), "GLO_PIXIESHIELD") then
                Osi.RemoveStatus(table.unpack(k), "GLO_PIXIESHIELD"); Doldb(string.format("Fixing pixie bug on %s", table.unpack(k)))
            end
        end
    end
end

--@Debug enabled printer
function Doldb(msg)
    if PersistentVars['dllogging'] == 1 then
        _P(msg)
    end
end

--@Crime Fix 
function YouSawNothing()
    Osi.DB_WitnessKiller_SawAsShape:Delete(Minthy, GetHostCharacter(), nil, nil, nil, nil)
    Osi.DB_Crime_GuardKiller_Witness:Delete(Minthy, GetHostCharacter(), nil, nil, nil, nil)
    Osi.DB_CRIME_GuardKiller_WitnessStatus:Delete(Minthy)
end

--@Game loaded with Minthara dead & pvar for her escape
function AlreadyDead()
    Doldb("Minthara Dead")
    Osi.PROC_Poof(Minthy)
    Purgatory()
    PersistentVars['MinthyRan'] = 1
end

--@Minthara escaping function
function MintharaEscape()
    Doldb("Minthara Escaped")
    Osi.TemplateDropFromCharacter("98282bec-aeaa-4490-ae43-0c27bed58c74", Minthy, 1)
    Osi.PROC_Poof(Minthy)
    Purgatory()
    PersistentVars['MinthyRan'] = 1
end

--@Kill Minthara and set to PermaDefeated for quest progression until act 2
function Purgatory()
    Doldb("Minthara Purgatory")
    Osi.Die(Minthy)
    Osi.DB_Dead(Minthy)
    Osi.DB_PermaDefeated(Minthy)
    Osi.PROC_StateSet_Defeated(Minthy)
    Osi.DB_PermaDefeated(Minthy)
end

--@Fully restore Minthara to health
function RestoreMinthara()
    Doldb("Restoring Minthara")
    YouSawNothing()
    Osi.DB_Dead:Delete(Minthy)
    Osi.DB_PermaDefeated:Delete(Minthy)
    Osi.DB_PreventPermaDefeated(Minthy)
    Osi.RemoveStatus(Minthy, "KNOCKED_OUT")
    Osi.RemoveHarmfulStatuses(Minthy)
    Osi.SetHitpointsPercentage(Minthy, 100)
    Osi.PROC_CharacterFullRestore(Minthy)
    if (Ext.Mod.IsModLoaded("62333410-e6f3-4c38-aa6a-cb03e126421e")) == true then
        EquipDrowPriestess()
    end
end

--@Equip Minthara Drow Priestess set
function EquipDrowPriestess()
    Doldb("Equipping Priestess Armor")
    local x, y, z = Osi.GetPosition(Minthy)
    Osi.Equip(Minthy, Osi.CreateAt("ARM_Underwear_DP_1e574070-a448-4c33-b85a-b9b05574aa36", x, y, z, 1, 0, ""))
    Osi.Equip(Minthy, Osi.CreateAt("ARM_Body_Camp_DP_2ed0e8ef-a002-4b36-afee-9ce730948a20", x, y, z, 1, 0, ""))
    Osi.SetArmourSet(Minthy, 1)
end

--@Minthara Health Tracker
Ext.Osiris.RegisterListener("HitpointsChanged", 2, "after", function(guid, hppct)
    if PersistentVars['Act2Started'] ~= 1 then
        if guid == Minthy and PersistentVars['MinthyRan'] ~= 1 and PersistentVars['MinRecruited'] ~=1 then
            Doldb(string.format("target %s hp changed to %s.", guid, hppct))
            if hppct < 30 then
                MintharaEscape()
            end
        end
    end
end)

--@Restore DenVictoryFlag to Original State when Ketheric is finished during Execution scene
Ext.Osiris.RegisterListener("DialogEnded", 2, "after", function (dialog, int)
    if PersistentVars['kethericdone'] ~= 1 then
        if dialog == "MOO_Execution_2b2f9929-86da-50b1-c796-7d3e485ed901" then
            PersistentVars['kethericdone'] = 1
            Doldb("Ketheric Done")
            if PersistentVars['DenVictoryFlag'] == 1 then
                Osi.SetFlag("DEN_AttackOnDen_State_DenVictory_71c7f23e-3ff1-c9b8-3ef5-d75fa1b42c8d", GetHostCharacter())
                Doldb("Restoring Flag to 1 via Ketheric Function")
                return
            else
                Osi.ClearFlag("DEN_AttackOnDen_State_DenVictory_71c7f23e-3ff1-c9b8-3ef5-d75fa1b42c8d", GetHostCharacter())
                ("Restoring Flag to 0 via Ketheric Function")
            end
        end
    end
end)

--@SubRegion change tracking while Execution Scene has not been completed for managing flag toggling
Ext.Osiris.RegisterListener("PROC_Subregion_Entered", 2, "before", function (a, b)
    if PersistentVars['Act2Started'] == 1 and PersistentVars['kethericdone'] ~= 1 then
        if b ~= "S_MOO_MainFloorInterior_SUB_429a55cc-58d2-4469-9577-852131e1fff3" and PersistentVars['DenVictoryFlag'] == 1 then
            Osi.SetFlag("DEN_AttackOnDen_State_DenVictory_71c7f23e-3ff1-c9b8-3ef5-d75fa1b42c8d", GetHostCharacter())
            Doldb("Setting DenVictory: Moonrise Entrance")
            return end
        if b == "S_MOO_MainFloorInterior_SUB_429a55cc-58d2-4469-9577-852131e1fff3" then
            Osi.ClearFlag("DEN_AttackOnDen_State_DenVictory_71c7f23e-3ff1-c9b8-3ef5-d75fa1b42c8d", GetHostCharacter())
                Doldb("Clearing DenVictory: Moonrise Entrance")
        end
    end
end)

--@Recruitment checker for Minthara
Ext.Osiris.RegisterListener("PROC_DisappearOutOfSight", 4, "after", function (char, speed, int, dest)
    if PersistentVars['MinRecruited'] ~=1 then
        if char == Minthy and dest == "MOO_MintharaFate_ToCamp" then
            Doldb("Minthara Recruited")
            PersistentVars['MinRecruited'] = 1
        end
    end
end)

--@Start Act2 Check 
Ext.Osiris.RegisterListener("PROC_RegionSwapReadyCheckPassed", 2, "before", function (character, prompt)
    local checkpoints = {"ReadyCheck_ToSCL02FromCRE", "ReadyCheck_ToSCLFromUnderdark"}
    for _, i in ipairs(checkpoints) do
        if i == prompt then
            Doldb("Checkpoint Match")
            PersistentVars['Act2Started'] = 1
            if PersistentVars['DenVictoryFlag'] == nil then
                Doldb("DenVictoryFlag not set. Setting now.")
                PersistentVars['DenVictoryFlag'] = Osi.GetFlag("DEN_AttackOnDen_State_DenVictory_71c7f23e-3ff1-c9b8-3ef5-d75fa1b42c8d", GetHostCharacter())
            end
            RestoreMinthara()
            Doldb(string.format("PROC_RegionSwapReadyCheckPassed: %s %s", a, b))
        end
    end
end)

--@Check for Halsin Bugfix application
Ext.Osiris.RegisterListener("DB_BUGFIX_Marker", 1, "after", function (bugfix)
    if bugfix == "GUS-303341" then
        Doldb("Halsin Bugfix Applied. Halsin was taken by Jergel")
    end
end)

--@Print on DenVictoryFlag Set 
Ext.Osiris.RegisterListener("SetFlag", 2, "after", function (flag, player)
    -- Doldb(string.format("flag %s set on target %s.", flag, player))
    if flag == "DEN_AttackOnDen_State_DenVictory_71c7f23e-3ff1-c9b8-3ef5-d75fa1b42c8d" then
        Doldb("DenVictoryFlag Set")
    end
end)

--@Print on DenVictoryFlag Clear 
Ext.Osiris.RegisterListener("ClearFlag", 2, "after", function (flag, player)
    if flag == "DEN_AttackOnDen_State_DenVictory_71c7f23e-3ff1-c9b8-3ef5-d75fa1b42c8d" then
        Doldb("DenVictory Flag Cleared")
    end
end)

--@Block Halsin Death
DoLPatchesApplied = nil
Ext.Osiris.RegisterListener("PROC_ApplySavegamePatches", 0, "before", function ()
    local partoftheteam = Osi.DB_PartOfTheTeam:Get(Minthy)
    if next(partoftheteam) and DoLPatchCheck() then
        Osi.DB_PartOfTheTeam:Delete(Minthy)
        _P("Applying Halsin Block")
        DoLPatchesApplied = 1
    end
end)

Ext.Osiris.RegisterListener("PROC_ApplySavegamePatches", 0, "after", function ()
    if DolPatchesApplied == 1 and DoLPatchCheck() then
        Osi.DB_PartOfTheTeam(Minthy)
    end
end)