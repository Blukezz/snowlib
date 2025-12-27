--!strict
--!native

--[[

    FABRIK Module
    Blukez

    i want this to work as seamlessly as possilbe wiht snoowlib, which can be done through the To dynamic option so ill have to design this\ give the target limb cframe as easily as possilbe


]]--

local Kinematics = {}

local Segment = {}
Segment.__index = Segment

function Segment.new(Length: number)
    local self = setmetatable({}, Segment)

    self.Length = Length
    self.CFrame = nil

    return self
end

local Joint = {}
Joint.__index = Joint

function Joint.new(Position: number?)
    local self = setmetatable({}, Joint)

    self.AngleConstraint = nil
    self.Position = Position

    return self
end

local function ChainLength(Chain)
    local TotalSegmentLength = 0

    for Index = 2, #Chain, 2 do
        local CurrentSegment = Chain[Index]
        TotalSegmentLength += CurrentSegment.Length
    end

    return TotalSegmentLength
end

local function IsPossible(Chain, Origin: Vector3, Target: Vector3)
    return ChainLength(Chain) > (Target - Origin).Magnitude
end

local function IterateBackwards(Chain, Target: Vector3)
    Chain[#Chain].Position = Target

    for Index = #Chain, 1, -2 do
        local CurrentJoint = Chain[Index]

        local NextJoint = Chain[Index - 2]
        local NextSegment = Chain[Index - 1]

        local Direction = (NextJoint.Position - CurrentJoint.Position).Unit
        NextJoint.Position = CurrentJoint.Position + (NextSegment.Direction * NextSegment.Length)
    end
end

local function IterateForwards(Chain, Origin: Vector3)
    Chain[1].Position = Origin

    for Index = 1, #Chain, 2 do
        local CurrentJoint = Chain[Index]

        local NextJoint = Chain[Index + 2]
        local NextSegment = Chain[Index + 1]

        local Direction = (NextJoint.Position - CurrentJoint.Position).Unit
        NextJoint.Position = CurrentJoint.Position + (NextSegment.Direction * NextSegment.Length)
    end
end

function Kinematics:Solve(Chain, Origin: Vector3 ,Target: Vector3, Tolerance: number?, MaxIterations: number?)
    local Tolerance = Tolerance or 0.01
    local MaxIterations = MaxIterations or 15

    if IsPossible(Chain, Origin, Target) then
        local Direction = (Target - Origin).Unit
        
        Chain[1].Position = Origin
        
        for Index = 2, #Chain, 2 do
            local CurrentSegment = Chain[Index]
            local LastJoint = Chain[Index - 1]
            local NextJoint = Chain[Index + 1]
            
            NextJoint.Position = LastJoint.Position + (Direction * CurrentSegment.Length)
        end
    else
        for Interations = 1, MaxIterations do
            IterateBackwards(Chain, Target)
            IterateForwards(Chain, Origin)

            local Distance = (Target - Chain[#Chain].Position).Magnitude

            if Distance <= Tolerance then
                break
            end
        end
    end

    for Index = 2, #Chain, 2 do
        local CurrentSegment = Chain[Index]
        local LastJoint = Chain[Index - 1]
        local NextJoint = Chain[Index + 1]

        local CenterPosition = LastJoint.Position + ((NextJoint.Position - LastJoint.Position) / 2)

        CurrentSegment.CFrame = CFrame.lookAt(CenterPosition, NextJoint.Position)
    end
end

Kinematics.Joint = Joint
Kinematics.Segment = Segment

return Kinematics