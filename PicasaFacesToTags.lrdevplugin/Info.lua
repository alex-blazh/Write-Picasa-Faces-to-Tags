--[[----------------------------------------------------------------------------
------------------------------------------------------------------------------]]
return {
	LrSdkVersion = 3.0,
	LrSdkMinimumVersion = 1.3, -- minimum SDK version required by this plug-in

	LrToolkitIdentifier = 'com.adobe.lightroom.sdk.helloworld',

	LrPluginName = LOC "$$$/PicasaFaceToTag/PluginName=Picasa Face to tag",
		
	-- Add the menu item to the Library menu.
	LrLibraryMenuItems = {
		{   title = "Write Picasa Faces to Tags", file = "PersonInImage.lua"},
	},
	VERSION = { major=4, minor=1, revision=0, build=831116, },
}


	