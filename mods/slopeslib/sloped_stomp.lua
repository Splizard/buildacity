if minetest.get_modpath("poschangelib") == nil then
	-- Register the function that does nothing to prevent crashes
	slopeslib.register_sloped_stomp = function(source_node_name, dest_node_name, stomp_desc)
	end
else

slopeslib.register_sloped_stomp = function(source_node_name, dest_node_name, stomp_desc)
	local source_slopes = slopeslib.get_replacement(source_node_name)
	local dest_slopes = slopeslib.get_replacement(dest_node_name)
	if source_slopes == nil then
		minetest.log("warning", "[register_sloped_stomp] No slope registered for " .. source_node_name)
		return
	end
	if dest_slopes == nil then
		minetest.log("warning", "[register_sloped_stomp] No slope registered for " .. dest_node_name)
		return
	end
	for _, slope_type in pairs({"source", "straight", "inner", "outer", "pike"}) do
		poschangelib.register_stomp(source_slopes[slope_type], dest_slopes[slope_type], stomp_desc)
	end
end

end -- if mod exists end
