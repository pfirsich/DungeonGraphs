local lg = love.graphics

local lineColor = {255, 255, 255, 255}
local tileSize = 64
local tilesN = 200
local tileMap = {}
local tiles = {}
local mode = "default"
local showGrid = true
modes = {
    default = {},
    chooseTile = {},
}

local EMPTY = 0
local CONNECTOR = -1
local LINE_END = -2
local LINE_BASE = -10

function love.load()
    local files = love.filesystem.getDirectoryItems("tiles")
    table.sort(files)
    for _, file in ipairs(files) do
        table.insert(tiles, lg.newImage("tiles/" .. file))
    end

    for y = 1, tilesN do
        tileMap[y] = {}
        for x = 1, tilesN do
            tileMap[y][x] = EMPTY--math.max(0, love.math.random(-5, #tiles))
        end
    end
    tileMap[1][1] = 9 -- entrance

    lg.setBackgroundColor(180, 180, 180)
end

local isDown = love.keyboard.isDown
function love.keypressed(key)
    local ctrl = isDown("lctrl") or isDown("rctrl")
    local shift = isDown("lshift") or isDown("rshift")

    if key == "space" then
        showGrid = not showGrid
    end

    if modes[mode].keypressed then
        modes[mode].keypressed(key)
    end
end

function love.mousepressed(x, y, button)
    if modes[mode].mousepressed then
        modes[mode].mousepressed(x, y, button)
    end
end

function love.update(dt)
    modes[mode].update(dt)
end

function love.draw()
    modes[mode].draw()
end

function modes.chooseTile.update(dt)

end

function modes.chooseTile.draw()
    lg.setColor(255, 255, 255)
    local tx, ty = 1, 1
    for i = 1, #tiles do
        local x, y = (tx-1)*tileSize, (ty-1)*tileSize
        local w, h = tiles[i]:getDimensions()
        lg.draw(tiles[i], x, y, 0, tileSize/w, tileSize/h)
        tx = tx + 1
        if tx > math.ceil(math.sqrt(#tiles)) then
            ty = ty + 1
            tx = 1
        end
    end
end

function modes.chooseTile.mousepressed(x, y, button)
    local tx, ty = math.floor(x/tileSize) + 1, math.floor(y/tileSize) + 1
    if button == 1 then
        local maxTx = math.ceil(math.sqrt(#tiles))
        if tx > maxTx then
            return
        end
        local index = (ty-1) * maxTx + tx
        if index > #tiles then
            return
        end

        local stx, sty = unpack(modes["chooseTile"].tileToChange)
        tileMap[sty][stx] = index
        updateTilemap()
        mode = "default"
    end
end

function modes.chooseTile.keypressed(key)
    if key == "escape" then
        mode = "default"
    end
end

function modes.default.update(dt)

end

-- up*8 + down*4 + 2*left + right
local lineFuncs = {
    [3] = function() -- left + right
        lg.line(0, tileSize/2, tileSize, tileSize/2)
    end,
    [6] = function() -- left + down
        lg.line(0, tileSize/2, tileSize/2, tileSize/2)
        lg.line(tileSize/2, tileSize/2, tileSize/2, tileSize)
    end,
    [7] = function() -- left + right + down
        lg.line(0, tileSize/2, tileSize, tileSize/2)
        lg.line(tileSize/2, tileSize/2, tileSize/2, tileSize)
    end,
    [12] = function() -- up + down
        lg.line(tileSize/2, 0, tileSize/2, tileSize)
    end,
    [13] = function() -- up + down + right
        lg.line(tileSize/2, 0, tileSize/2, tileSize)
        lg.line(tileSize/2, tileSize/2, tileSize, tileSize/2)
    end,
}

function drawLine(x, y, line)
    lg.push()
    lg.translate(x, y)
    lg.setColor(255, 255, 255)
    lg.setLineWidth(4)
    if lineFuncs[line] then
        lineFuncs[line]()
    else
        lg.rectangle("fill", tileSize/4, tileSize/4, tileSize/2, tileSize/2)
    end
    lg.setLineWidth(1)
    lg.setColor(50, 50, 50)
    lg.pop()
end

function modes.default.draw()
    local winW, winH = lg.getDimensions()

    lg.setColor(50, 50, 50)
    for ty = 1, tilesN do
        local y = (ty-1)*tileSize
        if showGrid then lg.line(0, y, tilesN*tileSize, y) end
        for tx = 1, tilesN do
            local x = (tx-1)*tileSize
            if showGrid then lg.line(x, 0, x, tilesN*tileSize) end
            if tileMap[ty][tx] > EMPTY then
                local img = tiles[tileMap[ty][tx]]
                local w, h = img:getDimensions()
                lg.setColor(255, 255, 255)
                lg.draw(img, x, y, 0, tileSize/w, tileSize/h)
                lg.setColor(50, 50, 50)
            end
            if tileMap[ty][tx] == CONNECTOR then
                drawLine(x, y, getTileSurroundings(tx, ty))

                lg.setColor(255, 255, 255)
                lg.circle("fill", x + tileSize/2, y + tileSize/2, tileSize/8, 32)
                lg.setColor(0, 0, 0)
                lg.circle("line", x + tileSize/2, y + tileSize/2, tileSize/8, 32)
                lg.setColor(50, 50, 50)
            end
            if tileMap[ty][tx] < LINE_BASE then
                local line = -tileMap[ty][tx] + LINE_BASE
                drawLine(x, y, line)
            end
        end
    end
end

function modes.default.mousepressed(x, y, button)
    local tx, ty = math.floor(x/tileSize) + 1, math.floor(y/tileSize) + 1
    if button == 1 then
        if tx > 1 and ty > 1 then
            mode = "chooseTile"
            modes["chooseTile"].tileToChange = {tx, ty}
        end
    elseif button == 2 then
        if tileMap[ty][tx] < LINE_BASE then
            tileMap[ty][tx] = CONNECTOR
        else
            tileMap[ty][tx] = EMPTY
        end
        updateTilemap()
    end
end

function checkTile(x, y)
    if x < 1 or y < 1 or x > tilesN or y > tilesN then return 0 end
    return tileMap[y][x] ~= EMPTY and 1 or 0
end

function getTileSurroundings(x, y)
    local up = checkTile(x, y - 1)
    local down = checkTile(x, y + 1)
    local left = checkTile(x - 1, y)
    local right = checkTile(x + 1, y)
    return 8*up + 4*down + 2*left + right
end

function updateTilemap()
    for ty = 1, tilesN do
        for tx = 1, tilesN do
            if tileMap[ty][tx] < LINE_BASE then
                tileMap[ty][tx] = EMPTY
            end
        end
    end

    -- this stores the "root" horizontal lines
    local rootLineMap = {}
    for y = 1, tilesN do
        rootLineMap[y] = {}
        for x = 1, tilesN do
            rootLineMap[y][x] = false
        end
    end

    -- find connectors and entrance and draw root lines from there
    for y = 1, tilesN do
        for x = 1, tilesN do
            if tileMap[y][x] == CONNECTOR or y == 1 then
                for cx = x + 1, tilesN do
                    if tileMap[y][cx] == LINE_END then
                        break
                    end
                    rootLineMap[y][cx] = true
                end
            end
        end
    end

    -- no find every non-empty tile and draw lines up until the root line and along it
    for y = 1, tilesN do
        for x = 1, tilesN do
            if tileMap[y][x] > EMPTY then
                -- draw up to the root line
                for ly = y - 1, 1, -1 do
                    if tileMap[ly][x] == EMPTY then
                        tileMap[ly][x] = LINE_BASE - 1
                    end

                    -- we hit a root line
                    if rootLineMap[ly][x] then
                        -- draw back to it's start
                        for lx = x, 1, -1 do
                            if tileMap[ly][lx] == EMPTY then
                                tileMap[ly][lx] = LINE_BASE - 1
                            end

                            if tileMap[ly][lx] == CONNECTOR or lx == 1 then
                                break
                            end
                        end

                        break
                    end
                end
            end
        end
    end

    for y = 1, tilesN do
        for x = 1, tilesN do
            if tileMap[y][x] < LINE_BASE then
                tileMap[y][x] = LINE_BASE - getTileSurroundings(x, y)
            end
        end
    end
end