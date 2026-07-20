# Signal Numbers

## Description

**Signal Numbers is a library mod intended for use by other mod developers. It does not make gameplay changes.**

**Signal Numbers** is a tool for CPU usage optimiziation in mods that make extensive use of `SignalID`s. It creates a two-way deterministic hash mapping between `SignalID`s and Lua numbers, associating a unique number to each `SignalID` and vice versa.

This scheme has several advantages over typical string-based signal hashing schemes:

- No string concatenation or other Lua garbage creation.
- No cache misses/string parsing of novel keys. (all possible keys are prepopulated)
- Fastest possible hash lookups inside Lua (byval hashing of the number's bits)

The tradeoff is the usage of a modest amount of memory to hold the complete hash table.

## How to Use

First you must add `signal-numbers` as a dependency in your mod's `info.json`. Then during the control phase you can import the library code:

```lua
-- `control.lua`
local signal_numbers = require("__signal-numbers__.signal-numbers")
```

The following methods are available:

- **number_to_signal**
```lua
---Convert a SignalNumber to a SignalID. Returns nil if the number is not valid.
---@param sn SignalNumber
---@return SignalID?
local signal_id = signal_numbers.number_to_signal(sn)
```

- **signal_to_number**
```lua
---Convert a SignalID to a SignalNumber. Returns nil if the signal is not valid.
---@param sid SignalID
---@return SignalNumber?
local sn = signal_numbers.signal_to_number(sid)
```

- **exploded_signal_to_number**
```lua
---Convert exploded SignalID fields to a SignalNumber. Returns nil if the signal is not valid.
---@param ty SignalIDType?
---@param name string?
---@param quality QualityID?
---@return SignalNumber?
local signal_number = signal_numbers.exploded_signal_to_number(ty, name, quality)
```

## Contributing

Please use the [GitHub repository](https://github.com/project-cybersyn/signal-numbers) for questions, bug reports, or pull requests.
