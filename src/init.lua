--[[



    *             *           *      //          ,+ ##                +     +            
      blukez's          *           //          / ##      +       +                 +    
      [*] snowanimator 1            \\        ./ ##                           +          
   *            *   snowwy!!         \\      .|`###         +            +               
           *                         //      | ####                 +            +       
      Animating, reimagined.  *     //      .|@####                          +           
            *                       \\       \@@####          +                          
     *                   *           \\       \@@@###                   +          +     
               *                     //        \.@@@###      o                           
                             *      //           \.@@@@###__/[]                          
        *                           \\             `+._@@@# ++\\                         
          __..__.---0._.__           \\                 ``--``                           


	  [+] snowlib
	   |
      [*] Version 0.3.0
       |  [+] added everything
       |  [-] removed stuff
       |  [*] changed stuff
       \__ this is a placeholder




]]--

-- // Variables n Setup

local snowlib = {}

local RunningBases = {}
local RunningDeltas = {}

local IKFunctions = require("@self/ik")
local EasingFunctions = require("@self/easing")
local BezierCurveFunctions = require("@self/bezier")

local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

-- weak table so it'll probably sove the issue of the table vlaues stacking forever
local PairIds = setmetatable({}, {__mode = "k"})

local Configuration = {
    VelocityAssist = false,
    AdaptAlphasToFramerate = true
}

local Time = {
    Now = time(),
    Ran = 0,
    Delta = 0,
    Last = time()
}

local AnimationLoop = RunService.Heartbeat:Connect(function()
    Time.Now = time()
    Time.Ran += Time.Delta
    Time.Delta = Time.Now - Time.Last
    Time.Last = time()

    for _, Animation in RunningBases do
        for _, Function in Animation.FunctionPipeline do
            Function(Animation)
        end
    end

    for _, Animation in RunningDeltas do
        for _, Function in Animation.FunctionPipeline do
            Function(Animation)
        end
    end
end)

type AnimationOptions = {
	To: CFrame | () -> CFrame,
	From: (CFrame?) | () -> (CFrame?) | ("Current" | "Live")?,
	Alpha: (number?) | () -> number?,
    Weight: (number?) | () -> number?,
	Easing: (number) -> number?,
	Duration: (number?) | () -> number?,
}

type ClassesWithCFrame = BasePart | Camera | JointInstance | CFrameValue | Attachment

-- // Functions

local function Dynamic(Property, Action)
    return function(Animation)
        Animation[Property] = Action()
    end
end

local function GetPairId(Object: Instance, Property: string)
    if not PairIds[Object] then
        PairIds[Object] = {}
    end

    local Id = PairIds[Object][Property]

     if not Id then
        Id = HttpService:GenerateGUID()
        PairIds[Object][Property] = Id
    end

    return Id
end

local PipelineFunctions = {}

PipelineFunctions.Time = {
    UpdateElapsedTime = function(Animation)
        Animation.ElapsedTime += Time.Delta
    end,
    
    UpdateProgress = function(Animation)
        Animation.Progress = Animation.ElapsedTime / Animation.Duration
    end
}

PipelineFunctions.Alpha = {
    ApplyTimeBased = function(Animation)
        Animation.Alpha = Animation.Progress
    end,
    
    AdaptToFramerate = function(Animation)
        Animation.Alpha = 1 - (1 - Animation.Alpha) ^ (Time.Delta * 60)
    end,
    
    ApplyEasing = function(Animation)
        Animation.Alpha = Animation.Easing(Animation.Progress)
    end
}

PipelineFunctions.Property = {
    UpdateLiveFrom = function(Animation)
        Animation.From = Animation.Object[Animation.Property]
    end
}

PipelineFunctions.Calculation = {
    StoreResult = function(Animation)
        local a = Animation.From
        local b = Animation.To
        local t = Animation.Alpha
        Animation.Result = a:Lerp(b, t)
    end,

    ApplyVelocity = function(Animation)
        local TargetPosition = Animation.Result.Position
        local DeltaPosition = TargetPosition - Animation.Object.Position
        local Velocity = DeltaPosition / Time.Delta
        Animation.Object.AssemblyLinearVelocity = Velocity
    end,

    ApplyResult = function(Animation)
        Animation.Object[Animation.Property] = Animation.Result
    end,

    BlendOrAddResult = function(Animation)
        Animation.Object[Animation.Property] = Animation.Object[Animation.Property]:Lerp(Animation.Result, math.abs(Animation.Weight))
    end,

    AddResult = function(Animation)
        Animation.Object[Animation.Property] = Animation.Object[Animation.Property] * CFrame.new():Lerp(Animation.Result, math.abs(Animation.Weight))
    end,
}

PipelineFunctions.Lifecycle = {
    CheckStopCondition = function(Animation)
        if Animation.ElapsedTime >= Animation.Duration or Animation.Progress >= 1 then
            Animation:Stop()
        end
    end
}


-- // Animation Class

local Animation = {}
Animation.__index = Animation

function Animation.new(Object: ClassesWithCFrame, Property: string, Options: AnimationOptions)
    local self = setmetatable({}, Animation)
    
    local ToType = typeof(Options.To)
    local FromType = typeof(Options.From)
    local AlphaType = typeof(Options.Alpha)
    local WeightType = typeof(Options.Weight)
    local EasingType = typeof(Options.Easing)
    local DurationType = typeof(Options.Duration)

    assert(Options.Alpha or Options.Duration, "The 'Alpha' and/or 'Duration' argument(s) must be present.")

    assert(ToType == "CFrame" or ToType == "function",
        "Argument 'To' must be either a CFrame or a function.")
    assert(FromType == "CFrame" or FromType == "function" or FromType == "string" or FromType == "nil",
        "Argument 'From' must be either a CFrame, string, function, or nil.")
    assert(AlphaType == "number" or AlphaType == "function" or AlphaType == "nil",
        "Argument 'Alpha' must be either a number, function, or nil.")
    assert(EasingType == "function" or EasingType == "nil",
        "Argument 'Easing' must be a function or nil.")
    assert(WeightType == "number" or WeightType == "function" or WeightType == "nil",
        "Argument 'Weight' must be either a number, function or nil.")
    assert(DurationType == "number" or DurationType == "function" or DurationType == "nil",
        "Argument 'Duration' must be either a number, function, or nil.")
    
    self.FunctionPipeline = {}

    self.Object = Object
	self.Property = Property

    self.To = nil
	self.From = nil
	self.Alpha = nil
    self.Weight = nil
	self.Easing = nil
	self.Duration = nil

    self.Progress = nil -- Progress percentage 0 - 1, nil if no duration to derive it from
    self.IsPlaying = false
    self.ElapsedTime = 0

    -- // Start of Pipline Construction
    
    table.insert(self.FunctionPipeline, PipelineFunctions.Time.UpdateElapsedTime)
    
    if Options.Duration then
        if DurationType == "function" then
            table.insert(self.FunctionPipeline, Dynamic(Options.Duration))
        end

        if DurationType == "number" then
            self.Duration = Options.Duration
        end

        table.insert(self.FunctionPipeline, PipelineFunctions.Time.UpdateProgress)
    end

    if Options.Alpha then
        if AlphaType == "function" then
            table.insert(self.FunctionPipeline, Dynamic(Options.Alpha))
        end

        if AlphaType == "number" then
            self.Alpha = Options.Alpha
        end

        if AlphaType == "number" and snowlib.AdaptAlphasToFramerate and Options.Alpha == "Live" then
            table.insert(self.FunctionPipeline, PipelineFunctions.Alpha.AdaptToFramerate)
        end
    else
        table.insert(self.FunctionPipeline, PipelineFunctions.Alpha.ApplyTimeBased)
    end

    if Options.Easing then
        self.Easing = Options.Easing
        table.insert(self.FunctionPipeline, PipelineFunctions.Alpha.ApplyEasing)
    end

    if Options.From then
        if FromType == "function" then
            table.insert(self.FunctionPipeline, Dynamic(Options.From))
        end

        if FromType == "CFrame" then
            self.From = Options.From
        end

        if FromType == "string" then
            if Options.From == "Live" then
                table.insert(self.FunctionPipeline, PipelineFunctions.Property.UpdateLiveFrom)
            end
            if Options.From == "Current" then
                self.From = self.Object[self.Property]
            end
        end
    else
		self.From = self.Object[self.Property]
    end

    if Options.To then
        if ToType == "function" then
            table.insert(self.FunctionPipeline, Dynamic(Options.To))
        end

        if ToType == "CFrame" then
            self.To = Options.To
        end
    end


    table.insert(self.FunctionPipeline, PipelineFunctions.Calculation.StoreResult)


    if snowlib.VelocityAssist and Object.AssemblyLinearVelocity then
        table.insert(self.FunctionPipeline, PipelineFunctions.Calculation.ApplyVelocity)
    end

    if Options.Weight then
        if WeightType == "function" then
            table.insert(self.FunctionPipeline, Dynamic(Options.Weight))
            table.insert(self.FunctionPipeline, PipelineFunctions.Calculation.BlendResult)
        end

        if WeightType == "number" then
            self.Weight = Options.Weight

            if self.Weight < 0 then
                table.insert(self.FunctionPipeline, PipelineFunctions.Calculation.AddResult)
            else
                table.insert(self.FunctionPipeline, PipelineFunctions.Calculation.BlendResult)
            end
        end

    else
        table.insert(self.FunctionPipeline, PipelineFunctions.Calculation.ApplyResult)
    end

    if Options.Duration then
        table.insert(self.FunctionPipeline, PipelineFunctions.Lifecycle.CheckStopCondition)
    end

    return self
end

function Animation:Reset() -- instead of the :play and stop functions reseting the animations, the user can just include this function
    self.ElapsedTime = 0
    self.Progress = 0
end

function Animation:Play()
    local AnimationTable = self.Weight and RunningDeltas or RunningBases
    local Index = self.Weight and self or GetPairId(self.Object, self.Property)

    if AnimationTable[Index] then AnimationTable[Index]:Stop() end

    self.IsPlaying = true
    AnimationTable[Index] = self
end

function Animation:Stop()
    local AnimationTable = self.Weight and RunningDeltas or RunningBases
    local Index = self.Weight and self or GetPairId(self.Object, self.Property)

    self.IsPlaying = false

    if AnimationTable[Index] ~= self then return end

    AnimationTable[Index] = nil
end

-- // Finalizaiton

snowlib.Time = Time
snowlib.Loop = AnimationLoop
snowlib.Animation = Animation
snowlib.Configuration = Configuration

snowlib.Easing = EasingFunctions
snowlib.Bezier = BezierCurveFunctions
snowlib.Kinematics = IKFunctions

return snowlib
