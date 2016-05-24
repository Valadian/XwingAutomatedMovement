-- X-Wing Automatic Movement - Hera Verito (Jstek), March 2016
-- X-Wing Arch and Range Ruler - Flolania, March 2016
-- X-Wing Auto Dial Integration - Flolania, March 2016
-- X-Wing Auto Tokens - Hera Verito (Jstek), March 2016
-- X-Wing Auto Bump Rewrite of Movement Code - Flolania, May 2016

--Auto Movement
undolist = {}
undopos = {}
undorot = {}
namelist1 = {}

--Auto Dials
dialpositions = {}

--Collider Infomation
BigShipList = {'https://paste.ee/r/LIxnJ','https://paste.ee/r/v9OYL','https://paste.ee/r/XoXqn','https://paste.ee/r/oOjRN','https://paste.ee/r/v8OYL','https://paste.ee/r/xBpMo','https://paste.ee/r/k4DLM','https://paste.ee/r/JavTd','http://pastebin.com/Tg5hdRTM'}

-- Auto Actions
freshLock = nil
enemy_target_locks = nil
focus = nil --'beca0f'
evade = nil --'4a352e'
stress = nil --'a25e12'
target = nil --'c81580'

ignorePlayerCheck = true

function onload()
    enemy_target_locks = findObjectByNameAndType("Enemy Target Locks", "Infinite").getGUID()
    focus = findObjectByNameAndType("Focus", "Infinite").getGUID()
    evade = findObjectByNameAndType("Evade", "Infinite").getGUID()
    stress = findObjectByNameAndType("Stress", "Infinite").getGUID()
    target = findObjectByNameAndType("Target Locks", "Infinite").getGUID()
    --VALADIAN onload
    onload_ai()
end

function onObjectLeaveScriptingZone(zone, object)
    --VALADIAN MISSION ZONE HANDLING
    onObjectLeaveScriptingZone_ai(zone,object)
    if object.tag == 'Card' and object.getDescription() ~= '' then
        local CardData = dialpositions[CardInArray(object.GetGUID())]
        if CardData ~= nil then
            local obj = getObjectFromGUID(CardData["ShipGUID"])
            if obj.getVar('HasDial') == true then
                ---DELETE ME (if statement) but keep the print
                if CardData["HasButtons"] == false then
                    printToColor(CardData["ShipName"] .. ' already has a dial.', object.held_by_color, {0.2,0.2,0.8})
                else
                    CardData["LeftZone"] = true
                end
            else
                obj.setVar('HasDial', true)
				--VALADIAN Set maneuver for Planning display
                obj.setVar('Maneuver', object.getDescription())
                CardData["Color"] = object.held_by_color
                CardData["LeftZone"] = true
                CardData["HasButtons"] = true
                local flipbutton = {['click_function'] = 'CardFlipButton', ['label'] = 'Flip', ['position'] = {0, -1, 1}, ['rotation'] =  {0, 0, 180}, ['width'] = 750, ['height'] = 550, ['font_size'] = 250}
                object.createButton(flipbutton)
                local deletebutton = {['click_function'] = 'CardDeleteButton', ['label'] = 'Delete', ['position'] = {0, -1, -1}, ['rotation'] =  {0, 0, 180}, ['width'] = 750, ['height'] = 550, ['font_size'] = 250}
                object.createButton(deletebutton)
                object.setVar('Lock',true)
            end
        else
            printToColor('That dial was not saved.', object.held_by_color, {0.2,0.2,0.8})
        end
    end
end


function onObjectEnterScriptingZone(zone, object)
    --VALADIAN MISSION ZONE HANDLING
    onObjectEnterScriptingZone_ai(zone,object)
    ---DELETE ME ALL OF ME HERE
    if dialpositions[1] ~= nil then
        local CardData = dialpositions[CardInArray(object.GetGUID())]
        if CardData ~= nil then
            CardData["LeftZone"] = false
        end
    end
end

function PlayerCheck(Color, GUID)
    ---DELETE ME
    local CardData = dialpositions[CardInArray(GUID)]
    if CardData["LeftZone"] == true then
        --VALADIAN IGNORE PLAYER CHECK
        if ignorePlayerCheck then return true end
    else
        printToColor('Due to TTS Bug -- cannot use buttons down here. Unlock. Drag to main play area and click buttons there.', CardData["Color"], {0.4,0.6,0.2})
        return false
    end
    -----
    local PC = false
    if getPlayer(Color) ~= nil then
        local HandPos = getPlayer(Color).getPointerPosition()
        local DialPos = getObjectFromGUID(GUID).getPosition()
        if distance(HandPos['x'],HandPos['z'],DialPos['x'],DialPos['z']) < 2 then
            PC = true
        end
    end
    return PC
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
        object.setRotation({0,CardData["Rotation"][2],0})
        object.clearButtons()
        local movebutton = {['click_function'] = 'CardMoveButton', ['label'] = 'Move', ['position'] = {-0.32, 1, 1}, ['rotation'] =  {0, 0, 0}, ['width'] = 750, ['height'] = 530, ['font_size'] = 250}
        object.createButton(movebutton)
        local actionbuttonbefore = {['click_function'] = 'CardActionButtonBefore', ['label'] = 'A', ['position'] = {-0.9, 1, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
        object.createButton(actionbuttonbefore)

    end
end

function CardMoveButton(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        check(CardData["ShipGUID"],object.getDescription())
        object.clearButtons()
        CardData["ActionDisplayed"] = false
        CardData["BoostDisplayed"] = false
        CardData["BarrelRollDisplayed"] = false
        local deletebutton = {['click_function'] = 'CardDeleteButton', ['label'] = 'Delete', ['position'] = {-0.32, 1, 1}, ['rotation'] =  {0, 0, 0}, ['width'] = 750, ['height'] = 530, ['font_size'] = 250}
        object.createButton(deletebutton)
        local undobutton = {['click_function'] = 'CardUndoButton', ['label'] = 'Q', ['position'] = {-0.9, 1, -1}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
        object.createButton(undobutton)
        local actionbuttonafter = {['click_function'] = 'CardActionButtonAfter', ['label'] = 'A', ['position'] = {-0.9, 1, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
        object.createButton(actionbuttonafter)
        local focusbutton = {['click_function'] = 'CardFocusButton', ['label'] = 'F', ['position'] = {0.9, 1, -1}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
        object.createButton(focusbutton)
        local stressbutton = {['click_function'] = 'CardStressButton', ['label'] = 'S', ['position'] = {0.9, 1, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
        object.createButton(stressbutton)
        local Evadebutton = {['click_function'] = 'CardEvadeButton', ['label'] = 'E', ['position'] = {0.9, 1, 1}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
        object.createButton(Evadebutton)
    end
end

function CallActionButton(object, beforeORafter)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    --1 before 2 after
    if CardData["ActionDisplayed"] == false then
        CardData["ActionDisplayed"] = true
        if beforeORafter == 1 then
            local focusbutton = {['click_function'] = 'CardFocusButton', ['label'] = 'F', ['position'] = {0.9, 1, -1}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
            object.createButton(focusbutton)
            local stressbutton = {['click_function'] = 'CardStressButton', ['label'] = 'S', ['position'] = {0.9, 1, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
            object.createButton(stressbutton)
            local Evadebutton = {['click_function'] = 'CardEvadeButton', ['label'] = 'E', ['position'] = {0.9, 1, 1}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
            object.createButton(Evadebutton)
            local undobutton = {['click_function'] = 'CardUndoButton', ['label'] = 'Q', ['position'] = {-0.9, 1, -1}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
            object.createButton(undobutton)
        end
        local BoostLeft = {['click_function'] = 'CardBoostLeft', ['label'] = 'BL', ['position'] = {-0.75, 1, -2.2}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
        object.createButton(BoostLeft)
        local BoostCenter = {['click_function'] = 'CardBoostCenter', ['label'] = 'B', ['position'] = {0, 1, -2.2}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
        object.createButton(BoostCenter)
        local BoostRight = {['click_function'] = 'CardBoostRight', ['label'] = 'BR', ['position'] = {0.75, 1, -2.2}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
        object.createButton(BoostRight)
        local BRLeftTop = {['click_function'] = 'CardBRLeftTop', ['label'] = 'XF', ['position'] = {-1.5, 1, -1}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
        object.createButton(BRLeftTop)
        local BRLeftCenter = {['click_function'] = 'CardBRLeftCenter', ['label'] = 'XL', ['position'] = {-1.5, 1, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
        object.createButton(BRLeftCenter)
        local BRLeftBack = {['click_function'] = 'CardBRLeftBack', ['label'] = 'XB', ['position'] = {-1.5, 1, 1}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
        object.createButton(BRLeftBack)
        local BRRightTop = {['click_function'] = 'CardBRRightTop', ['label'] = 'XF', ['position'] = {1.5, 1, -1}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
        object.createButton(BRRightTop)
        local BRRightCenter = {['click_function'] = 'CardRightCenter', ['label'] = 'XR', ['position'] = {1.5, 1, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
        object.createButton(BRRightCenter)
        local BRRightBack = {['click_function'] = 'CardRightBack', ['label'] = 'XB', ['position'] = {1.5, 1, 1}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
        object.createButton(BRRightBack)
        local TargetLock = {['click_function'] = 'CardTargetLock', ['label'] = 'TL', ['position'] = {-0.75, 1, 2.2}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
        object.createButton(TargetLock)
        local rangebutton = {['click_function'] = 'CardRangeButton', ['label'] = 'R', ['position'] = {0.75, 1, 2.2}, ['rotation'] =  {0, 0, 0}, ['width'] = 365, ['height'] = 530, ['font_size'] = 250}
        object.createButton(rangebutton)
    else
        CardData["ActionDisplayed"] = false
        CardData["BoostDisplayed"] = false
        CardData["BarrelRollDisplayed"] = false
        if beforeORafter == 1 then
            object.removeButton(2)
            object.removeButton(3)
            object.removeButton(4)
            object.removeButton(5)
        end
        object.removeButton(6)
        object.removeButton(7)
        object.removeButton(8)
        object.removeButton(9)
        object.removeButton(10)
        object.removeButton(11)
        object.removeButton(12)
        object.removeButton(13)
        object.removeButton(14)
        object.removeButton(15)
        object.removeButton(16)
    end
end


function CardActionButtonBefore(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        CallActionButton(object,1)
    end
end

function CardActionButtonAfter(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        CallActionButton(object,2)
    end
end



function CardRangeButton(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        if CardData["RangeDisplayed"] == false then
            CardData["RangeDisplayed"] = true
            CardData["RulerObject"] = ruler(CardData["ShipGUID"],2)
        else
            CardData["RangeDisplayed"] = false
            actionButton(CardData["RulerObject"])
        end
    end
end

function CardBoostLeft(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        if CardData["BoostDisplayed"] == false then
            CardData["BoostDisplayed"] = true
            check(CardData["ShipGUID"],'bl1')
        end
    end
end
function CardBoostCenter(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        if CardData["BoostDisplayed"] == false then
            CardData["BoostDisplayed"] = true
            check(CardData["ShipGUID"],'s1')
        end
    end
end
function CardBoostRight(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        if CardData["BoostDisplayed"] == false then
            CardData["BoostDisplayed"] = true
            check(CardData["ShipGUID"],'br1')
        end
    end
end
function CardBRLeftTop(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        if CardData["BarrelRollDisplayed"] == false then
            CardData["BarrelRollDisplayed"] = true
            check(CardData["ShipGUID"],'xlf')
        end
    end
end
function CardBRLeftCenter(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        if CardData["BarrelRollDisplayed"] == false then
            CardData["BarrelRollDisplayed"] = true
            check(CardData["ShipGUID"],'xl')
        end
    end
end
function CardBRLeftBack(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        if CardData["BarrelRollDisplayed"] == false then
            CardData["BarrelRollDisplayed"] = true
            check(CardData["ShipGUID"],'xlb')
        end
    end
end
function CardBRRightTop(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        if CardData["BarrelRollDisplayed"] == false then
            CardData["BarrelRollDisplayed"] = true
            check(CardData["ShipGUID"],'xrf')
        end
    end
end
function CardRightCenter(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        if CardData["BarrelRollDisplayed"] == false then
            CardData["BarrelRollDisplayed"] = true
            check(CardData["ShipGUID"],'xr')
        end
    end
end
function CardRightBack(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        if CardData["BarrelRollDisplayed"] == false then
            CardData["BarrelRollDisplayed"] = true
            check(CardData["ShipGUID"],'xrb')
        end
    end
end

function CardTargetLock(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        take(target, CardData["ShipGUID"],0.5,1,-0.5,true,CardData["Color"],CardData["ShipName"])
        notify(CardData["ShipGUID"],'action','acquires a target lock')
    end
end

function CardFocusButton(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        take(focus, CardData["ShipGUID"],-0.5,1,-0.5,false,0,0)
        notify(CardData["ShipGUID"],'action','takes a focus token')
    end
end

function CardStressButton(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        take(stress, CardData["ShipGUID"],0.5,1,0.5,false,0,0)
        notify(CardData["ShipGUID"],'action','takes stress')
    end
end

function CardEvadeButton(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        take(evade, CardData["ShipGUID"],-0.5,1,0.5,false,0,0)
        notify(CardData["ShipGUID"],'action','takes an evade token')
    end
end

function CardUndoButton(object)
    local CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        CardData["BoostDisplayed"] = false
        CardData["BarrelRollDisplayed"] = false
        check(CardData["ShipGUID"],'undo')
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
        object.setVar('Lock',false)
        CardData["Color"] = nil
        ---DELETE ME x2
        CardData["HasButtons"] = false
        CardData["LeftZone"] = false
		--VALADIAN next on maneuver deletion 
        getObjectFromGUID(CardData["ShipGUID"]).setDescription("ai next")
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
        printToAll(#index .. ' dials removed for ' .. obj.getName() .. '.', {0.2,0.2,0.8})
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
                        cardtable["ActionDisplayed"] = false
                        cardtable["BoostDisplayed"] = false
                        cardtable["BarrelRollDisplayed"] = false
                        cardtable["RangeDisplayed"] = false
                        cardtable["RulerObject"] = nil
                        cardtable["Color"] = nil
                        ---DELETE ME
                        cardtable["LeftZone"] = false
                        cardtable["HasButtons"] = false
                        --------END DELETE ME
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
        printToAll('Error: ' .. obj.getName() .. ' attempted to save dials already saved to another ship. Use rd on old ship first.',{0.2,0.2,0.8})
    end
    if deckerror == true then
        printToAll('Error: Cannot save dials in deck format.',{0.2,0.2,0.8})
    end
    if error == true then
        printToAll('Caution: Cannot save dials in main play area.',{0.2,0.2,0.8})
    end
    if count <= 17 then
        printToAll(count .. ' dials saved for ' .. obj.getName() .. '.', {0.2,0.2,0.8})
    else
        resetdials(guid,0)
        printToAll('Error: Tried to save to many dials for ' .. obj.getName() .. '.', {0.2,0.2,0.8})
    end
    setpending(guid)
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

    local button = {['click_function'] = 'GuideButton', ['label'] = 'Remove', ['position'] = {0, 0.5, 0}, ['rotation'] =  {0, 270, 0}, ['width'] = 1500, ['height'] = 1500, ['font_size'] = 250}
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
            local shipname = ship.getName()
            local shipdesc = ship.getDescription()
            checkname(shipguid,shipdesc,shipname)
            check(shipguid,shipdesc)
        end
        if ship.getVar('Lock') == true and ship.held_by_color == nil and ship.resting == true then
            ship.setVar('Lock',false)
            ship.lock()
        end
    end
    --VALADIAN AI handling
    update_ai()
end

function round(x)
    --Can you be Deleted?
    return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
end
function take(parent, guid, xoff, yoff, zoff, TL, color, name)
    local obj = getObjectFromGUID(guid)
    local objp = getObjectFromGUID(parent)
    local world = obj.getPosition()

    --VALADIAN Rotate Take to be relative position
    local offset = RotateVector({xoff, yoff, zoff}, obj.getRotation()[2])

    local params = {}
    params.position = {world[1]+offset[1], world[2]+offset[2], world[3]+offset[3]}
    if TL == true then
        local callback_params = {}
        callback_params['player_color'] = color
        callback_params['ship_name'] = name
        params.callback = 'setNewLock'
        params.callback_owner = Global
        params.params = callback_params
    end
    freshLock = objp.takeObject(params)
end

function setNewLock(object, params)
    freshLock.call('manualSet', {params['player_color'], params['ship_name']})
end

function undo(guid)
    local obj = getObjectFromGUID(guid)
    if undolist[guid] ~= nil then
        obj.setPosition(undopos[guid])
        obj.setRotation(undorot[guid])
    end
    obj.Unlock()
    setpending(guid)
end

function distance(x,y,a,b)
    x = (x-a)*(x-a)
    y = (y-b)*(y-b)
    return math.sqrt(math.abs((x+y)))
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
    obj.setVar('Lock',true)
    setpending(guid)
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

function ruler(guid,action)
    -- action for 1 for display button 2 for not
    local shipobject = getObjectFromGUID(guid)
    --VALADIAN clear buttons
    shipobject.clearButtons()
    local shipname = shipobject.getName()
    local direction = shipobject.getRotation()
    local world = shipobject.getPosition()
    local scale = shipobject.getScale()
    --VALADIAN TURBOLASER RULER
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
    if isBigShip(guid) == true then
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
    if action == 2 then
        return newruler
    else
        local button = {['click_function'] = 'actionButton', ['label'] = 'Remove', ['position'] = {0, 0.5, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 1300, ['height'] = 1300, ['font_size'] = 250}
        newruler.createButton(button)
    end
    notify(guid,'r')
end

function actionButton(object)
    object.destruct()
    local ship = findNearestShip(object.getPosition())
    --VALADIAN REDRAW BUTTON STATE
    Render_ButtonState(ship)
end
function BumpButton(guid)
    local obj = getObjectFromGUID(guid)
    obj.clearButtons()
    local button = {}
    if isBigShip(guid) == true then
        button = {['click_function'] = 'deletebump', ['label'] = 'BUMPED', ['position'] = {0, 0.2, 2}, ['rotation'] =  {0, 0, 0}, ['width'] = 1000, ['height'] = 350, ['font_size'] = 250}
    else
        button = {['click_function'] = 'deletebump', ['label'] = 'BUMPED', ['position'] = {0, 0.3, 0.8}, ['rotation'] =  {0, 0, 0}, ['width'] = 1000, ['height'] = 350, ['font_size'] = 250}
    end
    obj.createButton(button)
end

function deletebump(object)
    object.clearButtons()
    --VALADIAN REDRAW BUTTON STATE
    Render_ButtonState(object)
end


function isBigShip(guid)
    local obj = getObjectFromGUID(guid)
    local Properties = obj.getCustomObject()
    --printToAll('"'..Properties.collider..'"',{1,0,0})
    for i,ship in pairs(BigShipList) do
        if Properties.collider == ship then
            return true
        end
    end
    return false
end


function notify(guid,move,text,ship)
    if text == nil then
        text = ''
    end
    local obj = getObjectFromGUID(guid)
    local name = obj.getName()
    name = string.gsub(name,":","|")
    if move == 'q' then
        printToAll(name .. ' executed undo.', {0, 1, 0})
    elseif move == 'set' then
        printToAll(name .. ' set name.', {0, 1, 1})
    elseif move == 'r' then
        printToAll(name .. ' spawned a ruler.', {0.2, 0.2, 0.8})
elseif move == 'action' then
        printToAll(name .. ' ' .. text .. '.', {0.959999978542328 , 0.439000010490417 , 0.806999981403351})
    elseif move == 'keep' then
        printToAll(name .. ' stored his position.', {0.5, 0, 1})
    elseif move == 'decloak' then
        printToAll(name .. ' cannot decloak.', {0.5, 1, 0.9})
    else
        if ship ~= nil then
            printToAll(name .. ' attemped a (' .. move .. ') but is now touching ' .. ship .. '.', {0.9, 0.5, 0})
        else
            printToAll(name .. ' ' .. text ..' (' .. move .. ').', {1, 0, 0})
        end
    end
end

function check(guid,move)

    -- Ruler Commands
    if move == 'r' or move == 'ruler' then
        ruler(guid,1)

        -- Auto Dial Commands
    elseif move == 'sd' or move == 'storedial' or move == 'storedials' then
        if move == 'sd' then
            checkdials(guid)
        else
            SpawnDialGuide(guid)
        end
    elseif move == 'rd' or move == 'removedial' or move == 'removedials' then
        resetdials(guid, 1)

        -- Straight Commands
    elseif move == 's0' then
        notify(guid,move,'is stationary')
        setpending(guid)
    elseif move == 's1' then
        straight(guid,2.9,false,move,'flew straight 1')
    elseif move == 's2' then
        straight(guid,4.35,false,move,'flew straight 2')
    elseif move == 's3' then
        straight(guid,5.79,false,move,'flew straight 3')
    elseif move == 's4' then
        straight(guid,7.25,false,move,'flew straight 4')
    elseif move == 's5' then
        straight(guid,8.68,false,move,'flew straight 5')

        -- Bank Commands
    elseif move == 'br1' then
        turnShip(guid,3.689526061,1,0,false,move,'banked right 1')
    elseif move == 'br2' then
        turnShip(guid,5.490753857,1,0,false,move,'banked right 2')
    elseif move == 'br3' then
        turnShip(guid,7.363015996,1,0,false,move,'banked right 3')
    elseif move == 'bl1' or move == 'be1' then
        turnShip(guid,3.689526061,0,0,false,move,'banked left 1')
    elseif move == 'bl2' or move == 'be2' then
        turnShip(guid,5.490753857,0,0,false,move,'banked left 2')
    elseif move == 'bl3' or move == 'be3' then
        turnShip(guid,7.363015996,0,0,false,move,'banked left 3')

        -- Turn Commands
    elseif move == 'tr1' then
        turnShip(guid,2,1,1,false,move,'turned right 1')
    elseif move == 'tr2' then
        turnShip(guid,3,1,1,false,move,'turned right 2')
    elseif move == 'tr3' then
        turnShip(guid,4,1,1,false,move,'turned right 3')
    elseif move == 'tl1' or move == 'te1' then
        turnShip(guid,2,0,1,false,move,'turned left 1')
    elseif move == 'tl2' or move == 'te2' then
        turnShip(guid,3,0,1,false,move,'turned left 2')
    elseif move == 'tl3' or move == 'te3' then
        turnShip(guid,4,0,1,false,move,'turned left 3')

        -- Koiogran Turn Commands
    elseif move == 'k2' then
        straight(guid,4.35,true,move,'koiogran turned 2')
    elseif move == 'k3' then
        straight(guid,5.79,true,move,'koiogran turned 3')
    elseif move == 'k4' then
        straight(guid,7.25,true,move,'koiogran turned 4')
    elseif move == 'k5' then
        straight(guid,8.68,true,move,'koiogran turned 5')

        -- Segnor's Loop Commands
    elseif move == 'bl2s' or move == 'be2s' then
        turnShip(guid,5.490753857,0,0,true,move,'segnors looped left 2')
    elseif move == 'bl3s' or move == 'be3s' then
        turnShip(guid,7.363015996,0,0,true,move,'segnors looped left 3')
    elseif move == 'br2s' then
        turnShip(guid,5.490753857,1,0,true,move,'segnors looped right 2')
    elseif move == 'br3s' then
        turnShip(guid,7.363015996,1,0,true,move,'segnors looped right 3')

        -- Barrel Roll Commands
    elseif move == 'xl' or move == 'xe' then
        MiscMovement(guid,0,1,0,move,'barrel rolled left')
    elseif move == 'xlf' or move == 'xef' or move == 'rolllf' or move == 'rollet' then
        MiscMovement(guid,0.73999404907227,1,0,move,'barrel rolled forward left')
    elseif move == 'xlb' or move == 'xeb' or move == 'rolllb'  or move == 'rolleb' then
        MiscMovement(guid,-0.73999404907227,1,0,move,'barrel rolled backwards left')
    elseif move == 'xr' or move == 'rollr'then
        MiscMovement(guid,0,1,1,move,'barrel rolled right')
    elseif move == 'xrf' or move == 'rollrf' then
        MiscMovement(guid,0.73999404907227,1,1,move,'barrel rolled forward right')
    elseif move == 'xrb' or move == 'rollrb' then
        MiscMovement(guid,-0.73999404907227,1,1,move,'barrel rolled backwards right')

        -- Decloak Commands
    elseif move == 'cs' or move == 'cf' then
        MiscMovement(guid,4.35,2,2,move,'decloaked straight')
    elseif move == 'cl' or move == 'ce' then
        MiscMovement(guid,0,2,0,move,'decloaked left')
    elseif move == 'clf' or move == 'cef' then
        MiscMovement(guid,0.73999404907227,2,0,move,'decloaked forward left')
    elseif move == 'clb' or move == 'ceb' then
        MiscMovement(guid,-0.73999404907227,2,0,move,'decloaked backwards left')
    elseif move == 'cr' then
        MiscMovement(guid,0,2,1,move,'decloaked right')
    elseif move == 'crf' then
        MiscMovement(guid,0.73999404907227,2,1,move,'decloaked forward right')
    elseif move == 'crb' then
        MiscMovement(guid,-0.73999404907227,2,1,move,'decloak backwards right')

        -- MISC Commands
    elseif move == 'checkpos' then
        checkpos(guid)
    elseif move == 'checkrot' then
        checkrot(guid)
    elseif move == 'keep' then
        storeundo(guid)
        notify(guid,move)
        setpending(guid)
    elseif move == 'set' then
        registername(guid)
        notify(guid,move)
    elseif move == 'undo' or move == 'q' then
        undo(guid)
        notify(guid,'q')
    end
    --VALADIAN AI COMMANDS
    check_ai(guid, move)
end




function MiscMovement(guid,forwardDistance,type,direction,move,text)
    --guid = ship moving
    --type 1 = barrel roll 2 = decloak
    --direction = 0 left    1 right  2 forward
    --forwardDistance = distance to be traveled
    storeundo(guid)
    local obj = getObjectFromGUID(guid)
    local shipname = obj.getName()
    local sidewaysDistance
    if type == 1 then
        --barrel roll
        sidewaysDistance = 2.8863945007324
    elseif type == 2 then
        --decloak
        if direction == 2 then
            sidewaysDistance = 0
        else
            sidewaysDistance = 4.3295917510986
        end
    end
    if isBigShip(guid) == true then
        --barrelroll
        if type == 1 then
            --barrel roll
            sidewaysDistance = 3.6147861480713
            forwardDistance = forwardDistance*2
        elseif type == 2 then
            --nocloak big ships
            move = 'decloak'
            forwardDistance = 0
            sidewaysDistance = 0
        end
    end
    local rot = obj.getRotation()
    local world = obj.getPosition()
    local radrotval = math.rad(rot[2])
    local xDistance = math.sin(radrotval) * forwardDistance * -1
    local zDistance = math.cos(radrotval) * forwardDistance * -1
    --left is - and + is right
    if direction == 0 then
        radrotval = radrotval - math.rad(90)
    elseif direction == 1 then
        radrotval = radrotval + math.rad(90)
    end
    xDistance = xDistance + (math.sin(radrotval) * sidewaysDistance * -1)
    zDistance = zDistance + (math.cos(radrotval) * sidewaysDistance * -1)
    obj.setPosition( {world[1]+xDistance, world[2]+2, world[3]+zDistance} )
    obj.Rotate({0, 0, 0})
    setlock(guid)
    notify(guid,move,text)
end



function turnShip(guid,radius,direction,type,kturn,move,text)
    --radius = turn radius
    --direction = 0  - left  1 - right
    --type = 0 - 45 deg   1 - 90 deg
    --kturn = true false
    --guid = ship moving
    -- move and text for notify
    storeundo(guid)
    local obj = getObjectFromGUID(guid)
    local rot = obj.getRotation()
    local pos = obj.getPosition()
    local degree = {}
    if type == 0 then
        degree = 45
    elseif type == 1 then
        degree = 90
    end
    local BumpingObjects = posbumps(guid, direction)
    local Bumped = {false, nil}
    local coords,theta = turncoords(guid,radius,direction,degree,type)
    if BumpingObjects ~= nil then
        for k=#BumpingObjects ,1,-1 do
            local doescollide = collide(pos[1]+coords[1],pos[3]+coords[2],rot[2]+theta,guid,BumpingObjects[k]["Position"][1],BumpingObjects[k]["Position"][3],BumpingObjects[k]["Rotation"][2],BumpingObjects[k]["ShipGUID"])
            if doescollide == true then
                for e2=degree, 1, -1 do
                    local checkdegree = e2
                    coords,theta = turncoords(guid,radius,direction,checkdegree,type)
                    local doescollide2 = collide(pos[1]+coords[1],pos[3]+coords[2],rot[2]+theta,guid,BumpingObjects[k]["Position"][1],BumpingObjects[k]["Position"][3],BumpingObjects[k]["Rotation"][2],BumpingObjects[k]["ShipGUID"])
                    if doescollide2 == false then
                        degree = checkdegree
                        Bumped = {true, k}
                        break
                    end
                end
            end
        end
    end
    obj.setPosition({pos[1] + coords[1], 2, pos[3] + coords[2]})
    if kturn == true and Bumped[1] == false then
        theta = theta - 180
    end
    obj.Rotate({0, theta, 0})
    if Bumped[1] == true then
        BumpButton(guid)
        notify(guid,move,text,BumpingObjects[Bumped[2]]["ShipName"])
    else
        notify(guid,move,text)
    end
    setlock(guid)
end



function straight(guid,forwardDistance,kturn,move,text)
    -- guid = ship moving
    -- forwardDistance = amount to move forwardDistance
    -- kturn true or false
    -- move and text for notify
    storeundo(guid)
    local obj = getObjectFromGUID(guid)
    local pos = obj.getPosition()
    local rot = obj.getRotation()
    if isBigShip(guid) == true then
        forwardDistance = 1.468 + forwardDistance
    end
    local Bumped = {false , nil}
    local BumpingObjects = posbumps(guid, 2)
    local xDistance = math.sin(math.rad(rot[2])) * forwardDistance * -1
    local zDistance = math.cos(math.rad(rot[2])) * forwardDistance * -1
    if BumpingObjects ~= nil then
        for k=#BumpingObjects ,1,-1 do
            local doescollide = collide(pos[1]+xDistance,pos[3]+zDistance,rot[2],guid,BumpingObjects[k]["Position"][1],BumpingObjects[k]["Position"][3],BumpingObjects[k]["Rotation"][2],BumpingObjects[k]["ShipGUID"])
            if doescollide == true then
                for e2=100, 1, -1 do
                    local checkdistance = forwardDistance*(e2/100)
                    xDistance = math.sin(math.rad(rot[2])) * checkdistance * -1
                    zDistance = math.cos(math.rad(rot[2])) * checkdistance * -1
                    local doescollide2 = collide(pos[1]+xDistance,pos[3]+zDistance,rot[2],guid,BumpingObjects[k]["Position"][1],BumpingObjects[k]["Position"][3],BumpingObjects[k]["Rotation"][2],BumpingObjects[k]["ShipGUID"])
                    if doescollide2 == false then
                        forwardDistance = checkdistance
                        Bumped = {true, k}
                        break
                    end
                end
            end
        end
    end
    obj.setPosition({pos[1]+xDistance, pos[2]+2, pos[3]+zDistance})
    if kturn == true and Bumped[1] == false then
        obj.Rotate({0, 180, 0})
    else
        obj.Rotate({0, 0, 0})
    end
    if Bumped[1] == true then
        BumpButton(guid)
        notify(guid,move,text,BumpingObjects[Bumped[2]]["ShipName"])
    else
        notify(guid,move,text)
    end
    setlock(guid)
end

function turncoords(guid,radius,direction,theta,type)
    -- DO NOT CALL THIS USE TURN
    -- guid = ship moving
    -- radius of turn
    -- direction 0 left    1 right
    -- theta = 0 to 90
    -- type = 0 for 45 or 1 for 90
    -- This can be condensed alot by another function
    -- to lazy atm
    local scale = 0.734
    radius = (math.sqrt((radius - scale) * (radius - scale) * 2))/2

    if isBigShip(guid) == true then
        scale = scale * 2
    end

    local obj = getObjectFromGUID(guid)
    local rot = obj.getRotation()
    local pos = obj.getPosition()
    local xLeftDistance = pos[1] + radius * math.sin(math.rad(rot[2] + 135 - theta)) - radius * math.cos(math.rad(rot[2] + 135 - theta))
    local yLeftDistance = pos[3] + radius * math.cos(math.rad(rot[2] + 135 - theta)) + radius * math.sin(math.rad(rot[2] + 135 - theta))
    local xRightDistance = pos[1] + radius * math.sin(math.rad(rot[2] - 45 + theta)) - radius * math.cos(math.rad(rot[2] - 45 + theta))
    local yRightDistance = pos[3] + radius * math.cos(math.rad(rot[2] - 45 + theta)) + radius * math.sin(math.rad(rot[2] - 45 + theta))

    local rvector = {pos[1] + radius * math.sin(math.rad(rot[2]-45)) - radius * math.cos(math.rad(rot[2]-45)), pos[3] + radius * math.cos(math.rad(rot[2]-45)) + radius * math.sin(math.rad(rot[2]-45))}
    local rnvector = {math.sin(math.rad(rot[2] +90))* -1, math.cos(math.rad(rot[2]+90))* -1}
    rnvector = getNormal(rnvector[1],rnvector[2])
    rnvector = {rnvector[1]*scale,rnvector[2]*scale}

    local lvector = {pos[1] + radius * math.sin(math.rad(rot[2]+135)) - radius * math.cos(math.rad(rot[2]+135)), pos[3] + radius * math.cos(math.rad(rot[2]+135)) + radius * math.sin(math.rad(rot[2]+135))}
    local lnvector = {math.sin(math.rad(rot[2] -90))* -1,  math.cos(math.rad(rot[2]-90))* -1}
    lnvector = getNormal(lnvector[1],lnvector[2])
    lnvector = {lnvector[1]*scale,lnvector[2]*scale}

    local fvector = {pos[1] + radius * math.sin(math.rad(rot[2]-135)) - radius * math.cos(math.rad(rot[2]-135)), pos[3] + radius * math.cos(math.rad(rot[2]-135)) + radius * math.sin(math.rad(rot[2]-135))}
    local fnvector = {math.sin(math.rad(rot[2])) * -1, math.cos(math.rad(rot[2])) * -1}
    fnvector = getNormal(fnvector[1],fnvector[2])
    fnvector = {fnvector[1]*scale,fnvector[2]*scale}

    local fnhalfrvector = {math.sin(math.rad(rot[2]+45)) * -1, math.cos(math.rad(rot[2]+45)) * -1}
    fnhalfrvector = getNormal(fnhalfrvector[1],fnhalfrvector[2])
    fnhalfrvector = {fnhalfrvector[1]*scale,fnhalfrvector[2]*scale}

    local fnhalflvector = {math.sin(math.rad(rot[2]-45)) * -1, math.cos(math.rad(rot[2]-45)) * -1}
    fnhalflvector = getNormal(fnhalflvector[1],fnhalflvector[2])
    fnhalflvector = {fnhalflvector[1]*scale,fnhalflvector[2]*scale}

    local newleftturnvector = {lvector[1]-xLeftDistance+ fnvector[1],lvector[2]-yLeftDistance+ fnvector[2]}
    local newrightturnvector = {rvector[1]-xRightDistance+ fnvector[1],rvector[2]-yRightDistance+ fnvector[2]}

    if type == 1 then
        if theta == 90 then
            newleftturnvector = {newleftturnvector[1]+lnvector[1] ,newleftturnvector[2]+lnvector[2]}
            newrightturnvector = {newrightturnvector[1]+rnvector[1],newrightturnvector[2]+rnvector[2]}
        end
    elseif type == 0 then
        if theta == 45 then
            newleftturnvector = {newleftturnvector[1]+fnhalflvector[1] ,newleftturnvector[2]+fnhalflvector[2]}
            newrightturnvector = {newrightturnvector[1]+fnhalfrvector[1],newrightturnvector[2]+fnhalfrvector[2]}
        end
    end

    if direction == 0 then
        return {newleftturnvector[1],newleftturnvector[2]}, 360 - theta
    else
        return {newrightturnvector[1],newrightturnvector[2]}, theta
    end
end

function posbumps(guid, direction)
    --direction 0 = left 1 = right 2 = forward
    --direction of bump check
    local obj = getObjectFromGUID(guid)
    local pos = obj.getPosition()
    local rot = obj.getRotation()
    local rv,cv,lv,fv

    local scale = 0.734
    if isBigShip(guid) == true then
        scale = scale * 2
    end
    if direction == 1 then
        rv = {math.sin(math.rad(rot[2]+45))* -1, math.cos(math.rad(rot[2]+45)) * -1}
        cv = getNormal(rv[1],rv[2])
    elseif direction == 0 then
        lv = {math.sin(math.rad(rot[2]-45))* -1, math.cos(math.rad(rot[2]-45))* -1}
        cv = getNormal(lv[1],lv[2])
    elseif direction == 2 then
        fv = {math.sin(math.rad(rot[2]))* -1, math.cos(math.rad(rot[2]))* -1}
        cv = getNormal(fv[1],fv[2])
    end

    local Objects = {}
    for i,ship in ipairs(getAllObjects()) do
        if ship.tag == 'Figurine' and ship.name ~= '' and ship.getGUID() ~= guid then
            local shippos = ship.getPosition()
            local shiprot = ship.getRotation()
            local sfv = {shippos[1]-pos[1],shippos[3]-pos[3]}
            local scv = getNormal(sfv[1],sfv[2])
            local dot = dot2d({cv[1],cv[2]},{scv[1],scv[2]})
            if dot > 0 then
                local circledist = distance(pos[1],pos[3],shippos[1],shippos[3])
                if circledist < 8 then
                    local perp = calcPerpendicular({pos[1],pos[3]},{cv[1]+pos[1],cv[2]+pos[3]},{shippos[1],shippos[3]})
                    if perp < 3.2 then
                        local BumpTable = {}
                        BumpTable["Position"] = ship.getPosition()
                        BumpTable["Rotation"] = ship.getRotation()
                        BumpTable["ShipGUID"] = ship.getGUID()
                        BumpTable["ShipName"] = ship.getName()
                        BumpTable.MaxDistance = circledist
                        Objects[#Objects +1] = BumpTable
                    end
                end
            end
        end
    end
    table.sort(Objects, function(a,b) return a.MaxDistance < b.MaxDistance end)
    return Objects
end

function calcPerpendicular(a, b, c)
    -- a b c vectors x,y
    -- a b are points on the line
    -- c is the point to find distance to
    local slope1 = (b[2]-a[2])/(b[1]-a[1])
    local yint1 = a[2]-slope1*a[1]
    local slope2 = -(b[1]-a[1])/(b[2]-a[2])
    local yint2 = c[2]-slope2*c[1]
    local x = (yint2-yint1)/(slope1-slope2)
    local y = slope2*x+yint2
    return distance(x,y,c[1],c[2])
end

function getCorners(f,g,rotation,guid)
    local corners = {}
    local scale = 0.734
    if isBigShip(guid) == true then
        scale = scale * 2
    end
    local world_coords = {}
    world_coords[1] = {f - scale, g + scale}
    world_coords[2] = {f + scale, g + scale}
    world_coords[3] = {f + scale, g - scale}
    world_coords[4] = {f - scale, g - scale}
    for r, corr in ipairs(world_coords) do
        local xcoord = f + ((corr[1] - f) * math.sin(math.rad(rotation))) - ((corr[2] - g) * math.cos(math.rad(rotation)))
        local ycoord = g + ((corr[1] - f) * math.cos(math.rad(rotation))) + ((corr[2] - g) * math.sin(math.rad(rotation)))
        corners[r] = {xcoord,ycoord}
    end
    return corners
end

function getNormal(x,y)
    local len = math.sqrt((x*x)+(y*y))
    return {x/len,y/len}
end

function getAxis(c1,c2)
    local axis = {}
    axis[1] = {c1[2][1]-c1[1][1],c1[2][2]-c1[1][2]}
    axis[2] = {c1[4][1]-c1[1][1],c1[4][2]-c1[1][2]}
    axis[3] = {c2[2][1]-c2[1][1],c2[2][2]-c2[1][2]}
    axis[4] = {c2[4][1]-c2[1][1],c2[4][2]-c2[1][2]}
    return axis
end

function dot2d(p,o)
    return p[1] * o[1] + p[2] * o[2]
end

function collide(x1, y1, r1, guid1, x2, y2, r2, guid2)
    local c2 = getCorners(x2, y2, r2, guid2)
    local c1 = getCorners(x1, y1, r1, guid1)
    local axis = getAxis(c1,c2)
    local scalars = {}
    for i1 = 1, #axis do
        for i2, set in pairs({c1,c2}) do
            scalars[i2] = {}
            for i3, point in pairs(set) do
                table.insert(scalars[i2],dot2d(point,axis[i1]))
            end
        end
        local s1max = math.max(unpack(scalars[1]))
        local s1min = math.min(unpack(scalars[1]))
        local s2max = math.max(unpack(scalars[2]))
        local s2min = math.min(unpack(scalars[2]))
        if s2min > s1max or s2max < s1min then
            return false
        end
    end
    return true
end

-------------------------------------------------------------------
---- START VALADIAN'S AI CODE
-------------------------------------------------------------------

-- AI
aitype = {}
striketarget = nil
-- aicardguid = '2d84be'
squadleader = {}
squadmove = {}
squadposition = {}
squadrotation = {}
aimove = {}
aiswerved = {}
airollboosted = {}
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
function onload_ai()
    --    local aicard = findObjectByName("AI Action Card")
    --    if aicard~=nil then
    --        local prebutton = {['click_function'] = 'Action_Planning', ['label'] = 'Planning', ['position'] = {0, 0.3, -1.5}, ['rotation'] =  {0, 0, 0}, ['width'] = 1200, ['height'] = 400, ['font_size'] = 250}
    --        aicard.createButton(prebutton)
    --
    --        local flipbutton = {['click_function'] = 'Action_Activation', ['label'] = 'Activation', ['position'] = {0, 0.3, -0.5}, ['rotation'] =  {0, 0, 0}, ['width'] = 1200, ['height'] = 400, ['font_size'] = 250}
    --        aicard.createButton(flipbutton)
    --
    --        local attackbutton = {['click_function'] = 'Action_Combat', ['label'] = 'Combat', ['position'] = {0, 0.3, 0.5}, ['rotation'] =  {0, 0, 0}, ['width'] = 1200, ['height'] = 400, ['font_size'] = 250}
    --        aicard.createButton(attackbutton)
    --
    --        local clearbutton = {['click_function'] = 'Action_End', ['label'] = 'End', ['position'] = {0, 0.3, 1.5}, ['rotation'] =  {0, 0, 0}, ['width'] = 1200, ['height'] = 400, ['font_size'] = 250}
    --        aicard.createButton(clearbutton)
    --    end
    turn_marker = findObjectByName("Turn Marker")
    end_marker = findObjectByName("End Marker")
end
function update_ai()
    for i,ship in ipairs(getAllObjects()) do
        if ship.getName():match "Turbolaser.*" and (ship.getDescription()=="r" or ship.getDescription()=="ruler") then
            ruler(ship.getGUID())
        end
    end
    UpdatePlanningNote()
end
function check_ai (guid, move)

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
    if move:match 'ai flee (%a)' then
        local direction = string.lower(move:match 'ai flee (%a)')
        if contains({'e','s','n','w'},direction) then
            aitype[guid] = 'flee_'..direction
            local ship = getObjectFromGUID(guid)
            printToAll('AI Type For: ' .. ship.getName() .. ' set to FLEE',{0, 1, 0})
        else
            printToAll("'"..direction.."' is invalid direction for AI FLEE command {E, S, W, N}",{1, 0, 0})
        end
        setpending(guid)
    end
    if move == 'ai striketarget' or
            move == 'ai target' then
        striketarget = guid
        local ship = getObjectFromGUID(guid)
        printToAll('Strike Target Set: ' .. ship.getName(),{0.2, 0.2, 0.8})
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
                if not isAi(ship) and isShip(ship) and isInPlay(ship) and matches then
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
        if currentphase == MoveSort then
            local ship = getObjectFromGUID(guid)
            GoToNextMove(ship)
        elseif currentphase == AttackSort then
            Action_AiAttack(ship)
        end
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
    if string.starts(move,"q ") then
        local nextmove = string.gsub(move,"q ","")
        undo(guid)
        executeMove(getObjectFromGUID(guid),nextmove)
    end
end
function onObjectLeaveScriptingZone_ai(zone, object)
    if zone.getGUID() == missionzone and object.tag == 'Card' and object.getName():match '^Mission: (.*)' then
        object.clearButtons()
    end
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
        printToAll('Error: AI ' .. ai.getName() .. ' has no target',{0.2, 0.2, 0.8})
        setpending(guid)
    else
        local move
        if aitype[guid]~=nil and aitype[guid]:match 'flee_(%a)' then
            local direction = string.lower(aitype[guid]:match 'flee_(%a)')
            local offsets = {
                e = {12,0,0},
                s = {0, 0, -12},
                w = {-12, 0, 0},
                n = {0, 0, 12}
            }
            local aiPos = ai.getPosition()
            local aiForward = getForwardVector(guid)
            local tgtPos = add(ai.getPosition(), offsets[direction])
            local offset = {tgtPos[1] - aiPos[1],0,tgtPos[3] - aiPos[3]}
            local angle = math.atan2(offset[3], offset[1]) - math.atan2(aiForward[3], aiForward[1])
            if angle < 0 then
                angle = angle + 2 * math.pi
            end
            move = getMove(getAiType(ai),angle,12,true,true)
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
            move = getMove(getAiType(ai),angle,realDistance(guid,tgt.getGUID()),fleeing)
            if squad ~= nil and squadmove[squad]==nil then
                -- printToAll("Setting move for squad [".. squad.."] ".. move,{1,0,0})
                squadleader[squad] = guid
                squadmove[squad] = move
                squadposition[squad] = aiPos
                squadrotation[squad] = ai.getRotation()[2]
            end
        end
        executeMove(ai, move)
        Render_Swerves(ai)
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

function Action_AiSquad(ai)
    local squad = getAiSquad(ai)
    if squad == nil then
        printToAll("No squad name found (Must be in format '[AI:INT:1] Tie Interceptor Alpha#1')",{1,0,0})
        setpending(ai.getGUID())
        return
    end
    if squad ~=nil and squadmove[squad] ~= nil then
        -- printToAll("Found previous move for [".. squad.."] ".. squadmove[squad],{1,0,0})
        executeMove(ai, squadmove[squad])
        Render_Swerves(ai)
        aitargets[ai.getGUID()] = aitargets[squadleader[squad]]
    else
        printToAll("No Squad Move Found for ".. squad,{1,0,0})
        setpending(ai.getGUID())
        return
    end
    GoToNextMove(ai)
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
function Render_ButtonState(object)
    if currentphase == MoveSort then
        if isAi(object) then
            object.clearButtons()
            if aimove[object.getGUID()]~=nil then
                if airollboosted[object.getGUID()] then
                    Render_AiUndoBoostBarrel(object)
                else
                    Render_Undo(object)
                end
                Render_AiFocusEvade(object)

                Render_Ruler(object)
                if airollboosted[object.getGUID()]~=true then
                    Render_Swerves(object)
                    if getAiHasBoost(object) then
                        Render_Boost(object)
                    end

                    if getAiHasBarrelRoll(object) then
                        Render_BarrelRoll(object)
                    end
                end
            else
                local label = 'Move'
                if not isAi(object) then label = 'Next' end
                if isAi(object) then
                    Render_AiFreeFocusEvade(object)
                    Render_AiFreeTargetLock(object)
                end
                if getAiType(object)=="PHA" then
                    Render_AiDecloak(object)
                end
                local movebutton = {['click_function'] = 'Action_AiMove', ['label'] = label, ['position'] = {0, 0.3, -0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 750, ['height'] = 550, ['font_size'] = 250}
                object.createButton(movebutton)
                if isAi(object) and getAiSquad(object)~=nil and squadmove[getAiSquad(object)]~=nil then
                    local squadbutton = {['click_function'] = 'Action_AiSquad', ['label'] = 'Squad', ['position'] = {0, 0.3, 0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 750, ['height'] = 550, ['font_size'] = 250}
                    object.createButton(squadbutton)
                end
                local skipbutton = {['click_function'] = 'Action_AiSkip', ['label'] = "Skip", ['position'] = {0, 0.3, -1.2}, ['rotation'] =  {0, 0, 0}, ['width'] = 750, ['height'] = 550, ['font_size'] = 250}
            end
        elseif object==current then
            State_AIMove(object)
        end
    elseif currentphase == AttackSort then
        Render_Ruler(object)
        Render_AttackButton(object)
    end
end
function Action_AiSkip(object)
    object.setDescription("ai next")
end
function Render_Swerves(object)
    Render_SwerveLeft(object)
    Render_NoSwerve(object)
    Render_SwerveRight(object)
end
function Render_NoSwerve(object)
    local move = aimove[object.getGUID()]
    local noswerve = {['click_function'] = 'Action_NoSwerve', ['label'] = move, ['position'] = {0, 0.3, 1.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 450, ['height'] = 300, ['font_size'] = 300}
    object.createButton(noswerve)
end
function Action_NoSwerve(object)
    local move = aimove[object.getGUID()]
    object.setDescription("q "..move)
end
function Render_SwerveLeft(object)
    local move = aimove[object.getGUID()]

    local swerves = getSwerve(getAiType(object),move)
    if swerves ~= nil and swerves[1] ~= nil then -- and aiswerved[object.getGUID()]~=true
    local swerve = {['click_function'] = 'Action_SwerveLeft', ['label'] = swerves[1], ['position'] = {-1.0, 0.3, 1.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 450, ['height'] = 300, ['font_size'] = 300}
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
    if swerves ~= nil and swerves[2] ~= nil then -- and aiswerved[object.getGUID()]~=true
    local swerve = {['click_function'] = 'Action_SwerveRight', ['label'] = swerves[2], ['position'] = {1.0, 0.3, 1.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 450, ['height'] = 300, ['font_size'] = 300}
    object.createButton(swerve)
    end
end
function Action_SwerveRight(object)
    local move = aimove[object.getGUID()]
    local swerves = getSwerve(getAiType(object),move)
    aiswerved[object.getGUID()] = true
    object.setDescription("q "..swerves[2])
end

function getMove(type, direction,range,far, flee)
    local i_dir = math.ceil(direction / (math.pi/4) + 0.5)
    if i_dir > 8 then i_dir = i_dir - 8 end
    local i_range = range / 3.7
    local chooseClosing = i_range<=1 or (i_range <=2 and not far)
    local i_roll = math.random(6)

    local closeMoves = {}
    local farMoves = {}
    local fleeMoves = {}
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

        fleeMoves['tl1'] = 'tl3'
        fleeMoves['tl2'] = 'tl3'
        fleeMoves['bl2'] = 'bl3'
        fleeMoves['s2'] = 's5'
        fleeMoves['s3'] = 's5'
        fleeMoves['s4'] = 's5'
        fleeMoves['br2'] = 'br3'
        fleeMoves['tr2'] = 'tr3'
        fleeMoves['tr1'] = 'tr3'
        fleeMoves['k4*'] = 'k3*'
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

        fleeMoves['tl1'] = 'tl3'
        fleeMoves['tl2'] = 'tl3'
        fleeMoves['bl2'] = 'bl3'
        fleeMoves['s2'] = 's5'
        fleeMoves['s3'] = 's5'
        fleeMoves['s4'] = 's5'
        fleeMoves['br2'] = 'br3'
        fleeMoves['tr2'] = 'tr3'
        fleeMoves['tr1'] = 'tr3'
        fleeMoves['k5*'] = 'k3*'
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

        fleeMoves['tl2'] = 'tl3'
        fleeMoves['bl1'] = 'bl3'
        fleeMoves['bl2'] = 'bl3'
        fleeMoves['s2'] = 's5'
        fleeMoves['s3'] = 's5'
        fleeMoves['s4'] = 's5'
        fleeMoves['br1'] = 'br3'
        fleeMoves['br2'] = 'br3'
        fleeMoves['tr2'] = 'tr3'
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

        fleeMoves['tl2*'] = 'tl3'
        fleeMoves['bl1'] = 'bl3'
        fleeMoves['bl2'] = 'bl3'
        fleeMoves['s1'] = 's4'
        fleeMoves['s2'] = 's4'
        fleeMoves['s3'] = 's4'
        fleeMoves['br1'] = 'br3'
        fleeMoves['br2'] = 'br3'
        fleeMoves['tr2*'] = 'tr3'
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

        fleeMoves['tl1*'] = 'tl3'
        fleeMoves['tl2*'] = 'tl3'
        fleeMoves['bl1'] = 'bl3'
        fleeMoves['bl2'] = 'bl3'
        fleeMoves['s2'] = 's5'
        fleeMoves['s3'] = 's5'
        fleeMoves['s4'] = 's5'
        fleeMoves['br1'] = 'br3'
        fleeMoves['br2'] = 'br3'
        fleeMoves['tr1*'] = 'tr3'
        fleeMoves['tr2*'] = 'tr3'
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

        fleeMoves['tl1'] = 'tl3'
        fleeMoves['tl2'] = 'tl3'
        fleeMoves['bl2'] = 'bl3'
        fleeMoves['s2'] = 's4'
        fleeMoves['s3'] = 's4'
        fleeMoves['br2'] = 'br3'
        fleeMoves['tr2'] = 'tr3'
        fleeMoves['tr1'] = 'tr3'
        fleeMoves['k4*'] = 'k3*'
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


        fleeMoves['tl2'] = 'tl3'
        fleeMoves['bl1'] = 'bl3'
        fleeMoves['bl2'] = 'bl3'
        fleeMoves['s1'] = 's4'
        fleeMoves['s2'] = 's4'
        fleeMoves['s3'] = 's4'
        fleeMoves['br1'] = 'br3'
        fleeMoves['br2'] = 'br3'
        fleeMoves['tr2'] = 'tr3'
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

        fleeMoves['bl1'] = 'bl3*'
        fleeMoves['bl2'] = 'bl3*'
        fleeMoves['s1'] = 's3'
        fleeMoves['s2'] = 's3'
        fleeMoves['br1'] = 'br3*'
        fleeMoves['br2'] = 'br3*'
    end

    local move = ""
    if flee==true then
        move = farMoves[i_dir][i_roll]
        if fleeMoves[move]~=nil then
            move = fleeMoves[move]
        end
    else
        if chooseClosing then
            move = closeMoves[i_dir][i_roll]
        else
            move = farMoves[i_dir][i_roll]
        end
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
start_delay = ""
function Action_Planning()
    start_delay = ""
    currentphase = PlanningSort
    UpdatePlanningNote()
end
function Action_Activation()
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
    aidecloaked = {}
    -- ListAis(MoveSort)
    for i,ship in ipairs(getAllObjects()) do
        if isShip(ship) and isInPlay(ship) then
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
        --State_AIMove(first)
        Render_ButtonState(first)
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
function Action_Combat()
    -- printToAll("**************************",{0,1,1})
    -- printToAll("STARTING COMBAT PHASE",{0,1,1})
    -- printToAll("**************************",{0,1,1})
    currentphase = AttackSort
    --UpdateNote(AttackSort, nil)
    -- ListAis(AttackSort)
    for i,ship in ipairs(getAllObjects()) do
        if isShip(ship) then
            ship.clearButtons()
            -- Render_Ruler(ship)
        end
    end -- [end loop for all ships]
    Action_AiAttack(nil)
end
--function GoToNextAttack(ship)
--    local first = FindNextAi(ship, AttackSort)
--    current = first
--    if first ~=nil then
--        Render_Ruler(first)
--        Render_AttackButton(first)
--    end
--end

function Action_End()
    --TODO: clear all buttons
    for i,obj in ipairs(getAllObjects()) do
        if isInPlay(obj) and isTemporary(obj) then
            obj.destruct()
        end
    end
    local note = "*** [FF0000]End Phase - Turn "..tostring(getTurnNumber()).."/"..tostring(getTotalTurns()).."[-] ***\n"
    local done = getTurnNumber()==getTotalTurns()
    if done then
        note = note.."[b]Mission Over[/b]"
    else
        note = note.."Auto-Cleaned up Focus/Evade/Etc\nMoved Turn Marker"
        local pos = turn_marker.getPosition()
        turn_marker.setPosition({pos[1],pos[2],pos[3]-2.59})

    end
    setNotes(note)
    if not done then
        startLuaCoroutine(nil, 'delayPlanning')
    end
end
function delayPlanning()
    for i=1, 50, 1 do
        coroutine.yield(0)
    end
    Action_Planning()
    return true
end
turn_marker_warning = false
function getTurnNumber()
    local turn = 1
    if turn_marker ~=nil then
        local pos = turn_marker.getPosition()
        turn = round((13.3-pos[3])/2.59 + 1)
    else
        if not turn_marker_warning then
            printToAll("Add object with name 'Turn Marker' on Turn Track",{1,0,0})
            turn_marker_warning = true
        end
    end
    return turn
end
end_marker_warning = false
function getTotalTurns()
    local total = 12
    if end_marker ~=nil then
        local pos = end_marker.getPosition()
        total = round((13.3-pos[3])/2.59 + 1)
    else
        if not end_marker_warning then
            printToAll("Add object with name 'End Marker' on Turn Track",{1,0,0})
            end_marker_warning = true
        end
    end
    return total
end
function isTemporary(object)
    local name = object.getName()
    local desc = object.getDescription()
    local tag = object.tag
    return (name=="Evade" or name=="Focus" or name=="Weapon Disabled" or name=="Reinforce" or desc=="Red TL" or tag =="Dice") and desc~="keep"
end
function Render_AttackButton(object)

    local attackbutton = {['click_function'] = 'Action_AiAttack', ['label'] = 'Attack', ['position'] = {0, 0.3, -0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 750, ['height'] = 550, ['font_size'] = 250}
    object.createButton(attackbutton)
end
function Action_AiAttack(object)
    local guid
    if object~=nil then
        object.clearButtons()
        guid = object.getGUID()
    end
    local next = FindNextAi(guid,AttackSort)
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
        if isInPlay(ship) and (isAi(ship) or (isShip(ship)  and showPlayers)) and getSkill(ship)~=nil then
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
activation_started = false
function UpdatePlanningNote()
    if currentphase == PlanningSort then
        local ai_string = "*** [FF80FF]Planning Phase - Turn "..tostring(getTurnNumber()).."/"..tostring(getTotalTurns()).."[-] ***"
        local total = 0
        local ready = 0
        for i,ship in ipairs(getAllObjects()) do
            if isShip(ship) and isInPlay(ship) and not isAi(ship) then
                local status = "Waiting"
                local statuscolor = "FF0000"
                local found = ship.getVar('HasDial')
                local maneuver = ""
                --                for j,card in ipairs(getAllObjects()) do
                --                    if isInPlay(card) and card.tag ~= 'Figurine' and card.getName()==ship.getName() then
                --                        found = true
                --                    end
                --                end
                total = total + 1
                if found then
                    status = "Ready"
                    ready = ready + 1
                    statuscolor = "00FF00"
                    maneuver = " [101010]([-] "..ship.getVar('Maneuver').." [101010])[-]"
                end
                ai_string = ai_string .."\n".. prettyString(ship, false)..maneuver.." [101010][[-]["..statuscolor.."]"..status.."[-][101010]][-]"
            end
        end
        ai_string = ai_string .. "\n" .. start_delay
        setNotes(ai_string)
        if total>0 and total == ready and not activation_started==true then
            start_delay = " . . . . . . . . . ."
            startLuaCoroutine(nil, 'delayActivation')
        end
    end
end
function delayActivation()
    activation_started = true
    for i=1, 10, 1 do
        for i=1, 20, 1 do coroutine.yield(0) end
        start_delay = string.sub(start_delay ,3)
    end
    local total = 0
    local ready = 0
    for i,ship in ipairs(getAllObjects()) do
        if isShip(ship) and isInPlay(ship) and not isAi(ship) then
            local found = ship.getVar('HasDial')
            total = total + 1
            if found then ready = ready + 1 end
        end
    end
    if total == ready then
        Action_Activation()
    end
    activation_started = false

    return true
end
function ListAis(sort)
    printToAll("Sorting AIs, Found:",{0,1,0})
    local ais = {}
    local showPlayers = true
    for i,ship in ipairs(getAllObjects()) do
        if (isAi(ship) or isShip(ship) and isInPlay(ship) and showPlayers and getSkill(ship)~=nil) then
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
    local skill_color
    if skill~="nil" then
        skill_color = skill_colors[tonumber(skill)+1]
    end
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
        return stress.."PS["..skill_color.."]"..skill.."[-] ["..type_color.."]"..type.."[-] "..squad.."#"..number..stress_end..target --,{0,0,1}
    else
        return "PS["..skill_color.."]"..skill.."[-] "..stripPS(ship.getName()).."" --,{0,0,1}
    end
end
function getSimpleAiName(ai)
    local squad = getAiSquad(ai)
    if squad == nil then squad = "" end
    local number = tostring(getAiNumber(ai))
    return squad.."#"..number
end
function stripPS(name)
    return string.gsub(name,"%[%d+%]%s*","")
end
function prettyPrint(ship)
    printToAll(prettyString(ship),{0.2, 0.2, 0.8})
end
function FindNextAi(guid, sort)
    local ais = {}
    for i,ship in ipairs(getAllObjects()) do
        if isShip(ship) and isInPlay(ship) then
            table.insert(ais, ship)
        end
    end -- [end loop for all ships]
    if guid~=nil then
        local ai = getObjectFromGUID(guid)
        if ai~=nil and not contains(ais, ai) then
            table.insert(ais, ai)
            -- printToAll("Added self",{0,1,0})
        end
    end
    table.sort(ais,sort)
    -- for i,ship in ipairs(ais) do
    -- printToAll("Searching "..prettyString(ship),{1,1,1})
    -- end
    local selffound = false
    for i,ship in ipairs(ais) do
        if selffound or guid==nil then
            if isAi(ship) then
                -- printToAll("Found Next AI: "..prettyString(ship),{0,1,0})
                return ship
            else
                -- printToAll("Found Next Player: "..prettyString(ship),{0,1,0})
                table.insert(players_up_next,ship)
                return ship
            end
        end
        if ship.getGUID()==guid then
            selffound = true
            -- printToAll("Found Self: "..prettyString(ship),{0,1,0})
        end
    end
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
function PlanningSort(a, b) end
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
    if isAi(object) then
        Render_AiFreeFocusEvade(object)
        Render_AiFreeTargetLock(object)
    end
    local movebutton = {['click_function'] = 'Action_AiMove', ['label'] = label, ['position'] = {0, 0.3, -0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 750, ['height'] = 550, ['font_size'] = 250}
    object.createButton(movebutton)
    if isAi(object) and getAiSquad(object)~=nil and squadmove[getAiSquad(object)]~=nil then
        local squadbutton = {['click_function'] = 'Action_AiSquad', ['label'] = 'Squad', ['position'] = {0, 0.3, 0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 750, ['height'] = 550, ['font_size'] = 250}
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
        Action_Combat()
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

function Render_AiUndoBoostBarrel(object)
    local undobutton = {['click_function'] = 'Action_AiUndoBoostBarrel', ['label'] = 'q', ['position'] = {-0.9, 0.3, -0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
    object.createButton(undobutton)
end

function Action_AiUndoBoostBarrel(object)

    object.clearButtons()
    object.setDescription("q")
    airollboosted[object.getGUID()]=nil
    Render_ButtonState(object)
    --    Render_Ruler(object)
    --
    --    if getAiHasBoost(object) then
    --        Render_Boost(object)
    --    end
    --
    --    if getAiHasBarrelRoll(object) then
    --        Render_BarrelRoll(object)
    --    end
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
        local decloak = {['click_function'] = 'Action_AiDecloak', ['label'] = 'decloak', ['position'] = {0, 0.3, -1.9}, ['rotation'] =  {0, 0, 0}, ['width'] = 1000, ['height'] = 300, ['font_size'] = 250}
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
    airollboosted[object.getGUID()]=true
    Render_AiUndoBoostBarrel(object)
    Render_Ruler(object)
    Render_AiFocusEvade(object)
end

function Action_AiBoostStraight(object)
    object.setDescription("s1")
    object.clearButtons()
    airollboosted[object.getGUID()]=true
    Render_AiUndoBoostBarrel(object)
    Render_Ruler(object)
    Render_AiFocusEvade(object)
end

function Action_AiBoostRight(object)
    object.setDescription("br1")
    object.clearButtons()
    airollboosted[object.getGUID()]=true
    Render_AiUndoBoostBarrel(object)
    Render_Ruler(object)
    Render_AiFocusEvade(object)
end

function Render_BarrelRoll(object)

    local xlbbutton = {['click_function'] = 'Action_AiBarrelRollLeftBack', ['label'] = 'xlb', ['position'] = {-1.6, 0.3, 0.8}, ['rotation'] =  {0, 0, 0}, ['width'] = 350, ['height'] = 300, ['font_size'] = 250}
    object.createButton(xlbbutton)

    local xlbutton = {['click_function'] = 'Action_AiBarrelRollLeft', ['label'] = 'xl', ['position'] = {-1.6, 0.3, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 350, ['height'] = 300, ['font_size'] = 250}
    object.createButton(xlbutton)

    local xlfbutton = {['click_function'] = 'Action_AiBarrelRollLeftFront', ['label'] = 'xlf', ['position'] = {-1.6, 0.3, -0.8}, ['rotation'] =  {0, 0, 0}, ['width'] = 350, ['height'] = 300, ['font_size'] = 250}
    object.createButton(xlfbutton)

    local xrbbutton = {['click_function'] = 'Action_AiBarrelRollRightBack', ['label'] = 'xrb', ['position'] = {1.6, 0.3, 0.8}, ['rotation'] =  {0, 0, 0}, ['width'] = 350, ['height'] = 300, ['font_size'] = 250}
    object.createButton(xrbbutton)
    local xrbutton = {['click_function'] = 'Action_AiBarrelRollRight', ['label'] = 'xr', ['position'] = {1.6, 0.3, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 350, ['height'] = 300, ['font_size'] = 250}
    object.createButton(xrbutton)
    local xrfbutton = {['click_function'] = 'Action_AiBarrelRollRightFront', ['label'] = 'xrf', ['position'] = {1.6, 0.3, -0.8}, ['rotation'] =  {0, 0, 0}, ['width'] = 350, ['height'] = 300, ['font_size'] = 250}
    object.createButton(xrfbutton)
end

function Action_AiBarrelRollLeftBack(object)
    object.setDescription("xlb")
    object.clearButtons()
    airollboosted[object.getGUID()]=true
    Render_AiUndoBoostBarrel(object)
    Render_Ruler(object)
    Render_AiFocusEvade(object)
end
function Action_AiBarrelRollLeft(object)
    object.setDescription("xl")
    object.clearButtons()
    airollboosted[object.getGUID()]=true
    Render_AiUndoBoostBarrel(object)
    Render_Ruler(object)
    Render_AiFocusEvade(object)
end
function Action_AiBarrelRollLeftFront(object)
    object.setDescription("xlf")
    object.clearButtons()
    airollboosted[object.getGUID()]=true
    Render_AiUndoBoostBarrel(object)
    Render_Ruler(object)
    Render_AiFocusEvade(object)
end

function Action_AiBarrelRollRightBack(object)
    object.setDescription("xrb")
    object.clearButtons()
    airollboosted[object.getGUID()]=true
    Render_AiUndoBoostBarrel(object)
    Render_Ruler(object)
    Render_AiFocusEvade(object)
end
function Action_AiBarrelRollRight(object)
    object.setDescription("xr")
    object.clearButtons()
    airollboosted[object.getGUID()]=true
    Render_AiUndoBoostBarrel(object)
    Render_Ruler(object)
    Render_AiFocusEvade(object)
end
function Action_AiBarrelRollRightFront(object)
    object.setDescription("xrf")
    object.clearButtons()
    airollboosted[object.getGUID()]=true
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
function Render_AiFreeFocusEvade(object)
    local type = getAiType(object);
    if type=="INT" then
        local focusbutton = {['click_function'] = 'Action_Focus', ['label'] = 'F', ['position'] = {1.0, 0.3, -0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
        object.createButton(focusbutton)
    end
    if type=="PHA" then
        local evadebutton = {['click_function'] = 'Action_Evade', ['label'] = 'E', ['position'] = {1.0, 0.3, 0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 250}
        object.createButton(evadebutton)
    end
end
function Render_AiFreeTargetLock(object)
    local type = getAiType(object);
    if type=="SHU" or type=="DEF" or type=="BOM" or type=="ADV" or type=="DEC" then
        local tlbutton = {['click_function'] = 'Action_TargetLock', ['label'] = 'TL', ['position'] = {-1.2, 0.3, -0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 350, ['height'] = 530, ['font_size'] = 250}
        object.createButton(tlbutton)
        local tlbutton = {['click_function'] = 'RulerButton', ['label'] = 'R', ['position'] = {1.2, 0.3, -0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 350, ['height'] = 530, ['font_size'] = 250}
        object.createButton(tlbutton)
    end
end

function Action_TargetLock(object)
    local target = findAiTarget(object.getGUID())
    local dist = realDistance(target.getGUID(),object.getGUID())
    if target~=nil and dist<10.9 then
        take(enemy_target_locks, target.getGUID(),0.37,1,-0.37,true,"Red",getSimpleAiName(object))
        notify(object.getGUID(),'action','acquires a target lock')
    else
        notify(object.getGUID(),'action','has no target')
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
function findNearestShip(pos)
    local nearest
    local minDist = 999999
    for i,ship in ipairs(getAllObjects()) do
        if isShip(ship) then
            local distance = distance(pos[1],pos[3],ship.getPosition()[1],ship.getPosition()[3])
            if distance<minDist then
                minDist = distance
                nearest = ship
            end
        end
    end
    return nearest
end
function findNearestPlayer(guid)
    local ai  = getObjectFromGUID(guid)
    local inarc = getAiType(ai) ~= "DEC"
    local distances = {}
    local angles = {}

    for i,ship in ipairs(getAllObjects()) do
        if isShip(ship) and not isAi(ship) and isInPlay(ship) then
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
    if isBigShip(object.getGUID()) then scalar = 1.63 end
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
    if isBigShip(a.getGUID()) then dist = dist - 2.1 else dist = dist - 1.1 end
    if isBigShip(b.getGUID()) then dist = dist - 2.1 else dist = dist - 1.1 end
    return dist
end

function isShip(ship)
    return ship.tag == 'Figurine' and ship.name ~= '' -- and isInPlay(ship)
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
    if ai == nil then return nil end
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
--function containsByKey(self, val, key)
--    for index, value in ipairs (self) do
--        if value[key] == val[key] then
--            return true
--        end
--    end
--
--    return false
--end
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
    printToAll("[" .. os.date("%H:%M:%S") .. "] " .. string,{0.2, 0.2, 0.8})
end

function onObjectEnterScriptingZone_ai(zone, object)
    if zone.getGUID() == missionzone and object~=nil and object.tag == 'Card' and object.getName():match '^Mission: (.*)' then
        object.clearButtons()
        local p = {['click_function'] = 'Action_presetup', ['label'] = 'Pre-Setup', ['position'] = {0, 0.5, -1.0}, ['rotation'] =  {0, 0, 0}, ['width'] = 800, ['height'] = 200, ['font_size'] = 180}
        object.createButton(p)
        local p = {['click_function'] = 'Action_setupclear', ['label'] = 'Clear', ['position'] = {0, 0.5, -0.2}, ['rotation'] =  {0, 0, 0}, ['width'] = 800, ['height'] = 200, ['font_size'] = 180}
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
ELITE_ICON = "http://i.imgur.com/n9dywTO.png"

core_source = nil
tfa_source = nil
debris_source = nil
r1 = 3.75
v = {
    _0000 = {x=0, y=4.5, rot=180}, --N
    _0020 = {x=1, y=4.5, rot=180},
    _0030 = {x= 1.5, y= 4.5, rot=180}, --v4 in Local Trouble
    _0040 = {x=2, y=4.5, rot=180},
    _0100 = {x=3, y=4.5, rot=180},
    _0130 = {x= 4.5, y= 4.5, rot=225}, --upper right corner
    _0130S = {x= 4, y= 4.5, rot=180}, --upper left corner facing south
    _0200 = {x= 4.5, y= 3.0, rot=270},
    _0230 = {x= 4.5, y= 1.5, rot=270}, --v5 in Local Trouble
    _0240 = {x= 4.5, y= 1, rot=270},
    _0300 = {x= 4.5, y= 0, rot=270}, --E
    _0330 = {x= 4.5, y= -1.5, rot=270}, --v6 in Local Trouble
    _0400 = {x= 4.5, y= -3.0, rot=270},

    _0600 = {x= 0, y= -4.5, rot=0}, --S

    _0800 = {x= -4.5, y= -3.0, rot=90},
    _0830 = {x= -4.5, y= -1.5, rot=90}, --v1 in Local Trouble
    _0900 = {x= -4.5, y= 0, rot=90}, --W
    _0920 = {x= -4.5, y= 1, rot=90},
    _0930 = {x= -4.5, y= 1.5, rot=90}, --v2 in Local Trouble
    _1000 = {x= -4.5, y= 3.0, rot=90},
    _1030 = {x= -4.5, y= 4.5, rot=135}, --upper left corner
    _1030S = {x= -4, y= 4.5, rot=180}, --upper left corner facing south
    _1100 = {x = -3, y = 4.5, rot=180},
    _1120 = {x = -2, y = 4.5, rot=180},
    _1130 = {x= -1.5, y= 4.5, rot=180}, --v3 in Local Trouble
    _1200 = {x=0, y=4.5, rot=180}, --N
    bay1 = {x=-1, y=0, rot = 210},
    bay2 = {x=1, y=3, rot = 30}
}
local squads = {}
local missionsquads = {}
local missionvectors = {}
local decks = {}
local cards = {}
local shipnum = 1
local asteroid_min_x = -9.2
local asteroid_max_x = 9.2
local asteroid_min_y = -9.2
local asteroid_max_y = 9.2
local num_asteroids = 6
local num_debris = 0
local card_to_clear
function Action_presetup(object)
    CountPlayers()
    CalculatePlayerSkill()
    --BAD
    --object.clearButtons()

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
    local p = {['click_function'] = 'Action_setup', ['label'] = 'Setup', ['position'] = {0, 0.5, -0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 800, ['height'] = 200, ['font_size'] = 180}
    object.createButton(p)
end
function CountPlayers()
    local count = 0
    for i,ship in ipairs(getAllObjects()) do
        if ship.tag == 'Figurine' and not isAi(ship) and getSkill(ship) ~= nil and isInPlay(ship) then
            count = count + 1
            printToAll("Found: "..ship.getName(),{0,1,1})
        end
    end
    printToAll("Total Players: "..count,{0,1,1})
    mission_players = count
    return count
end
function CalculatePlayerSkill()
    local count = 0
    local ps = 0
    for i,ship in ipairs(getAllObjects()) do
        if ship.tag == 'Figurine' and not isAi(ship) and getSkill(ship) ~= nil and isInPlay(ship) then
            count = count + 1
            ps = ps + getSkill(ship)
        end
    end
    local avg_ps = math.floor(ps/count)
    printToAll("Average Pilot Skill: "..avg_ps,{0,1,1})
    mission_ps = avg_ps
    return avg_ps
end
function Action_setupclear(object)
    for i,obj in ipairs(getAllObjects()) do
        local pos = obj.getPosition()
        --is in play or ai setup
        if pos[1]>-16.5 and pos[3]>-16.5 and pos[3]<16.5 then
            --is AI, card, or damage marker
            if isAi(obj) or obj.tag=="Card" or obj.tag=="Deck" or obj.tag=="Chip" or obj.getName():match "Asteroid"or obj.getName():match "Debrisfield" then
                obj.destruct()
                --is player
            elseif not isAi(obj) and isShip(obj) and getSkill(obj)~=nil then
                local newpos = obj.getPosition()
                obj.setPosition({newpos[1],newpos[2],-16})
                obj.setRotation({0,180,0})
                obj.unlock()
            end
        end
    end
end
function Action_setup(object)
    --BAD
    --object.clearButtons()
    if mission_ps == nil or mission_players == nil then
        printToAll("Must select Number of players and Average Player Skill", {1,0,0})
    else
        local mission = object.getName():match '^Mission: (.*)'
        --local squads = {}
        missionsquads = {}
        missionvectors = {}
        decks = {}
        cards = {}
        squads = {}
        shipnum = 1
        asteroid_min_x = -9.2
        asteroid_max_x = 9.2
        asteroid_min_y = -9.2
        asteroid_max_y = 9.2
        num_asteroids = 0
        num_debris = 0
        local rule_page
        local turns = 12
        printToAll("Setting up: "..mission, {0,1,0})
        if mission == "Local Trouble" then
            turns = 10
            num_asteroids = 6
            rule_page = 46
            table.insert(missionsquads, {name="Alpha",turn=0,vector=3,ai="attack",type="TIE",count={1,1,0,1,0,1}, elite=false})
            table.insert(missionsquads, {name="Beta",turn=0,vector=4,ai="attack",type="TIE",count={1,0,1,0,1,0}, elite=false})
            table.insert(missionsquads, {name="Gamma",turn=4,vector="1d6",ai="attack",type="INT",count={1,0,0,1,0,0}, elite=false})
            table.insert(missionsquads, {name="Delta",turn=7,vector="1d6",ai="attack",type="TIE",count={0,1,1,0,1,1}, elite=false})
            --            table.insert(missionvectors, {x=-4.5, y=-1.5, rot=90})
            --            table.insert(missionvectors, {x=-4.5, y= 1.5, rot=90})
            --            table.insert(missionvectors, {x=-1.5, y= 4.5, rot=180})
            --            table.insert(missionvectors, {x= 1.5, y= 4.5, rot=180})
            --            table.insert(missionvectors, {x= 4.5, y= 1.5, rot=-90})
            --            table.insert(missionvectors, {x= 4.5, y=-1.5, rot=-90})
            missionvectors = {v._0830,v._0930, v._1130, v._0030,v._0230,v._0330}
        end
        if mission == "Rescue Rebel Operatives" then
            turns = 10
            num_asteroids = 6
            table.insert(missionsquads, {name="Alpha",turn=0,vector=3,ai="strike",type="TIE",count={1,1,0,1,0,1}, elite=false})
            table.insert(missionsquads, {name="Beta",turn=0,vector=4,ai="strike",type="TIE",count={1,1,1,0,1,0}, elite=false})
            table.insert(missionsquads, {name="Elite",turn=3,vector="1d6",ai="attack",type="INT",count={1,0,0,0,0,0}, elite=true})
            table.insert(missionsquads, {name="Gamma",turn=5,vector="1d6",ai="strike",type="TIE",count={1,1,-6,1,-4,1}, elite=false})
            table.insert(missionsquads, {name="Gamma",turn=5,vector="1d6",ai="strike",type="INT",count={0,0,6,0,4,0}, elite=false})
            table.insert(missionsquads, {name="Delta",turn=7,vector="1d6",ai="strike",type="TIE",count={1,-8,1,-6,1,1}, elite=false})
            table.insert(missionsquads, {name="Delta",turn=7,vector="1d6",ai="strike",type="INT",count={0,8,0,6,0,0}, elite=false})
            missionvectors = {v._0830,v._0930, v._1030S, v._0130S,v._0230,v._0330}
            --TODO implement spawning HWK-290
        end
        if mission == "Disable Sensor Net" then
            turns = 12
            num_asteroids = 12
            asteroid_min_x = -9.2 - r1
            asteroid_max_x = 9.2 + r1
            asteroid_min_y = -9.2 - r1
            asteroid_max_y = 9.2 + r1
            table.insert(missionsquads, {name="Alpha",turn=0,vector=2,ai="attack",type="TIE",count={1,1,-6,1,-4,1}, elite=false})
            table.insert(missionsquads, {name="Alpha",turn=0,vector=2,ai="attack",type="INT",count={0,0,6,0,4,0}, elite=false})
            table.insert(missionsquads, {name="Beta",turn=0,vector=5,ai="attack",type="TIE",count={1,1,1,-6,1,-4}, elite=false})
            table.insert(missionsquads, {name="Beta",turn=0,vector=5,ai="attack",type="INT",count={0,0,0,6,0,4}, elite=false})
            table.insert(missionsquads, {name="Patrol",turn=1,vector="1d6",ai="attack",type="INT",count={1,0,0,0,0,0}, elite=false})
            table.insert(missionsquads, {name="Elite",turn=2,vector="1d6",ai="attack",type="*",count={1,0,0,0,0,0}, elite=true})
            missionvectors = {v._0830,v._0930, v._1130, v._0030,v._0230,v._0330}
            --TODO: implement spawning Sensor Beacons
            --TODO implement spawning HWK-290
        end

        if mission == "Capture Refueling Station" then
            turns = 12
            num_asteroids = 6
            asteroid_min_x = -9.2 - r1
            asteroid_max_x = 9.2 + r1
            asteroid_min_y = -9.2 - r1
            asteroid_max_y = 9.2 - r1*3
            table.insert(missionsquads, {name="Alpha",turn=0,vector="bay1",ai="attack",type="TIE",count={1,-8,1,-6,1,1}, elite=false})
            table.insert(missionsquads, {name="Alpha",turn=0,vector="bay1",ai="attack",type="INT",count={0,8,0,6,0,0}, elite=false})
            table.insert(missionsquads, {name="Beta",turn=0,vector="bay2",ai="attack",type="INT",count={0,1,0,1,0,1}, elite=false})
            table.insert(missionsquads, {name="Gamma",turn=4,vector="bay1",ai="attack",type="TIE",count={1,1,-6,1,-4,1}, elite=false})
            table.insert(missionsquads, {name="Gamma",turn=4,vector="bay1",ai="attack",type="ADV",count={0,0,6,0,4,0}, elite=false})
            table.insert(missionsquads, {name="Delta",turn=5,vector="bay2",ai="attack",type="BOM",count={1,0,1,0,1,0}, elite=false})
            table.insert(missionsquads, {name="Elite",turn=8,vector="1d6",ai="attack",type="*",count={1,0,0,0,0,0}, elite=true})
            missionvectors = {v._0800,v._0900, v._1000, v._0200,v._0300,v._0400, bay1 = v.bay1, bay2 = v.bay2}
            --TODO: implement spawning refueling station

        end
        if mission == "Tread Softly" then
            turns = 12
            table.insert(missionsquads, {name="Minelayer",turn=0,vector=3,ai="attack",type="BOM",count={1,8,1,0,1,0}, elite=false})
            table.insert(missionsquads, {name="Alpha",turn=0,vector=5,ai="attack",type="TIE",count={1,1,-6,1,-4,1}, elite=false})
            table.insert(missionsquads, {name="Alpha",turn=0,vector=5,ai="attack",type="INT",count={0,0,6,0,4,0}, elite=false})
            table.insert(missionsquads, {name="Elite",turn=5,vector="1d6",ai="attack",type="BOM",count={1,0,0,0,0,0}, elite=true})
            table.insert(missionsquads, {name="Beta",turn=7,vector="1d6",ai="attack",type="TIE",count={1,1,8,1,6,1}, elite=false})
            missionvectors = {v._0830,v._0930, v._1130, v._0030,v._0230,v._0330}
            --TODO: implement minefield spawning

        end
        if mission == "Imperial Entanglements" then
            turns = 10
            table.insert(missionsquads, {name="Alpha",turn=0,vector=2,ai="attack",type="INT",count={1,0,6,1,0,4}, elite=false})
            table.insert(missionsquads, {name="Beta",turn=0,vector=4,ai="attack",type="TIE",count={1,1,0,1,0,1}, elite=false})
            table.insert(missionsquads, {name="Gamma",turn=3,vector="1d3",ai="strike",type="BOM",count={1,0,1,8,1,0}, elite=false})
            table.insert(missionsquads, {name="Decimator",turn=6,vector="c",ai="strike",type="DEC",count={1,0,0,0,0,0}, elite=false})
            table.insert(missionsquads, {name="Delta",turn=6,vector="1d6",ai="attack",type="TIE",count={8,1,-6,1,-4,1}, elite=false})
            table.insert(missionsquads, {name="Delta",turn=6,vector="1d6",ai="attack",type="*",count={0,0,1,0,1,0}, elite=false})

            missionvectors = {v._0630, v._0830,v._0930, v._1130, v._0030,v._0230,v._0330,c = v._0730}
            --TODO: implement minefield spawning
            --TODO: implement Transport spawning
            --TODO: implement Decimator spawning
            --TODO: implement spawning Ion Pulse Missile
        end
        if mission == "Care Package" then
            turns = 10
            num_asteroids = 12
            asteroid_min_x = -9.2 - r1
            asteroid_max_x = 9.2 + r1
            table.insert(missionsquads, {name="Alpha",turn=0,vector=3,ai="attack",type="TIE",count={1,1,1,-6,1,-4}, elite=false})
            table.insert(missionsquads, {name="Alpha",turn=0,vector=3,ai="attack",type="INT",count={0,0,0,6,0,4}, elite=false})
            table.insert(missionsquads, {name="Beta",turn=0,vector=4,ai="attack",type="TIE",count={1,1,-8,1,-4,1}, elite=false})
            table.insert(missionsquads, {name="Beta",turn=0,vector=4,ai="attack",type="INT",count={0,0,8,0,4,0}, elite=false})
            table.insert(missionsquads, {name="Assault1",turn=3,vector="*",ai="strike",type="BOM",count={1,8,1,0,1,0}, elite=false})
            table.insert(missionsquads, {name="Elite",turn=3,vector="1d6",ai="attack",type="*",count={1,0,0,0,0,0}, elite=true})
            table.insert(missionsquads, {name="Gamma",turn=6,vector="1d6",ai="attack",type="TIE",count={1,-8,1,-6,1,-4}, elite=false})
            table.insert(missionsquads, {name="Gamma",turn=6,vector="1d6",ai="attack",type="INT",count={0,8,0,6,0,4}, elite=false})
            table.insert(missionsquads, {name="Assault2",turn=6,vector="*",ai="srike",type="BOM",count={6,1,0,1,0,1}, elite=false})
            missionvectors = {v._0600, v._0730,v._0900, v._1200, v._0130,v._0300}
            --TODO: implement Transport spawning
            --TODO: implement spawning proton torpedo
        end
        if mission == "Needle in a Haystack" then
            turns = 12
            table.insert(missionsquads, {name="Alpha",turn=0,vector=3,ai="strike",type="TIE",count={1,1,0,1,0,1}, elite=false})
            table.insert(missionsquads, {name="Alpha",turn=0,vector=3,ai="strike",type="*",count={0,0,8,0,6,0}, elite=false})
            table.insert(missionsquads, {name="Beta",turn=0,vector=4,ai="strike",type="TIE",count={1,1,1,0,1,0}, elite=false})
            table.insert(missionsquads, {name="Beta",turn=0,vector=4,ai="strike",type="*",count={0,0,0,6,0,4}, elite=false})
            table.insert(missionsquads, {name="Gamma",turn=5,vector="1d6",ai="strike",type="TIE",count={1,1,0,1,0,0}, elite=false})
            table.insert(missionsquads, {name="Delta",turn=8,vector="1d6",ai="strike",type="*",count={1,0,1,0,1,0}, elite=false})
            table.insert(missionsquads, {name="Phantom",turn="*",vector="1d6",ai="attack",type="PHA",count={1,0,0,1,0,0}, elite=false})

            missionvectors = {v._0830,v._0930, v._1130, v._0030,v._0230,v._0330}
            --TODO: implement ion storm spawning
            --TODO: implement tracking token spawning
            --TODO: implement Assault Ship spawning
        end
        if mission == "Bait" then
            turns = 10
            num_asteroids = 6
            asteroid_min_x = -9.2 - r1
            asteroid_max_x = 9.2 + r1
            asteroid_min_y = -9.2 - r1
            asteroid_max_y = 9.2 + r1
            table.insert(missionsquads, {name="Alpha",turn=0,vector="1d6",ai="attack",type="TIE",count={1,1,1,-4,1,-8}, elite=false})
            table.insert(missionsquads, {name="Alpha",turn=0,vector="1d6",ai="attack",type="*",count={0,0,0,4,0,8}, elite=false})
            table.insert(missionsquads, {name="Beta",turn=0,vector="1d6+6",ai="attack",type="TIE",count={1,1,-8,1,-6,1}, elite=false})
            table.insert(missionsquads, {name="Beta",turn=0,vector="1d6+6",ai="attack",type="*",count={0,0,8,0,6,0}, elite=false})
            table.insert(missionsquads, {name="SupportA",turn=3,vector="1d6",ai="attack",type="SHU",count={0,1,0,0,0,0}, elite=false})
            table.insert(missionsquads, {name="SupportB",turn=3,vector="*",ai="attack",type="SHU",count={0,0,0,0,1,0}, elite=false})
            table.insert(missionsquads, {name="Elite",turn=4,vector="1d12",ai="*",type="PHA",count={1,0,0,0,0,0}, elite=true})
            table.insert(missionsquads, {name="Gamma",turn=6,vector="1d6",ai="attack",type="TIE",count={1,1,1,-8,1,-6}, elite=false})
            table.insert(missionsquads, {name="Gamma",turn=6,vector="1d6",ai="attack",type="*",count={0,0,0,8,0,6}, elite=false})
            table.insert(missionsquads, {name="Delta",turn=8,vector="1d6+6",ai="attack",type="TIE",count={1,1,-6,1,-4,1}, elite=false})
            table.insert(missionsquads, {name="Delta",turn=8,vector="1d6+6",ai="attack",type="*",count={0,0,6,0,4,0}, elite=false})
            --TODO: implement random filtering (not shuttle/phantom)
            missionvectors = {v._0730,v._0830,v._0930,v._1030,v._1130, v._0030,v._0130,v._0230,v._0330,v._0430,v._0530,v._0630}
            --TODO: implement Transport spawning
            --TODO: implement starting cloaked
            --TODO: implement spawning shuttle abilities
        end
        if mission == "Cloak and Dagger" then
            turns = 12
            table.insert(missionsquads, {name="Alpha",turn=0,vector=3,ai="attack",type="PHA",count={1,8,1,0,0,0}, elite=false})
            table.insert(missionsquads, {name="Beta",turn=4,vector="1d6",ai="attack",type="TIE",count={1,1,-6,1,-8,1}, elite=false})
            table.insert(missionsquads, {name="Beta",turn=4,vector="1d6",ai="attack",type="*",count={0,0,6,0,8,0}, elite=false})
            --TODO: implement random filtering (not shuttle/phantom)
            table.insert(missionsquads, {name="Gamma",turn=8,vector="1d6",ai="attack",type="TIE",count={1,1,1,-4,1,-6}, elite=false})
            table.insert(missionsquads, {name="Gamma",turn=8,vector="1d6",ai="attack",type="INT",count={0,0,0,4,0,6}, elite=false})

            missionvectors = {v._0830,v._0930, v._1130, v._0030,v._0230,v._0330}
            --TODO: implement ion storm spawning
            --TODO: implement spawning partial stations on side
        end
        if mission == "Revenge" then
            turns = 10
            table.insert(missionsquads, {name="Aces",turn=1,vector="1d12",ai="strike",type="INT",count={1,1,1,1,1,1}, elite=true})
            --TODO: implement ion storm spawning
            --TODO: elites match player PS
            --TODO: implement multistrike
        end
        if mission == "Capture Officer" then
            turns = 12
            num_asteroids = 6
            asteroid_min_x = -9.2 - r1
            asteroid_max_x = 9.2 + r1
            asteroid_min_y = -9.2 - r1
            asteroid_max_y = 9.2 + r1
            table.insert(missionsquads, {name="Shuttle",turn=0,vector=7,ai="attack",type="SHU",count={1,0,0,0,0,0}, elite=false})
            table.insert(missionsquads, {name="Alpha",turn=0,vector=7,ai="attack",type="TIE",count={1,1,0,1,0,1}, elite=false})
            table.insert(missionsquads, {name="Elite",turn=2,vector="1d6",ai="attack",type="ADV",count={1,0,0,0,0,0}, elite=true})
            table.insert(missionsquads, {name="Beta",turn=4,vector="1d6",ai="attack",type="TIE",count={1,-6,1,-8,1,-4}, elite=false})
            table.insert(missionsquads, {name="Beta",turn=4,vector="1d6",ai="attack",type="*",count={0,6,0,8,0,4}, elite=false})
            table.insert(missionsquads, {name="Gamma",turn=8,vector="1d6",ai="attack",type="TIE",count={1,-4,1,-6,1,-8}, elite=false})
            table.insert(missionsquads, {name="Gamma",turn=8,vector="1d6",ai="attack",type="INT",count={0,4,0,6,0,8}, elite=false})
            table.insert(missionsquads, {name="Delta",turn=11,vector="1d6",ai="attack",type="INT",count={1,1,0,1,0,1}, elite=false})
            missionvectors = {v._0530,v._0630,v._0930, v._1130, v._0030,v._0230, {x=0, y=-1,rot=180}}
        end
        if mission == "Nobody Home" then
            turns = 10
            num_asteroids = 6
            num_debris = 6
            asteroid_min_x = -9.2 - r1
            asteroid_max_x = 9.2 + r1
            asteroid_min_y = -9.2 - r1
            asteroid_max_y = 9.2 + r1
            table.insert(missionsquads, {name="Obstacle",turn=0,vector=6,ai="stiketarget",type="SHU",count={1,0,0,0,0,0}, elite=false})
            table.insert(missionsquads, {name="Alpha",turn=0,vector=1,ai="strike",type="INT",count={1,0,0,8,1,0}, elite=false})
            table.insert(missionsquads, {name="Beta",turn=0,vector=2,ai="strike",type="INT",count={0,6,1,0,0,1}, elite=false})
            table.insert(missionsquads, {name="Delta",turn=0,vector=3,ai="strike",type="TIE",count={1,1,-4,1,-8,1}, elite=false})
            table.insert(missionsquads, {name="Delta",turn=0,vector=3,ai="strike",type="*",count={0,0,4,0,8,0}, elite=false})
            table.insert(missionsquads, {name="Command",turn=0,vector=4,ai="strike",type="SHU",count={1,0,0,0,0,0}, elite=true})
            table.insert(missionsquads, {name="Epsilon",turn=0,vector=5,ai="strike",type="TIE",count={1,1,1,-6,1,-4}, elite=false})
            table.insert(missionsquads, {name="Epsilon",turn=0,vector=5,ai="strike",type="*",count={0,0,0,6,0,4}, elite=false})
            missionvectors = {v._1100,v._1120,v._0020, v._0040, v._0100, {x=0, y=-2,rot=180}}
        end
        if mission == "Miners' Strike" then
            turns = 12
            table.insert(missionsquads, {name="Cargo",turn=0,vector=7,ai="flee",type="SHU",count={1,0,0,0,0,0}, elite=false})
            table.insert(missionsquads, {name="Cargo",turn=0,vector=8,ai="flee",type="SHU",count={0,0,0,1,0,0}, elite=false})
            table.insert(missionsquads, {name="Alpha",turn=0,vector=2,ai="attack",type="TIE",count={1,0,1,0,1,0}, elite=false})--2/3?
            table.insert(missionsquads, {name="Beta",turn=0,vector=4,ai="attack",type="TIE",count={0,1,0,1,0,1}, elite=false})--4/5?
            table.insert(missionsquads, {name="Gamma",turn=6,vector="1d6",ai="attack",type="TIE",count={1,-6,1,-8,1,-4}, elite=false})
            table.insert(missionsquads, {name="Gamma",turn=6,vector="1d6",ai="attack",type="*",count={0,6,0,8,0,4}, elite=false})
            table.insert(missionsquads, {name="Delta",turn=8,vector="1d6",ai="attack",type="TIE",count={1,-8,1,-4,1,-6}, elite=false})
            table.insert(missionsquads, {name="Delta",turn=8,vector="1d6",ai="attack",type="*",count={0,8,0,4,0,6}, elite=false})

            --TODO: spawn station components
            missionvectors = {v._0630,v._0830,v._0930, v._1130, v._0030,v._0230,{x=0,y=3,rot=180},{x=2,y=2,rot=270}}
        end
        if mission == "Secure Holonet Receiver" then
            turns = 12
            num_asteroids = 6
            asteroid_min_x = -9.2 - r1
            asteroid_max_x = 9.2 + r1
            asteroid_min_y = -9.2 - r1
            asteroid_max_y = 9.2 + r1
            table.insert(missionsquads, {name="Alpha",turn=0,vector=2,ai="attack",type="TIE",count={1,1,-8,1,-6,1}, elite=false})
            table.insert(missionsquads, {name="Alpha",turn=0,vector=2,ai="attack",type="*",count={0,0,8,0,6,0}, elite=false})
            table.insert(missionsquads, {name="Beta",turn=0,vector=5,ai="attack",type="TIE",count={1,1,1,-6,1,-4}, elite=false})
            table.insert(missionsquads, {name="Beta",turn=0,vector=5,ai="attack",type="*",count={0,0,0,6,0,4}, elite=false})
            table.insert(missionsquads, {name="Gamma",turn=4,vector="1d6",ai="attack",type="TIE",count={0,1,0,1,0,1}, elite=false})
            table.insert(missionsquads, {name="Gamma",turn=4,vector="1d6",ai="attack",type="INT",count={8,0,4,0,6,0}, elite=false})
            --TODO: Spawn Satellite Relays
            --TODO: Spawn Station
            --TODO: spawn HWK-290
            missionvectors = {v._0600,v._0730,v._0900, v._0000,v._0130,v._0300}
        end
        if mission == "Defector" then
            turns = 10
            num_asteroids = 6
            table.insert(missionsquads, {name="Prototype",turn=0,vector=4,ai="attack",type="DEF",count={1,1,0,1,0,1}, elite=false})
            table.insert(missionsquads, {name="Alpha",turn=0,vector=1,ai="attack",type="TIE",count={1,1,1,-8,1,-6}, elite=false})
            table.insert(missionsquads, {name="Alpha",turn=0,vector=1,ai="attack",type="*",count={0,0,0,8,0,6}, elite=false})
            table.insert(missionsquads, {name="Beta",turn=0,vector=6,ai="attack",type="TIE",count={1,1,1,-6,1,-4}, elite=false})
            table.insert(missionsquads, {name="Beta",turn=0,vector=6,ai="attack",type="*",count={0,0,0,6,0,4}, elite=false})
            table.insert(missionsquads, {name="Gamma",turn=4,vector=3,ai="attack",type="SHU",count={1,0,0,0,0,0}, elite=false})
            table.insert(missionsquads, {name="Gamma",turn=4,vector=3,ai="attack",type="TIE",count={0,0,1,6,1,4}, elite=false})
            table.insert(missionsquads, {name="Delta",turn=8,vector="1d6",ai="attack",type="TIE",count={1,-8,1,-6,1,-4}, elite=false})
            table.insert(missionsquads, {name="Delta",turn=8,vector="1d6",ai="attack",type="*",count={0,8,0,6,0,4}, elite=false})
            --TODO: implement random filters
            missionvectors = {v._0920,v._1030S,v._1130,v._0030,v._0130S,v._0240}

        end
        if mission == "Pride of the Empire" then
            turns = 12
            num_asteroids = 6
            asteroid_min_x = -9.2 - r1
            asteroid_max_x = 9.2 + r1
            asteroid_min_y = -9.2 - r1
            asteroid_max_y = 9.2 + r1
            -- c = 13, d = 14, e = 15, f = 16, center = 17
            table.insert(missionsquads, {name="Instructor",turn=0,vector=17,ai="attack",type="SHU",count={1,0,0,0,0,0}, elite=false})
            table.insert(missionsquads, {name="Alpha",turn=0,vector=13,ai="attack",type="DEF",count={1,0,0,0,0,0}, elite=true})
            table.insert(missionsquads, {name="Alpha",turn=0,vector=13,ai="attack",type="TIE",count={0,0,1,0,1,0}, elite=false})
            table.insert(missionsquads, {name="Beta",turn=0,vector=14,ai="attack",type="DEF",count={0,0,0,1,0,0}, elite=true})
            table.insert(missionsquads, {name="Beta",turn=0,vector=14,ai="attack",type="TIE",count={1,1,0,0,0,0}, elite=false})
            table.insert(missionsquads, {name="Gamma",turn=0,vector=15,ai="attack",type="DEF",count={0,0,1,0,0,0}, elite=true})
            table.insert(missionsquads, {name="Gamma",turn=0,vector=15,ai="attack",type="TIE",count={1,0,0,0,1,0}, elite=false})
            table.insert(missionsquads, {name="Delta",turn=0,vector=16,ai="attack",type="DEF",count={0,0,0,0,0,1}, elite=true})
            table.insert(missionsquads, {name="Delta",turn=0,vector=16,ai="attack",type="TIE",count={0,1,0,1,0,0}, elite=false})
            table.insert(missionsquads, {name="Epsilon",turn=8,vector="1d12",ai="attack",type="INT",count={1,0,1,0,1,0}, elite=false})
            table.insert(missionsquads, {name="Epsilon",turn=8,vector="1d12",ai="attack",type="TIE",count={0,8,0,6,0,4}, elite=false})
            missionvectors = {v._0730,v._0830,v._0930,v._1030,v._1130,v._0030,v._0130,v._0230,v._0330,v._0430,v._0530,v._0630,
                {x=-1.5, y=1.5,rot=90}, --C
                {x=-1.5, y=-1.5,rot=180}, --D
                {x=1.5,y=-1.5,rot=270}, --E
                {x=1.5,y=1.5,rot=0}, --F
                {x=0,y=0,rot=180}    --center
            }
        end
        if mission == "Test" then
            --            shipnum = 1
            --            Spawn_Squad(1,"TIE","Alpha",4, false)
            --            Spawn_Squad(2,"INT","Beta",3, false)
            --            Spawn_Squad(3,"ADV","Beta",2, false)
            --            Spawn_Squad(4,"BOM","Gamma",1, false)
            --            Spawn_Squad(5,"DEF","Gamma",3, false)
            --            Spawn_Squad(6,"PHA","Gamma",4, false)
            --            Spawn_Squad(7,"SHU","Gamma",1, false)
            --            Spawn_Squad(8,"DEC","Gamma",1, false)
        end

        for i,squad in ipairs(missionsquads) do
            Spawn_Squad(squad)
        end
        --        local rules1 = findObjectByName("Rules Page 1")
        --        rules1.setState(rule_page)
        --        local rules2 = findObjectByName("Rules Page 2")
        --        rules2.setState(rule_page+1)
        startLuaCoroutine(nil, 'spawnAllAsteroidsCoroutine')
        turn_marker.setPosition({turn_marker.getPosition()[1],turn_marker.getPosition()[2],13.3})
        end_marker.setPosition({end_marker.getPosition()[1],end_marker.getPosition()[2],13.3-2.59*(turns-1)})
        -- Spawn_Card(nil,nil,nil)
    end
end
function mod(a,b)
    return a - math.floor(a/b)*b
end
local asteroids = {}
function spawnAllAsteroidsCoroutine()
    asteroids = {}
    local core_source = findObjectByNameAndType("Core Set Asteroids","Infinite")
    local tfa_source = findObjectByNameAndType("TFA Set Asteroids","Infinite")
    local debris_source = findObjectByNameAndType("Debris Fields","Infinite")
    for i=1,num_asteroids,1 do
        local i_source = math.random(2)
        local i_roll = math.random(6)
        local params = {}
        --local x = asteroid_min_x + (asteroid_max_x - asteroid_min_x)*math.random()
        --local y = asteroid_min_y + (asteroid_max_y - asteroid_min_y)*math.random()
        params.position = findClearPosition()
        params.rotation = {0,math.random(360),0}
        params.callback = 'setAsteroidState'
        params.callback_owner = Global
        --        local callback_params = {}
        --        --local state = mod(i_roll-1,6)+1
        --        callback_params['index'] = i
        --        callback_params['state'] = i_roll
        params.params = {index = i, state = i_roll}
        if i_roll==1 then
            asteroids[i] = core_source.takeObject(params)
        else
            asteroids[i] = tfa_source.takeObject(params)
        end
        local type = "Core"
        if i_roll==2 then type="TFA" end
        printToAll("Spawned Asteroid ("..type.." "..i_roll..") at {"..round(params.position[1],2)..",0,"..round(params.position[3],2).."}",{0,1,0})
        for i=1, 20, 1 do
            coroutine.yield(0)
        end
    end
    for i=1,num_debris,1 do
        local i_roll = math.random(6)
        local params = {}
        params.position = findClearPosition()
        params.rotation = {0,math.random(360),0}
        params.callback = 'setAsteroidState'
        params.callback_owner = Global
        local callback_params = {}
        local state = i_roll
        callback_params['index'] = num_asteroids+i
        callback_params['state'] = state
        params.params = callback_params
        asteroids[num_asteroids+i] = debris_source.takeObject(params)
        printToAll("Spawned Asteroid (Debris "..i_roll..") at {"..round(params.position[1],2)..",0,"..round(params.position[3],2).."}",{0,1,0})
        for i=1, 20, 1 do
            coroutine.yield(0)
        end
    end
    return true
end
function findClearPosition()
    local tries = 10
    local pos
    for i=1, tries, 1 do
        local x = asteroid_min_x + (asteroid_max_x - asteroid_min_x)*math.random()
        local y = asteroid_min_y + (asteroid_max_y - asteroid_min_y)*math.random()
        pos = {x,1,y}
        if isClear(pos) then
            return pos
        end
    end
    printToAll("Couldn't find clear area after 10 tries",{1,0,0})
    return pos
end
function isClear(pos)
    for i,asteroid in ipairs(getAllObjects()) do
        if asteroid.getName():match "Asteroid" or asteroid.getName():match "DebrisField" then
            local astpos = asteroid.getPosition()
            if distance(pos[1],pos[3],astpos[1],astpos[3])<5.5 then return false end
        end
    end
    return true
end
function setAsteroidState(object, params)
    asteroids[params['index']].setState( params['state'] )
    -- printToAll("Setting '"..asteroids[params['index']].getGUID().."' to state '"..params['state'].."'",{0,1,0})
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
squad_offsets = {{0,0,0},{2.2,0,0},{0,0,2.2},{2.2,0,2.2} }

squad_types = {"INT","INT","INT","INT","INT","INT",
    "BOM","BOM","BOM","BOM","BOM","BOM",
    "ADV","ADV","ADV","ADV",
    "DEF","DEF","DEF","DEF",
    "PHA","PHA","PHA","PHA",
    "SHU","SHU","SHU","SHU" }
placement_offset = {
    {0,0,0.25},
    {1.46,0,0.25},
    {1.46,0,2.46},
    {1.46,0,2.46}
}
function Spawn_Squad(squad)
    --TODO: implement type filtering
    --One Row? +0.25
    --Two Row? +2.46
    --One column? 0
    --Two column? +1.46
    if squad.type == "*" then
        local pick = math.random(28)
        squad.type = squad_types[pick]
    end
    local quantity = countSquad(squad)
    if quantity==0 then return end
    local position = {0,0,0 }
    local temp_position = {0,0,0}
    local rotation = 0
    local card = math.random(pilot_card_num[squad.type])
    local adjust = {0,0,0}
    temp_position = calculateTempPosition(squad)
    if squad.turn==0 then
        position = calculateRealPosition(squad)
        rotation = missionvectors[squad.vector].rot
        local adjustlookup = placement_offset[quantity]
        adjust = RotateVector(adjustlookup,rotation)
    else
        position = temp_position
    end
    for i,off in ipairs(squad_offsets) do
        if i<=quantity then
            Spawn_Ship(squad.type, squad.name, squad.elite, squad.ai, card, add(add(position,off),adjust), rotation, add(temp_position,off))
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
    if squad.turn == 0 then position = add(position,{0,0,2.59}) end
    if squads[squad.turn+1]~=nil then position = add(position, {10,0,0}) end
    return position
end
function countSquad(squad)
    local number = 0
    for i,s in ipairs(squad.count) do
        if s>0 and s<=mission_ps and i<=mission_players then number = number+1 end
        if s<0 and s>=-mission_ps and i<=mission_players then number = number-1 end
    end
    return number
end
--INT 6
--BOM 6
--ADV 4
--DEF 4
--PHA 4
--SHU 4
function add(pos, offset)
    return {pos[1] + offset[1],pos[2] + offset[2],pos[3] + offset[3]}
end
function Spawn_Ship(type, name, elite, ai, card, position, rotation, temp_pos)
    local obj_parameters = {}
    obj_parameters.type = 'Custom_Model'
    obj_parameters.position = position

    obj_parameters.rotation = { 0, 180+rotation, 0 }
    local newship = spawnObject(obj_parameters)
    newship.scale({0.625,0.625,0.625})
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
    if ai=="strike" then newship.setDescription("ai strike") end
    Spawn_Card(type, name, temp_pos, shipnum, card)
    shipnum = shipnum + 1

    --newship.lock()
end
pilot_card_offsets = {TIE=0,INT=1,BOM=7,ADV=13, DEF=17, PHA=21, SHU=25 }
pilot_card_num = {TIE=1,INT=6,BOM=6,ADV=4,DEF=4,PHA=4,SHU=4}
decks = {}
cards = {}
function Spawn_Card(type, name, position, shipnum, card)
    if pilot_card_num[type]==nil then return end
    local pilots = findObjectByNameAndType("Imperial Pilots","Infinite")
    local params = {}
    -- params.position = pilots.getPosition()
    -- params.position[1] = params.position[1]+5
    -- params.position[2] = 5
    params.position = {22,5,27.2 }
    params.callback = 'drawCard'
    params.callback_owner = Global
    local index = pilot_card_offsets[type]+card-1 --math.random(pilot_card_num[type])-1
    printToAll("Drawing card "..index,{0,1,0})
    params.params = {index = index, shipnum = shipnum, name = name, position = position }
    decks[shipnum] = pilots.takeObject(params)
end
function drawCard(object, params)
    local p = {}
    p.position = add(params.position,{5,3,0}) --{22,5,14 }
    p.index = params.index
    p.callback = 'updateCard'
    p.callback_owner = Global
    p.params = params
    cards[params.shipnum] = decks[params.shipnum].takeObject(p)
end
function updateCard(object, params)
    local card = cards[params.shipnum]
    printToAll("Drawing card "..params.name.."#"..tostring(params.shipnum),{0,1,0})
    card.setName(params.name.."#"..tostring(params.shipnum))
end
function string.starts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end
function findObjectByName(name)
    for i,obj in ipairs(getAllObjects()) do
        if obj.getName()==name then return obj end
    end
end
function findObjectByNameAndType(name, type)
    for i,obj in ipairs(getAllObjects()) do
        if obj.getName()==name and obj.tag == type then return obj end
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