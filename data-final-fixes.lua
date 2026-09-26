local prototype_info = require("__core__.lualib.prototype-info")
local tlib = require("lib.core.table")
local metadata = require("metadata")
local hash_lib = require("lib.core.math.hash")
local base64 = require("lib.core.math.base64")

local signal_types = metadata.signal_types
local signal_prototype_types = metadata.signal_prototype_types
local signal_type_keys = metadata.signal_type_keys
local murmur3_32 = hash_lib.murmur3_32
local base64_u32 = base64.encode_u32
local base64_u64 = base64.encode_u64
local strmatch = string.match
local pairs = pairs

local qualities = tlib.keys(data.raw["quality"])

---@type table<SignalKey, true>
local key_sid_keyset = {}
---@type SignalKey[]
local key_sid_keys = {}
---@type SignalID[]
local key_sid_values = {}
---@type table<string, table<string, table<string, SignalKey>>>
local sid_key = {}
---@type table<SignalKey, true>
local key_parameter_set = {}
---@type table<SignalKey, true>
local key_train_cargo_set = {}
---@type SignalKey[]
local key_stacksize_keys = {}
---@type uint32[]
local key_stacksize_values = {}

---@param sid SignalID
---@param key SignalKey
local function index_sid_key(sid, key)
	local sid_type = sid.type or "item"
	local sid_key_type = sid_key[sid_type]
	if not sid_key_type then
		sid_key_type = {}
		sid_key[sid_type] = sid_key_type
	end

	local sid_quality = sid.quality or "normal"
	local sid_key_quality = sid_key_type[sid_quality]
	if not sid_key_quality then
		sid_key_quality = {}
		sid_key_type[sid_quality] = sid_key_quality
	end

	sid_key_quality[sid.name] = key
end

local EMPTY_HASH = 0

---@param signal_type SignalIDType
---@param quality string
---@param name string
---@return SignalKey
local function make_signal_key(signal_type, quality, name)
	local type_key = signal_type_keys[signal_type]
	---@diagnostic disable-next-line: unnecessary-assert
	assert(type_key, "unknown signal type: " .. signal_type)
	local quality_hash = quality == "normal" and EMPTY_HASH or murmur3_32(quality)
	local name_hash_1 = name == "" and EMPTY_HASH or murmur3_32(name)
	local name_hash_2 = name == "" and EMPTY_HASH or murmur3_32(name, 0x9E3779B9)
	local key = type_key
		.. base64_u32(quality_hash)
		.. base64_u64(name_hash_1, name_hash_2)
	assert(#key == 18, "signal key has unexpected length")
	return key
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
				for name, proto in pairs(prototypes) do
					total_count = total_count + 1
					---@type SignalID
					local signal_id = {
						type = signal_type,
						quality = quality,
						name = name,
					}
					local signal_key = make_signal_key(signal_type, quality, name)
					if key_sid_keyset[signal_key] then
						error({
							"",
							"signal-numbers: hash collision for signal key ",
							serpent.line(signal_key),
							" incoming colliding signal: ",
							serpent.line(signal_id),
						})
					end
					key_sid_keyset[signal_key] = true
					key_sid_keys[#key_sid_keys + 1] = signal_key
					key_sid_values[#key_sid_values + 1] = signal_id
					index_sid_key(signal_id, signal_key)

					local is_parameter = strmatch(name, "^parameter%-")

					if is_parameter then key_parameter_set[signal_key] = true end

					if
						not is_parameter
						and (signal_type == "item" or signal_type == "fluid")
					then
						key_train_cargo_set[signal_key] = true
					end

					if (not is_parameter) and signal_type == "item" then
						key_stacksize_keys[#key_stacksize_keys + 1] = signal_key
						key_stacksize_values[#key_stacksize_values + 1] = proto.stack_size
							or 1
					end
				end
			end
		end
	end

	-- Quality signals can independently have any signal quality.
	for i_n = 1, #qualities do
		local name = qualities[i_n]
		local q_signal_id = {
			type = "quality",
			quality = quality,
			name = name,
		}
		local q_signal_key = make_signal_key("quality", quality, name)
		if key_sid_keyset[q_signal_key] then
			error({
				"",
				"signal-numbers: hash collision for quality signal key ",
				serpent.line(q_signal_key),
				" ",
				serpent.line(q_signal_id),
			})
		end
		key_sid_keyset[q_signal_key] = true
		key_sid_keys[#key_sid_keys + 1] = q_signal_key
		key_sid_values[#key_sid_values + 1] = q_signal_id
		index_sid_key(q_signal_id, q_signal_key)
		total_count = total_count + 1
	end
end

data:extend({
	{
		type = "mod-data",
		name = "signal-numbers",
		data = {
			sid_keys = key_sid_keys,
			sid_values = key_sid_values,
			sid_key = sid_key,
			stacksize_keys = key_stacksize_keys,
			stacksize_values = key_stacksize_values,
			parameter = tlib.keys(key_parameter_set),
			train_cargo = tlib.keys(key_train_cargo_set),
		},
	},
})

log({ "", "signal-numbers: generated ", total_count, " signal hashes" })
