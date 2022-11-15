local DEFAULTS = {
    line = {
        color = Color3.fromRGB(255, 0, 0),
        thickness = 0.2,
        transparency = 0.1,
    },

    plane = {
        color = Color3.fromRGB(255, 254, 254),
        transparency = 0,
        thickness = 0.1,
        grid = 4,
    }
}

local ReplicatedFirst = game:GetService("ReplicatedFirst")

local replicatedFirstShared = ReplicatedFirst:WaitForChild("Shared")

local Fusion = require(replicatedFirstShared:WaitForChild("Fusion"))
local Value = Fusion.Value
local unwrap = Fusion.unwrap

export type Line = {
    p1: Vector3,
    p2: Vector3,
    color: Color3,
    thickness: number,
    transparency: number,
    part: BasePart,
}

export type Plane = {
    p1: Vector3,
    p2: Vector3,
    p3: Vector3,
    color: Color3,
    thickness: number,
    transparency: number,
    grid: number,
    lines: table
}

local function apply(t, props)
    for k, v in pairs(props) do
        t[k] = v
    end

    return t
end

local Line: Line = {}
Line.__index = Line

function Line.new(props)
    local self: Line = setmetatable({}, Line)

    self.p1 = props.p1 or Vector3.new()
    self.p2 = props.p2 or Vector3.new()
    self.color = props.color or DEFAULTS.line.color
    self.thickness = props.thickness or DEFAULTS.line.thickness
    self.transparency = props.transparency or DEFAULTS.line.transparency
    self.visible = props.visible or true

    return self
end

function Line:draw()
    local line = self.part or Instance.new("Part")
    self.part = line

    local p1 = unwrap(self.p1)
    local p2 = unwrap(self.p2)
    local thickness = unwrap(self.thickness)

    line.Shape = Enum.PartType.Cylinder
    line.Size = Vector3.new(1, thickness, thickness)
    line.Color = unwrap(self.color)
    line.Anchored = true
    line.Material = Enum.Material.Neon
    line.CanCollide = false
    line.CanTouch = false
    line.CanQuery = false
    line.CFrame = CFrame.new(p1:Lerp(p2, 0.5), p2)
    line.Parent = game.Workspace

    return line
end

function Line:destroy()
    if self.part then
        self.part:Destroy()
    end
end

local Plane: Plane = {}
Plane.__index = Plane

function Plane.new(props)
    local self: Plane = setmetatable({}, Plane)

    self.p1 = props.p1 or Vector3.new()
    self.p2 = props.p2 or Vector3.new()
    self.p3 = props.p3 or Vector3.new()
    self.color = props.color or DEFAULTS.plane.color
    self.thickness = props.thickness or DEFAULTS.plane.thickness
    self.transparency = props.transparency or DEFAULTS.plane.transparency
    self.grid = props.grid or DEFAULTS.plane.grid
    self.visible = props.visible or true

    self.lines = {}

    return self
end

function Plane:draw()
    local p1 = self.p1
    local p2 = self.p2 -- the middle point
    local p3 = self.p3

    local grid = self.grid

    local linesUsed = 0

    local function drawLine(p1, p2)
        local thickness = self.thickness
        local color = self.color
        local transparency = self.transparency
        local lines = self.lines

        linesUsed += 1

        local line = apply(lines[linesUsed] or Line.new({}), {
            p1 = p1,
            p2 = p2,
            color = color,
            thickness = thickness,
            transparency = transparency,
        })

        lines[linesUsed] = line

        return line
    end

    -- the missing point of the rectangle formed by p1, p2, p3
    local p4 = p1 + (p3 - p2)

    -- create the vertical lines

    for i = 1, grid do
        local t = i / grid

        local p1 = p1:Lerp(p2, t)
        local p2 = p4:Lerp(p3, t)

        drawLine(p1, p2)
    end
end