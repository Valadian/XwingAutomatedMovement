set = nil
tinted = nil

colorTable = {}
colorTable['Red']= {1, 0, 0}
colorTable['Brown']= {0.6, 0.4, 0}
colorTable['White']= {1, 1, 1}
colorTable['Pink']= {1, 0.4, 0.8}
colorTable['Purple']= {0.8, 0, 0.8}
colorTable['Blue']= {0, 0, 1}
colorTable['Teal']= {0.2, 1, 0.8}
colorTable['Green']= {0, 1, 0}
colorTable['Yellow']= {1, 1, 0}
colorTable['Orange']= {1, 0.4, 0}
colorTable['Black']= {0, 0, 0}

function onload()
    set = false
    tinted = false
end

function manualSet(color_name)
    tinted = true
    set = true
    self.setColorTint(colorTable[color_name[1]])
    self.setName(color_name[2])
end

function onPickedUp()

    if tinted == false and self.held_by_color ~= nil then
        self.setColorTint(colorTable[self.held_by_color])
        tinted = true
    end

end

function onDropped()
    if self.getDescription() == 'man' and set == false then
        set = true
        printToAll(self.getName() .. ' set to manual', {0, 0, 1})
        self.setDescription('')
    end

    local spos = self.getPosition()
    local distances = {}

    if set == false then

        for i,ship in ipairs(getAllObjects()) do

            if ship.tag == 'Figurine' and ship.name ~= '' then
                local pos = ship.getPosition()
                distances[ship.getName()] = math.sqrt((spos['x']-pos['x'])*(spos['x']-pos['x'])  + (spos['z']-pos['z'])*(spos['z']-pos['z']))
            end -- [end checking distance to ship]

        end -- [end loop for all ships]

        local nearest = nil
        local minDist = 999999

        for name,dist in pairs(distances) do

            if dist < minDist then
                minDist = dist
                if minDist < 5 then
                    nearest = name
                end
            end -- [end check for nearest]

        end -- [end loop for each distance]

        if nearest ~= nil then
            printToAll(self.getName() .. ' named for ' .. nearest, {0, 0, 1})
            self.setName(nearest)
            set = true
        end -- [end setting TL name and status]

    end -- [end loop if TL not set]

end -- [end onDropped]
