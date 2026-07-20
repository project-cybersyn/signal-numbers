-- XXX: pypostprocessing mutates this in `data-final-fixes.lua` but we need to undo it here.
defines.prototypes.item["fluid"] = nil

local prototype_info = require("__core__.lualib.prototype-info")
local tlib = require("lib.core.table")
local metadata = require("metadata")
local hash_lib = require("lib.core.math.hash")

local signal_types = metadata.signal_types
local signal_prototype_types = metadata.signal_prototype_types
local jenkins_mix_u32 = hash_lib.jenkins_mix_u32
local jenkins_finalize_u32 = hash_lib.jenkins_finalize_u32
local djb2_mix_u32 = hash_lib.djb2_mix_u32
local strbyte = string.byte
local band = bit32.band
local type = type
local pairs = pairs

local qualities = tlib.keys(data.raw["quality"])

---@type table<number, true>
local sn_sid_keyset = {}
---@type number[]
local sn_sid_keys = {}
---@type SignalID[]
local sn_sid_values = {}
---@type table<string, table<string, (SignalNumber | table<string, SignalNumber>) > >
local sid_sn = {}

---@param sid SignalID
---@param sn SignalNumber
local function index_sid_sn(sid, sn)
	local sid_type = sid.type or "item"
	local sid_sn_t = sid_sn[sid_type]
	if not sid_sn_t then
		sid_sn_t = {}
		sid_sn[sid_type] = sid_sn_t
	end

	local sid_quality = sid.quality or "normal"
	local sid_sn_q = sid_sn_t[sid_quality]
	if not sid_sn_q then
		if sid_type == "quality" then
			sid_sn_t[sid_quality] = sn
			return
		end
		sid_sn_q = {}
		sid_sn_t[sid_quality] = sid_sn_q
	end
	if sid_type == "quality" then return end

	sid_sn_q[sid.name] = sn
end

local LOW_21_MASK = 0x1FFFFF
local U32_MASK = 0xFFFFFFFF
local TWO_POW_32 = 4294967296
local MAX_SAFE_INT53 = 9007199254740991

local function hash_signal_id(signal_type, quality, name)
	local h1 = 0
	local h2 = 5381

	local function mix_component(component)
		for i = 1, #component do
			local byte = strbyte(component, i)
			h1 = jenkins_mix_u32(h1, byte)
			h2 = djb2_mix_u32(h2, byte)
		end
		h1 = jenkins_mix_u32(h1, 0)
		h2 = djb2_mix_u32(h2, 0)
	end

	mix_component(signal_type)
	mix_component(quality)
	mix_component(name)

	h1 = jenkins_finalize_u32(h1)
	local high21 = band(h1, LOW_21_MASK)
	local low32 = band(h2, U32_MASK)
	local sn = high21 * TWO_POW_32 + low32
	assert(
		sn >= 0 and sn <= MAX_SAFE_INT53 and sn % 1 == 0,
		"signal hash exceeds exact int53 range"
	)
	return sn
end

log({ "", "signal-numbers: generating signal hashes..." })
local total_count = 0
for i_q = 1, #qualities do
	local quality = qualities[i_q]
	for i_t = 1, #signal_types do
		local signal_type = signal_types[i_t]
		local prototype_type = signal_prototype_types[i_t]
		local types = prototype_info[
			prototype_type --[[@cast -?]]
		].types
		for i_pt = 1, #types do
			local pt = types[i_pt]
			local prototypes = data.raw[pt]
			if prototypes then
				for name in pairs(prototypes) do
					total_count = total_count + 1
					---@type SignalID
					local signal_id = {
						type = signal_type,
						quality = quality,
						name = name,
					}
					local signal_number = hash_signal_id(signal_type, quality, name)
					if sn_sid_keyset[signal_number] then
						error({
							"",
							"signal-numbers: hash collision for signal #",
							signal_number,
							" ",
							serpent.line(signal_id),
						})
					end
					sn_sid_keyset[signal_number] = true
					sn_sid_keys[#sn_sid_keys + 1] = signal_number
					sn_sid_values[#sn_sid_values + 1] = signal_id
					index_sid_sn(signal_id, signal_number)
				end
			end
		end
	end

	-- Generate quality signal separately
	local q_signal_id = {
		type = "quality",
		quality = quality,
	}
	local q_signal_number = hash_signal_id("quality", quality, "")
	if sn_sid_keyset[q_signal_number] then
		error({
			"",
			"signal-numbers: hash collision for quality signal #",
			q_signal_number,
			" ",
			serpent.line(q_signal_id),
		})
	end
	sn_sid_keyset[q_signal_number] = true
	sn_sid_keys[#sn_sid_keys + 1] = q_signal_number
	sn_sid_values[#sn_sid_values + 1] = q_signal_id
	index_sid_sn(q_signal_id, q_signal_number)
	total_count = total_count + 1
end

data:extend({
	{
		type = "mod-data",
		name = "signal-numbers",
		data = {
			sn_sid_keys = sn_sid_keys,
			sn_sid_values = sn_sid_values,
			sid_sn = sid_sn,
		},
	},
})

log({ "", "signal-numbers: generated ", total_count, " signal hashes" })
