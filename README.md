> [!NOTE]
> Still a work in progress, expect bugs and untested features as this project is getting set up. And as a part of a larger project, it is the main export format of Snow Animator (coming soon) which is not unlike another animation tool, Moon Animator. To make a new workflow option for developers.

# snowlib

![GET FROM](https://img.shields.io/badge/get_from-grey?style=for-the-badge)
[![LOADSTRING](https://img.shields.io/badge/loadstring-skyblue?style=for-the-badge)](#loadstring)
[![WALLY](https://img.shields.io/badge/wally-lightblue?style=for-the-badge)](#wally)
[![MODEL](https://img.shields.io/badge/model-lightcyan?style=for-the-badge)](#model)
[![RBXM](https://img.shields.io/badge/RBXM-snow?style=for-the-badge)](https://github.com/Blukezz/snowlb/releases/latest)
⁥ ⁥ ⁥ ⁥ ⁥ ⁥ ⁥ ⁥ ⁥ ⁥ ⁥ ⁥ ⁥ ⁥⁥⁥⁥ ⁥ ⁥ ⁥ ⁥ ⁥ ⁥ ⁥ ⁥ ⁥ ⁥ ⁥ ⁥ ⁥⁥⁥⁥ ⁥ ⁥ ⁥⁥⁥⁥⁥⁥⁥⁥
![VERSION](https://img.shields.io/github/v/release/Blukezz/snowlib?style=for-the-badge&color=lightskyblue)
⁥ ⁥ ⁥ ⁥ ⁥ ⁥⁥⁥⁥
[![DISCORD](https://img.shields.io/badge/Discord-powderblue.svg?&logo=discord&logoColor=black&style=for-the-badge)](https://discord.gg/Byq78say2g)


snowlib is a flexible CFrame animation library that supports both **classic procedural animations** and **modern-era keyframe animation and its tools**. Under one clean [TweenService](https://create.roblox.com/docs/reference/engine/classes/TweenService) inspired API but with the power of raw math.

## Key Features

- [FABRIK](#FABRIK) (Inverse Kinematics)

- [Additive](#Additive) Animations
- Animation  [Blending](#Blending)
- Framerate Independece
- [Easing](#easing) Functions
- [Bezier](#bezier) Functions
- Framerate Adaptation for Damping Animations
- "[Dynamic](#animationnew-at-a-glance)" Options

## `Animation.new()` At a Glance

Make a new `Animation` object with the `Animation.new()` function!

> [!TIP]
> Values in the `Options` table can be functions! (aka a Dynamic Option™) They would be ran every frame and would use what the Dynamic Option returns. Go crazy with it!

```lua
function Animation.new(
    Object: Instance,
    -- required | Any instance that takes CFrame as a property
    Property: string,
    -- required | The name of the CFrame property that you want to animate ex: "CFrame"
    Options: {
	    To: CFrame | () -> CFrame,
        -- required | The target CFrame to animating to or a function that returns a CFrame of what to animate to
	    From: (CFrame?) | () -> (CFrame?) | ("Current" | "Live")?,
        -- optional | The starting CFrane, a function, 
        --   "Current" to set it to the Current property value when the function is ran,
        --   or "live" to continuously update it to the current property value each frame, useful for damping
        -- "Current" by default
	    Alpha: (number?) | () -> number?,
        -- optional | The interpolation factor
        -- by default, it automatically progresses based on the elapsed time and the duration
        Weight: (number?) | () -> number?,
        -- optional | Animation weight, the percentage which the animation would be blended/added to existing animations
        --   use a negative number for additive animations and a positive number for blending animations
        -- nil by default, sets as a base animation that overrides
	    Easing: (number) -> number?,
        -- optional | The easing function to apply, use snowlib.Easing for presets or snowlib.Bezier for custom ones
	    Duration: (number?) | () -> number?
        -- optional | The time the animation lasts
        --   if Alpha is used the duration would no long affect the speed of the animation
        -- by default the animation would last forever
    }
)
```

Returns a new `Animation` object that can be played with `:Play()`, reset with `:Reset()` and/or be paused with `:Stop()`

## Examples

Here's a simple animation that moves `Part` to `0, 10, 0` in 3 seconds (now with easing).

> [!TIP]
> Don't want to make 1 billion variables for all the animations? You can create a immediately run a animation if you'd like! It'll get garbage collected once it stops playing.

```lua
local Part = Instance.new("Part", game.Workspace)
Part.Anchored = true

local Animation = snowlib.Animation
local EasingFuncs = snowlib.Easing

local AnimationExample = Animation.new(Part, "CFrame", {
    To = CFrame.new(0, 10, 0),
    Easing = EasingFuncs.Quad.Out,
    Duration = 3
})

AnimationExample:Play()
```

`clerp` CFrame animations are pretty ancient, but here's one! They are a sort of a "damping animation" since every frame it moves 0.3 times or 30% closer to the target while using the CFrame from the last frame. Making a "out" easing function-like look.

```lua
  while wait() do
    wing1w.C0 = clerp(wing1w.C0,cf(-1,0.5,2)*angles(math.rad(80),math.rad(90),math.rad(0)),.3)
    wing2w.C0 = clerp(wing2w.C0,cf(-1,0,2)*angles(math.rad(85),math.rad(90),math.rad(0)),.3)
    wing3w.C0 = clerp(wing3w.C0,cf(-1,-0.5,2)*angles(math.rad(90),math.rad(90),math.rad(0)),.3)
  end
```

Same animation, but with snowlib.

```lua
Animation.new(wing1w, "C0", { To = cf(1,-0.5,2) * angles(math.rad(90),math.rad(270),math.rad(0)), Alpha = .3, From = "Live" }):Play()
Animation.new(wing2w, "C0", { To = cf(-1,0,2) * angles(math.rad(85),math.rad(90),math.rad(0)), Alpha = .3,  From = "Live" }):Play()
Animation.new(wing3w, "C0", { To = cf(-1,-0.5,2) * angles(math.rad(90),math.rad(90),math.rad(0)), Alpha = .3, From = "Live" }):Play()
```

## Easing

> [!NOTE]
> See https://easings.net for more information on all of the included easing functions!

Easing function are a mathematical formula that controls the speed and timing of an animation that come in various styles and directions for example: Quad Out starts fast and ends slower.

Use `snowlib.Easing` to get the table of easing functions and then index the easing style then the direction to get the easing function.

Here's a quick example.

```lua
local Easing = snowlib.Easing

local BackOut = Easing.Back.Out -- A function (number) -> number
```

## Bezier

Via the `Bezier.Quadratic` and `Bezier.Cubic` functions you can create whats essentially custom easing functions defined by a few points that (usually) go from 0 - 1. 

> [!TIP]
> You can use https://cubic-bezier.com/ to graphically make a cubic bezier easing function and copy + paste the numbers!

The Bezier functions in snowlib take in numbers like a conventional `cubic-bezier()` function but the ones in [bezier.lua](./bezier.lua) return functions that take in a number from 0 - 1 and output a number from 0 - 1. Similar to functions in [easings.lua](./easing.lua).

Here's a quick example.

```lua
local Part = Instance.new("Part", game.Workspace)
Part.Anchored = true

local Animation = snowlib.Animation
local CubicBezier = snowlib.Bezier.Cubic

local AnimationExample = Animation.new(Part, "CFrame", {
    To = CFrame.new(0, 10, 0),
    Easing = CubicBezier(0,.69,.65,.56) -- a custom easing function
    Duration = 3
})

AnimationExample:Play()
```

## Additive

planning on adding info here later

## Blending

planning on adding info here later

## Loadstring

nothign here yet

## Wally

noting here yet

## Model

nothing here yet

## Credits

`@egomoose` for the [explanation video](https://www.youtube.com/watch?v=UNoX65PRehA) on FABRIK.

`@index_self` for the code in a [devforum comment](https://devforum.roblox.com/t/luau-easing-styles-implementation/2806396/12) which is the code in [easings.lua](./easing.lua) (im lazy :p).

`@roblox` for their [bezier curve guide](https://web.archive.org/web/20221116215320/https://create.roblox.com/docs/mechanics/bezier-curves)! (article was deleted, the link uses the WayBack machine)

## color pallete

⁥![Version](https://img.shields.io/badge/version-0.3.2-skyblue?style=for-the-badge)
⁥![Version](https://img.shields.io/badge/version-0.3.2-lightskyblue?style=for-the-badge)
⁥![Version](https://img.shields.io/badge/version-0.3.2-lightblue?style=for-the-badge)
⁥![Version](https://img.shields.io/badge/version-0.3.2-powderblue?style=for-the-badge)
⁥![Version](https://img.shields.io/badge/version-0.3.2-lightcyan?style=for-the-badge)
⁥![Version](https://img.shields.io/badge/version-0.3.2-snow?style=for-the-badge)