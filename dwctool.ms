/*	MAXSCRIPT FOR BONE TOWN MESH IMPORTING FOR 3DSMAX
	
	Date:   April 1 2023
	Author: mariokart64n
	
	Disclaimer:
		This software is provided "as is" without any warranties or
		guarantees, express or implied.
		The author of this software shall not be liable for any
		damages, losses, or liabilities arising out of the use or
		inability to use this software, including but not limited
		to direct, indirect, incidental, special, or consequential
		damages. The user assumes all responsibility and risk for
		the use of this software. The author does not warrant that
		this software will be error-free, uninterrupted, or free
		from viruses or other harmful components. 
		By using this software, you agree to indemnify and hold the
		author harmless from any claims, damages, or expenses,
		including reasonable attorneys' fees, arising out of your
		use of the software.
	
	Notes:  
		I have identified 4 different mesh format variants throughout 
		the game installation.
		
		Versions: 24, 25, 27, 29
		
		However it appears as some of them are offical torque3d
		dts models and some are custom dts formats.
		
		I'm sure alot of these variants are left overs from the
		development process.
		
		However the mixing of format is extremely sloppy
		from the devolper side.
		
		This makes adding modding support annoyingly difficult
		to write tools for. Considering code needs to be written
		to support 8 possible model formats that the game
		may or may not even support.
		
		Looking at the model assets there are some concerns I have;
		
		1.) Looks like there is 1 body and 3 variants that they
		    morph between. If this is the case then replacing
			the a model would require all variants to also be 
			replaced. This would explain with they said "any"
			modification to the model would cause crashing.
		
		2.) Looks like the clothes and accessories don't add on
		    top of the base mesh. Instead it appears it replaces
			an entire section of the mesh. If this is the case
			simply editing a part of the base mesh will do nothing.
			All clothing would need to be edited to include the 
			moddified base mesh with it
		
		assuming the worst, to be able to edit a model would be
		too much trouble then it's worth. Atleast without offical
		tool support it would seem stupid to fight an up hill battle.
		
		As it stands I'm not able to import the clothing / accessories
		because they are saved to a different DTS version.
		
		If i did get DTM's supported then I would need to import
		all the assets into a single 3dsmax scene. then I would
		need to overwrite all the DWC and DTM files in the game.
		
		This is because they designed the model system around one
		base mesh. my guess is that it was designed that way to
		randomly generate NPC's and what they did made sense then.
		
		Because that porn star RonJ seems to be a discret model I
		would assume they have a method to create NPC's that are
		not tied to their random NPC generator system.
		
		In otherwords the dev would need to provide a method to the
		community to add their own NPC's.
		
		For now they've effectively made it easier to rip models 
		from their game then it would be to mod their game.
		
	Format Documents:
		http://www.garagegames.com/community/forums/viewthread/48429
		http://shaderman.com/Torque/TGEA/resources/DTS-FileFormat/DTS-FileFormat.pdf
		http://shaderman.com/Torque/TGEA/resources/DTS-FileFormat/DTS-FileFormat_eng.htm
		https://github.com/nzchris/ms2dtsExporterPlus
		http://docs.garagegames.com/torque-3d/official/content/documentation/Artist%20Guide/Formats/dts_format.html
		https://torquegameengines.github.io/T3D-Documentation/content/documentation/Artist%20Guide/Formats/dsq_format.html
		https://github.com/qoh/io_scene_dts
		http://www.garagegames.com/community/forums/viewthread/130081
	
	ChangeLog:
	[2023-04-01]
		I re-wrote the code to focus only on version 29 since managing it for 
		all version proved to be a hassle.
	
*/

debug = false
clearListener()
try(destroyDialog bt_dts)catch(bt_dts)
rollout bt_dts "B.T. DWC Tool" (
	group "Import" (
		button btn_imp "Open File" width:120 height:30 align:#center
		label lbl_file "                      " align:#center
		checkbox chk_clear "Clear Scene" checked:true
		checkbox chk_skin "Weights (slow)" checked:false
		checkbox chk_norm "Normals (slow)" checked:false
		listBox lbx_anim "Animation Select (slow)" height:4
		button btn_loadanim "Load Clip" width:60 height:16 align:#left
		)
	/*
		uncomment below to unhide export feature
		i decoded to abondon support for export when 
		I realized I would need to re-write every model
		in the game (>_<)
	*/
-- 	label lbl_bleh "*below has been abandoned*"
-- 	group "Edit" (
-- 		button btn_load "Load File" width:120 height:30 align:#center
-- 		button btn_exp "Save File" width:120 height:30 align:#center
-- 		--checkbox chk_faceopt "Optimize Face List" checked:false
-- 		--checkbox chk_fixBonePos "Update Bone Positions" checked:false
-- 		listBox lbx_mesh "Meshes" height:4
-- 		button btn_import "Import" width:60 height:16 across:2
-- 		button btn_replace "Replace" width:60 height:16
-- 		label lbl_gamepath "GamePath:" align:#left
-- 		editText edt_gamepath "" align:#left
-- 		label lbl_texpath "TexPath:" align:#left
-- 		editText edt_texpath "" align:#left
-- 		label lbl_expnote "*Mesh must use the same\nskeleton.\n\nwhen saving you will be\nprompted to open an\nexisting model file.\n\nThe selected file will not be\noverwritten, it is only used\nto write a new file.\n" height:132 align:#left
-- 		)
	hyperLink lbl_author "Author : mariokart64n" address:"https://www.deviantart.com/mariokart64n" align:#left
	label lbl_date "Date   : April 1 2023" align:#left
	/*
		format specification adapted from torque's public document
		https://torquegameengines.github.io/T3D-Documentation/content/documentation/Artist%20Guide/Formats/dts_format.html#MESHES
	*/
	
	struct fmtDTS_Bounds ( -- 44 Bytes
		/*
			the bounds are like 15% larger then the mesh for some reason?
			not confirmed but may include bounds of the mesh during animated states?
			
			the radius goes around the bound box and so is larger on its own
			the tube radius seems to be just a radius around the mesh
		*/
		/*float*/           	radius         = 0.0,
		/*float*/           	tubeRadius     = 0.0,
		/*float[3]*/        	center         = [0.0, 0.0, 0.0],                     -- Center coordinates of the DTS (x / y / z)
		/*float[6]*/        	bounds         = #([0.0, 0.0, 0.0], [0.0, 0.0, 0.0]), -- min / max
		fn build mscale:39.3700787401574803149606299212598425196850393700787402 = (
			local dim = bounds[2] - bounds[1]
			local s = Sphere radius:(radius * mscale) pos:(center * mscale) isSelected:off
			local t = Sphere radius:(tubeRadius * mscale) pos:(center * mscale) isSelected:off
			local d = Dummy boxsize:(dim * mscale) pos:(center * mscale) isSelected:off
			s.parent = d
			t.parent = d
			),
		fn read &f = (
			radius     = readFloat f
			tubeRadius = readFloat f
			center     = [readFloat f, readFloat f, readFloat f]
			bounds     = #([readFloat f, readFloat f, readFloat f], [readFloat f, readFloat f, readFloat f])
			),
		fn write &s = (
			writeFloat s radius
			writeFloat s tubeRadius
			writeFloat s center[1]
			writeFloat s center[2]
			writeFloat s center[3]
			writeFloat s bounds[1][1]
			writeFloat s bounds[1][2]
			writeFloat s bounds[1][3]
			writeFloat s bounds[2][1]
			writeFloat s bounds[2][2]
			writeFloat s bounds[2][3]
			)
		)
	
	struct fmtDTS_Node ( -- 20 Bytes
		/*int32_t*/         	nameIndex      = -1,
		/*int32_t*/         	parent         = -1,
		/*int32_t*/         	reserved       = -1, -- always -1, not used
		/*int32_t*/         	childIndex     = -1, -- ?
		/*int32_t*/         	siblingIndex   = -1, -- ?
		fn read &f = (
			nameIndex = readLong f #signed
			parent = readLong f #signed
			reserved = readLong f #signed
			childIndex = readLong f #signed
			siblingIndex = readLong f #signed
			--format "%\t%\t%\t%\t%\t\n" nameIndex numMeshes firstMesh nodeIndex siblingIndex
			),
		fn write &s = (
			writeLong s nameIndex #signed
			writeLong s parent #signed
			writeLong s reserved #signed
			writeLong s childIndex #signed
			writeLong s siblingIndex #signed
			)
		)
	
	struct fmtDTS_Object (	-- 20 Bytes
		/*
			use this to contruct the models 
			from the meshes buffer
		*/
		/*int32_t*/         	nameIndex      = -1,
		/*int32_t*/         	numMeshes      = -1,
		/*int32_t*/         	firstMesh      = -1,
		/*int32_t*/         	nodeIndex      = -1, -- ? always -1
		/*int32_t*/         	siblingIndex   = -1, -- ? always -1
		/*int32_t*/         	firstDecal     = undefined, -- (depreciated)
		fn read &f &version = (
			nameIndex = readLong f #signed
			numMeshes = readLong f #signed
			firstMesh = readLong f #signed
			nodeIndex = readLong f #signed
			siblingIndex = readLong f #signed
			--format "%\t%\t%\t%\t%\t\n" nameIndex numMeshes firstMesh nodeIndex siblingIndex
			if version <= 24 do (
				firstDecal = readLong f #signed
				)
			),
		fn write &s = (
			writeLong s nameIndex #signed
			writeLong s numMeshes #signed
			writeLong s firstMesh #signed
			writeLong s nodeIndex #signed
			writeLong s siblingIndex #signed
			if firstDecal != undefined do (
				writeLong s firstDecal #signed
				)
			)
		)
	
	struct fmtDTS_Decal (	-- 8 bytes (maybe not decal, could b a subshapes)
		/*
			I'm not sure what this is, it seems to have a fixed count 
			
			only thing remotely close to this in the docs is the 
			decals info
			
		*/
		/*uint32_t*/        	firstNode      = 0, -- ? always 1
		/*uint32_t*/        	firstObject    = 0, -- 3rd occurrence is node count, 4th occurrence is mesh count, otherwise 0
		/*uint32_t*/        	firstDecal     = undefined, -- or numDecals
		fn read &f &version = (
			firstNode = readLong f #unsigned
			firstObject = readLong f #unsigned
			--format "%\t%\n" firstNode firstObject
			if version <= 24 do (
				firstDecal = readLong f #unsigned
				)
			),
		fn write &s = (
			writeLong s firstNode #unsigned
			writeLong s firstObject #unsigned
			if firstDecal != undefined do (
				writeLong s firstDecal #unsigned
				)
			)
		)
	
	struct fmtDTS_Primative ( -- 8 Bytes
		/*uint16_t*/        	firstElement   = 0,	-- face position to read from
		/*uint16_t*/        	numElements    = 0,	-- how many faces to read
		/*uint32_t*/        	type           = 0, -- doc says type and materail id, so i'm assuming the index is masked in the int.. 
		/* Type:
			Triangles    = 0x00000000
			NoMaterial   = 0x10000000
			Indexed      = 0x20000000
			Strip        = 0x40000000
			Fan          = 0x80000000 
			TypeMask     = 0xC0000000
			MaterialMask = 0x0FFFFFFF
			
			example:
			1010000000000000000000000000000 0x50000000
			1010000000000000000000000000001 0x50000001
			1010000000000000000000000000010 0x50000002
			1000000000000000000000000000000 0x40000000 ? strips
			0010000000000000000000000000000 0x10000000 ? no material
		*/
		fn matid = (bit.and type 0xFFFF),
		fn read &f = (
			firstElement = readShort f #unsigned
			numElements = readShort f #unsigned
			type = readLong f #unsigned
			),
		fn write &s = (
			writeShort s firstElement #unsigned
			writeShort s numElements #unsigned
			writeLong s type #unsigned
			)
		)
	
	struct fmtDTS_Junk ( -- 40 Bytes
		/*
			this had looked like signed shorts as floats
			but i'm seeing Bip01 repeated sometimes.
			
			the string stream looks corrupt, my guess is that
			it is an uninitialized buffer...
			
			in the dts format doc this struct would match the
			bound box one..
		*/
		/*float[6]*/        	bound = #([0.0, 0.0, 0.0], [0.0, 0.0, 0.0]),
		/*float[3]*/        	center = [0.0, 0.0, 0.0],
		/*float*/           	radius = 0.0,
		fn read &f = (
			bound = #([readFloat f, readFloat f, readFloat f], [readFloat f, readFloat f, readFloat f])
			center = [readFloat f, readFloat f, readFloat f]
			radius = readFloat f
			),
		fn write &s = (
			writeFloat s bound[1][1]
			writeFloat s bound[1][2]
			writeFloat s bound[1][3]
			writeFloat s bound[2][1]
			writeFloat s bound[2][2]
			writeFloat s bound[2][3]
			writeFloat s center[1]
			writeFloat s center[2]
			writeFloat s center[3]
			writeFloat s radius
			)
		)
	
	struct fmtDTS_Mesh (
		/*uint32_t*/        	type           = 0,
		/* type:
			T_Standard     =    0x00000000, Rigid mesh
			T_Skin         =    0x00000001, Skined (mesh with bones)
			T_Decal        =    0x00000002, is no longer used
			T_Sorted       =    0x00000003, BSP Sorted for correct alpha rendering
			T_Null         =    0x00000004, zero mesh, will be in collision objects used
		
			0x00    0000: T_Standard
			0x01    0001: T_Skin
			0x02    0010: T_Decal
			0x04    0100: T_Sorted
			0x08    1000: T_Null
		*/
		--flag = 0,
		/*
			Billboard      = 	0x80000000 	Mesh always faces the camera
			HasDetail      = 	0x40000000
			BillboardZ     = 	0x20000000 	If billboard, only rotate around Z axis
			EncodedNormals = 	0x10000000 	Mesh uses encoded normals
		*/
		/*fmtDTS_Junk*/     	crap           = fmtDTS_Junk(), -- 40 bytes
		/*uint32_t*/        	position_count = 0,
		/*float[3][]*/      	positions      = #(),
		/*uint32_t*/        	texcoord_count = 0,
		/*float[2][]*/      	texcoords      = #(),
		/*uint32_t*/        	normal_count   = 0,
		/*float[3][]*/      	normals        = #(),
		/*uint32_t*/        	primitive_count= 0,
		/*fmtDTS_Primative*/	primitives     = #(),
		/*uint32_t*/        	face_count     = 0,
		/*uint16_t[]*/      	faces          = #(),
		/*uint32_t*/        	mface_count    = 0, -- ? Always 0, Doc says Merged Indices are depreciated (not used)
		/*uint16_t[]*/      	mfaces         = #(),
		/*uint32_t*/        	mesh_flags      = 0, -- lol doc says this is mesh flags, but then doesn't explain them
		/*uint32_t*/        	tran_count     = 0,
		/*float[64][]*/     	trans          = #(), -- bone transforms of the bones used by the blend weights, probably local/relative transforms?
		/*uint32_t*/        	index1_count   = 0,
		/*uint32_t[]*/      	index1         = #(),
		/*uint32_t*/        	index2_count   = 0,
		/*uint32_t[]*/      	index2         = #(),
		/*uint32_t*/        	weight_count   = 0,
		/*float[]*/         	weight         = #(),
		/*uint32_t*/        	index3_count   = 0,
		/*uint32_t[]*/      	index3         = #(),
		/*
			bone pallete (smaller arrays)
			'meshes[s].trans' contains matrices of each bone used by the weights but only the rotational parts, the position is missing...
			'meshes[s].index3' indices that connect the trans to main skeleton, probably to get the trans position?
			
			weight pallete 
			'index1, index2, weight' have the same counts so are connected weight data
			'meshes[s].index1' contains indices to the vertices
			'meshes[s].index2' contains indices to 'meshes[s].trans'
			'meshes[s].weight' is the weight values
			
			the way they store weights is different, not sure if theres a cap to how many bone influences per verted
		*/
		fn decode_triangle_strip &faceArray &matidArray matid:1 faceStart:0 faceEnd:0 vertex_start:0 face_add:1 = (
			/*
			converts the triangles strips into trianle list and creates
			material id for each face
			*/
			local fa = 1,fb = 1,fc = 1,x = faceStart, y = faceStart
			local face_flip = false
			local face_reset = true
			
			if faceEnd == 0 do (faceEnd = faces.count)
			
			while x < faceEnd do (
				x+=1
				if face_reset then (
					x+=2
					fa = (faces[y + 1]-vertex_start) + face_add
					fb = (faces[y + 2]-vertex_start) + face_add
					fc = (faces[y + 3]-vertex_start) + face_add
					y += 3
					if fa != fb and fb != fc and fc != fa do (
						face_reset = false
						append matidArray matid
						if face_flip then (
							append faceArray [fa,fb,fc]
							)
						else(
							append faceArray [fa,fc,fb]
							)
						face_flip = not face_flip
						)
					)
				else (
					fa = fb
					fb = fc
					fc = faces[y = y + 1]
					if fc < 0xFFFF and fc != -1 then (
						fc += face_add - vertex_start
						
						if fa != fb and fb != fc and fc != fa do (
							append matidArray matid
							if face_flip then (
								append faceArray [fa,fb,fc]
								)
							else (
								append faceArray [fa,fc,fb]
								)
							)
						face_flip = not face_flip
						)
					else (
						face_reset = true
						)
					)
				)
			),
		fn decode_triange_list &faceArray &matidArray matid:1 faceStart:0 faceEnd:0 vertex_start:0 face_add:1 = (
			/*
			reads triangle list and creates material id for each face
			*/
			local i = 1, x = faceStart
			if faceEnd == 0 do (
				faceEnd = faces.count
				)
			while x < faceEnd do (
				append faceArray (([faces[x + 1], faces[x + 3], faces[x + 2]]-vertex_start) + face_add)
				append matidArray matid
				x += 3
				)
			),
		fn read &f = (
			local i = 1
			
			-- maybe a count???, another number after the face array seems to be a type code
			type = readLong f #unsigned
			--format "\nmeshtype: \t% @ %\n" type (((ftell f) - 4) as integer)
			
			
			if type != 8 do ( -- 8 is a skip?
				
				
				
				--flag = readLong f #unsigned
				
				crap.read(&f) -- 40 bytes of junk?
				
				
				position_count = readLong f #unsigned
				positions = #()
				if position_count > 0 do (
					positions[position_count] = [0.0, 0.0, 0.0]
					for i = 1 to position_count do ( -- 12 Bytes per
						positions[i] = [readFloat f, readFloat f, readFloat f]
						)
					)
				
				texcoord_count = readLong f #unsigned
				texcoords = #()
				if texcoord_count > 0 do (
					texcoords[texcoord_count] = #(0.0, 0.0)
					for i = 1 to texcoord_count do ( -- 8 Bytes per
						texcoords[i] = #(readFloat f, readFloat f)
						)
					)
				
				normal_count = readLong f #unsigned
				normals = #()
				if normal_count > 0 do (
					normals[normal_count] = [0.0, 0.0, 0.0]
					for i = 1 to normal_count do ( -- 12 Bytes per
						normals[i] = [readFloat f, readFloat f, readFloat f]
						)
					)
				
				primitive_count = readLong f #unsigned
				primitives = #()
				if primitive_count > 0 do (
					primitives[primitive_count] = fmtDTS_Primative()
					for i = 1 to primitive_count do ( -- 8 Bytes per
						primitives[i] = fmtDTS_Primative()
						primitives[i].read(&f)
						)
					)
	-- 			format "primitives\n"
	-- 			print primitives
	-- 			print ""
				
				
				face_count = readLong f #unsigned
				faces = #()
				if face_count > 0 do (
					faces[face_count] = 0
					for i = 1 to face_count do (
						faces[i] = readShort f #unsigned
						)
					)
				
				mfaces = #()
				mface_count = readLong f #unsigned -- always observed as 0
				if mface_count > 0 do (
					format "Warning!!: this not NULL, may mean something {%} @ %\n" unk004 (((ftell f) - 4) as integer)
					mfaces[mface_count] = 0
					for i = 1 to face_count do (
						mfaces[i] = readShort f #unsigned
						)
					)
				
				mesh_flags = readLong f #unsigned -- 2
				
				
				-- stuff below may only show if the skin flag is on?
				--format "facetype?: \t% @ %\n" mesh_flags (((ftell f) - 4) as integer)
				if bit.get mesh_flags 2 do (
					
					tran_count = readLong f #unsigned
					trans = #()
					if tran_count > 0 do (
						trans[tran_count] = #(
							#(0.0, 0.0, 0.0, 0.0), 
							#(0.0, 0.0, 0.0, 0.0), 
							#(0.0, 0.0, 0.0, 0.0), 
							#(0.0, 0.0, 0.0, 0.0)
							)
						for i = 1 to tran_count do (
							trans[i] = #(
								#(readFloat f, readFloat f, readFloat f, readFloat f), 
								#(readFloat f, readFloat f, readFloat f, readFloat f), 
								#(readFloat f, readFloat f, readFloat f, readFloat f), 
								#(readFloat f, readFloat f, readFloat f, readFloat f)
								)
							)
						)
					
					
					index1_count = readLong f #unsigned
					index1 = #()
					if index1_count > 0 do (
						index1[index1_count] = 0
						for i = 1 to index1_count do (
							index1[i] = readLong f #unsigned
							)
						)
					
					index2_count = readLong f #unsigned
					index2 = #()
					if index2_count > 0 do (
						index2[index2_count] = 0
						for i = 1 to index2_count do (
							index2[i] = readLong f #unsigned
							)
						)
					
					weight_count = readLong f #unsigned
					weight = #()
					if weight_count > 0 do (
						weight[weight_count] = 0.0
						for i = 1 to weight_count do (
							weight[i] = readFloat f
							)
						)
					
					index3_count = readLong f #unsigned
					index3 = #()
					if index3_count > 0 do (
						index3[index3_count] = 0
						for i = 1 to index3_count do (
							index3[i] = readLong f #unsigned
							)
						)
					)
				)
			--format "Mesh ENd Read: %\n" ((ftell f) as integer)
			),
		fn write &s = (
			local i = 1
			
			writeLong s type #unsigned
			if type != 8 do ( -- 8 is a skip?
				crap.write(&s)
				
				writeLong s (position_count = positions.count) #unsigned
				for i = 1 to position_count do ( -- 12 Bytes per
					writeFloat s positions[i][1]
					writeFloat s positions[i][2]
					writeFloat s positions[i][3]
					)
				
				writeLong s (texcoord_count = texcoords.count) #unsigned
				for i = 1 to texcoord_count do ( -- 8 Bytes per
					writeFloat s texcoords[i][1]
					writeFloat s texcoords[i][2]
					)
				
				writeLong s (normal_count = normals.count) #unsigned
				for i = 1 to normal_count do ( -- 12 Bytes per
					writeFloat s normals[i][1]
					writeFloat s normals[i][2]
					writeFloat s normals[i][3]
					)
				
				writeLong s (primitive_count = primitives.count) #unsigned
				for i = 1 to primitive_count do ( -- 8 Bytes per
					primitives[i].write(&s)
					)
				
				writeLong s (face_count = faces.count) #unsigned
				for i = 1 to face_count do (
					writeShort s faces[i] #unsigned
					)
				
				writeLong s (mface_count = mfaces.count) #unsigned
				for i = 1 to mface_count do (
					writeShort s mfaces[i] #unsigned
					)
				
				writeLong s mesh_flags #unsigned
				if bit.get mesh_flags 2 do (
					
					writeLong s (tran_count = trans.count) #unsigned
					local x = 1, y = 1
					for i = 1 to tran_count do (
						for x = 1 to 4 do (
							for y = 1 to 4 do (
								writeFloat s trans[i][x][y]
								)
							)
						)
					
					writeLong s (index1_count = index1.count) #unsigned
					for i = 1 to index1_count do (
						writeLong s index1[i] #unsigned
						)
					
					writeLong s (index2_count = index2.count) #unsigned
					for i = 1 to index2_count do (
						writeLong s index2[i] #unsigned
						)
					
					writeLong s (weight_count = weight.count) #unsigned
					for i = 1 to weight_count do (
						writeFloat s weight[i]
						)
					
					writeLong s (index3_count = index3.count) #unsigned
					for i = 1 to index3_count do (
						writeLong s index3[i] #unsigned
						)
					)
				)
			),
		fn get_mesh_normals &obj &faceArray &normArray = (
			local i = 1, ii = 1, iii = 1
			local numFaceSides = 3 -- number of sides in a  triangle
			local faceIndex = 0 -- face index
			local normal_modifier = Edit_Normals() -- spawn modifier
			local mesh_modifier = Edit_Mesh() -- spawn modifier
			local modNormals = #()
			local polyFace = #()
			local face_count = 0
			local tfm = obj.transform.rotationPart as matrix3
			
			if (face_count = faceArray.count) > 0 do (--getNumFaces obj
				normArray = #()
				normArray[face_count * 3] = [0.0, 0.0, 0.0]
				select obj -- select mesh
				modPanel.addModToSelection mesh_modifier ui:off -- apply edit
				modPanel.addModToSelection normal_modifier ui:off -- apply modifier
				modPanel.setCurrentObject normal_modifier -- select modifier
			
				for ii = 1 to face_count do (
					for iii = 1 to numFaceSides do (
						normArray[((ii - 1) * 3) + iii] = (
							normalize (
								(transMatrix (
									normal_modifier.GetNormal (normal_modifier.GetNormalID ii iii)
									)) * tfm
								).row4
							)
						)
					)
			
				/*
				else (
					for ii = 1 to (getNumFaces obj) do (
						polyFace = polyop.getFaceVerts obj ii
						modNormals = #()
						
						for iii = 1 to polyFace.count do ( -- get each vertex listed in face index list
							
							faceIndex += 1
							normArray[faceIndex] = (
								normalize (
									((matrix3 [1,0,0] [0,1,0] [0,0,1] (normal_modifier.GetNormal iii)) * \
									(obj.transform*(matrix3 [1,0,0] [0,1,0] [0,0,1] -obj.transform.row4))).row4
									)
								)
							)
						)
					)
				*/
				deleteModifier obj mesh_modifier
				deleteModifier obj normal_modifier
				)
			),
		fn get_mesh_blendweights &obj &boneArray &biArray &wvArray = (
			local i = 1, ii = 1, v = 1
			local skin_modifier = undefined
			local boneNames = #()
			local skinBoneNames = #()
			local numSkinBones = 0
			local numBoneWeights = 0
			local wv = #(), bi = #()
			
			-- Create a Lookup
			if boneArray.count > 0 do (
				boneNames[boneArray.count] = ""
				for i = 1 to boneArray.count do (
					boneNames[i] = boneArray[i].name
					)
				)
			
			if classof (skin_modifier = obj.modifiers[#Skin]) == Skin then (
				select obj
				modPanel.setCurrentObject skin_modifier
				numSkinBones = skinOps.GetNumberBones skin_modifier
				if numSkinBones > 0 do (skinBoneNames[numSkinBones] = "")
				for i = 1 to numSkinBones do (
					skinBoneNames[i] = skinOps.GetBoneName skin_modifier i 0
					
					if findItem boneNames skinBoneNames[i] == 0 do (
						-- if bone not in lookup, then add to bone list
						append boneNames skinBoneNames[i]
						append boneArray (getNodeByName skinBoneNames[i])
						)
					)
				if obj.numverts > 0 do (
					biArray[obj.numverts] = #()
					wvArray[obj.numverts] = #()
					)
				for i = 1 to obj.numverts do (
					wv = #()
					bi = #()
					numBoneWeights = skinOps.GetVertexWeightCount skin_modifier i
					if numBoneWeights > 0 then (
						wv[numBoneWeights] = 0.0
						bi[numBoneWeights] = 1
						for ii = 1 to numBoneWeights do (
							wv[ii] = skinops.getvertexweight skin_modifier i ii
							bi[ii] = skinOps.GetVertexWeightBoneID skin_modifier i ii
							bi[ii] = if bi[ii] > 0 then (bi[ii] = findItem boneNames skinBoneNames[bi[ii]]) else (1)
							)
						)
					else (
						bi = #(1)
						wv = #(1.0)
						)
					wvArray[i] = wv
					biArray[i] = bi
					)
				)
			),
		fn rebuildFromScene &boneArray &boneArrayRelMatrices &texpath &texList = (
			/*
				mesh should be converted to editable mesh (triangle mesh)
				prior to runnning this function on the mesh.
				
				the mesh is read and wriitten to the object per face as triangle list
				
				this means the resulting data written back to the game is unoptimized,
				larger in size, slower to load and will hinder frame rates.
				
				an optimizer to shrink would need to be wriiten later..
			*/
			-- Reset arrays in object
			primitives = #()
			faces = #()
			positions = #()
			normals = #()
			texcoords = #()
			trans = #()
			index1 = #()
			index2 = #()
			weight = #()
			index3 = #()
			
			-- convert scene selection into an array
			local o = undefined
			
			-- filter out none mesh types from selection
			local mdls = for o in selection where findItem #(Editable_mesh, Editable_Poly) (classof o) > 0 collect o
			
			-- Convert meshes from selection array into memory objects
			local i = 1
			local moodles = #()
			if mdls.count > 0 do (
				moodles[mdls.count] = undefined
				)
			-- get total face count
			face_count = 0
			for i = 1 to mdls.count do (
				moodles[i] = snapshotAsMesh mdls[i]
				face_count += moodles[i].numfaces
				)
			
			-- check face count
			if face_count > 0 do (
				
				local t
				local j = 1
				local faceArray = #()
				local vertArray = #()
				local tvertArray = #()
				local normArray = #()
				local weArray = #()
				local biArray = #()
				local weights = #()
				local boneids = #()
				local skinMod = undefined
				local vpos = 0
				local fpos = 0
				local ii = 1
				local v = 0
				local j = 1
				local m = 1
				local matCount = 0
				local faceSel = #{}
				local f
				local tvface = [1,1,1]
				local x = 0
				local w = 0
				local commitedFaces = 0
				local uniqueBones = #()
				local boneIndex = 0
				local tfm = matrix3 1
				local facemats = #()
				local texIds = #()
				local texName = ""
				-- dimension ararys in object
				faces[face_count*3] = 1
				positions[face_count*3] = [0.0, 0.0, 0.0]
				normals[face_count*3] = [0.0, 0.0, 0.0]
				texcoords[face_count*3] = #(0.0, 0.0)
				
				-- Auto Generate a raw face index sequence
				for j = 1 to face_count * 3 do (
					x = fpos + j
					faces[x] = x - 1
					
					-- swap faces around
					if mod j 3 == 0 do (
						ii = faces[x]
						faces[x] = faces[x - 1]
						faces[x - 1] = ii
						)
					)
				
				-- process each mesh from selection
				for i = 1 to mdls.count do (
					
					-- get memory object that was created previously
					t = moodles[i]
					
					-- bail if mesh is empty
					if t.numfaces == 0 do continue
					
					-- Get face indices from tmesh (memory object)
					faceArray = #()
					faceArray[t.numfaces] = [1,1,1]
					for j = 1 to t.numfaces do (
						faceArray[j] = getFace t j
						)
					
					-- Get Normals
					normArray = #()
					get_mesh_normals mdls[i] faceArray &normArray
					
					-- Get Blend Weights
					biArray = #()
					wvArray = #()
					get_mesh_blendweights &mdls[i] &boneArray &biArray &wvArray
					
					
					-- Count the number of materials used by the mesh
					matCount = 0
					texIds = #()
					if classof mdls[i].material == MultiMaterial then ( -- run through each material
						matCount += mdls[i].material.count
						if matCount> 0 do (
							texIds[matCount] = 0
							)
						for j = 1 to mdls[i].material.count do (
							texIds[j] = 0
							texName = ""
							case (classOf mdls[i].material[j]) of (
								(StandardMaterial): (
									if mdls[i].material[j].diffuseMap != undefined do (
										texName = try((getFilenameFile mdls[i].material[j].diffuseMap.filename))catch("")
										)
									)
								(PhysicalMaterial): (
									if mdls[i].material[j].base_color_map != undefined do (
										texName = try((getFilenameFile mdls[i].material[j].base_color_map.filename))catch("")
										)
									)
								)
							if texName != "" do (
								
								
								x = findItem texList (texpath + texName)
								if x == 0 do (
									append texList (texpath + texName)
									x = texList.count
									)
								
								texIds[j] = x - 1
								
								)
							)
						)
					else (
						matCount = 1
						case (classOf mdls[i].material) of (
							(StandardMaterial): (
								if mdls[i].material.diffuseMap != undefined do (
									texName = try((getFilenameFile mdls[i].material.diffuseMap.filename))catch("")
									)
								)
							(PhysicalMaterial): (
								if mdls[i].material.base_color_map != undefined do (
									texName = try((getFilenameFile mdls[i].material.base_color_map.filename))catch("")
									)
								)
							)
						if texName != "" do (
							
							
							x = findItem texList (texpath + texName)
							if x == 0 do (
								append texList (texpath + texName)
								x = texList.count
								)
							
							texIds = #(x - 1)
							
							)
						)
					
					-- get face material id's for ordering faces by id
					facemats = #()
					facemats[t.numfaces] = 1
					if matCount > 1 then (
						for j = 1 to t.numfaces do (
							facemats[j] = (mod ((getFaceMatID t j) - 1) matCount) + 1
							)
						) else (for j = 1 to t.numfaces do (facemats[j] = 1))
					
					-- Set faces that are to be read to a bit array
					faceSel = #{1..(t.numfaces)}
					
					-- loop through each material, check for relating mat id agasint each face material index
					for m = 1 to matCount do (
						
						-- count how many faces per material, its possible there could be none
						commitedFaces = 0
						
						-- loop through each face set in the bit array
						for f in faceSel do (
							
							-- Check face material index againt the material index
							if facemats[f] == m do (
								
								-- eliminate face index from bit array
								faceSel[f] = false
								
								-- increment material face count for this material index
								commitedFaces+=1
								
								
								-- Positions
								for ii = 1 to 3 do (
									x = vpos + v + ii
									positions[x] = getVert t faceArray[f][ii]
									)
								
								-- Texture Coordinates
								tvface = getTVFace t f
								for ii = 1 to 3 do (
									x = vpos + v + ii
									texcoords[x] = getTVert t tvface[ii]
									texcoords[x] = [texcoords[x][1], 1.0 - texcoords[x][2], 0.0]
									)
								
								for ii = 1 to 3 do (
									x = vpos + v + ii
									normals[x] = normArray[faceArray[f][ii]]
									)
								
								-- Blend Weights
								for ii = 1 to 3 do (
									x = vpos + v + ii
									for w = 1 to wvArray[faceArray[f][ii]].count do (
										
										append weight wvArray[faceArray[f][ii]][w] -- Weight Value
										boneIndex = findItem index3 biArray[faceArray[f][ii]][w]
										if boneIndex == 0 do (
											append index3 biArray[faceArray[f][ii]][w] -- Pallet Bone Index
											boneIndex = uniqueBones.count
											)
										append index1 x -- Vertex Index
										append index2 boneIndex -- Weight Bone Index
										
										-- transform the normal
										tfm = matrixFromNormal normals[x] * boneArrayRelMatrices[biArray[faceArray[f][ii]][w]]
										tfm.row4 = [0.0, 0.0, 0.0]
										append trans #(
											#(tfm.row1.x, tfm.row1.y, tfm.row1.z, 0.0),
											#(tfm.row2.x, tfm.row2.y, tfm.row2.z, 0.0),
											#(tfm.row3.x, tfm.row3.y, tfm.row3.z, 0.0),
											#(tfm.row4.x, tfm.row4.y, tfm.row4.z, 1.0)
											)
										)
									)
								
								-- increment vertex index for chr buffer
								v += 3
								)
							)
						
						-- check if any faces were commited for this material index
						if commitedFaces > 0 do (
							
							-- add material element to object
							append primitives (
								fmtDTS_Primative firstElement:fpos numElements:commitedFaces type:(texIds[m] + 0x10000000) --add flag for no material ?
								)
							fpos += commitedFaces
							vpos += commitedFaces * 3
							)
						)
					-- Remove Mesh From Memory
					delete moodles[i]
					)
				)
			-- clean up model array
			moodles = undefined
			)
		)
	
	struct fmtDTS_DetailLevel ( -- 28 bytes
		/*uint32_t*/        	nameIndex      = 0, -- incrementing number from 0 ? frame index?
		/*uint32_t*/        	subshapeIndex  = 0, -- ? always 0 ? material frame index?
		/*uint32_t*/        	LOD_Level      = 0, -- same as above, number increments from 0 ? decal frame index?
		/*float*/           	minDrawSize    = 0.0, -- range [2 to 30], lower detail meshes are 2.0 and higher ones are around 30.0
		/*float*/           	avgError       = 0.0, -- always 0
		/*float*/           	maxError       = 0.0, -- always 0
		/*uint32_t*/        	polygon_count  = 0,
		fn read &f = (
			nameIndex = readLong f #unsigned
			subshapeIndex = readLong f #unsigned
			LOD_Level = readLong f #unsigned
			minDrawSize = readFloat f
			avgError = readFloat f
			maxError = readFloat f
			polygon_count = readLong f #unsigned
			),
		fn write &s = (
			writeLong s nameIndex #unsigned
			writeLong s subshapeIndex #unsigned
			writeLong s LOD_Level #unsigned
			writeFloat s minDrawSize
			writeFloat s avgError
			writeFloat s maxError
			writeLong s polygon_count #unsigned
			)
		)
	
	struct fmtDSQ_Sequence (
		/*
			the docs cover the DSQ and the squences struct,
			but nothing seems to match up.. hm
		*/
		/*uint32_t*/        	unk012         = 0, -- flag
		/*uint32_t*/        	unk013         = 0, -- number of frames
		/*float*/           	unk014         = 0.0, -- duration in seconds 
		/*uint32_t*/        	unk015         = 0, -- starting bone?
		/*uint32_t*/        	unk016         = 0, -- number of bones in the skeleton?
		/*string[]*/        	unk016_Array   = "", -- name
		/*uint32_t*/        	unk017         = 0,
		/*uint32_t*/        	unk018         = 0,
		/*uint32_t*/        	unk019         = 0, -- number of bitsets for rotations
		/*uint32_t[]*/      	unk019_Array   = #(), -- rotation bitset
		/*uint32_t*/        	unk020         = 0, -- num of rotation keyframe updates
		/*uint32_t*/        	unk021         = 0,
		/*uint32_t*/        	unk022         = 0, -- number of bitsets for translation
		/*uint32_t[]*/      	unk022_Array   = #(), -- translation bitset
		/*uint32_t*/        	unk023         = 0, -- num of translation keyframe updates
		/*uint32_t*/        	unk024         = 0,
		/*uint32_t*/        	unk025         = 0,
		/*uint32_t*/        	unk026         = 0,
		/*uint32_t*/        	unk027         = 0,
		/*uint32_t[]*/      	unk027_Array   = #(), -- ? scale bitset??
		/*uint32_t*/        	unk028         = 0,
		/*uint32_t[]*/      	unk028_Array   = #(), -- ? decal bitset??
		/*uint32_t*/        	unk029         = 0,
		/*uint32_t[]*/      	unk029_Array   = #(), -- ? material bitset??
		/*uint32_t*/        	unk030         = 0,
		/*uint32_t*/        	unk031         = 0,
		/*uint32_t*/        	unk032         = 0,
		/*uint32_t*/        	unk033         = 0,
		/*uint32_t*/        	unk034         = 0,
		/*uint32_t*/        	unk035         = 0,
		/*uint32_t*/        	unk036         = 0,
		/*string[]*/        	unk036_Array   = #(), -- ? visiblity bitset??
		/*uint32_t*/        	unk037         = 0,
		/*string[]*/        	unk037_Array   = #(), -- ? frame bitset??
		/*uint32_t[]*/      	unk038_Array   = #(), -- ? material frame bitset??
		fn readFixedString &f = (
			local i = 1, s = "", l = readByte f #unsigned
			for i = 1 to l do (s += bit.IntAsChar(readByte f #unsigned))
			s
			),
		fn writeFixedString &s &str = (
			local i = 1, c = str.count
			writeByte s c #unsigned
			for i = 1 to c do (writeByte s (bit.CharAsInt(subString str i 1)) #unsigned)
			),
		fn read &f verbose:false = (
			unk012 = readLong f #unsigned
			unk013 = readLong f #unsigned -- 2, count
			unk014 = readFloat f
			unk015 = readLong f #unsigned
			unk016 = readLong f #unsigned
			unk016_Array = readFixedString(&f)
			if verbose do print unk016_Array
			unk017 = readLong f #unsigned -- string index for the same name but in the model file.. hm
			unk018 = readLong f #unsigned
			unk019 = readLong f #unsigned
			
			if verbose do (
			format "BuF1: \t%, [numframes: %?], %, %, %, %, %, %\n" \
				unk012 unk013 unk014 unk015 \
				unk016 unk017 unk018 unk019
				)
			
			/*
				this field defines bitsets as unsigned 32bit ints
				however max only stores them as signed so it messes
				things up. below I just read the bit set as 16bits
				to avoid the sign issue in maxscript....
			*/
			unk019_Array = #()
			if unk019 > 0 do (
				--unk019_Array[unk019] = 0
				unk019_Array[unk019*2] = 0
				for i = 1 to unk019*2 do (
					--unk019_Array[i] = readLong f #unsigned
					unk019_Array[i] = readShort f #unsigned
					)
				)
			if verbose do print (unk019_Array as string)
			
			unk020 = readLong f #unsigned
			unk021 = readLong f #unsigned
			unk022 = readLong f #unsigned
			
			if verbose do format "BuF2: \t%, %, %\n" unk020 unk021 unk022
			
			unk022_Array = #()
			if unk022 > 0 do (
				--unk022_Array[unk022] = 0
				unk022_Array[unk022*2] = 0
				for i = 1 to unk022*2 do (
					--unk022_Array[i] = readLong f #unsigned
					unk022_Array[i] = readShort f #unsigned
					)
				)
			if verbose do print (unk022_Array as string)
			
			unk023 = readLong f #unsigned
			unk024 = readLong f #unsigned
			unk025 = readLong f #unsigned
			unk026 = readLong f #unsigned
			unk027 = readLong f #unsigned
			
			if verbose do format "BuF3: \t%, %, %, %, %\n" unk023 unk024 unk025 unk026 unk027
			
			unk027_Array = #()
			if unk027 > 0 do ( -- rotations
				unk027_Array[unk027] = #(0.0, 0.0, 0.0, 0.0)
				for i = 1 to unk027 do (
					unk027_Array[i] = #(readShort f #signed / 32767.0, readShort f #signed / 32767.0, readShort f #signed / 32767.0, readShort f #signed / 32767.0)
					)
				)
			if verbose do print (unk027_Array as string)
			unk028 = readLong f #unsigned
			unk028_Array = #()
			if unk028 > 0 do ( -- rotations still
				unk028_Array[unk028] = #(0.0, 0.0, 0.0, 0.0)
				for i = 1 to unk028 do (
					unk028_Array[i] = #(readShort f #signed / 32767.0, readShort f #signed / 32767.0, readShort f #signed / 32767.0, readShort f #signed / 32767.0)
					)
				)
			if verbose do print (unk028_Array as string)
			unk029 = readLong f #unsigned
			unk029_Array = #()
			if unk029 > 0 do (
				unk029_Array[unk029] = [0, 0, 0]
				for i = 1 to unk029 do (
					unk029_Array[i] = [readFloat f, readFloat f, readFloat f]
					--print (unk029_Array[i] as string)
					)
				)
			--local msh = mesh vertices:unk029_Array faces:#()
			
			if verbose do print (unk029_Array as string)
			unk030 = readLong f #unsigned
			unk031 = readLong f #unsigned
			unk032 = readLong f #unsigned
			unk033 = readLong f #unsigned
			unk034 = readLong f #unsigned
			unk035 = readLong f #unsigned
			unk036 = readLong f #unsigned
			
			if verbose do (format "BuF4: \t%, %, %, %, %, %, %\n" \
				unk030 unk031 unk032 unk033 unk034 \
				unk035 unk036)
			
			unk036_Array = #()
			if unk036 > 0 do (
				unk036_Array[unk036] = #(0, 0)
				for i = 1 to unk036 do (
					unk036_Array[i] = #(readLong f #unsigned, readLong f #unsigned)
					)
				)
			if verbose do print (unk036_Array as string)
			
			unk037 = readLong f #unsigned
			unk037_Array = #()
			unk038_Array = #()
			if unk037 > 0 do (
				unk037_Array[unk037] = ""
				unk038_Array[unk037] = 0
				for i = 1 to unk037 do (
					unk037_Array[i] = readFixedString(&f)
					)
				for i = 1 to unk037 do (
					unk038_Array[i] = readLong f #unsigned
					)
				)
			if verbose do print (unk037_Array as string)
			if verbose do print (unk038_Array as string)
			),
		fn write &s = (
			local i = 1
			writeLong s unk012 #unsigned
			writeLong s unk013 #unsigned
			writeFloat s unk014
			writeLong s unk015 #unsigned
			writeLong s unk016 #unsigned
			writeFixedString &s unk016_Array
			writeLong s unk017 #unsigned
			writeLong s unk018 #unsigned
			/*
				had to change the bitet read from a 32bit to a 16bit
				because of a technical reading in maxscript.
			*/
			--writeLong s (unk019 = unk019_Array.count) #unsigned
			writeLong s (unk019 = (unk019_Array.count / 2) as integer) #unsigned
			for i = 1 to unk019_Array.count do (
				--writeLong s unk019_Array[unk019] #unsigned
				writeShort s unk019_Array[unk019] #unsigned
				)
			writeLong s unk020 #unsigned
			writeLong s unk021 #unsigned
			--writeLong s (unk022 = unk022_Array.count) #unsigned
			writeLong s (unk022 = (unk022_Array.count / 2) as integer) #unsigned
			for i = 1 to unk022_Array.count do (
				--writeLong s unk022_Array[i] #unsigned
				writeShort s unk022_Array[i] #unsigned
				)
			writeLong s unk023 #unsigned
			writeLong s unk024 #unsigned
			writeLong s unk025 #unsigned
			writeLong s unk026 #unsigned
			writeLong s (unk027 = unk027_Array.count) #unsigned
			for i = 1 to unk027 do (
				writeShort s (unk027_Array[i][1] * 32767.0) #signed
				writeShort s (unk027_Array[i][2] * 32767.0) #signed
				writeShort s (unk027_Array[i][3] * 32767.0) #signed
				writeShort s (unk027_Array[i][4] * 32767.0) #signed
				)
			writeLong s (unk028 = unk028_Array.count) #unsigned
			for i = 1 to unk028 do (
				writeShort s (unk028_Array[i][1] * 32767.0) #signed
				writeShort s (unk028_Array[i][2] * 32767.0) #signed
				writeShort s (unk028_Array[i][3] * 32767.0) #signed
				writeShort s (unk028_Array[i][4] * 32767.0) #signed
				)
			writeLong s (unk029 = unk029_Array.count) #unsigned
			for i = 1 to unk029 do (
				writeLong s unk029_Array[i][1] #unsigned
				writeLong s unk029_Array[i][2] #unsigned
				writeLong s unk029_Array[i][3] #unsigned
				)
			writeLong s unk030 #unsigned
			writeLong s unk031 #unsigned
			writeLong s unk032 #unsigned
			writeLong s unk033 #unsigned
			writeLong s unk034 #unsigned
			writeLong s unk035 #unsigned
			writeLong s (unk036 = unk036_Array.count) #unsigned
			for i = 1 to unk036 do (
				writeLong s unk036_Array[i][1] #unsigned
				writeLong s unk036_Array[i][2] #unsigned
				)
			writeLong s (unk037 = unk037_Array.count) #unsigned
			for i = 1 to unk037 do (writeFixedString &s unk037_Array[i])
			for i = 1 to unk037 do (writeLong s unk038_Array[i] #unsigned)
			)
		)
	
	struct fmtDSQ (
		/*uint16_t*/        	version        = 0,
		/*uint16_t*/        	exporter       = 0,
		/*uint16_t*/        	count          = 0,
		/*string[]*/        	nodes          = #(),
		/*uint32_t*/        	unk011         = 0,
		/*fmtDSQ_Sequence*/ 	seq            = fmtDSQ_Sequence(),
		fn readFixedString &f = (
			local i = 1, s = "", l = readByte f #unsigned
			for i = 1 to l do (s += bit.IntAsChar(readByte f #unsigned))
			s
			),
		fn writeFixedString &s &str = (
			local i = 1, c = str.count
			writeByte s c #unsigned
			for i = 1 to c do (writeByte s (bit.CharAsInt(subString str i 1)) #unsigned)
			),
		fn read &f = (
			version = readShort f #unsigned
			exporter = readShort f #unsigned
			count = readLong f #unsigned
			nodes = #()
			if count > 0 do (
				local i = 1
				nodes[count] = ""
				for i = 1 to count do (
					nodes[i] = readFixedString(&f)
					)
				)
			unk011 = readLong f #unsigned
			seq.read(&f)
			),
		fn write &s = (
			writeShort s version #unsigned
			writeShort s exporter #unsigned
			writeLong s (count = nodes.count) #unsigned
			local i = 1
			for i = 1 to count do (
				writeFixedString &s nodes[i]
				)
			riteLong s unk011 #unsigned
			seq.write(&s)
			)
		)
	
	struct fmtUNK (
		/*uint16_t*/        	unk040         = 0,
		/*uint32_t*/        	unk041         = 0,
		/*uint32_t*/        	unk042         = 0,
		/*uint32_t*/        	unk043         = 0,
		/*uint32_t*/        	unk044         = 0,
		/*string[]*/        	unk045         = 0,
		/*uint32_t*/        	unk046         = 0,
		/*uint32_t*/        	unk047         = 0,
		/*uint32_t*/        	unk048         = 0,
		/*uint32_t[]*/      	unk048_Array   = #(),
		/*uint32_t*/        	unk049         = 0,
		/*uint32_t*/        	unk050         = 0,
		/*uint32_t*/        	unk051         = 0,
		/*uint32_t[]*/      	unk051_Array   = #(),
		/*uint32_t*/        	unk052         = 0,
		/*uint32_t*/        	unk053         = 0,
		/*uint32_t*/        	unk054         = 0,
		/*uint32_t*/        	unk055         = 0,
		/*uint32_t*/        	unk056         = 0,
		/*uint32_t[]*/      	unk056_Array   = #(),
		/*uint32_t*/        	unk057         = 0,
		/*uint32_t[]*/      	unk057_Array   = #(),
		/*uint32_t*/        	unk058         = 0,
		/*uint32_t[]*/      	unk058_Array   = #(),
		/*uint32_t*/        	unk059         = 0,
		/*uint32_t*/        	unk060         = 0,
		/*uint32_t*/        	unk061         = 0,
		/*uint32_t*/        	unk062         = 0,
		/*uint32_t*/        	unk063         = 0,
		/*uint32_t*/        	unk064         = 0,
		/*uint32_t*/        	unk065         = 0,
		/*uint32_t*/        	unk066         = 0,
		fn readFixedString &f = (
			local i = 1, s = "", l = readByte f #unsigned
			for i = 1 to l do (s += bit.IntAsChar(readByte f #unsigned))
			s
			),
		fn writeFixedString &s &str = (
			local i = 1, c = str.count
			writeByte s c #unsigned
			for i = 1 to c do (writeByte s (bit.CharAsInt(subString str i 1)) #unsigned)
			),
		fn read &f = (
			local i = 1
			unk040 = readShort f #unsigned
			unk041 = readLong f #unsigned
			unk042 = readLong f #unsigned
			unk043 = readLong f #unsigned
			unk044 = readLong f #unsigned
			unk045 = readFixedString(&f)
			unk046 = readLong f #unsigned
			unk047 = readLong f #unsigned
			unk048 = readLong f #unsigned
			unk048_Array = #()
			if unk048 > 0 do (
				unk048_Array[unk048] = 0
				for i = 1 to unk048 do (
					unk048_Array[i] = readLong f #unsigned
					)
				)
			
			unk049 = readLong f #unsigned
			unk050 = readLong f #unsigned
			unk051 = readLong f #unsigned
			unk051_Array = #()
			if unk051 > 0 do (
				unk051_Array[unk051] = 0
				for i = 1 to unk051 do (
					unk051_Array[i] = readLong f #unsigned
					)
				)
			unk052 = readLong f #unsigned
			unk053 = readLong f #unsigned
			unk054 = readLong f #unsigned
			unk055 = readLong f #unsigned
			unk056 = readLong f #unsigned
			unk056_Array = #()
			if unk056 > 0 do (
				unk056_Array[unk056] = #(0, 0)
				for i = 1 to unk056 do (
					unk056_Array[i] = #(readLong f #unsigned, readLong f #unsigned)
					)
				)
			unk057 = readLong f #unsigned
			unk057_Array = #()
			if unk057 > 0 do (
				unk057_Array[unk057] = #(0, 0)
				for i = 1 to unk057 do (
					unk057_Array[i] = #(readLong f #unsigned, readLong f #unsigned)
					)
				)
			unk058 = readLong f #unsigned
			unk058_Array = #()
			if unk058 > 0 do (
				unk058_Array[unk058] = #(0, 0, 0)
				for i = 1 to unk058 do (
					unk058_Array[i] = #(readLong f #unsigned, readLong f #unsigned, readLong f #unsigned)
					)
				)
			unk059 = readLong f #unsigned
			unk060 = readLong f #unsigned
			unk061 = readLong f #unsigned
			unk062 = readLong f #unsigned
			unk063 = readLong f #unsigned
			unk064 = readLong f #unsigned
			unk065 = readLong f #unsigned
			unk066 = readLong f #unsigned
			),
		fn write &s = (
			local i = 1
			writeShort s unk040 #unsigned
			writeLong s unk041 #unsigned
			writeLong s unk042 #unsigned
			writeLong s unk043 #unsigned
			writeLong s unk044 #unsigned
			writeFixedString &s unk045
			writeLong s unk046 #unsigned
			writeLong s unk047 #unsigned
			writeLong s (unk048 = unk048_Array.count) #unsigned
			for i = 1 to unk048 do (
				writeLong s unk048_Array[i] #unsigned
				)
			writeLong s unk049 #unsigned
			writeLong s unk050 #unsigned
			writeLong s (unk051 = unk051_Array.count) #unsigned
			for i = 1 to unk051 do (
				writeLong s unk051_Array[i] #unsigned
				)
			writeLong s unk052 #unsigned
			writeLong s unk053 #unsigned
			writeLong s unk054 #unsigned
			writeLong s unk055 #unsigned
			writeLong s (unk056 = unk056_Array.count) #unsigned
			for i = 1 to unk056 do (
				writeLong s unk056_Array[i][1] #unsigned
				writeLong s unk056_Array[i][2] #unsigned
				)
			writeLong s (unk057 = unk057_Array.count) #unsigned
			for i = 1 to unk057 do (
				writeLong s unk057_Array[i][1] #unsigned
				writeLong s unk057_Array[i][2] #unsigned
				)
			writeLong s (unk058 = unk058_Array.count) #unsigned
			for i = 1 to unk058 do (
				writeLong s unk058_Array[i][1] #unsigned
				writeLong s unk058_Array[i][2] #unsigned
				writeLong s unk058_Array[i][3] #unsigned
				)
			writeLong s unk059 #unsigned
			writeLong s unk060 #unsigned
			writeLong s unk061 #unsigned
			writeLong s unk062 #unsigned
			writeLong s unk063 #unsigned
			writeLong s unk064 #unsigned
			writeLong s unk065 #unsigned
			writeLong s unk066 #unsigned
			)
		)
	
	struct fmtDSQ_File (
		/*
			in one doc it said that the squences are like the 
			DSQ files except the name?
			
			I observed two types 0x1D and 0x1E, the structures
			varied enough so I didn't care to corrolate them
			so I split them into two structs; fmtDSQ, fmtUNK
		*/
		/*uint16_t*/        	type           = 0,
		/*
				bin:6543210987654321
			hex  	1111111000000000
			========================
			0x0000 	0000000000000000
			0x0001 	0000000000000001 	UniformScale
			0x0002 	0000000000000010 	AlignedScale
			0x0004 	0000000000000100 	ArbitraryScale
			0x0008 	0000000000001000 	Blend
			0x0010 	0000000000010000 	Cyclic
			0x0020 	0000000000100000	MakePath
			0x0040 	0000000001000000	IFLInit
			0x0080 	0000000010000000	HasTranslucency

			----------------
			1111111111111111
			
			0x1E 	00011110
			0x1D 	00011101
			
			
		*/
		/*fmtDSQ_Sequence*/ 	dsq            = fmtDSQ_Sequence(),
		/*fmtUMK*/          	unk            = fmtUNK(),
		fn read &f = (
			local result = true
			local pos = ftell f
			type = readShort f #unsigned
			case type of (
				0x1D: (
					unk = fmtUNK()
					unk.read(&f)
					-- fseek f 18 #seek_cur
					-- fseek f (readByte f #unsigned) #seek_cur
					-- fseek f 8 #seek_cur
					-- fseek f ((readLong f #unsigned) * 4) #seek_cur
					-- fseek f 8 #seek_cur
					-- fseek f ((readLong f #unsigned) * 4) #seek_cur
					-- fseek f 16 #seek_cur
					-- fseek f ((readLong f #unsigned) * 8) #seek_cur
					-- fseek f ((readLong f #unsigned) * 8) #seek_cur
					-- fseek f ((readLong f #unsigned) * 12) #seek_cur
					-- fseek f 32 #seek_cur
					
					)
				0x1E: (
					dsq = fmtDSQ_Sequence()
					dsq.read(&f)
					)
				default: (
					format "Error: \tUnknown file type {%} @ %\n" type ((pos) as integer)
					result = false
					)
				)
			result
			),
		fn write &s = (
			writeShort s type #unsigned
			case type of (
				0x1D: (unk.write(&s))
				0x1E: (dsq.write(&s))
				)
			)
		)
	
	struct fmtDTS ( -- Dynamix Three Space
		/*uint16_t*/        	version        = 29,
		/*uint16_t*/        	exp_ver        = 0, -- always 0
		/*fmtDTS_Bounds*/    	bound          = fmtDTS_Bounds(),
		/*uint32_t*/        	node_count     = 0,
		/*fmtDTS_Node[]*/    	nodes          = #(),
		/*uint32_t*/        	obj_count      = 0,
		/*fmtDTS_Object[]*/ 	objs           = #(),
		/*fmtDTS_Decal[4]*/ 	decals         = #(fmtDTS_Decal(), fmtDTS_Decal(), fmtDTS_Decal(), fmtDTS_Decal()),
		/*uint32_t*/        	rotation_count = 0,
		/*uint16_t[4][]*/	   	rotations      = #(),
		/*uint32_t*/        	position_count = 0,
		/*float[3][]*/      	positions      = #(),
		/*uint32_t*/        	unk001         = 0,
		/*float*/           	unk002         = 0.0,
		/*uint32_t*/        	lod_count      = 0,
		/*fmtDTS_DetailLevel*/ 	LevelOfDetails = #(),
		/*uint32_t*/        	mesh_count     = 0,
		/*fmtDTS_Mesh*/     	meshes         = #(),
		/*uint32_t*/        	string_count   = 0,
		/*string[]*/        	strings        = #(),
		/*uint32_t*/        	sequence_count = 0,
		/*fmtDSQ_File[]*/   	sequences      = #(),
		/*uint32_t*/        	texture_count  = 0, -- seems the game only uses 1 texture per material
		/*string[]*/        	textures       = #(),
		fn readFixedString &f = (
			local i = 1, s = "", l = readByte f #unsigned
			for i = 1 to l do (s += bit.IntAsChar(readByte f #unsigned))
			s
			),
		fn writeFixedString &s &str = (
			local i = 1, c = str.count
			writeByte s c #unsigned
			for i = 1 to c do (writeByte s (bit.CharAsInt(subString str i 1)) #unsigned)
			),
		fn read &f = (
			local i = 1
			
			-- Read Version
			version = readShort f #unsigned
			
			-- Only continue if version 27 or 29
			if version == 27 or version == 29 then (
				
				-- Read Header
				exp_ver = readShort f #unsigned
				
				if version > 27 do (
					bound.read(&f) -- 44 bytes
					)
				
				-- Read Datablocks, starts at position 48
				local i = 1
				
				-- Read Node / Bone Details
				nodes = #()
				node_count = readLong f #unsigned
				--format "\nnode_count: \t%\n" node_count
				--print "----------------------------------------------------------------"
				if node_count > 0 do (
					nodes[node_count] = fmtDTS_Node()
					for i = 1 to node_count do (
						-- 20 bytes per entry
						nodes[i] = fmtDTS_Node()
						nodes[i].read(&f)
						)
					)
				--print nodes
				
				-- Read Object Details
				objs = #()
				obj_count = readLong f #unsigned
				--format "\nobj_count: \t%\n" obj_count
				--print "----------------------------------------------------------------"
				if obj_count > 0 do (
					objs[obj_count] = fmtDTS_Object()
					for i = 1 to obj_count do (
						-- 20 bytes per entry
						objs[i] = fmtDTS_Object()
						objs[i].read &f version
						)
					)
				--print objs
				
				if version > 27 do (
					
					-- Read Decal Info
					local decal_count = 4
					for i = 1 to decal_count do (-- 8 bytes per entry
						/*
							the 3rd and 4th entry contain the counts to the
							node and object table respectfully
							
							I would guess this is detailing objects in the file?
							so i wonder why the first two are nulled or left reserved..
							
							example:
							(fmtDTS_Decal firstNode:1 firstObject:0 firstDecal:0)
							(fmtDTS_Decal firstNode:1 firstObject:0 firstDecal:0)
							(fmtDTS_Decal firstNode:1 firstObject:18 firstDecal:0)
							(fmtDTS_Decal firstNode:1 firstObject:6 firstDecal:0)
							
						*/
						decals[i] = fmtDTS_Decal()
						decals[i].read &f version
						)
					
					rotations = #()
					rotation_count = readLong f #unsigned
					if rotation_count > 0 do (
						rotations[rotation_count] = quat 0 0 0 1
						for i = 1 to rotation_count do ( -- 8 bytes
							rotations[i] = (
								quat \
									((readShort f #signed) / 32767.0) \
									((readShort f #signed) / 32767.0) \
									((readShort f #signed) / 32767.0) \
									((readShort f #signed) / 32767.0)
								)
							
							)
						)
					
					positions = #()
					position_count = readLong f #unsigned
					if position_count > 0 do (
						positions[position_count] = [0.0, 0.0, 0.0]
						for i = 1 to position_count do ( -- 12 bytes
							positions[i] = [readFloat f, readFloat f, readFloat f]
							)
						)
					
					
					unk001 = readLong f #unsigned -- 2 ? could be type code or max number of mesh materials?
					--format "unk001: \t% (%)\n" unk001 (((ftell f) - 4) as integer)
					unk002 = readFloat f -- 1.0 ? detail size? or visiblity?
					--print unk002
					)
				
				LOD_Count = readLong f #unsigned
				LevelOfDetails = #()
				if LOD_Count > 0 do ( -- 28 Bytes per
					LevelOfDetails[LOD_Count] = fmtDTS_DetailLevel()
					for i = 1 to LOD_Count do (
						LevelOfDetails[i] = fmtDTS_DetailLevel()
						LevelOfDetails[i].read(&f)
						)
					)
				
				
				mesh_count = readLong f #unsigned
				--format "mesh_count: \t% (%)\n" mesh_count ((ftell f) as integer)
				meshes = #()
				if mesh_count > 0 do (
					meshes[mesh_count] = fmtDTS_Mesh()
					for i = 1 to mesh_count do (
						--format "Mesh(% / %): \t%\n" i mesh_count ((ftell f) as integer)
						meshes[i] = fmtDTS_Mesh()
						meshes[i].read(&f)
						
						
						
						)
					)
				
				strings = #()
				string_count = readLong f #unsigned
				--format "string_count: \t% (%)\n" string_count ((ftell f) as integer)
				if string_count > 0 do (
					strings[string_count] = ""
					for i = 1 to string_count do (
						strings[i] = readFixedString(&f)
						--format "%\t%\n" (i - 1) strings[i]
						)
					)
				--print (ftell f)
				
				sequence_count = 0
				sequences = #()
				if version > 27 do (
					
					sequence_count = readLong f #unsigned
					--format "sequence_count: \t%\n" sequence_count
					if sequence_count > 0 do (
						sequences[sequence_count] = fmtDSQ_File()
						for i = 1 to sequence_count do (
							sequences[i] = fmtDSQ_File()
							if not sequences[i].read(&f) do (
								format "Error Ocurred Reading sequences Section {%}\n" ((ftell f) as integer)
								exit
								)
							)
						)
					)
				texture_count = readLong f #unsigned
				textures = #()
				if texture_count > 0 do (
					textures[texture_count] = ""
					for i = 1 to texture_count do (
						textures[i] = readFixedString(&f)
						)
					)
				
				local read_stop = ftell f
				fseek f 0 #seek_end
				local fsize = ftell f
				if fsize != read_stop do (
					
					format "Read Error: \tRead to % of %\n" ((read_stop) as integer) ((fsize) as integer)
					)
				) else (messageBox ("Error:\nUnsupported Version v" + (version as string)))
			),
		fn write &s = (
			local i = 1
			writeShort s version #unsigned
			writeShort s exp_ver #unsigned
			if version > 27 do (bound.write(&s))
			writeLong s (node_count = nodes.count) #unsigned
			for i = 1 to node_count do (nodes[i].write(&s))
			writeLong s (obj_count = objs.count) #unsigned
			for i = 1 to obj_count do (objs[i].write(&s))
			if version > 27 do (
				local decal_count = 4
				for i = 1 to decal_count do (decals[i].write(&s))
				writeLong s (rotation_count = rotations.count) #unsigned
				for i = 1 to rotation_count do ( -- 8 bytes
					writeShort s (rotations[i].x * 32767.0) #signed
					writeShort s (rotations[i].y * 32767.0) #signed
					writeShort s (rotations[i].z * 32767.0) #signed
					writeShort s (rotations[i].w * 32767.0) #signed
					)
				writeLong s (position_count = positions.count) #unsigned
				for i = 1 to position_count do ( -- 12 bytes
					writeFloat s positions[i][1]
					writeFloat s positions[i][2]
					writeFloat s positions[i][3]
					)
				writeLong s unk001 #unsigned -- 2 ? could be type code
				writeFloat s unk002
				)
			writeLong s (LOD_Count = LevelOfDetails.count) #unsigned
			for i = 1 to LOD_Count do (LevelOfDetails[i].write(&s))
			writeLong s (mesh_count = meshes.count) #unsigned
			for i = 1 to mesh_count do (meshes[i].write(&s))
			writeLong s (string_count = strings.count) #unsigned
			for i = 1 to string_count do (writeFixedString &s strings[i])
			if version > 27 do (
				writeLong s (sequence_count = sequences.count) #unsigned
				for i = 1 to sequence_count do (sequences[i].write(&s))
				)
			writeLong s (texture_count = textures.count) #unsigned
			for i = 1 to texture_count do (writeFixedString &s textures[i])
			),
		fn buildSkeleton mscale:39.3700787401574803149606299212598425196850393700787402 = (
			local boneArray = #()
			local num_bones = positions.count
			if num_bones > 0 do (
				local i = 1
				local b = undefined
				local boneName = ""
				local buildBone = #{1..(num_bones)}
				boneArray[num_bones] = undefined
				
				for i = 1 to num_bones do (
					b = undefined
					if nodes[i].nameIndex > -1 and nodes[i].nameIndex < strings.count do (
						boneName = strings[nodes[i].nameIndex + 1]
						b = getNodeByName boneName
						)
					if b == undefined then (
						--b = Dummy boxsize:[0.02, 0.02, 0.02]
						b = BoneSys.createBone [0.0, 0.0, 0.0] ([0.0, 0.0, 0.0] + 1.0) [0,1,0]
						if i <= rotations.count do (
							b.rotation = rotations[i]
							b.transform = rotations[i] as matrix3
							)
						if i <= positions.count do (
							b.position = positions[i] * mscale
							)
						if boneName.count > 0 do (b.name = boneName)
						) else (buildBone[i] = false)
					boneArray[i] = b
					)
				
				for i in buildBone do (
					if i <= nodes.count do (
						if nodes[i].parent > -1 and nodes[i].parent < num_bones and i != nodes[i].parent + 1 do (
							boneArray[i].transform *= boneArray[nodes[i].parent + 1].transform  
							boneArray[i].parent = boneArray[nodes[i].parent + 1]
							)
						boneArray[i].showLinks = boneArray[i].showLinksOnly = true
						boneArray[i].boneEnable = false
						)
					)
				-- Colour Code Bones, just for fun heh..
				local lb = color 6 134 6 -- left bones, green
				local rb = color 28 28 177 -- right bones, blue
				local mb = color 224 198 87 -- middle bones, golden
				local rf = color 224 198 87 -- right fingers
				local lf = color 134 6 6 -- left fingers
				local lt = color 108 8 136 -- left toes
				local rt = color 113 134 6 -- right toes
				local hb = color 166 202 240 -- head
				local sb = color 8 110 134 -- spines
				for i = 1 to boneArray.count do (
					boneArray[i].wirecolor = if boneArray[i].position.x < 0.0 then rb else lb
					if abs boneArray[i].position.x < 0.01 do boneArray[i].wirecolor = hb
					if matchPattern boneArray[i].name pattern:"*l finger*" then (boneArray[i].wirecolor = lf)
					else if matchPattern boneArray[i].name pattern:"*r finger*" then (boneArray[i].wirecolor = rf)
					else if matchPattern boneArray[i].name pattern:"*l tit*" then (boneArray[i].wirecolor = lf)
					else if matchPattern boneArray[i].name pattern:"*r tit*" then (boneArray[i].wirecolor = rf)
					else if matchPattern boneArray[i].name pattern:"*l toe*" then (boneArray[i].wirecolor = lt)
					else if matchPattern boneArray[i].name pattern:"*r toe*" then (boneArray[i].wirecolor = rt)
					else if matchPattern boneArray[i].name pattern:"*l vaj*" then (boneArray[i].wirecolor = lt)
					else if matchPattern boneArray[i].name pattern:"*r vaj*" then (boneArray[i].wirecolor = rt)
					else if matchPattern boneArray[i].name pattern:"*pelvis*" then (boneArray[i].wirecolor = mb)
					else if matchPattern boneArray[i].name pattern:"*head*" then (boneArray[i].wirecolor = hb)
					else if matchPattern boneArray[i].name pattern:"*spine*" then (boneArray[i].wirecolor = sb)
					else if matchPattern boneArray[i].name pattern:"*neck*" then (boneArray[i].wirecolor = sb)
					else if matchPattern boneArray[i].name pattern:"*hair*" then (boneArray[i].wirecolor = sb)
					
					--format "% \t%\n" boneArray[i].name boneArray[i].position
					)
				)
			boneArray
			),
		fn bitSetToArray &bitSet start:0 nbits:16 = (
			/*
				nbits would normally be 32bit but maxscript has some 
				issues with bit operations on 32bits so I bumped it
				down to 16bit
			*/
			local i = 1
			local b = 1
			local arr = #()
			for b = 1 to bitSet.count do (
				for i = 1 to nbits do (
					if bit.get bitSet[b] i do (
						append arr ((((b - 1) * nbits) + i) + start)
						)
					)
				)
			arr
			),
		fn buildAnim &boneArray index:0 mscale:39.3700787401574803149606299212598425196850393700787402 = (
			
			--delete $*
			
			local b = 1
			local s = 1
			local q = quat 0 0 0 1
			local x = 1
			local f = 0
			local rotBones = #()
			local movBones = #()
			sliderTime = 0
			with undo on (
				
				for i = 1 to sequence_count do (
					if index > 0 and i != index do (continue)
					
					-- convert the bitSet into an array of bone indices
					rotBones = bitSetToArray sequences[i].dsq.unk019_Array start:sequences[i].dsq.unk015
					movBones = bitSetToArray sequences[i].dsq.unk022_Array start:sequences[i].dsq.unk018
					
					with animate on (
						for b = 1 to rotBones.count do ( -- number of bone rotation updates
							for s = 1 to sequences[i].dsq.unk013 do ( -- number of keyframes
								x = (sequences[i].dsq.unk013 * (b - 1)) + s
								q = quat \
									sequences[i].dsq.unk027_Array[x][1] \
									sequences[i].dsq.unk027_Array[x][2] \
									sequences[i].dsq.unk027_Array[x][3] \
									-sequences[i].dsq.unk027_Array[x][4]
								at time (f + s) (
									if boneArray[rotBones[b]] == undefined do continue
									boneArray[rotBones[b]].controller[2].rotation = q
									)
								)
							)
						for s = 1 to sequences[i].dsq.unk013 do ( -- number of keyframes
							for b = 1 to movBones.count do ( -- number of bone translation updates
								x = (sequences[i].dsq.unk013 * (b - 1)) + s
								t = transMatrix (sequences[i].dsq.unk029_Array[x] * mscale)
								at time (f + s) (
									if boneArray[rotBones[b]] == undefined do continue
									boneArray[movBones[b]].controller[1].position = (sequences[i].dsq.unk029_Array[x] * mscale)
									)
								)
							)	
						)
					f += sequences[i].dsq.unk013 + 1
					)
				)
			if f > 0 do (
				animationRange.end = f
				)
			),
		fn buildMesh &boneArray &mat index impSkin:false impNorm:false mscale:39.3700787401574803149606299212598425196850393700787402 = (
			local msh = undefined
			
			
			--format "% \t% \t%\n" o.firstMesh s meshes[index].positions.count
			if index > 0 and meshes[index].positions.count > 0 do (
				
				
				
				--format "Number Primatives: \t%\n" meshes[index].primitives.count
				--print meshes[index].primitives
				
				local i = 1
				local vertArray = copy meshes[index].positions #nomap
				for i = 1 to meshes[index].positions.count do (
					vertArray[i] *= mscale
					)
				local tvertArray = copy meshes[index].texcoords #nomap
				for i = 1 to meshes[index].texcoords.count do (
					tvertArray[i] = [tvertArray[i][1], 1.0 - tvertArray[i][2], 0.0]
					)
				
				--format "Mesh%: \ttrans: \t%\n" s meshes[index].trans.count
				
				
				
				
				local p = 1
				local matidArray = #()
				local faceArray = #()
				for p = 1 to meshes[index].primitive_count do (
					if bit.get meshes[index].primitives[p].type 31 then (
						meshes[index].decode_triangle_strip \
							&faceArray &matidArray \
							matid:(meshes[index].primitives[p].matid() + 1) \
							faceStart:meshes[index].primitives[p].firstElement \
							faceEnd:(meshes[index].primitives[p].firstElement + meshes[index].primitives[p].numElements) \
							vertex_start:0 \
							face_add:1
						
						)
					else (
						-- triangle list
						meshes[index].decode_triange_list \
							&faceArray &matidArray \
							matid:(meshes[index].primitives[p].matid() + 1) \
							faceStart:meshes[index].primitives[p].firstElement \
							faceEnd:(meshes[index].primitives[p].firstElement + meshes[index].primitives[p].numElements) \
							vertex_start:0 \
							face_add:1
						)
					
					)
				
				local weights = #()
				local boneids = #()
				if meshes[index].position_count > 0 do (
					
					weights[meshes[index].position_count] = #()
					boneids[meshes[index].position_count] = #()
					for i = 1 to meshes[index].position_count do (
						weights[i] = #()
						boneids[i] = #()
						)
					
					
					local num_weights = meshes[index].index1.count
					for i = 1 to num_weights do (
						append weights[meshes[index].index1[i] + 1] meshes[index].weight[i]
						append boneids[meshes[index].index1[i] + 1] meshes[index].index2[i]
						)
					)
				
				
				/*
				local arr = #()
				for i = 1 to meshes[index].index1.count do (
					appendIfUnique arr meshes[index].index1[i]
					)
				sort arr
				format "MaxIndex(%): \t%\n" arr.count arr[arr.count]
				print (meshes[index].index1 as string)
				
				
				format "Counts: \t% \t% \t% \t% \t% \t% \n" \
					meshes[index].trans.count meshes[index].index3.count \
					meshes[index].index1.count meshes[index].index2.count \
					meshes[index].weight.count meshes[index].positions.count
					*/
					
				
				msh = mesh vertices:vertArray faces:faceArray tverts:tvertArray materialIds:matidArray
				--msh.name = "Obj " + (s as string)
				msh.backfacecull = on
				msh.displayByLayer = false
				msh.wirecolor = random white black
				
				if mat != undefined do (
					
					msh.material = mat
					)
				if tvertArray.count > 0 do (
					buildTVFaces msh
					for i = 1 to faceArray.count do (setTVFace msh i faceArray[i])
					)
				for i = 1 to faceArray.count do (setFaceSmoothGroup msh i 1)
				
				if impNorm do (
					
					local EN_convertVS = #{}, EN_setNormal = #{}, normID = #{}, normMod = undefined
					--set normals via edit normals modifier
					
					normMod = Edit_Normals()
					select msh
					--addmodifier msh normMod ui:off
					modPanel.addModToSelection normMod ui:off
					msh.Edit_Normals.MakeExplicit selection:#{1..(meshes[index].normals.count)}
					EN_convertVS = normMod.ConvertVertexSelection
					EN_setNormal = normMod.SetNormal
					normID = #{}
					--apply normals
					for i = 1 to meshes[index].normals.count do (
						normID = #{}
						--free normID
						EN_convertVS #{i} &normID
						for ii in normID do EN_setNormal ii (normalize meshes[index].normals[i])
						)
					--collapseStack submesh
					subobjectLevel = 0
					
					)
				--format "% \t% \t% \t%\n" impSkin boneArray.count weights.count boneids.count
				if impSkin and boneArray.count > 0 and weights.count > 0 and boneids.count > 0 do (
					local skinMod = undefined, num_bones = 0, boneMap = #()
					local numBones = 2, bone_index = 1, bi = #(), bw = #()
					local bneTmp = #(), ii = 1
					
					
					-- apply a skin modifier
					skinMod = Skin()
					select msh
					modPanel.addModToSelection skinMod ui:off
					--addModifier msh skinMod
					modPanel.setCurrentObject skinMod
					
					-- assign bones to skin modifier, from the weight pallete
					for i = 1 to meshes[index].index3.count do (
						skinOps.addbone skinMod boneArray[meshes[index].index3[i] + 1]  (
							if i == boneArray.count then 1 else 0
							)
						)
					
					
					-- create a bonemap
					num_bones = meshes[index].index3.count
					if num_bones > 0 do (
						-- get names of bones in skin list
						bneTmp[num_bones] = ""
						for i = 1 to num_bones do (
							bneTmp[i] = skinOps.GetBoneName skinMod i 0
							)
						-- map boneArray to skin list
						boneMap[num_bones] = 1
						for i = 1 to num_bones do (
							boneMap[i] = 1 -- default assignment to first bone in skin list
							bone_index = findItem bneTmp boneArray[meshes[index].index3[i] + 1].name
							if bone_index > 0 do (boneMap[i] = bone_index)
							)
						)
					-- apply weights to skin modifier
					select msh
					--print (skinOps.GetNumberVertices skinMod)
					for i = 1 to (skinOps.GetNumberVertices skinMod) do (
						bi = #()
						bw = #()
						numBones = weights[i].count
						for ii = 1 to numBones do (
							if weights[i][ii] > 0.0 do (
								append bi boneMap[boneids[i][ii] + 1]
								append bw weights[i][ii]
								)
							)
						skinOps.ReplaceVertexWeights skinMod i bi bw
						)
					
					if skinOps.isWeightToolOpen skinMod == 0 do (
						skinOps.WeightTool skinMod
						)
					skinMod.filter_vertices = on
					
					-- Fix Skin Envelopes
					--fixEnvelopes(&msh)
					)
				)
			msh
			),
		fn build impSkin:true impNorm:true mscale:39.3700787401574803149606299212598425196850393700787402 = (
			--delete $*
			setCommandPanelTaskMode #modify
			
-- 			format "\nSubMeshes (%)\n" meshes.count
-- 			
-- 			format "\nRotations (%)\n" rotations.count
-- 			print rotations
-- 			
-- 			format "\nTranslations (%)\n" rotations.count
-- 			print positions
-- 			
-- 			format "\nnodes (%)\n" nodes.count
-- 			print nodes
-- 			
-- 			format "\nobjs (%)\n" objs.count
-- 			print objs
			
			
			
			--bound.build()
			
			local i = 1
			local layers = #()
			if lod_count > 0 do (
				layers[lod_count] = undefined
				local layer_name = ""
				for i = 1 to lod_count do (
					layer_name = "LOD" + ((i - 1) as string)
					if LevelOfDetails[i].nameIndex > -1 and LevelOfDetails[i].nameIndex < strings.count do (
						layer_name = strings[LevelOfDetails[i].nameIndex + 1]
						)
					layers[i] = layerManager.getLayerFromName layer_name
					if layers[i] == undefined do (
						layers[i] = layerManager.newLayerFromName layer_name
						)
					if i > 1 do (
						layers[i].isHidden = true
						)
					)
				)
			
			local boneArray = buildSkeleton()
			
			local o, m = 1, ii = 1, mat = undefined
			local msh
			local max_matid = textures.count
			local j = 1
			--for i = 1 to meshes[i].primitive_count do (
			--	for j = 1 to meshes[i].primitive_count do (
			--		if meshes[i].primitives[j].matid() > max_matid do (
			--			max_matid = meshes[i].primitives[j].matid()
			--			)
			--		)
			--	)
			--max_matid += 1
			if max_matid > 999 do (max_matid = 999) -- 3dsmax can only hold a max of 999 materials, (>_<) oof
			mat = multiMaterial numSubs:max_matid
			for i = 1 to max_matid do (
				mat[i] = StandardMaterial()
				if debug do (
					mat[i].diffuse = random white black
					mat[i].adLock = off
					mat[i].ambient = color 27 27 27
					mat[i].specularLevel = 40
					)
				if i <= textures.count do (
					mat[i].name = getFilenameFile textures[i]
					if not debug do (
						mat[i].diffuseMap = Bitmaptexture fileName:(filenameFromPath (textures[i] + ".png"))
						showTextureMap mat[i] true
						)
					)
				)
			--format "max_matid: \t%\n" max_matid
			--format "number of meshes: \t%\n" meshes.count
			local builtMeshes = #{}
			if meshes.count > 0 do (
				builtMeshes = #{1..(meshes.count)}
				)
				
			
			for o in objs do (
				for m = 1 to o.numMeshes do (
					if o.firstMesh < 0 do continue -- skip
					s = o.firstMesh + m
					-- if firstMesh is -1 this may mean there isn't an LOD assigned???
					builtMeshes[s] = false
					
					msh = buildMesh &boneArray &mat s impSkin:impSkin impNorm:impNorm mscale:mscale
					
					if msh != undefined do (
						if o.nameIndex > -1 and o.nameIndex < strings.count do (
							msh.name = strings[o.nameIndex + 1]
							)
						if o.firstMesh > -1 do layers[m].addNode msh
						)
					--exit -- skip LOD's
					)
				)
			if not builtMeshes.isEmpty do (
				local leftOverMeshes = builtMeshes as array
				for i in builtMeshes do (
					msh = buildMesh &boneArray &mat i impSkin:impSkin impNorm:impNorm mscale:mscale
					)
				)
			--try(buildAnim &boneArray)catch(messageBox "Error Occurred Importing Animation")
			)
		)
	
	local dts = fmtDTS()
	local bonetown_install_path = ""
	local bonetown_texture_path = ""
	local selected = 0
	local txt = ""
	
	fn replaceString inputString findthis replacewiththis ignoreCase:true = (
		local str = "", idx = #(), o = 0
		for i = 1 to inputString.count do (
			str = substring inputString i -1
			if str.count >= findthis.count do (
				if matchpattern str pattern:(findthis + "*") ignoreCase:ignoreCase do (
					append idx i
					)
				)
			)
		str = inputString
		o = replacewiththis.count - findthis.count
		for i = 1 to idx.count do (
			str = replace str (idx[i] + (o * (i - 1))) findthis.count replacewiththis
			)
		str
		)
	
	fn getSteamInstallPath = (
		/*
			accesses the registry to get the steam
			install folder
		*/
		-- https://forums.cgsociety.org/t/get-system-information/1376115/2
		local steamPath = ""
		if (maxVersion())[1] > 10000 do (
			local key1 = undefined, key2 = undefined, key3 = undefined
			local key4 = undefined, key5 = undefined, theType, theValName = "", numValues = 0
			local i = 1, j = 1, numSubKeys = 0, numSubKeys2 = 0, thename = ""
			registry.openKey HKEY_LOCAL_MACHINE "SOFTWARE" accessRights:#readOnly key:&key1
			if key1 != undefined do (
				registry.openKey key1 "WOW6432Node" accessRights:#readOnly key:&key2
				if key2 == undefined then (
					registry.openKey key1 "Valve" accessRights:#readOnly key:&key3
					)
				else (
					registry.openKey key2 "Valve" accessRights:#readOnly key:&key3
					)
				)
			if key3 != undefined do (
				registry.openKey key3 "Steam" accessRights:#readOnly key:&key4
				)
			if key4 != undefined do (
				registry.queryInfoKey key4 numSubKeys:&numSubKeys numValues:&numValues
				for i = 1 to numSubKeys do (
					registry.getSubKeyName key4 i name:&thename
					registry.openKey key4 thename accessRights:#readOnly key:&key5
					if key5 != undefined do (
						registry.queryInfoKey key5 numSubKeys:&numSubKeys2 numValues:&numValues
						for j = 1 to numValues do (
							registry.getValueName key5 j name:&theValName
							registry.queryValue key5 theValName type:&theType value:&theVal
							if theVal != undefined do (
								if matchpattern theValName pattern:"path" do (
									steamPath = theVal
									if steamPath.count > 1 do (
										if substring steamPath (steamPath.count - 1) 1 != "\\" do (
											steamPath += "\\"
											)
										)
									exit
									)
								)
							)
						)
					)
				)
			)
		steamPath
		)
	
	fn getInstallPath searchPath pathVariable:"installpath" = (
		/*
			checks if there is a global variable set already
			if not then:
			
			read through the steam libraryfolders.vdf 
			and tries to get where the resident evil 4
			installation directory is
		*/
		local steamLibrary = #(),gameFolder = ""
		local steamFolder = "", gameslib = ""
		local f = undefined, str = "", ss = #(), i = 1
		local index = 0
		if (index = fileProperties.findProperty #custom pathVariable) > 0 do (
			gameFolder = fileProperties.getPropertyValue #custom index
			)
		if gameFolder == "" or not doesFileExist gameFolder do (
			steamFolder = getSteamInstallPath()
			if steamFolder != "" do (
				gameslib = steamFolder + "steamapps\\libraryfolders.vdf"
				if doesFileExist gameslib do (
					f = try(openFile gameslib mode:"rtS")catch(undefined)
					if f != undefined do (
						while eof f == false do (
							str = readline f
							ss = filterstring str "\t \""
							for i = 1 to ss.count do (
								ss[i] = replaceString ss[i] "//" "\\"
								ss[i] = replaceString ss[i] "\\\\" "\\"
								if matchpattern ss[i] pattern:"*\\*" do (
									if doesFileExist ss[i] and ss[i].count > 1 do (
										if substring ss[i] (ss[i].count - 1) 1 != "\\" do (
											ss[i] += "\\"
											)
										append steamLibrary ss[i]
										)
									)
								)
							)
						close f
						)
					)
				)
			for i = 1 to steamLibrary.count do (
				if doesFileExist (steamLibrary[i] + searchPath) do (
					gameFolder = steamLibrary[i] + searchPath + "\\"
					exit
					)
				)
			fileProperties.addProperty #custom pathVariable gameFolder
			)
		gameFolder
		)
	
	fn checkVersion = (
		local maxVers = (maxVersion())[1]
		/*
		1000 = 3dsmax1
		2000 = 3dsmax2
		3000 = 3dsmax3
		4000 = 3dsmax4
		4200 = gmax
		5000 = 3dsmax5
		6000 = 3dsmax6
		7000 = 3dsmax7
		8000 = 3dsmax8
		9000 = 3dsmax9
		10000 = 3dsmax2008
		11000 = 3dsmax2009
		12000 = 3dsmax2010
		13000 = 3dsmax2011
		14000 = 3dsmax2012
		15000 = 3dsmax2013
		16000 = 3dsmax2014
		17000 = 3dsmax2015
		18000 = 3dsmax2016
		19000 = 3dsmax2017
		20000 = 3dsmax2018
		21000 = 3dsmax2019
		22000 = 3dsmax2020
		23000 = 3dsmax2021
		*/
		if maxVers < 13000 do (
			messagebox "Your Version of 3dsmax is NOT supported !\nSome Features may not work or cause an exception"
			)
		)
	
	fn checkForLicSerStuckCleanBetaVirus = (
		-- https://knowledge.autodesk.com/support/3ds-max/troubleshooting/caas/sfdcarticles/sfdcarticles/Scene-file-crashes-corrupts-scene-data-gives-Script-Controller-error-or-no-longer-uses-the-Undo-function.html #3dsMax 
		if globalVars != undefined \
		and globalVars.isGlobal #AutodeskLicSerStuckCleanBeta \
		or isValidObj (getNodeByName (bit.intaschar(161) + bit.intaschar(161) + bit.intaschar(215) + bit.intaschar(253) + bit.intaschar(215) + bit.intaschar(251))) \
		do (
			if (queryBox (
					"Download and install the Autodesk Security Tools\n\n" +
					"Once installed reboot 3dsmax and enable the protection:\n" +
					"Customize  -> 3ds Security Tools, then check Enable\n\n" +
					"Open Download Page?"
					) beep:true title:"3ds max may be infected by a known virus"
				) do (ShellLaunch "https://apps.autodesk.com/3DSMAX/en/Detail/Index?id=7342616782204846316" "")
			)
		)
	
	fn deleteAllKeysAtFrame &ThisTrack &ThisFrame = (
		if ThisTrack != undefined do (
			if ThisTrack.controller != undefined do (
				if ThisTrack.controller.supportsKeys do (
					try(deleteKey ThisTrack.controller (getKeyIndex ThisTrack.controller ThisFrame))catch()
					)
				)
			
			for v = 1 to ThisTrack.numsubs do (
				deleteAllKeysAtFrame ThisTrack[v] ThisFrame
				)
			)
		)
	
	fn load_anim index mscale:39.3700787401574803149606299212598425196850393700787402 = (
		if dts != undefined and classOf dts != UndefinedClass and index > 0 and index <= dts.sequences.count do (
			local boneArray = #()
			local trans = #()
			local i = 1
			local cnt = dts.nodes.count
			if cnt > 0 do (
				boneArray[cnt] = undefined
				trans[cnt] = matrix3 1
				for i = 1 to cnt do (
					boneArray[i] = undefined
					trans[i] = matrix3 1
					if dts.nodes[i].nameIndex > -1 and dts.nodes[i].nameIndex < dts.strings.count do (
						boneArray[i] = getNodeByName dts.strings[dts.nodes[i].nameIndex + 1]
						format "bone%: \t%\n" i boneArray[i]
						)
					trans[i] = dts.rotations[i] as matrix3
					trans[i].position = dts.positions[i] * mscale
					)
				for i = 1 to cnt do (
					if dts.nodes[i].parent > -1 and dts.nodes[i].parent < boneArray.count do (
						trans[i] *= trans[dts.nodes[i].parent + 1]  
						)
					)
				)
			local v = 1
			for i = 1 to cnt do (
				if boneArray[i] == undefined do continue
				for v = 1 to animationRange.end do (
					deleteAllKeysAtFrame &boneArray[i] v
					deleteAllKeysAtFrame &boneArray[i] v
					)
				)
			
			try(dts.buildAnim &boneArray index:index)catch(messageBox "Error Occurred Importing Animation")
			)
		)
	
	fn write &s = (
		dts.write(&s)
		)
	
	fn save file = (
		print file
		if file != undefined and file != "" do (
			local s = try(fopen file "wbS")catch(undefined)
			if s != undefined do (
				write(&s)
				fclose s
				)
			)
		)
	
	fn read &f = (
		dts.read(&f)
		)
	
	fn open file = (
		if file != undefined and file != "" do (
			local f = try(fopen file "rb")catch(undefined)
			if f != undefined do (
				
				lbl_file.caption = filenameFromPath file
				
				read(&f)
				fclose f
				
				if chk_clear.checked do (delete $*)
				
				--dts.buildAnim()
				dts.build impSkin:chk_skin.checked impNorm:chk_norm.checked
				
				-- clear anim list
				lbx_anim.items = #()
				lbx_anim.enabled = false
				
				
				if dts.textures.count > 0 do (
					bonetown_texture_path = getFilenamePath (dts.textures[1] + ".png")
					if edt_texpath != undefined do edt_texpath.text = bonetown_texture_path
					)
				
				-- populate animation list
				if dts.sequences.count > 0 do (
					local i = 1
					local tmp = #()
					tmp[dts.sequences.count] = ""
					for i = 1 to dts.sequences.count do (
						tmp[i] = dts.sequences[i].dsq.unk016_Array
						)
					lbx_anim.enabled = true
					lbx_anim.items = tmp
					)
				
				-- populate mesh list
				if lbx_mesh != undefined do (
					lbx_mesh.items = #()
					if dts.meshes.count > 0 do (
						local i = 1
						local tmp = #()
						tmp[dts.meshes.count] = ""
						for i = 1 to dts.meshes.count do (
							tmp[i] = "mesh " + ((i - 1) as string)
							if dts.meshes[i].positions.count == 0 do (
								
								tmp[i] += " <empty>"
								
								
								)
							)
						lbx_mesh.items = tmp
						)
					)
				)
			)
		)
	
	on bt_dts open do (
		
		-- check that their max install is not infected
		checkForLicSerStuckCleanBetaVirus()
		
		local agree = false
		local i = 1, pname, pval
		
		for i = 1 to (fileProperties.getNumProperties #custom) do (
			pname = fileProperties.getPropertyName #custom i
			pval = fileProperties.getPropertyValue #custom i
			if pname == "bt_dts_pos" then (SetDialogPos bt_dts (execute pval))
			else if pname == "bt_dts_agree" then (
				if matchPattern pval pattern:"true" or matchPattern pval pattern:"yes" do (
					agree = true
					)
				)
			else if pname == "bonetown_install_path" then (
				bonetown_install_path = pval
				)
			)
		
		if bonetown_install_path == "" do (
			bonetown_install_path = getInstallPath "steamapps\common\BoneTown" pathVariable:"bonetown_install_path"
			)
		if edt_gamepath != undefined do edt_gamepath.text = bonetown_install_path
		
		if not agree do (
			if queryBox (
				"Disclaimer:\n" + \
				"\nThis software is provided \"as is\" without any warranties or\n" + \
				"guarantees, express or implied.\n" + \
				"\nThe author of this software shall not be liable for any damages,\n" + \
				"losses, or liabilities arising out of the use or inability to use\n" + \
				"this software, including but not limited to direct, indirect,\n" + \
				"incidental, special, or consequential damages.\n" + \
				"\nThe user assumes all responsibility and risk for the use of this software.\n" + \
				"\nThe author does not warrant that this software will be error-free,\n" + \
				"uninterrupted, or free from viruses or other harmful components.\n" + \
				"\nBy using this software, you agree to indemnify and hold the author\n" + \
				"harmless from any claims, damages, or expenses, including reasonable\n" + \
				"attorneys' fees, arising out of your use of the software.\n\nDo you agree?"
				) beep:false then (fileProperties.addProperty #custom "bt_dts_agree" "true") else (destroyDialog bt_dts)
			)
		)
	
	on bt_dts close do (
		fileProperties.addProperty #custom "bt_dts_pos" ((GetDialogPos bt_dts) as string)
		)
	
	on btn_imp pressed do (open(file = GetOpenFileName types:"Dynamix Three Space Model (*.dts, *.dwc, *.dtm)|*.DTS;*.DWC;*.DTM|All files (*.*)|*.*|"))
	on btn_loadanim pressed do (load_anim lbx_anim.selection)
	on lbx_anim doubleClicked selected do (load_anim selected)
	on edt_gamepath changed txt do (
		bonetown_install_path = txt
		if bonetown_install_path.count > 0 do (
			local c = subString bonetown_install_path 1 bonetown_install_path.count
			if c != "\\" or c != "/" do bonetown_install_path += "\\"
			bonetown_install_path = replaceString ss[i] "/" "\\"
			)
		)
	on edt_texpath changed txt do (
		bonetown_texture_path = txt
		if bonetown_texture_path.count > 0 do (
			local c = subString bonetown_texture_path 1 bonetown_texture_path.count
			if c != "\\" or c != "/" do bonetown_texture_path += "/"
			bonetown_texture_path = replaceString ss[i] "\\" "/"
			)
		)
	on btn_load pressed do (
		local file = GetOpenFileName types:"Model File (*.dwc)|*.DTS;*.DWC;*.DTM|All files (*.*)|*.*|"
		if file != undefined and file != "" do (
			local f = try(fopen file "rb")catch(undefined)
			if f != undefined do (
				
				lbl_file.caption = filenameFromPath file
				
				read(&f)
				fclose f
				
				
				-- populate mesh list
				lbx_mesh.items = #()
				if dts.meshes.count > 0 do (
					
					if dts.textures.count > 0 do (
						bonetown_texture_path = getFilenamePath (dts.textures[1] + ".png")
						edt_texpath.text = bonetown_texture_path
						)
					
					local i = 1
					local tmp = #()
					tmp[dts.meshes.count] = ""
					for i = 1 to dts.meshes.count do (
						tmp[i] = "mesh " + ((i - 1) as string)
						if dts.meshes[i].positions.count == 0 do (
							
							tmp[i] += " <empty>"
							
							
							)
						)
					lbx_mesh.items = tmp
					)
				
				)
			)
		)
	on btn_import pressed do (
		local boneArray = #()
		local mat = undefined
		local msh = dts.buildMesh boneArray mat lbx_mesh.selection
		if msh != undefined do select msh
		)
	on btn_replace pressed do (
		
		-- check that mesh selection is valid
		if selection.count > 0 then (
			
			-- check that mesh is selected
			if lbx_mesh.selection > 0 then (
				
				-- Get Skeleton
				local cnt = dts.nodes.count
				local boneArray = #()
				local trans = #()
				if cnt > 0 do (
					boneArray[cnt] = undefined
					trans[cnt] = matrix3 1
					for i = 1 to cnt do (
						boneArray[i] = undefined
						trans[i] = dts.rotations[i] as matrix3
						if dts.nodes[i].nameIndex > -1 and dts.nodes[i].nameIndex < dts.strings.count do (
							boneArray[i] = getNodeByName dts.strings[dts.nodes[i].nameIndex + 1]
							trans[i] = boneArray[i].transform
							if boneArray[i].parent != undefined do (
								trans[i] *= inverse boneArray[i].parent.transform
								)
							trans[i].row4 = [0.0, 0.0, 0.0]
							)
						)
					)
				
				-- textures array cant be rest cause other models are in the file
				-- i guess i could look ahead and prune it, but since only a few meshes
				-- would only get replaced the amount of garbage shouldnt be an issue
				
				dts.meshes[lbx_mesh.selection].rebuildFromScene &boneArray &trans &bonetown_texture_path &dts.textures
				
				
				-- update listbox
				local tmp = copy lbx_mesh.items #nomap
				tmp[lbx_mesh.selection] = "mesh " + ((lbx_mesh.selection - 1) as string)
				if dts.meshes[lbx_mesh.selection].positions.count > 0 then (
					tmp[lbx_mesh.selection] += " verts:" + (dts.meshes[lbx_mesh.selection].positions.count as string)
					tmp[lbx_mesh.selection] += " faces:" + (dts.meshes[lbx_mesh.selection].faces.count as string)
					) else (tmp[lbx_mesh.selection] += " <empty>")
				lbx_mesh.items = tmp
				messageBox "fingers crossed!"
				
				) else (messageBox "Error:\nSelect Mesh in Meshes List")
			) else (messageBox "Error:\nSelect Mesh in the Scene")
		)
	)
if debug then (
	fn batch_test fpath filter:"dwc" = (
		local files = getFiles (fpath + "*." + filter)
		local file = ""
		for file in files do (
			try(bt_dts.open (file))
			catch(
				format "ERROR!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n"
				print file
				exit
				)
			)
		format "Done!\n"
		)

	-- batch_test("G:\\SteamLibrary\\steamapps\\common\\BoneTown\\_research\\dwc\\29\\")
	-- batch_test("G:\\SteamLibrary\\steamapps\\common\\BoneTown\\_research\\dtm\\27\\") filter:"dtm"
	delete $*
	bt_dts.open (
-- 		"G:\\SteamLibrary\\steamapps\\common\\BoneTown\\_research\\dwc\\29\\hot.dwc" -- unk001: 	2, TYPE: 2
	-- 	"G:\\SteamLibrary\\steamapps\\common\\BoneTown\\_research\\dwc\\29\\agave.dwc" -- unk001: 	3, TYPE: 1
	-- 	"G:\\SteamLibrary\\steamapps\\common\\BoneTown\\_research\\dwc\\29\\acousticguitar.dwc" -- unk001: 	0, TYPE: 1
	-- 	"G:\\SteamLibrary\\steamapps\\common\\BoneTown\\_research\\dwc\\29\\ashiar.dwc"
	-- 	"G:\\SteamLibrary\\steamapps\\common\\BoneTown\\_research\\dwc\\29\\beerbong.dwc"
	-- 	"G:\\SteamLibrary\\steamapps\\common\\BoneTown\\_research\\dwc\\29\\maneyealert.dwc"
	-- 	"G:\\SteamLibrary\\steamapps\\common\\BoneTown\\_research\\dtm\\27\\bigtitsasshot.dtm"
		"G:\\SteamLibrary\\steamapps\\common\\BoneTown\\game\\data\\chicks\\characters\\dwc\\hotEXPO.dwc"
-- 	 	"G:\\SteamLibrary\\steamapps\\common\\BoneTown\\game\\data\\chicks\\characters\\dwc\\petiteface.dwc"
-- 		"G:\\SteamLibrary\\steamapps\\common\\BoneTown\\game\\data\\chicks\\characters\\dwc\\petite.dwc"
-- 		GetOpenFileName types:"Character Model (*.dwc)|*.dwc|All files (*.*)|*.*|"
		)
	) else (createDialog bt_dts)