local pairs = pairs
local type = type

---@class SignalNumbers.Lib
local lib = {}

---@alias SignalNumber int64

local mod_data = prototypes.mod_data["signal-numbers"].data
local sn_sid_keys = mod_data.sn_sid_keys --[[@as SignalNumber[] ]]
local sn_sid_values = mod_data.sn_sid_values --[[@as SignalID[] ]]
local sid_sn = mod_data.sid_sn --[[@as table<string, table<string, (SignalNumber | table<string, SignalNumber>)>> ]]

local rebuild_prof = helpers.create_profiler()
local sn_sid = {}
for i = 1, #sn_sid_keys do
	local sn = sn_sid_keys[i]
	local sid = sn_sid_values[i]
	sn_sid[sn] = sid
end
rebuild_prof.stop()
---@diagnostic disable-next-line: param-type-mismatch
log({
	"",
	"signal-numbers: rebuilt sn_sid table for ",
	script.mod_name,
	" in ",
	rebuild_prof,
})

lib.sn_sid = sn_sid
lib.sid_sn = sid_sn

---Convert a SignalNumber to a SignalID. Returns nil if the number is not valid.
---@param sn SignalNumber
---@return SignalID?
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
function lib.exploded_signal_to_number(ty, name, quality)
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
---@return SignalID[] signal_ids
---@return int32[] counts
function lib.counts_to_signals_split(counts)
	---@type SignalID[]
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

return lib
