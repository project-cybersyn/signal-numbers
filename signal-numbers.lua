---@alias SignalNumber int64

---@alias SignalNumberCounts table<SignalNumber, int32>

local mod_data = prototypes.mod_data["signal-numbers"].data
local sn_sid = mod_data.sn_sid --[[@as table<SignalNumber, SignalID>]]
local sid_sn = mod_data.sid_sn --[[@as table<string, table<string, (SignalNumber | table<string, SignalNumber>)>> ]]

local type = type

---@class SignalNumbers.Lib
local lib = {}

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

---@param signals Signal[]
---@return SignalNumberCounts
function lib.signals_to_counts(signals)
	---@type SignalNumberCounts
	local counts = {}
	for i = 1, #signals do
		local signal = signals[i]
		local sn = signal_to_number(signal.signal)
		counts[sn] = (counts[sn] or 0) + signal.count
	end
	return counts
end

return lib
