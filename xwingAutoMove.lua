-- X-Wing Automatic Movement - Hera Verito (Jstek), March 2016
-- X-Wing Arch and Range Ruler - Flolania, March 2016
-- X-Wing Auto Dial Integration - Flolania, March 2016
-- X-Wing AI Auto movement - Valadian, April 2016

function onload()
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

    aicard = getObjectFromGUID(aicardguid)
    if aicard then
        local flipbutton = {['click_function'] = 'Action_MovePhase', ['label'] = 'AI Move', ['position'] = {0, 0.3, -1.3}, ['rotation'] =  {0, 0, 0}, ['width'] = 1200, ['height'] = 550, ['font_size'] = 550}
        aicard.createButton(flipbutton)

        local attackbutton = {['click_function'] = 'Action_AttackPhase', ['label'] = 'AI Attack ', ['position'] = {0, 0.3, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 1200, ['height'] = 550, ['font_size'] = 550}
        aicard.createButton(attackbutton)

        local clearbutton = {['click_function'] = 'Action_ClearAi', ['label'] = 'Clear AI', ['position'] = {0, 0.3, 1.3}, ['rotation'] =  {0, 0, 0}, ['width'] = 1200, ['height'] = 550, ['font_size'] = 550}
        aicard.createButton(clearbutton)
    end
end

function PlayerCheck(Color, GUID)
    local PC = false
    if getPlayer(Color) ~= nil then
        HandPos = getPlayer(Color).getPointerPosition()
        DialPos = getObjectFromGUID(GUID).getPosition()
        if distance(HandPos['x'],HandPos['z'],DialPos['x'],DialPos['z']) < 2 then
            PC = true
        end
    end
    return PC
end

function onObjectLeaveScriptingZone(zone, object)
    if object.tag == 'Card' and object.getDescription() ~= '' then
        CardData = dialpositions[CardInArray(object.GetGUID())]
        if CardData ~= nil then
            obj = getObjectFromGUID(CardData["ShipGUID"])
            if obj.getVar('HasDial') == true then
                printToColor(CardData["ShipName"] .. ' already has a dial.', object.held_by_color, {0, 0, 1})
            else
                obj.setVar('HasDial', true)
                CardData["Color"] = object.held_by_color

                local flipbutton = {['click_function'] = 'CardFlipButton', ['label'] = 'Flip', ['position'] = {0, -1, 1}, ['rotation'] =  {0, 0, 180}, ['width'] = 750, ['height'] = 550, ['font_size'] = 550}
                object.createButton(flipbutton)
                local deletebutton = {['click_function'] = 'CardDeleteButton', ['label'] = 'Delete', ['position'] = {0, -1, -1}, ['rotation'] =  {0, 0, 180}, ['width'] = 750, ['height'] = 550, ['font_size'] = 550}
                object.createButton(deletebutton)

                object.setVar('Lock',true)
            end
        else
            printToColor('That dial was not saved.', object.held_by_color, {0, 0, 1})
        end
    end
end

function CardInArray(GUID)
    CIAPos = nil
    for i, card in ipairs(dialpositions) do
        if GUID == card["GUID"] then
            CIAPos = i
        end
    end
    return CIAPos
end

function CardFlipButton(object)
    CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        rot = getObjectFromGUID(CardData["ShipGUID"]).getRotation()
        object.setRotation({0,rot[2],0})
        object.clearButtons()
        local movebutton = {['click_function'] = 'CardMoveButton', ['label'] = 'Move', ['position'] = {0, 1, '.9'}, ['rotation'] =  {0, 0, 0}, ['width'] = 750, ['height'] = 550, ['font_size'] = 550}
        object.createButton(movebutton)
    end
end


function CardMoveButton(object)
    CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        check(CardData["ShipGUID"],object.getDescription())
        object.clearButtons()

        local deletebutton = {['click_function'] = 'CardDeleteButton', ['label'] = 'Delete', ['position'] = {'-.35', 1, 1}, ['rotation'] =  {0, 0, 0}, ['width'] = 750, ['height'] = 650, ['font_size'] = 550}
        object.createButton(deletebutton)

        local undobutton = {['click_function'] = 'CardUndoButton', ['label'] = 'q', ['position'] = {'-.9', 1, -1}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 550}
        object.createButton(undobutton)

        local focusbutton = {['click_function'] = 'CardFocusButton', ['label'] = 'F', ['position'] = {'.9', 1, -1}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 550}
        object.createButton(focusbutton)

        local stressbutton = {['click_function'] = 'CardStressButton', ['label'] = 'S', ['position'] = {'.9', 1, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 550}
        object.createButton(stressbutton)

        local evadebutton = {['click_function'] = 'CardEvadeButton', ['label'] = 'E', ['position'] = {'.9', 1, 1}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 550}
        object.createButton(evadebutton)

    end
end

function CardFocusButton(object)
    CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        take(focus, CardData["ShipGUID"],-0.5,1,-0.5)
        notify(CardData["ShipGUID"],'action','takes a focus token')
    end
end

function CardStressButton(object)
    CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        take(stress, CardData["ShipGUID"],0.5,1,0.5)
        notify(CardData["ShipGUID"],'action','takes stress')
    end
end

function CardEvadeButton(object)
    CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        take(evade, CardData["ShipGUID"],-0.5,1,0.5)
        notify(CardData["ShipGUID"],'action','takes an evade token')
    end
end

function CardUndoButton(object)
    CardData = dialpositions[CardInArray(object.GetGUID())]
    if PlayerCheck(CardData["Color"],CardData["GUID"]) == true then
        check(CardData["ShipGUID"],'undo')
        object.removeButton(1)
    end
end

function CardDeleteButton(object)
    CardData = dialpositions[CardInArray(object.GetGUID())]
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
    obj = getObjectFromGUID(guid)
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
    obj = getObjectFromGUID(guid)
    count = 0
    display = false
    error = false
    deckerror = false
    for i,card in ipairs(getAllObjects()) do
        cardpos = card.getPosition()
        objpos = obj.getPosition()
        if distance(cardpos[1],cardpos[3],objpos[1],objpos[3]) < 5.5 then
            if cardpos[3] >= 18 or cardpos[3] <= -18 then
                if card.tag == 'Card' and card.getDescription() ~= '' then
                    CardData = dialpositions[CardInArray(card.getGUID())]
                    if CardData == nil then
                        count = count + 1
                        cardtable = {}
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
    shipobject = getObjectFromGUID(guid)
    world = shipobject.getPosition()
    direction = shipobject.getRotation()
    obj_parameters = {}
    obj_parameters.type = 'Custom_Model'
    obj_parameters.position = {world[1], world[2]+0.15, world[3]}
    obj_parameters.rotation = { 0, direction[2], 0 }
    DialGuide = spawnObject(obj_parameters)
    custom = {}
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
            shipguid = ship.getGUID()
            shipname = ship.getName()
            shipdesc = ship.getDescription()
            checkname(shipguid,shipdesc,shipname)
            check(shipguid,shipdesc)
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
    obj = getObjectFromGUID(guid)
    objp = getObjectFromGUID(parent)
    world = obj.getPosition()
    local offset = RotateVector({xoff, yoff, zoff}, obj.getRotation()[2])
    local params = {}
    params.position = {world[1]+offset[1], world[2]+offset[2], world[3]+offset[3]}
    objp.takeObject(params)
end

function undo(guid)
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
    obj = getObjectFromGUID(guid)
    direction = obj.getRotation()
    world = obj.getPosition()
    undolist[guid] = guid
    undopos[guid] = world
    undorot[guid] = direction
end

function registername(guid)
    obj = getObjectFromGUID(guid)
    name = obj.getName()
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
        obj = getObjectFromGUID(guid)
        obj.setName(namelist1[guid])
    end
end

function setpending(guid)
    fixname(guid)
    obj = getObjectFromGUID(guid)
    obj.setDescription('Pending')
end

function setlock(guid)
    fixname(guid)
    obj = getObjectFromGUID(guid)
    obj.setDescription('Locking')
end


function notify(guid,move,text)
    if text == nil then
        text = ''
    end

    obj = getObjectFromGUID(guid)
    name = obj.getName()
    if move == 'q' then
        printToAll(name .. ' executed undo.', {0, 1, 0})
    elseif move == 'set' then
        printToAll(name .. ' set name.', {0, 1, 1})
    elseif move == 'r' then
        printToAll(name .. ' spawned a ruler.', {0, 0, 1})
    elseif move == 'action' then
        printToAll(name .. ' ' .. text .. '.', {0.959999978542328 , 0.439000010490417 , 0.806999981403351})
    else
        printToAll(name .. ' ' .. text ..' (' .. move .. ').', {1, 0, 0})
    end
end


function check(guid,move)
    -- Checking for Lock
    if move == 'Locking' then
        if locktimer[guid] ~= nil or locktimer[guid] == 0 then
            if locktimer[guid] > 1 then
                locktimer[guid] = locktimer[guid] - 1
            elseif locktimer[guid] == 0 then
                locktimer[guid] = 100
            else
                locktimer[guid] = 0
                obj = getObjectFromGUID(guid)
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
        ship = getObjectFromGUID(guid)
        printToAll('AI Type For: ' .. ship.getName() .. ' set to STRIKE',{0, 1, 0})
        setpending(guid)
    end
    if move == 'ai attack' then
        aitype[guid] = nil
        local ship = getObjectFromGUID(guid)
        printToAll('AI Type For: ' .. ship.getName() .. ' set to ATTACK',{0, 1, 0})
        setpending(guid)
    end
    if move == 'ai target' then
        striketarget = guid
        ship = getObjectFromGUID(guid)
        printToAll('Strike Target Set: ' .. ship.getName(),{0, 0, 1})
        setpending(guid)
    end
    if move == "ai pos" then
        local ship = getObjectFromGUID(guid)
        printToAll('Position '..ship.getPosition()[1].." "..ship.getPosition()[2].." "..ship.getPosition()[3],{0,1,0})
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
end
function string.starts(String,Start)
    return string.sub(String,1,string.len(Start))==Start
end

function checkpos(guid)
    setpending(guid)
    obj = getObjectFromGUID(guid)
    world = obj.getPosition()
    for i, v in ipairs(world) do
        print(v)
    end
end

function checkrot(guid)
    setpending(guid)
    obj = getObjectFromGUID(guid)
    world = obj.getRotation()
    for i, v in ipairs(world) do
        print(v)
    end
end

function ruler(guid)

    shipobject = getObjectFromGUID(guid)
    shipname = shipobject.getName()
    direction = shipobject.getRotation()
    world = shipobject.getPosition()
    scale = shipobject.getScale()

    obj_parameters = {}
    obj_parameters.type = 'Custom_Model'
    obj_parameters.position = {world[1], world[2]+0.28, world[3]}
    obj_parameters.rotation = { 0, direction[2] +180, 0 }
    newruler = spawnObject(obj_parameters)
    custom = {}
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
    obj = getObjectFromGUID(guid)
    shipname = obj.getName()
    if shipname:match '%LGS$' then
        forwardDistance = forwardDistance + bsfd
    end
    direction = obj.getRotation()
    world = obj.getPosition()
    rotval = round(direction[2])
    radrotval = math.rad(rotval)
    xDistance = math.sin(radrotval) * forwardDistance * -1
    zDistance = math.cos(radrotval) * forwardDistance * -1
    setlock(guid)
    obj.setPosition( {world[1]+xDistance, world[2]+2, world[3]+zDistance} )
    obj.Rotate({0, 0, 0})


end

function straightk(guid,forwardDistance,bsfd)
    storeundo(guid)
    obj = getObjectFromGUID(guid)
    shipname = obj.getName()
    if shipname:match '%LGS$' then
        forwardDistance = forwardDistance + bsfd
    end
    direction = obj.getRotation()
    world = obj.getPosition()
    rotval = round(direction[2])
    radrotval = math.rad(rotval)
    xDistance = math.sin(radrotval) * forwardDistance * -1
    zDistance = math.cos(radrotval) * forwardDistance * -1
    setlock(guid)
    obj.setPosition( {world[1]+xDistance, world[2]+2, world[3]+zDistance} )
    obj.Rotate({0, 180, 0})
end

function right(guid,forwardDistance,sidewaysDistance,rotate,bsfd,bssd)
    storeundo(guid)
    obj = getObjectFromGUID(guid)
    shipname = obj.getName()
    if shipname:match '%LGS$' then
        forwardDistance = forwardDistance + bsfd
        sidewaysDistance = sidewaysDistance + bssd
    end
    direction = obj.getRotation()
    world = obj.getPosition()
    rotval = round(direction[2])
    radrotval = math.rad(rotval)
    xDistance = math.sin(radrotval) * forwardDistance * -1
    zDistance = math.cos(radrotval) * forwardDistance * -1
    radrotval = radrotval + math.rad(90)
    xDistance = xDistance + (math.sin(radrotval) * sidewaysDistance * -1)
    zDistance = zDistance + (math.cos(radrotval) * sidewaysDistance * -1)
    setlock(guid)
    obj.setPosition( {world[1]+xDistance, world[2]+2, world[3]+zDistance} )
    obj.Rotate({0, rotate, 0})
end

function left(guid,forwardDistance,sidewaysDistance,rotate,bsfd,bssd)
    storeundo(guid)
    obj = getObjectFromGUID(guid)
    shipname = obj.getName()
    if shipname:match '%LGS$' then
        forwardDistance = forwardDistance + bsfd
        sidewaysDistance = sidewaysDistance + bssd
    end
    direction = obj.getRotation()
    world = obj.getPosition()
    rotval = round(direction[2])
    radrotval = math.rad(rotval)
    xDistance = math.sin(radrotval) * forwardDistance * -1
    zDistance = math.cos(radrotval) * forwardDistance * -1
    radrotval = radrotval - math.rad(90)
    xDistance = xDistance + (math.sin(radrotval) * sidewaysDistance * -1)
    zDistance = zDistance + (math.cos(radrotval) * sidewaysDistance * -1)
    setlock(guid)
    obj.setPosition( {world[1]+xDistance, world[2]+2, world[3]+zDistance} )
    obj.Rotate({0, rotate, 0})
end

function auto(guid)
    local ai = getObjectFromGUID(guid)
    local tgtGuid
    --if getAiFocus(ai.getName()) then
    --    tgtGuid = getAiFocus(ai.getName())
    local squad = getAiSquad(ai.getName())
--    if squadmove[squad] ~= nil
--            and squadrotation[squad] == ai.getRotation[2]
--            and realDistance(guid,squadleader[squad])<3.7 then
--        printToAll("Found previous move for [".. squad.."] ".. squadmove[squad],{1,0,0})
--        executeMove(ai, squadmove[squad])
--        return
--    end
    if aitype[guid] == 'strike' then
        tgtGuid = striketarget
        printToAll(ai.getName() .. " is STRIKE AI",{0,1,0})
    else
        tgtGuid = findNearestPlayer(guid)
    end
    if tgtGuid == nil then
        printToAll('Error: AI ' .. ai.getName() .. ' has no target',{0, 0, 1})
        setpending(guid)
    else
        local tgt = getObjectFromGUID(tgtGuid)
        printToAll(ai.getName() .. " pursues: " .. tgt.getName(),{0,1,0})
        local aiPos = ai.getPosition()
        local tgtPos = tgt.getPosition()
        local aiForward = getForwardVector(guid)
        local tgtForward = getForwardVector(tgtGuid)
        local offset = {tgtPos[1] - aiPos[1],0,tgtPos[3] - aiPos[3]}
        local angle = math.atan2(offset[3], offset[1]) - math.atan2(aiForward[3], aiForward[1])
        if angle < 0 then
            angle = angle + 2 * math.pi
        end
        local fleeing = dot(offset,tgtForward)>0
        local move = getMove(getAiType(ai.getName()),angle,realDistance(guid,tgtGuid),fleeing)
        if squad ~= nil then
            printToAll("Setting move for squad [".. squad.."] ".. move,{1,0,0})
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

function AiSquadButton(ai)
    local squad = getAiSquad(ai.getName())
    if squad == nil then
        printToAll("No squad name found (Must be in format '[AI:INT:1] Tie Interceptor Alpha#1')",{1,0,0})
        setpending(ai.getGUID())
        return
    end
    if squad ~=nil and squadmove[squad] ~= nil then
        printToAll("Found previous move for [".. squad.."] ".. squadmove[squad],{1,0,0})
        executeMove(ai, squadmove[squad])
        State_AIPostMove(ai)
    else
        printToAll("No Squad Move Found for ".. squad,{1,0,0})
        setpending(ai.getGUID())
        return
    end
end
function executeMove(ai, move)
    if aiswerved[ai.getGUID()]~=true then
        aimove[ai.getGUID()] = move
    end
    local movestripped = string.gsub(move,"*","")
    ai.setDescription(movestripped)
    if string.find(move,'*') then
        printToAll('[STRESS - No Action]',{1, 0, 0})
    end
end
function Render_SwerveLeft(object)
    local move = aimove[object.getGUID()]

    local swerves = getSwerve(getAiType(object.getName()),move)
    if swerves ~= nil and swerves[1] ~= nil and aiswerved[object.getGUID()]~=true then
        local swerve = {['click_function'] = 'Action_SwerveLeft', ['label'] = swerves[1], ['position'] = {-0.6, 0.3, 1.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 400, ['height'] = 300, ['font_size'] = 300}
        object.createButton(swerve)
--    else
--        -- REMOVE SWERVES
--        for i,button in ipairs(object.getButtons()) do
--            if button~=nil and button['click_function']:matches "swerve" then
--                object.removeButton(button['index'])
--            end
--        end
    end
end
function Action_SwerveLeft(object)
    local move = aimove[object.getGUID()]
    local swerves = getSwerve(getAiType(object.getName()),move)
    aiswerved[object.getGUID()] = true
    object.setDescription("q "..swerves[1])
end
function Render_SwerveRight(object)
    local move = aimove[object.getGUID()]

    local swerves = getSwerve(getAiType(object.getName()),move)
    if swerves ~= nil and swerves[2] ~= nil and aiswerved[object.getGUID()]~=true then
        local swerve = {['click_function'] = 'Action_SwerveRight', ['label'] = swerves[2], ['position'] = {0.6, 0.3, 1.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 400, ['height'] = 300, ['font_size'] = 300}
        object.createButton(swerve)
--    else
--        -- REMOVE SWERVES
--        for i,button in ipairs(object.getButtons()) do
--            if button~=nil and button['click_function']:matches "swerve" then
--                object.removeButton(button['index'])
--            end
--        end
    end
end
function Action_SwerveRight(object)
    local move = aimove[object.getGUID()]
    local swerves = getSwerve(getAiType(object.getName()),move)
    aiswerved[object.getGUID()] = true
    object.setDescription("q "..swerves[2])
end

function getMove(type, direction,range,fleeing)
    local i_dir = math.ceil(direction / (math.pi/4) + 0.5)
    if i_dir > 8 then i_dir = i_dir - 8 end
    local i_range = range / 3.7
    local chooseClosing = i_range<=1 or (i_range <=2 and not fleeing)
    local i_roll = math.random(6)
    --    if chooseClosing then
    --        log("Info: AI choice Quad: ".. i_dir..", Close, Move: " .. i_roll)
    --    else
    --        log("Info: AI choice Quad: ".. i_dir..", Far, Move: " .. i_roll)
    --    end

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
        closeMoves[1] = {'*','*','*','s1','br1','bl1'}
        closeMoves[2] = {'*','s1','bl1','bl1','bl1','tl2*'}
        closeMoves[3] = {'*','tl2*','tl2*','tl2*','bl1','bl2'}
        closeMoves[4] = {'*','tl2*','tl2*','tl2*','bl2','bl3*'}
        closeMoves[5] = {'*','*','tr2*','tl2*','br3*','bl3*'}
        closeMoves[6] = {'*','tr2*','tr2*','tr2*','br2','br3*'}
        closeMoves[7] = {'*','tr2*','tr2*','tr2*','br1','br2'}
        closeMoves[8] = {'*','s1','br1','br1','br1','tr2*' }

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
        swerves["*"] = {nil,nil}
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
        swerves["s1"] = {"bl1","bl1"}
        swerves["br1"] = {"s1","tr2*" }
    end
    if type == "DEC" then
        swerves["bl1"] = {"tl2","s1"}
        swerves["s1"] = {"bl1","bl1"}
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
        swerves["tr2"] = {"bl2",nil }
    end
    if type == "DEF" or type == "BOM" or type == "SHU" then
        swerves["tl2*"] = {nil,"bl2"}
        swerves["bl2"] = {"tl2*","s2"}
        swerves["s2"] = {"bl2","br2"}
        swerves["br2"] = {"s2","tr2*"}
        swerves["tr2*"] = {"bl2",nil }
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
    squadleader = {}
    squadmove = {}
    squadposition = {}
    squadrotation = {}
    aimove = {}
    aiswerved = {}
    for i,ship in ipairs(getAllObjects()) do
        if ship.tag == 'Figurine' and ship.getGUID() ~= guid and ship.name ~= '' and isAi(ship.getName()) then
            ship.clearButtons()
            -- Set MOVE button
            -- State_AIMove(ship)
        end
    end -- [end loop for all ships]

    local first = FindNextAi(nil, MoveSort)

    if first ~=nil then
        State_AIMove(first)
    end
end
function Action_ClearAi()
    for i,ship in ipairs(getAllObjects()) do
        if ship.tag == 'Figurine' and ship.getGUID() ~= guid and ship.name ~= '' and isAi(ship.getName()) then
            ship.clearButtons()
        end
    end -- [end loop for all ships]
end
function Action_AttackPhase()
    for i,ship in ipairs(getAllObjects()) do
        if ship.tag == 'Figurine' and ship.getGUID() ~= guid and ship.name ~= '' and isAi(ship.getName()) then
            ship.clearButtons()
            -- Render_Ruler(ship)
        end
    end -- [end loop for all ships]
    local first = FindNextAi(nil, AttackSort)

    if first ~=nil then
        Render_Ruler(first)
        Render_AttackButton(first)
    end
end
function Render_AttackButton(object)

    local attackbutton = {['click_function'] = 'Action_AiAttack', ['label'] = 'Attack', ['position'] = {0, 0.3, -0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 750, ['height'] = 550, ['font_size'] = 550}
    object.createButton(attackbutton)
end
function Action_AiAttack(object)
    object.clearButtons()
    local next = FindNextAi(object.getGUID(),AttackSort)

    if next ~=nil then
        Render_Ruler(next)
        Render_AttackButton(next)
    end
end
function FindNextAi(guid, sort)
    local ais = {}
    for i,ship in ipairs(getAllObjects()) do
        if ship.tag == 'Figurine' and ship.name ~= '' and isAi(ship.getName()) and isInPlay(ship) then
            table.insert(ais, ship)
        end
    end -- [end loop for all ships]
    table.sort(ais,sort)
--    for i,ship in ipairs(ais) do
--        printToAll(ship.getName(),{0,1,0})
--    end
    if guid==nil then
        return ais[1]
    else
        local selffound = false
        for i,ship in ipairs(ais) do
            if selffound then return ship end
            if ship.getGUID()==guid then selffound = true end
        end
    end
end
function AttackSort(a, b)
    local a_ps = tonumber(getAiSkill(a.getName()))
    local a_num = tonumber(getAiNumber(a.getName()))
    local b_ps = tonumber(getAiSkill(b.getName()))
    local b_num = tonumber(getAiNumber(b.getName()))
    if a_ps ~= b_ps then
        return a_ps > b_ps
    else
        return a_num<b_num
    end
end
function MoveSort(a, b)
    local a_ps = tonumber(getAiSkill(a.getName()))
    local a_num = tonumber(getAiNumber(a.getName()))
    local b_ps = tonumber(getAiSkill(b.getName()))
    local b_num = tonumber(getAiNumber(b.getName()))
    if a_ps ~= b_ps then
        return a_ps < b_ps
    else
        return a_num<b_num
    end
end
function State_AIMove(object)
    -- Set MOVE button
    local movebutton = {['click_function'] = 'Action_AiMove', ['label'] = 'Move', ['position'] = {0.3, 0.3, -0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 750, ['height'] = 550, ['font_size'] = 550}
    object.createButton(movebutton)
    local squadbutton = {['click_function'] = 'AiSquadButton', ['label'] = 'Squad', ['position'] = {0.3, 0.3, 0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 750, ['height'] = 550, ['font_size'] = 550}
    object.createButton(squadbutton)
    if getAiType(object.getName()) == "PHA" then
        Render_AiDecloak(object)
    end
end
function Action_AiMove(object)
    object.setDescription("ai")

    State_AIPostMove(object)
    local next = FindNextAi(object.getGUID(),MoveSort)

    if next ~=nil then
        State_AIMove(next)
    end
    for i,ship in ipairs(getAllObjects()) do
        if ship.tag == 'Figurine' and ship.getGUID()~=object.getGUID() and ship.name ~= '' and isAi(ship.getName()) then
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

    if getAiHasBoost(object.getName()) then
        Render_Boost(object)
    end

    if getAiHasBarrelRoll(object.getName()) then
        Render_BarrelRoll(object)
    end
end


function Render_Undo(object)
    local undobutton = {['click_function'] = 'AiUndoButton', ['label'] = 'q', ['position'] = {-0.9, 0.3, -0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 550}
    object.createButton(undobutton)
end

function AiUndoButton(object)
    aiswerved[object.getGUID()] = nil
    if squadleader[object.getGUID()]~=nil then
        local squad = getAiSquad(ai.getName())
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
    local undobutton = {['click_function'] = 'Action_AiUndoBoostBarrel', ['label'] = 'q', ['position'] = {-0.9, 0.3, -0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 550}
    object.createButton(undobutton)
end

function Action_AiUndoBoostBarrel(object)

    object.clearButtons()
    object.setDescription("q")

    Render_Ruler(object)

    if getAiHasBoost(object.getName()) then
        Render_Boost(object)
    end

    if getAiHasBarrelRoll(object.getName()) then
        Render_BarrelRoll(object)
    end
end

function Render_Ruler(object)
    local rulerbutton = {['click_function'] = 'RulerButton', ['label'] = 'r', ['position'] = {-0.9, 0.3, 0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 550}
    object.createButton(rulerbutton)
end

function RulerButton(object)
    object.setDescription("r")
end

function Render_Boost(object)

    local bl1button = {['click_function'] = 'Action_AiBoostLeft', ['label'] = 'bl1', ['position'] = {-1.1, 0.3, -1.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 330, ['height'] = 300, ['font_size'] = 300}
    object.createButton(bl1button)

    local s1button = {['click_function'] = 'Action_AiBoostStraight', ['label'] = 's1', ['position'] = {0, 0.3, -1.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 300, ['font_size'] = 300}
    object.createButton(s1button)

    local br1button = {['click_function'] = 'Action_AiBoostRight', ['label'] = 'br1', ['position'] = {1.1, 0.3, -1.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 330, ['height'] = 300, ['font_size'] = 300}
    object.createButton(br1button)
end

function Render_AiDecloak(object)
    local decloak = {['click_function'] = 'Action_AiDecloak', ['label'] = 'decloak', ['position'] = {0, 0.3, -1.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 1000, ['height'] = 300, ['font_size'] = 300}
    object.createButton(decloak)
end

function Action_AiDecloak(object)
    local i_roll = math.random(3)
    local options = {"ce","cs","cr" }
    object.setDescription(options[i_roll])
    Render_Undo(object)
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

    local xebbutton = {['click_function'] = 'Action_AiBarrelRollLeft', ['label'] = 'xl', ['position'] = {-1.6, 0.3, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 300, ['font_size'] = 300}
    object.createButton(xebbutton)

    local xrbbutton = {['click_function'] = 'Action_AiBarrelRollRight', ['label'] = 'xr', ['position'] = {1.6, 0.3, 0}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 300, ['font_size'] = 300}
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

    local focusbutton = {['click_function'] = 'Action_Focus', ['label'] = 'F', ['position'] = {0.9, 0.3, -0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 550}
    object.createButton(focusbutton)

    local type = getAiType(object.getName());
    if type == "TIE" or type=="INT" or type == "ADV" or type == "PHA" then
        local evadebutton = {['click_function'] = 'Action_Evade', ['label'] = 'E', ['position'] = {0.9, 0.3, 0.6}, ['rotation'] =  {0, 0, 0}, ['width'] = 200, ['height'] = 530, ['font_size'] = 550}
        object.createButton(evadebutton)
    end
end


function Action_Focus(object)
    take(focus, object.getGUID(),-0.5,1,-0.5)
    notify(object.getGUID(),'action','takes a focus token')
end
function Action_Evade(object)
    take(evade, object.getGUID(),-0.5,1,0.5)
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
    local inarc = getAiType(ai.getName()) == "DEC"
    local distances = {}
    local angles = {}

    for i,ship in ipairs(getAllObjects()) do
        if ship.tag == 'Figurine' and ship.getGUID() ~= guid and ship.name ~= '' and not isAi(ship.getName()) and isInPlay(ship) then
            local pos = ship.getPosition()
            -- log("Adding Target: "..ship.getName())
            distances[ship.getGUID()] = realDistance(guid,ship.getGUID())

            local aiPos = ai.getPosition()
            local aiForward = getForwardVector(guid)
            local tgtForward = getForwardVector(ship.getGUID())
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

    for guid,dist in pairs(distances) do

        if dist < minDist then
            minDist = dist
            if minDist < 35 then
                nearest = guid
            end
        end -- [end check for nearest]

    end -- [end loop for each distance]
--    local nearestInArc
--    minDist = 3.7 * 3
--    for guid,dist in pairs(distances) do
--
--        if angles[guid]<dist < minDist then
--            minDist = dist
--            if minDist < 35 then
--                nearest = guid
--            end
--        end -- [end check for nearest]
--
--    end -- [end loop for each distance]

    return nearest
end

function realDistance(guid1, guid2)
    -- Lazy calc to start. need to go from nearest corner to nearest corner
    local a  = getObjectFromGUID(guid1)
    local b  = getObjectFromGUID(guid2)
    local apos = a.getPosition()
    local bpos = b.getPosition()
    if a == nil or b == nil then return nil end
    local dist = distance(apos[1],apos[3],bpos[1],bpos[3])
    if a.name:match '%LGS$' then dist = dist - 2.1 else dist = dist - 1.1 end
    if b.name:match '%LGS$' then dist = dist - 2.1 else dist = dist - 1.1 end
    return dist
end

function isAi(name)
    --local is_ai = name:match '.*AI$' ~= nil or name:match '.*AILGS$' ~= nil
    local is_ai = name:match '^%[AI:?%u*:?%d*:?%w*].*'
    -- if is_ai then log("This is an AI: ".. name) else log("This is not an AI: " .. name) end
    return is_ai
end

function getAiType(name)
    local type =  name:match '^%[AI:?(%u*):?%d*:?%w*].*'
    local validTypes = {"TIE","INT","ADV","BOM","DEF","PHA","DEC","SHU" }
    if contains(validTypes, type) then
        return type
    else
        printToAll("Error: "..name .. " does not define valid type in format '[AI:{type}:{PS}] Name'",{1,0,0})
        printToAll("Error: Implemented Types are: TIE, INT, ADV, BOM, DEF, PHA, DEC, SHU",{1,0,0})
        return "INT"
    end
end
function getAiSkill(name)
    return name:match '^%[AI:?%u+:?(%d*)].*'
end
function getAiSquad(name)
    return name:match '(%a+)[#%s]?%d+$'
end
function getAiNumber(name)
    return name:match '(%d+)$'
end
function getAiHasBoost(name)
    local type = getAiType(name)
    return type == "INT"
end
function getAiHasBarrelRoll(name)
    local type = getAiType(name)
    return type == "TIE" or type == "INT" or type == "ADV"or type == "BOM" or type == "DEF" or type == "PHA"
end
function isInPlay(object)
    return math.abs(object.getPosition()[1])<16.5 and math.abs(object.getPosition()[3])<16.5
end
function contains (tab, val)
    for index, value in ipairs (tab) do
        if value == val then
            return true
        end
    end

    return false
end

function log(string)
    printToAll("[" .. os.date("%H:%M:%S") .. "] " .. string,{0, 0, 1})
end
