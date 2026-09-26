local pairs = pairs
local type = type
local strbyte = string.byte

---@class SignalNumbers.Lib
local lib = {}

---@diagnostic disable-next-line: duplicate-type
---@alias SignalKey string

---@class SQSignalID : SignalID
---@field type? SignalIDType
---@field name? string
---@field quality? string

local mod_data = prototypes.mod_data["signal-numbers"].data
local key_sid_keys = mod_data.sid_keys --[[@as SignalKey[] ]]
local key_sid_values = mod_data.sid_values --[[@as SignalID[] ]]
local key_stacksize_keys = mod_data.stacksize_keys --[[@as SignalKey[] ]]
local key_stacksize_values = mod_data.stacksize_values --[[@as uint32[] ]]
local sid_key = mod_data.sid_key --[[@as table<string, table<string, table<string, SignalKey>>> ]]
local key_parameter_array = mod_data.parameter --[[@as SignalKey[] ]]
local key_train_cargo_array = mod_data.train_cargo --[[@as SignalKey[] ]]

local function array_to_set(array)
	---@type table<string, true>
	local set = {}
	for i = 1, #array do
		set[array[i]] = true
	end
	return set
end

local function kv_to_map(keys, values)
	local map = {}
	for i = 1, #keys do
		local key = keys[i]
		local value = values[i]
		map[key] = value
	end
	return map
end

local rebuild_prof = helpers.create_profiler()

---@type table<SignalKey, SQSignalID>
local key_sid = kv_to_map(key_sid_keys, key_sid_values)

---@type table<SignalKey, uint32>
local key_stacksize = kv_to_map(key_stacksize_keys, key_stacksize_values)

local key_parameter_set = array_to_set(key_parameter_array)
local key_train_cargo_set = array_to_set(key_train_cargo_array)

rebuild_prof.stop()
---@diagnostic disable-next-line: param-type-mismatch
log({
	"",
	"signal-numbers: rebuilt signal key tables for ",
	script.mod_name,
	" in ",
	rebuild_prof,
})

lib.key_sid = key_sid
lib.sid_key = sid_key

---Convert a SignalKey to a SignalID. Returns nil if the key is not valid.
---@param key SignalKey
---@return SQSignalID?
local function key_to_signal(key) return key_sid[key] end
lib.key_to_signal = key_to_signal

---Convert a SignalID to a SignalKey. Returns nil if the signal is not valid.
---@param sid SignalID
---@return SignalKey?
local function signal_to_key(sid)
	local st = sid.type or "item"
	-- Support quality specified by prototype (annoying)
	local sq = sid.quality or "normal"
	if type(sq) ~= "string" then sq = sq.name end

	local sid_key_type = sid_key[st]
	if not sid_key_type then return nil end
	local sid_key_quality = sid_key_type[sq]
	if not sid_key_quality then return nil end
	return sid_key_quality[sid.name or ""]
end
lib.signal_to_key = signal_to_key

---Convert exploded SignalID fields to a SignalKey. Returns nil if the signal is not valid.
---@param ty SignalIDType?
---@param name string?
---@param quality QualityID?
---@return SignalKey?
local function exploded_signal_to_key(ty, name, quality)
	ty = ty or "item"
	local sid_key_type = sid_key[ty]
	if not sid_key_type then return nil end
	quality = quality or "normal"
	if type(quality) ~= "string" then quality = quality.name end
	local sid_key_quality = sid_key_type[quality]
	if not sid_key_quality then return nil end
	return sid_key_quality[name or ""]
end
lib.exploded_signal_to_key = exploded_signal_to_key

---Convert a list of `Signal`s to a mapping of `SignalKey` to counts.
---@param signals Signal[]
---@return table<SignalKey, int32> counts
function lib.signals_to_counts(signals)
	---@type table<SignalKey, int32>
	local counts = {}
	for i = 1, #signals do
		local signal = signals[i]
		local key = signal_to_key(signal.signal)
		if key then counts[key] = (counts[key] or 0) + signal.count end
	end
	return counts
end

---Convert a mapping of `SignalKey` to counts back into a list of `Signal`s.
---@param counts table<SignalKey, int32>
---@return Signal[]
function lib.counts_to_signals(counts)
	---@type Signal[]
	local signals = {}
	for key, count in pairs(counts) do
		local sid = key_to_signal(key)
		if sid then signals[#signals + 1] = { signal = sid, count = count } end
	end
	return signals
end

---Split a mapping of `SignalKey` to counts into parallel arrays of `SignalID`s and counts.
---@param counts table<SignalKey, int32>
---@return SQSignalID[] signal_ids
---@return int32[] counts
function lib.counts_to_signals_split(counts)
	---@type SQSignalID[]
	local signal_ids = {}
	---@type int32[]
	local counts_out = {}
	for key, count in pairs(counts) do
		local sid = key_to_signal(key)
		if sid then
			signal_ids[#signal_ids + 1] = sid
			counts_out[#counts_out + 1] = count
		end
	end
	return signal_ids, counts_out
end

local ITEM_TYPE_BYTE = strbyte("I")
local FLUID_TYPE_BYTE = strbyte("F")
local VIRTUAL_TYPE_BYTE = strbyte("V")
local QUALITY_TYPE_BYTE = strbyte("Q")

local TYPE_BY_BYTE = {
	[ITEM_TYPE_BYTE] = "item",
	[FLUID_TYPE_BYTE] = "fluid",
	[VIRTUAL_TYPE_BYTE] = "virtual",
	[strbyte("E")] = "entity",
	[strbyte("R")] = "recipe",
	[strbyte("S")] = "space-location",
	[strbyte("A")] = "asteroid-chunk",
	[QUALITY_TYPE_BYTE] = "quality",
}

---Return the signal type encoded in a key, or `nil` for an unknown type byte.
---@param key SignalKey
---@return SignalIDType?
function lib.key_to_type(key) return TYPE_BY_BYTE[strbyte(key)] end

---@param key SignalKey
function lib.is_parameter(key) return key_parameter_set[key] end

---@param key SignalKey
function lib.is_virtual(key) return strbyte(key) == VIRTUAL_TYPE_BYTE end

---@param key SignalKey
function lib.is_item(key) return strbyte(key) == ITEM_TYPE_BYTE end

---@param key SignalKey
function lib.is_fluid(key) return strbyte(key) == FLUID_TYPE_BYTE end

---@param key SignalKey
function lib.is_train_cargo(key) return key_train_cargo_set[key] end

---@param key SignalKey
function lib.is_quality(key) return strbyte(key) == QUALITY_TYPE_BYTE end

---Given a `SignalKey`, return the stack size of the corresponding item, or `nil` if the signal is not an item.
---@param key SignalKey
---@return uint32?
function lib.get_stack_size(key) return key_stacksize[key] end

---Return a key for the same signal type and name with the given quality.
---@param key SignalKey
---@param quality QualityID
---@return SignalKey?
function lib.with_quality(key, quality)
	local sid = key_to_signal(key)
	if not sid then return nil end
	return exploded_signal_to_key(sid.type, sid.name, quality)
end

return lib
