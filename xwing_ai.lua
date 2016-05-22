
-- X-Wing AI Auto movement - Valadian, April 2016

function onload()
    Render_Menu_v2()
end
--Render Section
function Render_Menu_v1()
    self.createButton(buildMenuButton('Planning',{position={0,0.3,-1.5}}))
    self.createButton(buildMenuButton('Activation',{position={0,0.3,-0.5}}))
    self.createButton(buildMenuButton('Combat',{position={0,0.3,0.5}}))
    self.createButton(buildMenuButton('End',{position={0,0.3,1.5}}))
end
function Render_Menu_v2()
    self.createButton(buildMiniButton('Planning',{function_owner=Global,position={-1.5,0.3,-1.5},rotation={0,-45,0}}))
    self.createButton(buildMiniButton('Activation',{function_owner=Global,position={0,0.3,-2.1}}))
    self.createButton(buildMiniButton('Combat',{function_owner=Global,position={1.5,0.3,-1.5},rotation={0,45,0}}))
    self.createButton(buildButton('End',{function_owner=Global,position={0,0.3,0},font_size=700,height=800,width=1200}))
end
function buildMiniButton(label, def)
    def.width = 700
    def.height = 300
    def.font_size = 120
    return buildButton(label, def)
end
function buildMenuButton(label, def)
    def.width = 1200
    def.height = 400
    return buildButton(label, def)
end
function buildButton(label, def)
    local DEFAULT_POSITION = {0,0.3,0}
    local DEFAULT_ROTATION = {0,0,0}
    local DEFAULT_WIDTH_PER_CHAR = 125
    local DEFAULT_HEIGHT = 530
    local DEFAULT_FONT_SIZE = 250
    if def.position==nil then def.position = DEFAULT_POSITION end
    if def.rotation==nil then def.rotation = DEFAULT_ROTATION end
    if def.width==nil then def.width = 100 + string.len(label)*DEFAULT_WIDTH_PER_CHAR end
    if def.height==nil then def.height = DEFAULT_HEIGHT end
    if def.font_size==nil then def.font_size = DEFAULT_FONT_SIZE end
    if def.click_function==nil then def.click_function = 'Action_'..label end
    if def.function_owner==nil then def.function_owner = self end
    return {['click_function'] = def.click_function, ['function_owner'] = def.function_owner, ['label'] = label, ['position'] = def.position, ['rotation'] =  def.rotation, ['width'] = def.width, ['height'] = def.height, ['font_size'] = def.font_size}
end