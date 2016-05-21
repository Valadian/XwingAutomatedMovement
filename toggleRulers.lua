local rulers = {}
local rulersState = 0 -- 0: none, 1: roid setup, 2: ship setup

local rulerData = {}
rulerData.mesh = 'http://pastebin.com/raw.php?i=MLLajD97'
rulerData.collider = 'http://pastebin.com/raw.php?i=MLLajD97'
rulerData.diffuse = 'http://i.imgur.com/46CSDvj.jpg'
rulerData.material = 1

local roidRot = {
    { 0, 270, 180},
    { 0, 180, 180},
    { 0, 270, 180},
    { 0, 0, 180},
    { 0, 0, 180},
    { 0, 90, 180},
    { 0, 90, 180},
    { 0, 180, 180}
}

local setupRot = {
    {0, 270, 0},
    {0, 0, 0},
    {0, 270, 0},
    {0, 0, 0},
    {0, 0, 0},
    {0, 90, 0},
    {0, 180, 0},
    {0, 90, 0},
    {0, 180, 0},
    {0, 180, 0}
}

local roidPos = {
    { -30.042200088501, 0.99871951341629, -11.1546182632446},
    { -31.552360534668, 0.998719453811646, -9.64833354949951},
    { -10.9784393310547, 0.998719573020935, -11.1076889038086},
    { -9.47546291351318, 0.998719453811646, -9.59820747375488},
    { -9.46722316741943, 0.99871951341629, 9.53365325927734},
    { -10.9758749008179, 0.998719453811646, 11.0407905578613},
    { -30.0285949707031, 0.998719394207001, 11.0695362091064},
    { -31.5308876037598, 0.998719453811646, 9.55834770202637}
}

local setupPos = {
    {-3.82240991592407, 1.00172388553619, -11.0651750564575},
    {-9.51806907653809, 1.00172448158264, -12.5975313186646},
    {-37.3094985961914, 1.00172400474548, -11.0700817108154},
    {-20.5756023406982, 1.0017237663269, -12.6035499572754},
    {-31.6121223449707, 1.00172340869904, -12.6002779006958},
    {-3.82240991592407, 1.00172388553619, 11.0651750564575},
    {-9.51806907653809, 1.00172448158264, 12.5975313186646},
    {-37.3094985961914, 1.00172400474548, 11.0700817108154},
    {-20.5756023406982, 1.0017237663269, 12.6035499572754},
    {-31.6121223449707, 1.00172340869904, 12.6002779006958}
}

local corrScale = {0.625, 0.625, 0.625}

local setupOffset = {20.5,0,0.1}

function onload()

    local button = {}
    button.click_function = 'toggleRulers'
    button.function_owner = self
    button.label = 'TOGGLE RULERS'
    button.position = {8, 0.1, 0}
    button.rotation = {0, 90, 0}
    button.width = 5000
    button.height = 1200 -- 40
    button.font_size = 1500
    self.createButton(button)

end

function toggleRulers()

    deleteAll()
    rulersState = rulersState + 1
    if rulersState == 1 then
        spawnSet(roidPos, roidRot)
    elseif rulersState == 2 then
        spawnSet(setupPos, setupRot)
    elseif rulersState == 3 then
        rulersState = 0
    end

end

function spawnSet(posTable, rotTable)

    for k,pos in pairs(posTable) do
        local params = {} -- 50
        params.type = 'Custom_Model'
        local pos = posTable[k]
        params.position = {pos[1]+setupOffset[1],pos[2]+setupOffset[2],pos[3]+setupOffset[3]}
        params.rotation = rotTable[k]
        obj = spawnObject(params)
        obj.setCustomObject(rulerData)
        obj.setScale(corrScale)
        obj.lock()
        obj.setDescription('autoruler')
        table.insert(rulers, obj)
    end

end

function deleteAll()
    for k,ruler in pairs(rulers) do ruler.destruct() ruler = nil end
end

function onObjectDestroyed(obj)

    if obj.getDescription() == 'autoruler' then
        for k, v in pairs(rulers) do
            if v == obj then table.remove(rulers, k) end
        end
    end

end
