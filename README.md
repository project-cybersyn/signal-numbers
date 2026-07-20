# Signal Numbers

## Description

**Signal Numbers is a library mod intended for use by other mod developers. It does not make gameplay changes.**

**Signal Numbers** is a tool for CPU usage optimiziation in mods that make extensive use of `SignalID`s. During the data phase, it creates deterministic numerical hash codes for all possible `SignalID`s and stores it in `mod-data`. It also provides a small library that can be `require`d by consuming mods in the control phase to quickly map between `SignalID`s and corresponding numerical hash codes.

## How to Use

First you must add `signal-numbers` as a dependency in your mod's `info.json`. Then during the control phase you can import the library code:

```lua
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
