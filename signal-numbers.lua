local pairs = pairs
local type = type

---@class SignalNumbers.Lib
local lib = {}

---@alias SignalNumber int64

---@class SQSignalID : SignalID
---@field type? SignalIDType
---@field name? string
---@field quality? string

local mod_data = prototypes.mod_data["signal-numbers"].data
local sn_sid_keys = mod_data.sn_sid_keys --[[@as SignalNumber[] ]]
local sn_sid_values = mod_data.sn_sid_values --[[@as SignalID[] ]]
local sn_stacksize_keys = mod_data.sn_stacksize_keys --[[@as SignalNumber[] ]]
local sn_stacksize_values = mod_data.sn_stacksize_values --[[@as uint32[] ]]
local sid_sn = mod_data.sid_sn --[[@as table<string, table<string, (SignalNumber | table<string, SignalNumber>)>> ]]
local sn_parameter_array = mod_data.sn_parameter --[[@as SignalNumber[] ]]
local sn_virtual_array = mod_data.sn_virtual --[[@as SignalNumber[] ]]
local sn_item_array = mod_data.sn_item --[[@as SignalNumber[] ]]
local sn_fluid_array = mod_data.sn_fluid --[[@as SignalNumber[] ]]
local sn_train_cargo_array = mod_data.sn_train_cargo --[[@as SignalNumber[] ]]
local sn_quality_array = mod_data.sn_quality --[[@as SignalNumber[] ]]

local function array_to_set(array)
	---@type table<number, true>
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

---@type table<SignalNumber, SQSignalID>
local sn_sid = kv_to_map(sn_sid_keys, sn_sid_values)

---@type table<SignalNumber, uint32>
local sn_stacksize = kv_to_map(sn_stacksize_keys, sn_stacksize_values)

local sn_parameter_set = array_to_set(sn_parameter_array)
local sn_virtual_set = array_to_set(sn_virtual_array)
local sn_item_set = array_to_set(sn_item_array)
local sn_fluid_set = array_to_set(sn_fluid_array)
local sn_train_cargo_set = array_to_set(sn_train_cargo_array)
local sn_quality_set = array_to_set(sn_quality_array)

rebuild_prof.stop()
---@diagnostic disable-next-line: param-type-mismatch
log({
	"",
	"signal-numbers: rebuilt sn tables for ",
	script.mod_name,
	" in ",
	rebuild_prof,
})

lib.sn_sid = sn_sid
lib.sid_sn = sid_sn

---Convert a SignalNumber to a SignalID. Returns nil if the number is not valid.
---@param sn SignalNumber
---@return SQSignalID?
local function number_to_signal(sn) return sn_sid[sn] end
lib.number_to_signal = number_to_signal

---Convert a SignalID to a SignalNumber. Returns nil if the signal is not valid.
---@param sid SignalID
---@return SignalNumber?
local function signal_to_number(sid)
	local st = sid.type or "item"
	-- Support quality specified by prototype (annoying)
	local sq = sid.quality or "normal"
	if type(sq) ~= "string" then sq = sq.name end

	local sid_sn_type = sid_sn[st]
	if not sid_sn_type then return nil end
	local sid_sn_quality = sid_sn_type[sq]
	if not sid_sn_quality then return nil end
	if st == "quality" then return sid_sn_quality end
	return sid_sn_quality[sid.name or ""]
end
lib.signal_to_number = signal_to_number

---Convert exploded SignalID fields to a SignalNumber. Returns nil if the signal is not valid.
---@param ty SignalIDType?
---@param name string?
---@param quality QualityID?
---@return SignalNumber?
local function exploded_signal_to_number(ty, name, quality)
	ty = ty or "item"
	local sid_sn_type = sid_sn[ty]
	if not sid_sn_type then return nil end
	quality = quality or "normal"
	if type(quality) ~= "string" then quality = quality.name end
	local sid_sn_quality = sid_sn_type[quality]
	if not sid_sn_quality then return nil end
	if ty == "quality" then
		return sid_sn_quality --[[@as SignalNumber]]
	end
	return sid_sn_quality[name or ""]
end
lib.exploded_signal_to_number = exploded_signal_to_number

---Convert a list of `Signal`s to a mapping of `SignalNumber` to counts.
---@param signals Signal[]
---@return table<SignalNumber, int32> counts
function lib.signals_to_counts(signals)
	---@type table<SignalNumber, int32>
	local counts = {}
	for i = 1, #signals do
		local signal = signals[i]
		local sn = signal_to_number(signal.signal)
		if sn then counts[sn] = (counts[sn] or 0) + signal.count end
	end
	return counts
end

---Convert a mapping of `SignalNumber` to counts back into a list of `Signal`s.
---@param counts table<SignalNumber, int32>
---@return Signal[]
function lib.counts_to_signals(counts)
	---@type Signal[]
	local signals = {}
	for sn, count in pairs(counts) do
		local sid = number_to_signal(sn)
		if sid then signals[#signals + 1] = { signal = sid, count = count } end
	end
	return signals
end

---Split a mapping of `SignalNumber` to counts into two parallel arrays: one of `SignalID`s and one of corresponding counts. The index of the signal is the same as the index of the corresponding count.
---@param counts table<SignalNumber, int32>
---@return SQSignalID[] signal_ids
---@return int32[] counts
function lib.counts_to_signals_split(counts)
	---@type SQSignalID[]
	local signal_ids = {}
	---@type int32[]
	local counts_out = {}
	for sn, count in pairs(counts) do
		local sid = number_to_signal(sn)
		if sid then
			signal_ids[#signal_ids + 1] = sid
			counts_out[#counts_out + 1] = count
		end
	end
	return signal_ids, counts_out
end

---@param sn SignalNumber
function lib.is_parameter(sn) return sn_parameter_set[sn] end

---@param sn SignalNumber
function lib.is_virtual(sn) return sn_virtual_set[sn] end

---@param sn SignalNumber
function lib.is_item(sn) return sn_item_set[sn] end

---@param sn SignalNumber
function lib.is_fluid(sn) return sn_fluid_set[sn] end

---@param sn SignalNumber
function lib.is_train_cargo(sn) return sn_train_cargo_set[sn] end

---@param sn SignalNumber
function lib.is_quality(sn) return sn_quality_set[sn] end

---Given a `SignalNumber`, return the stack size of the corresponding item, or `nil` if the signal is not an item.
---@param sn SignalNumber
---@return uint32?
function lib.get_stack_size(sn) return sn_stacksize[sn] end

---Given a `SignalNumber`, return a new `SignalNumber` of the given quality with the same type and name, or `nil` if the signal is not valid.
---@param sn SignalNumber
---@param quality QualityID
---@return SignalNumber?
function lib.with_quality(sn, quality)
	local sid = number_to_signal(sn)
	if not sid then return nil end
	return exploded_signal_to_number(sid.type, sid.name, quality)
end

return lib
