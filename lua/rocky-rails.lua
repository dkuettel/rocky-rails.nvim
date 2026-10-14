---@namespace rocky-rails

local M = {}

---@alias Cross {c:string?,u:string?,l:string?,d:string?,r:string?}
---@alias Connectivity {u:bool,l:bool,d:bool,r:bool}

---@param r integer relative
---@param c integer relative
---@return string?
local function get_char(r, c)
    -- (1,0)-based indexing
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    row = row + r
    col = col + c
    local m = unpack(vim.api.nvim_buf_get_text(0, row - 1, col, row - 1, col + 1, {}))
    if not m or m == "" then
        return nil
    end
    return m
end

---@type table<string,Connectivity>
local connectivities = { o = { u = true, l = true, d = true, r = true } }

---@return Connectivity
local function get_connectivity(m)
    local none = { u = false, l = false, d = false, r = false }
    return connectivities[m] or none
end

---@return Cross
local function get_cross()
    return {
        c = get_char(0, 0),
        u = get_char(-1, 0),
        l = get_char(0, -1),
        d = get_char(1, 0),
        r = get_char(0, 1),
    }
end

---@param cross Cross
---@return string[]
local function get_candidates(cross)
    local cons = {
        u = get_connectivity(cross.u),
        l = get_connectivity(cross.l),
        d = get_connectivity(cross.d),
        r = get_connectivity(cross.r),
    }
    local cans = {}
    if cons.u.d and cons.d.u then
        table.insert(cans, "|")
    end
    if cons.l.r and cons.r.l then
        table.insert(cans, "-")
    end
    return cans
end

function M.cycle()
    local cross = get_cross()
    if not cross.c then
        return
    end
    local candidates = get_candidates(cross)
    local new = nil
    for i, can in ipairs(candidates) do
        if can == cross.c then
            new = candidates[(i % #candidates) + 1]
            break
        end
    end
    if not new then
        new = candidates[1]
    end
    vim.print { cross = cross, candidates = candidates, new = new }
    vim.cmd.normal { args = { "r" .. new }, bang = true }
end

return M
