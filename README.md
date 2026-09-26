# Signal Numbers

## Description

**Signal Numbers is a library mod intended for use by other mod developers. It does not make gameplay changes.**

**Signal Numbers** is a tool for CPU/UPS optimization in mods that make extensive use of `SignalID`s. It creates a two-way deterministic mapping between `SignalID`s and short, interned string keys.

This scheme has several advantages:

- Converting in either direction is a prepopulated table lookup.
- The keys are short enough to always be interned/cached by Lua.
- Names and qualities are hashed independently, so keys for the same identifiable signal remain stable across mod-list changes.
- The first byte identifies the signal type without needing to lookup the key.

The tradeoff is a modest amount of static memory for the complete lookup tables.

## Key Format

`SignalKey`s should be treated as opaque printable strings, except for the first byte, which represents the signal type: `I` item, `F` fluid, `V` virtual, `E` entity, `R` recipe, `S` space location, `A` asteroid chunk, or `Q` quality.

All generated keys are checked for collisions during the data stage.

## How to Use

First you must add `signal-numbers` as a dependency in your mod's `info.json`. Then during the control phase you can import the library code:

```lua
-- `control.lua`
local signal_numbers = require("__signal-numbers__.signal-numbers")
```

The following methods are available:

- **key_to_signal**
```lua
---Convert a SignalKey to a SignalID. Returns nil if the key is not valid.
---@param key SignalKey
---@return SQSignalID?
local signal_id = signal_numbers.key_to_signal(key)
```

- **signal_to_key**
```lua
---Convert a SignalID to a SignalKey. Returns nil if the signal is not valid.
---@param sid SignalID
---@return SignalKey?
local key = signal_numbers.signal_to_key(sid)
```

- **exploded_signal_to_key**
```lua
---Convert exploded SignalID fields to a SignalKey. Returns nil if the signal is not valid.
---@param ty SignalIDType?
---@param name string?
---@param quality QualityID?
---@return SignalKey?
local key = signal_numbers.exploded_signal_to_key(ty, name, quality)
```

- **key_to_type**
```lua
---Return the signal type encoded in a key, or nil for an unknown type byte.
---@param key SignalKey
---@return SignalIDType?
local signal_type = signal_numbers.key_to_type(key)
```

- **signals_to_counts**
```lua
---Convert a list of `Signal`s to a mapping of `SignalKey` to counts.
---@param signals Signal[]
---@return table<SignalKey, int32> counts
local counts = signal_numbers.signals_to_counts(signals)
```

- **counts_to_signals**
```lua
---Convert a mapping of `SignalKey` to counts back into a list of `Signal`s.
---@param counts table<SignalKey, int32>
---@return Signal[]
local signals = signal_numbers.counts_to_signals(counts)
```

- **counts_to_signals_split**
```lua
---Split a mapping of `SignalKey` to counts into parallel arrays of `SignalID`s and counts.
---@param counts table<SignalKey, int32>
---@return SQSignalID[] signal_ids
---@return int32[] counts
local signals, counts = signal_numbers.counts_to_signals_split(counts)
```

- **is_parameter**, **is_virtual**, **is_item**, **is_fluid**, **is_train_cargo**, **is_quality**
```lua
---Test whether a signal key belongs to the given category.
---@param key SignalKey
---@return result boolean `true` if the signal is of the given type.
local result = signal_numbers.is_X(key)
```

- **get_stack_size**
```lua
---Given a `SignalKey`, return the stack size of the corresponding item, or `nil` if the signal is not an item.
---@param key SignalKey
---@return uint32?
local stack_size = signal_numbers.get_stack_size(key)
```

- **with_quality**
```lua
---Return a key for the same signal type and name with the given quality.
---@param key SignalKey
---@param quality QualityID
---@return SignalKey?
local quality_key = signal_numbers.with_quality(key, quality)
```

## EmmyLua Typings

IF using FMTK and the EmmyLua typechecker, you may obtain typings for your development workflow:

1) Unzip the mod somewhere.
2) Add the following to `.emmyrc.json`:
```json
{
  "workspace": {
    "library": [
      "D:\\dev\\factorio\\signal-numbers\\signal-numbers.lua"
    ]
  }
}
```
3) Import with type assertions:
```lua
-- `control.lua`
local signal_numbers = require("__signal-numbers__.signal-numbers") --[[@as SignalNumbers.Lib]]
```

## Contributing

Please use the [GitHub repository](https://github.com/project-cybersyn/signal-numbers) for questions, bug reports, or pull requests.

## Why is it called Signal Numbers?

Legacy reasons -- it used to generate Int53 keys, but they were too prone to collision and slower to hash than fully-interned strings.
