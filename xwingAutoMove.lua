-- X-Wing Automatic Movement - Hera Verito (Jstek), March 2016
-- X-Wing Arch and Range Ruler - Flolania, March 2016
-- X-Wing Auto Dial Integration - Flolania, March 2016
-- X-Wing AI Auto movement - Valadian, April 2016

--Auto Movement
undolist = {}
undopos = {}
undorot = {}
namelist1 = {}
locktimer = {}

--Auto Dials
--dial information
dialpositions = {}

-- Auto Actions
focus = 'beca0f'
evade = '4a352e'
stress = 'a25e12'

-- AI
aitype = {}
striketarget = nil
aicardguid = '2d84be'
squadleader = {}
squadmove = {}
squadposition = {}
squadrotation = {}
aimove = {}
aiswerved = {}
aitargets = {}
aistressed = {}
aidecloaked = {}
-- Auto Setup
missionzone = '6fef74'
mission_ps = nil
mission_players = nil
players_up_next = {}
players_up_next_delay = 0
ai_stress = false
ai_stress_delay = 0
current = nil
currentphase = nil
turn_marker = nil
end_marker = nil

function onload()
    local aicard = getObjectFromGUID(aicardguid)
    if aicard then
        local prebutton = {['click_function'] = 'Action_PreMovePhase', ['label'] = 'Start Turn', ['position'] = {0, 0.3, -1.5}, ['rotation'] =  {0, 0, 0}, ['width'] = 1200, ['height'] = 400, ['font_size'] = 250}
        aicard.createButton(prebutton)

        local flipbutton = {['click_function'] = 'Action_MovePhase', ['label'] = 'Activation', ['position'] = {0, 0.3, -0.5}, ['rotation'] =  {0, 0, 0}, ['width'] = 1200, ['height'] = 400, ['font_size'] = 250}
        aicard.createButton(flipbutton)

        local attackbutton = {['click_function'] = 'Action_AttackPhase', ['label'] = 'Combat', ['position'] = {0, 0.3, 0.5}, ['rotation'] =  {0, 0, 0}, ['width'] = 1200, ['height'] = 400, ['font_size'] = 250}
        aicard.createButton(attackbutton)

        local clearbutton = {['click_function'] = 'Action_EndPhase', ['label'] = 'End', ['position'] = {0, 0.3, 1.5}, ['rotation'] =  {0, 0, 0}, ['width'] = 1200, ['height'] = 400, ['font_size'] = 250}
        aicard.createButton(clearbutton)
    end
    turn_marker = findObjectByName("Turn Marker")
    end_marker = findObjectByName("End Marker")
end
function findObjectByName(name)
    for i,obj in ipairs(getAllObjects()) do
        if obj.getName()==name then return obj end
    end
end
function PlayerCheck(Color, GUID)
    return true
--    local PC = false
--    if getPlayer(Color) ~= nil then
--        HandPos = getPlayer(Color).getPointerPosition()
--        DialPos = getObjectFromGUID(GUID).getPosition()
--        if distance(HandPos['x'],HandPos['z'],DialPos['x'],DialPos['z']) < 2 then
--            PC = true
--        end
--    end
--    return PC
end
function onObjectLeaveScriptingZone(zone, object)
    if zone.getGUID() == missionzone and object.tag == 'Card' and object.getName():match '^Mission: (.*)' then
        object.clearButtons()
    end
    if object.tag == 'Card' and object.getDescription() ~= '' then
        local CardData = dialpositions[CardInArray(object.GetGUID())]
        if CardData ~= nil then
            local obj = getObjectFromGUID(CardData["ShipGUID"])
            if obj.getVar('HasDial') == true then
                printToColor(CardData["ShipName"] .. ' already has a dial.', object.held_by_color, {0, 0, 1})
            else
                obj.setVar('HasDial', true)
                CardData["Color"] = object.held_by_color

                local flipbutton = {['click_function'] = 'CardFlipButton', ['label'] = 'Flip', ['position'] = {0, -1, 1}, ['rotation'] =  {0, 0, 180}, ['width'] = 750, ['height'] = 550, ['font_size'] = 250}
                object.createButton(flipbutton)
                local deletebutton = {['click_function'] = 'CardDeleteButton', ['label'] = 'Delete', ['position'] = {0, -1, -1}, ['rotation'] =  {0, 0, 180}, ['width'] = 750, ['height'] = 550, ['font_size'] = 250}
                object.createButton(deletebutton)

                object.setVar('Lock',true)
            end
        else
            printToColor('That dial was not saved.', object.held_by_color, {0, 0, 1})
        end
    end
end

function CardInArray(GUID)
    local CIAPos
    for i, card in ipairs(dialpositions) do
        if GUID == card["GUID"] then
            CIAPos = i
        end
    end
    return CIAPos
end

function CardFlipButton(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        local rot = getObjectFromGUID(CardData["ShipGUID"]).getRotation()
        object.setRotation({0,rot[2],0})
        object.clearButtons()
        local movebutton = {['click_function'] = 'CardMoveButton', ['label'] = 'Move', ['position'] = {0, 1, '.9'}, ['rotation'] =  {0, 0, 0}, ['width'] = 750, ['height'] = 550, ['font_size'] = 250}
        object.createButton(movebutton)
    end
end


function CardMoveButton(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        check(CardData["ShipGUID"],object.getDescription())
        object.clearButtons()

        local deletebutton = {['click_function'] = 'CardDeleteButton', ['label'] = 'Delete', ['position'] = {'-.35', 1, 1}, ['rotation'] =  {0, 0, 0}, ['width'] = 750, ['height'] = 650, ['font_size'] = 250}
        object.createButton(deletebutton)

        local undobutton = {['click_function'] = 'CardUndoButton', ['label'] = 'q', ['position'] = {'-.9', 1, -1}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
        object.createButton(undobutton)

        local focusbutton = {['click_function'] = 'CardFocusButton', ['label'] = 'F', ['position'] = {'.9', 1, -1}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
        object.createButton(focusbutton)

        local stressbutton = {['click_function'] = 'CardStressButton', ['label'] = 'S', ['position'] = {'.9', 1, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
        object.createButton(stressbutton)

        local evadebutton = {['click_function'] = 'CardEvadeButton', ['label'] = 'E', ['position'] = {'.9', 1, 1}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
        object.createButton(evadebutton)

    end
end

function CardFocusButton(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        take(focus, CardData["ShipGUID"],-0.3,1,-0.3)
        notify(CardData["ShipGUID"],'action','takes a focus token')
    end
end

function CardStressButton(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        take(stress, CardData["ShipGUID"],0.3,1,0.3)
        notify(CardData["ShipGUID"],'action','takes stress')
    end
end

function CardEvadeButton(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        take(evade, CardData["ShipGUID"],-0.5,1,0.5)
        notify(CardData["ShipGUID"],'action','takes an evade token')
    end
end

function CardUndoButton(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        check(CardData["ShipGUID"],'undo')
        object.removeButton(1)
    end
end

function CardDeleteButton(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        getObjectFromGUID(CardData["ShipGUID"]).setVar('HasDial',false)
        object.Unlock()
        object.clearButtons()
        object.setPosition (CardData["Position"])
        object.setRotation (CardData["Rotation"])
        CardData["Color"] = nil
    end
end

function resetdials(guid,notice)
    local obj = getObjectFromGUID(guid)
    local index = {}
    for i, card in ipairs(dialpositions) do
        if guid == card["ShipGUID"] then
            index[#index + 1] = i
        end
    end
    obj.setVar('HasDial',false)
    if notice == 1 then
        printToAll(#index .. ' dials removed for ' .. obj.getName() .. '.', {0, 0, 1})
    end
    for i=#index,1,-1 do
        table.remove(dialpositions, index[i])
    end
    setpending(guid)
end

function checkdials(guid)
    resetdials(guid,0)
    local obj = getObjectFromGUID(guid)
    local count = 0
    local display = false
    local error = false
    local deckerror = false
    for i,card in ipairs(getAllObjects()) do
        local cardpos = card.getPosition()
        local objpos = obj.getPosition()
        if distance(cardpos[1],cardpos[3],objpos[1],objpos[3]) < 5.5 then
            if cardpos[3] >= 18 or cardpos[3] <= -18 then
                if card.tag == 'Card' and card.getDescription() ~= '' then
                    local CardData = dialpositions[CardInArray(card.getGUID())]
                    if CardData == nil then
                        count = count + 1
                        local cardtable = {}
                        cardtable["GUID"] = card.getGUID()
                        cardtable["Position"] = card.getPosition()
                        cardtable["Rotation"] = card.getRotation()
                        cardtable["ShipGUID"] = obj.getGUID()
                        cardtable["ShipName"] = obj.getName()
                        cardtable["Color"] = nil
                        obj.setVar('HasDial',false)
                        dialpositions[#dialpositions +1] = cardtable
                        card.setName(obj.getName())
                    else
                        display = true
                    end
                end
                if card.tag == 'Deck' then
                    deckerror = true
                end
            else
                error = true
            end
        end
    end
    if display == true then
        printToAll('Error: ' .. obj.getName() .. ' attempted to save dials already saved to another ship. Use rd on old ship first.',{0, 0, 1})
    end
    if deckerror == true then
        printToAll('Error: Cannot save dials in deck format.',{0, 0, 1})
    end
    if error == true then
        printToAll('Caution: Cannot save dials in main play area.',{0, 0, 1})
    end
    if count <= 17 then
        printToAll(count .. ' dials saved for ' .. obj.getName() .. '.', {0, 0, 1})
    else
        resetdials(guid,0)
        printToAll('Error: Tried to save to many dials for ' .. obj.getName() .. '.', {0, 0, 1})
    end
    setpending(guid)
end

function distance(x,y,a,b)
    x = (x-a)*(x-a)
    y = (y-b)*(y-b)
    return math.sqrt(math.abs((x+y)))
end

function SpawnDialGuide(guid)
    local shipobject = getObjectFromGUID(guid)
    local world = shipobject.getPosition()
    local direction = shipobject.getRotation()
    local obj_parameters = {}
    obj_parameters.type = 'Custom_Model'
    obj_parameters.position = {world[1], world[2]+0.15, world[3]}
    obj_parameters.rotation = { 0, direction[2], 0 }
    local DialGuide = spawnObject(obj_parameters)
    local custom = {}
    custom.mesh = 'http://pastebin.com/raw/qPcTJZyP'
    custom.collider = 'http://pastebin.com/raw.php?i=UK3Urmw1'

    DialGuide.setCustomObject(custom)
    DialGuide.lock()
    DialGuide.scale({'.4','.4','.4'})

    local button = {['click_function'] = 'GuideButton', ['label'] = 'Remove', ['position'] = {0, 0.5, 0}, ['rotation'] =  {0, 270, 0}, ['width'] = 1500, ['height'] = 1500, ['font_size'] = 500}
    DialGuide.createButton(button)
    shipobject.setDescription('Pending')
    checkdials(guid)
end

function GuideButton(object)
    object.destruct()
end

function update ()
    for i,ship in ipairs(getAllObjects()) do
        if ship.tag == 'Figurine' and ship.name ~= '' then
            local shipguid = ship.getGUID()
            local shipdesc = ship.getDescription()
            local shipname = ship.getName()
            checkname(shipguid,shipdesc,shipname)
            check(shipguid,shipdesc)
        elseif ship.getName():match "Turbolaser.*" and (ship.getDescription()=="r" or ship.getDescription()=="ruler") then
            ruler(ship.getGUID())
        end
        if ship.getVar('Lock') == true and ship.held_by_color == nil and ship.resting == true then
            ship.setVar('Lock',false)
            ship.lock()
        end
    end
end

function round(x)
    return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
end

function round(num, idp)
    if num == nil then return nil end
    local mult = 10^(idp or 0)
    if num >= 0 then return math.floor(num * mult + 0.5) / mult
    else return math.ceil(num * mult - 0.5) / mult end
end

function take(parent, guid, xoff, yoff, zoff)
    local obj = getObjectFromGUID(guid)
    local objp = getObjectFromGUID(parent)
    local world = obj.getPosition()
    local offset = RotateVector({xoff, yoff, zoff}, obj.getRotation()[2])
    local params = {}
    params.position = {world[1]+offset[1], world[2]+offset[2], world[3]+offset[3]}
    objp.takeObject(params)
end

function undo(guid)
    local obj
    if undolist[guid] ~= nil then
        obj = getObjectFromGUID(guid)
        obj.setPosition(undopos[guid])
        obj.setRotation(undorot[guid])
        setpending(guid)
    else
        obj = getObjectFromGUID(guid)
        setpending(guid)
    end
    obj.Unlock()
end

function storeundo(guid)
    local obj = getObjectFromGUID(guid)
    local direction = obj.getRotation()
    local world = obj.getPosition()
    undolist[guid] = guid
    undopos[guid] = world
    undorot[guid] = direction
end

function registername(guid)
    local obj = getObjectFromGUID(guid)
    local name = obj.getName()
    namelist1[guid] = name
    setlock(guid)
end

function checkname(guid,move,name)
    if move == 'Pending' then
        if namelist1[guid] == nil then
            namelist1[guid] = name
        end
    end
end

function fixname(guid)
    if namelist1[guid] ~= nil then
        local obj = getObjectFromGUID(guid)
        obj.setName(namelist1[guid])
    end
end

function setpending(guid)
    fixname(guid)
    local obj = getObjectFromGUID(guid)
    obj.setDescription('Pending')
end

function setlock(guid)
    fixname(guid)
    local obj = getObjectFromGUID(guid)
    obj.setDescription('Locking')
end


function notify(guid,move,text)
    if text == nil then
        text = ''
    end

    local obj = getObjectFromGUID(guid)
    local name = obj.getName()
    local name = string.gsub(name,":","|")
    if move == 'q' then
        printToAll(name .. ' executed undo.', {0, 1, 0})
    elseif move == 'set' then
        printToAll(name .. ' set name.', {0, 1, 1})
    elseif move == 'r' then
        printToAll(name .. ' spawned a ruler.', {0, 0, 1})
    elseif move == 'action' then
        printToAll(name .. ' ' .. text .. '.', {0.959999978542328 , 0.439000010490417 , 0.806999981403351})
    elseif move == 'keep' then
        printToAll(name .. ' saved location.', {0, 1, 1})
    else
        local color = {1,1,1}
        if aistressed[guid] then
            color = {1, 0, 0}
        end
        printToAll(name .. ' ' .. text ..' (' .. move .. ').', color)
    end
end


function check(guid,move)
    local ship = getObjectFromGUID(guid)
    local shipname = ship.getName()
    -- Checking for Lock
    if move == 'Locking' then
        if locktimer[guid] ~= nil or locktimer[guid] == 0 then
            if locktimer[guid] > 1 then
                locktimer[guid] = locktimer[guid] - 1
            elseif locktimer[guid] == 0 then
                locktimer[guid] = 100
            else
                locktimer[guid] = 0
                local obj = getObjectFromGUID(guid)
                obj.lock()
                setpending(guid)
            end
        else
            locktimer[guid] = 100
        end
    end

    --Ruler
    if move == 'r' or move == 'ruler' then
        ruler(guid)
    end

    --DialCheck
    if move == 'sd' or move == 'storedial' or move == 'storedials' then
        if move == 'sd' then
            checkdials(guid)
        else
            SpawnDialGuide(guid)
        end
    end
    if move == 'rd' or move == 'removedial' or move == 'removedials' then
        resetdials(guid, 1)
    end

    -- AI Commands
    if move == 'ai' then
        auto(guid)
    end
    if move == 'ai strike' then
        aitype[guid] = 'strike'
        local ship = getObjectFromGUID(guid)
        printToAll('AI Type For: ' .. ship.getName() .. ' set to STRIKE',{0, 1, 0})
        setpending(guid)
    end
    if move == 'ai attack' then
        aitype[guid] = nil
        local ship = getObjectFromGUID(guid)
        printToAll('AI Type For: ' .. ship.getName() .. ' set to ATTACK',{0, 1, 0})
        setpending(guid)
    end
    if move == 'ai striketarget' then
        striketarget = guid
        local ship = getObjectFromGUID(guid)
        printToAll('Strike Target Set: ' .. ship.getName(),{0, 0, 1})
        setpending(guid)
    end
    if move:match "ai target (.*)"~=nil then
        local target = move:match "ai target (.*)"
        if target == "clear" then
            aitargets[guid] = nil
            printToAll('Cleared target for AI',{0, 1, 0})
        else
            local players = {}
            for i,ship in ipairs(getAllObjects()) do
                local matches = string.match(ship.getName(),target)
                if not isAi(ship) and isShip(ship) and matches then
                    table.insert(players, ship)
                end
            end
            if not empty(players) then
                aitargets[guid] = players[1]
                printToAll('Set target for AI to: ' .. players[1].getName(),{0, 1, 0})
            end
        end
        if currentphase~=nil then
            local currentGuid
            if current~= nil then currentGuid = current.getGUID() end
            UpdateNote(currentphase, currentGuid)
        end
        setpending(guid)
    end
    if move == "ai pos" then
        local ship = getObjectFromGUID(guid)
        printToAll('Position '..ship.getPosition()[1].." "..ship.getPosition()[2].." "..ship.getPosition()[3],{0,1,0})
    end
    if move == "ai next" then
        local ship = getObjectFromGUID(guid)
        GoToNextMove(ship)
        setpending(guid)
    end
    if move == "ai stress true" or move == "ai stress" then
        aistressed[guid] = true
        setpending(guid)
    end
    if move == "ai stress false" or move == "ai stress clear" then
        aistressed[guid] = nil
        setpending(guid)
    end
    -- Straight Commands
    if move == 's0' then
        notify(guid,move,'is stationary')
        setpending(guid)
    end
    if move == 's1' then
        straight(guid,2.9,1.45)
        notify(guid,move,'flew straight 1')
    elseif move == 's2' or move == 'cs' then
        if move == 's2' then
            straight(guid,4.35,1.45)
            notify(guid,move,'flew straight 2')
        else
            if shipname:match '%LGS$' then
            else
                straight(guid,4.35,1.45)
                notify(guid,move,'decloaked straight 2')
            end
        end
    elseif move == 's3' then
        straight(guid,5.79,1.45)
        notify(guid,move,'flew straight 3')
    elseif move == 's4' then
        straight(guid,7.25,1.5)
        notify(guid,move,'flew straight 4')
    elseif move == 's5' then
        straight(guid,8.68,1.45)
        notify(guid,move,'flew straight 5')
        -- Bank Commands
    elseif move == 'br1' then
        right(guid,3.33,1.36,45,1.26,0.5)
        notify(guid,move,'banked right 1')
    elseif move == 'br2' then
        right(guid,4.59,1.89,45,1.26,0.5)
        notify(guid,move,'banked right 2')
    elseif move == 'br3' then
        right(guid,5.91032266616821,2.5119037628174,45,1.26,0.5)
        notify(guid,move,'banked right 3')
    elseif move == 'bl1' or move == 'be1' then
        left(guid,3.33,1.36,-45,1.26,0.5)
        notify(guid,move,'banked left 1')
    elseif move == 'bl2' or move == 'be2' then
        left(guid,4.59,1.89,-45,1.26,0.5)
        notify(guid,move,'banked left 2')
    elseif move == 'bl3' or move == 'be3' then
        left(guid,5.91032266616821,2.5119037628174,-45,1.26,0.5)
        notify(guid,move,'banked left 3')
        -- Turn Commands
    elseif move == 'tr1' then
        right(guid,1.9999457550049,2.00932357788086,90,0.7,0.75)
        notify(guid,move,'turned right 1')
    elseif move == 'tr2' then
        right(guid,2.9963474273682,2.97769641876221,90,0.7,0.75)
        notify(guid,move,'turned right 2')
    elseif move == 'tr3' then
        right(guid,3.9047927856445,4.052940441535946,90,0.7,0.75)
        notify(guid,move,'turned right 3')
    elseif move == 'tl1' or move == 'te1' then
        left(guid,2.0049457550049,2.02932357788086,270,0.7,0.75)
        notify(guid,move,'turned left 1')
    elseif move == 'tl2' or move == 'te2' then
        left(guid,2.9963474273682,2.97769641876221,270,0.7,0.75)
        notify(guid,move,'turned left 2')
    elseif move == 'tl3' or move == 'te3' then
        left(guid,3.9047927856445,4.052940441535946,270,0.7,0.75)
        notify(guid,move,'turned left 3')
        -- Koiogran Turn Commands
    elseif move == 'k2' then
        straightk(guid,4.35,1.45)
        notify(guid,move,'koiogran turned 2')
    elseif move == 'k3' then
        straightk(guid,5.79,1.45)
        notify(guid,move,'koiogran turned 3')
    elseif move == 'k4' then
        straightk(guid,7.25,1.45)
        notify(guid,move,'koiogran turned 4')
    elseif move == 'k5' then
        straightk(guid,8.68,1.45)
        notify(guid,move,'koiogran turned 5')
        -- Segnor's Loop Commands
    elseif move == 'bl2s' or move == 'be2s' then
        left(guid,4.59,1.89,135,1.26,0.5)
        notify(guid,move,'segnors looped left 2')
    elseif move == 'bl3s' or move == 'be3s' then
        left(guid,5.91032266616821,2.5119037628174,135,1.26,0.5)
        notify(guid,move,'segnors looped left 3')
    elseif move == 'br2s' then
        right(guid,4.59,1.89,225,1.26,0.5)
        notify(guid,move,'segnors looped right 2')
    elseif move == 'br3s' then
        right(guid,5.91032266616821,2.5119037628174,225,1.26,0.5)
        notify(guid,move,'segnors looped right 3')
        -- Barrel Roll Commands
    elseif move == 'xl' or move == 'xe' then
        if shipname:match '%LGS$' then
            left(guid,0,0.73999404907227,0,0,2.87479209899903)
        else
            left(guid,0,2.8863945007324,0,0,0)
        end
        notify(guid,move,'barrel rolled left')
    elseif move == 'xlf' or move == 'xef' or move == 'rolllf' or move == 'rollet' then
        if shipname:match '%LGS$' then
            left(guid,2.936365485191352/2,0.73999404907227,0,0,2.87479209899903)
        else
            left(guid,0.73999404907227,2.8863945007324,0,0,0)
        end
        notify(guid,move,'barrel rolled forward left')
    elseif move == 'xlb' or move == 'xeb' or move == 'rolllb'  or move == 'rolleb' then
        if shipname:match '%LGS$' then
            left(guid,-2.936365485191352/2,0.73999404907227,0,0,2.87479209899903)
        else
            left(guid,-0.73999404907227,2.8863945007324,0,0,0)
        end
        notify(guid,move,'barrel rolled backwards left')
    elseif move == 'xr' or move == 'rollr'then
        if shipname:match '%LGS$' then
            right(guid,0,0.73999404907227,0,0,2.87479209899903)
        else
            right(guid,0,2.8863945007324,0,0,0)
        end
        notify(guid,move,'barrel rolled right')
    elseif move == 'xrf' or move == 'rollrf' then
        if shipname:match '%LGS$' then
            right(guid,2.936365485191352/2,0.73999404907227,0,0,2.87479209899903)
        else
            right(guid,0.73999404907227,2.8863945007324,0,0,0)
        end
        notify(guid,move,'barrel rolled forward right')
    elseif move == 'xrb' or move == 'rollrb' then
        if shipname:match '%LGS$' then
            right(guid,-2.936365485191352/2,0.73999404907227,0,0,2.87479209899903)
        else
            right(guid,-0.73999404907227,2.8863945007324,0,0,0)
        end
        notify(guid,move,'barrel rolled backwards right')
        -- Decloak Commands
    elseif move == 'cl' or move == 'ce' then
        if shipname:match '%LGS$' then
        else
            left(guid,0,4.3295917510986,0,0,0)
            notify(guid,move,'decloaked left')
        end
    elseif move == 'clf' or move == 'cef' then
        if shipname:match '%LGS$' then
        else
            left(guid,0.73999404907227,4.3295917510986,0,0,0)
            notify(guid,move,'decloaked forward left')
        end
    elseif move == 'clb' or move == 'ceb' then
        if shipname:match '%LGS$' then
        else
            left(guid,-0.73999404907227,4.3295917510986,0,0,0)
            notify(guid,move,'decloaked backwards left')
        end
    elseif move == 'cr' or move == 'ce' then
        if shipname:match '%LGS$' then
        else
            right(guid,0,4.3295917510986,0,0,0)
            notify(guid,move,'decloaked right')
        end
    elseif move == 'crf' then
        if shipname:match '%LGS$' then
        else
            right(guid,0.73999404907227,4.3295917510986,0,0,0)
            notify(guid,move,'decloaked forward right')
        end
    elseif move == 'crb' then
        if shipname:match '%LGS$' then
        else
            right(guid,-0.73999404907227,4.3295917510986,0,0,0)
            notify(guid,move,'decloak backwards right')
        end
        -- MISC Commands
    elseif move == 'checkpos' then
        checkpos(guid)
    elseif move == 'checkrot' then
        checkrot(guid)
    elseif move == 'keep' then
        storeundo(guid)
        notify(guid,'keep')
        setpending(guid)
    elseif move == 'set' then
        registername(guid)
        notify(guid,move)
    elseif move == 'undo' or move == 'q' then
        undo(guid)
        notify(guid,'q')
    elseif string.starts(move,"q ") then
        local nextmove = string.gsub(move,"q ","")
        undo(guid)
        executeMove(getObjectFromGUID(guid),nextmove)
    end
--    if not empty(players_up_next) then
--        if players_up_next_delay>100 then
--            for i,ship in ipairs(players_up_next) do
--                printToAll("PlayersTurn: ",{0,1,1})
--                prettyPrint(ship)
--            end
--            players_up_next = {}
--            players_up_next_delay = 0
--        else
--            players_up_next_delay = players_up_next_delay + 1
--        end
--    end
--    if ai_stress then
--
--        if ai_stress_delay>100 then
--
--            printToAll('[STRESS - No Action]',{1, 0, 0})
--            ai_stress = false
--            ai_stress_delay = 0
--        else
--            ai_stress_delay = ai_stress_delay + 1
--        end
--    end
end
function string.starts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end

function checkpos(guid)
    setpending(guid)
    local obj = getObjectFromGUID(guid)
    local world = obj.getPosition()
    for i, v in ipairs(world) do
        print(v)
    end
end

function checkrot(guid)
    setpending(guid)
    local obj = getObjectFromGUID(guid)
    local world = obj.getRotation()
    for i, v in ipairs(world) do
        print(v)
    end
end

function ruler(guid)

    local shipobject = getObjectFromGUID(guid)
    local shipname = shipobject.getName()
    local direction = shipobject.getRotation()
    local world = shipobject.getPosition()
    local scale = shipobject.getScale()
    -- Turbolaser models are not scaled correctly. hack it.
    if shipname:match 'Turbolaser.*' then
        local s = 0.6327
        scale = {scale[1] * s,scale[2] * s,scale[3] * s}
        direction[2] = direction[2] - 90
    end

    local obj_parameters = {}
    obj_parameters.type = 'Custom_Model'
    obj_parameters.position = {world[1], world[2]+0.28, world[3]}
    obj_parameters.rotation = { 0, direction[2] +180, 0 }
    local newruler = spawnObject(obj_parameters)
    local custom = {}
    if shipname:match '%LGS$' then
        custom.mesh = 'http://pastebin.com/raw/3AU6BBjZ'
        custom.collider = 'https://paste.ee/r/JavTd'
    else
        custom.mesh = 'http://pastebin.com/raw/wkfqqnwX'
        custom.collider = 'https://paste.ee/r/6jn13'
    end
    newruler.setCustomObject(custom)
    newruler.lock()
    newruler.scale(scale)
    setpending(guid)
    local button = {['click_function'] = 'actionButton', ['label'] = 'Remove', ['position'] = {0, 0.5, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 1500, ['height'] = 1500, ['font_size'] = 500}
    newruler.createButton(button)
    notify(guid,'r')
end

function actionButton(object)
    object.destruct()
end

function straight(guid,forwardDistance,bsfd)
    storeundo(guid)
    local obj = getObjectFromGUID(guid)
    local shipname = obj.getName()
    if shipname:match '%LGS$' then
        forwardDistance = forwardDistance + bsfd
    end
    local direction = obj.getRotation()
    local world = obj.getPosition()
    local rotval = round(direction[2])
    local radrotval = math.rad(rotval)
    local xDistance = math.sin(radrotval) * forwardDistance * -1
    local zDistance = math.cos(radrotval) * forwardDistance * -1
    setlock(guid)
    obj.setPosition( {world[1]+xDistance, world[2]+2, world[3]+zDistance} )
    obj.Rotate({0, 0, 0})


end

function straightk(guid,forwardDistance,bsfd)
    storeundo(guid)
    local obj = getObjectFromGUID(guid)
    local shipname = obj.getName()
    if shipname:match '%LGS$' then
        forwardDistance = forwardDistance + bsfd
    end
    local direction = obj.getRotation()
    local world = obj.getPosition()
    local rotval = round(direction[2])
    local radrotval = math.rad(rotval)
    local xDistance = math.sin(radrotval) * forwardDistance * -1
    local zDistance = math.cos(radrotval) * forwardDistance * -1
    setlock(guid)
    obj.setPosition( {world[1]+xDistance, world[2]+2, world[3]+zDistance} )
    obj.Rotate({0, 180, 0})
end

function right(guid,forwardDistance,sidewaysDistance,rotate,bsfd,bssd)
    storeundo(guid)
    local obj = getObjectFromGUID(guid)
    local shipname = obj.getName()
    if shipname:match '%LGS$' then
        forwardDistance = forwardDistance + bsfd
        sidewaysDistance = sidewaysDistance + bssd
    end
    local direction = obj.getRotation()
    local world = obj.getPosition()
    local rotval = round(direction[2])
    local radrotval = math.rad(rotval)
    local xDistance = math.sin(radrotval) * forwardDistance * -1
    local zDistance = math.cos(radrotval) * forwardDistance * -1
    local radrotval = radrotval + math.rad(90)
    local xDistance = xDistance + (math.sin(radrotval) * sidewaysDistance * -1)
    local zDistance = zDistance + (math.cos(radrotval) * sidewaysDistance * -1)
    setlock(guid)
    obj.setPosition( {world[1]+xDistance, world[2]+2, world[3]+zDistance} )
    obj.Rotate({0, rotate, 0})
end

function left(guid,forwardDistance,sidewaysDistance,rotate,bsfd,bssd)
    storeundo(guid)
    local obj = getObjectFromGUID(guid)
    local shipname = obj.getName()
    if shipname:match '%LGS$' then
        forwardDistance = forwardDistance + bsfd
        sidewaysDistance = sidewaysDistance + bssd
    end
    local direction = obj.getRotation()
    local world = obj.getPosition()
    local rotval = round(direction[2])
    local radrotval = math.rad(rotval)
    local xDistance = math.sin(radrotval) * forwardDistance * -1
    local zDistance = math.cos(radrotval) * forwardDistance * -1
    radrotval = radrotval - math.rad(90)
    xDistance = xDistance + (math.sin(radrotval) * sidewaysDistance * -1)
    zDistance = zDistance + (math.cos(radrotval) * sidewaysDistance * -1)
    setlock(guid)
    obj.setPosition( {world[1]+xDistance, world[2]+2, world[3]+zDistance} )
    obj.Rotate({0, rotate, 0})
end

function auto(guid)
    local ai = getObjectFromGUID(guid)
    --local tgtGuid
    local squad = getAiSquad(ai)
--    if aitype[guid] == 'strike' then
--        tgtGuid = striketarget
--        printToAll(ai.getName() .. " is STRIKE AI",{0,1,0})
--    else
--        tgtGuid = findNearestPlayer(guid)
--    end
    local tgt = findAiTarget(guid)
    if tgt == nil then
        printToAll('Error: AI ' .. ai.getName() .. ' has no target',{0, 0, 1})
        setpending(guid)
    else
        -- local tgt = getObjectFromGUID(tgtGuid)
        -- aitargets[guid] = tgt
        -- printToAll("--------------------------------------------------",{0,1,0})
        -- printToAll(ai.getName().." declares target as [00FF00][u]" .. tgt.getName().."[/u][-]",{0,1,0})
        local aiPos = ai.getPosition()
        local tgtPos = tgt.getPosition()
        local aiForward = getForwardVector(guid)
        local tgtForward = getForwardVector(tgt.getGUID())
        local offset = {tgtPos[1] - aiPos[1],0,tgtPos[3] - aiPos[3]}
        local angle = math.atan2(offset[3], offset[1]) - math.atan2(aiForward[3], aiForward[1])
        if angle < 0 then
            angle = angle + 2 * math.pi
        end
        local fleeing = dot(offset,tgtForward)>0
        local move = getMove(getAiType(ai),angle,realDistance(guid,tgt.getGUID()),fleeing)
        if squad ~= nil then
            -- printToAll("Setting move for squad [".. squad.."] ".. move,{1,0,0})
            squadleader[squad] = guid
            squadmove[squad] = move
            squadposition[squad] = aiPos
            squadrotation[squad] = ai.getRotation()[2]
        end
        executeMove(ai, move)
        Render_SwerveLeft(ai,move)
        Render_SwerveRight(ai,move)
    end
end
function findAiTarget(guid)
    if aitargets[guid]~=nil then
        return aitargets[guid]
    end
    local ai = getObjectFromGUID(guid)
    local tgtGuid
    if aitype[guid] == 'strike' then
        printToAll(ai.getName() .. " is STRIKE AI",{0,1,0})
        tgtGuid = striketarget
    else
        tgtGuid = findNearestPlayer(guid)
    end
    if tgtGuid ~= nil then
        local tgt = getObjectFromGUID(tgtGuid)
        aitargets[guid] = tgt
        return tgt
    else
        return nil
    end
end

function AiSquadButton(ai)
    local squad = getAiSquad(ai)
    if squad == nil then
        printToAll("No squad name found (Must be in format '[AI:INT:1] Tie Interceptor Alpha#1')",{1,0,0})
        setpending(ai.getGUID())
        return
    end
    if squad ~=nil and squadmove[squad] ~= nil then
        -- printToAll("Found previous move for [".. squad.."] ".. squadmove[squad],{1,0,0})
        executeMove(ai, squadmove[squad])
        State_AIPostMove(ai)
        aitargets[ai.getGUID()] = aitargets[squadleader[squad]]
    else
        printToAll("No Squad Move Found for ".. squad,{1,0,0})
        setpending(ai.getGUID())
        return
    end
    local next = FindNextAi(ai.getGUID(),MoveSort)

    if next ~=nil then
        State_AIMove(next)
        UpdateNote(MoveSort, next.getGUID())
    else
        UpdateNote(MoveSort, nil, true)
    end
    for i,ship in ipairs(getAllObjects()) do
        if isAi(ship) and ship.getGUID()~=ai.getGUID() then
            if next==nil or ship.getGUID()~=next.getGUID() then
                ship.clearButtons()
            end
        end
    end
end
function executeMove(ai, move)
    if aiswerved[ai.getGUID()]~=true then
        aimove[ai.getGUID()] = move
    end
    local movestripped = string.gsub(move,"*","")
    ai.setDescription(movestripped)

    if string.find(move,'*') then
        aistressed[ai.getGUID()] = true
        ai_stress = true
--        printToAll('[STRESS - No Action]',{1, 0, 0})
    end
end
function Render_SwerveLeft(object)
    local move = aimove[object.getGUID()]

    local swerves = getSwerve(getAiType(object),move)
    if swerves ~= nil and swerves[1] ~= nil and aiswerved[object.getGUID()]~=true then
        local swerve = {['click_function'] = 'Action_SwerveLeft', ['label'] = swerves[1], ['position'] = {-0.6, 0.3, 1.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 400, ['height'] = 300, ['font_size'] = 300}
        object.createButton(swerve)
    end
end
function Action_SwerveLeft(object)
    local move = aimove[object.getGUID()]
    local swerves = getSwerve(getAiType(object),move)
    aiswerved[object.getGUID()] = true
    object.setDescription("q "..swerves[1])
end
function Render_SwerveRight(object)
    local move = aimove[object.getGUID()]

    local swerves = getSwerve(getAiType(object),move)
    if swerves ~= nil and swerves[2] ~= nil and aiswerved[object.getGUID()]~=true then
        local swerve = {['click_function'] = 'Action_SwerveRight', ['label'] = swerves[2], ['position'] = {0.6, 0.3, 1.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 400, ['height'] = 300, ['font_size'] = 300}
        object.createButton(swerve)
    end
end
function Action_SwerveRight(object)
    local move = aimove[object.getGUID()]
    local swerves = getSwerve(getAiType(object),move)
    aiswerved[object.getGUID()] = true
    object.setDescription("q "..swerves[2])
end

function getMove(type, direction,range,fleeing)
    local i_dir = math.ceil(direction / (math.pi/4) + 0.5)
    if i_dir > 8 then i_dir = i_dir - 8 end
    local i_range = range / 3.7
    local chooseClosing = i_range<=1 or (i_range <=2 and not fleeing)
    local i_roll = math.random(6)

    local closeMoves = {}
    local farMoves = {}
    if type == "TIE" then
        closeMoves[1] = {'bl2','br2','s2','s2','k4*','k4*'}
        closeMoves[2] = {'s2','bl2','bl2','k4*','k4*','tl1'}
        closeMoves[3] = {'tl1','tl1','tl2','tl2','k3*','k4*'}
        closeMoves[4] = {'tl1','tl1','tl2','k3*','k4*','k4*'}
        closeMoves[5] = {'k4*','k3*','k3*','tl3','tr3','s5'}
        closeMoves[6] = {'tr1','tr1','tr2','k3*','k4*','k4*'}
        closeMoves[7] = {'tr1','tr1','tr2','tr2','k3*','k4*'}
        closeMoves[8] = {'s2','br2','br2','k4*','k4*','tr1' }

        farMoves[1] = {'s5','s5','s5','s4','s4','s3'}
        farMoves[2] = {'s3','bl2','bl3','bl3','bl3','tl3'}
        farMoves[3] = {'bl3','tl3','bl2','tl2','tl2','tl1'}
        farMoves[4] = {'k4*','k3*','k3*','tl2','tl2','tl1'}
        farMoves[5] = {'k3*','k3*','k3*','k3*','tl1','tr1'}
        farMoves[6] = {'k4*','k3*','k3*','tr2','tr2','tr1'}
        farMoves[7] = {'br3','tr3','br2','tr2','tr2','tr1'}
        farMoves[8] = {'s3','br2','br3','br3','br3','tr3' }
    end
    if type == "INT" then
        closeMoves[1] = {'bl2','br2','s2','s2','k5*','k5*'}
        closeMoves[2] = {'s2','bl2','bl2','k5*','k5*','tl1'}
        closeMoves[3] = {'tl1','tl1','tl2','tl2','k3*','k5*'}
        closeMoves[4] = {'tl1','tl1','tl2','k3*','k5*','k5*'}
        closeMoves[5] = {'k5*','k3*','k3*','tl3','tr3','s5'}
        closeMoves[6] = {'tr1','tr1','tr2','k3*','k5*','k5*'}
        closeMoves[7] = {'tr1','tr1','tr2','tr2','k3*','k5*'}
        closeMoves[8] = {'s2','br2','br2','k5*','k5*','tr1' }

        farMoves[1] = {'s5','s5','s5','s4','s4','s3'}
        farMoves[2] = {'s3','bl2','bl3','bl3','bl3','tl3'}
        farMoves[3] = {'bl3','tl3','bl2','tl2','tl2','tl1'}
        farMoves[4] = {'k5*','k3*','k3*','tl2','tl2','tl1'}
        farMoves[5] = {'k3*','k3*','k3*','k3*','tl1','tr1'}
        farMoves[6] = {'k5*','k3*','k3*','tr2','tr2','tr1'}
        farMoves[7] = {'br3','tr3','br2','tr2','tr2','tr1'}
        farMoves[8] = {'s3','br2','br3','br3','br3','tr3' }
    end
    if type == "ADV" then
        closeMoves[1] = {'bl1','br1','s2','s2','k4*','k4*'}
        closeMoves[2] = {'s2','bl1','bl1','bl1','k4*','k4*'}
        closeMoves[3] = {'bl1','k4*','k4*','tl2','tl2','tl2'}
        closeMoves[4] = {'k4*','k4*','k4*','tl2','tl2','bl1'}
        closeMoves[5] = {'k4*','k4*','k4*','k4*','tl3','tr3'}
        closeMoves[6] = {'k4*','k4*','k4*','tr2','tr2','br1'}
        closeMoves[7] = {'br1','k4*','k4*','tr2','tr2','tr2'}
        closeMoves[8] = {'s2','br1','br1','br1','k4*','k4*' }

        farMoves[1] = {'s5','s5','s5','s4','s4','s3'}
        farMoves[2] = {'s3','bl2','bl3','bl3','bl3','tl3'}
        farMoves[3] = {'bl1','bl2','tl2','tl2','tl3','tl3'}
        farMoves[4] = {'k4*','k4*','k4*','tl2','tl2','tl2'}
        farMoves[5] = {'k4*','k4*','k4*','k4*','tl2','tr2'}
        farMoves[6] = {'k4*','k4*','k4*','tr2','tr2','tr2'}
        farMoves[7] = {'br1','br2','tr2','tr2','tr3','tr3'}
        farMoves[8] = {'s3','br2','br3','br3','br3','tr3' }
    end
    if type == "BOM" then
        closeMoves[1] = {'bl1','br1','s1','s1','s1','k5*'}
        closeMoves[2] = {'tl3','s1','bl1','bl1','bl1','k5*'}
        closeMoves[3] = {'bl1','tl2*','tl2*','tl3','tl3','tl3'}
        closeMoves[4] = {'k5*','k5*','k5*','tl3','tl3','tl2*'}
        closeMoves[5] = {'k5*','k5*','k5*','k5*','tl3','tr3'}
        closeMoves[6] = {'k5*','k5*','k5*','tr3','tr3','tr2*'}
        closeMoves[7] = {'br1','tr2*','tr2*','tr3','tr3','tr3'}
        closeMoves[8] = {'tr3','s1','br1','br1','br1','k5*' }

        farMoves[1] = {'s4','s4','s4','s3','s3','s2'}
        farMoves[2] = {'s2','bl2','bl3','bl3','bl3','tl3'}
        farMoves[3] = {'bl3','tl2*','tl2*','tl3','tl3','tl3'}
        farMoves[4] = {'k5*','k5*','tl2*','tl2*','tl3','tl3'}
        farMoves[5] = {'k5*','k5*','k5*','k5*','tl2*','tr2*'}
        farMoves[6] = {'k5*','k5*','tr2*','tr2*','tr3','tr3'}
        farMoves[7] = {'br3','tr2*','tr2*','tr3','tr3','tr3'}
        farMoves[8] = {'s2','br2','br3','br3','br3','tr3' }
    end
    if type == "DEF" then
        closeMoves[1] = {'bl1','br1','s2','s2','k4','k4'}
        closeMoves[2] = {'s2','bl1','bl1','k4','k4','tl1*'}
        closeMoves[3] = {'bl1','k4','k4','tl2*','tl1*','tl1*'}
        closeMoves[4] = {'k4','k4','k4','tl2*','tl2*','tl1*'}
        closeMoves[5] = {'k4','k4','k4','k4','tl3','tr3'}
        closeMoves[6] = {'k4','k4','k4','tr2*','tr2*','tr1*'}
        closeMoves[7] = {'br1','k4','k4','tr2*','tr1*','tr1*'}
        closeMoves[8] = {'s2','br1','br1','k4','k4','tr1*' }

        farMoves[1] = {'s5','s5','s5','s4','s4','s3'}
        farMoves[2] = {'s3','bl2','bl3','bl3','bl3','tl3'}
        farMoves[3] = {'bl1','bl2','tl2*','tl3','tl3','tl3'}
        farMoves[4] = {'k4','k4','k4','tl2*','tl2*','tl1*'}
        farMoves[5] = {'k4','k4','k4','k4','tl1*','tr1*'}
        farMoves[6] = {'k4','k4','k4','tr2*','tr2*','tr1*'}
        farMoves[7] = {'br1','br2','tr2*','tr3','tr3','tr3'}
        farMoves[8] = {'s3','br2','br3','br3','br3','tr3' }
    end
    if type == "PHA" then
        closeMoves[1] = {'bl2','br2','s2','k4*','k4*','k4*'}
        closeMoves[2] = {'s2','bl2','k4*','k4*','tl1','tl1'}
        closeMoves[3] = {'tl1','tl1','tl1','tl2','tl2','k4*'}
        closeMoves[4] = {'tl1','tl1','tl2','k3*','k4*','k4*'}
        closeMoves[5] = {'k4*','k3*','k3*','tl3','tr3','s4'}
        closeMoves[6] = {'tr1','tr1','tr2','k3*','k4*','k4*'}
        closeMoves[7] = {'tr1','tr1','tr1','tr2','tr2','k4*'}
        closeMoves[8] = {'s2','br2','k4*','k4*','tr1','tr1' }

        farMoves[1] = {'s4','s4','s4','s3','s3','s2'}
        farMoves[2] = {'s3','bl2','bl3','bl3','bl3','tl3'}
        farMoves[3] = {'tl1','tl1','tl2','tl2','tl3','bl2'}
        farMoves[4] = {'k4*','k3*','k3*','tl2','tl2','tl1'}
        farMoves[5] = {'k3*','k3*','k3*','k3*','tl1','tr1'}
        farMoves[6] = {'k4*','k3*','k3*','tr2','tr2','tr1'}
        farMoves[7] = {'tr1','tr1','tr2','tr2','tr3','br2'}
        farMoves[8] = {'s3','br2','br3','br3','br3','tr3' }
    end
    if type == "DEC" then
        closeMoves[1] = {'s4','s4','bl3','br3','tl3','tr3'}
        closeMoves[2] = {'bl3','br3','br2','tr2','s4','s4'}
        closeMoves[3] = {'bl3','bl3','tl3','bl2','tl2','bl1'}
        closeMoves[4] = {'bl3','bl3','tl2','tl2','bl2','bl1'}
        closeMoves[5] = {'tl3','tr3','tl2','tr2','bl1','br1'}
        closeMoves[6] = {'br3','br3','tr2','tr2','br2','br1'}
        closeMoves[7] = {'br3','br3','tr3','br2','tr2','br1'}
        closeMoves[8] = {'br3','bl3','bl2','tl2','s4','s4' }

        farMoves[1] = {'s4','s4','s4','s3','s3','s2'}
        farMoves[2] = {'s4','bl3','bl3','bl3','bl2','tl3'}
        farMoves[3] = {'bl3','tl3','tl3','tl2','tl2','bl1'}
        farMoves[4] = {'tl2','tl2','tl2','tl3','tl3','bl1'}
        farMoves[5] = {'tl2','tl2','tl2','tr2','tr2','tr2'}
        farMoves[6] = {'tr2','tr2','tr2','tr3','tr3','br1'}
        farMoves[7] = {'br3','tr3','tr3','tr2','tr2','br1'}
        farMoves[8] = {'s4','br3','br3','br3','br2','tr3' }
    end
    if type == "SHU" then
        closeMoves[1] = {'s0*','s0*','s0*','s1','br1','bl1'}
        closeMoves[2] = {'s0*','s1','bl1','bl1','bl1','tl2*'}
        closeMoves[3] = {'s0*','tl2*','tl2*','tl2*','bl1','bl2'}
        closeMoves[4] = {'s0*','tl2*','tl2*','tl2*','bl2','bl3*'}
        closeMoves[5] = {'s0*','*','tr2*','tl2*','br3*','bl3*'}
        closeMoves[6] = {'s0*','tr2*','tr2*','tr2*','br2','br3*'}
        closeMoves[7] = {'s0*','tr2*','tr2*','tr2*','br1','br2'}
        closeMoves[8] = {'s0*','s1','br1','br1','br1','tr2*' }

        farMoves[1] = {'s3','s3','s3','s2','s2','s1'}
        farMoves[2] = {'s2','bl3*','bl2','bl2','bl2','tl2*'}
        farMoves[3] = {'tl2*','tl2*','tl2*','tl2*','bl2','bl3*'}
        farMoves[4] = {'tl2*','tl2*','tl2*','tl2*','bl1','bl1'}
        farMoves[5] = {'tl2*','tl2*','tl2*','tr2*','tr2*','tr2*'}
        farMoves[6] = {'tr2*','tr2*','tr2*','tr2*','br1','br1'}
        farMoves[7] = {'tr2*','tr2*','tr2*','tr2*','br2','br3*'}
        farMoves[8] = {'s2','br3*','br2','br2','br2','tr2*' }
    end

    local move = ""
    if chooseClosing then
        move = closeMoves[i_dir][i_roll]
    else
        move = farMoves[i_dir][i_roll]
    end

    return move
end
function getSwerve(type, move)
    local swerves = {}
    if type == "SHU" then
        swerves["s0*"] = {nil,nil}
    end
    -- 1
    if type == "TIE" or type == "INT" or type == "PHA" then
        swerves["tl1"] = {nil,"bl2"}
        swerves["tr1"] = {"br2",nil }
    end
    if type == "ADV" then
        swerves["bl1"] = {"tl2","s2"}
        swerves["br1"] = {"s2","tr2" }
    end
    if type == "DEF" then
        swerves["tl1*"] = {nil,"bl1"}
        swerves["bl1"] = {"tl1*","s2"}
        swerves["br1"] = {"s2","tr1*" }
        swerves["tr1*"] = {"br1",nil }
    end
    if type == "BOM" then
        swerves["bl1"] = {"tl2*","s1"}
        swerves["s1"] = {"bl1","br1"}
        swerves["br1"] = {"s1","tr2*" }
    end
    if type == "DEC" then
        swerves["bl1"] = {"tl2","s1"}
        swerves["s1"] = {"bl1","br1"}
        swerves["br1"] = {"s1","tr2" }
    end
    if type == "SHU" then
        swerves["bl1"] = {"tl2*","s1"}
        swerves["s1"] = {"bl1","br1"}
        swerves["br1"] = {"s1","tr2*"}
    end
    -- 2
    if type == "TIE" or type == "INT" or type == "ADV" or type == "PHA" or type == "DEC" then

        swerves["tl2"] = {nil,"bl2"}
        swerves["bl2"] = {"tl2","s2"}
        swerves["s2"] = {"bl2","br2"}
        swerves["br2"] = {"s2","tr2"}
        swerves["tr2"] = {"br2",nil }
    end
    if type == "DEF" or type == "BOM" or type == "SHU" then
        swerves["tl2*"] = {nil,"bl2"}
        swerves["bl2"] = {"tl2*","s2"}
        swerves["s2"] = {"bl2","br2"}
        swerves["br2"] = {"s2","tr2*"}
        swerves["tr2*"] = {"br2",nil }
    end
    -- 3
    if type == "TIE" or type == "INT" or type == "ADV" or type == "PHA" or type == "DEF" or type == "BOM" or type == "DEC" then
        swerves["tl3"] = {nil,"bl3"}
        swerves["bl3"] = {"tl3","s3"}
        swerves["s3"] = {"bl3","br3"}
        swerves["br3"] = {"s3","tr3"}
        swerves["tr3"] = {"br3",nil }
    end
    if type == "SHU" then
        swerves["bl3*"] = {"tl2*","s3"}
        swerves["s3"] = {"bl3*","br3*"}
        swerves["br3*"] = {"s3","tr2*"}
    end
    if type == "TIE" or type == "INT" or type == "PHA" then
        swerves["k3*"] = {"bl3","br3"}
    end
    -- 4
    if type == "TIE" or type == "INT" or type == "ADV" or type == "PHA" or type == "DEF" or type == "BOM" or type == "DEC" then
        swerves["s4"] = {"bl3","br3"}
    end
    if type == "TIE" or type == "ADV" or type == "PHA" then
        swerves["k4*"] = {"bl3","br3" }
    end
    if type == "DEF" then
        swerves["k4"] = {"bl3","br3" }
    end
    --5
    if type == "TIE" or type == "INT" or type == "ADV" or type == "DEF" then

        swerves["s5"] = {"bl3","br3"}
    end
    if type == "INT"  or type == "BOM" then
        swerves["k5*"] = {"bl3","br3" }
    end
    return swerves[move]
end
function RotateVector(direction, yRotation)

    local rotval = round(yRotation)
    local radrotval = math.rad(rotval)
    local xDistance = math.cos(radrotval) * direction[1] + math.sin(radrotval) * direction[3]
    local zDistance = math.sin(radrotval) * direction[1] * -1 + math.cos(radrotval) * direction[3]
    return {xDistance, direction[2], zDistance}
end

function Action_MovePhase()
    -- printToAll("*****************************",{0,1,1})
    -- printToAll("STARTING ACTIVATION PHASE",{0,1,1})
    -- printToAll("*****************************",{0,1,1})
    currentphase = MoveSort
    squadleader = {}
    squadmove = {}
    squadposition = {}
    squadrotation = {}
    aimove = {}
    aiswerved = {}
    aitargets = {}
    aistressed = {}
    -- ListAis(MoveSort)
    for i,ship in ipairs(getAllObjects()) do
        if isShip(ship) then
            ship.clearButtons()
            if getAiType(ship)=="PHA" then
                Render_AiDecloak(ship)
            end
            -- Set MOVE button
            -- State_AIMove(ship)
        end
    end -- [end loop for all ships]

    local first = FindNextAi(nil, MoveSort)
    current = first
    if first ~=nil then
        findAiTarget(first.getGUID())
        State_AIMove(first)
    end
    UpdateNote(MoveSort, nil)
end
function Action_ClearAi()
    for i,ship in ipairs(getAllObjects()) do
        if isAi(ship) then
            ship.clearButtons()
        end
    end -- [end loop for all ships]
end
function Action_AttackPhase()
    -- printToAll("**************************",{0,1,1})
    -- printToAll("STARTING COMBAT PHASE",{0,1,1})
    -- printToAll("**************************",{0,1,1})
    currentphase = AttackSort
    UpdateNote(AttackSort, nil)
    -- ListAis(AttackSort)
    for i,ship in ipairs(getAllObjects()) do
        if isShip(ship) then
            ship.clearButtons()
            -- Render_Ruler(ship)
        end
    end -- [end loop for all ships]
    local first = FindNextAi(nil, AttackSort)
    current = first
    if first ~=nil then
        Render_Ruler(first)
        Render_AttackButton(first)
    end
end


function Action_EndPhase()
    for i,obj in ipairs(getAllObjects()) do
        if isInPlay(obj) and isTemporary(obj) then
            obj.destruct()
        end
    end
    local note = "*** [FF0000]End Phase - Turn "..tostring(getTurnNumber()).."/"..tostring(getTotalTurns()).."[-] ***\n"
    if getTurnNumber()==getTotalTurns() then
        note = note.."[b]Mission Over[/b]"
    else
        note = note.."Auto-Cleaned up Focus/Evade/Etc\nMoved Turn Marker"
        local pos = turn_marker.getPosition()
        turn_marker.setPosition({pos[1],pos[2],pos[3]-2.59})
    end
    setNotes(note)
end
function getTurnNumber()
    local pos = turn_marker.getPosition()
    return round((13.3-pos[3])/2.59 + 1)
end
function getTotalTurns()
    local pos = end_marker.getPosition()
    return round((13.3-pos[3])/2.59 + 1)
end
function isTemporary(object)
    local name = object.getName()
    return (name=="Evade" or name=="Focus" or name=="Weapon Disabled" or name=="Reinforce") and object.getDescription()~="keep"
end
function Render_AttackButton(object)

    local attackbutton = {['click_function'] = 'Action_AiAttack', ['label'] = 'Attack', ['position'] = {0, 0.3, -0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 750, ['height'] = 550, ['font_size'] = 250}
    object.createButton(attackbutton)
end
function Action_AiAttack(object)
    object.clearButtons()
    local next = FindNextAi(object.getGUID(),AttackSort)
    current = next
    if next ~=nil then
        Render_Ruler(next)
        Render_AttackButton(next)
        UpdateNote(AttackSort, next.getGUID())
    else
        UpdateNote(AttackSort, nil, true)
    end
end
function UpdateNote(sort, next,complete)
    local phasename = {}
    phasename[MoveSort] = "Activation"
    phasename[AttackSort] = "Combat"
    local phasecolor = {}
    phasecolor[MoveSort] = "00FF80"
    phasecolor[AttackSort] = "FF8000"
    local ai_string = ""
    if currentphase ~= nil then
        ai_string = "*** ["..phasecolor[currentphase].."]"..phasename[currentphase].." Phase - Turn "..tostring(getTurnNumber()).."/"..tostring(getTotalTurns()).."[-] ***"
    end
    local ais = {}
    local showPlayers = true
    for i,ship in ipairs(getAllObjects()) do
        if (isAi(ship) or isShip(ship) and showPlayers and getSkill(ship)~=nil) then
            table.insert(ais, ship)
        end
    end -- [end loop for all ships]
    table.sort(ais,sort)
    local first = true
    for i,ship in ipairs(ais) do
        local arrow = ''
        local current = next == nil and not complete and  first or next == ship.getGUID()
        if current then
            arrow = "[0080FF][b]Current ---->[/b][-] "
            first = false
        end
        ai_string = ai_string.."\n"..arrow..prettyString(ship,true)
    end
    if complete then
        ai_string = ai_string.."\n".."[0080FF][b][Complete][/b][-]"
    end
    setNotes(ai_string)
end
function ListAis(sort)
    printToAll("Sorting AIs, Found:",{0,1,0})
    local ais = {}
    local showPlayers = true
    for i,ship in ipairs(getAllObjects()) do
        if (isAi(ship) or isShip(ship) and showPlayers and getSkill(ship)~=nil) then
            table.insert(ais, ship)
        end
    end -- [end loop for all ships]
    table.sort(ais,sort)
    for i,ship in ipairs(ais) do
        prettyPrint(ship)
    end
end
function prettyString(ship,withtarget)
    local skill_colors = {"666666","FF30FF","8030FF","3030FF","3080FF","30FFFF","30FF80","30FF30","80FF30","FFFF30","FF3030" }
    local type_colors = {TIE="666666",INT="600000",ADV="c1440e",BOM="00FFFF",DEF="660066",PHA="2C75FF",DEC="808080",SHU="A0A0A0"}
    local isAi = isAi(ship)
    local skill = tostring(getSkill(ship))
    local skill_color = skill_colors[tonumber(skill)+1]
    if skill_color==nil then skill_color="000000" end
    if isAi then
        local type = tostring(getAiType(ship))
        local type_color = type_colors[type]
        if type_color == nil then type_color = "000000" end
        local squad = getAiSquad(ship)
        if squad == nil then squad = "" end
        local number = tostring(getAiNumber(ship))
        local target = ""
        local stress = ""
        local stress_end = ""
        if aistressed[ship.getGUID()]~=nil then
            --stress = "[800000][*][-] "
            stress = "[C02020]"
            stress_end = "[-]"
        end
        if withtarget and aitargets[ship.getGUID()] then
            local nops = stripPS(aitargets[ship.getGUID()].getName())
            local nocolor = string.gsub(string.gsub(nops,"%[%w*%]",""),"%[%-%]","")
            local short = string.sub(nocolor, 1,3)
            local shortwithcolor = string.gsub(nops,nocolor,short)
            --local stripped_colors = nops:match
            target = " [101010][[-][u]"..shortwithcolor.."[/u][101010]][-]"
        end
        return stress.."PS["..skill_color.."]"..skill.."[-] ["..type_color.."]"..type.."[-] "..squad.."#"..number..stress_end..target,{0,0,1}
    else
        return "PS["..skill_color.."]"..skill.."[-] "..stripPS(ship.getName()).."",{0,0,1}
    end
end
function stripPS(name)
    return string.gsub(name,"%[%d+%]%s*","")
end
function prettyPrint(ship)
    printToAll(prettyString(ship),{0,0,1})
end
function FindNextAi(guid, sort)
    local ais = {}
    for i,ship in ipairs(getAllObjects()) do
        if isShip(ship) then
            table.insert(ais, ship)
        end
    end -- [end loop for all ships]
--    for i,ship in ipairs(ais) do
--        printToAll(ship.getName().." - "..getSkill(ship.getName()).." - "..getAiNumber(ship.getName()),{0,1,0})
--    end
    table.sort(ais,sort)
--    if guid==nil then
--        return ais[1]
--    else
        local selffound = false
        for i,ship in ipairs(ais) do
            if selffound or guid==nil then
                if isAi(ship) then
                    return ship
                else
                    table.insert(players_up_next,ship)
                    return ship
                end
            end
            if ship.getGUID()==guid then selffound = true end
        end
--    end
end
function AttackSort(a, b)
    local a_ps = tonumber(getSkill(a))
    local a_num = tonumber(getAiNumber(a))
    local b_ps = tonumber(getSkill(b))
    local b_num = tonumber(getAiNumber(b))
    if a_ps ~= b_ps then
        if a_ps == nil or b_ps == nil then
            return a_ps~=nil
        end
        return a_ps > b_ps
    else
        if isAi(a) ~= isAi(b) then
            return isAi(a)
        else
            return a_num<b_num
        end
    end
end
function MoveSort(a, b)
    local a_ps = tonumber(getSkill(a))
    local a_num = tonumber(getAiNumber(a))
    local b_ps = tonumber(getSkill(b))
    local b_num = tonumber(getAiNumber(b))
    if a_ps ~= b_ps then
        if a_ps == nil or b_ps == nil then
            return a_ps~=nil
        end
        return a_ps < b_ps
    else
        if isAi(a) ~= isAi(b) then
            return isAi(a)
        else
            return a_num<b_num
        end
    end
end
function State_AIMove(object)
    -- Set MOVE button
    local label = 'Move'
    if not isAi(object) then label = 'Next' end
    local movebutton = {['click_function'] = 'Action_AiMove', ['label'] = label, ['position'] = {0, 0.3, -0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 750, ['height'] = 550, ['font_size'] = 250}
    object.createButton(movebutton)
    if isAi(object) and getAiSquad(object)~=nil then
        local squadbutton = {['click_function'] = 'AiSquadButton', ['label'] = 'Squad', ['position'] = {0, 0.3, 0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 750, ['height'] = 550, ['font_size'] = 250}
        object.createButton(squadbutton)
    end
    --if getAiType(object) == "PHA" then
    --    Render_AiDecloak(object)
    --end
end
function Action_AiMove(object)
    --object.setDescription("ai")

    if isAi(object) then
        auto(object.getGUID())
    end
    GoToNextMove(object)
end
function GoToNextMove(object)
    if isAi(object) then
        State_AIPostMove(object)
    else
        object.clearButtons()
    end
    local next = FindNextAi(object.getGUID(),MoveSort)
    current = next
    if next ~=nil then
        findAiTarget(next.getGUID())
        State_AIMove(next)
        UpdateNote(MoveSort, next.getGUID())
    else
        UpdateNote(MoveSort, nil, true)
    end
    for i,ship in ipairs(getAllObjects()) do
        if isAi(ship) and ship.getGUID()~=object.getGUID() then
            if next==nil or ship.getGUID()~=next.getGUID() then
                ship.clearButtons()
            end
        end
    end
end
function State_AIPostMove(object)

    object.clearButtons()
    Render_Undo(object)

    Render_AiFocusEvade(object)

    Render_Ruler(object)

    if getAiHasBoost(object) then
        Render_Boost(object)
    end

    if getAiHasBarrelRoll(object) then
        Render_BarrelRoll(object)
    end
end


function Render_Undo(object)
    local undobutton = {['click_function'] = 'AiUndoButton', ['label'] = 'q', ['position'] = {-0.9, 0.3, -0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
    object.createButton(undobutton)
end
function Render_AiUndoDecloak(object)
    local undobutton = {['click_function'] = 'Action_AiUndoDecloak', ['label'] = 'q', ['position'] = {-0.9, 0.3, -0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
    object.createButton(undobutton)
end
function Action_AiUndoDecloak(object)
    aidecloaked[object.getGUID()] = nil
    object.setDescription("q")
    Render_AiDecloak(object)

end
function AiUndoButton(object)
    aiswerved[object.getGUID()] = nil
    if squadleader[object.getGUID()]~=nil then
        local squad = getAiSquad(object)
        squadleader[squad] = nil
        squadmove[squad] = nil
        squadposition[squad] = nil
        squadrotation[squad] = nil
    end
    object.clearButtons()
    object.setDescription("q")

    State_AIMove(object)
end

local function Render_AiUndoBoostBarrel(object)
    local undobutton = {['click_function'] = 'Action_AiUndoBoostBarrel', ['label'] = 'q', ['position'] = {-0.9, 0.3, -0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
    object.createButton(undobutton)
end

function Action_AiUndoBoostBarrel(object)

    object.clearButtons()
    object.setDescription("q")

    Render_Ruler(object)

    if getAiHasBoost(object) then
        Render_Boost(object)
    end

    if getAiHasBarrelRoll(object) then
        Render_BarrelRoll(object)
    end
end

function Render_Ruler(object)
    local rulerbutton = {['click_function'] = 'RulerButton', ['label'] = 'r', ['position'] = {-0.9, 0.3, 0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
    object.createButton(rulerbutton)
end

function RulerButton(object)
    object.setDescription("r")
end

function Render_Boost(object)

    local bl1button = {['click_function'] = 'Action_AiBoostLeft', ['label'] = 'bl1', ['position'] = {-1.1, 0.3, -1.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 330, ['height'] = 300, ['font_size'] = 250}
    object.createButton(bl1button)

    local s1button = {['click_function'] = 'Action_AiBoostStraight', ['label'] = 's1', ['position'] = {0, 0.3, -1.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 300, ['font_size'] = 250}
    object.createButton(s1button)

    local br1button = {['click_function'] = 'Action_AiBoostRight', ['label'] = 'br1', ['position'] = {1.1, 0.3, -1.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 330, ['height'] = 300, ['font_size'] = 250}
    object.createButton(br1button)
end

function Render_AiDecloak(object)
    if aidecloaked[object.getGUID()]==nil then
        local decloak = {['click_function'] = 'Action_AiDecloak', ['label'] = 'decloak', ['position'] = {0, 0.3, -1.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 1000, ['height'] = 300, ['font_size'] = 250}
        object.createButton(decloak)
    end
end

function Action_AiDecloak(object)
    local i_roll = math.random(3)
    local options = {"ce","cs","cr" }
    object.setDescription(options[i_roll])
    aidecloaked[object.getGUID()]= true
    removeButtonByName(object, "decloak")
    Render_AiUndoDecloak(object)
end

function Action_AiBoostLeft(object)
    object.setDescription("bl1")
    object.clearButtons()
    Render_AiUndoBoostBarrel(object)
    Render_Ruler(object)
    Render_AiFocusEvade(object)
end

function Action_AiBoostStraight(object)
    object.setDescription("s1")
    object.clearButtons()
    Render_AiUndoBoostBarrel(object)
    Render_Ruler(object)
    Render_AiFocusEvade(object)
end

function Action_AiBoostRight(object)
    object.setDescription("br1")
    object.clearButtons()
    Render_AiUndoBoostBarrel(object)
    Render_Ruler(object)
    Render_AiFocusEvade(object)
end

function Render_BarrelRoll(object)

    local xebbutton = {['click_function'] = 'Action_AiBarrelRollLeft', ['label'] = 'xl', ['position'] = {-1.6, 0.3, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 300, ['height'] = 300, ['font_size'] = 250}
    object.createButton(xebbutton)

    local xrbbutton = {['click_function'] = 'Action_AiBarrelRollRight', ['label'] = 'xr', ['position'] = {1.6, 0.3, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 300, ['height'] = 300, ['font_size'] = 250}
    object.createButton(xrbbutton)
end

function Action_AiBarrelRollLeft(object)
    object.setDescription("xl")
    object.clearButtons()
    Render_AiUndoBoostBarrel(object)
    Render_Ruler(object)
    Render_AiFocusEvade(object)
end

function Action_AiBarrelRollRight(object)
    object.setDescription("xr")
    object.clearButtons()
    Render_AiUndoBoostBarrel(object)
    Render_Ruler(object)
    Render_AiFocusEvade(object)
end

function Render_AiFocusEvade(object)

    local focusbutton = {['click_function'] = 'Action_Focus', ['label'] = 'F', ['position'] = {0.9, 0.3, -0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
    object.createButton(focusbutton)

    local type = getAiType(object);
    if type == "TIE" or type=="INT" or type == "ADV" or type == "PHA" then
        local evadebutton = {['click_function'] = 'Action_Evade', ['label'] = 'E', ['position'] = {0.9, 0.3, 0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
        object.createButton(evadebutton)
    end
end


function Action_Focus(object)
    take(focus, object.getGUID(),-0.37,1,-0.37)
    notify(object.getGUID(),'action','takes a focus token')
end
function Action_Evade(object)
    take(evade, object.getGUID(),-0.37,1,0.37)
    notify(object.getGUID(),'action','takes an evade token')
end

function getForwardVector(guid)
    local this = getObjectFromGUID(guid)
    local direction = this.getRotation()
    local rotval = round(direction[2])
    local radrotval = math.rad(rotval)
    local xForward = math.sin(radrotval) * -1
    local zForward = math.cos(radrotval) * -1
    -- log(guid .. " for x: "..round(xForward,2).." y: "..round(zForward,2))
    return {xForward, 0, zForward}
end
function dot(a,b)
    return a[3]*b[3] + a[1]*b[1]
end

function findNearestPlayer(guid)
    local ai  = getObjectFromGUID(guid)
    local inarc = getAiType(ai) ~= "DEC"
    local distances = {}
    local angles = {}

    for i,ship in ipairs(getAllObjects()) do
        if isShip(ship) and not isAi(ship) then
            local pos = ship.getPosition()
            -- log("Adding Target: "..ship.getName())
            distances[ship.getGUID()] = realDistance(guid,ship.getGUID())

            local aiPos = ai.getPosition()
            local aiForward = getForwardVector(guid)
            local tgtForward = getForwardVector(ship.getGUID())
            local tgtCorners = findCorners(ship)
            for i,corner in ipairs(tgtCorners) do
                local offset = {corner[1] - aiPos[1],0,corner[3] - aiPos[3]}
                local angle = math.atan2(offset[3], offset[1]) - math.atan2(aiForward[3], aiForward[1])
                if angle < 0 then
                    angle = angle + 2 * math.pi
                end
                if angles[ship.getGUID()] == nil then
                    angles[ship.getGUID()] = angle
                else
                    local new_diff = angle
                    if angle>math.pi then new_diff = math.pi*2 - angle end
                    local old_diff = angles[ship.getGUID()]
                    if angles[ship.getGUID()]>math.pi then new_diff = math.pi*2 - angles[ship.getGUID()] end
                    if new_diff < old_diff then angles[ship.getGUID()] = angle end
                end
            end
            local offset = {pos[1] - aiPos[1],0,pos[3] - aiPos[3]}
            local angle = math.atan2(offset[3], offset[1]) - math.atan2(aiForward[3], aiForward[1])
            if angle < 0 then
                angle = angle + 2 * math.pi
            end
            angles[ship.getGUID()] = angle
        end -- [end checking distance to ship]

    end -- [end loop for all ships]

    local nearest
    local minDist = 999999

    if inarc then
        local nearestInArc
        minDist = 3.7 * 3
        for guid,dist in pairs(distances) do

            local diff = angles[guid]
            if diff>math.pi then diff = math.pi*2 - diff end
            if diff<math.pi/4 and dist < minDist then
                minDist = dist
                nearestInArc = guid
            end -- [end check for nearest]

        end -- [end loop for each distance]
        if nearestInArc ~= nil then return nearestInArc end
    end
    minDist = 999999
    for guid,dist in pairs(distances) do

        if dist < minDist then
            minDist = dist
            if minDist < 35 then
                nearest = guid
            end
        end -- [end check for nearest]

    end -- [end loop for each distance]

    return nearest
end
function findCorners(object)
    local scalar = 0.85
    if object.getName():match '%LGS$' then scalar = 1.63 end
    local forward = getForwardVector(object.getGUID())
    local f = {forward[1] * scalar, 0, forward[3] * scalar}
    local corners = {}
    corners[1] = { f[1] - f[3], 0,  f[3] + f[1]}
    corners[2] = { f[1] + f[3], 0,  f[3] - f[1]}
    corners[3] = {-f[1] - f[3], 0, -f[3] + f[1]}
    corners[4] = {-f[1] + f[3], 0, -f[3] - f[1] }
    return corners
end
function realDistance(guid1, guid2)
    -- Lazy calc to start. need to go from nearest corner to nearest corner
    local a  = getObjectFromGUID(guid1)
    local b  = getObjectFromGUID(guid2)
    local apos = a.getPosition()
    local bpos = b.getPosition()
    if a == nil or b == nil then return nil end
    local dist = distance(apos[1],apos[3],bpos[1],bpos[3])
    if a.getName():match '%LGS$' then dist = dist - 2.1 else dist = dist - 1.1 end
    if b.getName():match '%LGS$' then dist = dist - 2.1 else dist = dist - 1.1 end
    return dist
end

function isShip(ship)
    return ship.tag == 'Figurine' and ship.name ~= '' and isInPlay(ship)
end

function isAi(ai)
    local is_ai = ai.getName():match '^%[AI:?%u*:?%d*:?%w*].*'
    return isShip(ai) and is_ai~=nil
end

function getAiType(ai)
    local type =  ai.getName():match '^%[AI:?(%u*):?%d*].*'
    local validTypes = {"TIE","INT","ADV","BOM","DEF","PHA","DEC","SHU" }
    if contains(validTypes,type) then
        return type
    else
        -- printToAll("Error: "..ai.getName() .. " does not define valid type in format '[AI:{type}:{PS}] Name'",{1,0,0})
        -- printToAll("Error: Implemented Types are: TIE, INT, ADV, BOM, DEF, PHA, DEC, SHU",{1,0,0})
        return "INT"
    end
end
function getSkill(ai)
    return ai.getName():match '^%[%a*:?%u*:?(%d*)].*'
end
function getAiSquad(ai)
    --return name:match '(%a+)[#%s]?%d+$'
    return ai.getName():match '(%a+)#'
end
function getAiNumber(ai)
    local num = ai.getName():match '#(%d+)'
    if num == nil then return "0" else return num end
    end
function getAiHasBoost(ai)
    local type = getAiType(ai)
    return type == "INT"
end
function getAiHasBarrelRoll(ai)
    local type = getAiType(ai)
    return type == "TIE" or type == "INT" or type == "ADV"or type == "BOM" or type == "DEF" or type == "PHA"
end
function isInPlay(object)
    return math.abs(object.getPosition()[1])<17 and math.abs(object.getPosition()[3])<17
end
function contains(self, val)
    for index, value in ipairs (self) do
        if value == val then
            return true
        end
    end

    return false
end
function empty (self)
    for _, _ in pairs(self) do
        return false
    end
    return true
end
function removeButtonByName(object, name)
    for i,button in ipairs(object.getButtons()) do
        if button.label == name then
            object.removeButton(button.index)
            return
        end
    end
end
function log(string)
    printToAll("[" .. os.date("%H:%M:%S") .. "] " .. string,{0, 0, 1})
end

function onObjectEnterScriptingZone(zone, object)
    if zone.getGUID() == missionzone and object.tag == 'Card' and object.getName():match '^Mission: (.*)' then
        object.clearButtons()
        local offset = 0
        for i,num in ipairs({1,2,3,4,5,6}) do
            local p = {['click_function'] = 'Action_SetPlayer'..num, ['label'] = num..'P', ['position'] = {-1.5, 0.5, -1.3 + offset}, ['rotation'] =  {0, 0, 0}, ['width'] = 250, ['height'] = 250, ['font_size'] = 200}
            object.createButton(p)
            offset = offset + 0.5
        end
        offset = 0
        for i,num in ipairs({2,3,4,5,6,7,8,9,10}) do
            local p = {['click_function'] = 'Action_SetPS'..num, ['label'] = num..'PS', ['position'] = {1.5, 0.5, -1.3 + offset}, ['rotation'] =  {0, 0, 0}, ['width'] = 300, ['height'] = 200, ['font_size'] = 150}
            object.createButton(p)
            offset = offset + 0.3125
        end
        local p = {['click_function'] = 'Action_setup', ['label'] = 'Setup', ['position'] = {0, 0.5, -0.2}, ['rotation'] =  {0, 0, 0}, ['width'] = 450, ['height'] = 200, ['font_size'] = 180}
        object.createButton(p)
    end
end
function Action_SetPlayer1() SetPlayers(1) end
function Action_SetPlayer2() SetPlayers(2) end
function Action_SetPlayer3() SetPlayers(3) end
function Action_SetPlayer4() SetPlayers(4) end
function Action_SetPlayer5() SetPlayers(5) end
function Action_SetPlayer6() SetPlayers(6) end
function SetPlayers(num) mission_players = num printToAll("Setting Number of Players to: "..num,{0,1,1}) end
function Action_SetPS2() SetPS(2) end
function Action_SetPS3() SetPS(3) end
function Action_SetPS4() SetPS(4) end
function Action_SetPS5() SetPS(5) end
function Action_SetPS6() SetPS(6) end
function Action_SetPS7() SetPS(7) end
function Action_SetPS8() SetPS(8) end
function Action_SetPS9() SetPS(9) end
function Action_SetPS10() SetPS(10) end
function SetPS(num) mission_ps = num printToAll("Setting Average Pilot Skill (PS) of Players to: "..num,{0,1,1}) end

MESH= {
    TIE = "https://paste.ee/r/Yz0kt",
    INT = "https://paste.ee/r/JxWNX",
    BOM = "https://paste.ee/r/5A0YG",
    ADV = "https://paste.ee/r/NeptF",
    SHU = "https://paste.ee/r/4uxZO",
    DEF = "https://paste.ee/r/tIm5S",
    PHA = "https://paste.ee/r/JN16g",
    DEC = "https://paste.ee/r/MJOFI",
    GR = "https://paste.ee/r/h5ND1",
    YT = "https://paste.ee/r/kkPoB"
}
DIFFUSE = {
    TIE = "http://i.imgur.com/otxKcUx.png",
    INT = "http://www.fotos-hochladen.net/uploads/alphatex5hjsqnpatb.jpg",
    BOM = "http://i.imgur.com/nYO1XwT.jpg",
    ADV = "http://i.imgur.com/trxaCDg.jpg",
    SHU = "http://i.imgur.com/rd9ZPz3.jpg",
    DEF = "http://i.imgur.com/0u5rtnX.jpg",
    PHA = "http://i.imgur.com/4bXBvZZ.jpg",
    DEC = "http://i.imgur.com/atzM3rO.jpg",
    GR = "http://i.imgur.com/Nur18O2.jpg",
    YT = "http://i.imgur.com/QiomPcM.jpg"
}
COLLIDER = {
    TIE = "https://paste.ee/r/1dx1C",
    INT = "https://paste.ee/r/1dx1C",
    BOM = "https://paste.ee/r/1dx1C",
    ADV = "https://paste.ee/r/VAYqd",
    SHU = "https://paste.ee/r/xBpMo",
    DEF = "https://paste.ee/r/6jn13",
    PHA = "https://paste.ee/r/1dx1C",
    DEC = "https://paste.ee/r/JavTd",
    GR = "https://paste.ee/r/qIaBu",
    YT = "https://paste.ee/r/LIxnJ"
}
shipnum = 1
missionsquads = {}
missionvectors = {}
function Action_setup(object)
    if mission_ps == nil or mission_players == nil then
        printToAll("Must select Number of players and Average Player Skill", {1,0,0})
    else
        local mission = object.getName():match '^Mission: (.*)'
        squads = {}
        missionvectors = {}
        if mission == "Local Trouble" then
            printToAll("Setting up: "..mission, {0,1,0})
            table.insert(missionsquads, {name="Alpha",turn=0,vector=3,ai="attack",type="TIE",count={1,1,0,1,0,1}, elite=false})
            table.insert(missionsquads, {name="Beta",turn=0,vector=4,ai="attack",type="TIE",count={1,0,1,0,1,0}, elite=false})
            table.insert(missionsquads, {name="Gamma",turn=4,vector="1d6",ai="attack",type="INT",count={1,0,0,1,0,0}, elite=false})
            table.insert(missionsquads, {name="Delta",turn=7,vector="1d6",ai="attack",type="TIE",count={0,1,1,0,1,1}, elite=false})
            table.insert(missionvectors, {x=-4.5, y=-1.5, rot=90})
            table.insert(missionvectors, {x=-4.5, y= 1.5, rot=90})
            table.insert(missionvectors, {x=-1.5, y= 4.5, rot=180})
            table.insert(missionvectors, {x= 1.5, y= 4.5, rot=180})
            table.insert(missionvectors, {x= 4.5, y= 1.5, rot=-90})
            table.insert(missionvectors, {x= 4.5, y=-1.5, rot=-90})
        end
        if mission == "Rescue Rebel Operatives" then

        end
        if mission == "Test" then
            shipnum = 1
            Spawn_Squad(1,"TIE","Alpha",4, false)
            Spawn_Squad(2,"INT","Beta",3, false)
            Spawn_Squad(3,"ADV","Beta",2, false)
            Spawn_Squad(4,"BOM","Gamma",1, false)
            Spawn_Squad(5,"DEF","Gamma",3, false)
            Spawn_Squad(6,"PHA","Gamma",4, false)
            Spawn_Squad(7,"SHU","Gamma",1, false)
            Spawn_Squad(8,"DEC","Gamma",1, false)
        end

        for i,squad in ipairs(missionsquads) do
            Spawn_Squad(squad)
        end
    end
end
PS =  {
    TIE = {1, nil, nil, nil, nil},
    INT = {1,4, 6, 8, 10},
    ADV = {2,4, 6, 8, 10},
    BOM = {2,3, 5, 7, 9},
    DEF = {1,3, 5, 7, 9},
    PHA = {3,3, 5, 7, 9},
    SHU = {2,4, 4, 6, 8},
    DEC = {3, nil, nil, nil, nil}
}
squad_offsets = {{0,0,0},{2.2,0,0},{0,0,-2.2},{2.2,0,-2.2} }
squads = {}
function Spawn_Squad(squad)
    local quantity = countSquad(squad)
    local position = {0,0,0 }
    local rotation = 0
    if squad.turn==0 then
        position = calculateRealPosition(squad)
        rotation = missionvectors[squad.vector].rot
    else
        position = calculateTempPosition(squad)
    end
    for i,off in ipairs(squad_offsets) do
        if i<=quantity then
            Spawn_Ship(squad.type, squad.name, squad.elite, add(position,off), rotation)
        end
    end
    squads[squad.turn+1] = squad
end
function calculateRealPosition(squad)
    return {missionvectors[squad.vector].x*3.6, 1, missionvectors[squad.vector].y*3.6}
end
function calculateTempPosition(squad)
    local x = 21.7
    if squads[squad.turn]~=nil and squads[squad.turn-1]~=nil then x = x+4.4 end
    local position = {x, 1, 13.3 - (squad.turn-1)*2.59 }
    if squad.turn == 0 then position = {-5, 1, 13.3} end
    if squads[squad.turn+1]~=nil then position = add(position, {10,0,0}) end
    return position
end
function countSquad(squad)
    local number = 0
    for i,s in ipairs(squad.count) do
        if s>0 and i<=mission_players then number = number+1 end
    end
    return number
end
function add(pos, offset)
    return {pos[1] + offset[1],pos[2] + offset[2],pos[3] + offset[3]}
end

function Spawn_Ship(type, name, elite, position, rotation)
    local obj_parameters = {}
    obj_parameters.type = 'Custom_Model'
    obj_parameters.position = position

    obj_parameters.rotation = { 0, 180+rotation, 0 }
    local newship = spawnObject(obj_parameters)
    local custom = {}
    custom.mesh = MESH[type]
    custom.diffuse = DIFFUSE[type]
    custom.collider = COLLIDER[type]
    custom.type = 1 --Figurine
    custom.material = 1
    custom.specular_intensity = 0
    custom.specular_color = {223/255, 207/255, 190/255}
    newship.setCustomObject(custom)
    local ps = PS[type][1]
    if elite then
        if mission_ps >= 8 then ps = PS[type][5]
        elseif mission_ps >= 6 then ps = PS[type][4]
        elseif mission_ps >= 4 then ps = PS[type][3]
        else ps = PS[type][2]
        end
    end
    local size = ""
    if type == "SHU" or type == "DEC" or type == "YT" then size = " LGS" end
    newship.setName("[AI:"..type..":"..ps.."] "..name.."#"..tostring(shipnum)..size)
    shipnum = shipnum + 1

    newship.scale({0.6327,0.6327,0.6327})
    --newship.lock()
end