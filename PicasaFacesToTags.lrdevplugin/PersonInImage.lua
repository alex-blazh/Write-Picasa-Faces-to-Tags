--[[----------------------------------------------------------------------------
------------------------------------------------------------------------------]]
-- Access the Lightroom SDK namespaces.
local LrTasks = import 'LrTasks'
local LrProgressScope = import 'LrProgressScope'
local LrApplication = import 'LrApplication' 
local catalog = LrApplication.activeCatalog() 
local photos = catalog:getTargetPhotos()

local LrPathUtils = import 'LrPathUtils'
local logger = import 'LrLogger'("lr")
logger:enable('print')

local function csplit(str,sep)
	--[[split string to array using separator]]
        local ret={}
        local n=1
        for w in str:gmatch("([^"..sep.."]*)") do
                        ret[n]=ret[n] or w:gsub("^%s", "") -- only set once (so the blank after a string is ignored) 
                        									-- and removing space after separator
                        if w=="" then n=n+1 end -- step forwards on a blank but not a string
        end
        return ret
end

local function faceToTag()
	--[[Convert faces from picasa xmp tag to microsoft xmp ]]
	exeFile = LrPathUtils.child( _PLUGIN.path, "exiftool.exe" )
	cfgFile = LrPathUtils.child( _PLUGIN.path, "ExifTool_config_convert_regions" )
	redirect = LrPathUtils.getStandardFilePath('temp') .. "exiftool.stdout"
	local total = ( # catalog:getTargetPhotos() )
 	local exifArgs = {"-b -RegionName \>" .. redirect,
 	--'-overwrite_original "-RegionName\>PersonInImage"',
 	'-overwrite_original "-RegionName\>RegionPersonDisplayName"',
 	'-config  '..cfgFile..' -overwrite_original "-regioninfomp\<MyRegionMP"'}

			local progressScope = LrProgressScope{ 
				title = "Write Picasa Faces to Tags",
				caption = "Updateting " .. total .. " photos." ,
			}			
			progressScope:setCancelable( true )

 	local parrent
 	catalog:withWriteAccessDo("Create parrent keyword", function ()  
    	parrent = catalog:createKeyword("names", {}, false, nil, true)
 		--logger:debug("parrent keyword created: " .. tostring(parrent))
    end)

 
  	for completed, photo in ipairs(photos) do
  		progressScope:setPortionComplete(completed, total)
  		progressScope:setCaption("Updated " .. tostring(completed) .. " of " .. tostring(total) .. " photos")
  		if progressScope:isCanceled() then progressScope:done() break end

	 	local path = photo:getRawMetadata('path')
	 	logger:debug(path) -- write filename to debug log
	 	for i,exifArg in ipairs(exifArgs) do
	 		local exeCmd ='"' .. exeFile.." "..exifArg.." "..path .. '"'
 			local status = LrTasks.execute(exeCmd)
 			if io.open(redirect):read() == nil then break end --check is there any names in the file
 			--logger:debug(exeCmd)
		 	if status ~= 0
		 		then logger:debug("Error "..exeCmd)
		 			progressScope:done()
	 		end
	 	end

	 	for name in  io.lines(redirect) do
	 		if name ~= nil then -- check is there any pleople on photo	
	   			logger:debug(name)
	   			catalog:withWriteAccessDo("Adding name keywords", function ()  
	   				local keyword = catalog:createKeyword(name, {}, true, parrent, true)
	   				logger:debug("keyword created: " .. tostring(keyword))
	   				photo:addKeyword(keyword)
	   				--photo:setRawMetadata('PersonInImage', keyword) --doesn't work
		 			logger:debug("keyword added: " .. name)
		 		end)
	 		end
	 	end

--[[
	 	names = photo:getFormattedMetadata('personShown')
	 	logger:debug(names)
	 	if names ~= nil then -- check is there any pleople on photo
	   		for x,name in ipairs(csplit(names, "," )) do
	   			catalog:withWriteAccessDo("Adding name keywords", function ()  
	   				local keyword = catalog:createKeyword(name, {}, true, parrent, true)
	   				photo:addKeyword(keyword)
	   				--logger:debug(name)
	   			end)
		 	end
	 	end ]]
	end
	
progressScope:done()
end
--[[
function run()
     catalog:withProlongedWriteAccessDo( 
          {
               title="Converting Faces",
               func=faceToTag,
               caption="Initializing plugin",
               pluginName="Face to Tag",
               optionalMessage = "The plugin will first read your Expression Media XML file and then import the data into Lightroom for "
                    .. ( # catalog:getTargetPhotos() ) .. " photos"
          })
     
end
]]
LrTasks.startAsyncTask(faceToTag)