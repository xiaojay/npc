local json = require("json")
local bint = require('.bint')(1024)

TARGET_WORLD_PID = "9a_YP6M7iN7b6QUoSvpoV3oe3CqxosyuJnraCucy5ss"
WAR = "xU9zFkq3X2ZQ6olwNVvr1vUWIjc3kXTWr7xKQD6dh10"
POOL = 'dBbZhQoV4Lq9Bzbm0vlTrHmOZT7NchC_Dillbmqx0tM'
Discount = 200

local function getAmountOut(amountIn, reserveIn, reserveOut, discount)
  local discounted = bint.__mul(amountIn, bint.__sub(10000, discount))
  local numerator = bint.__mul(discounted, reserveOut)
  local denominator = bint.__add(bint.__mul(10000, reserveIn), discounted)
  return bint.udiv(numerator, denominator)
end

function Register()
  Send({
    Target = TARGET_WORLD_PID,
    Tags = {
      Action = "Reality.EntityCreate",
    },
    Data = json.encode({
      Type = "Avatar",
      Metadata = {
        DisplayName = "LLAMASwap",
        SkinNumber = 1,
        Interaction = {
            Type = 'SchemaExternalForm',
            Id = 'Swap'
        },
      },
    }),
  })
end

function Move()
  Send({
    Target = TARGET_WORLD_PID,
    Tags = {
      Action = "Reality.EntityUpdatePosition",
    },
    Data = json.encode({
      Position = {
        math.random(-3, 3),
        math.random(-3, 3),
      },
    }),
  })
end

Handlers.add(
  'SchemaExternal',
  Handlers.utils.hasMatchingTag('Action', 'SchemaExternal'),
  function(msg)
    local amountIn = bint('50000000000')
    local info = Send({Target = POOL, Action = "Info"}).receive()
    local reserveIn = bint(info.PY)
    local reserveOut = bint(info.PX)
    local amountOut = getAmountOut(amountIn, reserveIn, reserveOut, Discount)
    local formatted = string.format("%.2f", math.floor(amountOut/10000000000) / 100)

    Send({
        Target = msg.From,
        Tags = { Type = 'SchemaExternal' },
        Data = json.encode({
          Swap = {
            Target = WAR,
            Title = "Swap for Some $LLAMA coins ?",
            Description = [[
              Swap 0.05 $AR for at least ]] ..  formatted ..  [[ $LLAMA. 
              And check out swap result at https://www.permaswap.network/#/ao
              ]],
            Schema = {
              Tags = json.decode(SwapSchemaTags(amountOut)),
            },
          },
        })
      })
  end
)

function SwapSchemaTags(minAmountOut)
  local minOut = tostring(minAmountOut)
  return [[
  {
  "type": "object",
  "required": [
    "Action",
    "Recipient",
    "Quantity",
    "X-PS-For",
    "X-PS-MinAmountOut"
  ],
  "properties": {
    "Action": {
      "type": "string",
      "const": "Transfer"
    },
    "Recipient": {
      "type": "string",
      "const": "]] .. POOL .. [["
    },
    "Quantity": {
      "type": "number",
      "const": ]] .. 0.05 .. [[,
      "$comment": "]] .. 1000000000000 .. [["
    },
    "X-PS-For": {
      "type": "string",
      "const": "Swap",
    },
    "X-PS-MinAmountOut": {
      "type": "string",
      "const": "]] .. minOut .. [[",
    },
  }
  }
  ]]
end

Handlers.add(
  "CronTick",                                      
  Handlers.utils.hasMatchingTag("Action", "Cron"), 
  function()
    Move()                                    
  end
)