
<!---
*
*	Adding new layers or moving code to a new app:
*	Add a <cfif Find("water",VisibleLayers)> <cfimage... block for each new layer.
*	The layer designator (e.g. "water") must match the table of contents checkbox id name in index.cfm.
*
*	Also add appropriate <cfif> block to the "Reorder visible layers..." section.
--->

<cfsetting requestTimeOut = "300" showDebugOutput = "yes">

<cfset PdfFile = "co2_#hour(now())##minute(now())##second(now())#.pdf">

<cfdocument format="pdf" pagetype="letter" orientation="#url.orientation#" overwrite="yes" filename="\\vmpyrite\d$\webware\Apache\Apache2\htdocs\kgsmaps\oilgas\output\#PdfFile#">

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>#application.title# Image</title>
</head>

<body>
<cfoutput>

<!--- Set output size: --->
<cfset Aspect = #url.width# / #url.height#>

<cfswitch expression="#url.size#">
	<cfcase value="small">
    	<cfif Aspect gt 1.25>
        	<cfset ImgWidth = 500>
        <cfelse>
    		<cfset ImgWidth = 400>
        </cfif>
    </cfcase>
    <cfcase value="medium">
    	<cfif Aspect gt 1.25>
        	<cfset ImgWidth = 700>
        <cfelse>
    		<cfset ImgWidth = 600>
        </cfif>
    </cfcase>
    <!---<cfcase value="large">
    	<cfif Aspect gt 1.25>
        	<cfset ImgWidth = 900>
        <cfelse>
       		<cfset ImgWidth = 800>
        </cfif>
    </cfcase>--->
    <cfcase value="map">
    	<cfset ImgWidth = #url.width#>
		<cfset ImgHeight = #url.height#>
        <!---<cfimage name="scalebar" source="images/scalebars/#url.level#.gif">--->
    </cfcase>
    <cfcase value="fixed">
    	<cfset ImgWidth = 775>
        <cfset ImgHeight = 575>
    </cfcase>
</cfswitch>

<!--- Resize scalebar image: --->
<!---<cfimage name="scalebar" source="images/scalebars/#url.level#.gif">
<cfset WidthRatio = (ImgWidth/#url.width#) * 100>
<cfset ImageResize(scalebar, "#WidthRatio#%", "")>--->

<!---<cfif url.size neq "map">
	<cfset ImgHeight = Int(ImgWidth / Aspect)>
</cfif>--->

<!--- Reverse order of visible layers so bottom layer is first in list: --->
<cfset VisibleLayers = "">
<cfloop list="#url.vislyrs#" index="i">
	<cfset VisibleLayers = ListPrepend(VisibleLayers,#i#)>
</cfloop>

<!--- Create a blank image. Solves problem that occurred when trying to print just 2 layers. Prepend to visible layers list so it gets placed on bottom: --->
<cfset Blank = ImageNew("", #ImgWidth#, #ImgHeight#, "argb")>
<cfset VisibleLayers = ListPrepend(VisibleLayers, "Blank")>

<cfset ImageSetAntialiasing(Blank)>

<!--- Create cfimages for each visible layer: --->
<cfif Find("fields",VisibleLayers)>
	<!---<cfimage
    	name="fields"
        source="http://mapserver1.kansasgis.org/arcgis/rest/services/oilgas/oilgas_fields_sort_102100/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:1"
    />--->
    <cfimage
    	name="fields"
        source="http://services.kgs.ku.edu/arcgis/rest/services/oilgas/oilgas_fields_tld/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true"
    />
</cfif>

<!---<cfif Find("crosssections",VisibleLayers)>
	<cfimage
    	name="crosssections"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/general/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:9"
    />
</cfif>--->

<cfif Find("wells",VisibleLayers)>
	<!--- Create layer definition for each well filter type: --->
    <cfset LayerDef = "">
    <cfswitch expression="#url.filter#">
    	<cfcase value="selected_field">
        	<cfset LayerDef = "FIELD_KID=" & #url.currfield#>
        </cfcase>
        <cfcase value="scanned">
        	<cfset LayerDef = URLEncodedFormat("KID IN (SELECT WELL_HEADER_KID FROM ELOG.SCAN_URLS)")>
        </cfcase>
        <cfcase value="paper">
        	<cfset LayerDef = URLEncodedFormat("KID IN (SELECT WELL_HEADER_KID FROM ELOG.LOG_HEADERS)")>
        </cfcase>
        <cfcase value="cuttings">
        	<cfset LayerDef = URLEncodedFormat("KID IN (SELECT WELL_HEADER_KID FROM CUTTINGS.BOXES)")>
        </cfcase>
        <cfcase value="cores">
        	<cfset LayerDef = URLEncodedFormat("KID IN (SELECT WELL_HEADER_KID FROM CORE.CORE_HEADERS)")>
        </cfcase>
        <cfcase value="active_well">
        	<cfset LayerDef = URLEncodedFormat("STATUS NOT LIKE '%&A'")>
        </cfcase>
        <cfcase value="las">
        	<cfset LayerDef = URLEncodedFormat("KID IN (SELECT WELL_HEADER_KID FROM LAS.WELL_HEADERS WHERE PROPRIETARY = 0)")>
        </cfcase>
        <cfcase value="regional">
        	<cfset LayerDef = URLEncodedFormat("KID IN (SELECT KID FROM DOE_CO2.ALL_PROJECT_WELLS_KID)")>
        </cfcase>
        <cfcase value="precamb">
        	<cfset LayerDef = URLEncodedFormat("KID IN (SELECT KID FROM DOE_CO2.PRE_CAMB_WELL_KID)")>
        </cfcase>
        <cfcase value="supertype">
        	<cfset LayerDef = URLEncodedFormat("kid in (select kid from doe_co2.super_type_well_kid)")>
        </cfcase>
        <cfcase value="typewell">
        	<cfset LayerDef = URLEncodedFormat("kid in (select kid from doe_co2.type_well_global_kid)")>
        </cfcase>
        <cfcase value="las3">
        	<cfset LayerDef = URLEncodedFormat("kid in (select well_header_kid from las3.well_headers where " & #url.las3where# & ")")>
        </cfcase>
    </cfswitch>

	<cfif url.filter eq "none">
        <cfimage
        	name="wells"
            source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/general/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&layers=show:#url.labelid#&transparent=true"
    	/>
    <cfelse>
    	<cfimage
        	name="wells"
            source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/general/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&layers=show:#url.labelid#&transparent=true&layerDefs=#url.labelid#:#LayerDef#"
    	/>
    </cfif>
</cfif>

<cfif Find("wwc5",VisibleLayers)>
	<cfset wwc5LayerDef = "">
	<cfif #url.wwc5_filter# eq "remove_monitoring">
    	<cfset wwc5LayerDef = URLEncodedFormat("water_use_code not in (8,10,11,122,240,242,245)")>
    </cfif>

	<cfimage
        name="wwc5"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/general/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:8&layerDefs=8:#wwc5LayerDef#"
    />
</cfif>


<cfif Find("hrzwells",VisibleLayers)>
	<cfimage
    	name="hrzwells"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/general/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:11"
    />
</cfif>

<cfif Find("modelareas",VisibleLayers)>
	<cfimage
    	name="modelareas"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/general/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:12"
    />
</cfif>

<cfif Find("plss",VisibleLayers)>
	<cfimage
    	name="plss"
        source="http://services.kgs.ku.edu/arcgis/rest/services/PLSS/section_township_range/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true"
    />
</cfif>

<!---<cfif Find("water",VisibleLayers)>
	<cfimage
        name="water"
        source="http://giselle.kgs.ku.edu:80/arcgis/rest/services/water_features/MapServer/export?bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true"
    />
</cfif>--->

<cfif Find("drg",VisibleLayers)>
	<cfimage
    	name="drg"
        source="http://imageserver.kansasgis.org/arcgis/rest/services/Statewide/DRG/ImageServer/exportImage?bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&imagesr=102100&bboxsr=102100&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&layers=show:2&transparent=true"
    />
</cfif>

<cfif Find("naip12",VisibleLayers)>
	<cfimage
    	name="naip12"
        source="http://services.kgs.ku.edu/arcgis/rest/services/Statewide/2012_NAIP_1m_Color/ImageServer/exportImage?bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&imagesr=102100&bboxsr=102100&size=#ImgWidth#,#ImgHeight#&format=jpg&f=image&layers=show:1"
    />
</cfif>

<!---<cfif Find("doqq02",VisibleLayers)>
	<cfimage
    	name="doqq02"
        source="http://giselle.kgs.ku.edu:80/arcgis/rest/services/ImageServer/2002_DOQQ_1m_bw/ImageServer/exportImage?bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&imagesr=102100&bboxsr=102100&size=#ImgWidth#,#ImgHeight#&format=jpg&f=image"
    />
</cfif>--->

<cfif Find("base",VisibleLayers)>
	<cfimage
    	name="base"
        source="http://server.arcgisonline.com/ArcGIS/rest/services/World_Topo_Map/MapServer/export?bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image"
    />
</cfif>

<cfif Find("locallinears",VisibleLayers)>
	<cfimage
    	name="locallinears"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/remote_sensing_features/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&layers=show:0&transparent=true"
    />
</cfif>

<cfif Find("localovals",VisibleLayers)>
	<cfimage
    	name="localovals"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/remote_sensing_features/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&layers=show:1&transparent=true"
    />
</cfif>

<cfif Find("localtonals",VisibleLayers)>
	<cfimage
    	name="localtonals"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/remote_sensing_features/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&layers=show:2&transparent=true"
    />
</cfif>

<cfif Find("mediumkarst",VisibleLayers)>
	<cfimage
    	name="mediumkarst"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/remote_sensing_features/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&layers=show:3&transparent=true"
    />
</cfif>

<cfif Find("mediumlinears",VisibleLayers)>
	<cfimage
    	name="mediumlinears"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/remote_sensing_features/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&layers=show:4&transparent=true"
    />
</cfif>

<cfif Find("regionallinears",VisibleLayers)>
	<cfimage
    	name="regionallinears"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/remote_sensing_features/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&layers=show:5&transparent=true"
    />
</cfif>

<cfif Find("regionalkarst",VisibleLayers)>
	<cfimage
    	name="regionalkarst"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/remote_sensing_features/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&layers=show:6&transparent=true"
    />
</cfif>

<cfif Find("ga210m",VisibleLayers)>
	<cfimage
    	name="ga210m"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/gravity/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:0"
    />
</cfif>

<cfif Find("gta",VisibleLayers)>
	<cfimage
    	name="gta"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/gravity/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:1"
    />
</cfif>

<cfif Find("rbg700m",VisibleLayers)>
	<cfimage
    	name="rbg700m"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/gravity/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:2"
    />
</cfif>

<cfif Find("taga210m",VisibleLayers)>
	<cfimage
    	name="taga210m"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/gravity/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:3"
    />
</cfif>

<cfif Find("tatm",VisibleLayers)>
	<cfimage
    	name="tatm"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/magnetic/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:0"
    />
</cfif>

<cfif Find("tatm210m",VisibleLayers)>
	<cfimage
    	name="tatm210m"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/magnetic/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:1"
    />
</cfif>

<cfif Find("tma210m",VisibleLayers)>
	<cfimage
    	name="tma210m"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/magnetic/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:2"
    />
</cfif>

<cfif Find("tmtp910m",VisibleLayers)>
	<cfimage
    	name="tmtp910m"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/magnetic/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:3"
    />
</cfif>

<cfif Find("misssubsea",VisibleLayers)>
	<cfimage
    	name="misssubsea"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/regional_geology/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:9"
    />
</cfif>

<cfif Find("arbksubsea",VisibleLayers)>
	<cfimage
    	name="arbksubsea"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/regional_geology/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:21"
    />
</cfif>

<cfif Find("missmissbaseiso",VisibleLayers)>
	<cfimage
    	name="missmissbaseiso"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/regional_geology/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:32"
    />
</cfif>

<cfif Find("chasesubsea",VisibleLayers)>
	<cfimage
    	name="chasesubsea"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/regional_geology/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:33"
    />
</cfif>

<cfif Find("arbkisopach",VisibleLayers)>
	<cfimage
    	name="arbkisopach"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/regional_geology/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:24"
    />
</cfif>

<cfif Find("hbnrsubsea",VisibleLayers)>
	<cfimage
    	name="hbnrsubsea"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/regional_geology/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:18"
    />
</cfif>

<cfif Find("kasisopach",VisibleLayers)>
	<cfimage
    	name="kasisopach"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/regional_geology/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:12"
    />
</cfif>

<cfif Find("tippisopach",VisibleLayers)>
	<cfimage
    	name="tippisopach"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/regional_geology/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:0"
    />
</cfif>

<cfif Find("isochattmiss",VisibleLayers)>
	<cfimage
    	name="isochattmiss"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/regional_geology/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:27"
    />
</cfif>

<cfif Find("missleakage",VisibleLayers)>
	<cfimage
    	name="missleakage"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/faults/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:0"
    />
</cfif>

<cfif Find("bmissleakage",VisibleLayers)>
	<cfimage
    	name="bmissleakage"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/faults/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:1"
    />
</cfif>

<cfif Find("arbkleakage",VisibleLayers)>
	<cfimage
    	name="arbkleakage"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/faults/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:2"
    />
</cfif>

<cfif Find("arbkfaults",VisibleLayers)>
	<cfimage
    	name="arbkfaults"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/faults/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:3"
    />
</cfif>

<cfif Find("precambsubsea",VisibleLayers)>
	<cfimage
    	name="precambsubsea"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/regional_geology/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:3"
    />
</cfif>

<cfif Find("isojccroub",VisibleLayers)>
	<cfimage
    	name="isojccroub"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/regional_geology/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:15"
    />
</cfif>

<cfif Find("isoroubgas",VisibleLayers)>
	<cfimage
    	name="isoroubgas"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/regional_geology/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:30"
    />
</cfif>

<cfif Find("isogasgunter",VisibleLayers)>
	<cfimage
    	name="isogasgunter"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/regional_geology/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:28"
    />
</cfif>

<cfif Find("isogunterpc",VisibleLayers)>
	<cfimage
    	name="isogunterpc"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/regional_geology/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:29"
    />
</cfif>

<cfif Find("precambdepth",VisibleLayers)>
	<cfimage
    	name="precambdepth"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/regional_geology/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:6"
    />
</cfif>

<cfif Find("abwseismic",VisibleLayers)>
	<cfimage
    	name="abwseismic"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/seismic/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:0"
    />
</cfif>

<cfif Find("morrowdsseismic",VisibleLayers)>
	<cfimage
    	name="morrowdsseismic"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/seismic/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:5"
    />
</cfif>

<cfif Find("morrowtimeseismic",VisibleLayers)>
	<cfimage
    	name="morrowtimeseismic"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/seismic/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:3"
    />
</cfif>

<cfif Find("meramecdsseismic",VisibleLayers)>
	<cfimage
    	name="meramecdsseismic"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/seismic/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:4"
    />
</cfif>

<cfif Find("arbuckletimeseismic",VisibleLayers)>
	<cfimage
    	name="arbuckletimeseismic"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/seismic/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:1"
    />
</cfif>

<cfif Find("pcbasetimeseismic",VisibleLayers)>
	<cfimage
    	name="pcbasetimeseismic"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/seismic/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:2"
    />
</cfif>

<cfif Find("swksinfdrainage",VisibleLayers)>
	<cfimage
    	name="swksinfdrainage"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/remote_sensing_features/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&layers=show:7&transparent=true"
    />
</cfif>

<cfif Find("swksdrainage",VisibleLayers)>
	<cfimage
    	name="swksdrainage"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/remote_sensing_features/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&layers=show:8&transparent=true"
    />
</cfif>

<cfif Find("swkssatinf",VisibleLayers)>
	<cfimage
    	name="swkssatinf"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/remote_sensing_features/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&layers=show:10&transparent=true"
    />
</cfif>

<cfif Find("swkssat",VisibleLayers)>
	<cfimage
    	name="swkssat"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/remote_sensing_features/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&layers=show:9&transparent=true"
    />
</cfif>

<cfif Find("swkskarst",VisibleLayers)>
	<cfimage
    	name="swkskarst"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/remote_sensing_features/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&layers=show:11&transparent=true"
    />
</cfif>

<cfif Find("ftrileydip",VisibleLayers)>
	<cfimage
    	name="ftrileydip"
        source="http://services.kgs.ku.edu/arcgis/rest/services/CO2/regional_geology/MapServer/export?bboxSR=102100&bbox=#url.xmin#,#url.ymin#,#url.xmax#,#url.ymax#&size=#ImgWidth#,#ImgHeight#&format=png24&f=image&transparent=true&layers=show:31"
    />
</cfif>


<!--- Remove group layer headings from visible layers list: --->
<cfif FindNoCase('locals', VisibleLayers)>
	<cfset VisibleLayers = Replace(VisibleLayers, 'locals', '')>
</cfif>

<cfif FindNoCase('mediums', VisibleLayers)>
	<cfset VisibleLayers = Replace(VisibleLayers, 'mediums', '')>
</cfif>

<cfif FindNoCase('regionals', VisibleLayers)>
	<cfset VisibleLayers = Replace(VisibleLayers, 'regionals', '')>
</cfif>

<cfif Find(',,', VisibleLayers)>
	<cfset VisibleLayers = Replace(VisibleLayers, ',,', ',')>
</cfif>

<!--- Reorder visible layers list to desired draw order (bottom layer first, top layer last): --->
<cfset VisLayersReordered = "Blank">
<cfif FindNoCase('base', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'base')>
</cfif>
<cfif FindNoCase('doqq02', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'doqq02')>
</cfif>
<cfif FindNoCase('naip12', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'naip12')>
</cfif>
<cfif FindNoCase('drg', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'drg')>
</cfif>
<cfif FindNoCase('ftrileydip', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'ftrileydip')>
</cfif>
<cfif FindNoCase('fields', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'fields')>
</cfif>
<cfif FindNoCase('locallinears', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'locallinears')>
</cfif>
<cfif FindNoCase('localovals', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'localovals')>
</cfif>
<cfif FindNoCase('localtonals', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'localtonals')>
</cfif>
<cfif FindNoCase('mediumkarst', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'mediumkarst')>
</cfif>
<cfif FindNoCase('mediumlinears', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'mediumlinears')>
</cfif>
<cfif FindNoCase('regionallinears', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'regionallinears')>
</cfif>
<cfif FindNoCase('regionalkarst', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'regionalkarst')>
</cfif>
<cfif FindNoCase('ga210m', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'ga210m')>
</cfif>
<cfif FindNoCase('gta', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'gta')>
</cfif>
<cfif FindNoCase('rbg700m', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'rbg700m')>
</cfif>
<cfif FindNoCase('taga210m', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'taga210m')>
</cfif>
<cfif FindNoCase('tatm', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'tatm')>
</cfif>
<cfif FindNoCase('tatm210m', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'tatm210m')>
</cfif>
<cfif FindNoCase('tma210m', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'tma210m')>
</cfif>
<cfif FindNoCase('tmtp910m', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'tmtp910m')>
</cfif>
<cfif FindNoCase('abwseismic', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'abwseismic')>
</cfif>

<cfif FindNoCase('morrowdsseismic', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'morrowdsseismic')>
</cfif>
<cfif FindNoCase('morrowtimeseismic', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'morrowtimeseismic')>
</cfif>
<cfif FindNoCase('meramecdsseismic', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'meramecdsseismic')>
</cfif>
<cfif FindNoCase('arbuckletimeseismic', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'arbuckletimeseismic')>
</cfif>
<cfif FindNoCase('pcbasetimeseismic', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'pcbasetimeseismic')>
</cfif>

<cfif FindNoCase('plss', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'plss')>
</cfif>
<cfif FindNoCase('misssubsea', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'misssubsea')>
</cfif>
<cfif FindNoCase('arbksubsea', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'arbksubsea')>
</cfif>
<cfif FindNoCase('arbkisopach', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'arbkisopach')>
</cfif>
<cfif FindNoCase('hbnrsubsea', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'hbnrsubsea')>
</cfif>
<cfif FindNoCase('isochattmiss', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'isochattmiss')>
</cfif>
<cfif FindNoCase('kasisopach', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'kasisopach')>
</cfif>
<cfif FindNoCase('tippisopach', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'tippisopach')>
</cfif>
<cfif FindNoCase('precambsubsea', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'precambsubsea')>
</cfif>
<cfif FindNoCase('arbkfaults', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'arbkfaults')>
</cfif>

<cfif FindNoCase('missleakage', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'missleakage')>
</cfif>
<cfif FindNoCase('bmissleakage', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'bmissleakage')>
</cfif>
<cfif FindNoCase('arbkleakage', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'arbkleakage')>
</cfif>

<cfif FindNoCase('isojccroub', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'isojccroub')>
</cfif>
<cfif FindNoCase('isoroubgas', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'isoroubgas')>
</cfif>
<cfif FindNoCase('isogasgunter', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'isogasgunter')>
</cfif>
<cfif FindNoCase('isogunterpc', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'isogunterpc')>
</cfif>
<cfif FindNoCase('precambdepth', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'precambdepth')>
</cfif>
<cfif FindNoCase('swksinfdrainage', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'swksinfdrainage')>
</cfif>
<cfif FindNoCase('swksdrainage', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'swksdrainage')>
</cfif>
<cfif FindNoCase('swkssat', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'swkssat')>
</cfif>
<cfif FindNoCase('swkssatinf', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'swkssatinf')>
</cfif>
<cfif FindNoCase('swkskarst', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'swkskarst')>
</cfif>

<cfif FindNoCase('missmissbaseiso', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'missmissbaseiso')>
</cfif>
<cfif FindNoCase('chasesubsea', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'chasesubsea')>
</cfif>

<cfif FindNoCase('modelareas', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'modelareas')>
</cfif>


<cfif FindNoCase('wwc5', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'wwc5')>
</cfif>
<cfif FindNoCase('wells', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'wells')>
</cfif>
<cfif FindNoCase('hrzwells', VisibleLayers)>
	<cfset VisLayersReordered = ListAppend(VisLayersReordered, 'hrzwells')>
</cfif>


<cfif ListLen(VisLayersReordered) eq 0>
	<!--- Warn user: --->
	Error: At least one layer must be visible to print an image.
</cfif>

<cfif ListLen(VisLayersReordered) gt 1>
	<!--- Stack the bottom 2 image: --->
    <!--- ListGetAt function was used because any layer could be the bottom layer. Now code has been changed so "Blank" is always the bottom layer, but left ListGetAt in anyway. --->
	<cfset ImagePaste(#Evaluate(ListGetAt(VisLayersReordered,1))#, #Evaluate(ListGetAt(VisLayersReordered,2))#, 0, 0)>
    <cfif ListLen(VisLayersReordered) gt 2>
    	<!--- Stack additional images. Target image is always the first (bottom) one: --->
    	<cfloop index="i" from="3" to="#ListLen(VisLayersReordered)#">
    		<cfset ImagePaste(#Evaluate(ListGetAt(VisLayersReordered,1))#, #Evaluate(ListGetAt(VisLayersReordered,i))#, 0, 0)>
    	</cfloop>
    </cfif>
</cfif>

<!--- Add KGS and date text to image: --->
<cfset Today = DateFormat(Now(),"mm/dd/yyyy")>

<cfset attr.font = "arial">
<cfset attr.size = 10>
<cfset attr.style = "bold">

<cfset ImageSetDrawingColor(#Evaluate(ListGetAt(VisLayersReordered,1))#, "##000000")>
<cfset ImageDrawText(#Evaluate(ListGetAt(VisLayersReordered,1))#, "Kansas Geological Survey - #Today#", #ImgWidth# - 200, #ImgHeight# - 5, attr)>

<!--- Add scalebar: --->
<!---<cfif url.size eq "small">
	<cfset ImagePaste(#Evaluate(ListGetAt(VisibleLayers,1))#, #scalebar#, #ImgWidth# - (#ImgWidth# - 5), #ImgHeight# - 21)>
<cfelseif url.size eq "medium">
	<cfset ImagePaste(#Evaluate(ListGetAt(VisibleLayers,1))#, #scalebar#, #ImgWidth# - (#ImgWidth# - 5), #ImgHeight# - 25)>
<cfelse>
	<cfset ImagePaste(#Evaluate(ListGetAt(VisibleLayers,1))#, #scalebar#, #ImgWidth# - (#ImgWidth# - 5), #ImgHeight# - 35)>
</cfif>--->

<!--- Add border: --->
<!--- ImageAddBorder function and <cfimage action="border"> produced Band Count error, so am creating border by drawing a rectangle on the image: --->
<cfset strokeAttr.width= 4>
<cfset ImageSetDrawingStroke(#Evaluate(ListGetAt(VisLayersReordered,1))#,strokeAttr)>
<cfset ImageDrawRect(#Evaluate(ListGetAt(VisLayersReordered,1))#, 0, 0, #ImgWidth#, #ImgHeight#, "no")>

<!--- Display the final image: --->
<!---<span style="font:normal normal bold 12px Arial">To save the image to your computer, right-click on the image and select <em>Save Picture As</em> or <em>Save Image As</em>.<br />--->
<p>
<!---<cfimage action="writeToBrowser" source="#Evaluate(ListGetAt(VisibleLayers,1))#">--->
<cfset TimeStamp = "#hour(now())##minute(now())##second(now())#">
<cfimage
       action="write"
       source="#Evaluate(ListGetAt(VisLayersReordered,1))#"
       overwrite="true"
       destination="\\vmpyrite\d$\webware\Apache\Apache2\htdocs\kgsmaps\oilgas\output\co2_#TimeStamp#.png">

<div align="center">
	<table border="0">
    	<tr><td style="font-weight:bold; font-size:24px; text-align:center">#url.pdftitle#</td></tr>
        <tr><td align="center"><img src="#application.outputDir#/co2_#TimeStamp#.png"></td></tr>
        <tr><td align="left" width="#ImgWidth#px">#url.pdfnotes#</td></tr>
    </table>
</div>

</cfoutput>

</body>
</html>
</cfdocument>

<cfoutput>
<script type="text/javascript">
	window.location = '#application.outputDir#/#PdfFile#';
</script>
</cfoutput>
