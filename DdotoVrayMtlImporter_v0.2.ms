---variable-definition-------------------------------------------------------------------
global TB_Maplist
global DVOpenCloseUi
global DVDefineUI
global DVRollOut
global DvFloater
global MapUTile = Bezier_Float()
MapUTile.value = 1.0
global MapVTile = Bezier_Float()
MapVTile.value = 1.0
global TB_Maplist = #()
extensions_array = #("png","bmp","exr","hdr","jpg","psd","tga","tif")
global Typenames = #("diffuse","reflect","rglossiness","normal","bump","height","metalness")
global MatTypenames = #("Metal","Dielectric","Mixed")
---function-------------------------------------------------------------------------------
fn RemoveExt str extension = 
(
	Strpos = findString str ("."+extension)
	newstr = replace Str Strpos (str.count-StrPos+1) ""
	newstrplus = filterString newstr "_"
	newstrplus[1]
)
fn GetFileNameFromPath FilePath ext= --Separate File name and file path in one array
(
	
	pathbreak=filterString FilePath "\\"
	Fpath =pathbreak[1]
	--print pathbreak[pathbreak.count]
	fname= RemoveExt pathbreak[pathbreak.count] ext
	for i=2 to (pathbreak.count-1) do
		(
			--print pathbreak[i]
			Fpath+="\\"+pathbreak[i]
			--print Fpath
		)
	#(fname,Fpath)
)
fn CreateMixedMap msk =
(
	mixmap = Mix()
	mixmap.map1 = VrayColor()
	mixmap.map2 = VrayColor()
	mixmap.map1.red = mixmap.map1.green = mixmap.map1.blue = 1.6
	mixmap.map2.red = mixmap.map2.green = mixmap.map2.blue = 20.0
	mixmap.mask = msk
	mixmap
)
fn CreateDdoMtl Mname mapList Height:1 BlendMtl:false NormalType:0 MaType:"Dielectric" Triplannar:1 meditSlot:1 = --Create Vray Material from Path List
(
	-- assign Texmap variable
	texassign = #()
	for t in mapList do 
		(
			if Triplannar then
				(
					tx = VRayTriplanarTex()
					tx.texture = t
					append texassign tx
				) else
				(
					append texassign t
				)
		)
	 basemtl = VrayMtl name:Mname reflection_lockIOR:off brdf_type:4
	dif =texassign[1]
	ref =texassign[2]
	reg =texassign[3]
	If NormalType then nor = VrayNormalMap normal_map_multiplier:1.0 flip_green:on else nor = Normal_Bump mult_spin:1.0 flipgreen:on
	nortex = texassign[4]
	bump= texassign[5]
	dis= texassign[6]
	nor.normal_map = nortex 
	-- Create Mtl
	case MaType of 
	(
		"Dielectric": basemtl.reflection_ior=1.6
		"Metal": basemtl.reflection_ior=20.0
		"Mixed": basemtl.texmap_reflectionIOR=(CreateMixedMap texassign[7])
	)
	basemtl.texmap_diffuse = dif
	basemtl.texmap_reflection = ref
	basemtl.texmap_reflectionGlossiness = reg
	basemtl.texmap_bump = nor
	if Height do basemtl.texmap_displacement = dis
	basemtl.texmap_bump_multiplier =100
	basemtl.texmap_displacement_on = off
	if BlendMtl then
	(
	NewMtl = VrayBlendMtl()
	newMtl.name = Mname +"_BlendMtl"
	meditmaterials[meditSlot] = newmtl
	meditmaterials[meditSlot].baseMtl = basemtl
	meditmaterials[meditSlot].showinviewport = true
	if $ != undefined do for o in $ do o.material= newmtl
	) else meditmaterials[meditSlot] = basemtl; meditmaterials[meditSlot].showinviewport = true; if $ != undefined do for o in $ do o.material= basemtl
	
)
fn GetFileList ext=
	(
		FilePathList = #()
		fullpath= (getOpenFileName caption:"Choose a map:") 
		if fullpath != undefined do
		(
			--append FilePathList filebasename
			--print fullpath
			breakpath = (getFileNameFromPath fullPath ext)
			for t in Typenames do 
			(
				--print t
				--print ext
				
				--print breakpath[1]
				---print breakpath[2]
				MapPath = breakpath[2] +"\\"+breakpath[1]+"_"+t+"."+ext
				try(if t == "normal" then bmap = openBitMap MapPath gamma:1.0 else bmap = openBitMap MapPath) catch() 
				if bmap!= undefined do
				(
					bmptexture= bitmaptexture name:(breakpath[1]+"_"+t) bitmap:bmap
					bmptexture.coords.U_Tiling.controller = MapUTile
					bmptexture.coords.V_Tiling.controller = MapVTile
					bmptexture.reload()
					--print bmptexture
					append FilePathList bmptexture
				)
			)
		)
		#(breakpath[1],FilePathList)
	)

fn DVOpenCloseUI =
	(
	if DVFloater != undefined then CloseRolloutFloater DVFloater
	DVDefineUI()
	DVFloater = newRolloutFloater "DDO Material Importer " 200 480
	addRollout DVRollout DVFloater
	)

fn DVDefineUI = 
(
	rollout DVRollOut "Import DDo Material"
	(
		local mapList
		dropdownlist EXTDropDown "1- Choose file type:" items:extensions_array align:#left
		label label1 "2-Browse maps:" align:#left
		listbox maplistbox "Map Found:"
		button BrowseBT "..." width:150 height:20 align:#center
		spinner meditslide "3- Choose the Medit Slot:" range:[1,24,1] type:#integer width:100 align:#left
		dropdownlist MatTypeDropDown "4- Choose Material type:" items:MatTypeNames align:#left
		checkBox useblendCheckBox "Use Blended Vray Material"align:#left
		checkBox usetriplannarCheckBox "Use TriPlannar"align:#left
		checkBox useVraynorCheckBox "Use VrayNormalMap \n (Recommended for Vray3.4.01)"align:#left height:30
		checkBox useHeightCheckBox "Use HeightMap "align:#left
		button CreateMaterialbt "Create Material" width:150 height:40
		label label2 "Adjust Tilling" align:#left
		spinner UVslide "Tilling:" range:[0,100,1] type:#float width:100 align:#left
		on BrowseBt pressed do 
		(
			try (
				mapList = #()
				mapList=GetFileLIst (EXTDropDown.selected as string)
				maplistbox.items = (for m in maplist[2] collect (filterString (m as string) ":")[1])
				) catch()
			
		)
		on CreateMaterialbt pressed do
		(
			if mapList != undefined do CreateDdoMtl mapList[1] mapList[2] Height:useHeightCheckBox.checked NormalType:useVraynorCheckBox.checked TriPlannar:usetriplannarCheckBox.checked BlendMtl:useblendCheckBox.checked MaType:MatTypeDropDown.selected meditSlot:meditslide.value
		)
		on UVslide changed tilevalue do
		(
			MapUTile.value = MapVTile.value = tilevalue
		)
	)
)
---Execution--------------------------------------------------------------------------------------------
DVOpenCloseUI()