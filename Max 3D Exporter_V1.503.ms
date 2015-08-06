 ---------------------------------------
-- Need to add support for:
--		Single frame exports.
--		Compression of non-animated properties.
--			write every property for first frame.
--			skip any properties that are not animated for the frames that they are not animated.
--			check for a parent!
--		Lights.

/*
v1.5	re-wrote the exporter to ACTUALLY write out xml. Pshh...
	added some "compression" so that non-animated values are only written out for one frame, and animated values are truncated to first and last key
*/
---------------------------------------
try(closeRolloutFloater AEPositionExporter)catch()
(
	global frameRangeStart
	global frameRangeEnd
	global clipboardString
	global headderText
	global footerText
	global clipbpardString
	global theAnimatedObject
	global currentFrame
	global totalFrames
	global exportProgress
	global itemExportProgress
	global totalNumItems
	global selectedCamsArray = #()
	global selectedPointsArray = #()
	global fileName = ""
		
	theanimatedobject = "undefined"
	frameRangeStart = animationRange.start
	frameRangeEnd = animationRange.end
	clipboardString = "defined"
	xPosition = 1.000
	yPosition = 2.000
	zPosition = 3.000
	currentFrame = 0
	totalFrames = 100
	exportProgress = 0
	itemExportProgress = 0
	totalNumItems = 0
)

rollout ST_Max3dXmlExporter "ST_Max 3D XML Exporter" width:275 height:510
(
	label lbl3 "ST Max 3D XML Exporter" pos:[5,5] width:200 height:17
	
	groupBox camGroup "Camera Export" pos:[5,25] width:266 height:183
	listBox camListBox "Cameras" pos:[10,40] width:250 height:8
	button camAddSelectedBtn "Add Selected" pos:[10,175] width:160 height:24
	button camClearBtn "Clear" pos:[173,175] width:68 height:24
	button camSubBtn "-" pos:[244,175] width:16 height:24
	
	groupBox pointGroup "3D Point Export" pos:[5,215] width:266 height:183
	listBox pointListBox "Points" pos:[10,230] width:250 height:8
	button pointAddSelectedBtn "Add Selected" pos:[10,365] width:160 height:24
	button pointClearBtn "Clear" pos:[173,365] width:68 height:24
	button pointSubBtn "-" pos:[244,365] width:16 height:24
	
	groupBox frameRangeGroup "Frame Range" pos:[5,403] width:266 height:43
	spinner framesStartSpinner "" range:[0,99999,frameRangeStart] width:50 type:#integer pos: [10,420]
	spinner framesEndSpinner "To " range:[0,99999,frameRangeEnd] width:50 type:#integer pos: [75,420]
	button snapFrameRange "Snap to Timeline" pos:[135,418] width:125 height:20
	
	button exportBtn "Export XML" pos:[5,460] width:265 height:30
	progressbar exportProgressBar   pos: [5,492] width: 265 height:5 color:[26,181,30]
	progressbar itemProgressBar   pos: [5,498] width: 265 height:5 color:[180,140,25]
	

	
	----------------- EVENT LISTENERS -----------------

	on camAddSelectedBtn pressed do
	(
		if (selection.count == 1) then
		(
			if (SuperClassOf($) == Camera) then
			(
				appendIfUnique selectedCamsArray $.name
			) else
			(
				messageBox "Please select a camera."
			)
		) else (
			for i = 1 to $.count do
			(
				if (SuperClassOf($[i]) == Camera) then					-- this needs work!
				(
					appendIfUnique selectedCamsArray $[i].name
				) else (
					messageBox "One or more of the items you selected was not a camera and was not added to the list."
				)
			)
		)
		
		camListBox.items = selectedCamsArray
	)
	
	on camSubBtn pressed do
	(
		camListBox.items = deleteItem camListBox.items camListBox.selection
	)
	
	on camClearBtn pressed do
	(
		camListBox.items = #()
		selectedCamsArray = #()
	)
	
	on pointAddSelectedBtn pressed do
	(
		if (selection.count == 1) then
		(
			appendIfUnique selectedPointsArray $.name
		) else (
			for j = 1 to $.count do
			(
				appendIfUnique selectedPointsArray $[j].name
			)
		)
		
		pointListBox.items = selectedPointsArray
	)
	
	on pointSubBtn pressed do
	(
		pointListBox.items = deleteItem pointListBox.items pointListBox.selection
	)
	
	on pointClearBtn pressed do
	(
		pointListBox.items = #()
		selectedPointsArray = #()
	)
	
	on framesStartSpinner changed framesStartVal do
	(
		frameRangeStart = framesStartVal
			
		if (frameRangeStart >= frameRangeEnd) then
		(
		frameRangeEndUpdate = (frameRangeStart+1)
		frameRangeEnd = frameRangeEndUpdate
		framesEndSpinner.range = [0,99999,frameRangeEndUpdate]
		)
	)

	on framesEndSpinner changed framesEndVal do
	(
		frameRangeEnd = framesEndVal
			
		if (frameRangeStart >= frameRangeEnd) then
		(
		frameRangeStartUpdate = (frameRangeEnd-1)
		frameRangeStart = frameRangeStartUpdate
		framesStartSpinner.range = [0,99999,frameRangeStartUpdate]
		)
	)
	
	on snapFrameRange pressed do
	(
		framesStartSpinner.range = [0,99999,animationRange.start]
		framesEndSpinner.range = [0,99999,animationRange.end]
		frameRangeStart = animationRange.start
		frameRangeEnd = animationRange.end
	)
	
-------------------- When the export button is pressed! ----------------------
	on exportBtn pressed do
	(
		-- store these values because the variables are going to be written over later
		spinnerStartVal = frameRangeStart
		spinnerEndVal = frameRangeEnd

		-- FIRST LETS BUILD ARRAYS OF ALL OF THE OBJECTS TO EXPORT --
		camerasArray = #()
		for i = 1 to camListBox.items.count do
		(
			camItem = getnodebyname camListBox.items[i]
			append camerasArray camItem
		)
		
		pointsArray = #()
		for i = 1 to pointListBox.items.count do
		(
			pointItem = getnodebyname pointListBox.items[i]
			append pointsArray pointItem
		)
		
		------------------------ HERES THE EXPORT CODE! ------------------------
		fileName = getFilenamePath rendOutputFilename + getFilenameFile maxFileName + ".xml"
		saveXmlName = GetSaveFileName filename:fileName types:"XML(*.xml)"

		if saveXmlName != undefined then
		(
			oldSliderTime = sliderTime
			disableSceneRedraw()
			exportProgress = 0
			exportProgressBar.value = 0
			
			--lets kick off the XML file!
			dotNet.loadAssembly "system.xml"
			if (not getFilenameType saveXmlName == ".xml") do
			(
				saveXmlName += ".xml"
			)
			theXmlFile = dotNetObject "system.xml.xmlDocument"

			-- create the root
			xmlSceneNode = theXmlFile.createElement "scene"
			theXmlFile.appendChild xmlSceneNode

		------------------------| PROCESS THE CAMERAS

			-- create the "cameras" parent
			xmlCamerasNode = theXmlFile.createElement "cameras"
			xmlSceneNode.appendChild xmlCamerasNode

			for i = 1 to camerasArray.count do
			(
				currentCam = camerasArray[i]

				camName = currentCam.name
				camType = currentCam.type

				if (camType == #free) then
				(
					xmlCurrentCam = theXmlFile.createElement "camera"
					xmlCurrentCam.setAttribute "name" currentCam.name
					xmlCurrentCam.setAttribute "type" "Free"
					xmlCamerasNode.appendChild xmlCurrentCam

				-------------| Positions
					if currentCam.parent == undefined then
					(
						positionArray = currentCam.controller.position.controller.keys

						if (positionArray != undefined and positionArray.count != 0) then
						(
							frameRangeStart = positionArray[1].time
							frameRangeEnd = positionArray[positionArray.count].time

							if frameRangeStart < spinnerStartVal do
							(
								frameRangeStart = spinnerStartVal
							)

							if frameRangeEnd > spinnerEndVal do
							(
								frameRangeEnd = spinnerEndVal
							)
						) else (
							frameRangeStart = 0
							frameRangeEnd = 0
						)
					) else (
						frameRangeStart = spinnerStartVal
						frameRangeEnd = spinnerEndVal
					)

					currentFrame = frameRangeStart

					while (currentFrame <= frameRangeEnd) do
					(
						sliderTime = currentFrame

						xPosition = currentCam.pos.x
						yPosition = -currentCam.pos.z
						zPosition = currentCam.pos.y

						xmlCurrentPosition = theXmlFile.createElement "position"
						xmlCurrentPosition.setAttribute "frameNum" ((sliderTime.frame as integer) as string)
						xmlCurrentPosition.setAttribute "xPosition" (xPosition as string)
						xmlCurrentPosition.setAttribute "yPosition" (yPosition as string)
						xmlCurrentPosition.setAttribute "zPosition" (zPosition as string)
						xmlCurrentCam.appendChild xmlCurrentPosition

						currentFrame += 1
					)

				-------------| Rotations
					if currentCam.parent == undefined then
					(
						rotationArray = currentCam.controller.rotation.controller.keys

						if (rotationArray != undefined and rotationArray.count != 0) then
						(
							frameRangeStart = rotationArray[1].time
							frameRangeEnd = rotationArray[rotationArray.count].time

							if frameRangeStart < spinnerStartVal do
							(
								frameRangeStart = spinnerStartVal
							)

							if frameRangeEnd > spinnerEndVal do
							(
								frameRangeEnd = spinnerEndVal
							)
						) else (
							frameRangeStart = 0
							frameRangeEnd = 0
						)
					) else (
						frameRangeStart = spinnerStartVal
						frameRangeEnd = spinnerEndVal
					)

					currentFrame = frameRangeStart

					while (currentFrame <= frameRangeEnd) do
					(
						sliderTime = currentFrame

						xyzRotation = quatToEuler currentCam.rotation
						xRotation = (-xyzRotation.x) - 90
						yRotation = xyzRotation.y
						zRotation = xyzRotation.z

						xmlCurrentRotation = theXmlFile.createElement "rotation"
						xmlCurrentRotation.setAttribute "frameNum" ((sliderTime.frame as integer) as string)
						xmlCurrentRotation.setAttribute "xRotation" (xRotation as string)
						xmlCurrentRotation.setAttribute "yRotation" (yRotation as string)
						xmlCurrentRotation.setAttribute "zRotation" (zRotation as string)
						xmlCurrentCam.appendChild xmlCurrentRotation

						currentFrame += 1
					)

				-------------| FOV
					if (currentCam.fov.controller != undefined) do
					(
						fovArray = currentCam.fov.controller.keys
					)

					if (currentCam.fov.controller != undefined and fovArray.count != 0) then
					(
						frameRangeStart = fovArray[1].time
						frameRangeEnd = fovArray[fovArray.count].time

						if frameRangeStart < spinnerStartVal do
						(
							frameRangeStart = spinnerStartVal
						)

						if frameRangeEnd > spinnerEndVal do
						(
							frameRangeEnd = spinnerEndVal
						)
					) else (
						frameRangeStart = 0
						frameRangeEnd = 0
					)

					currentFrame = frameRangeStart

					while (currentFrame <= frameRangeEnd) do
					(
						sliderTime = currentFrame

						xmlCurrentFov = theXmlFile.createElement "lens"
						xmlCurrentFov.setAttribute "frameNum" ((sliderTime.frame as integer) as string)
						xmlCurrentFov.setAttribute "fov" (currentCam.fov as string)
						xmlCurrentCam.appendChild xmlCurrentFov

						currentFrame += 1
					)
				) else (
					-- targeted camera 	
					xmlCurrentCam = theXmlFile.createElement "camera"
					xmlCurrentCam.setAttribute "name" currentCam.name
					xmlCurrentCam.setAttribute "type" "Targeted"
					xmlCamerasNode.appendChild xmlCurrentCam

				-------------| Cam Positions
					if currentCam.parent == undefined then
					(
						positionArray = currentCam.controller.position.controller.keys

						if (positionArray != undefined and positionArray.count != 0) then
						(
							frameRangeStart = positionArray[1].time
							frameRangeEnd = positionArray[positionArray.count].time

							if frameRangeStart < spinnerStartVal do
							(
								frameRangeStart = spinnerStartVal
							)

							if frameRangeEnd > spinnerEndVal do
							(
								frameRangeEnd = spinnerEndVal
							)
						) else (
							frameRangeStart = 0
							frameRangeEnd = 0
						)
					) else (
						frameRangeStart = spinnerStartVal
						frameRangeEnd = spinnerEndVal
					)

					currentFrame = frameRangeStart

					while (currentFrame <= frameRangeEnd) do
					(
						sliderTime = currentFrame

						xPosition = currentCam.pos.x
						yPosition = -currentCam.pos.z
						zPosition = currentCam.pos.y

						xmlCurrentPosition = theXmlFile.createElement "camPosition"
						xmlCurrentPosition.setAttribute "frameNum" ((sliderTime.frame as integer) as string)
						xmlCurrentPosition.setAttribute "xPosition" (xPosition as string)
						xmlCurrentPosition.setAttribute "yPosition" (yPosition as string)
						xmlCurrentPosition.setAttribute "zPosition" (zPosition as string)
						xmlCurrentCam.appendChild xmlCurrentPosition

						currentFrame += 1
					)

				-------------| Target Positions
					if currentCam.target.parent == undefined then
					(
						positionArray = currentCam.target.controller.position.controller.keys

						if (positionArray != undefined and positionArray.count != 0) then
						(
							frameRangeStart = positionArray[1].time
							frameRangeEnd = positionArray[positionArray.count].time

							if frameRangeStart < spinnerStartVal do
							(
								frameRangeStart = spinnerStartVal
							)

							if frameRangeEnd > spinnerEndVal do
							(
								frameRangeEnd = spinnerEndVal
							)
						) else (
							frameRangeStart = 0
							frameRangeEnd = 0
						)
					) else (
						frameRangeStart = spinnerStartVal
						frameRangeEnd = spinnerEndVal
					)

					currentFrame = frameRangeStart

					while (currentFrame <= frameRangeEnd) do
					(
						sliderTime = currentFrame

						xPosition = currentCam.target.pos.x
						yPosition = -currentCam.target.pos.z
						zPosition = currentCam.target.pos.y

						xmlCurrentPosition = theXmlFile.createElement "targetPosition"
						xmlCurrentPosition.setAttribute "frameNum" ((sliderTime.frame as integer) as string)
						xmlCurrentPosition.setAttribute "xPosition" (xPosition as string)
						xmlCurrentPosition.setAttribute "yPosition" (yPosition as string)
						xmlCurrentPosition.setAttribute "zPosition" (zPosition as string)
						xmlCurrentCam.appendChild xmlCurrentPosition

						currentFrame += 1
					)

				-------------| Roll
					if currentCam.parent == undefined then
					(
						rollArray = currentCam.controller.roll_angle.keys

						if (rollArray != undefined and rollArray.count != 0) then
						(
							frameRangeStart = rollArray[1].time
							frameRangeEnd = rollArray[rollArray.count].time

							if frameRangeStart < spinnerStartVal do
							(
								frameRangeStart = spinnerStartVal
							)

							if frameRangeEnd > spinnerEndVal do
							(
								frameRangeEnd = spinnerEndVal
							)
						) else (
							frameRangeStart = 0
							frameRangeEnd = 0
						)
					) else (
						frameRangeStart = spinnerStartVal
						frameRangeEnd = spinnerEndVal
					)

					currentFrame = frameRangeStart

					while (currentFrame <= frameRangeEnd) do
					(
						sliderTime = currentFrame

						roll = -currentCam.controller.roll_angle

						xmlCurrentRoll = theXmlFile.createElement "roll"
						xmlCurrentRoll.setAttribute "frameNum" ((sliderTime.frame as integer) as string)
						xmlCurrentRoll.setAttribute "roll" (roll as string)
						xmlCurrentCam.appendChild xmlCurrentRoll

						currentFrame += 1
					)

				-------------| FOV
					if (currentCam.fov.controller != undefined) do
					(
						fovArray = currentCam.fov.controller.keys
					)

					if (currentCam.fov.controller != undefined and fovArray.count != 0) then
					(
						frameRangeStart = fovArray[1].time
						frameRangeEnd = fovArray[fovArray.count].time

						if frameRangeStart < spinnerStartVal do
						(
							frameRangeStart = spinnerStartVal
						)

						if frameRangeEnd > spinnerEndVal do
						(
							frameRangeEnd = spinnerEndVal
						)
					) else (
						frameRangeStart = 0
						frameRangeEnd = 0
					)

					currentFrame = frameRangeStart

					while (currentFrame <= frameRangeEnd) do
					(
						sliderTime = currentFrame

						xmlCurrentFov = theXmlFile.createElement "lens"
						xmlCurrentFov.setAttribute "frameNum" ((sliderTime.frame as integer) as string)
						xmlCurrentFov.setAttribute "fov" (currentCam.fov as string)
						xmlCurrentCam.appendChild xmlCurrentFov

						currentFrame += 1
					)
				)
			)

		------------------------| PROCESS THE POINTS
			-- create the "points" parent
			xmlPointsNode = theXmlFile.createElement "points"
			xmlSceneNode.appendChild xmlPointsNode

			for i = 1 to pointsArray.count do
			(
				currentPoint = pointsArray[i]

				xmlCurrentPoint = theXmlFile.createElement "point"
				xmlCurrentPoint.setAttribute "name" currentPoint.name
				xmlPointsNode.appendChild xmlCurrentPoint


			-------------| Positions
				if currentPoint.parent == undefined then
				(
					positionArray = currentPoint.controller.position.controller.keys

					if (positionArray != undefined and positionArray.count != 0) then
					(
						frameRangeStart = positionArray[1].time
						frameRangeEnd = positionArray[positionArray.count].time

						print ("spinnerStartVal: " + spinnerStartVal as string)
						print ("spinnerEndVal: " + spinnerEndVal as string)
						print ("frameRangeStart: " + frameRangeStart as string)
						print ("frameRangeEnd: " + frameRangeEnd as string)

						if frameRangeStart < spinnerStartVal do
						(
							frameRangeStart = spinnerStartVal
						)

						if frameRangeStart > spinnerEndVal do
						(
							frameRangeStart = spinnerEndVal
						)

						if frameRangeEnd > spinnerEndVal do
						(
							frameRangeEnd = spinnerEndVal
						)

						if frameRangeEnd < spinnerStartVal do
						(
							frameRangeEnd = spinnerStartVal
						)
					) else (
						frameRangeStart = spinnerStartVal
						frameRangeEnd = spinnerStartVal
					)
				) else (
					frameRangeStart = spinnerStartVal
					frameRangeEnd = spinnerEndVal
				)

				currentFrame = frameRangeStart

				while (currentFrame <= frameRangeEnd) do
				(
					sliderTime = currentFrame

					xPosition = currentPoint.pos.x
					yPosition = -currentPoint.pos.z
					zPosition = currentPoint.pos.y

					xmlCurrentPosition = theXmlFile.createElement "position"
					xmlCurrentPosition.setAttribute "frameNum" ((sliderTime.frame as integer) as string)
					xmlCurrentPosition.setAttribute "xPosition" (xPosition as string)
					xmlCurrentPosition.setAttribute "yPosition" (yPosition as string)
					xmlCurrentPosition.setAttribute "zPosition" (zPosition as string)
					xmlCurrentPoint.appendChild xmlCurrentPosition

					currentFrame += 1
				)

			-------------| Rotations
				if currentPoint.parent == undefined then
				(
					rotationArray = currentPoint.controller.rotation.controller.keys

					if (rotationArray != undefined and rotationArray.count != 0) then
					(
						frameRangeStart = rotationArray[1].time
						frameRangeEnd = rotationArray[rotationArray.count].time

						if frameRangeStart < spinnerStartVal do
						(
							frameRangeStart = spinnerStartVal
						)

						if frameRangeEnd > spinnerEndVal do
						(
							frameRangeEnd = spinnerEndVal
						)
					) else (
						frameRangeStart = 0
						frameRangeEnd = 0
					)
				) else (
					frameRangeStart = spinnerStartVal
					frameRangeEnd = spinnerEndVal
				)

				currentFrame = frameRangeStart

				while (currentFrame <= frameRangeEnd) do
				(
					sliderTime = currentFrame

					xyzRotation = quatToEuler currentPoint.rotation
					xRotation = (-xyzRotation.x) - 90
					yRotation = xyzRotation.y
					zRotation = xyzRotation.z

					xmlCurrentRotation = theXmlFile.createElement "rotation"
					xmlCurrentRotation.setAttribute "frameNum" ((sliderTime.frame as integer) as string)
					xmlCurrentRotation.setAttribute "xRotation" (xRotation as string)
					xmlCurrentRotation.setAttribute "yRotation" (yRotation as string)
					xmlCurrentRotation.setAttribute "zRotation" (zRotation as string)
					xmlCurrentPoint.appendChild xmlCurrentRotation

					currentFrame += 1
				)
			)
			
			sliderTime = oldSliderTime
			theXmlFile.save (saveXmlName)
			enableSceneRedraw()
			messagebox "3D data exported."
		)
	)
)

createDialog ST_Max3dXmlExporter 275 510
