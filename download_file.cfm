<!--- Creates a zip file containing text files for wells, tops, logs, LAS, cuttings, and cores. --->

<cfsetting requestTimeOut = "600" showDebugOutput = "yes">

<!--- Wells: --->
<cfquery name="qWellData" datasource="plss">
	select
    	w.kid,
		w.api_number,
        w.lease_name,
        w.well_name,
        w.operator_name,
        w.field_name,
        w.township,
        w.township_direction,
        w.range,
        w.range_direction,
        w.section,
        w.subdivision_4_smallest,
        w.subdivision_3,
        w.subdivision_2,
        w.subdivision_1_largest,
        w.feet_north_from_reference,
        w.feet_east_from_reference,
        w.reference_corner,
        w.spot,
        w.nad27_longitude as longitude,
        w.nad27_latitude as latitude,
        w.county_code,
        to_char(w.permit_date,'mm/dd/yyyy') as permit_date,
        to_char(w.spud_date,'mm/dd/yyyy') as spud_date,
        to_char(w.completion_date,'mm/dd/yyyy') as completion_date,
        to_char(w.plug_date,'mm/dd/yyyy') as plug_date,
        w.status,
        w.well_class,
        w.rotary_total_depth,
        w.elevation_kb,
        w.elevation_df,
        w.elevation_gl,
        w.producing_formation,
        o.operator_name as current_op,
        c.name as county
    from
    	#application.wellsTable# w,
        nomenclature.operators o,
        global.counties c
    where
      w.operator_kid = o.kid(+)
      and
      w.county_code = c.code

	<cfswitch expression="#url.filter#">
    	<cfcase value="selected_field">
        	and field_kid = #url.field#
        </cfcase>
        <cfcase value="scanned">
        	and w.kid in (select well_header_kid from elog.scan_urls)
            and w.nad27_longitude > #url.xmin# and w.nad27_longitude < #url.xmax# and w.nad27_latitude > #url.ymin# and w.nad27_latitude < #url.ymax#
        </cfcase>
        <cfcase value="paper">
        	and w.kid in (select well_header_kid from elog.log_headers)
        	and w.nad27_longitude > #url.xmin# and w.nad27_longitude < #url.xmax# and w.nad27_latitude > #url.ymin# and w.nad27_latitude < #url.ymax#
        </cfcase>
        <cfcase value="cuttings">
        	and w.kid in (select well_header_kid from cuttings.boxes)
            and w.nad27_longitude > #url.xmin# and w.nad27_longitude < #url.xmax# and w.nad27_latitude > #url.ymin# and w.nad27_latitude < #url.ymax#
        </cfcase>
        <cfcase value="cores">
        	and w.kid in (select well_header_kid from core.core_headers)
            and w.nad27_longitude > #url.xmin# and w.nad27_longitude < #url.xmax# and w.nad27_latitude > #url.ymin# and w.nad27_latitude < #url.ymax#
        </cfcase>
        <cfcase value="active_well">
        	and status not like '%&A'
            and w.nad27_longitude > #url.xmin# and w.nad27_longitude < #url.xmax# and w.nad27_latitude > #url.ymin# and w.nad27_latitude < #url.ymax#
        </cfcase>
        <cfcase value="las">
        	and w.kid in (select well_header_kid from las.well_headers)
            and w.nad27_longitude > #url.xmin# and w.nad27_longitude < #url.xmax# and w.nad27_latitude > #url.ymin# and w.nad27_latitude < #url.ymax#
        </cfcase>
        <cfcase value="regional">
        	and w.kid in (select kid from doe_co2.all_project_wells_kid)
            and w.nad27_longitude > #url.xmin# and w.nad27_longitude < #url.xmax# and w.nad27_latitude > #url.ymin# and w.nad27_latitude < #url.ymax#
        </cfcase>
        <cfcase value="precamb">
        	and w.kid in (select kid from doe_co2.pre_camb_well_kid)
            and w.nad27_longitude > #url.xmin# and w.nad27_longitude < #url.xmax# and w.nad27_latitude > #url.ymin# and w.nad27_latitude < #url.ymax#
        </cfcase>
        <cfcase value="supertype">
        	and w.kid in (select kid from doe_co2.super_type_well_kid)
            and w.nad27_longitude > #url.xmin# and w.nad27_longitude < #url.xmax# and w.nad27_latitude > #url.ymin# and w.nad27_latitude < #url.ymax#
        </cfcase>
        <cfcase value="typewell">
        	and w.kid in (select kid from doe_co2.type_well_global_kid)
            and w.nad27_longitude > #url.xmin# and w.nad27_longitude < #url.xmax# and w.nad27_latitude > #url.ymin# and w.nad27_latitude < #url.ymax#
        </cfcase>
        <cfdefaultcase>
        	and w.nad27_longitude > #url.xmin# and w.nad27_longitude < #url.xmax# and w.nad27_latitude > #url.ymin# and w.nad27_latitude < #url.ymax#
        </cfdefaultcase>
    </cfswitch>
</cfquery>

<cfset TimeStamp = "#hour(now())##minute(now())##second(now())#">
<cfset WellsFileName = "Wells_#TimeStamp#.txt">
<cfset WellsOutputFile = "\\vmpyrite\d$\webware\Apache\Apache2\htdocs\kgsmaps\oilgas\output\#WellsFileName#">

<cfset Columns = "KID,API,LEASE_NAME,WELL_NAME,ORIG_OPERATOR,CURR_OPERATOR,FIELD_NAME,TOWNSHIP,TOWNSHIP_DIR,RANGE,RANGE_DIR,SECTION,SPOT,SUBDIVISION_4_SMALLEST,SUBDIVISION_3,SUBDIVISION_2,SUBDIVISION_1_LARGEST,FEET_NORTH,FEET_EAST,REFERENCE_CORNER,LONGITUDE,LATITUDE,COUNTY,PERMIT_DATE,SPUD_DATE,COMPLETION_DATE,PLUG_DATE,WELL_TYPE,STATUS,TOTAL_DEPTH,ELEVATION,ELEVATION_REFERENCE,PRODUCING_FORMATION">
<cffile action="write" file="#WellsOutputFile#" output="#Columns#" addnewline="yes">

<cfloop query="qWellData">
	<!--- Format elevation value: --->
	<cfif #elevation_kb# neq "">
		<cfset Elev = #elevation_kb#>
		<cfset ElevRef = "KB">
	<cfelseif #elevation_df# neq "">
		<cfset Elev = #elevation_df#>
		<cfset ElevRef = "DF">
	<cfelseif #elevation_gl# neq "">
		<cfset Elev = #elevation_gl#>
		<cfset ElevRef = "GL">
	<cfelse>
		<cfset Elev = "">
		<cfset ElevRef = "">
    </cfif>

	<cfset Record = '"#kid#","#api_number#","#lease_name#","#well_name#","#operator_name#","#current_op#","#field_name#","#township#","#township_direction#","#range#","#range_direction#","#section#","#spot#","#subdivision_4_smallest#","#subdivision_3#","#subdivision_2#","#subdivision_1_largest#","#feet_north_from_reference#","#feet_east_from_reference#","#reference_corner#","#longitude#","#latitude#","#county#","#permit_date#","#spud_date#","#completion_date#","#plug_date#","#status#","#well_class#","#rotary_total_depth#","#Elev#","#ElevRef#","#producing_formation#"'>
	<cffile action="append" file="#WellsOutputFile#" output="#Record#" addnewline="yes">
</cfloop>

<!--- Create temporary table of KIDs for use in subsequent queries (workaround for problem of Oracle's 1000 item limit in lists): --->
<cfquery name="qKIDView" datasource="plss">
    create table ogv#TimeStamp#(kid number)
</cfquery>

<cfloop query="qWellData">
	<cfquery name="qInsertKID" datasource="plss">
		insert into ogv#TimeStamp#
    	values(#kid#)
    </cfquery>
</cfloop>


<!--- Tops: --->
<cfquery name="qTopsData" datasource="plss">
	select
    	w.kid,
        w.api_number,
        w.nad27_longitude as longitude,
        w.nad27_latitude as latitude,
        w.elevation_kb,
        w.elevation_df,
        w.elevation_gl,
        t.formation_name,
        t.depth_top,
        t.depth_base,
        t.data_source,
        to_char(t.update_date,'mm/dd/yyyy') as update_date
    from
    	#application.wellsTable# w, qualified.well_tops t
    where
    	w.kid in (select kid from ogv#TimeStamp#)
        and
    	w.kid = t.well_header_kid
</cfquery>

<cfif qTopsData.recordcount gt 0>
	<cfset TopsFileName = "Tops_#TimeStamp#.txt">
    <cfset TopsOutputFile = "\\vmpyrite\d$\webware\Apache\Apache2\htdocs\kgsmaps\oilgas\output\#TopsFileName#">

	<cfset Columns = "KID,API,LONGITUDE,LATITUDE,ELEVATION,ELEVATION_REFERENCE,FORMATION,TOP,BASE,SOURCE,UPDATED">
	<cffile action="write" file="#TopsOutputFile#" output="#Columns#" addnewline="yes">

    <cfloop query="qTopsData">
        <!--- Format elevation value: --->
        <cfif #elevation_kb# neq "">
            <cfset Elev = #elevation_kb#>
            <cfset ElevRef = "KB">
        <cfelseif #elevation_df# neq "">
            <cfset Elev = #elevation_df#>
            <cfset ElevRef = "DF">
        <cfelseif #elevation_gl# neq "">
            <cfset Elev = #elevation_gl#>
            <cfset ElevRef = "GL">
        <cfelse>
            <cfset Elev = "">
            <cfset ElevRef = "">
        </cfif>
    
        <cfset Record = '"#kid#","#api_number#","#longitude#","#latitude#","#Elev#","#ElevRef#","#formation_name#","#depth_top#","#depth_base#","#data_source#","#update_date#"'>
        <cffile action="append" file="#TopsOutputFile#" output="#Record#" addnewline="yes">
    </cfloop>
</cfif>


<!--- Logs: --->
<cfquery name="qLogData" datasource="plss">
	select
      h.well_header_kid AS KID,
      'T'||w.township||w.township_direction||' R'||w.range||w.range_direction||', Sec. '||w.section||', '||w.spot||' '||w.subdivision_4_smallest||' '||w.subdivision_3||' '||w.subdivision_2 ||' '||w.subdivision_1_largest as LOCATION,
      w.operator_name AS OPERATOR,
      n.operator_name as CURROPERATOR,
      w.lease_name||' '||w.well_name as LEASE,
      w.api_number as API,
      w.elevation_kb,
      w.elevation_df,
      w.elevation_gl,
      l.logger_name as LOGGER,
      t.tool_desc AS TOOL,
      h.top as TOP,
      h.bottom as BOTTOM,
      h.bhtemp as TEMP,
      s.path_string AS SCAN,
      h.log_date as LOGDATE
    from
      elog.log_headers h,
      #application.wellsTable# w,
      nomenclature.operators n,
      elog.loggers l,
      elog.tools t,
      elog.scan_urls s
    where
      h.well_header_kid in (select kid from ogv#TimeStamp#)
      AND
      w.kid = h.well_header_kid
      AND
      h.logger_id = l.logger_id
      AND
      h.logger_id = t.logger_id
      AND
      h.tool_id = t.tool_id
      AND
      h.kid = s.log_header_kid(+)
      and
      w.operator_kid = n.kid(+)
</cfquery>

<cfif qLogData.recordcount gt 0>
	<cfset LogFileName = "Logs_#TimeStamp#.txt">
    <cfset LogOutputFile = "\\vmpyrite\d$\webware\Apache\Apache2\htdocs\kgsmaps\oilgas\output\#LogFileName#">

	<cfset Columns = "KID,LOCATION,ORIGINAL-OPERATOR,CURRENT-OPERATOR,LEASE,API,ELEVATION,LOGGER,TOOL,TOP,BOTTOM,TEMP,SCANNED,LOG_DATE">
	<cffile action="write" file="#LogOutputFile#" output="#Columns#" addnewline="yes">

    <cfloop query="qLogData">
        <!--- Format elevation value: --->
        <cfif #elevation_kb# neq "">
            <cfset Elev = #elevation_kb#>
            <cfset ElevRef = "KB">
        <cfelseif #elevation_df# neq "">
            <cfset Elev = #elevation_df#>
            <cfset ElevRef = "DF">
        <cfelseif #elevation_gl# neq "">
            <cfset Elev = #elevation_gl#>
            <cfset ElevRef = "GL">
        <cfelse>
            <cfset Elev = "">
            <cfset ElevRef = "">
        </cfif>
    
        <!--- Format scan value: --->
        <cfif #SCAN# neq "">
            <cfset Scanned = "Scanned">
        <cfelse>
            <cfset Scanned = "Unscanned">
        </cfif>
    
        <cfset Record = '"#KID#","#LOCATION#","#OPERATOR#","#CURROPERATOR#","#LEASE#","#API#","#Elev# #ElevRef#","#LOGGER#","#TOOL#","#TOP#","#BOTTOM#","#TEMP#","#Scanned#","#DateFormat(LOGDATE,'MM/DD/YYYY')#"'>
        <cffile action="append" file="#LogOutputFile#" output="#Record#" addnewline="yes">
    </cfloop>
</cfif>


<!--- LAS: --->
<cfquery name="qLASData" datasource="plss">
	select
      well_header_kid AS KID,
      las_filename as LASFILE
    from
      las.well_headers
    where
      well_header_kid in (select kid from ogv#TimeStamp#)
</cfquery>

<cfif qLASData.recordcount gt 0>
	<cfset LASFileName = "LAS_#TimeStamp#.txt">
    <cfset LASOutputFile = "\\vmpyrite\d$\webware\Apache\Apache2\htdocs\kgsmaps\oilgas\output\#LASFileName#">

	<cfset Columns = "KID,LASFILE">
	<cffile action="write" file="#LASOutputFile#" output="#Columns#" addnewline="yes">

    <cfloop query="qLASData">
        <cfset Record = '"#KID#","#LASFILE#"'>
        <cffile action="append" file="#LASOutputFile#" output="#Record#" addnewline="yes">
    </cfloop>
</cfif>


<!--- Cuttings: --->
<cfquery name="qCuttingsData" datasource="plss">
	select
    	well_header_kid,
    	box_id,
        depth_start,
        depth_stop
    from
    	cuttings.boxes
    where
    	well_header_kid in (select kid from ogv#TimeStamp#)
</cfquery>

<cfif qCuttingsData.recordcount gt 0>
	<cfset CuttingsFileName = "Cuttings_#TimeStamp#.txt">
    <cfset CuttingsOutputFile = "\\vmpyrite\d$\webware\Apache\Apache2\htdocs\kgsmaps\oilgas\output\#CuttingsFileName#">

	<cfset Columns = "KID,BOX_NUMBER,STARTING_DEPTH,ENDING_DEPTH">
	<cffile action="write" file="#CuttingsOutputFile#" output="#Columns#" addnewline="yes">

    <cfloop query="qCuttingsData">
        <cfset Record = '"#well_header_kid#","#box_id#","#depth_start#","#depth_stop#"'>
        <cffile action="append" file="#CuttingsOutputFile#" output="#Record#" addnewline="yes">
    </cfloop>
</cfif>


<!--- Cores: --->
<cfquery name="qCoreData" datasource="plss">
	select
    	h.well_header_kid as KID,
  		b.barcode as BARCODE,
  		b.facility as FACILITY,
  		b.storage_aisle as AISLE,
  		b.storage_column as STORCOL,
  		b.storage_row as STORROW,
  		b.segment_top as TOP,
        b.segment_bot as BOTTOM,
        b.coretype as CORETYPE,
        b.comments as COMM
	from
    	core.core_headers h,
  		core.core_boxedsegments b
	where
  		h.well_header_kid in (select kid from ogv#TimeStamp#)
  		and
  		h.kid = b.corehdrkid
</cfquery>

<cfif qCoreData.recordcount gt 0>
	<cfset CoreFileName = "Core_#TimeStamp#.txt">
    <cfset CoreOutputFile = "\\vmpyrite\d$\webware\Apache\Apache2\htdocs\kgsmaps\oilgas\output\#CoreFileName#">

	<cfset Columns = "KID,BARCODE,FACILITY,AISLE,COLUMN,ROW,TOP,BOTTOM,CORE_TYPE,COMMENTS">
	<cffile action="write" file="#CoreOutputFile#" output="#Columns#" addnewline="yes">

    <cfloop query="qCoreData">
        <cfset Record = '"#KID#","#BARCODE#","#FACILITY#","#AISLE#","#STORCOL#","#STORROW#","#TOP#","#BOTTOM#","#CORETYPE#","#COMM#"'>
        <cffile action="append" file="#CoreOutputFile#" output="#Record#" addnewline="yes">
    </cfloop>
</cfif>


<!--- Create zip file: --->
<cfzip action="zip"
	source="\\vmpyrite\d$\webware\Apache\Apache2\htdocs\kgsmaps\oilgas\output"
    file="\\vmpyrite\d$\webware\Apache\Apache2\htdocs\kgsmaps\oilgas\output\oilgas_#TimeStamp#.zip"
    filter="*#TimeStamp#*"
    overwrite="yes" >
    
    
<!--- Delete temporary KID table: --->
<cfquery name="qDeleteOGV" datasource="plss">
	drop table ogv#TimeStamp#
</cfquery>


<!--- xhr response text: --->
<cfoutput>
<cfif FileExists(#WellsOutputFile#)>
    <div style="font:normal normal normal 12px arial; text-align:left">
    	<ul>
        	<li>Right-click on the link below and select <em>Save Target As</em> or <em>Save Link As</em> to save the file.</li>
            <li>See the 'Download Wells' section of the Help page for information on opening these files in Excel.</li>
        </ul>
        <ul>
            <li><a href="#application.outputDir#/oilgas_#TimeStamp#.zip">oilgas_#TimeStamp#.zip</a></li>
        </ul>
    </div>
<cfelse>
	<span style="font:normal normal normal 12px arial">An error has occurred - file was not created.</span>
</cfif>
</cfoutput>