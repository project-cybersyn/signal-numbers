local lib = {}

lib.signal_types = {
	"item",
	"fluid",
	"virtual",
	"entity",
	"recipe",
	"space-location",
	"asteroid-chunk",
}

lib.signal_prototype_types = {
	"item",
	"fluid",
	"virtual-signal",
	"entity",
	"recipe",
	"space-location",
	"asteroid-chunk",
}

lib.signal_type_keys = {
	item = "I",
	fluid = "F",
	virtual = "V",
	entity = "E",
	recipe = "R",
	["space-location"] = "S",
	["asteroid-chunk"] = "A",
	quality = "Q",
}

return lib
