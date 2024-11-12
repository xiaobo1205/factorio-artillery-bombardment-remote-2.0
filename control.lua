local target_limit = 5000
local function position_to_chunk(position)
    return {
        x = math.floor(position.x / 32),
        y = math.floor(position.y / 32)
    }
end

-- Aidiakapi#2177
-- https://gist.github.com/Aidiakapi/a1b4e603c37f1121686d372e542d4339
local function chunk_to_chunkid(chunk_x, chunk_y)
    if chunk_x < 0 then
        chunk_x = 0x10000 + chunk_x
    end
    if chunk_y < 0 then
        chunk_y = 0x10000 + chunk_y
    end
    return bit32.bor(chunk_x, bit32.lshift(chunk_y, 16))
end

-- Aidiakapi#2177
-- https://gist.github.com/Aidiakapi/a1b4e603c37f1121686d372e542d4339
local function chunkid_to_chunk(chunkid)
    local chunk_x = bit32.band(chunkid, 0xffff)
    local chunk_y = bit32.rshift(chunkid, 16)
    if chunk_x >= 0x8000 then
        chunk_x = chunk_x - 0x10000
    end
    if chunk_y >= 0x8000 then
        chunk_y = chunk_y - 0x10000
    end
    return chunk_x, chunk_y
end

-- EnigmaticAussie#9641
local function chunkid_to_chunk_position(chunkid)
    local chunk_x, chunk_y = chunkid_to_chunk(chunkid)
    chunk_x = chunk_x * 32 + 16
    chunk_y = chunk_y * 32 + 16
    return chunk_x, chunk_y
end

local function on_player_selected_area(event)
    if event.item == 'artillery-bombardment-remote' then
        if not global[event.player_index] then
            global[event.player_index] = {}
        end
        local settings = global[event.player_index]
        local surface = game.players[event.player_index].surface
        local force = game.players[event.player_index].force
        local count = 0
        local col_count = 0
        for x = event.area.left_top.x, event.area.right_bottom.x, (settings.x or 6) do
            for y = (event.area.left_top.y + ((settings.col_count or 2) * (col_count % (settings.col_count or 2)))), event.area.right_bottom.y, (settings.y or 4) do
                surface.create_entity(
                    {
                        name = 'artillery-flare',
                        position = {x, y},
                        force = force,
                        movement = {0, 0},
                        height = 0,
                        vertical_speed = 0,
                        frame_speed = 0
                    }
                )
                count = count + 1
                if count > target_limit then
                    break
                end
            end
            col_count = col_count + 1
            if count > target_limit then
                game.players[event.player_index].print({'artillery-bombardment-remote.shot_limit_reached', target_limit})
                break
            end
        end
    elseif event.item == 'smart-artillery-bombardment-remote' then
        if not global[event.player_index] then
            global[event.player_index] = {}
        end
        local settings = global[event.player_index]
        local surface = game.players[event.player_index].surface
        local force = game.players[event.player_index].force
        local count = 0
        local points_hit = {}
        if event.area.left_top.x == event.area.right_bottom.x or event.area.left_top.y == event.area.right_bottom.y then
            return
        end
        -- Find enemy military structures in selection area, mark with flare
        local military_structures =
            surface.find_entities_filtered(
            {
                area = event.area,
                force = 'enemy',
                type = {'unit-spawner', 'turret', 'simple-entity-with-force', 'radar', 'player-port'}
            }
        )
        for _, entity in ipairs(military_structures) do
            if game.players[event.player_index].cheat_mode or force.is_chunk_charted(surface, position_to_chunk(entity.position)) then
                local skip = false
                local entity_position = entity.position
                for _, position in ipairs(points_hit) do
                    local x_dist = math.abs(entity_position.x - position.x)
                    local y_dist = math.abs(entity_position.y - position.y)
                    if math.sqrt(x_dist * x_dist + y_dist * y_dist) < (settings.radius or 6) then
                        skip = true
                        break
                    end
                end
                if not skip then
                    surface.create_entity(
                        {
                            name = 'artillery-flare',
                            position = entity_position,
                            force = force,
                            movement = {0, 0},
                            height = 0,
                            vertical_speed = 0,
                            frame_speed = 0
                        }
                    )
                    table.insert(points_hit, entity.position)
                    count = count + 1
                    if count > target_limit then
                        break
                    end
                end
            end
        end
        -- Mark chunks with flare for exploration position_to_chunk
        local left_top_chunk = position_to_chunk(event.area.left_top)
        local right_bottom_chunk = position_to_chunk(event.area.right_bottom)
        for x = left_top_chunk.x, right_bottom_chunk.x do
            for y = left_top_chunk.y, right_bottom_chunk.y do
                if not force.is_chunk_charted(surface, {x, y}) then
                    surface.create_entity(
                        {
                            name = 'artillery-flare',
                            position = {(x * 32) + 16, (y * 32) + 16},
                            force = force,
                            movement = {0, 0},
                            height = 0,
                            vertical_speed = 0,
                            frame_speed = 0
                        }
                    )
                end
            end
        end

        if count > target_limit then
            game.players[event.player_index].print({'artillery-bombardment-remote.shot_limit_reached', target_limit})
        end
    elseif event.item == 'smart-artillery-exploration-remote' then
        local id = event.player_index
        local player = game.players[id]
        local surface = player.surface
        local force = player.force
        -- Find artillery in selection area, add it's chunk to the global list
        -- Have on_tick handler manage the flare markers
        local artillery =
            surface.find_entities_filtered(
            {
                area = event.area,
                force = 'player',
                type = {'artillery-turret', 'artillery-wagon'}
            }
        )
        if artillery ~= nil then
            -- get artillery range, multiply by bonus, minus 2/3rds of a chunk for accuracy
            local artillery_range = (game.item_prototypes['artillery-wagon-cannon'].attack_parameters.range) * (1 + game.players[event.player_index].force.artillery_range_modifier) * 2.5 - (2 * 32 / 3)
            -- for each artillery turret, add it's chunk to the global list
            for _, entity in ipairs(artillery) do
                local artillery_chunk_position = position_to_chunk(entity.position)
                local artillery_chunk_id = chunk_to_chunkid(artillery_chunk_position.x, artillery_chunk_position.y)
                log(artillery_chunk_id)
                if not storage.fabr.chunks[artillery_chunk_id] then
                    storage.fabr.chunks[artillery_chunk_id] = {
                        force = force,
                        surface = surface,
                        i = 1,
                        artillery_range = artillery_range
                    }
                end
            end
        end
    end
end
script.on_event(defines.events.on_player_selected_area, on_player_selected_area)

local function on_player_alt_selected_area(event)
    if event.item == 'artillery-bombardment-remote' or event.item == 'smart-artillery-bombardment-remote' then
        if event.area.left_top.x == event.area.right_bottom.x or event.area.left_top.y == event.area.right_bottom.y then
            return
        end
        local flares =
            game.players[event.player_index].surface.find_entities_filtered(
            {
                area = event.area,
                name = 'artillery-flare',
                force = game.players[event.player_index].force
            }
        )
        for _, flare in ipairs(flares) do
            flare.destroy()
        end
    end
end
script.on_event(defines.events.on_player_alt_selected_area, on_player_alt_selected_area)

local draw_gui_functions = {
    ['artillery-bombardment-remote'] = function(event)
        local player = game.players[event.player_index]
        local settings = global[event.player_index]
        local frame =
            player.gui.center.add(
            {
                name = 'artillery_bombardment_config',
                type = 'frame',
                direction = 'vertical'
            }
        )
        local config_flow =
            frame.add(
            {
                name = 'artillery_bombardment_config_flow',
                type = 'flow',
                direction = 'vertical'
            }
        )

        local x_slider_label =
            config_flow.add(
            {
                name = 'artillery_bombardment_x_slider_label',
                type = 'label',
                caption = {'artillery-bombardment-remote.config-x-label'}
            }
        )
        local x_slider_flow =
            config_flow.add(
            {
                name = 'artillery_bombardment_x_slider_flow',
                type = 'flow',
                direction = 'horizontal'
            }
        )
        local x_slider =
            x_slider_flow.add(
            {
                name = 'artillery_bombardment_x_slider',
                type = 'slider',
                minimum_value = 1,
                maximum_value = 50,
                value = settings.x or 6,
                tooltip = {'artillery-bombardment-remote.config-x-spacing-tooltip'}
            }
        )
        local x_slider_text =
            x_slider_flow.add(
            {
                name = 'artillery_bombardment_x_textbox',
                type = 'textfield',
                text = settings.x or 6,
                tooltip = {'artillery-bombardment-remote.config-x-spacing-tooltip'}
            }
        )

        local y_slider_label =
            config_flow.add(
            {
                name = 'artillery_bombardment_y_slider_label',
                type = 'label',
                caption = {'artillery-bombardment-remote.config-y-label'}
            }
        )
        local y_slider_flow =
            config_flow.add(
            {
                name = 'artillery_bombardment_y_slider_flow',
                type = 'flow',
                direction = 'horizontal'
            }
        )
        local y_slider =
            y_slider_flow.add(
            {
                name = 'artillery_bombardment_y_slider',
                type = 'slider',
                minimum_value = 1,
                maximum_value = 50,
                value = settings.y or 4,
                tooltip = {'artillery-bombardment-remote.config-y-spacing-tooltip'}
            }
        )
        local y_slider_text =
            y_slider_flow.add(
            {
                name = 'artillery_bombardment_y_textbox',
                type = 'textfield',
                text = settings.y or 4,
                tooltip = {'artillery-bombardment-remote.config-y-spacing-tooltip'}
            }
        )

        local column_slider_label =
            config_flow.add(
            {
                name = 'artillery_bombardment_column_slider_label',
                type = 'label',
                caption = {'artillery-bombardment-remote.config-column-label'}
            }
        )
        local column_slider_flow =
            config_flow.add(
            {
                name = 'artillery_bombardment_column_slider_flow',
                type = 'flow',
                direction = 'horizontal'
            }
        )
        local column_slider =
            column_slider_flow.add(
            {
                name = 'artillery_bombardment_column_slider',
                type = 'slider',
                minimum_value = 1,
                maximum_value = 10,
                value = settings.col_count or 2,
                tooltip = {'artillery-bombardment-remote.config-column-offset-tooltip'}
            }
        )
        local column_slider_text =
            column_slider_flow.add(
            {
                name = 'artillery_bombardment_column_textbox',
                type = 'textfield',
                text = settings.col_count or 2,
                tooltip = {'artillery-bombardment-remote.config-column-offset-tooltip'}
            }
        )
        player.opened = frame
    end,
    ['smart-artillery-bombardment-remote'] = function(event)
        local player = game.players[event.player_index]
        local settings = global[event.player_index]
        local frame =
            player.gui.center.add(
            {
                name = 'artillery_bombardment_config',
                type = 'frame',
                direction = 'vertical'
            }
        )
        local config_flow =
            frame.add(
            {
                name = 'artillery_bombardment_config_flow',
                type = 'flow',
                direction = 'vertical'
            }
        )
        local radius_slider_label =
            config_flow.add(
            {
                name = 'artillery_bombardment_radius_slider_label',
                type = 'label',
                caption = {'artillery-bombardment-remote.config-radius-label'}
            }
        )
        local radius_slider_flow =
            config_flow.add(
            {
                name = 'artillery_bombardment_radius_slider_flow',
                type = 'flow',
                direction = 'horizontal'
            }
        )
        local radius_slider =
            radius_slider_flow.add(
            {
                name = 'artillery_bombardment_radius_slider',
                type = 'slider',
                minimum_value = 0,
                maximum_value = 10,
                value = settings.radius or 6,
                tooltip = {'artillery-bombardment-remote.config-radius-tooltip'}
            }
        )
        local radius_slider_text =
            radius_slider_flow.add(
            {
                name = 'artillery_bombardment_radius_textbox',
                type = 'textfield',
                text = settings.radius or 6,
                tooltip = {'artillery-bombardment-remote.config-radius-tooltip'}
            }
        )
        player.opened = frame
    end
}

local function on_mod_item_opened(event)
    if draw_gui_functions[event.item.name] then
        if not global[event.player_index] then
            global[event.player_index] = {}
        end
        draw_gui_functions[event.item.name](event)
    end
end
script.on_event(defines.events.on_mod_item_opened, on_mod_item_opened)

local gui_change_handlers = {
    artillery_bombardment_x_slider = function(event)
        local settings = global[event.player_index]
        event.element.slider_value = math.floor(event.element.slider_value)
        settings.x = event.element.slider_value
        event.element.parent.artillery_bombardment_x_textbox.text = event.element.slider_value
    end,
    artillery_bombardment_x_textbox = function(event)
        local settings = global[event.player_index]
        if tonumber(event.element.text) and math.floor(tonumber(event.element.text)) >= 1 then
            settings.x = math.floor(tonumber(event.element.text))
            event.element.parent.artillery_bombardment_x_slider.slider_value = tonumber(event.element.text)
        elseif not tonumber(event.element.text) and string.len(event.element.text) > 0 then
            event.element.text = settings.x or event.element.parent.artillery_bombardment_x_slider.slider_value
        end
    end,
    artillery_bombardment_y_slider = function(event)
        local settings = global[event.player_index]
        event.element.slider_value = math.floor(event.element.slider_value)
        settings.y = event.element.slider_value
        event.element.parent.artillery_bombardment_y_textbox.text = event.element.slider_value
    end,
    artillery_bombardment_y_textbox = function(event)
        local settings = global[event.player_index]
        if tonumber(event.element.text) and math.floor(tonumber(event.element.text)) >= 1 then
            settings.y = math.floor(tonumber(event.element.text))
            event.element.parent.artillery_bombardment_y_slider.slider_value = tonumber(event.element.text)
        elseif not tonumber(event.element.text) and string.len(event.element.text) > 0 then
            event.element.text = settings.y or event.element.parent.artillery_bombardment_y_slider.slider_value
        end
    end,
    artillery_bombardment_column_slider = function(event)
        local settings = global[event.player_index]
        event.element.slider_value = math.floor(event.element.slider_value)
        settings.col_count = event.element.slider_value
        event.element.parent.artillery_bombardment_column_textbox.text = event.element.slider_value
    end,
    artillery_bombardment_column_textbox = function(event)
        local settings = global[event.player_index]
        if tonumber(event.element.text) and math.floor(tonumber(event.element.text)) >= 1 then
            settings.col_count = math.floor(tonumber(event.element.text))
            event.element.parent.artillery_bombardment_column_slider.slider_value = tonumber(event.element.text)
        elseif not tonumber(event.element.text) and string.len(event.element.text) > 0 then
            event.element.text = settings.col_count or event.element.parent.artillery_bombardment_column_slider.slider_value
        end
    end,
    artillery_bombardment_radius_slider = function(event)
        local settings = global[event.player_index]
        event.element.slider_value = math.floor(event.element.slider_value)
        settings.radius = event.element.slider_value
        event.element.parent.artillery_bombardment_radius_textbox.text = event.element.slider_value
    end,
    artillery_bombardment_radius_textbox = function(event)
        local settings = global[event.player_index]
        if tonumber(event.element.text) and math.floor(tonumber(event.element.text)) >= 0 then
            settings.radius = math.floor(tonumber(event.element.text))
            event.element.parent.artillery_bombardment_radius_slider.slider_value = tonumber(event.element.text)
        elseif not tonumber(event.element.text) and string.len(event.element.text) > 0 then
            event.element.text = settings.radius or event.element.parent.artillery_bombardment_radius_slider.slider_value
        end
    end
}
local function on_gui_event(event)
    if gui_change_handlers[event.element.name] then
        gui_change_handlers[event.element.name](event)
    end
end
script.on_event(defines.events.on_gui_text_changed, on_gui_event)
script.on_event(defines.events.on_gui_value_changed, on_gui_event)

local function on_gui_closed(event)
    local player = game.players[event.player_index]
    local frame = player.gui.center.artillery_bombardment_config
    if frame then
        frame.destroy()
    end
end
script.on_event(defines.events.on_gui_closed, on_gui_closed)

local function on_init(event)
    storage.fabr = {}
    storage.fabr.chunks = {}
end
script.on_init(on_init)

local function on_configuration_changed(event)
    if not storage.fabr then
        storage.fabr = {}
        storage.fabr.chunks = {}
    end
end
script.on_configuration_changed(on_configuration_changed)

local function on_nth_tick()
    -- on_tick handler for iterating over artillery turrets to mark max distance flares
    -- currently limited to 3 points every 5 ticks to reduce UPS loss
    -- currently processes the first chunk id in the available chunks list
    if next(storage.fabr.chunks) ~= nil then
        local chunkid, data = next(storage.fabr.chunks)
        --log(serpent.block(chunkid))
        --log(serpent.block(data))

        local chunk_pos_x, chunk_pos_y = chunkid_to_chunk_position(chunkid)
        local surface = data.surface
        local force = data.force
        -- limited to 3 calculations per 5 ticks
        for i = data.i, data.i + 3 do
            -- get angle
            local angle = i * math.pi / 180
            -- get co-ordinates
            local ptx = chunk_pos_x + data.artillery_range * math.cos(angle)
            local pty = chunk_pos_y + data.artillery_range * math.sin(angle)
            -- get chunk at that position
            local attack_chunk_pos = position_to_chunk({x = ptx, y = pty})
            -- check if charted
            if not force.is_chunk_charted(surface, {attack_chunk_pos.x, attack_chunk_pos.y}) then
                --log(serpent.block(attack_chunk_pos))
                -- Mark chunks with flare for exploration
                surface.create_entity(
                    {
                        name = 'artillery-flare',
                        position = {(attack_chunk_pos.x * 32) + 16, (attack_chunk_pos.y * 32) + 16},
                        force = force,
                        movement = {0, 0},
                        height = 0,
                        vertical_speed = 0,
                        frame_speed = 0
                    }
                )
            end
        end
        -- remove finished artillery positions
        if data.i + 1 >= 360 then
            data = nil
            storage.fabr.chunks[chunkid] = nil
        else
            data.i = data.i + 3
        end
    end

    if storage.fabr.chunks ~= nil then
        for chunkid, data in pairs(storage.fabr.chunks) do
        end
    end
end
script.on_nth_tick(5, on_nth_tick)
