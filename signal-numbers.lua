---@alias SignalNumber int64

---@alias SignalNumberCounts table<SignalNumber, int32>

local mod_data = prototypes.mod_data["signal-numbers"].data
local sn_sid = mod_data.sn_sid --[[@as table<SignalNumber, SignalID>]]
local sid_sn = mod_data.sid_sn --[[@as table<string, table<string, (SignalNumber | table<string, SignalNumber>)>> ]]

local type = type

local lib = {}

lib.sn_sid = sn_sid
lib.sid_sn = sid_sn

---@param sn SignalNumber
---@return SignalID?
function lib.number_to_signal(sn) return sn_sid[sn] end

---@param sid SignalID
---@return SignalNumber?
function lib.signal_to_number(sid)
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

return lib
