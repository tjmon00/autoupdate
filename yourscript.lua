local Base = {
    name = "Your Script Name", -- used for output messages
    debug = true, -- true to show error messages

    host = self,
    print = function(self, message)
        print(self.name .. ": " .. message)
    end,
    error = function(self, message)
        if self.debug then
            error(self.name .. ": " .. message)
        end
    end,
    reload = function(self)
        Wait.condition(function()
            return not self.host or self.host.reload()
        end, function()
            return not self.host or self.host.resting
        end)
    end
}

local AutoUpdate  = setmetatable({
    version = "1.0.0", -- current version of your script, must match the .ver file contents
    versionUrl = "https://raw.githubusercontent.com/yourname/yourrepo/refs/heads/main/yourscript.ver", -- text file with the version number, eg: 1.0.0
    scriptUrl = "https://raw.githubusercontent.com/yourname/yourrepo/refs/heads/main/yourscript.lua", -- latest version of your script

    run = function(self)
        WebRequest.get(self.versionUrl, function(request)
            if request.response_code ~= 200 then
                self:error("Failed to check version (" .. request.response_code .. ": " .. request.error .. ")")
                return
            end
            local remoteVersion = request.text:match("[^\r\n]+") or ""
            if self:isNewerVersion(remoteVersion) then
                self:fetchNewScript(remoteVersion)
            end
        end)
    end,
    isNewerVersion = function(self, remoteVersion)
        local function split(v)
            return { v:match("^(%d+)%.?(%d*)%.?(%d*)") or 0 }
        end
        local r, l = split(remoteVersion), split(self.version)
        for i = 1, math.max(#r, #l) do
            local rv, lv = tonumber(r[i]) or 0, tonumber(l[i]) or 0
            if rv ~= lv then
                return rv > lv
            end
        end
        return false
    end,
    fetchNewScript = function(self, newVersion)
        WebRequest.get(self.scriptUrl, function(request)
            if request.response_code ~= 200 then
                self:error("Failed to fetch new script (" .. request.response_code .. ": " .. request.error .. ")")
                return
            end
            if request.text and #request.text > 0 then
                self.host.setLuaScript(request.text)
                self:print("Updated to version " .. newVersion)
                self:reload()
            else
                self:error("New script is empty")
            end
        end)
    end,
}, { __index = Base })

--function onLoad()
--    AutoUpdate:run()
--end
