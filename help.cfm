<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<cfoutput>
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>#application.title#  - Map Viewer Help</title>
<style type="text/css">
	fieldset, td {
		font:normal normal normal 12px arial;
		}

	legend {
		font:normal normal bold 12px arial;
		}
</style>
</head>

<body>
<div id="help">
<table width="100%">
<tr>
	<td align="left" width="50%" style="font-weight:bold">#application.title# Map Viewer Help</td>
    <td align="right" width="50%">
    	For questions about geologic data contact the <a href="mailto:lwatney@kgs.ku.edu">Principal Investigator</a> (785-864-2184).<br />
    	For map viewer questions or problems contact <a href="mailto:killion@kgs.ku.edu?subject=KGS oil and gas map viewer">GIS Services</a> (785-864-2131).
    </td>
</tr>
</table>
<p>
<fieldset>
<legend>Supported Browsers</legend>
	The following web browsers are supported:
	<ol>
    	<li>Chrome</li>
    	<li>Safari</li>
        <li>Firefox</li>
        <li>Internet Explorer</li>
    </ol>
</fieldset>
<p>
<fieldset>
<legend>Navigation</legend>
	ZOOM IN / ZOOM OUT
	<ul>
        <li>Use the slider on the left side of the map to change zoom level</li>
        <li>SHIFT and drag to select an area and zoom in</li>
        <li>Mouse scroll forward to zoom in</li>
        <li>Plus (+) key to zoom in a level</li>
        <li>SHIFT and CTRL and drag to select an area and zoom out</li>
        <li>Mouse scroll backward to zoom out</li>
        <li>Minus (-) key to zoom out a level</li>
    </ul>
    PAN
    <ul>
        <li>Use arrows on sides of map to pan</li>
        <li>Click and drag map to pan</li>
        <li>Use arrow keys to pan</li>

	</ul>
    ZOOM TO LOCATION
    <ul>
    	<li>Select the area to zoom to from the drop-down lists, or enter the name of the field to zoom to, then click the appropriate Go button.</li>
        <li>Click on the 'Zoom to Wellington Field' button to go directly to the Wellington study area.
    </ul>

</fieldset>
<p>
<fieldset>
<legend>Tabs</legend>
	LAYERS
	<ul>
    	<li>Controls which features are visible and their transparency.</li>
		<li>Layers can be turned on and off by checking and unchecking the box next to the layer name.</li>
    	<li>Some layers are only visible when zoomed in to a certain level. If the layer is not visible at the current scale, the layer name will be grayed out and an asterisk will appear after the name. To make the layer visible, zoom in and make certain the checkbox is checked.</li>
    	<li>The transparency of some layers can be controlled with the slider to the right of the layer name. Move the slider to the right to make a layer more transparent.</li>
        <li>Some layers can be turned on and off as groups by clicking the checkbox next to the heading. Layers inside the group can still be turned off and on individually.</li>
	</ul>
    <p>

    INFO
    <ul>
    	<li>Displays information about selected map features.</li>
		<li>Single click on a map feature to display information about that feature in the Info tab. If more than one feature is found, select the desired feature from the pop-up box.</li>
        <li>Click on the "Full KGS Database Entry" link at the bottom to view additional information from the Kansas Geological Survey about a well or field.</li>
        <li>Click on the "View LAS File" link to view the LAS file in a separate viewer. This link will only be visible if the oil or gas well has an associated LAS file.</li>
	</ul>

    LEGEND
    <ul>
    	<li>Displays a legend of oil and gas well symbols.</li>
    </ul>
</fieldset>
<p>
<fieldset>
<legend>Tools</legend>
	STUDY AREA
    <ul><li>Click on this link to zoom out to the full extent of the regional study area.</li></ul>
    ZOOM TO LOCATION
    <ul>
    	<li>Select the area to zoom to from the drop-down lists, or enter the name of the field to zoom to, then click the appropriate Go button.</li>
    </ul>
    FILTER WELLS
    <ul>
    	<li>Restrict which oil and gas wells, and water wells, are displayed on the map by selecting from the menu.
        <li>To turn the filter off and display all wells, either click the 'Show All Wells' button at the bottom of the map, or select 'Show All Wells' from the menu.</li>
    </ul>
	LABEL WELLS
    <ul><li>Select labels for oil and gas wells from the menu. Water wells cannot be labeled.</li></ul>
    DOWNLOAD WELLS
	<ul>
        <li>Creates a zip file containing comma-delimited text files with well, top, log, LAS, cuttings, and core information for oil and gas wells visible in the current map extent.</li>
        <li>If a filter is in effect, the download will also be filtered.</li>
        <li>If the <em>Show Wells Assigned to Selected Field</em> filter is on, all wells for the field will be downloaded, even if they are not visible in the current map extent.</li>
        <li>The dialog box will close and another will open when your files are ready (usually about 1 minute).</li>
        <li>You may continue to use the map while the progress indicator is displayed.</li>
        <li>The KID column can be used to join the tables.</li>
        <li>To open the files in Excel:</li>
    	<ul>
        	<li>Unzip the download file.</li>
        	<li>Open Excel.</li>
        	<li>Choose Open from the File menu.</li>
        	<li>Change 'Files of Type' to 'All Files'.</li>
			<li>Find your file and open.</li>
			<li>When the Text Import Wizard opens check Delimited in step 1, then click on Next.</li>
			<li>In step 2 check Comma, then click Finish (or Next if you want to format your fields before opening).</li>
        </ul>
    </ul>
    PRINT TO PDF
    <ul>
    	<li>Creates a PDF of the map (including layer transparencies and highlights) in a new browser window.</li>
        <li>The PDF can be printed or saved to disk when the PDF window opens.</li>
        <li>Choosing the "map only" option creates a jpeg image of the map without any surrounding text or map elements.</li>
        <li>NOTE: To display the PDF, pop-up blockers must be turned off or set to allow pop-ups from 'maps.kgs.ku.edu'</li>
    </ul>
    CLEAR HIGHLIGHT
    <ul><li>Click this link to remove the yellow outline around selected features.</li></ul>
	CROSS SECTION TOOLS
    <ul>
    	<li>This tool is used to select wells for inclusion in a cross section.</li>
        <li>Select a well by clicking on it.
        <li>Choose 'Add Well' to include it in the cross section, repeat to include additional wells. A light blue line will display on the map to indicate the cross section line.</li>
        <li>When finished selecting wells, click 'Create Cross Section' to launch the Java-based cross section builder.</li>
        <li>Existing cross sections can be viewed by checking the box labeled 'Cross Section Lines' under the Layers tab, then clicking on a purple cross section line on the map.</li>
    </ul>
</fieldset>
<!---<p>
<fieldset>
<legend>Printing</legend>
	A "Print Map" function will be added in a future version of the map viewer. In the meantime, there are two methods for printing or capturing the map image.
    <p>
    First, a screen capture program can be used to clip out the map and save it as a jpeg image that can be pasted into other documents. There are a variety of free and fee-based screen capture tools available on the Internet, and Windows Vista includes a Snipping Tool.
    <p>
	Second, the map can be printed from the File/Print menu of the browser. This option will also print all of the surrounding frames, including the right-side panels. To print the legend, make sure the legend tab is open. For best results, enable printing of background colors and images (see instructions for specific browsers below).
	<p>
	IE6 and IE7
    <ul>
    	<li>Go to menu Tools > Internet Options</li>
        <li>Select Advanced tab</li>
        <li>Scroll down to Printing</li>
        <li>Check 'Print background colors and images'</li>
    </ul>
    FIREFOX (Windows)
    <ul>
    	<li>Go to menu File > Page Setup</li>
        <li>Select Format & Options tab</li>
        <li>Check 'Print background colors and images'</li>
        <li>Firefox version 3+ may be required</li>
    </ul>
    FIREFOX (Mac)
    <ul>
    	<li>Go to menu File > Print</li>
        <li>Check 'Print background colors' and 'Print background images'</li>
    </ul>
    SAFARI (Mac)
    <ul>
    	<li>Go to menu File > Print</li>
        <li>Check 'Print backgrounds'</li>
    </ul>
</fieldset>--->
</div>
</body>
</html>
</cfoutput>