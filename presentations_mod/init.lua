 local ie = _G
 if minetest.request_insecure_environment then
	 ie = minetest.request_insecure_environment()
	 if not ie then
		 error("Insecure environment required!")
	 end
 end

 Http  = ie.require("socket.http")
 Ltn12 = ie.require("ltn12")

 Modname = minetest.get_current_modname()
 Modpath = minetest.get_modpath(Modname)


currentTexturePath = "img.png"

displays = {}
nextDisplayIndex =0

local DisplayEntity = {
    initial_properties = {
        hp_max = 1,
        physical = true,
        collide_with_objects = false,
        collisionbox = {-.5, -.5, -.1, .5, .5, .1},
        visual = "mesh",
        mesh = "test.obj",
        visual_size = {x = 1, y = 1},
        textures = {"img.png"},
        spritediv = {x = 1, y = 1},
        initial_sprite_basepos = {x = 0, y = 0},
    },

    id = -1
}

function DisplayEntity:on_activate(staticdata, dtime_s)
    
    if staticdata ~= nil and staticdata ~= "" then
        local data = minetest.parse_json(staticdata)
        self.id = data.id
    end
    
    if self.id <0 then
        self.id = nextDisplayIndex
        nextDisplayIndex = nextDisplayIndex + 1
    end
    
    displays[self.id] = self
    
end


function  DisplayEntity:get_staticdata()
    return minetest.write_json({
        id = self.id
    })
end


function DisplayEntity:on_rightclick(clicker)
    self.object:set_properties ({
        textures = {currentTexturePath}
    })
    minetest.show_formspec(clicker:get_player_name(), Modname .. ":testSpec", testSpec)
end

minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname ~= Modname .. ":testSpec" then
        return
    end

    if fields.URL then
        local resName = downloadAndSaveTexture(fields.URL)
        if resName then
            minetest.chat_send_all("Saved " .. resName)
            currentTexturePath = resName
            end
    end
end)


local string testSpec = 
"formspec_version[4]" ..
"size[10,5]" ..
"label[1,1;Please insert URL Here:]" ..
"field[1,2;8,1;URL;URL;]"

minetest.register_entity(Modname .. ':display', DisplayEntity)

function downloadAndSaveTexture(url)
        minetest.chat_send_all("HTTP Request: " .. url)
		local method = "GET"
		local resp   = {}

		local client, code, headers, status = Http.request({url=url, sink=Ltn12.sink.table(resp), method=method })
            
        if code == 200 then
			
            if resp then
                local data = table.concat(resp);
                if data then
                    --minetest.chat_send_all("DataLength: " .. data);
                    --minetest.chat_send_all(hex_dump(data))
                    local name = url:match( "([^/]+)$" )

                    local path =  Modpath .. DIR_DELIM .. "textures" .. DIR_DELIM .. name
                    local file = io.open(path, "w+")
                    io.output(file)
                    io.write(data)
                    io.close(file)

                    --for key,value in pairs(minetest) do
                      --  if(key)
                      --  minetest.chat_send_all(key);
                    --end

                    minetest.dynamic_add_media(path)
                    --    minetest.chat_send_all( name .. "confirmed")
                    --end)

                    --minetest.chat_send_all("Dynamic addition: " .. res)
                    --minetest.chat_send_all("Saving " .. name .. " to: " .. path)
                    return name
                end
                return nil
            end
        else
            minetest.chat_send_all("ERROR: " ..code)
            return nil
        end
end

function hex_dump (str)
    local len = string.len( str )
    local dump = ""
    local hex = ""
    local asc = ""
    
    for i = 1, len do
        if 1 == i % 8 then
            dump = dump .. hex .. asc .. "\n"
            hex = string.format( "%04x: ", i - 1 )
            asc = ""
        end
        
        local ord = string.byte( str, i )
        hex = hex .. string.format( "%02x ", ord )
        if ord >= 32 and ord <= 126 then
            asc = asc .. string.char( ord )
        else
            asc = asc .. "."
        end
    end

    
    return dump .. hex
            .. string.rep( "   ", 8 - len % 8 ) .. asc
end