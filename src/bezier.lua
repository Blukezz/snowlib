--!strict
--!native

--[[

    Bezier Functions
    Blukez

    Resources used (very handy:
    https://en.wikipedia.org/wiki/B%C3%A9zier_curve
    https://blog.maximeheckel.com/posts/cubic-bezier-from-math-to-motion/
    https://web.archive.org/web/20221116215320/https://create.roblox.com/docs/mechanics/bezier-curves


    we want a function that returns a function that the aniator can use
    the function returned shhould be the bezier curve specified but in a easing fucntion "form" or number input, number output, no additonal arguments just a number from 0 - 1
]]--

local function Lerp(a: number, b: number, t: number): number
	return a + (b - a) * t
end


local Bezier = {
	Quadratic = function(p0, p1, p2): (number) -> number
		return function (t: number)
			local l1 = Lerp(p0, p1, t)
			local l2 = Lerp(p1, p2, t)
    
			return Lerp(l1, l2, t)
		end
	end,

	Cubic = function(p0, p1, p2, p3): (number) -> number
		return function(t: number)
			local l1 = Lerp(p0, p1, t)
			local l2 = Lerp(p1, p2, t)
			local l3 = Lerp(p2, p3, t)
			local l4 = Lerp(l1, l2, t)
			local l5 = Lerp(l2, l3, t)

			return Lerp(l4, l5, t)
		end
	end
}

return Bezier