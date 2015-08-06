//------------------------------------------------------------\\
//  To do:
//      Support lights!
//      Add loading bar
//		Add support for scale
//------------------------------------------------------------\\

{
	function ImportButtonPressed (xmlRoot, cameraCheckboxState, pointCheckboxState, lightCheckboxState, scaleFactor, centerScene, convertPointsToLights) {
		
		var selectedComp = app.project.activeItem;
		if (!selectedComp || !(selectedComp instanceof CompItem)) {
			alert("Please select a composition.");
		} else {
			app.beginUndoGroup("import 3D scene.");
			var compFrameRate = selectedComp.frameRate;      //calculate frames, instead of seconds.
			layerMarker = new MarkerValue("!_Imported. Scale = " + scaleFactor);

			//------------------------------- PROCESS CAMERAS -------------------------------\\
			if (cameraCheckboxState == true) {
				var numberOfCameras = xmlRoot.cameras.children().length();

				//for each camera in the XML file, create a camera with it's properties
				for (var i = 0; i < numberOfCameras; i++) {
					//grab some data about the cam
					var cameraName = xmlRoot.cameras.camera[i].@name;
					var cameraType = xmlRoot.cameras.camera[i].@type;
					//var numFrames = xmlRoot.cameras.camera[i].frame.length();

					//create the 3D camera to work with
					var theCamera = selectedComp.layers.addCamera(cameraName, [0,0]);

					if (cameraType == "Free") {
						theCamera.autoOrient = AutoOrientType.NO_AUTO_ORIENT;
						theCamera.property("Marker").setValueAtTime(0, layerMarker);

						// write out all of the position keys
						var numFrames = xmlRoot.cameras.camera[i].position.length();
						for (var j = 0; j < numFrames; j++) {
							var frameNum = xmlRoot.cameras.camera[i].position[j].@frameNum; var frameNum = parseInt(frameNum);
							var xPosition = xmlRoot.cameras.camera[i].position[j].@xPosition; xPosition = parseFloat(xPosition);
								xPosition = xPosition * scaleFactor; xPosition = (centerScene == true) ? xPosition + (selectedComp.width/2) : xPosition;
							var yPosition = xmlRoot.cameras.camera[i].position[j].@yPosition; yPosition = parseFloat(yPosition);
								yPosition = yPosition * scaleFactor; yPosition = (centerScene == true) ? yPosition + (selectedComp.width/2) : yPosition;
							var zPosition = xmlRoot.cameras.camera[i].position[j].@zPosition; zPosition = parseFloat(zPosition);
								zPosition = zPosition * scaleFactor;
							
							theCamera.property("position").setValueAtTime(frameNum/compFrameRate, [xPosition,yPosition,zPosition]);
						}

						// write out all of the rotation keys
						var numFrames = xmlRoot.cameras.camera[i].rotation.length();
						for (var j = 0; j < numFrames; j++) {
							var frameNum = xmlRoot.cameras.camera[i].rotation[j].@frameNum; var frameNum = parseInt(frameNum);
							var xRotation = xmlRoot.cameras.camera[i].rotation[j].@xRotation; xRotation = parseFloat(xRotation);
							var yRotation = xmlRoot.cameras.camera[i].rotation[j].@yRotation; yRotation = parseFloat(yRotation);
							var zRotation = xmlRoot.cameras.camera[i].rotation[j].@zRotation; zRotation = parseFloat(zRotation);

							theCamera.property("X Rotation").setValueAtTime(frameNum/compFrameRate, xRotation);
							theCamera.property("Y Rotation").setValueAtTime(frameNum/compFrameRate, yRotation);
							theCamera.property("Z Rotation").setValueAtTime(frameNum/compFrameRate, zRotation);
						}

						// write out all of the FOV keys
						var numFrames = xmlRoot.cameras.camera[i].lens.length();
						for (var j = 0; j < numFrames; j++) {
							var frameNum = xmlRoot.cameras.camera[i].lens[j].@frameNum; var frameNum = parseInt(frameNum);
							var cameraFov = xmlRoot.cameras.camera[i].lens[j].@fov;

							theCamera.property("Zoom").expression = "thisComp.width/ (2*Math.tan(degreesToRadians ("+ cameraFov +"/2)))";
							var zoomValue = theCamera.property("Zoom").value;
							theCamera.property("Zoom").setValueAtTime(frameNum/compFrameRate, zoomValue);
							theCamera.property("Zoom").expression = "";
						}
					}

					if (cameraType == "Targeted") {
						theCamera.property("Marker").setValueAtTime(0, layerMarker);

						// write out all of the position keys
						var numFrames = xmlRoot.cameras.camera[i].camPosition.length();
						for (var j = 0; j < numFrames; j++) {
							var frameNum = xmlRoot.cameras.camera[i].camPosition[j].@frameNum; var frameNum = parseInt(frameNum);
							var xPosition = xmlRoot.cameras.camera[i].camPosition[j].@xPosition; xPosition = parseFloat(xPosition);
								xPosition = xPosition * scaleFactor; xPosition = (centerScene == true) ? xPosition + (selectedComp.width/2) : xPosition;
							var yPosition = xmlRoot.cameras.camera[i].camPosition[j].@yPosition; yPosition = parseFloat(yPosition);
								yPosition = yPosition * scaleFactor; yPosition = (centerScene == true) ? yPosition + (selectedComp.width/2) : yPosition;
							var zPosition = xmlRoot.cameras.camera[i].camPosition[j].@zPosition;  zPosition = parseFloat(zPosition);
								zPosition = zPosition * scaleFactor;
							
							theCamera.property("position").setValueAtTime(frameNum/compFrameRate, [xPosition,yPosition,zPosition]);
						}

						// write out all of the target position keys
						var numFrames = xmlRoot.cameras.camera[i].targetPosition.length();
						for (var j = 0; j < numFrames; j++) {
							var frameNum = xmlRoot.cameras.camera[i].targetPosition[j].@frameNum; var frameNum = parseInt(frameNum);
							var xPosition = xmlRoot.cameras.camera[i].targetPosition[j].@xPosition; xPosition = parseFloat(xPosition);
								xPosition = xPosition * scaleFactor; xPosition = (centerScene == true) ? xPosition + (selectedComp.width/2) : xPosition;
							var yPosition = xmlRoot.cameras.camera[i].targetPosition[j].@yPosition; yPosition = parseFloat(yPosition);
								yPosition = yPosition * scaleFactor; yPosition = (centerScene == true) ? yPosition + (selectedComp.width/2) : yPosition;
							var zPosition = xmlRoot.cameras.camera[i].targetPosition[j].@zPosition;  zPosition = parseFloat(zPosition);
								zPosition = zPosition * scaleFactor;
							
							theCamera.property("Point of Interest").setValueAtTime(frameNum/compFrameRate, [xPosition,yPosition,zPosition]);
						}

						// write out all of the roll keys
						var numFrames = xmlRoot.cameras.camera[i].roll.length();
						for (var j = 0; j < numFrames; j++) {
							var frameNum = xmlRoot.cameras.camera[i].roll[j].@frameNum; var frameNum = parseInt(frameNum);
							var roll = xmlRoot.cameras.camera[i].roll[j].@roll; var roll = parseFloat(roll);
							
							theCamera.property("Z Rotation").setValueAtTime(frameNum/compFrameRate, roll);
						}

						// write out all of the FOV keys
						var numFrames = xmlRoot.cameras.camera[i].lens.length();
						for (var j = 0; j < numFrames; j++) {
							var frameNum = xmlRoot.cameras.camera[i].lens[j].@frameNum; var frameNum = parseInt(frameNum);
							var cameraFov = xmlRoot.cameras.camera[i].lens[j].@fov;

							theCamera.property("Zoom").expression = "thisComp.width/ (2*Math.tan(degreesToRadians ("+ cameraFov +"/2)))";
							var zoomValue = theCamera.property("Zoom").value;
							theCamera.property("Zoom").setValueAtTime(frameNum/compFrameRate, zoomValue);
							theCamera.property("Zoom").expression = "";
						}
					}
				}
			}

			//------------------------------- PROCESS POINTS -------------------------------\\
			if (pointCheckboxState == true && convertPointsToLights == false) {
				var numberOfPoints = xmlRoot.points.children().length();
				
				//for each point in the XML file, create a null with it's properties
				for (var i = 0; i < numberOfPoints; i++) {
					
					var pointName = xmlRoot.points.point[i].@name;

					//create the 3D point to work with
					var theNull = selectedComp.layers.addNull();
					theNull.name = pointName;
					theNull.threeDLayer = true;
					theNull.shy = true;
					theNull.property("Marker").setValueAtTime(0, layerMarker);


					// write out all of the position keys
					var numFrames = xmlRoot.points.point[i].position.length();
					for (var j = 0; j < numFrames; j++) {
						var frameNum = xmlRoot.points.point[i].position[j].@frameNum; var frameNum = parseInt(frameNum);
						var xPosition =xmlRoot.points.point[i].position[j].@xPosition; xPosition = parseFloat(xPosition);
							xPosition = xPosition * scaleFactor; xPosition = (centerScene == true) ? xPosition + (selectedComp.width/2) : xPosition;
						var yPosition =xmlRoot.points.point[i].position[j].@yPosition; yPosition = parseFloat(yPosition);
							yPosition = yPosition * scaleFactor; yPosition = (centerScene == true) ? yPosition + (selectedComp.width/2) : yPosition;
						var zPosition =xmlRoot.points.point[i].position[j].@zPosition; zPosition = parseFloat(zPosition);
							zPosition = zPosition * scaleFactor;
						
						theNull.property("position").setValueAtTime(frameNum/compFrameRate, [xPosition,yPosition,zPosition]);
					}

					// write out all of the rotation keys
					var numFrames = xmlRoot.points.point[i].rotation.length();
					for (var j = 0; j < numFrames; j++) {
						var frameNum = xmlRoot.points.point[i].rotation[j].@frameNum; frameNum = parseInt(frameNum);
						var xRotation = xmlRoot.points.point[i].rotation[j].@xRotation; xRotation = parseFloat(xRotation);
						var yRotation = xmlRoot.points.point[i].rotation[j].@yRotation; yRotation = parseFloat(yRotation);
						var zRotation = xmlRoot.points.point[i].rotation[j].@zRotation; zRotation = parseFloat(zRotation);

						theNull.property("X Rotation").setValueAtTime(frameNum/compFrameRate, xRotation);
						theNull.property("Y Rotation").setValueAtTime(frameNum/compFrameRate, yRotation);
						theNull.property("Z Rotation").setValueAtTime(frameNum/compFrameRate, zRotation);
					}
				}
			}

			//------------------------ convert points to lights
			if (pointCheckboxState == true && convertPointsToLights == true) {
				var numberOfPoints = xmlRoot.points.children().length();

				//for each point in the XML file, create a light with it's properties
				for (var i = 0; i < numberOfPoints; i++) {
					var lightName = xmlRoot.points.point[i].@name;

					//create the 3D light to work with
					var theLight = selectedComp.layers.addLight(lightName, [0,0]);
					theLight.lightType = LightType.POINT;
					theLight.shy = true;
					theLight.property("Marker").setValueAtTime(0, layerMarker);


					// write out all of the position keys
					var numFrames = xmlRoot.points.point[i].position.length();
					for (var j = 0; j < numFrames; j++) {
						var frameNum = xmlRoot.points.point[i].position[j].@frameNum; var frameNum = parseInt(frameNum);
						var xPosition =xmlRoot.points.point[i].position[j].@xPosition; xPosition = parseFloat(xPosition);
							xPosition = xPosition * scaleFactor; xPosition = (centerScene == true) ? xPosition + (selectedComp.width/2) : xPosition;
						var yPosition =xmlRoot.points.point[i].position[j].@yPosition; yPosition = parseFloat(yPosition);
							yPosition = yPosition * scaleFactor; yPosition = (centerScene == true) ? yPosition + (selectedComp.width/2) : yPosition;
						var zPosition =xmlRoot.points.point[i].position[j].@zPosition; zPosition = parseFloat(zPosition);
							zPosition = zPosition * scaleFactor;
						
						theLight.property("position").setValueAtTime(frameNum/compFrameRate, [xPosition,yPosition,zPosition]);
					}
				}
			}
		}
		app.endUndoGroup();
	}


	var theXMLFile = File.openDialog("Select the XML file", "XML: *.xml", false);
		var fileOK = theXMLFile.open("r");
	if (!fileOK) {
		alert("There was an error with the XML file.");
	} else {
		var xmlRoot = new XML (theXMLFile.read());
		theXMLFile.close();
	}

	// Put all of the objects into arrays for building the tree-view
	var cameraArray  = new Array();
	var pointArray  = new Array();
	var lightArray  = new Array();
	
	for (i = 0; i < xmlRoot.cameras.children().length(); i ++) {
		cameraArray[i] = xmlRoot.cameras.camera[i].@name;
	}
	for (i = 0; i < xmlRoot.points.children().length(); i ++) {
		pointArray[i] = xmlRoot.points.point[i].@name;
	}
	for (i = 0; i < xmlRoot.lights.children().length(); i ++) {
		lightArray[i] = xmlRoot.lights.light[i].@name;
	}
	
	//---------------------------------------------------- BUILD THE UI ----------------------------------------------------\\
	var ae3dWin = new Window("palette", "AE 3D Importer", undefined);
		ae3dWin.orientation = "column";
		ae3dWin.margins = [4,4,4,4]
		
	var myTab = ae3dWin.add("tabbedpanel", undefined, "");
		var tab1 = myTab.add("tab", undefined, "XML Data");
			tab1.margins = [10,10,10,10]
			var myMultiTree = tab1.add("treeview", [0,0,190,200], "My Tree View");
				var myTreeItems = myMultiTree.add("node", "Scene");
				var camNode = myTreeItems.add("node", "Cameras");
				var pointNode = myTreeItems.add("node", "Points");
				var lightNode = myTreeItems.add("node", "Lights");
				
			for (i = 0; i < cameraArray.length; i ++) {
				camNode.add("item", cameraArray[i]);
			}
			for (i = 0; i < pointArray.length; i ++) {
				pointNode.add("item", pointArray[i]);
			}
			for (i = 0; i < lightArray.length; i ++) {
				lightNode.add("item", lightArray[i]);
			}
			myTreeItems.expanded = true;

			var importGroup = tab1.add("group", undefined, "ImportGroup");
				var cameraCheckbox = importGroup.add("checkbox", undefined, "Cameras");
				var pointCheckbox = importGroup.add("checkbox", undefined, "Points");
				var lightCheckbox = importGroup.add("checkbox", undefined, "Lights");

		var tab2 = myTab.add("tab", undefined, "Advanced");
			tab2.orientation = "column";
			tab2.alignChildren = "left";
			tab2.margins = [10,10,10,10]
			tab2.spacing = 10;
			var tab2row1 = tab2.add("group");
				tab2row1.orientation = "row";
				tab2row1.add("statictext", undefined, "Scale Factor: ")
				var scaleFactorBox = tab2row1.add("edittext", undefined, "10")
					scaleFactorBox.characters = 5;
					scaleFactorBox.justify = "center";
			var tab2row2 = tab2.add("group");
				var centerSceneChkbox = tab2row2.add("checkbox", undefined, "  Move scene to comp center.");
					centerSceneChkbox.value = true;
			var tab2row3 = tab2.add("group");
				var convertPointsToLightsChkbox = tab2row3.add("checkbox", undefined, "  Convert points to lights.");
					convertPointsToLightsChkbox.value = false;
		
	var endGroup = ae3dWin.add("group", undefined, "GroupOne");
		endGroup.orientation = "column"; //column, row and center
		var importButton = endGroup.add("button", [0,0,190,28], "Import 3D");
		//var progressBar = endGroup.add("progressbar", [0,0,190,8], "Progress");
		
	//grey out empty items
	if (cameraArray.length < 1) {
		camNode.enabled = false;
		cameraCheckbox.enabled = false;
	} else {
		camNode.expanded = true;
		cameraCheckbox.value = true;
	}
	if (pointArray.length < 1) {
		pointNode.enabled = false;
		pointCheckbox.enabled = false;
	} else {
		pointNode.expanded = true;
		pointCheckbox.value = true;
	}
	if (lightArray.length < 1) {
		lightNode.enabled = false;
		lightCheckbox.enabled = false;
	} else {
		pointCheckbox.value = true;
	}
		
	//Event listeners
	cameraCheckbox.onClick = function () {
		if (cameraCheckbox.value == true && cameraArray.length >= 1) {
			camNode.enabled = true;
			camNode.expanded = true;
		} else {
			camNode.enabled = false;
			camNode.expanded = false;
		}
	}

	pointCheckbox.onClick = function () {
		if (pointCheckbox.value == true && pointArray.length >= 1) {
			pointNode.enabled = true;
			pointNode.expanded = true;
		} else {
			pointNode.enabled = false;
			pointNode.expanded = false;
		}
	}

	lightCheckbox.onClick = function () {
		if (lightCheckbox.value == true && lightArray.length >= 1) {
			lightNode.enabled = true;
			lightNode.expanded = true;
		} else {
			lightNode.enabled = false;
			lightNode.expanded = false;
		}
	}

	importButton.onClick = function () {
		//importButton.text = "Loading...";
		ImportButtonPressed(xmlRoot, cameraCheckbox.value, pointCheckbox.value, lightCheckbox.value, scaleFactorBox.text, centerSceneChkbox.value, convertPointsToLightsChkbox.value);
		//importButton.text = "Import 3D";
		};

	ae3dWin.center();
	ae3dWin.show();
}
