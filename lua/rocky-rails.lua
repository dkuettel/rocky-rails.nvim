---@namespace rocky-rails

local M = {}

---@alias Hood {c:string?,u:string?,l:string?,d:string?,r:string?}
---@alias Connectivity {u:bool,l:bool,d:bool,r:bool}

---@param r integer relative
---@param c integer relative
---@return string?
local function get_char(r, c)
    -- (1,0)-based indexing, but its bytes, not utf8 items for cols
    local row, _col = unpack(vim.api.nvim_win_get_cursor(0))
    local col = vim.fn.getcursorcharpos()[3] - 1
    row = row + r
    col = col + c

    local l = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
    if not l then
        return nil
    end

    -- 1-based indexing
    local p = vim.str_utf_pos(l)

    local a = p[col + 1]
    if not a then
        return nil
    end
    local b = (p[col + 2] or (#l + 1)) - 1

    local m = string.sub(l, a, b)
    if not m or m == "" then
        return nil
    end

    return m
end

---@type table<string,Connectivity>
local connectivities = {
    o = { u = true, l = true, d = true, r = true },
    -- from https://en.wikipedia.org/wiki/Box-drawing_characters#Box_Drawing
    -- these are easy, but you cannot make a a "T" that only allows up-left and up-right, it always allows left-right too
    ["━"] = { u = false, l = true, d = false, r = true },
    ["┃"] = { u = true, l = false, d = true, r = false },
    ["┏"] = { u = false, l = false, d = true, r = true },
    ["┓"] = { u = false, l = true, d = true, r = false },
    ["┗"] = { u = true, l = false, d = false, r = true },
    ["┛"] = { u = true, l = true, d = false, r = false },
    ["┣"] = { u = true, l = false, d = true, r = true },
    ["┫"] = { u = true, l = true, d = true, r = false },
    ["┳"] = { u = false, l = true, d = true, r = true },
    ["┻"] = { u = true, l = true, d = false, r = true },
    ["╋"] = { u = true, l = true, d = true, r = true },
}

---@param m string?
---@return Connectivity
local function get_connectivity(m)
    local none = { u = false, l = false, d = false, r = false }
    return connectivities[m] or none
end

---@return Hood
local function get_hood_at_cursor()
    return {
        c = get_char(0, 0),
        u = get_char(-1, 0),
        l = get_char(0, -1),
        d = get_char(1, 0),
        r = get_char(0, 1),
    }
end

---@param cross Hood
---@return string[]
local function get_candidates(cross)
    local cons = {
        u = get_connectivity(cross.u),
        l = get_connectivity(cross.l),
        d = get_connectivity(cross.d),
        r = get_connectivity(cross.r),
    }
    local cans = {}
    for k, v in pairs(connectivities) do
        if
            k ~= "o"
            and (not v.u or cons.u.d)
            and (not v.l or cons.l.r)
            and (not v.d or cons.d.u)
            and (not v.r or cons.r.l)
        then
            table.insert(cans, k)
        end
    end
    return cans
end

--- cycle thru legal characters at the cursor given its neighbors
---@param forward bool? which way to cycle
function M.cycle(forward)
    if forward == nil then
        forward = true
    end

    local hood = get_hood_at_cursor()
    local ocans = get_candidates(hood)

    local cans
    if forward then
        cans = ocans
    else
        cans = vim.fn.reverse(ocans)
    end

    local next = nil
    for i, can in ipairs(cans) do
        if can == hood.c then
            next = cans[(i % #cans) + 1]
            break
        end
    end

    if not next then
        next = cans[1]
        if not next then
            next = "o"
        end
    end

    vim.cmd.normal { args = { "r" .. next }, bang = true }

    ---@diagnostic disable-next-line: redundant-parameter
    local vis = vim.iter(ocans)
        :map(function(i)
            if i == next then
                return ">" .. i .. "<"
            else
                return " " .. i .. " "
            end
        end)
        :join("")
    vim.print(vis)
end

function M.cycle_forward()
    M.cycle(true)
end

function M.cycle_backward()
    M.cycle(false)
end

--- select and insert symbol, for normal mode
function M.insert()
    ---@param item string?
    ---@param _idx integer?
    local function on_choice(item, _idx)
        if not item then
            return
        end
        vim.cmd.normal { args = { "r" .. item }, bang = true }
    end
    local cans = vim.fn.keys(connectivities)
    vim.ui.select(cans, {}, on_choice)
end

return M
