--gitChanged
---variable-definition---------------------------------------------------------------------
global TB_Maplist
global DVOpenCloseUi
global DVDefineUI
global DvTypeName
global DVRollOut
global DvFloater
global MapUTile = Bezier_Float()
MapUTile.value = 1.0
global MapVTile = Bezier_Float()
MapVTile.value = 1.0
global TB_Maplist = #()
extensions_array = #("png","bmp","exr","hdr","jpg","psd","tga","tif")
global Typenames = #("diffuse","reflect","rglossiness","normal","bump","height","metalness")
global Typenamestex= ""
for t in Typenames do Typenamestex +=(t+"\n") 
	print typenamestex
global MatTypenames = #("Metal","Dielectric")
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
fn CreateDdoMtl Mname Dmap Rmap Gmap Nmap Bmap Hmap Mmap Bump:0 Height:0 BlendMtl:false NormalType:0 MaType:"Dielectric" Triplannar:1 meditSlot:1 = --Create Vray Material from Path List
(
	-- assign Texmap variable
	texmap = #(Dmap,Rmap,Gmap,Nmap,Bmap,Hmap,Mmap)
	texassign = #()
	for t in texmap do 
		(
			if Triplannar then
				(
					t = VRayTriplanarTex texture:t
				)
		)
	 basemtl = VrayMtl name:Mname reflection_lockIOR:off brdf_type:4
	dif =Dmap
	ref = Rmap
	reg =Gmap
	If NormalType then nor = VrayNormalMap normal_map_multiplier:1.0 flip_green:on else nor = Normal_Bump mult_spin:1.0 flipgreen:on
	nortex = Nmap
	
	nor.normal_map = nortex 
	-- Create Mtl
	case MaType of 
	(
		"Dielectric": basemtl.reflection_ior=1.6
		"Metal": basemtl.reflection_ior=20.0
		"Mixed": basemtl.texmap_reflectionIOR=(CreateMixedMap Mmap)
	)
	basemtl.texmap_diffuse = dif
	basemtl.texmap_reflection = ref
	basemtl.texmap_reflectionGlossiness = reg
	if (classof nor) == Normal_Bump do (if Bump do nor.bump_map = Bmap)
	basemtl.texmap_bump = nor
	if Height do basemtl.texmap_displacement = Hmap
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
	) else (meditmaterials[meditSlot] = basemtl; meditmaterials[meditSlot].showinviewport = true; if $ != undefined do for o in $ do o.material= basemtl)
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
	DVFloater = newRolloutFloater "PBR Material Importer " 200 520
	addRollout DVTypeName DVFloater category:1 rolledup:true
	addRollout DVRollout DVFloater category:2
	)

fn DVDefineUI = 
(
	rollout DVTypeName "MapNameSuffix"
	(
		label label0 "MapTypeName:" align:#left
		edittext DTextBox text:TypeNames[1]
		edittext RTextBox text:TypeNames[2]
		edittext GTextBox text:TypeNames[3]
		edittext NTextBox text:TypeNames[4]
		edittext BTextBox text:TypeNames[5]
		edittext HTextBox text:TypeNames[6]
		edittext MTextBox text:TypeNames[7]
		on DTextBox entered txt do TypeNames[1]=txt
		on RTextBox entered txt do TypeNames[2]=txt
		on GTextBox entered txt do TypeNames[3]=txt
		on NTextBox entered txt do TypeNames[4]=txt
		on BTextBox entered txt do TypeNames[5]=txt
		on HTextBox entered txt do TypeNames[6]=txt
		on MTextBox entered txt do TypeNames[7]=txt
	)
	rollout DVRollOut "Main"
	(
		local mapList
		local Dmap =undefined
		local Rmap =undefined
		local Gmap =undefined
		local Nmap =undefined
		local Bmap =undefined
		local Hmap =undefined
		local Mmap =undefined
		dropdownlist EXTDropDown "1- Choose file type:" items:extensions_array align:#left
		label label1 "2-Browse maps:" align:#left
		listbox maplistbox "Map Found:"
		button BrowseBT "..." width:150 height:20 align:#center
		spinner meditslide "3- Choose the Medit Slot:" range:[1,24,1] type:#integer width:100 align:#left
		dropdownlist MatTypeDropDown "4- Choose Material type:" items:MatTypeNames align:#left
		checkBox useblendCheckBox "Use Blended Vray Material"align:#left
		checkBox usetriplannarCheckBox "Use TriPlannar"align:#left
		checkBox useVraynorCheckBox "Use VrayNormalMap \n (Recommended for Vray3.4.01)"align:#left height:30
		checkBox useBumpCheckBox "Use BumpMap "align:#left enabled:false
		checkBox useHeightCheckBox "Use HeightMap "align:#left enabled:false
		button CreateMaterialbt "Create Material" width:150 height:40 enabled:false
		label label2 "Adjust Tilling" align:#left
		spinner UVslide "Tilling:" range:[0,100,1] type:#float width:100 align:#left
		on BrowseBt pressed do 
		(
			mapList = #()
			try (
				
				mapList=GetFileLIst (EXTDropDown.selected as string)
				maplistbox.items = (for m in maplist[2] collect (filterString (m as string) ":")[1])
				for m in maplist[2] do
				(
					if (matchPattern m.name pattern:("*"+Typenames[1])) do Dmap = m
					if (matchPattern m.name pattern:("*"+Typenames[2])) do Rmap = m  
					if (matchPattern m.name pattern:("*"+Typenames[3])) do Gmap = m
					if (matchPattern m.name pattern:("*"+Typenames[4])) do Nmap = m
					if (matchPattern m.name pattern:("*"+Typenames[5])) do (Bmap = m; useBumpCheckBox.enabled = true)
					if (matchPattern m.name pattern:("*"+Typenames[6])) do (Hmap = m; useHeightCheckBox.enabled = true)
					if (matchPattern m.name pattern:("*"+Typenames[7])) do (Mmap = m; MatTypeDropDown.items =#("Metal","Dielectric","Mixed"); MatTypeDropDown.selection = 3)
				)
				if maplistbox.items.count >=4 do CreateMaterialbt.enabled=true
				) catch()
			
		)
		on CreateMaterialbt pressed do
		(
			CreateDdoMtl mapList[1] Dmap Rmap Gmap Nmap Bmap Hmap Mmap Bump:useBumpCheckBox.checked Height:useHeightCheckBox.checked NormalType:useVraynorCheckBox.checked TriPlannar:usetriplannarCheckBox.checked BlendMtl:useblendCheckBox.checked MaType:MatTypeDropDown.selected meditSlot:meditslide.value
		)
		on UVslide changed tilevalue do
		(
			MapUTile.value = MapVTile.value = tilevalue
		)
	)
)
---Execution--------------------------------------------------------------------------------------------
DVOpenCloseUI()