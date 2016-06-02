
<cfquery name="qCounties" datasource="plss">
	select name from global.counties
    order by name asc
</cfquery>

<cfoutput>
<!doctype html>

<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<meta http-equiv="X-UA-Compatible" content="IE=7" />
<meta name="description" content="Interactive map for the Kansas Geological Survey's Carbon Sequestration project." />
<meta name="author" content="Mike Killion">
<meta name="copyright" content="&copy; Kansas Geological Survey">
<meta name="keywords" content="CO2, sequestration, carbon dioxide, KIOGM, Kansas, geology">

<title>KIOGM</title>

<link rel="stylesheet" href="http://js.arcgis.com/3.7/js/dojo/dijit/themes/soria/soria.css">
<link rel="stylesheet" href="http://js.arcgis.com/3.7/js/esri/css/esri.css">

<script src="http://js.arcgis.com/3.7/"></script>
<script>var dojoConfig = { parseOnLoad: false };</script>

<script>require(["dojo/parser"]);</script>


<link rel="stylesheet" type="text/css" href="style.css">

<style type="text/css">
	.dijitTitlePaneTitle {
		background:url(images/gold_top.jpg) repeat-x;
		}

  .box {
  	z-index:1500;
    margin-top: 10px;
    color: ##292929;
    width: 1250px;
	height: 610px;
    position: absolute;
    top: 80px;
    border: 1px solid ##BABABA;
    background-color: ##ddd;
    padding-left: 10px;
    padding-right: 10px;
    margin-left: 10px;
    margin-bottom: 1em;
    -o-border-radius: 10px;
    -moz-border-radius: 12px;
    -webkit-border-radius: 10px;
    -webkit-box-shadow: 0px 3px 7px ##adadad;
    border-radius: 10px;
    -moz-box-sizing: border-box;
    -opera-sizing: border-box;
    -webkit-box-sizing: border-box;
    -khtml-box-sizing: border-box;
    box-sizing: border-box;
    overflow: hidden;
  }

    th {
        border-right: 1px solid gray;
    }

    ##geollayerpicker td {
        background-color: ##ddd;
        font: normal normal normal 14px arial;
        vertical-align: top;
    }


</style>

<script src="js/show_loading.js"></script>
<script src="js/hide_loading.js"></script>

<script type="text/javascript">
	dojo.require("esri.map");
	dojo.require("esri.tasks.identify");
	dojo.require("esri.toolbars.draw");
	dojo.require("esri.tasks.find");
	dojo.require("esri.tasks.geometry");
	dojo.require("esri.tasks.query");
	dojo.require("esri.geometry");
	dojo.require("esri.graphic");

	dojo.require("dijit.layout.ContentPane");
	dojo.require("dijit.layout.TabContainer");
	dojo.require("dojo.data.ItemFileReadStore");
	dojo.require("dijit.form.FilteringSelect");
	dojo.require("dijit.form.Slider");
	dojo.require("dijit.Dialog");
	dojo.require("dijit.Menu");
	dojo.require("dijit.layout.BorderContainer");
	dojo.require("dijit.TitlePane");
	dojo.require("dojo.fx");
	dojo.require("dojo.dnd.Mover");
  	dojo.require("dojo.dnd.Moveable");
  	dojo.require("dojo.dnd.move");
  	dojo.require("esri.dijit.Scalebar");
	dojo.require("esri.layers.graphics");

	dojo.require("esri.layers.FeatureLayer");
	dojo.require("esri.tasks.GenerateRendererTask");
    dojo.require("esri.dijit.Legend");
	dojo.require("esri.tasks.PrintTask");

	var app = {};

	var ovmap;
	var resizeTimer;
	var identify, identifyParams;
	var currField = "";
	var filter, wwc5_filter;
	var label;
	var visibleWellLyr;
	var lastLocType, lastLocValue;
	var xSectionKIDS = new Array();
	var xSectionPointGraphics;
	var currentKID;
	var xSectionLineGraphics;
	var xSectionXs = new Array();
	var xSectionYs = new Array();
	var las3whereClause = "";
	var las3Count;
	var m2;
	var eligibleWellsGraphics;
	var fieldFilt;
	var xSectionLine;
	var sr;
	var formationList = '';
    var loadedLyrs = "";

	dojo.addOnLoad(init);

	function init() {
		showLoading();
		dojo.parser.parse();
    	hideLoading();

		esri.config.defaults.io.proxyUrl = 'http://maps.kgs.ku.edu/proxy.jsp';
        //esri.config.defaults.io.timeout = 2000;

		sr = new esri.SpatialReference({ wkid:3857 });
		var initExtent = new esri.geometry.Extent(-11267810, 4420699, -10719558, 4632090, sr);

		app.map = new esri.Map("map_div", { nav:true, logo:false });

		// Create event listeners:
		dojo.connect(app.map, 'onLoad', function(){
			dojo.connect(dijit.byId('map_div'), 'resize', function(){
				resizeMap();
			});


			dojo.connect(app.map, "onClick", executeIdTask);
			dojo.connect(app.map, "onExtentChange", setScaleDependentTOC);

			// Add graphics layers:
			app.map.addLayer(xSectionPointGraphics);
			app.map.addLayer(xSectionLineGraphics);
			app.map.addLayer(eligibleWellsGraphics);

			var scalebar = new esri.dijit.Scalebar({
				map: app.map,
			    scalebarUnit:'english'
          	});

			showLAS3Wells();
            //parseURL(); //not currently used (20140806), zooms to feature passed through URL.
		});

		// Dynamic renderer layer:
		app.rendererDataUrl = "http://services.kgs.ku.edu/arcgis1/rest/services/co2/oilgas_fields_co2_rendering/MapServer/0";

		xSectionPointGraphics = new esri.layers.GraphicsLayer();
		xSectionLineGraphics = new esri.layers.GraphicsLayer();
		eligibleWellsGraphics = new esri.layers.GraphicsLayer();

		// Define layers:
		baseLayer = new esri.layers.ArcGISTiledMapServiceLayer("http://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer");

		fieldsLayer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/oilgas/oilgas_fields/MapServer", { visible:false });

		fieldsFilterRenderLayer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis1/rest/services/co2/oilgas_fields_co2_rendering/MapServer", { id:"og_fields_render", opacity:1.0, visible:false });
		fieldsFilterRenderLayer.setVisibleLayers([0]);

		wellsNoLabelLayer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis1/rest/services/co2/general/MapServer", { visible:true, id:"ogwells" });
		wellsNoLabelLayer.setVisibleLayers([0]);

		wellsLeaseWellLabelLayer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis1/rest/services/co2/general/MapServer", { visible:false });
		wellsLeaseWellLabelLayer.setVisibleLayers([5]);

		wellsAPILabelLayer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis1/rest/services/co2/general/MapServer", { visible:false });
		wellsAPILabelLayer.setVisibleLayers([6]);

		wellsFormationLabelLayer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis1/rest/services/co2/general/MapServer", { visible:false });
		wellsFormationLabelLayer.setVisibleLayers([7]);

		wwc5Layer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis1/rest/services/co2/general/MapServer", { visible:false });
		wwc5Layer.setVisibleLayers([8]);

		superTypesLayer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis1/rest/services/co2/general/MapServer", { visible:true });
		superTypesLayer.setVisibleLayers([10]);

		hrzWellsLayer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis1/rest/services/co2/general/MapServer", { visible:false });
		hrzWellsLayer.setVisibleLayers([11]);

        plssLayer = new esri.layers.ArcGISTiledMapServiceLayer("http://services.kgs.ku.edu/arcgis2/rest/services/plss/plss/MapServer");


		var imageServiceParameters = new esri.layers.ImageServiceParameters();
        imageServiceParameters.format = "jpg";

		//drgLayer = new esri.layers.ArcGISImageServiceLayer("http://services.kgs.ku.edu/arcgis7/rest/services/Elevation/USGS_Digital_Topo/MapServer", { visible:false, imageServiceParameters:imageServiceParameters });
		drgLayer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis7/rest/services/Elevation/USGS_Digital_Topo/MapServer", { visible:false });
		drgLayer.setVisibleLayers([11]);

		naipLayer = new esri.layers.ArcGISImageServiceLayer("http://services.kgs.ku.edu/arcgis7/rest/services/IMAGERY_STATEWIDE/FSA_NAIP_2014_Color/ImageServer", { visible:false, imageServiceParameters:imageServiceParameters });

		nedLayer = new esri.layers.ArcGISImageServiceLayer("http://services.kgs.ku.edu/arcgis/rest/services/Elevation/National_Elevation_Dataset/ImageServer", { visible:false, imageServiceParameters:imageServiceParameters });

		modelAreasLayer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis1/rest/services/co2/results/MapServer", { visible:true });
		modelAreasLayer.setVisibleLayers([2]);

		p10Layer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis1/rest/services/co2/results/MapServer", { visible:false });
		p10Layer.setVisibleLayers([0]);

		p90Layer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis1/rest/services/co2/results/MapServer", { visible:false });
		p90Layer.setVisibleLayers([1]);

		typeWellsLayer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis1/rest/services/co2/general/MapServer", { visible:true });
		typeWellsLayer.setVisibleLayers([12]);

		earthquakesLayer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis1/rest/services/co2/seismic_1/MapServer", { visible:false });
		earthquakesLayer.setVisibleLayers([19]);

        class1WellsLayer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis1/rest/services/co2/class_1_2_wells/MapServer", { visible:false });
		class1WellsLayer.setVisibleLayers([0]);

        class2WellsLayer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis1/rest/services/co2/class_1_2_wells/MapServer", { visible:false });
		class2WellsLayer.setVisibleLayers([1]);

		pcLithoLayer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis1/rest/services/co2/class_1_2_wells/MapServer", { visible:false });
		pcLithoLayer.setVisibleLayers([2]);

		wellingtonEarthquakesLayer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis1/rest/services/co2/seismic_1/MapServer", { visible:false });
		wellingtonEarthquakesLayer.setVisibleLayers([20,21]);



		// Add layers (first layer added displays on the bottom):
		app.map.addLayer(baseLayer);
		app.map.addLayer(naipLayer);
		app.map.addLayer(drgLayer);
		app.map.addLayer(nedLayer);
		app.map.addLayer(p90Layer);
		app.map.addLayer(p10Layer);
		app.map.addLayer(fieldsLayer);
		app.map.addLayer(fieldsFilterRenderLayer);
		app.map.addLayer(plssLayer);
		app.map.addLayer(wwc5Layer);
		app.map.addLayer(wellsNoLabelLayer);
		app.map.addLayer(wellsLeaseWellLabelLayer);
		app.map.addLayer(wellsAPILabelLayer);
		app.map.addLayer(wellsFormationLabelLayer);
		app.map.addLayer(hrzWellsLayer);
		app.map.addLayer(typeWellsLayer);
		app.map.addLayer(modelAreasLayer);
		app.map.addLayer(earthquakesLayer);
		app.map.addLayer(wellingtonEarthquakesLayer);
        app.map.addLayer(class1WellsLayer);
        app.map.addLayer(class2WellsLayer);
        app.map.addLayer(pcLithoLayer);


		visibleWellLyr = wellsNoLabelLayer;

		app.map.setExtent(initExtent, true);
		app.map.setLevel(8);

		setScaleDependentTOC();

		// Drag and drop layer picker setup:
	    m2 = new dojo.dnd.Moveable("animDiv");

	    dojo.subscribe("/dnd/move/start", function(mover){
	      console.debug("Start move", mover);
	    });
	    dojo.subscribe("/dnd/move/stop", function(mover){
	      console.debug("Stop move", mover);
	    });

	    dojo.connect(m2, "onMoveStart", function(mover){
	      console.debug("Start moving m2", mover);
	    });
	    dojo.connect(m2, "onMoveStop", function(mover){
	      console.debug("Stop moving m2", mover);
	    });

	}

    // this function not used, just keeping code.
    function parseURL() {
        var queryParams = location.search.substr(1);
        var pairs = queryParams.split("&");
        if (pairs.length > 1) {
            var extType = pairs[0].substring(11);
            var extValue = pairs[1].substring(12);

            var findTask = new esri.tasks.FindTask("http://services.kgs.ku.edu/arcgis1/rest/services/co2/general/MapServer");
			var findParams = new esri.tasks.FindParameters();
			findParams.returnGeometry = true;
			findParams.contains = false;

            switch (extType) {
                case "well":
                    findParams.layerIds = [0];
					findParams.searchFields = ["kid"];
                    break;
                case "field":
                    findParams.layerIds = [1];
					findParams.searchFields = ["field_kid"];
					fieldsLayer.show();
					dojo.byId('fields').checked = 'checked';
                    break;
                case "county":
                    findParams.layerIds = [2];
          			findParams.searchFields = ["county"];
                    break;
                case "plss":
                    findParams.layerIds = [3];
					findParams.searchFields = ["s_r_t"];
                    break;
            }

            lastLocType = extType;
			lastLocValue = extValue;
            findParams.searchText = extValue;
            findTask.execute(findParams,zoomToResults);
        }
    }


	function animateDiv(action) {
		var fadeOut = dojo.fadeOut({node: "animDiv",duration: 750});
		var fadeIn = dojo.fadeIn({node: "animDiv",duration: 750});
		var wipeOut = dojo.fx.wipeOut({node: "animDiv",duration: 750});
		var wipeIn = dojo.fx.wipeIn({node: "animDiv",duration: 750});
		var slideRight = dojo.fx.slideTo({node: "animDiv",duration: 750, left: 300, top: 80});
		var slideLeft = dojo.fx.slideTo({node: "animDiv",duration: 750, left: 0, top:80});

		var animOut = dojo.fx.combine([fadeOut, wipeOut, slideRight]);
		var animIn = dojo.fx.combine([fadeIn, wipeIn, slideLeft]);

		if (action == 'close') {
			var currentAnimation = animOut;
		} else {
			var currentAnimation = animIn;
		}

		currentAnimation.play();
	}


	function resizeMap() {
		clearTimeout(resizeTimer);
		resizeTimer = setTimeout(function(){
			app.map.resize();
			app.map.reposition();
		}, 500);
	}


	/*function changeOvExtent(ext) {
		// Change extent of overview map in response to extent change on main app.map. Padding makes extent bigger than main map extent.
		padding = 12000;
		ovMapExtent = new esri.geometry.Extent(ext.xmin - padding, ext.ymin - padding, ext.xmax + padding, ext.ymax + padding);

		ovapp.map.setExtent(ovMapExtent);

		symbol = new esri.symbol.SimpleFillSymbol(esri.symbol.SimpleFillSymbol.STYLE_SOLID, new esri.symbol.SimpleLineSymbol(esri.symbol.SimpleLineSymbol.STYLE_SOLID, new dojo.Color([255,0,0]), 2), new dojo.Color([255,0,0,0.2]));
		boxPts = new Array();
		box = new esri.geometry.Polygon();

		boxNW = new esri.geometry.Point(ext.xmin, ext.ymax);
		boxSW = new esri.geometry.Point(ext.xmin, ext.ymin);
		boxSE = new esri.geometry.Point(ext.xmax, ext.ymin);
		boxNE = new esri.geometry.Point(ext.xmax, ext.ymax);

		boxPts.push(boxNW, boxSW, boxSE, boxNE, boxNW);

		box.addRing(boxPts);

		if (ovapp.map.graphics) {
			ovapp.map.graphics.clear();
			ovapp.map.graphics.add(new esri.Graphic(box, symbol));
		}

		// Give map time to load then toggle scale-dependent layers in table of contents:
		setTimeout(setScaleDependentTOC, 1000);

		// If filter is on, re-apply with new extent:
		if (filter != 'off') {
			filterWells(filter);
		}
	}*/

	function setScaleDependentTOC() {
		// On extent change, check level of detail and change styling on scale-dependent layer names:
		var lod = app.map.getLevel();

		// PLSS & oilgas wells:
		if (lod >= 11) {
			dojo.byId('plss_txt').innerHTML = 'Sec-Twp-Rng';
			dojo.byId('plss_txt').style.color = '##000000';
			dojo.byId('vis_msg').innerHTML = '';
		}
		else {
			dojo.byId('plss_txt').innerHTML = 'Sec-Twp-Rng*';
			dojo.byId('plss_txt').style.color = '##999999';
			dojo.byId('vis_msg').innerHTML = '* Zoom in to view layer';
		}

		if (lod >= 12) {
			dojo.byId('ogwells_txt').innerHTML = 'All Oil & Gas Wells';
			dojo.byId('ogwells_txt').style.color = '##000000';
			dojo.byId('vis_msg').innerHTML = '';
		} else {
			dojo.byId('ogwells_txt').innerHTML = 'All Oil & Gas Wells*';
			dojo.byId('ogwells_txt').style.color = '##999999';
			dojo.byId('vis_msg').innerHTML = '* Zoom in to view layer';
		}

		// WWC5:
		if (lod >= 13) {
			dojo.byId('wwc5_txt').innerHTML = 'WWC5 Water Wells';
			dojo.byId('wwc5_txt').style.color = '##000000';
			dojo.byId('vis_msg').innerHTML = '';
		}
		else {
			dojo.byId('wwc5_txt').innerHTML = 'WWC5 Water Wells*';
			dojo.byId('wwc5_txt').style.color = '##999999';
			dojo.byId('vis_msg').innerHTML = '* Zoom in to view layer';
		}

		//dojo.byId('junk').innerHTML = lod;
	}


	function executeIdTask(evt) {
		identify = new esri.tasks.IdentifyTask("http://services.kgs.ku.edu/arcgis1/rest/services/co2/general/MapServer");

		identifyParams = new esri.tasks.IdentifyParameters();
		identifyParams.tolerance = 4;
        identifyParams.returnGeometry = true;
		identifyParams.mapExtent = app.map.extent;
		identifyParams.geometry = evt.mapPoint;

		if (label == 'leasewell') {
				lyrID = 5;
			}
			else if (label == 'api') {
				lyrID = 6;
			}
			else if (label == 'formation') {
				lyrID = 7;
			}
			else {
				lyrID = 0;
			}

		if (dojo.byId('shelig').innerHTML == 'Hide') {
			identifyParams.layerDefinitions = [];
			identifyParams.layerDefinitions[lyrID] = "kid in (select well_header_kid from iqstrat.doe_co2_las3)";
		} else if (dojo.byId('shelig').innerHTML == 'Show') {
			identifyParams.layerDefinitions = [];
			identifyParams.layerDefinitions[lyrID] = "";
		}

		if (fieldFilt == 'on') {
			identifyParams.layerDefinitions = [];
			identifyParams.layerDefinitions[1] = "field_kid in (select field_kid from nomenclature.fields_reservoirs where upper(formation_name) in " + formationList + ")";
		}

		identifyParams.layerIds = [13,0,8,1];

		identify.execute(identifyParams, function(fset) {
			addToMap(fset,evt);
		});
	}


	function sortAPI(a, b) {
        var numA = a.feature.attributes["api_number"];
        var numB = b.feature.attributes["api_number"];
        if (numA < numB) { return -1 }
        if (numA > numB) { return 1 }
        return 0;
    }


	function displayCrossSection(xSectKID)
	{
		var url = 'http://www.kgs.ku.edu/PRS/Ozark/Applet/GCrossSection.html?sKID=' + xSectKID;

		var xSectionDisplay = window.open(url, '', '');
	}


	function addToMap(results,evt) {
		featureset = results;

		if (featureset.length > 1) {
			var content = "";
			var selectionType = "";
		}
		else {
			var title = results.length + " features were selected:";
			var content = "Please zoom in further to select a well.";
			var isSelection = false;
		}

		if (results.length == 1) {
			if (featureset[0].layerId == 9) {
				displayCrossSection(results[0].feature.attributes["CROSS_KID"]);
			}

			if (featureset[0].layerId == 0 || featureset[0].layerId == 8 || featureset[0].layerId == 13) {
				showPoint(featureset[0].feature, featureset[0].layerId);
			}
			else {
				//fieldsLayer.show();
				//dojo.byId('fields').checked = 'checked';
				if (dojo.byId('fields').checked) {
					showPoly(featureset[0].feature);
				}

				//showPoly(featureset[0].feature);
			}
		}
		else {
			results.sort(sortAPI);

			for (var i = 0, il = results.length; i < il; i++) {
				var graphic = results[i].feature;

			  	switch (graphic.geometry.type) {
					case "point":
				  		var symbol = new esri.symbol.SimpleMarkerSymbol(esri.symbol.SimpleMarkerSymbol.STYLE_CIRCLE, 10, new esri.symbol.SimpleLineSymbol(esri.symbol.SimpleLineSymbol.STYLE_SOLID, new dojo.Color([255,255,0]), 1), new dojo.Color([255,255,0,0.25]));
				 		break;
					case "polyline":
				  		var symbol = new esri.symbol.SimpleLineSymbol(esri.symbol.SimpleLineSymbol.STYLE_DASH, new dojo.Color([0,255,0]), 1);
				  		break;
					case "polygon":
				  		var symbol = new esri.symbol.SimpleFillSymbol(esri.symbol.SimpleFillSymbol.STYLE_NULL, new esri.symbol.SimpleLineSymbol(esri.symbol.SimpleLineSymbol.STYLE_SOLID, new dojo.Color([255,255,0]), 3), new dojo.Color([0,255,0,0.25]));
				 		break;
					case "multipoint":
				  		var symbol = new esri.symbol.SimpleMarkerSymbol(esri.symbol.SimpleMarkerSymbol.STYLE_DIAMOND, 20, new esri.symbol.SimpleLineSymbol(esri.symbol.SimpleLineSymbol.STYLE_SOLID, new dojo.Color([0,0,0]), 1), new dojo.Color([0,255,0,0.5]));
				  		break;
			  	}

			  	graphic.setSymbol(symbol);

				switch (featureset[0].layerId) {
					case 13:
						selectionType = "well";
						var title = results.length + " Type Wells were selected:";
						content += "<tr><td width='*'>" + results[i].feature.attributes["LEASE_NAME"] + " " + results[i].feature.attributes["WELL_NAME"] + "</td><td width='15%'>" + results[i].feature.attributes["API_NUMBER"] + "</td><td width='10%'>" + results[i].feature.attributes["STATUS"] + "</td><td width='10%' align='center'><A style='text-decoration:underline;color:blue;cursor:pointer' onclick='showPoint(featureset[" + i + "].feature,13);'>display</A></td></tr>";
						break;
					case 0:
						selectionType = "well";
						var title = results.length + " oil or gas wells were selected:";
						content += "<tr><td width='*'>" + results[i].feature.attributes["lease_name"] + " " + results[i].feature.attributes["well_name"] + "</td><td width='15%'>" + results[i].feature.attributes["api_number"] + "</td><td width='10%'>" + results[i].feature.attributes["status"] + "</td><td width='10%' align='center'><A style='text-decoration:underline;color:blue;cursor:pointer' onclick='showPoint(featureset[" + i + "].feature,0);'>display</A></td></tr>";
						break;
					case 1:
						selectionType = "field";
						var title = results.length + " fields were selected:";
						content += "<tr><td>" + results[i].feature.attributes["FIELD_NAME"] + "</td><td><A style='text-decoration:underline;color:blue;cursor:pointer;' onclick='showPoly(featureset[" + i + "].feature,1);'>display</A></td></tr>";
						break;
					case 8:
						selectionType = "wwc5";
						var title = results.length + " water wells were selected:";

						var status = "";
						if (results[i].feature.attributes["TYPE_OF_ACTION_CODE"] == 1) {
							status = "Constructed";
						}

						if (results[i].feature.attributes["TYPE_OF_ACTION_CODE"] == 2) {
							status = "Reconstructed";
						}

						if (results[i].feature.attributes["TYPE_OF_ACTION_CODE"] == 3) {
							status = "Plugged";
						}

						var useCodeAtt = results[i].feature.attributes["WATER_USE_CODE"];
						switch (useCodeAtt) {
							case '1':
								useCode = "Domestic";
								break;
							case '2':
								useCode = "Irrigation";
								break;
							case '4':
								useCode = "Industrial";
								break;
							case '5':
								useCode = "Public Water Supply";
								break;
							case '6':
								useCode = "Oil Field Water Supply";
								break;
							case '7':
								useCode = "Lawn and Garden - domestic only";
								break;
							case '8':
								useCode = "Air Conditioning";
								break;
							case '9':
								useCode = "Dewatering";
								break;
							case '10':
								useCode = "Monitoring well/observation/piezometer";
								break;
							case '11':
								useCode = "Injection well/air sparge (AS)/shallow";
								break;
							case '12':
								useCode = "Other";
								break;
							case '107':
								useCode = "Test hole/well";
								break;
							case '116':
								useCode = "Feedlot/Livestock/Windmill";
								break;
							case '122':
								useCode = "Recovery/Soil Vapor Extraction/Soil Vent";
								break;
							case '183':
								useCode = "(unstated)/abandoned";
								break;
							case '189':
								useCode = "Road Construction";
								break;
							case '237':
								useCode = "Pond/Swimming Pool/Recreation";
								break;
							case '240':
								useCode = "Cathodic Protection Borehole";
								break;
							case '242':
								useCode = "Recharge Well";
								break;
							case '245':
								useCode = "Heat Pump (Closed Loop/Disposal), Geothermal";
								break;
							case '260':
								useCode = "Domestic, changed from Irrigation";
								break;
							case '270':
								useCode = "Domestic, changed from Oil Field Water Supply";
								break;
							default:
								useCode = "";
						}

						content += "<tr><td width='*'>" + results[i].feature.attributes["OWNER_NAME"] + "</td><td width='25%'>" + useCode + "</td><td width='15%'>" + status + "</td><td width='15%' align='center'><A style='text-decoration:underline;color:blue;cursor:pointer' onclick='showPoint(featureset[" + i + "].feature,8);'>display</A><br/>";
						break;
				}

				//app.map.graphics.add(graphic);
			}

			if (selectionType == "well") {
				content = "<table border='1' cellpadding='3'><tr><th>LEASE/WELL</th><th>API NUMBER</th><th>WELL TYPE</th><th>INFO</th></tr>" + content + "</table><p><input type='button' value='Close' onClick='app.map.infoWindow.hide();' />";
			}

			if (selectionType == "field") {
				content = "<table border='1' cellpadding='3'<tr><th>FIELD NAME</th><th>INFO</th></tr>" + content + "</table><p><input type='button' value='Close' onClick='app.map.infoWindow.hide();' />";
			}

			if (selectionType == "wwc5") {
				content = "<table border='1' cellpadding='3'><tr><th>OWNER</th><th>WELL USE</th><th>STATUS</th><th>INFO</th></tr>" + content + "</table><p><input type='button' value='Close' onClick='app.map.infoWindow.hide();' />";
			}

			app.map.infoWindow.resize(450, 300);
			app.map.infoWindow.setTitle(title);
			app.map.infoWindow.setContent(content);
			app.map.infoWindow.show(evt.screenPoint,app.map.getInfoWindowAnchor(evt.screenPoint));
		}
	}


	function showPoint(feature, lyrId) {
		app.map.graphics.clear();

		// Highlight selected feature:
		var ptSymbol = new esri.symbol.SimpleMarkerSymbol();
		ptSymbol.setOutline(new esri.symbol.SimpleLineSymbol(esri.symbol.SimpleLineSymbol.STYLE_SOLID, new dojo.Color([255,255,0]), 3));
		ptSymbol.size = 20;
		feature.setSymbol(ptSymbol);

		app.map.graphics.add(feature);

		if (lyrId == 0) {
			// oil or gas well.
			var idURL = "retrieve_info.cfm?get=well&kid=" + feature.attributes.kid + "&api=" + feature.attributes.api_number;
			currentKID = feature.attributes.kid;
		}
		else if (lyrId == 13) {
			// type well - separating this out because the attributes are uppercase for some reason.
			var idURL = "retrieve_info.cfm?get=well&kid=" + feature.attributes.KID + "&api=" + feature.attributes.API_NUMBER;
			currentKID = feature.attributes.KID;
		}
		else if (lyrId == 8) {
			// wwc5 well.
			var idURL = "retrieve_info.cfm?get=wwc5&seq=" + feature.attributes.INPUT_SEQ_NUMBER;
		}

		// Make an ajax request to retrieve well info (content is formatted in retrieve_info.cfm):
		dojo.xhrGet( {
			url: idURL,
			handleAs: "text",
			load: function(response, ioArgs) {
				dojo.byId('infoTab').innerHTML = response;
				return response;
			},
			/*error: function(err) {
				alert(err);
			},*/
			timeout: 180000
		});

		// Make Info tab active:
		tabContainer = dijit.byId('mainTabContainer');
		tabContainer.selectChild('infoTab');

		// Update number of wells selected for cross section:
		setTimeout(updateNumSelected, 500);

	}


	function showPoly(feature) {
        app.map.graphics.clear();
		app.map.infoWindow.hide();

		// Highlight selected feature:
        var symbol = new esri.symbol.SimpleFillSymbol(esri.symbol.SimpleFillSymbol.STYLE_NULL, new esri.symbol.SimpleLineSymbol(esri.symbol.SimpleLineSymbol.STYLE_SOLID, new dojo.Color([255,255,0]), 4), new dojo.Color([255,0,0,0.25]));
		feature.setSymbol(symbol);

		app.map.graphics.add(feature);

		var kid = feature.attributes.FIELD_KID;

		// Make an ajax request to retrieve field info (content is formatted in retrieve_info.cfm):
		dojo.xhrGet( {
			url: "retrieve_info.cfm?get=field&kid=" + kid,
			handleAs: "text",
			load: function(response, ioArgs) {
				dojo.byId('infoTab').innerHTML = response;
				return response;
			},
			/*error: function(err) {
				alert(err);
			},*/
			timeout: 180000
		});

		// Make Info tab active:
		tabContainer = dijit.byId('mainTabContainer');
		tabContainer.selectChild('infoTab');

		currField = kid;

		if (filter == "selected_field") {
			filterWells('selected_field');
		}
	}


	function createDownloadFile() {
		// Reproject extent to NAD27, then request well records inside new extent:
		//var inCoords = new esri.Graphic();
		//inCoords.setGeometry(app.map.extent);

		var outSR = new esri.SpatialReference({ wkid: 4267});

		var gsvc = new esri.tasks.GeometryService("http://services.kgs.ku.edu/arcgis1/rest/services/Utilities/Geometry/GeometryServer");

		gsvc.project([ app.map.extent ], outSR, function(features) {
			var xMin = features[0].xmin;
			var xMax = features[0].xmax;
			var yMin = features[0].ymin;
			var yMax = features[0].ymax;

			dojo.byId('loading_div').style.top = "-" + (app.map.height / 2 + 50) + "px";
			dojo.byId('loading_div').style.left = app.map.width / 2 + "px";
			dojo.byId('loading_div').style.display = "block";

			dojo.xhrGet( {
				url: 'download_file.cfm?xmin=' + xMin + '&xmax=' + xMax + '&ymin=' + yMin + '&ymax=' + yMax + '&filter=' + filter + '&field=' + currField,
				handleAs: "text",
				load: function(response) {
					dojo.byId('loading_div').style.display = "none";
					dijit.byId('download_results').show();
					dojo.byId('download_msg').innerHTML = response;
				},
				error: function(err) {
					alert(err);
				},
				timeout: 600000
			});
		});
	}


	function checkDownload() {
		var lod = app.map.getLevel();

		if (lod >= 5) { // Prevent user from downloading all wells.
			dijit.byId('download').show();
		}
		else {
			// Show warning dialog box:
			dojo.byId('warning_msg').innerHTML = "Please zoom in to limit the number of wells.";
			dijit.byId('warning_box').show();
		}
	}


	function zoomToResults(results) {
		if (results.length == 0) {
			// Show warning dialog box:
			dojo.byId('warning_msg').innerHTML = "This search did not return any features.<br>Please check your entries and try again.";
			dijit.byId('warning_box').show();
		}

		var feature = results[0].feature;

		switch (feature.geometry.type) {
			case "point":
				// Set extent around well (slightly offset so well isn't behind field label), and draw a highlight circle around it:
				var x = feature.geometry.x;
				var y = feature.geometry.y;

				ext = new esri.geometry.Extent(x - 600, y - 600, x + 500, y + 500, sr);
				app.map.setExtent(ext.expand(3));

				var lyrId = results[0].layerId;
				showPoint(feature,lyrId);
				break;
			case "polygon":
				var ext = feature.geometry.getExtent();

				// Pad extent so entire feature is visible when zoomed to:
				var padding = 1000;
				ext.xmax += padding;
				ext.xmin -= padding;
				ext.ymax += padding;
				ext.ymin -= padding;

				app.map.setExtent(ext);

				var lyrId = results[0].layerId;
				showPoly(feature,lyrId);
				break;
		}
	}


    function changeMap(layer, chkObj, legend, title) {
		if (layer == "wells") {
			switch (visibleWellLyr) {
				case wellsNoLabelLayer:
					layer = wellsNoLabelLayer;
					break;

				case wellsLeaseWellLabelLayer:
					layer = wellsLeaseWellLabelLayer;
					break;

				case wellsAPILabelLayer:
					layer = wellsAPILabelLayer;
					break;

				case wellsFormationLabelLayer:
					layer = wellsFormationLabelLayer;
					break;
			}
		}

		if (layer == fieldsLayer) {
			if (fieldFilt == 'on') {
				layer = fieldsFilterRenderLayer;
			}
		}

		if (chkObj.checked) {
			layer.show();

			if (title != 'none') {
				var strAdd = '<BR><B>' + title + '</B><BR><IMG src="http://maps.kgs.ku.edu/co2/images/' + legend + '.jpg" />' + dojo.byId("mainlegenddiv").innerHTML;
				dojo.byId("mainlegenddiv").innerHTML = strAdd;
			}
		}
		else {
			layer.hide();

			if (title != 'none') {
				var inHTML = dojo.byId('mainlegenddiv').innerHTML.toUpperCase();
				var lg = legend.toUpperCase();
				var t = title.toUpperCase();
				var strRemove = '<BR><B>' + t + '</B><BR><IMG SRC="HTTP://MAPS.KGS.KU.EDU/CO2/IMAGES/' + lg + '.JPG">'.toUpperCase();
				dojo.byId('mainlegenddiv').innerHTML = inHTML.replace(strRemove,"");
			}
		}
	}


	function loadNChangeMap(layer, chkObj, srvc, lyrID, legend, title) {
        var lID = lyrID.split(",");

        var isLoaded = loadedLyrs.search(layer);

        if (isLoaded < 0) {   //first time layer has been called upon.
            loadedLyrs += layer;

            layer = new esri.layers.ArcGISDynamicMapServiceLayer("http://services.kgs.ku.edu/arcgis1/rest/services/co2/" + srvc + "/MapServer", { visible:false, id:layer });
            layer.setVisibleLayers(lID);
            app.map.addLayer(layer);

            layer.show();
            addLegend(title,legend);
        } else {
            var lyrObj = app.map.getLayer(layer);

            if (chkObj.checked) {
                lyrObj.show();
                addLegend(title,legend);
            }
            else {
                lyrObj.hide();

                // Remove legend:
                if (title != 'none') {
                    var inHTML = dojo.byId('mainlegenddiv').innerHTML.toUpperCase();
                    var lg = legend.toUpperCase();
                    var t = title.toUpperCase();
                    var strRemove = '<BR><B>' + t + '</B><BR><IMG SRC="HTTP://MAPS.KGS.KU.EDU/CO2/IMAGES/' + lg + '.JPG">'.toUpperCase();
                    dojo.byId('mainlegenddiv').innerHTML = inHTML.replace(strRemove,"");
                }
            }
        }
	}


    function addLegend(title, legend) {
        if (title != 'none') {
            var strAdd = '<BR><B>' + title + '</B><BR><IMG src="http://maps.kgs.ku.edu/co2/images/' + legend + '.jpg" />' + dojo.byId("mainlegenddiv").innerHTML;
            dojo.byId("mainlegenddiv").innerHTML = strAdd;
        }
    }


	function changeOpacity(layers, opa) {
        var l = layers;

        if (typeof layers == "string") {
            l = app.map.getLayer(layers);
        }
		trans = (10 - opa)/10;
		l.setOpacity(trans);
    }


	function quickZoom(type, value, button) {
		findTask = new esri.tasks.FindTask("http://services.kgs.ku.edu/arcgis1/rest/services/co2/general/MapServer");

		findParams = new esri.tasks.FindParameters();
		findParams.returnGeometry = true;
		findParams.contains = false;

		switch (type) {
			case 'county':
				findParams.layerIds = [2];
				findParams.searchFields = ["county"];
				findParams.searchText = value;
				break;

			case 'field':
				findParams.layerIds = [1];

				if (button == 'return') {
					findParams.searchFields = ["field_kid"];
					findParams.searchText = value;
				}
				else {
					findParams.searchFields = ["field_name"];
					findParams.searchText = value;
				}

				fieldsLayer.show();
				dojo.byId('fields').checked = 'checked';
				break;

			case 'well':
				findParams.layerIds = [0];

				if (button == 'return') {
					findParams.searchFields = ["kid"];
					findParams.searchText = value;
				}
				else {
					var apiText = dojo.byId('api_state').value + "-" + dojo.byId('api_county').value + "-" + dojo.byId('api_number').value;

					if (dojo.byId('api_extension').value != "") {
						apiText = apiText + "-" + dojo.byId('api_extension').value;
					}

					findParams.searchFields = ["api_number"];
					findParams.searchText = apiText;
				}

				visibleWellLyr.show();
				///dojo.byId('wells').checked = 'checked';
				break;

			case 'plss':
				var plssText;

				if (button == 'return') {
					findParams.layerIds = [3];
					findParams.searchFields = ["s_r_t"];
					findParams.searchText = value;
				}
				else {
					// Format search string - if section is not specified search for township/range only (in different layer):
					if (dojo.byId('rng_dir_e').checked == true) {
						var rngDir = 'E';
					}
					else {
						var rngDir = 'W';
					}

					if (dojo.byId('sec').value != "") {
						plssText = 'S' + dojo.byId('sec').value + '-T' + dojo.byId('twn').value + 'S-R' + dojo.byId('rng').value + rngDir;
						findParams.layerIds = [3];
						findParams.searchFields = ["s_r_t"];
					}
					else {
						plssText = 'T' + dojo.byId('twn').value + 'S-R' + dojo.byId('rng').value + rngDir;
						findParams.layerIds = [4];
						findParams.searchFields = ["t_r"];
					}

					findParams.searchText = plssText;
				}
				break;
		}

		// Hide dialog box:
		dijit.byId('quickzoom').hide();

		// Execute task and zoom to feature:
		findTask.execute(findParams, function(fset) {
			zoomToResults(fset);
		});
	}


	function fullExtent() {
		//app.map.setExtent(initExtent);
		var pt = new esri.geometry.Point(-10997834, 4534450, sr);
		app.map.centerAndZoom(pt, 8);
	}


	function jumpFocus(nextField,chars,currField) {
		if (dojo.byId(currField).value.length == chars) {
			dojo.byId(nextField).focus();
		}
	}


	function filterWells(method) {

		var layerDef = [];
		var mExt = app.map.extent;

		if (label == 'leasewell') {
			lyrID = 5;
		}
		else if (label == 'api') {
			lyrID = 6;
		}
		else if (label == 'formation') {
			lyrID = 7;
		}
		else {
			lyrID = 0;
		}

		switch (method) {
			case 'off':
				layerDef[lyrID] = "";
				visibleWellLyr.setLayerDefinitions(layerDef);
				dojo.byId('filter_on').style.display = "none";
				filter = "off";
				break;

			case 'typewells_off':
				layerDef[lyrID] = "";
				visibleWellLyr.setLayerDefinitions(layerDef);
				dojo.byId('filter_on').style.display = "none";
				filter = "off";

				showLAS3Wells();
				break;

			case 'selected_field':
				if (filter != "selected_field") {
					filter = "selected_field";
				}

				if (currField == "") {
					// Show warning dialog box:
					dojo.byId('warning_msg').innerHTML = "Please select a field before using this tool.";
					dijit.byId('warning_box').show();
				}
				else {
					layerDef[lyrID] = "FIELD_KID = " + currField;
					visibleWellLyr.setLayerDefinitions(layerDef);
					dojo.byId('filter_on').style.display = "block";
					filter = "selected_field";
					dojo.byId('filter_msg').innerHTML = "Only showing wells assigned to the selected field ";
				}
				break;

			case 'scanned':
				app.map.graphics.clear();
				layerDef[lyrID] = "kid in (select well_header_kid from elog.scan_urls)";
				visibleWellLyr.setLayerDefinitions(layerDef);
				dojo.byId('filter_on').style.display = "block";
				filter = "scanned";
				dojo.byId('filter_msg').innerHTML = "Only showing wells with scanned logs ";
				break;

			case 'paper':
				app.map.graphics.clear();
				layerDef[lyrID] = "kid in (select well_header_kid from elog.log_headers)";
				visibleWellLyr.setLayerDefinitions(layerDef);
				dojo.byId('filter_on').style.display = "block";
				filter = "paper";
				dojo.byId('filter_msg').innerHTML = "Only showing wells with paper logs ";
				break;

			case 'cuttings':
				app.map.graphics.clear();
				layerDef[lyrID] = "kid in (select well_header_kid from cuttings.boxes)";
				visibleWellLyr.setLayerDefinitions(layerDef);
				dojo.byId('filter_on').style.display = "block";
				filter = "cuttings";
				dojo.byId('filter_msg').innerHTML = "Only showing wells with rotary cutting samples ";
				break;

			case 'cores':
				app.map.graphics.clear();
				layerDef[lyrID] = "kid in (select well_header_kid from core.core_headers)";
				visibleWellLyr.setLayerDefinitions(layerDef);
				dojo.byId('filter_on').style.display = "block";
				filter = "cores";
				dojo.byId('filter_msg').innerHTML = "Only showing wells with core samples ";
				break;

			case 'horiz':
				app.map.graphics.clear();
				layerDef[lyrID] = "substr(api_workovers, 1, 2) <> '00'";
				visibleWellLyr.setLayerDefinitions(layerDef);
				dojo.byId('filter_on').style.display = "block";
				filter = "horiz";
				dojo.byId('filter_msg').innerHTML = "Only showing horizontal wells ";
				break;

			case 'active_well':
				app.map.graphics.clear();
				layerDef[lyrID] = "status not like '%&A'";
				visibleWellLyr.setLayerDefinitions(layerDef);
				dojo.byId('filter_on').style.display = "block";
				filter = "active_well";
				dojo.byId('filter_msg').innerHTML = "Only showing active wells ";
				break;
			case 'las':
				app.map.graphics.clear();
				layerDef[lyrID] = "kid in (select well_header_kid from las.well_headers where proprietary = 0)";
				visibleWellLyr.setLayerDefinitions(layerDef);
				dojo.byId('filter_on').style.display = "block";
				filter = "las";
				dojo.byId('filter_msg').innerHTML = "Only showing wells with LAS files ";
				break;
			case 'regional':
				app.map.graphics.clear();
				layerDef[lyrID] = "kid in (select kid from doe_co2.all_project_wells_kid)";
				visibleWellLyr.setLayerDefinitions(layerDef);
				dojo.byId('filter_on').style.display = "block";
				filter = "regional";
				dojo.byId('filter_msg').innerHTML = "Only showing Key Regional Wells ";
				break;
			case 'precamb':
				app.map.graphics.clear();
				layerDef[lyrID] = "kid in (select kid from doe_co2.pre_camb_well_kid)";
				visibleWellLyr.setLayerDefinitions(layerDef);
				dojo.byId('filter_on').style.display = "block";
				filter = "precamb"
				dojo.byId('filter_msg').innerHTML = "Only showing Precambrian wells ";
				break;
			case 'supertype':
				app.map.graphics.clear();
				layerDef[lyrID] = "kid in (select kid from doe_co2.super_type_well_kid)";
				visibleWellLyr.setLayerDefinitions(layerDef);
				dojo.byId('filter_on').style.display = "block";
				filter = "supertype"
				dojo.byId('filter_msg').innerHTML = "Only showing Super Type wells ";
				break;
			case 'typewell':
				app.map.graphics.clear();
				layerDef[lyrID] = "kid in (select kid from doe_co2.type_well_global_kid)";
				visibleWellLyr.setLayerDefinitions(layerDef);
				dojo.byId('filter_on').style.display = "block";
				filter = "typewell"
				dojo.byId('filter_msg').innerHTML = "Only showing Type wells ";
				break;
			case 'show_monitoring':
				app.map.graphics.clear();
				layerDef[8] = "";
				wwc5Layer.setLayerDefinitions(layerDef);
				dojo.byId('wwc5_filter_on').style.display = "none";
				wwc5_filter = "off";
				break;
			case 'remove_monitoring':
				app.map.graphics.clear();
				layerDef[8] = "water_use_code not in (8,10,11,122,240,242,245)";
				wwc5Layer.setLayerDefinitions(layerDef);
				dojo.byId('wwc5_filter_on').style.display = "block";
				wwc5_filter = "remove_monitoring";
				dojo.byId('wwc5_filter_msg').innerHTML = "Water Wells: Monitoring/Engineering Wells Excluded";
				break;
			case 'wwc5_off':
				layerDef[8] = "";
				wwc5Layer.setLayerDefinitions(layerDef);
				dojo.byId('wwc5_filter_on').style.display = "none";
				wwc5_filter = "off";
				break;
			case 'las3':
				/*dijit.byId('las3').hide();
				dojo.byId('filter_on').style.display = "none";

				if (las3whereClause.charAt(las3whereClause.length - 2) == 'd') {
					// Slice off trailing "and ":
					las3whereClause = las3whereClause.slice(0, las3whereClause.length - 4);
				}

				app.map.graphics.clear();
				if (las3whereClause == "") {
					layerDef[lyrID] = "";
				} else {
					if (las3Count > 0) {
						layerDef[lyrID] = "kid in (select well_header_kid from las3.well_headers where " + las3whereClause + ")";
						dojo.byId('filter_msg').innerHTML = "Only showing wells with selected LAS 3 data types ";
						dojo.byId('filter_on').style.display = "block";
						filter = "las3";
					}
				}
				visibleWellLyr.setLayerDefinitions(layerDef);

				break;*/
				app.map.graphics.clear();
				layerDef[lyrID] = "kid in (select well_header_kid from iqstrat.doe_co2_las3)";
				dojo.byId('filter_msg').innerHTML = "Only showing wells with selected LAS 3 files ";
				dojo.byId('filter_on').style.display = "block";
				filter = "las3";
				visibleWellLyr.setLayerDefinitions(layerDef);
				break;
		}
	}


	function checkLAS3Count()
	{
		las3whereClause = "";

		if (dojo.byId('lasl').checked) {
			if (las3whereClause.search("L") == -1) {
				las3whereClause += "instr(data_types, 'L') > 0 and ";
			}
		} else {
			las3whereClause.replace("instr(data_types, 'L') > 0 and ", "");
		}

		if (dojo.byId('lasc').checked) {
			if (las3whereClause.search("C") == -1) {
				las3whereClause += "instr(data_types, 'C') > 0 and ";
			}
		} else {
			las3whereClause.replace("instr(data_types, 'C') > 0 and ", "");
		}

		if (dojo.byId('last').checked) {
			if (las3whereClause.search("T") == -1) {
				las3whereClause += "instr(data_types, 'T') > 0 and ";
			}
		} else {
			las3whereClause.replace("instr(data_types, 'T') > 0 and ", "");
		}

		if (dojo.byId('lasp').checked) {
			if (las3whereClause.search("P") == -1) {
				las3whereClause += "instr(data_types, 'P') > 0 and ";
			}
		} else {
			las3whereClause.replace("instr(data_types, 'P') > 0 and ", "");
		}

		if (dojo.byId('lasd').checked) {
			if (las3whereClause.search("D") == -1) {
				las3whereClause += "instr(data_types, 'D') > 0 and ";
			}
		} else {
			las3whereClause.replace("instr(data_types, 'D') > 0 and ", "");
		}

		if (dojo.byId('lass').checked) {
			if (las3whereClause.search("S") == -1) {
				las3whereClause += "instr(data_types, 'S') > 0 and ";
			}
		} else {
			las3whereClause.replace("instr(data_types, 'S') > 0 and ", "");
		}

		if (dojo.byId('lasf').checked) {
			if (las3whereClause.search("F") == -1) {
				las3whereClause += "instr(data_types, 'F') > 0 and ";
			}
		} else {
			las3whereClause.replace("instr(data_types, 'F') > 0 and ", "");
		}

		if (dojo.byId('lasg').checked) {
			if (las3whereClause.search("G") == -1) {
				las3whereClause += "instr(data_types, 'G') > 0 and ";
			}
		} else {
			las3whereClause.replace("instr(data_types, 'G') > 0 and ", "");
		}

		dojo.xhrGet( {
			url: 'las3_count.cfm?where=' + encodeURI(las3whereClause),
			handleAs: "text",
			load: function(response) {
				dojo.byId('las3_count_msg').innerHTML = "Number of wells matching criteria: " + response;
				las3Count = parseInt(response);
			},
			error: function(err) {
				alert(err);
			},
			timeout: 600000
		});
	}


	function setVisibleWellLayer(labelLyr) {
		visibleWellLyr.hide();

		switch (labelLyr) {
			case 'none':
				visibleWellLyr = wellsNoLabelLayer;
				label = 'none';
				break;

			case 'leasewell':
				visibleWellLyr = wellsLeaseWellLabelLayer;
				label = 'leasewell';
				break;

			case 'api':
				visibleWellLyr = wellsAPILabelLayer;
				label = 'api';
				break;

			case 'formation':
				visibleWellLyr = wellsFormationLabelLayer;
				label = 'formation';
				break;
		}

		filterWells(filter);
		visibleWellLyr.show();
	}


	function addXSectionPt()
	{
		if (currentKID != null) {
			if (dojo.byId('shelig').innerHTML == 'Hide') {
				xSectionKIDS.push(currentKID);

				// Update number selected text:
				//dojo.byId('numselected').innerHTML = xSectionKIDS.length;
				updateNumSelected();

				// Return geometery for highlighting:
				var qTask = new esri.tasks.QueryTask("http://services.kgs.ku.edu/arcgis1/rest/services/co2/general/MapServer/0");

				var query = new esri.tasks.Query;
				query.returnGeometry = true;
				query.where = "KID = " + currentKID;

				qTask.execute(query, function(fset) {
					app.map.graphics.clear();

					var sym = new esri.symbol.SimpleMarkerSymbol();
					sym.setOutline(new esri.symbol.SimpleLineSymbol(esri.symbol.SimpleLineSymbol.STYLE_SOLID, new dojo.Color([0,230,250]), 3));
					sym.size = 20;
					fset.features[0].setSymbol(sym);

					xSectionPointGraphics.add(fset.features[0]);

					// Store X,Y values for drawing line:
					xSectionXs.push(fset.features[0].geometry.x);
					xSectionYs.push(fset.features[0].geometry.y);

					currentKID = null;

					drawXSectionLine();
				});
			} else {
				alert('"Show Type Wells" must be selected before a well can be added to the cross-section list.');
			}
		}
	}


	function drawXSectionLine()
	{
		if (xSectionXs.length > 1)
		{
			// Create polyline geometry:
			var line = new esri.geometry.Polyline(new esri.SpatialReference( {wkid:102100} ));
			var coords = new Array();

			for (i=0; i<xSectionXs.length; i++)
			{
				coords.push([xSectionXs[i], xSectionYs[i]]);
			}

			line.addPath(coords);

			// Add polyline to graphics layer:
			var lineSym = new esri.symbol.SimpleLineSymbol(esri.symbol.SimpleLineSymbol.STYLE_SOLID, new dojo.Color([0,230,250]), 5);

			var xSectionLine = new esri.Graphic();
			xSectionLine.geometry = line;
			xSectionLine.setSymbol(lineSym);

			xSectionLineGraphics.add(xSectionLine);
		}
	}


	function removeLastXSectionPt()
	{
		// Remove last point:
		xSectionKIDS.pop();

		var kids = xSectionKIDS.toString();

		// Query remaining KIDs, clear all features from graphics layer, add remaining features back in:
		var qTask = new esri.tasks.QueryTask("http://services.kgs.ku.edu/arcgis1/rest/services/co2/general/MapServer/0");

		var query = new esri.tasks.Query;
		query.returnGeometry = true;
		query.where = "KID in (" + kids + ")";

		qTask.execute(query, function(fset) {
			xSectionPointGraphics.clear()

			var sym = new esri.symbol.SimpleMarkerSymbol();
			sym.setOutline(new esri.symbol.SimpleLineSymbol(esri.symbol.SimpleLineSymbol.STYLE_SOLID, new dojo.Color([0,230,250]), 3));
			sym.size = 20;

			dojo.forEach(fset.features, function(feature) {
				xSectionPointGraphics.add(feature.setSymbol(sym));
			});
        });

		//dojo.byId('numselected').innerHTML = xSectionKIDS.length;
		updateNumSelected();

		// Remove last coordinate from polyline array, clear line graphics, call draw function:
		xSectionXs.pop();
		xSectionYs.pop();

		xSectionLineGraphics.clear();

		drawXSectionLine();
	}


	function clearXSectionPts()
	{
		xSectionKIDS.length = 0;
		xSectionXs.length = 0;
		xSectionYs.length = 0;

		//dojo.byId('numselected').innerHTML = xSectionKIDS.length;
		updateNumSelected();

		xSectionPointGraphics.clear();
		xSectionLineGraphics.clear();
	}


	function createXSection()
	{
		var kidList = xSectionKIDS.toString();
		var xSectionURL = 'http://www.kgs.ku.edu/PRS/Ozark/GXSection/GXSection.html?sLIST=' + kidList;
		var xSectionWin = window.open(xSectionURL, '', '');
	}


	function updateNumSelected()
	{
		dojo.byId('numselected').innerHTML = xSectionKIDS.length;

		if (xSectionKIDS.length == 4) {
			dojo.byId('addwellbtn').disabled = true;
		} else {
			dojo.byId('addwellbtn').disabled = false;
		}
	}


	function expandList(list)
	{
		dojo.byId(list).style.display = (dojo.byId(list).style.display=='none')?'block':'none';

		var image = list + 'image';

		if (dojo.byId(list).style.display == 'block')
		{
			dojo.byId(image).src = 'images/minus.jpg';
		}
		else
		{
			dojo.byId(image).src = 'images/plus.jpg';
		}
	}


	function filterFields(horizon, attr) {
		app.map.graphics.clear();
		dijit.byId('fieldsdialog').hide();

		var lyrDef = [];

		switch (horizon) {
			case 'cretaceous':
				formationList = "('NIOBRARA')";
				break;
			case 'permian':
				formationList = "('ADMIRE','INDIAN CAVE SANDSTONE','WINFIELD','PERMIAN','CHASE GROUP','HERINGTON LIMESTONE','TOWANDA','KRIDER LIMESTONE','CHASE','FORT RILEY','COUNCIL GROVE','COTTONWOOD','NEVA','COUNCIL GROVE GROUP','RED EAGLE LIMESTONE')";
				break;
			case 'penn':
				formationList = "('PENNSYLVANIAN','PENN SAND','PENNSYLVANIAN SAND / H ZONE','PENN. CONGL.','CONGLOMERATE','PENNSYLVANIAN CONGLOMERATE SAND','CONGL.','PENN BASAL CONG','BASAL PENN.','MISSISSIPPIAN CHERT CONGLOMERATE','CONGLOMERATE SAND')";
				break;
			case 'upperpenn':
				formationList = "('LANSING','DENNIS LIMESTONE (J ZONE)','LANSING-KANSAS CITY E ZONE','LANSING-KANSAS CITY A ZONE','LANSING-KANSAS CITY','LANSING B ZONE','KANSAS CITY','LANSING-KANSAS CITY ZONE-E (GAS)','LANSING-KANSAS CITY GROUP','DENNIS LIMESTONE','HERTHA LIMESTONE',";
				formationList += "'LANSING KANSAS CITY','LANSING: 40','LANSING-KANSAS CITY (H','KANSAS CITY (DRUM)','KANSAS CITY: H-ZONE','KANSAS CITY DRUM','LANSING-KANSAS CITY D','LANSING-KANSAS CITY K ZONE','CLEVELAND','PLEASANTON','KNOBTOWN','HEPLER','IMMEDIATELY BELOW THE KC BASE','EXLINE LIMESTONE / PLEASANTON GROUP',";
				formationList += "'LAYTON','WABAUNSEE','TARKIO SAND','WABAUNSEE - HOWARD LIMESTONE','TARKIO','LANGDON','WILLARD','SEVERY','HOWARD','WABAUNSEE GROUP','WHITE CLOUD','EMPORIA LIMESTONE','SHAWNEE GROUP','SYNDERVILLE SAND','ELGIN SAND','TOPEKA','TORONTO LIMESTONE','ELGIN','HOOVER','SHAWNEE',";
				formationList += "'LEAVENWORTH','TORONTO','LANSING-KANSAS CITY ZONE-E (GAS)')";
				break;
			case 'midpenn':
				formationList = "('MARMATON','BANDERA QUARRY','PERU','WAYSIDE','GORHAM','FORT SCOTT','WEISER','PENNSYLVANIAN MARMATON GROUP','PERRY GAS SAND','MARMATON GROUP','PAWNEE','OSWEGO','UPPER ALTAMONT','LOWER PAWNEE','MARMATON: PAWNEE & FORT SCOTT FORMATIONS','BARTLESVILLE','BEVIER COAL','BURGESS',";
				formationList += "'CATTLEMAN','CHEROKEE','CHEROKEE (JOHNSON ZONE)','CHEROKEE COALS','CHEROKEE LIME','COAL','CHEROKEE SAND','JOHNSON','JOHNSON ZONE','MCLOUTH','MULKY COAL','NEW ALBANY','PRUE','SQUIRREL','SUMMIT COAL','UPPER MCCLOUTH SANDSTONE','WEIR-PITT COAL','ATOKAN','ATOKA','ATOKAN SAND (BASAL PENNSYLVANIAN)')";
				break;
			case 'lowpenn':
				formationList = "('MORROWAN','LOWER MORROW','PENNSYLVANIAN MORROWAN SANDSTONE','LOWER MORROW (KEYES)','KEARNY FORMATION (PURDY SANDSTONE)','MORROW','UPPER MORROW SANDSTONE','KEYES SANDSTONE','MORROWAN SANDSTONE')";
				break;
			case 'missdevonian':
				formationList = "('CHESTERAN','CHESTERAN LIMESTONE','MISSISSIPPIAN','MISSISSIPPIAN (SPERGEN DOLOMITE)','MISSISSIPPIAN (ST. LOUIS)','MISSISSIPPIAN - MERAMEC','MISSISSIPPIAN - St. LOUIS','MISSISSIPPIAN CHERT (Chat" + "\"" + ")" + "\"" + "','MISSISSIPPIAN CHESTER SANDSTONE','MISSISSIPPIAN CHESTER SERIES',";
				formationList += "'MISSISSIPPIAN LIMESTONE','MISSISSIPPIAN MERAMECIAN (ST. LOUIS)','MISSISSIPPIAN OSAGE','MISSISSIPPIAN SPERGEN DOLOMITE (C ZONE)','MISSISSIPPIAN ST. LOUIS FORMATION','OSAGIAN','PENN.-MISS.','SPERGEN','ST. LOUIS','WARSAW','MISSISSIPPIAN STE. GENEVIEVE LIMESTONE','ST. GENEVIEVE',";
				formationList += "'KINDERHOOKIAN','KINDERHOOK','MISENER','HUNTON')";
				break;
			case 'upperord':
				formationList = "('MAQUOKETA','VIOLA','VIOLA-SIMPSON')";
				break;
			case 'lowerord':
				formationList = "('SIMPSON','SIMPSON SAND (ST. PETER)','ARBUCKLE','ORDOVICIAN','REAGAN','GRANITE WASH','CAMBRIAN','SIMPSON SAND (ST. PETER)')";
				break;
		}

		if (horizon == 'all') {
			clearFieldFilter();
		} else {
			lyrDef[0] = "field_kid in (select field_kid from nomenclature.fields_reservoirs where upper(formation_name) in " + formationList + ")";
		}

		fieldsFilterRenderLayer.setLayerDefinitions(lyrDef);
		dojo.byId('field_filter_on').style.display = "block";
		dojo.byId('field_filter_msg').innerHTML = "Field filter/classification is on ";
		fieldFilt = 'on';
		dojo.byId('fields').checked = 'checked';
		fieldsLayer.hide();
		fieldsFilterRenderLayer.show();

		classBreaks(attr,formationList, horizon);

		showStaticLegend(horizon,attr);
	}

	function clearFieldFilter() {
		dijit.byId('fieldsdialog').hide();

		var lyrDef = [];

		lyrDef[0] = "";
		fieldsFilterRenderLayer.setLayerDefinitions(lyrDef);
		dojo.byId('field_filter_on').style.display = "none";

		fieldFilt = 'off';

		fieldsLayer.show();
		fieldsFilterRenderLayer.hide();

		dojo.byId('dynamiclegenddiv').innerHTML = '';
	}


	function classBreaks(attr,formationList,horizon) {
		var depthElevAttr = '';

		switch (attr) {
			case 'AVGDEPTH':
				// blue 2:
				var c1 = "##BEE8FF";
				var c2 = "##08519C";

				switch (horizon) {
					case 'cretaceous':
						depthElevAttr = 'cret_dpth';
						break;
					case 'permian':
						depthElevAttr = 'perm_dpth';
						break;
					case 'penn':
						depthElevAttr = 'penn_dpth';
						break;
					case 'upperpenn':
						depthElevAttr = 'upenn_dpth';
						break;
					case 'midpenn':
						depthElevAttr = 'mpenn_dpth';
						break;
					case 'lowpenn':
						depthElevAttr = 'lpenn_dpth';
						break;
					case 'missdevonian':
						depthElevAttr = 'misdv_dpth';
						break;
					case 'upperord':
						depthElevAttr = 'uord_dpth';
						break;
					case 'lowerord':
						depthElevAttr = 'lord_dpth';
						break;
				}
				break;
			case 'CUMM_OIL':
				// brown 3 umber:
				var c1 = "##FFFFBE";
				var c2 = "##734C00";
				break;
			case 'ELEVSL':
				// purple:
				var c1 = "##54278F";
				var c2 = "##F2F0F7";

				switch (horizon) {
					case 'cretaceous':
						depthElevAttr = 'cret_elev';
						break;
					case 'permian':
						depthElevAttr = 'perm_elev';
						break;
					case 'penn':
						depthElevAttr = 'penn_elev';
						break;
					case 'upperpenn':
						depthElevAttr = 'upenn_elev';
						break;
					case 'midpenn':
						depthElevAttr = 'mpenn_elev';
						break;
					case 'lowpenn':
						depthElevAttr = 'lpenn_elev';
						break;
					case 'missdevonian':
						depthElevAttr = 'misdv_elev';
						break;
					case 'upperord':
						depthElevAttr = 'uord_elev';
						break;
					case 'lowerord':
						depthElevAttr = 'lord_elev';
						break;
				}
				break;
			case 'CUMM_GAS':
				// red 2 orange:
				var c1 = "##FFFFBE";
				var c2 = "##FF0000";
				break;
			/*other colors
				// green:
				var c1 = "##EDF8E9";
				var c2 = "##006D2C";
				// esri yellow to green:
				var c1 = "##FFFFCC";
				var c2 = "##006837";
				// gray:
				var c1 = "##F7F7F7";
				var c2 = "##252525";
				*/
				// brown:
				/*var c1 = "##FEEDDE";
				var c2 = "##A63603";*/
				// different brown:
				/*var c1 = "##FFEBAF";
				var c2 = "##734C00";*/
				// red:
				/*var c1 = "##FFBEBE";
				var c2 = "##E60000";*/
				// blue:
				/*var c1 = "##EFF3FF";
				var c2 = "##08519C";*/
		}

        var classDef = new esri.tasks.ClassBreaksDefinition();
		if (depthElevAttr == '') {
			depthElevAttr = attr;
		}
		classDef.classificationField = depthElevAttr;
        classDef.classificationMethod = "natural-breaks";
        classDef.breakCount = 5;

        var colorRamp = new esri.tasks.AlgorithmicColorRamp();
        colorRamp.fromColor = new dojo.colorFromHex(c1);
        colorRamp.toColor = new dojo.colorFromHex(c2);
        colorRamp.algorithm = "hsv";

		classDef.baseSymbol = new esri.symbol.SimpleFillSymbol("solid", new esri.symbol.SimpleLineSymbol(esri.symbol.SimpleLineSymbol.STYLE_SOLID, new dojo.Color([0,0,0]), 1), null);
        classDef.colorRamp = colorRamp;

        var params = new esri.tasks.GenerateRendererParameters();
        params.classificationDefinition = classDef;
		if (formationList != '') {
			params.where = "field_kid in (select field_kid from nomenclature.fields_reservoirs where upper(formation_name) in " + formationList + ")";
		}

        var generateRenderer = new esri.tasks.GenerateRendererTask(app.rendererDataUrl);
		generateRenderer.execute(params, applyRenderer, rendererError);
      }


	function applyRenderer(renderer) {
        var optionsArray = [];
        var drawingOptions = new esri.layers.LayerDrawingOptions();
        drawingOptions.renderer = renderer;
        optionsArray[0] = drawingOptions;
        app.map.getLayer("og_fields_render").setLayerDrawingOptions(optionsArray);

        /*if ( ! app.hasOwnProperty("legend") ) {
          createLegend();
        }*/
      }


	function createLegend() {
        app.legend = new esri.dijit.Legend({
          map : app.map,
		  autoUpdate:true,
		  respectCurrentMapScale:false,
          layerInfos : [ {
			layer:fieldsFilterRenderLayer,
            title : "Title Goes Here"
          } ]
        }, dojo.byId("dynamiclegenddiv"));
        app.legend.startup();
      }


	function rendererError(err) {
        console.log("error: ", dojo.toJson(err));
      }


	function showStaticLegend(horizon,attr) {
		var title, subTitle;

		switch (attr) {
			case 'CUMM_OIL':
				subTitle = '<br />Cumulative Oil Production (bbl)';
				break;
			case 'CUMM_GAS':
				subTitle = '<br />Cumulative Gas Production (mcf)';
				break;
			case 'AVGDEPTH':
				subTitle = '<br />Average Depth (ft)';
				break;
		}

		switch (horizon) {
			case 'all':
				title = subTitle;
				break;
			case 'cretaceous':
				title = '<b>Cretaceous Fields</b>' + subTitle;
				break;
			case 'permian':
				title = '<b>Permian Fields</b>' + subTitle;
				break;
			case 'penn':
				title = '<b>Pennslyvanian Fields</b>' + subTitle;
				break;
			case 'upperpenn':
				title = '<b>Upper Pennslyvanian Fields</b>' + subTitle;
				break;
			case 'midpenn':
				title = '<b>Middle Pennslyvanian Fields</b>' + subTitle;
				break;
			case 'lowpenn':
				title = '<b>Lower Pennslyvanian Fields</b>' + subTitle;
				break;
			case 'missdevonian':
				title = '<b>Mississippian & Devonian Fields</b>' + subTitle;
				break;
			case 'upperord':
				title = '<b>Upper Ordovician Fields</b>' + subTitle;
				break;
			case 'lowerord':
				title = '<b>Lower Ordovivian & Cambrian Fields</b>' + subTitle;
				break;
		}

		var legendHTML = title + '<br />';
		legendHTML += '<img src="images/field_legends/' + horizon + '_' + attr + '.png" />';
		dojo.byId('dynamiclegenddiv').innerHTML = legendHTML;
	}


	function showLAS3Wells() {
		var layerDef = [];

			if (label == 'leasewell') {
				lyrID = 5;
			}
			else if (label == 'api') {
				lyrID = 6;
			}
			else if (label == 'formation') {
				lyrID = 7;
			}
			else {
				lyrID = 0;
			}

		if (dojo.byId('shelig').innerHTML == 'Hide') {
			dojo.byId('typewells').checked = '';
			///dojo.byId('wells').checked = 'checked';
			eligibleWellsGraphics.clear();
			dojo.byId('shelig').innerHTML = 'Show';
			layerDef[lyrID] = "";
			visibleWellLyr.setLayerDefinitions(layerDef);
			dojo.byId('filter_on').style.display = "none";

			switch (visibleWellLyr) {
				case wellsNoLabelLayer:
					layer = wellsNoLabelLayer;
					break;

				case wellsLeaseWellLabelLayer:
					layer = wellsLeaseWellLabelLayer;
					break;

				case wellsAPILabelLayer:
					layer = wellsAPILabelLayer;
					break;

				case wellsFormationLabelLayer:
					layer = wellsFormationLabelLayer;
					break;
			}
			layer.show();
			typeWellsLayer.hide();
		}
		else {
			dojo.byId('typewells').checked = 'checked';

			layerDef[lyrID] = "kid in (select well_header_kid from iqstrat.doe_co2_las3)";
			visibleWellLyr.setLayerDefinitions(layerDef);
			dojo.byId('filter_on').style.display = "block";
			dojo.byId('shelig').innerHTML = 'Hide';
			filter = "las3";
			dojo.byId('filter_msg').innerHTML = "Only showing Type Wells ";

			typeWellsLayer.show();
		}
	}


	function printPDF() {
		var printUrl = 'http://services.kgs.ku.edu/arcgis1/rest/services/Utilities/PrintingTools/GPServer/Export%20Web%20Map%20Task';
		var printTask = new esri.tasks.PrintTask(printUrl);
        var printParams = new esri.tasks.PrintParameters();
        var template = new esri.tasks.PrintTemplate();
		var w, h;

		var theExt = esri.geometry.webMercatorToGeographic(app.map.extent);
		if (theExt.xmin > -96) {
			var theSR = 3159;
		} else if (theExt.xmin > -102 && theExt.xmin < 96) {
			var theSR = 3158;
		} else if (theExt.xmin < 102) {
			var theSR = 2957;
		}
		var printOutSr = new esri.SpatialReference({ wkid:theSR });

		/*if (dojo.byId('plss').checked) {
			plssLayer.hide();
			app.map.addLayer(plssDynLayer);
			plssDynLayer.show();
		}*/

		title = dojo.byId("pdftitle2").value;

		if (dojo.byId('portrait2').checked) {
			var layout = "Letter ANSI A Portrait";
		} else {
			var layout = "Letter ANSI A Landscape";
		}

		dijit.byId('printdialog2').hide();
		dojo.byId('printing_div').style.display = "block";

		if (dojo.byId('maponly').checked) {
			layout = 'MAP_ONLY';
			format = 'JPG';

			if (dojo.byId('portrait2').checked) {
				w = 600;
				h = 960;
			} else {
				w = 960;
				h = 600;
			}

			template.exportOptions = {
  				width: w,
  				height: h,
  				dpi: 96
			};
		} else {
			format = 'PDF';
		}

        template.layout = layout;
		template.format = format;
        template.preserveScale = true;
		template.showAttribution = false;
		template.layoutOptions = {
			scalebarUnit: "Miles",
			titleText: title,
			authorText: "Kansas Geological Survey",
			copyrightText: "http://maps.kgs.ku.edu/co2",
			legendLayers: []
		};

		printParams.map = app.map;
		printParams.outSpatialReference = printOutSr;
        printParams.template = template;

        printTask.execute(printParams, printResult, printError);
	}

	function printResult(result){
		dojo.byId('printing_div').style.display = "none";
		window.open(result.url);

		/*if (dojo.byId('plss').checked) {
			plssDynLayer.hide();
			app.map.removeLayer(plssDynLayer);
			plssLayer.show();
		}*/
    }

    function printError(result){
        console.log(result);
    }

    function filterQuakes(year, mag) {
        var nextYear = parseInt(year) + 1;
        var def = [];

        if (year !== "all") {
            if (mag !== "all") {
                def[19] = "the_date >= to_date('" + year + "-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS') and the_date < to_date('" + nextYear + "-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS') and mag >=" + mag;
            } else {
                def[19] = "the_date >= to_date('" + year + "-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS') and the_date < to_date('" + nextYear + "-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS') and mag >= 2";
            }
        } else {
            if (mag !== "all") {
                def[19] = " mag >=" + mag;
            } else {
                def[19] = "";
            }
        }

        earthquakesLayer.setLayerDefinitions(def);
    }

    function wellingtonFilterQuakes(year, mag) {
        var nextYear = parseInt(year) + 1;
        var def = [];

        if (year !== "all") {
            if (mag !== "all") {
                def[20] = "event >= to_date('" + year + "-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS') and event < to_date('" + nextYear + "-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS') and moment_mag >=" + mag;
            } else {
                def[20] = "event >= to_date('" + year + "-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS') and event < to_date('" + nextYear + "-01-01 00:00:00','YYYY-MM-DD HH24:MI:SS')";
            }
        } else {
            if (mag !== "all") {
                def[20] = " moment_mag >=" + mag;
            } else {
                def[20] = "";
            }
        }
        wellingtonEarthquakesLayer.setLayerDefinitions(def);
    }

    function filterQuakesDays(days) {
        var def = [];

        if (days !== "all") {
            def[19] = "sysdate - the_date <= " + days + " and mag >= 2";
        } else {
            def[19] = "";
        }
        earthquakesLayer.setLayerDefinitions(def);
    }

    function wellingtonFilterQuakesDays(days) {
        var def = [];

        if (days !== "all") {
            def[20] = "sysdate - event <= " + days;
        } else {
            def[20] = "";
        }
        wellingtonEarthquakesLayer.setLayerDefinitions(def);
    }

    function filterQuakesRecent() {
    	var def = [];
    	def[19] = "state = 'KS' and mag >= 2 and the_date = (select max(the_date) from earthquakes where state = 'KS' and mag >= 2)";
    	earthquakesLayer.setLayerDefinitions(def);
    }

    function wellingtonFilterQuakesRecent() {
    	var def = [];
    	def[20] = "latitude >= 37 and event = (select max(event) from earthquakes_wellington where latitude >= 37)";
    	wellingtonEarthquakesLayer.setLayerDefinitions(def);
    }

    function clearQuakeFilter() {
        var def = [];
        def = "";
        earthquakesLayer.setLayerDefinitions(def);
        days.options[0].selected="selected";
        mag.options[0].selected="selected";
        year.options[0].selected="selected";
    }

    function wellingtonClearQuakeFilter() {
        var def = [];
        def = "";
        wellingtonEarthquakesLayer.setLayerDefinitions(def);
        wellingtondays.options[0].selected="selected";
        wellingtonmag.options[0].selected="selected";
        wellingtonyear.options[0].selected="selected";
    }


	function zoomToLatLong(lat,lon,datum) {
		var gsvc = new esri.tasks.GeometryService("http://services.kgs.ku.edu/arcgis2/rest/services/Utilities/Geometry/GeometryServer");
		var params = new esri.tasks.ProjectParameters();
		var wgs84Sr = new esri.SpatialReference( { wkid: 4326 } );

		if (lon > 0) {
			lon = 0 - lon;
		}

		switch (datum) {
			case "nad27":
				var srId = 4267;
				break;
			case "nad83":
				var srId = 4269;
				break;
			case "wgs84":
				var srId = 4326;
				break;
		}

		var p = new esri.geometry.Point(lon, lat, new esri.SpatialReference( { wkid: srId } ) );
		params.geometries = [p];
		params.outSR = wgs84Sr;

		gsvc.project(params, function(features) {
			var pt84 = new esri.geometry.Point(features[0].x, features[0].y, wgs84Sr);

			var wmPt = esri.geometry.geographicToWebMercator(pt84);

			var ptSymbol = new esri.symbol.SimpleMarkerSymbol();
			ptSymbol.setStyle(esri.symbol.SimpleMarkerSymbol.STYLE_X);
			ptSymbol.setOutline(new esri.symbol.SimpleLineSymbol(esri.symbol.SimpleLineSymbol.STYLE_SOLID, new dojo.Color([255,0,0]), 3));
			ptSymbol.size = 20;

			app.map.graphics.clear();
			var graphic = new esri.Graphic(wmPt,ptSymbol);
			app.map.graphics.add(graphic);
			app.map.centerAndZoom(wmPt, 16);
		} );
	}

</script>

<script type="text/javascript">

  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-25612728-1']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();

</script>

</head>

<body class="soria">

<div id="loading">
	<div id="loading_msg">Loading...</div>
	<div id="loading_img" style="visibility: hidden;">
		<img src="images/loadingAnimation.gif" alt="Loading">
	</div>
</div>

<!-- Topmost container: -->
<div id="mainWindow" dojotype="dijit.layout.BorderContainer" design="headline" gutters="false" style="width:100%; height:100%;">

	<!--Header: -->
	<div id="header" dojotype="dijit.layout.ContentPane" region="top" >
		<div style="padding:5px; font:normal normal bold 18px Arial; color:##FFFF66;">
        	#application.title#
        	<span id="kgs" style="font-weight:normal; font-size:12px; position:fixed; right:55px; padding-top:2px;">Kansas Geological Survey</span>
        </div>
        <div id="toolbar">
        	<span class="tool_link" onclick="fullExtent();">Study Area</span> &nbsp;|&nbsp;
            <span class="tool_link" onclick="dijit.byId('quickzoom').show();">Zoom to Location</span>&nbsp;|&nbsp;
            <span class="tool_link" id="filter">Filter Wells</span>&nbsp;|&nbsp;
            <span class="tool_link" id="label">Label Wells</span>&nbsp;|&nbsp;
            <span class="tool_link" onclick="checkDownload();">Download Wells</span>&nbsp;|&nbsp;
            <span class="tool_link" onclick="dijit.byId('fieldsdialog').show();">Filter Fields</span>&nbsp;|&nbsp;
            <span class="tool_link" onclick="dijit.byId('printdialog2').show();">Print to PDF</span>&nbsp;|&nbsp;
            <span class="tool_link" onclick="app.map.graphics.clear();">Clear Highlight</span>&nbsp;|&nbsp;
            <a class="tool_link" href="help.cfm" target="_blank">Help</a>
       	</div>
	</div>

	<!-- Center container: -->
	<div id="map_div" dojotype="dijit.layout.ContentPane" region="center" style="background-color:white;"></div>

	<!-- Right container: -->
	<div dojotype="dijit.layout.ContentPane" region="right" id="sidebar" style="width:260px;border-left: medium solid ##0013AA;">
		<div id="mainTabContainer" class="mainTab" dojoType="dijit.layout.TabContainer" >
            <div id="layersTab" dojoType="dijit.layout.ContentPane" title="Layers">
                <table>
                <tr><td style="font-weight:bold">Layer</td><td style="font-weight:bold">Transparency</td></tr>
                <tr>
                    <td colspan="2"><input type="checkbox" id="typewells" onClick="showLAS3Wells();" checked>Type Wells&nbsp;&nbsp;<img src="images/green_dot.png" style="vertical-align:middle"></td>
                </tr>
                <tr>
                    <td><input type="checkbox" id="wells" onClick="changeMap('wells',this,'blank','none');" checked><span id="ogwells_txt"></span></td>
                    <td></td>
                </tr>

                <tr>
                    <td colspan="2"><input type="checkbox" id="class1wells" onClick="changeMap(class1WellsLayer,this,'red_tri','Class I Wells');">Class I Injection Wells</td>
                </tr>
                <tr>
                    <td colspan="2"><input type="checkbox" id="class2wells" onClick="changeMap(class2WellsLayer,this,'blue_tri','Class II Wells');">Class II Injection Wells</td>
                </tr>

                <tr><td colspan="2"><hr /></td></tr>

                <tr><td colspan="2">Earthquakes</td></tr>
                <tr>
                    <td colspan="2"><input type="checkbox" id="earthquakes" onClick="changeMap(earthquakesLayer,this,'usgsearthquakes','USGS Array Earthquakes');">USGS Array >2.0 &nbsp;&nbsp; <span style="text-decoration:underline;cursor:pointer;font-size:12px;" onclick="dijit.byId('quakefilter').show();">Filter</span>&nbsp;&nbsp;&nbsp;<span style="text-decoration:underline;cursor:pointer;font-size:12px;" onclick="dijit.byId('usgsquakenotes').show();">Read Me</span></td>
                </tr>

                <!---<tr>
                    <td colspan="2"><input type="checkbox" id="wellingtonearthquakes" onClick="changeMap(wellingtonEarthquakesLayer,this,'wellingtonearthquakes3','Wellington Array Earthquakes');">Wellington Array &nbsp;&nbsp; <span style="text-decoration:underline;cursor:pointer;font-size:12px;" onclick="dijit.byId('wellingtonquakefilter').show();">Filter</span>&nbsp;&nbsp;&nbsp;<span style="text-decoration:underline;cursor:pointer;font-size:12px;" onclick="dijit.byId('wellingtonquakenotes').show();">Read Me</span></td>
                </tr>--->

                <tr><td colspan="2"><hr /></td></tr>

                <tr>
                    <td colspan="2"><input type="checkbox" id="pclitho" onClick="changeMap(pcLithoLayer,this,'pc_lithology','Precambrian Basement Lithology');">Precambrian Basement Lithology</td>
                </tr>

                <tr>
                    <td colspan="2"><input type="checkbox" id="hrzwells" onClick="changeMap(hrzWellsLayer,this,'blank','none');">Horizontal Wells since 2010&nbsp;&nbsp;<img src="images/black_square.jpg" style="vertical-align:middle"></td>
                </tr>

                <tr>
                    <td nowrap="nowrap"><input type="checkbox" id="wwc5" onClick="changeMap(wwc5Layer,this,'blank','none');"><span id="wwc5_txt"></span></td>
                    <td></td>
                </tr>
                <tr>
                    <td colspan="2"><input type="checkbox" id="modelareas" onClick="changeMap(modelAreasLayer,this,'blank','none');" checked>Modeling Areas</td>
                </tr>
                <tr>
                    <td><input type="checkbox" id="plss" onClick="changeMap(plssLayer,this,'blank','none');" checked><span id="plss_txt"></span></td>
                    <td>
                        <div id="horizontalSlider_plss" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                            intermediateChanges="true" style="width:75px"
                            onChange="dojo.byId('horizontalSlider_plss').value = arguments[0];changeOpacity(plssLayer,dojo.byId('horizontalSlider_plss').value);">
                        </div>
                    </td>
                </tr>
                <tr>
                    <td><input type="checkbox" id="fields" onClick="changeMap(fieldsLayer,this,'blank','none');" >Oil & Gas Fields</td>
                    <td>
                        <div id="horizontalSlider_fields" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                            intermediateChanges="true" style="width:75px"
                            onChange="dojo.byId('horizontalSlider_fields').value = arguments[0];changeOpacity(fieldsLayer,dojo.byId('horizontalSlider_fields').value);">
                        </div>
                    </td>
                </tr>
                <tr>
                    <td><input type="checkbox" id="drg" onClick="changeMap(drgLayer,this,'blank','none');">Topographic Map</td>
                    <td>
                        <div id="horizontalSlider_drg" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                            intermediateChanges="true" style="width:75px"
                            onChange="dojo.byId('horizontalSlider_drg').value = arguments[0];changeOpacity(drgLayer,dojo.byId('horizontalSlider_drg').value);">
                        </div>
                    </td>
                </tr>
                <tr>
                    <td><input type="checkbox" id="naip12" onClick="changeMap(naipLayer,this,'blank','none');">2014 Aerials</td>
                    <td>
                        <div id="horizontalSlider_naip12" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                            intermediateChanges="true" style="width:75px"
                            onChange="dojo.byId('horizontalSlider_naip12').value = arguments[0];changeOpacity(naipLayer,dojo.byId('horizontalSlider_naip12').value);">
                        </div>
                    </td>
                </tr>
                <tr>
                    <td><input type="checkbox" id="ned" onClick="changeMap(nedLayer,this,'blank','none');">Nat. Elev. Dataset</span></td>
                    <td>
                        <div id="horizontalSlider_ned" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                            intermediateChanges="true" style="width:75px"
                            onChange="dojo.byId('horizontalSlider_ned').value = arguments[0];changeOpacity(nedLayer,dojo.byId('horizontalSlider_ned').value);">
                        </div>
                    </td>
                </tr>

                <tr>
                    <td><input type="checkbox" id="base" onClick="changeMap(baseLayer,this,'blank','none');" checked>Base map</td>
                    <td>
                        <div id="horizontalSlider_base" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                            intermediateChanges="true" style="width:75px"
                            onChange="dojo.byId('horizontalSlider_base').value = arguments[0];changeOpacity(baseLayer,dojo.byId('horizontalSlider_base').value);">
                        </div>
                    </td>
                </tr>

                <tr><td class="note" id="vis_msg" colspan="2">* Layer not visible at all scales</td></tr>

				<tr><td colspan="2"><hr /></td></tr>

                <tr>
                	<td><input type="checkbox" id="p10" onClick="changeMap(p10Layer,this,'p10_legend','CO2 P10 Storage Est. (tons/100 sq km)');">P10 Storage Est.</td>
                    <td>
                        <div id="horizontalSlider_p10" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                            intermediateChanges="true" style="width:75px"
                            onChange="dojo.byId('horizontalSlider_p10').value = arguments[0];changeOpacity(p10Layer,dojo.byId('horizontalSlider_p10').value);">
                        </div>
                    </td>
                </tr>

                <tr>
                	<td><input type="checkbox" id="p90" onClick="changeMap(p90Layer,this,'p90_legend','CO2 P90 Storage Est. (tons/100 sq km)');">P90 Storage Est.</td>
                    <td>
                        <div id="horizontalSlider_p90" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                            intermediateChanges="true" style="width:75px"
                            onChange="dojo.byId('horizontalSlider_p90').value = arguments[0];changeOpacity(p90Layer,dojo.byId('horizontalSlider_p90').value);">
                        </div>
                    </td>
                </tr>

                <!-- old layer picker: -->
				<!--<tr><td><span style="font:normal normal bold 11px arial;text-decoration:underline;cursor:pointer;" onclick="javascript:animateDiv('open');">Geologic Base Layers</span></td></tr>-->

                <!-- new layer picker: -->
                <tr><td><span style="font:normal normal bold 11px arial;text-decoration:underline;cursor:pointer;" onclick="dijit.byId('geollayerpicker').show();">Geologic Base Layers</span></td></tr>


                </table>

                <!--<div id="ovmap_div"></div>-->
            </div>

            <div class="tab" id="infoTab" dojoType="dijit.layout.ContentPane" title="Info">Click on a well or field to display information.</div>

            <div class="tab" id="legendTab" dojoType="dijit.layout.ContentPane" title="Legend">
            	<div id="dynamiclegenddiv"></div>
                <div id="mainlegenddiv"></div>
                <hr>
                <img src="images/well_sym.jpg" />
            </div>
        </div>
	</div>

	<!-- Footer: -->
	<div id="bottom" dojotype="dijit.layout.ContentPane" region="bottom" style="height:23px;">
		<div id="footer">
			<div preload="true" dojoType="dijit.layout.ContentPane" id="filter_on" style="background-color:##FF0000; display:none; text-align:left; width:33%; position:fixed; left:0px">
				<span id="filter_msg" style="color:##000000;font:normal normal bold 12px Arial;padding-left:3px"></span>
				<button class="label" onclick="filterWells('typewells_off');" style="text-align:center;z-index:26">Remove Filter</button>
			</div>
            <div preload="true" dojoType="dijit.layout.ContentPane" id="field_filter_on" style="background-color:##00FFCC; display:none; text-align:left; width:33%; position:fixed; left:33.5%">
				<span id="field_filter_msg" style="color:##000000;font:normal normal bold 12px Arial;padding-left:3px"></span>
				<button class="label" onclick="clearFieldFilter();" style="text-align:center;z-index:26">Show All Fields</button>
			</div>
            <div preload="true" dojoType="dijit.layout.ContentPane" id="wwc5_filter_on" style="background-color:##00FFFF; display:none; text-align:left; width:33%; position:fixed; right:0px">
				<span id="wwc5_filter_msg" style="color:##000000;font:normal normal bold 12px Arial;padding-left:3px">WWC5</span>
				<button class="label" onclick="filterWells('wwc5_off');" style="text-align:center;z-index:26">Show All Water Wells</button>
			</div>
            <div id="junk"></div>
		</div>
	</div>
</div>

<!-- Quick zoom dialog box: -->
<div class="dialog" dojoType="dijit.Dialog" id="quickzoom" title="Zoom to Location" style="text-align:center;font:normal normal bold 14px arial">
    <table>
    <tr>
        <td class="label">Township: </td>
        <td>
            <select id="twn">
                <option value=""></option>
                <cfloop index="i" from="1" to="35">
                    <option value="#i#">#i#</option>
                </cfloop>
            </select>
        </td>
        <td class="label" style="text-align:left">South</td>
    </tr>
    <tr>
        <td class="label">Range: </td>
        <td>
            <select id="rng">
                <option value=""></option>
                <cfloop index="j" from="1" to="43">
                    <option value="#j#">#j#</option>
                </cfloop>
            </select>
        </td>
        <td class="label">East:<input type="radio" name="rng_dir" id="rng_dir_e" value="E" /> or West:<input type="radio" name="rng_dir" id="rng_dir_w" value="W" checked="checked" /></td>
    </tr>
    <tr>
        <td class="label">Section: </td>
        <td>
            <select id="sec">
                <option value=""></option>
                <cfloop index="k" from="1" to="36">
                    <option value="#k#">#k#</option>
                </cfloop>
            </select>
        </td>
    </tr>
    <tr><td></td><td><button class="label" onclick="quickZoom('plss');">Go</button></td></tr>
    </table>

    <div id="or"><img src="images/or.jpg" /></div>
    <table>
    	<tr><td class="label" align="right">Latitude: </td><td align="left"><input type="text" id="latitude" size="10" /><span class="note" style="font-weight:normal">&nbsp;(ex. 39.12345)</span></td></tr>
        <tr><td class="label" align="right">Longitude: </td><td align="left"><input type="text" id="longitude" size="10" /><span class="note" style="font-weight:normal">&nbsp;(ex. -95.12345)</span></td></tr>
        <tr><td class="label" align="right">Datum: </td><td align="left">
        	<select id="datum">
        		<option value="nad27">NAD27</option>
        		<option value="nad83">NAD83</option>
        		<option value="wgs84">WGS84</option>
        	</select>
       	<tr><td></td><td align="left"><button class="label" onclick="zoomToLatLong(dojo.byId('latitude').value,dojo.byId('longitude').value,dojo.byId('datum').value);">Go</button></td></tr>
    </table>

    <div id="or"><img src="images/or.jpg" /></div>
        <table>
        <tr><td class="label">Well API:</td><td></td><td></td><td class="note">(extension optional)</td></tr>
        <tr>
            <td><input type="text" id="api_state" size="2" onkeyup="jumpFocus('api_county', 2, this.id)" style="height:14px"/> - </td>
            <td><input type="text" id="api_county" size="3" onkeyup="jumpFocus('api_number', 3, this.id)" style="height:14px" /> - </td>
            <td><input type="text" id="api_number" size="5" onkeyup="jumpFocus('api_extension', 5, this.id)" style="height:14px" /> - </td>
            <td><input type="text" id="api_extension" size="4" style="height:14px" />&nbsp;<button class="label" onclick="quickZoom('well');">Go</button></td>
        </tr>
        </table>
    <div id="or"><img src="images/or.jpg" /></div>
    <div class="input">
        <span class="label">Field Name:</span>
        <div dojoType="dojo.data.ItemFileReadStore" jsId="fieldStore" url="fields.txt"></div>
        <input id="field" dojoType="dijit.form.FilteringSelect" store="fieldStore" searchAttr="name" autocomplete="false" hasDownArrow="false"/>
        <button class="label" onclick="quickZoom('field',dojo.byId('field').value);">Go</button>
        <div class="input">
    		<button onclick="quickZoom('field', 'WELLINGTON', '');" style="font-weight:bold">Zoom to Wellington field</button>
        </div>
    </div>
    <div id="or"><img src="images/or.jpg" /></div>
    <div class="input">
        <span class="label">County:</span>
        <select id="county">
            <option value="">-- Select --</option>
            <cfloop query="qCounties">
                <option value="#name#">#name#</option>
            </cfloop>
        </select>
        <button class="label" onclick="quickZoom('county',dojo.byId('county').value);">Go</button>
    </div>
</div>

<!-- Filter menu: -->
<div dojoType="dijit.Menu" id="filterMenu" contextMenuForWindow="false" style="display: none;" targetNodeIds="filter" leftClicktoOpen="true">
	<div dojoType="dijit.MenuItem"><b>Oil and Gas Wells:</b></div>
	<div dojoType="dijit.MenuItem" onClick="filterWells('off');">Show All Wells</div>
	<div dojoType="dijit.MenuItem" onClick="filterWells('selected_field');">Show Wells Assigned to Selected Field</div>
	<div dojoType="dijit.PopupMenuItem" id="submenu2">
    	<span>Show Wells with Electric Logs</span>
        <div dojoType="dijit.Menu">
        	<div dojoType="dijit.MenuItem" onClick="filterWells('paper')">Paper</div>
        	<div dojoType="dijit.MenuItem" onClick="filterWells('scanned')">Scanned</div>
    	</div>
    </div>
    <div dojoType="dijit.MenuItem" onclick="filterWells('las');">Show Wells with LAS 2 Files</div>
    <!---<div dojoType="dijit.MenuItem" onclick="dijit.byId('las3').show();">Show Wells with LAS 3 Files</div>--->
    <!---<div dojoType="dijit.MenuItem" onclick="filterWells('las3');">Show Wells with LAS 3 Files</div>--->
    <div dojoType="dijit.MenuItem" onClick="filterWells('cuttings');">Show Wells with Rotary Cuttings</div>
    <div dojoType="dijit.MenuItem" onClick="filterWells('cores');">Show Wells with Core Samples</div>
    <div dojoType="dijit.MenuItem" onclick="filterWells('active_well');">Show Only Active Wells</div>
	<div dojoType="dijit.MenuItem" onclick="filterWells('horiz');">Show Only Horizontal Wells</div>
    <!---<div dojoType="dijit.MenuSeparator"></div>
    <div dojoType="dijit.MenuItem" onclick="filterWells('regional');">Show Key Regional Wells</div>
    <div dojoType="dijit.MenuItem" onclick="filterWells('precamb');">Show Precambrian Wells</div>
    <div dojoType="dijit.MenuItem" onclick="filterWells('supertype');">Show Super Type Wells</div>
    <div dojoType="dijit.MenuItem" onclick="filterWells('typewell');">Show Type Wells</div>--->
    <div dojoType="dijit.MenuSeparator"></div>
    <div dojoType="dijit.MenuItem"><b>WWC5 Water Wells:</b></div>
    <div dojoType="dijit.MenuItem" onclick="filterWells('show_monitoring');">Show All Wells</div>
    <div dojoType="dijit.MenuItem" onclick="filterWells('remove_monitoring');">Remove Monitoring/Engineering Wells</div>
</div>

<!-- Label menu: -->
<div dojoType="dijit.Menu" id="labelMenu" contextMenuForWindow="false" style="display: none;" targetNodeIds="label" leftClicktoOpen="true">
	<div dojoType="dijit.MenuItem"><b>Oil and Gas Wells</b></div>
	<div dojoType="dijit.MenuItem" onClick="setVisibleWellLayer('none');">No Labels</div>
    <div dojoType="dijit.MenuItem" onclick="setVisibleWellLayer('api');">API Number</div>
	<div dojoType="dijit.MenuItem" onClick="setVisibleWellLayer('leasewell');">Lease & Well Name</div>
    <div dojoType="dijit.MenuItem" onclick="setVisibleWellLayer('formation');">Producing Formation</div>
</div>

<!--- Warning message dialog box: --->
<div class="dialog" dojoType="dijit.Dialog" id="warning_box" title="Error" style="text-align:center;font:normal normal bold 14px arial">
	<div id="warning_msg" style="font:normal normal normal 12px Arial"></div><p>
	<button class="label" onclick="dijit.byId('warning_box').hide()">OK</button>
</div>

<!--- Download dialog box: --->
<div class="dialog" dojoType="dijit.Dialog" id="download" title="Download Oil and Gas Well Data" style="text-align:center;font:normal normal bold 14px arial">
    <div style="font:normal normal normal 12px arial; text-align:left">
    	<ul>
        	<li>Creates comma-delimited text files with well, tops, log, LAS, cuttings, and core information for wells visible in the current map extent.</li>
            <li>If a filter is in effect, the download will also be filtered.</li>
            <li>If the <em>Show Wells Assigned to Selected Field</em> filter is on, all wells for the field will be downloaded, even if they are not visible in the current map extent.</li>
        </ul>
        <ul>
        	<li>This dialog box will close and another will open with links to your files (may take a few minutes depending on number of wells).</li>
            <li><b>You may continue to use the map while the progress indicator is displayed.</b></li>
        </ul>
        <ul>
       		<li>
        		Other options to download well data can be accessed through the <a href="http://www.kgs.ku.edu/PRS/petroDB.html" target="_blank">oil and gas well database</a>.
        	</li>
        </ul>
    </div>
    <button class="label" style="text-align:center" onclick="createDownloadFile();dijit.byId('download').hide();">Download</button>
    <button class="label" style="text-align:center" onclick="dijit.byId('download').hide();">Cancel</button>
</div>

<div class="dialog" dojoType="dijit.Dialog" id="download_results" title="Download File is Ready" style="text-align:center;font:normal normal bold 14px arial">
	<span id="download_msg"></span>
</div>

<!--- Print dialog box 2 (for new print task): --->
<div dojoType="dijit.Dialog" id="printdialog2" title="Print to PDF" style="text-align:center;font:normal normal bold 14px arial">
    <div style="font:normal normal normal 12px arial;">
    	<table align="center">
        	<tr><td style="font-weight:bold" align="right">Title (optional):</td><td align="left"><input type="text" id="pdftitle2" size="50" /></td></tr>
            <tr><td style="font-weight:bold" align="right">Orientation:</td><td align="left"><input type="radio" id="landscape2" name="pdforientation2" value="landscape" checked="checked" />Landscape&nbsp;&nbsp;&nbsp;&nbsp;<input type="radio" id="portrait2" name="pdforientation2" value="portrait" />Portrait</td></tr>
            <tr><td style="font-weight:bold" align="right">Print map only (as jpg):</td><td align="left"><input type="checkbox" id="maponly"></td></tr>
        </table>
    </div>
    <p>
    <button class="label" onclick="printPDF();" style="text-align:center">Print</button>
    <button class="label" style="text-align:center" onclick="dijit.byId('printdialog2').hide();">Cancel</button>
    <p>
    <span style="font:normal normal normal 12px arial">Note: Pop-up blockers must be turned off or set to allow pop-ups from 'maps.kgs.ku.edu'</span>
</div>

<!--- Filter fields dialog: --->
<div dojoType="dijit.Dialog" id="fieldsdialog" title="Filter Fields" style="text-align:center;font:normal normal bold 14px arial">
    <div style="text-align:left;font:normal normal normal 12px arial">
    	1. Select a producing horizon:<br />
        <select name="horizon" id="horizon">
        	<!--<option value="all">All Fields</option>-->
            <option value="cretaceous">Cretaceous</option>
            <option value="permian">Permian</option>
            <option value="penn">Pennsylvanian</option>
            <option value="upperpenn">Upper Pennsylvanian</option>
            <option value="midpenn">Middle Pennsylvanian</option>
            <option value="lowpenn">Lower Pennsylvanian</option>
            <option value="missdevonian">Mississippian &amp; Devonian</option>
            <option value="upperord">Upper Ordovician</option>
            <option value="lowerord">Lower Ordovician &amp; Cambrian</option>
        </select>
        <p>
        2. Select an attribute to classify:<br />
        <select name="fieldattribute" id="fieldattr">
            <option value="CUMM_OIL">Cumulative Oil Production</option>
            <option value="CUMM_GAS">Cumulative Gas Production</option>
            <option value="AVGDEPTH">Average Depth</option>
            <!--<option value="ELEVSL">Average Elevation (sea level)</option>-->
        </select>
        <p>
        <input type="button" onclick="filterFields(dojo.byId('horizon').value,dojo.byId('fieldattr').value);" value="Go" />&nbsp;&nbsp;&nbsp;&nbsp;
        <input type="button" onclick="clearFieldFilter();" value="Remove Filter" />
    </div>
</div>

<!--- Cross section help dialog: --->
<div dojoType="dijit.Dialog" id="xSectHelp" title="How to Create a Cross Section" style="text-align:center;font:normal normal bold 14px arial">
	<div style="font:normal normal normal 12px arial;text-align:left">
        <ul>
            <li>Click the "Show Type Wells" button to display wells that can be used to create a cross section (or check Type Wells in the layers tab).</li>
            <li>Select a well for inclusion by clicking on it - you must zoom in on the well before it can be selected.<br />
            	Use the zoom slider in the upper left or the shift key and the mouse to drag a box around the area you want to zoom to.<br />
                Use the "Study Area" link in the upper left to zoom out to the entire study area extent.</li>
            <li>Once the selected well is highlighted, click the "Add Well" button.</li>
            <li>When all desired wells have been selected and added, click the "Create Cross Section" button to launch the cross-section Java applet.</li>
        </ul>
	</div>
</div>

<!-- Earthquake filter dialog: -->
<div dojoType="dijit.Dialog" id="quakefilter" title="Filter Earthquakes" style="text-align:center;font:normal normal bold 14px arial">
    <div style="text-align:left;font:normal normal normal 12px arial">
        <p>
        <input type="button" onclick="filterQuakesRecent();" value="Show Last Event in Kansas" />
   		</p>
   		OR
    	<p>
        Year:&nbsp;
        <select name="year" id="year">
            <option value="all" selected>All</option>
            <option value="2016">2016</option>
            <option value="2015">2015</option>
            <option value="2014">2014</option>
            <option value="2013">2013</option>
        </select>
        &nbsp;&nbsp;
        Magnitude:&nbsp;
        <select name="mag" id="mag">
            <option value="all" selected>All</option>
            <option value="2">2.0+</option>
            <option value="3">3.0+</option>
            <option value="4">4.0+</option>
        </select>
        &nbsp;&nbsp;
        <input type="button" onclick="filterQuakes(dojo.byId('year').value,dojo.byId('mag').value);" value="Go" />
        </p>
        <p>
        OR
        </p>
        <p>
        Show all earthquakes &nbsp;
        <select name="days" id="days">
            <option value="7" selected>in the last week</option>
            <option value="14">in the last two weeks</option></option>
            <option value="30">in the last month</option>
            <option value="all">since 2013</option>
        </select>
        &nbsp;&nbsp;
        <input type="button" onclick="filterQuakesDays(dojo.byId('days').value)" value="Go" />
        </p>
        <p>
        <input type="button" onclick="clearQuakeFilter()" value="Reset" />
        </p>
    </div>
</div>

<!-- Wellington earthquake filter dialog: -->
<div dojoType="dijit.Dialog" id="wellingtonquakefilter" title="Filter Earthquakes" style="text-align:center;font:normal normal bold 14px arial">
    <div style="text-align:left;font:normal normal normal 12px arial">
        <p>
        <input type="button" onclick="wellingtonFilterQuakesRecent();" value="Show Last Event in Kansas" />
   		</p>
   		OR
    	<p>
        Year:&nbsp;
        <select name="wellingtonyear" id="wellingtonyear">
            <option value="all" selected>All</option>
            <option value="2016">2016</option>
            <option value="2015">2015</option>
            <!--- <option value="2014">2014</option>
            <option value="2013">2013</option> --->
        </select>
        &nbsp;&nbsp;
        Magnitude:&nbsp;
        <select name="wellingtonmag" id="wellingtonmag">
            <option value="all" selected>All</option>
            <option value="2">2.0+</option>
            <option value="3">3.0+</option>
            <option value="4">4.0+</option>
        </select>
        &nbsp;&nbsp;
        <input type="button" onclick="wellingtonFilterQuakes(dojo.byId('wellingtonyear').value,dojo.byId('wellingtonmag').value);" value="Go" />
        </p>
        <p>
        OR
        </p>
        <p>
        Show all earthquakes &nbsp;
        <select name="wellingtondays" id="wellingtondays">
            <option value="7" selected>in the last week</option>
            <option value="14">in the last two weeks</option></option>
            <option value="30">in the last month</option>
            <!--- <option value="all">since 2013</option> --->
        </select>
        &nbsp;&nbsp;
        <input type="button" onclick="wellingtonFilterQuakesDays(dojo.byId('wellingtondays').value)" value="Go" />
        </p>
        <p>
        <input type="button" onclick="wellingtonClearQuakeFilter()" value="Reset" />
        </p>
    </div>
</div>

<!--- Earthquake Notes dialog: --->
<div dojoType="dijit.Dialog" id="usgsquakenotes" title="Earthquake Data Notes" style="text-align:center;font:normal normal bold 14px arial">
    <div style="text-align:left;font:normal normal normal 12px arial">
        <p>Events in this layer are from the USGS "us" and "ismpkansas" nets, and the Oklahoma Geological Survey.</p>
        <p>Data for all events occurring between 1/9/2013 and 3/7/2014 was provided by the Oklahoma Geological Survey.</p>
        <p>Earthquake data for Oklahoma is incomplete and only extends back to 12/2/2014. Only events occurring in northern Oklahoma<br>
        (north of Medford) are included on the mapper.</p>
    </div>
</div>

<!--- Wellington earthquake Notes dialog: --->
<div dojoType="dijit.Dialog" id="wellingtonquakenotes" title="Earthquake Data Notes" style="text-align:center;font:normal normal bold 14px arial">
    <div style="text-align:left;font:normal normal normal 12px arial">
        <p>Events in this layer are from the Wellington Field Seismometer Array installed by the KGS as part of research<br>
        on carbon management at Wellington Field funded by the U.S. Department of Energy under contract DE-FE0006821.<br>
        The catalog of events reported goes back to April 2015 to the present and is updated on approximately a weekly basis.<br>
        The seismometers are managed by a research group at the KGS and the Department of Geology at The University of Kansas.</p>
    </div>
</div>

<!--- Scalebar: --->
<!---<div id="scalebar_div">
	<img id="scalebarimage" src="images/scalebars/0.gif">
</div>--->

<!--- Download loading indicator: --->
<div id="loading_div" style="display:none; position:relative; z-index:1000;">
    <img src="images/loading.gif" />
</div>

<!--- Printing indicator: --->
<div id="printing_div" style="display:none; position:absolute; top:50px; left:565px; z-index:1000;">
    <img src="images/ajax-loader.gif" />
</div>

<!--- Cross section tools: --->
<!---<cfif isDefined('url.pass') and url.pass eq 'project'>--->
	<div id="xsectiontools" dojoType="dijit.TitlePane" title="Cross Section Tools" open="false" style="position:absolute;top:35px;left:775px;z-index:900;width:275px;font:normal normal bold 12px Arial;visibility:hidden;">
    	<button onclick="dijit.byId('xSectHelp').show();" style="width:155px">Help</button><br />
	    <button onclick="showLAS3Wells()" style="width:155px"><span id="shelig">Show</span> Type Wells</button><br />
        <button onclick="addXSectionPt()" style="width:155px" id="addwellbtn">Add Well</button>&nbsp;&nbsp;Selected: <span id=numselected style="font:normal normal normal 12px Arial">0</span><br />
	    <button onclick="removeLastXSectionPt()" style="width:155px">Remove Last Well</button>&nbsp;&nbsp;<span style="font:normal normal normal 12px arial">(select 4 max.)</span><br />
	    <button onclick="clearXSectionPts()" style="width:155px">Remove All Wells</button><br />
	    <button onclick="createXSection()" style="width:155px">Create Cross Section</button>
	</div>
<!---</cfif>--->

<!--- LAS 3 filter dialog: --->
<div class="dialog" dojoType="dijit.Dialog" id="las3" title="LAS 3 Filter Options" style="text-align:center;font:normal normal bold 14px arial">
	<table>
    	<tr><td colspan="2" class="input">Display wells with LAS 3 files containing the following:</td></tr>
    	<tr><td align="right"><input type="checkbox" id="lasl" value="L" onchange="checkLAS3Count()" /></td><td class="input" align="left">Log Data</td></tr>
        <tr><td align="right"><input type="checkbox" id="lasc" value="C" onchange="checkLAS3Count()" /></td><td class="input" align="left">Measured Core Data</td></tr>
        <tr><td align="right"><input type="checkbox" id="last" value="T" onchange="checkLAS3Count()" /></td><td class="input" align="left">Tops Data</td></tr>
        <tr><td align="right"><input type="checkbox" id="lasp" value="P" onchange="checkLAS3Count()" /></td><td class="input" align="left">Perforation Data</td></tr>
        <tr><td align="right"><input type="checkbox" id="lasd" value="D" onchange="checkLAS3Count()" /></td><td class="input" align="left">DST Data</td></tr>
        <tr><td align="right"><input type="checkbox" id="lass" value="S" onchange="checkLAS3Count()" /></td><td class="input" align="left">Sequence Stratigraphy Data</td></tr>
        <tr><td align="right"><input type="checkbox" id="lasf" value="F" onchange="checkLAS3Count()" /></td><td class="input" align="left">Flow Units Data</td></tr>
        <tr><td align="right"><input type="checkbox" id="lasg" value="G" onchange="checkLAS3Count()" /></td><td class="input" align="left">Georeport Data</td></tr>
        <tr><td colspan="2" align="center"><button class="label" onclick="filterWells('las3')">Apply Filter</button><button class="label" onclick="dijit.byId('las3').hide();">Cancel</button></td></tr>
        <tr><td colspan="2" align="center"><div id="las3_count_msg"></div></td></tr>
    </table>
</div>


<!--- modal regional geology layer picker: --->
<div class="dialog" dojoType="dijit.Dialog" id="geollayerpicker" title="Geology Base Layers" style="text-align:center;font:normal normal bold 14px arial;">
    <div style="width:1000px; height:795px; overflow:auto;">
	<table style="border:2px solid black;width:95%;">
        <tr>
            <th>Regional Geology</th>
            <th>Seismic</th>
            <th>Other</th>
        </tr>
        <tr>
            <td style="text-align:left;width:33%">
                <input type="checkbox" id="hpatopo" onclick="loadNChangeMap('hpaTopoLayer',this,'regional_geology_2','2','hpatopo','High Plains Aquifer Topography (ft)');">High Plains Aquifer Topography<br>
                <input type="checkbox" id="hpaiso" onclick="loadNChangeMap('hpaIsoLayer',this,'regional_geology_2','0','hpaiso','High Plains Aquifer Isopach (ft)');">High Plains Aquifer Isopach<br>
                <input type="checkbox" id="hpabedrock" onclick="loadNChangeMap('hpaBedrockLayer',this,'regional_geology_2','1','hpabedrock','High Plains Aquifer Bedrock Elev. (ft)');">High Plains Aquifer Base Elevation<br>
                <input type="checkbox" id="fthays" onclick="loadNChangeMap('baseFtHaysLayer',this,'regional_geology_3','6,7','fthays_base','Fort Hays Base Elevation (ft)');">Fort Hays Base Elevation<br>
                <input type="checkbox" id="greenhorntop" onclick="loadNChangeMap('greenhornTopLayer',this,'regional_geology_3','10,11','greenhorn_top','Greenhorn Elevation (ft)');">Greenhorn Top Elevation<br>
                <input type="checkbox" id="greenhornblaineiso" onclick="loadNChangeMap('greenhornBlaineIsoLayer',this,'regional_geology_3','12','greenhorn_blaine_iso','Greenhorn to Blain Isopach (ft)');">Greenhorn to Blaine Isopach<br>
                <input type="checkbox" id="blainesubsea" onclick="loadNChangeMap('blaineSubseaLayer',this,'regional_geology_2','11,30','blaine_top','Blaine Top Elevation (ft)');">Blaine Top<br>
                <input type="checkbox" id="blainecedariso" onclick="loadNChangeMap('blaineCedarIsoLayer',this,'regional_geology_2','12','blainecedariso','Blaine to Cedar Hills Isopach (ft)');">Blaine to Cedar Hills Isopach<br>
                <input type="checkbox" id="cedarhillstop" onclick="loadNChangeMap('cedarHillsTopLayer',this,'regional_geology_3','8,9','cedarhills_top','Cedar Hills Top (ft)');">Cedar Hills Top<br>
                <input type="checkbox" id="cedarhillsiso" onclick="loadNChangeMap('cedarHillsIsoLayer',this,'regional_geology_2','14','cedarhills_iso','Cedar Hills Isopach (ft)');">Cedar Hills Isopach<br>
                <input type="checkbox" id="stonecorraltop" onclick="loadNChangeMap('stoneCorralTopLayer',this,'regional_geology_3','15,16','stonecorl_top','Stone Corral Top Elevation (ft)');">Stone Corral Top<br>
                <input type="checkbox" id="stonecorrallansiso" onclick="loadNChangeMap('stoneCorralLansingIsoLayer',this,'regional_geology_3','17,18','stonecorl_lans_iso','Stone Corral to Lansing Isopach (ft)');">Stone Corral to Lansing Isopach<br>
                <input type="checkbox" id="stonecorralmissiso" onclick="loadNChangeMap('stoneCorralMissIsoLayer',this,'regional_geology_3','13,14','stonecorral_miss_iso','Stone Corral to Miss. Isopach (ft)');">Stone Corral to Miss. Isopach<br>
                <input type="checkbox" id="cimmsaltiso" onclick="loadNChangeMap('cimmSaltIsoLayer',this,'regional_geology_2','15','cimmsalt_legend','Cimarron Salt Isopach (ft)');">Cimarron Salt Isopach<br>
                <input type="checkbox" id="hutchtop" onclick="loadNChangeMap('hutchTopLayer',this,'regional_geology_2','9,31','hutchsalt_top','Hutchinson Salt Top Elevation (ft)');">Hutchinson Salt Top<br>
                <input type="checkbox" id="hutchchaseiso" onclick="loadNChangeMap('hutchChaseIsoLayer',this,'regional_geology_2','10,32','hutch_chase_iso','Hutchinson Salt to Chase Isopach (ft)');">Hutchinson Salt to Chase Isopach<br>
                <input type="checkbox" id="hutchnevaiso" onclick="loadNChangeMap('hutchNevaIsoLayer',this,'regional_geology_2','13','hutchnevaiso','Hutchinson Salt to Neva Isopach (ft)');">Hutchinson Salt to Neva Isopach<br>
                <input type="checkbox" id="chasesubsea" onclick="loadNChangeMap('chaseTopLayer',this,'regional_geology_1','15,30','chase_top','Chase Group Top (ft)');">Chase Top<br>
				<input type="checkbox" id="ftrileydip" onclick="loadNChangeMap('fortRileyLayer',this,'regional_geology_1','13','blank','');">Fort Riley Dip
                <div id="horizontalSlider_ftriley2" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:100px;"
                    onChange="dojo.byId('horizontalSlider_ftriley2').value = arguments[0];changeOpacity('fortRileyLayer',dojo.byId('horizontalSlider_ftriley2').value);">
                </div><br>
                <input type="checkbox" id="stotlertop" onclick="loadNChangeMap('stotlerTopLayer',this,'regional_geology_3','19,20','stotler_top','Stotler Top Elevation (ft)');">Stotler Top<br>
                <input type="checkbox" id="stotlermissiso" onclick="loadNChangeMap('stotlerMissIsoLayer',this,'regional_geology_3','23,24','stotler_miss_iso','Stotler to Mississippian Isopach (ft)');">Stotler to Mississippian Isopach<br>
                <input type="checkbox" id="stotlerarbkiso" onclick="loadNChangeMap('stotlerArbkIsoLayer',this,'regional_geology_3','21,22','stotler_arbk_iso','Stotler to Arbuckle Isopach (ft)');">Stotler to Arbuckle Isopach<br>
                <input type="checkbox" id="hbnrsubsea" onclick="loadNChangeMap('hbnrSubseaRGLayer',this,'regional_geology_1','6,29','heebner','Heebner Top Elevation (ft)');">Heebner Top<br>
                <input type="checkbox" id="lansingtop" onclick="loadNChangeMap('lansingTopLayer',this,'regional_geology_3','4,5','lansing_top','Lansing Top (ft - sealevel)');">Lansing Top<br>
                <input type="checkbox" id="marmatontop" onclick="loadNChangeMap('marmatonTopLayer',this,'regional_geology_3','2,3','marmaton_top','Marmaton Top (ft - sealevel)');">Marmaton Top<br>
                <input type="checkbox" id="chrkmissiso" onclick="loadNChangeMap('chrkMissIsoLayer',this,'regional_geology_3','0,1','chrk_miss_iso','Cherokee to Mississippian Isopach (ft)');">Cherokee to Mississippian Isopach<br>
                <input type="checkbox" id="atokansubsea" onclick="loadNChangeMap('atokanSubseaLayer',this,'regional_geology_2','3','atokansubsea','Atokan Top Elevation (ft)');">Atokan Top<br>
                <input type="checkbox" id="atokaniso" onclick="loadNChangeMap('atokanIsoLayer',this,'regional_geology_2','6','atokaniso','Atokan Isopach (ft)');">Atokan Isopach<br>
                <input type="checkbox" id="morrowsubsea" onclick="loadNChangeMap('morrowSubseaLayer',this,'regional_geology_2','4,16','morrowsubsea','Morrow Top Elevation (ft)');">Morrow Top<br>
                <input type="checkbox" id="morrowmissiso" onclick="loadNChangeMap('morrowMissIsoLayer',this,'regional_geology_2','5,17','morrowmissiso','Morrow to Mississippian Isopach (ft)');">Morrow to Mississippian Isopach<br>
                <input type="checkbox" id="misssubsea" onclick="loadNChangeMap('missSubseaRGLayer',this,'regional_geology_1','3,20','misssubsea','Mississippian Top Elevation (ft)');">Mississippian Top<br>
                <input type="checkbox" id="missmissbaseiso" onclick="loadNChangeMap('missMissBaseIsoLayer',this,'regional_geology_1','14,25','missmissbaseiso','Mississippian Isopach (ft)');">Mississippian Isopach<br>
                <input type="checkbox" id="chestersubsea" onclick="loadNChangeMap('chesterSubseaLayer',this,'regional_geology_2','7,18','chestersubsea','Chester Top Elevation (ft)');">Chester Top<br>
                <input type="checkbox" id="chesteriso" onclick="loadNChangeMap('chesterIsoLayer',this,'regional_geology_2','8','chesteriso','Chester Isopach (ft)');">Chester Isopach<br>
                <input type="checkbox" id="kdhksubsea" onclick="loadNChangeMap('kdhkSubseaLayer',this,'regional_geology_1','16,27','kdhksubsea','Kinderhook Top Elevation (ft)');">Kinderhook Top<br>
                <input type="checkbox" id="kdhkiso" onclick="loadNChangeMap('kdhkIsoLayer',this,'regional_geology_2','24','kdhkiso','Kinderhook Isopach (ft)');">Kinderhook Isopach<br>
                <input type="checkbox" id="kdhksubseawellington" onclick="loadNChangeMap('kdhkWellingtonLayer',this,'regional_geology_1','17','kdhksubseawellington','Kinderhook Top Elevation (Wellington area, ft)');">Kinderhook Top (Wellington Area)<br>
                <input type="checkbox" id="isochattmiss" onclick="loadNChangeMap('chattMissBaseLayer',this,'regional_geology_1','9','chattmissiso','Chattanooga Isopach (ft)');">Chattanooga Isopach<br>
                <input type="checkbox" id="huntontop" onclick="loadNChangeMap('huntonTopLayer',this,'regional_geology_2','22,23','huntontop','Hunton Elevation (ft)');">Hunton Top<br>
                <input type="checkbox" id="huntoniso" onclick="loadNChangeMap('huntonIsoLayer',this,'regional_geology_2','21','huntoniso','Hunton Isopach (ft)');">Hunton Isopach<br>
                <input type="checkbox" id="violatop" onclick="loadNChangeMap('violaTopLayer',this,'regional_geology_2','28,29','violatop','Viola Elevation (ft)');">Viola Top<br>
                <input type="checkbox" id="violaiso" onclick="loadNChangeMap('violaIsoLayer',this,'regional_geology_1','28','violaiso','Viola Isopach (ft)');">Viola Isopach<br>
                <input type="checkbox" id="simpsontop" onclick="loadNChangeMap('simpsonTopLayer',this,'regional_geology_2','26,27','simpsontop','Simpson Elevation (ft)');">Simpson Top<br>
                <input type="checkbox" id="simpsoniso" onclick="loadNChangeMap('simpsonIsoLayer',this,'regional_geology_2','25','simpsoniso','Simpson Isopach (ft)');">Simpson Isopach<br>
                <input type="checkbox" id="arbksubsea" onclick="loadNChangeMap('arbkSubseaRGLayer',this,'regional_geology_1','7,23','arbksubsea','Arbuckle Top Elevation (ft)');">Arbuckle Top<br>
                <input type="checkbox" id="arbkisopach" onclick="loadNChangeMap('arbkIsopachRGLayer',this,'regional_geology_1','8,24','arbkpciso','Arbuckle Isopach (ft)');">Arbuckle Isopach<br>
				<input type="checkbox" id="isojccroub" onclick="loadNChangeMap('jccRoubLayer',this,'regional_geology_1','5,22','jccroubiso','Jefferson City-Cotter to Roubidoux Isopach (ft)');">Jefferson City-Cotter to Roubidoux Iso.<br>
				<input type="checkbox" id="isoroubgas" onclick="loadNChangeMap('roubGasconadeLayer',this,'regional_geology_1','12','roubgasiso','Roubidoux to Gasconade Isopach (ft)');">Roubidoux to Gasconade Isopach<br>
                <input type="checkbox" id="isogasgunter" onclick="loadNChangeMap('gasGunterLayer',this,'regional_geology_1','10','gasgunteriso','Gasconade to Gunter Isopach (ft)');">Gasconade to Gunter Isopach<br>
                <input type="checkbox" id="isogunterpc" onclick="loadNChangeMap('gunterPrecambLayer',this,'regional_geology_1','11','gunterpciso','Gunter to Precambrian Isopach (ft)');">Gunter to Precambrian Isopach<br>
				<input type="checkbox" id="precambsubsea" onclick="loadNChangeMap('precambSubseaRGLayer',this,'regional_geology_1','1,18','pcsubsea','Precambrian Top Elevation (ft)');">Precambrian Top<br>
				<input type="checkbox" id="precambdepth" onclick="loadNChangeMap('precambDepthLayer',this,'regional_geology_1','2,19','pcdepth','Precambrian Depth (ft)');">Precambrian Depth<br>
            <td style="text-align:left;width:33%" nowrap>
                <span style="font:normal normal normal 14px arial">Anson-Bates-Wellington Area</span><br>
                <input type="checkbox" id="abwseismic2" style="margin-left:11px;" onclick="loadNChangeMap('abwSeismicLayer',this,'seismic_1','0','abwseismic','Arbuckle Time Structure, A-B-W');">Arbuckle Time Structure
                <div id="horizontalSlider_abwseismic2" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_abwseismic2').value = arguments[0];changeOpacity('abwSeismicLayer',dojo.byId('horizontalSlider_abwseismic2').value);">
                </div><br>
                <p></p>
                <span style="font:normal normal normal 14px arial">Adamson Area</span><br>
                <input type="checkbox" id="adamsonheebtime" style="margin-left:11px;" onclick="loadNChangeMap('adamsonHeebTimeLayer',this,'seismic_1','2','adamson_heeb_ts','Adamson Heebner Time Structure');">Heebner Time Structure
                <div id="horizontalSlider_adamsonheebtime" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_adamsonheebtime').value = arguments[0];changeOpacity('adamsonHeebTimeLayer',dojo.byId('horizontalSlider_adamsonheebtime').value);">
                </div>
                <br>
                <input type="checkbox" id="adamsonmrrwdepth" style="margin-left:11px;" onclick="loadNChangeMap('adamsonMrrwDepthLayer',this,'seismic_1','6','adamson_mrrw_dc','Adamson Morrow Depth');">Morrow Depth Converted
                <div id="horizontalSlider_adamsonmrrwdepth" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_adamsonmrrwdepth').value = arguments[0];changeOpacity('adamsonMrrwDepthLayer',dojo.byId('horizontalSlider_adamsonmrrwdepth').value);">
                </div>
                <br>
                <input type="checkbox" id="adamsonmrrwtime" style="margin-left:11px;" onclick="loadNChangeMap('adamsonMrrwTimeLayer',this,'seismic_1','5','adamson_mrrw_ts','Adamson Morrow Time');">Morrow Time Structure
                <div id="horizontalSlider_adamsonmrrwtime" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_adamsonmrrwtime').value = arguments[0];changeOpacity('adamsonMrrwTimeLayer',dojo.byId('horizontalSlider_adamsonmrrwtime').value);">
                </div>
                <br>
                <input type="checkbox" id="adamsonmrmcdepth" style="margin-left:11px;" onclick="loadNChangeMap('adamsonMrmcDepthLayer',this,'seismic_1','3','adamson_mrmc_dc','Adamson Meramec Depth');">Meramec Depth Converted
                <div id="horizontalSlider_adamsonmrmcdepth" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_adamsonmrmcdepth').value = arguments[0];changeOpacity('adamsonMrmcDepthLayer',dojo.byId('horizontalSlider_adamsonmrmcdepth').value);">
                </div>
                <br>
                <input type="checkbox" id="adamsonmrmctime" style="margin-left:11px;" onclick="loadNChangeMap('adamsonMrmcTimeLayer',this,'seismic_1','4','adamson_mrmc_ts','Adamson Meramec Time');">Meramec Time Structure
                <div id="horizontalSlider_adamsonmrmctime" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_adamsonmrmctime').value = arguments[0];changeOpacity('adamsonMrmcTimeLayer',dojo.byId('horizontalSlider_adamsonmrmctime').value);">
                </div>
                <br>
                <input type="checkbox" id="adamsonarbktime" style="margin-left:11px;" onclick="loadNChangeMap('adamsonArbkTimeLayer',this,'seismic_1','1','adamson_arbk_ts','Adamson Arbuckle Time Structure');">Arbuckle Time Structure
                <div id="horizontalSlider_adamsonarbktime" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_adamsonarbktime').value = arguments[0];changeOpacity('adamsonArbkTimeLayer',dojo.byId('horizontalSlider_adamsonarbktime').value);">
                </div>
                <br>
                <input type="checkbox" id="adamsonpctime" style="margin-left:11px;" onclick="loadNChangeMap('adamsonPcTimeLayer',this,'seismic_1','9','adamson_pc_ts','Adamson Precambrian Time');">Precambrian Time Structure
                <div id="horizontalSlider_adamsonpctime" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_adamsonpctime').value = arguments[0];changeOpacity('adamsonPcTimeLayer',dojo.byId('horizontalSlider_adamsonpctime').value);">
                </div>
                <p></p>
                <span style="font:normal normal normal 14px arial">Cutter Area</span><br>
                <input type="checkbox" id="cutterheebtime" style="margin-left:11px;" onclick="loadNChangeMap('cutterHeebTimeLayer',this,'seismic_1','16','cutter_heeb_ts','Cutter Heebner Time Structure');">Heebner Time Structure
                <div id="horizontalSlider_cutterheebtime" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_cutterheebtime').value = arguments[0];changeOpacity('cutterHeebTimeLayer',dojo.byId('horizontalSlider_cutterheebtime').value);">
                </div>
                <br>
                <input type="checkbox" id="cuttermrrwdepth" style="margin-left:11px;" onclick="loadNChangeMap('cutterMrrwDepthLayer',this,'seismic_1','14','cutter_mrrw_dc','Cutter Morrow Depth');">Morrow Depth Converted
                <div id="horizontalSlider_cuttermrrwdepth" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_cuttermrrwdepth').value = arguments[0];changeOpacity('cutterMrrwDepthLayer',dojo.byId('horizontalSlider_cuttermrrwdepth').value);">
                </div>
                <br>
                <input type="checkbox" id="cuttermrrwtime" style="margin-left:11px;" onclick="loadNChangeMap('cutterMrrwTimeLayer',this,'seismic_1','13','cutter_mrrw_ts','Cutter Morrow Time Structure');">Morrow Time Structure
                <div id="horizontalSlider_cuttermrrwtime" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_cuttermrrwtime').value = arguments[0];changeOpacity('cutterMrrwTimeLayer',dojo.byId('horizontalSlider_cuttermrrwtime').value);">
                </div>
                <br>
                <input type="checkbox" id="cuttermrmcdepth" style="margin-left:11px;" onclick="loadNChangeMap('cutterMrmcDepthLayer',this,'seismic_1','12','cutter_mrmc_dc','Cutter Meramec Depth');">Meramec Depth Converted
                <div id="horizontalSlider_cuttermrmcdepth" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_cuttermrmcdepth').value = arguments[0];changeOpacity('cutterMrmcDepthLayer',dojo.byId('horizontalSlider_cuttermrmcdepth').value);">
                </div>
                <br>
                <input type="checkbox" id="cuttermrmctime" style="margin-left:11px;" onclick="loadNChangeMap('cutterMrmcTimeLayer',this,'seismic_1','11','cutter_mrmc_ts','Cutter Meramec Time Structure');">Meramec Time Structure
                <div id="horizontalSlider_cuttermrmctime" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_cuttermrmctime').value = arguments[0];changeOpacity('cutterMrmcTimeLayer',dojo.byId('horizontalSlider_cuttermrmctime').value);">
                </div>
                <br>
                <input type="checkbox" id="cuttervioltime" style="margin-left:11px;" onclick="loadNChangeMap('cutterViolTimeLayer',this,'seismic_1','15','cutter_vio_ts','Cutter Viola Time Structure');">Viola Time Structure
                <div id="horizontalSlider_cuttervioltime" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_cuttervioltime').value = arguments[0];changeOpacity('cutterViolTimeLayer',dojo.byId('horizontalSlider_cuttervioltime').value);">
                </div>
                <br>
                <input type="checkbox" id="cutterpctime" style="margin-left:11px;" onclick="loadNChangeMap('cutterPcTimeLayer',this,'seismic_1','10','cutter_pc_ts','Cutter Precambrian Time Structure');">Precambrian Time Structure
                <div id="horizontalSlider_cutterpctime" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_cutterpctime').value = arguments[0];changeOpacity('cutterPcTimeLayer',dojo.byId('horizontalSlider_cutterpctime').value);">
                </div>
                <p></p>
                <span style="font:normal normal normal 14px arial">Eubank Area</span><br>
                <input type="checkbox" id="eubanklanstime" style="margin-left:11px;" onclick="loadNChangeMap('eubankLansTimeLayer',this,'seismic_1','18','eubank_lans_ts','Eubank Mid-Lansing Time Structure');">Mid-Lansing Time Structure
                <div id="horizontalSlider_eubanklanstime" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_eubanklanstime').value = arguments[0];changeOpacity('eubankLansTimeLayer',dojo.byId('horizontalSlider_eubanklanstime').value);">
                </div>
                <br>
                <input type="checkbox" id="eubankmrrwdepth" style="margin-left:11px;" onclick="loadNChangeMap('eubankMrrwDepthLayer',this,'seismic_2','9','eubank_mrrw_dc','Eubank Morrow Depth');">Morrow Depth Converted
                <div id="horizontalSlider_eubankmrrwdepth" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_eubankmrrwdepth').value = arguments[0];changeOpacity('eubankMrrwDepthLayer',dojo.byId('horizontalSlider_eubankmrrwdepth').value);">
                </div>
                <br>
                <input type="checkbox" id="eubankmrrwtime" style="margin-left:11px;" onclick="loadNChangeMap('eubankMrrwTimeLayer',this,'seismic_2','8','eubank_mrrw_ts','Eubank Morrow Time Structure');">Morrow Time Structure
                <div id="horizontalSlider_eubankmrrwtime" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_eubankmrrwtime').value = arguments[0];changeOpacity('eubankMrrwTimeLayer',dojo.byId('horizontalSlider_eubankmrrwtime').value);">
                </div>
                <br>
                <input type="checkbox" id="eubankmrmctime" style="margin-left:11px;" onclick="loadNChangeMap('eubankMrmcTimeLayer',this,'seismic_2','11','eubank_mrmc_ts','Eubank Meramec Time Structure');">Meramec Time Structure
                <div id="horizontalSlider_eubankmrmctime" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_eubankmrmctime').value = arguments[0];changeOpacity('eubankMrmcTimeLayer',dojo.byId('horizontalSlider_eubankmrmctime').value);">
                </div>
                <br>
                <input type="checkbox" id="eubankvioltime" style="margin-left:11px;" onclick="loadNChangeMap('eubankViolTimeLayer',this,'seismic_2','10','eubank_viol_ts','Eubank Viola Time Structure');">Viola Time Structure
                <div id="horizontalSlider_eubankvioltime" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_eubankvioltime').value = arguments[0];changeOpacity('eubankViolTimeLayer',dojo.byId('horizontalSlider_eubankvioltime').value);">
                </div>
                <br>
                <input type="checkbox" id="eubankpctime" style="margin-left:11px;" onclick="loadNChangeMap('eubankPcTimeLayer',this,'seismic_1','17','eubank_pc_ts','Eubank Precambrian Time Structure');">Precambrian Time Structure
                <div id="horizontalSlider_eubankpctime" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_eubankpctime').value = arguments[0];changeOpacity('eubankPcTimeLayer',dojo.byId('horizontalSlider_eubankpctime').value);">
                </div>
                <p></p>
                <span style="font:normal normal normal 14px arial">Pleasant Prairie Area</span><br>
                <input type="checkbox" id="ppkctime" style="margin-left:11px;" onclick="loadNChangeMap('ppKcTimeLayer',this,'seismic_2','13','pp_kc_ts','Pleasant Prairie KC Time Structure');">Kansas City Time Structure
                <div id="horizontalSlider_ppkctime" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_ppkctime').value = arguments[0];changeOpacity('ppKcTimeLayer',dojo.byId('horizontalSlider_ppkctime').value);">
                </div>
                <br>
                <input type="checkbox" id="ppmrrwdepth" style="margin-left:11px;" onclick="loadNChangeMap('ppMrrwDepthLayer',this,'seismic_2','17','pp_mrrw_dc','Pleasant Prairie Morrow Depth');">Morrow Depth Converted
                <div id="horizontalSlider_ppmrrwdepth" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_ppmrrwdepth').value = arguments[0];changeOpacity('ppMrrwDepthLayer',dojo.byId('horizontalSlider_ppmrrwdepth').value);">
                </div>
                <br>
                <input type="checkbox" id="ppmrrwtime" style="margin-left:11px;" onclick="loadNChangeMap('ppMrrwTimeLayer',this,'seismic_2','16','pp_mrrw_ts','Pleasant Prairie Morrow Time Structure');">Morrow Time Structure
                <div id="horizontalSlider_ppmrrwtime" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_ppmrrwtime').value = arguments[0];changeOpacity('ppMrrwTimeLayer',dojo.byId('horizontalSlider_ppmrrwtime').value);">
                </div>
                <br>
                <input type="checkbox" id="ppmrmcdepth" style="margin-left:11px;" onclick="loadNChangeMap('ppMrmcDepthLayer',this,'seismic_2','15','pp_mrmc_dc','Pleasant Prairie Meramec Depth');">Meramec Depth Converted
                <div id="horizontalSlider_ppmrmcdepth" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_ppmrmcdepth').value = arguments[0];changeOpacity('ppMrmcDepthLayer',dojo.byId('horizontalSlider_ppmrmcdepth').value);">
                </div>
                <br>
                <input type="checkbox" id="ppmrmctime" style="margin-left:11px;" onclick="loadNChangeMap('ppMrmcTimeLayer',this,'seismic_2','14','pp_mrmc_ts','Pleasant Prairie Meramec Time Structure');">Meramec Time Structure
                <div id="horizontalSlider_ppmrmctime" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_ppmrmctime').value = arguments[0];changeOpacity('ppMrmcTimeLayer',dojo.byId('horizontalSlider_ppmrmctime').value);">
                </div>
                <br>
                <input type="checkbox" id="pparbktime" style="margin-left:11px;" onclick="loadNChangeMap('ppArbkTimeLayer',this,'seismic_2','12','pp_arbk_ts','Pleasant Prairie Arbuckle Time Structure');">Arbuckle Time Structure
                <div id="horizontalSlider_pparbktime" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_pparbktime').value = arguments[0];changeOpacity('ppArbkTimeLayer',dojo.byId('horizontalSlider_pparbktime').value);">
                </div>
                <br>
                <input type="checkbox" id="pppctime" style="margin-left:11px;" onclick="loadNChangeMap('ppPcTimeLayer',this,'seismic_2','18','pp_pc_ts','Pleasant Prairie Precambrian Time Structure');">Precambrian Time Structure
                <div id="horizontalSlider_pppctime" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_pppctime').value = arguments[0];changeOpacity('ppPcTimeLayer',dojo.byId('horizontalSlider_pppctime').value);">
                </div>
                <p></p>
                <span style="font:normal normal normal 14px arial">Wellington Area</span><br>
                <input type="checkbox" id="wellhwrdtime" style="margin-left:11px;" onclick="loadNChangeMap('wellingtonHowardTimeLayer',this,'seismic_3','4','wellington_hwrd','Wellington Howard Time Structure');">Howard Time Structure
                <div id="horizontalSlider_wellhwrdtime" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_wellhwrdtime').value = arguments[0];changeOpacity('wellingtonHowardTimeLayer',dojo.byId('horizontalSlider_wellhwrdtime').value);">
                </div>
                <br>
                <input type="checkbox" id="wellshwn1time" style="margin-left:11px;" onclick="loadNChangeMap('wellingtonShawnee1TimeLayer',this,'seismic_3','1','wellington_shwn_1','Wellington Shawnee 1 Time Structure');">Shawnee 1 Time Structure
                <div id="horizontalSlider_wellshwn1time" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_wellshwn1time').value = arguments[0];changeOpacity('wellingtonShawnee1TimeLayer',dojo.byId('horizontalSlider_wellshwn1time').value);">
                </div>
                <br>
                <input type="checkbox" id="wellshwn2time" style="margin-left:11px;" onclick="loadNChangeMap('wellingtonShawnee2TimeLayer',this,'seismic_3','0','wellington_shwn_2','Wellington Shawnee 2 Time Structure');">Shawnee 2 Time Structure
                <div id="horizontalSlider_wellshwn2time" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_wellshwn2time').value = arguments[0];changeOpacity('wellingtonShawnee2TimeLayer',dojo.byId('horizontalSlider_wellshwn2time').value);">
                </div>
                <br>
                <input type="checkbox" id="wellkctime" style="margin-left:11px;" onclick="loadNChangeMap('wellingtonKcTimeLayer',this,'seismic_3','3','wellington_kc','Wellington Kansas City Time Structure');">Kansas City Time Structure
                <div id="horizontalSlider_wellkctime" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_wellkctime').value = arguments[0];changeOpacity('wellingtonKcTimeLayer',dojo.byId('horizontalSlider_wellkctime').value);">
                </div>
                <br>
                <input type="checkbox" id="wellchrktime" style="margin-left:11px;" onclick="loadNChangeMap('wellingtonCherokeeTimeLayer',this,'seismic_3','5','wellington_chrk','Wellington Cherokee Time Structure');">Cherokee Time Structure
                <div id="horizontalSlider_wellchrktime" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_wellchrktime').value = arguments[0];changeOpacity('wellingtonCherokeeTimeLayer',dojo.byId('horizontalSlider_wellchrktime').value);">
                </div>
                <br>
                <input type="checkbox" id="wellmisstime" style="margin-left:11px;" onclick="loadNChangeMap('wellingtonMissTimeLayer',this,'seismic_3','2','wellington_miss','Wellington Mississippian Time Structure');">Mississippian Time Structure
                <div id="horizontalSlider_wellmisstime" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_wellmisstime').value = arguments[0];changeOpacity('wellingtonMissTimeLayer',dojo.byId('horizontalSlider_wellmisstime').value);">
                </div>
                <br>
                <input type="checkbox" id="wellarbktime" style="margin-left:11px;" onclick="loadNChangeMap('wellingtonArbuckleTimeLayer',this,'seismic_3','6','wellington_arbk','Wellington Arbuckle Time Structure');">Arbuckle Time Structure
                <div id="horizontalSlider_wellarbktime" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;float:right;margin-right:5px;"
                    onChange="dojo.byId('horizontalSlider_wellarbktime').value = arguments[0];changeOpacity('wellingtonArbuckleTimeLayer',dojo.byId('horizontalSlider_wellarbktime').value);">
                </div>
                <br>
            </td>
            <td style="text-align:left;width:33%" nowrap>
                <span style="font:normal normal bold 14px arial">Merged Well and Seismic Data</span><br>
                <span style="font:normal normal normal 14px arial">Adamson Area</span><br>
                <input type="checkbox" style="margin-left:11px;" id="adamsonmrrwmerge" onclick="loadNChangeMap('adamsonMrrwMergeLayer',this,'seismic_2','6','adamson_mrrw','Adamson Morrow Elevation (ft)');">Morrow Subsea<br>
                <input type="checkbox" style="margin-left:11px;" id="adamsonmrmcmerge" onclick="loadNChangeMap('adamsonMrmcMergeLayer',this,'seismic_2','7','adamson_mrmc','Adamson Meramec Elevation (ft)');">Meramec Subsea<br>
                <span style="font:normal normal normal 14px arial">Cutter Area</span><br>
                <input type="checkbox" style="margin-left:11px;" id="cuttermrrwmerge" onclick="loadNChangeMap('cutterMrrwMergeLayer',this,'seismic_2','5','cutter_mrrw','Cutter Morrow Elevation (ft)');">Morrow Subsea<br>
                <input type="checkbox" style="margin-left:11px;" id="cuttermrmcmerge" onclick="loadNChangeMap('cutterMrmcMergeLayer',this,'seismic_2','4','cutter_mrmc','Cutter Meramec Elevation (ft)');">Meramec Subsea<br>
                <span style="font:normal normal normal 14px arial">Eubank Area</span><br>
                <input type="checkbox" style="margin-left:11px;" id="eubankmrrwmerge" onclick="loadNChangeMap('eubankMrrwMergeLayer',this,'seismic_2','3','eubank_mrrw','Eubank Morrow Elevation (ft)');">Morrow Subsea<br>
                <input type="checkbox" style="margin-left:11px;" id="eubankmrmcmerge" onclick="loadNChangeMap('eubankMrmcMergeLayer',this,'seismic_2','2','eubank_mrmc','Eubank Meramec Elevation (ft)');">Meramec Subsea<br>
                <span style="font:normal normal normal 14px arial">Pleasant Prairie Area</span><br>
                <input type="checkbox" style="margin-left:11px;" id="ppmrrwmerge" onclick="loadNChangeMap('pleasantPrairieMrrwMergeLayer',this,'seismic_2','1','pleasantprairie_mrrw','Pleasant Prairie Morrow Elev. (ft)');">Morrow Subsea<br>
                <input type="checkbox" style="margin-left:11px;" id="ppmrmcmerge" onclick="loadNChangeMap('pleasantPrairieMrmcMergeLayer',this,'seismic_2','0','pleasantprairie_mrmc','Pleasant Prairie Meramec Elev. (ft)');">Meramec Subsea<br>
                <p></p>

                <span style="font:normal normal bold 14px arial">Faults</span><br>
                <input type="checkbox" id="missleakage" onclick="loadNChangeMap('missLeakageMajorLayer',this,'faults','0','faults_legend','');">Mississippian Top<br>
                <input type="checkbox" id="bmissleakage" onclick="loadNChangeMap('baseMissLeakageMajorLayer',this,'faults','1','faults_legend','');">Mississippian Base<br>
                <input type="checkbox" id="violafaults" onclick="loadNChangeMap('violaFaultsLayer',this,'faults','3','faults_legend','');">Viola<br>
                <input type="checkbox" id="pcarbkfaults" onclick="loadNChangeMap('pcArbkFaultsLayer',this,'faults','2','faults_legend','');">Precambrian-Arbuckle<br>
                <p></p>

                <table>
                <tr><td><span style="font:normal normal bold 14px arial">Gravity / Magnetic</span></td></tr>
                <tr><td><input type="checkbox" id="ga210m" onclick="loadNChangeMap('ga210mGravLayer',this,'gravity','0','gravanomaly210','Gravity Anomaly');">Gravity Anomaly 2-10 Mile</td>
                <td><div id="horizontalSlider_ga210m2" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px"
                    onChange="dojo.byId('horizontalSlider_ga210m2').value = arguments[0];changeOpacity('ga210mGravLayer',dojo.byId('horizontalSlider_ga210m2').value);">
                </div></td></tr>
                <tr><td><input type="checkbox" id="gta" onclick="loadNChangeMap('gtaGravLayer',this,'gravity','1','gravtiltangle','Gravity Tilt Angle');">Gravity Tilt Angle</td>
                <td><div id="horizontalSlider_gta2" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;"
                    onChange="dojo.byId('horizontalSlider_gta2').value = arguments[0];changeOpacity('gtaGravLayer',dojo.byId('horizontalSlider_gta2').value);">
                </div></td></tr>
                <tr><td><input type="checkbox" id="rbg700m" onclick="loadNChangeMap('rbg700mGravLayer',this,'gravity','2','bougergrav700','Residual Bouguer Gravity');">Residual Bouguer Gravity 700m</td>
                <td><div id="horizontalSlider_rbg700m2" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;"
                    onChange="dojo.byId('horizontalSlider_rbg700m2').value = arguments[0];changeOpacity('rbg700mGravLayer',dojo.byId('horizontalSlider_rbg700m2').value);">
                </div></td></tr>
                <tr><td><input type="checkbox" id="taga210m" onclick="loadNChangeMap('taga210mGravLayer',this,'gravity','3','tiltanglegravanom210','Tilt Angle Gravity Anomaly');">Tilt Angle Gravity Anomaly 2-10 Mile</td>
                <td><div id="horizontalSlider_taga210m2" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;"
                    onChange="dojo.byId('horizontalSlider_taga210m2').value = arguments[0];changeOpacity('taga210mGravLayer',dojo.byId('horizontalSlider_taga210m2').value);">
                </div></td></tr>
                <tr><td><input type="checkbox" id="tatm" onclick="loadNChangeMap('tatmMagLayer',this,'magnetic','0','tatotalmag','Tilt Angle Total Magnetic');">Tilt Angle Total Magnetic</td>
                <td><div id="horizontalSlider_tatm2" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;"
                    onChange="dojo.byId('horizontalSlider_tatm2').value = arguments[0];changeOpacity('tatmMagLayer',dojo.byId('horizontalSlider_tatm2').value);">
                </div></td></tr>
                <tr><td><input type="checkbox" id="tatm210m" onclick="loadNChangeMap('tatm210mMagLayer',this,'magnetic','1','tatotalmag210','Tilt Angle Total Magnetic 2-10 Mile');">Tilt Angle Total Magnetic 2-10 Mile</td>
                <td><div id="horizontalSlider_tatm210m2" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;"
                    onChange="dojo.byId('horizontalSlider_tatm210m2').value = arguments[0];changeOpacity('tatm210mMagLayer',dojo.byId('horizontalSlider_tatm210m2').value);">
                </div></td></tr>
                <tr><td><input type="checkbox" id="tma210m" onclick="loadNChangeMap('tma210mMagLayer',this,'magnetic','2','totalmaganom210','Total Magnetic Anomaly');">Total Magnetic Anomaly 2-10 Mile</td>
                <td><div id="horizontalSlider_tma210m2" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;"
                    onChange="dojo.byId('horizontalSlider_tma210m2').value = arguments[0];changeOpacity('tma210mMagLayer',dojo.byId('horizontalSlider_tma210m2').value);">
                </div></td></tr>
                <tr><td><input type="checkbox" id="tmtp910m" onclick="loadNChangeMap('tmtp910mMagLayer',this,'magnetic','3','totalmag910','Total Magnetic to Pole');">Total Magnetic to Pole 910 Meters</td>
                <td><div id="horizontalSlider_tmtp910m2" dojoType="dijit.form.HorizontalSlider" value="0" minimum="0" maximum="10" discreteValues="11"
                    intermediateChanges="true" style="width:75px;"
                    onChange="dojo.byId('horizontalSlider_tmtp910m2').value = arguments[0];changeOpacity('tmtp910mMagLayer',dojo.byId('horizontalSlider_tmtp910m2').value);">
                </div></td></tr>
                </table>

                <p></p>
                <span style="font:normal normal bold 14px arial">Remote Sensing Features</span><br>
                <input type="checkbox" id="locallinears" onclick="loadNChangeMap('localScaleLinearsLayer',this,'remote_sensing','0','local_linears','Local Linears');">Local Scale Linears<br>
                <input type="checkbox" id="localovals" onclick="loadNChangeMap('localScaleOvalsLayer',this,'remote_sensing','1','local_ovals','Local Ovals');">Local Scale Ovals<br>
                <input type="checkbox" id="localtonals" onclick="loadNChangeMap('localScaleTonalsLayer',this,'remote_sensing','2','local_tonals','Local Tonals');">Local Scale Tonals<br>
                <input type="checkbox" id="mediumkarst" onclick="loadNChangeMap('mediumScaleKarstLayer',this,'remote_sensing','3','karst','Karst');">Medium Scale Karst<br>
                <input type="checkbox" id="mediumlinears" onclick="loadNChangeMap('mediumScaleLinearsLayer',this,'remote_sensing','4','medium_linears','Medium Linears');">Medium Scale Linears<br>
                <input type="checkbox" id="regionalkarst" onclick="loadNChangeMap('regionalScaleKarstLayer',this,'remote_sensing','6,11','karst','Karst');">Regional Scale Karst<br>
                <input type="checkbox" id="regionallinears" onclick="loadNChangeMap('regionalScaleLinearsLayer',this,'remote_sensing','5,9,10','regional_linears','Regional Linears');">Regional Scale Linears<br>
                <input type="checkbox" id="swksdrainage" onclick="loadNChangeMap('swKsDrainageLayer',this,'remote_sensing','8,7','swksdrainage','Drainage');">SW: Drainage/Topo<br>
            </td>
        </tr>
    </table>
    </div>
</div>



</body>
</html>
</cfoutput>

