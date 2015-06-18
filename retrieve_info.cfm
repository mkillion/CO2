<cfsetting requestTimeOut = "3600" showDebugOutput = "yes"><head>

<style type="text/css">
	.info_label {
		font:normal normal normal 11px Arial;
		color:#CC0000;
		}

	.info_text {
		font:normal normal normal 11px Arial;
		}
</style>
</head>

<cfprocessingdirective suppresswhitespace="yes">
<cfif url.get eq "well">
	<!--- Get well info: --->
    <cfquery name="qWell_Headers" datasource="plss">
        select
        	api_number,
            lease_name,
            well_name,
            operator_name,
            field_name,
            township,
            township_direction,
            range,
            range_direction,
            section,
            subdivision_4_smallest,
            subdivision_3,
            subdivision_2,
            subdivision_1_largest,
            operator_kid,
            feet_north_from_reference,
            feet_east_from_reference,
            reference_corner,
            spot,
            nad27_longitude as longitude,
            nad27_latitude as latitude,
            county_code,
            permit_date,
            spud_date,
            completion_date,
            plug_date,
            status,
            well_class,
            rotary_total_depth,
            elevation,
            elevation_kb,
            elevation_df,
            elevation_gl,
            producing_formation,
            initial_production_oil,
            initial_production_water,
            initial_production_gas
        from
        	qualified.well_headers
        where
        	kid = #url.kid#
    </cfquery>

    <!--- Get current operator: --->
    <cfif qWell_Headers.operator_kid neq "">
        <cfquery name="qOperators" datasource="plss">
            select operator_name
            from nomenclature.operators
            where kid = #qWell_Headers.operator_kid#
        </cfquery>
        <cfset CurrOperator = qOperators.operator_name>
    <cfelse>
        <cfset CurrOperator = "">
    </cfif>

    <!--- Lookup county name: --->
    <cfquery name="qCounty" datasource="plss">
        select name
        from global.counties
        where code = #qWell_Headers.county_code#
    </cfquery>
    <cfset CountyName = qCounty.name>

    <!--- Format location: --->
    <cfoutput query="qWell_Headers">
        <cfset Location = "T" & #township# & #township_direction# & " R" & #range# & #range_direction# & " Sec. " & #section#>
        <cfset Quarters = #spot# & " " & #subdivision_4_smallest# & " " & #subdivision_3# & " " & #subdivision_2# & " " & #subdivision_1_largest#>

        <cfif #feet_north_from_reference# lt 0>
            <cfset NS_Dir = "South">
        <cfelse>
            <cfset NS_Dir = "North">
        </cfif>

        <cfif #feet_east_from_reference# lt 0>
            <cfset EW_Dir = "West">
        <cfelse>
            <cfset EW_Dir = "East">
        </cfif>

        <cfif #feet_north_from_reference# neq "" and #feet_east_from_reference# neq "">
            <cfset Footage_1 = Abs(#feet_north_from_reference#) & " " & NS_Dir & ", " & Abs(#feet_east_from_reference#) & " " & EW_Dir>
            <cfset Footage_2 = " from " & #reference_corner# & " corner">
        <cfelse>
            <cfset Footage_1 = "">
            <cfset Footage_2 = "">
        </cfif>
    </cfoutput>

    <!--- Format elevation value: --->
    <cfif qWell_Headers.elevation_kb neq "">
        <cfset Elev = qWell_Headers.elevation_kb & " KB">
    <cfelseif qWell_Headers.elevation_df neq "">
        <cfset Elev = qWell_Headers.elevation_df & " DF">
    <cfelseif qWell_Headers.elevation_gl neq "">
        <cfset Elev = qWell_Headers.elevation_gl & " GL">
    <cfelseif qWell_Headers.elevation neq "">
        <cfset Elev = qWell_Headers.elevation & " est.">
    <cfelse>
        <cfset Elev = "">
    </cfif>

    <!--- Check for LAS 2 file: --->
    <cfquery name="qCheckLAS" datasource="plss">
    	select
        	kid,
            rownum
        from
        	las.well_headers
        where
    		well_header_kid = #url.kid#
            and
            proprietary = 0
    </cfquery>

    <!--- Check for LAS 3 file: --->
    <cfquery name="qCheckLAS3" datasource="plss">
    	select
        	kid,
            las_url,
            rownum
        from
        	las3.well_headers
        where
    		well_header_kid = #url.kid#
            and
            proprietary = 0
    </cfquery>

    <!--- Format response text: --->
    <cfoutput query="qWell_Headers">
        <span class='layer_name'>&nbsp;<strong>OIL or GAS WELL</strong></span><br />
        <table cellspacing='0' width='100%'>
            <tr style='background-color:##D9E6FB'><td class='info_label'>API:</td><td class='info_text'>#api_number#</td></tr>
            <tr><td class='info_label'>Lease:</td><td class='info_text'>#lease_name#</td></tr>
            <tr style='background-color:##D9E6FB'><td class='info_label'>Well:</td><td class='info_text'>#well_name#</td></tr>
            <tr><td class='info_label'>Original Operator:</td><td class='info_text'>#operator_name#</td></tr>
            <tr style='background-color:##D9E6FB'><td class='info_label'>Current Operator:</td><td class='info_text'>#CurrOperator#</td></tr>
            <tr><td class='info_label'>Field:</td><td class='info_text'>#field_name#</td></tr>
            <tr style='background-color:##D9E6FB'>
                <td class='info_label'>Location:</td>
                <td class='info_text'>#Location#<br />#Quarters#<br />#Footage_1#<br />#Footage_2#</td>
            </tr>
            <tr><td class='info_label'>Longitude:</td><td class='info_text'>#longitude#</td></tr>
            <tr style='background-color:##D9E6FB'><td class='info_label'>Latitude:</td><td class='info_text'>#latitude#</td></tr>
            <tr><td class='info_label'>County:</td><td class='info_text'>#CountyName#</td></tr>
            <tr style='background-color:##D9E6FB'><td class='info_label'>Permit Date:</td><td class='info_text'>#DateFormat(permit_date,'mmm-dd-yyyy')#</td></tr>
            <tr><td class='info_label'>Spud Date:</td><td class='info_text'>#DateFormat(spud_date,'mmm-dd-yyyy')#</td></tr>
            <tr style='background-color:##D9E6FB'><td class='info_label'>Completion Date:</td><td class='info_text'>#DateFormat(completion_date,'mmm-dd-yyyy')#</td></tr>
            <tr><td class='info_label'>Plugging Date:</td><td class='info_text'>#DateFormat(plug_date,'mmm-dd-yyyy')#</td></tr>
            <tr style='background-color:##D9E6FB'><td class='info_label'>Well Type:</td><td class='info_text'>#status#</td></tr>
            <tr><td class='info_label'>Status:</td><td class='info_text'>#well_class#</td></tr>
            <tr style='background-color:##D9E6FB'><td class='info_label'>Total Depth:</td><td class='info_text'>#rotary_total_depth#</td></tr>
            <tr><td class='info_label'>Elevation:</td><td class='info_text'>#Elev#</td></tr>
            <tr style='background-color:##D9E6FB'><td class='info_label'>Producing Formation:</td><td class='info_text'>#producing_formation#</td></tr>
            <tr><td class='info_label'>IP Oil (bbl):</td><td class='info_text'>#initial_production_oil#</td></tr>
            <tr style='background-color:##D9E6FB'><td class='info_label'>IP Water (bbl):</td><td class='info_text'>#initial_production_water#</td></tr>
            <tr><td class='info_label'>IP Gas (mcf):</td><td class='info_text'>#initial_production_gas#</td></tr>
            </table>
            <p>
            <b>Links:</b>
            <ul>
                <li><a href="http://chasm.kgs.ku.edu/apex/qualified.well_page.DisplayWell?f_kid=#url.kid#" target="_blank">Full KGS Database Entry</a></li>
            </ul>

            <!--- LAS 2 link: --->
			<!---<cfif qCheckLAS.recordcount gt 0>
                <cfif qCheckLAS.recordcount eq 1>
                    <b>#qCheckLAS.recordcount# LAS 2 file found:</b>
                <cfelse>
                    <b>#qCheckLAS.recordcount# LAS 2 files found:</b>
                </cfif>
            </cfif>--->

            <ul>
                <cfloop query="qCheckLAS">
                	<li><a href="http://www.kgs.ku.edu/Gemini/LAS.html?sAPI=#url.api#&sKID=#kid#" target="_blank">View LAS-2 file #rownum#</a></li>
                </cfloop>
            </ul>

            <!--- LAS 3 link: --->
           <!--- <cfif qCheckLAS3.recordcount gt 0>
                <cfif qCheckLAS3.recordcount eq 1>
                    <b>#qCheckLAS3.recordcount# LAS 3 file found:</b>
                <cfelse>
                    <b>#qCheckLAS3.recordcount# LAS 3 files found:</b>
                </cfif>
            </cfif>--->

            <ul>
                <cfloop query="qCheckLAS3">
                	<!---<li><a href="#las_url#" target="_blank">View LAS-3 file #rownum#</a></li>--->
                    <li><a href="http://www.kgs.ku.edu/PRS/Ozark/Applet/GProfile.html?sKID=#kid#" target="_blank">View LAS-3 file #rownum#</a></li>
                </cfloop>
            </ul>
    </cfoutput>
</cfif>


<cfif url.get eq "field">
	<!--- Get field info from fields and reservoir tables: --->
    <cfquery name="qFields" datasource="plss">
        select
        	field_name,
            status,
            decode(type_of_field,
            	'OIL', 'Oil',
            	'GAS', 'Gas',
                'O&G', 'Oil and Gas') as type_of_field,
            produces_gas,
            produces_oil
        from
        	nomenclature.fields
        where
        	kid = #url.kid#
    </cfquery>

    <cfquery name="qFormations" datasource="plss">
        select formation_name
        from nomenclature.fields_reservoirs
        where field_kid = #url.kid#
    </cfquery>

    <!--- Lookup counties field occupies: --->
    <!---<cfquery name="qCounties" datasource="plss">
        select name
        from global.counties
        where code in
            (select county_code
            from nomenclature.fields_counties
            where field_kid = #url.kid#)
    </cfquery>--->

    <!--- Format response text: --->
    <cfoutput query="qFields">
        <span class='layer_name'>&nbsp;<strong>FIELD</strong></span><br />
        <table cellspacing='0' width='100%'>
            <tr style='background-color:##D9E6FB'><td class='info_label'>Name:</td><td class='info_text'>#field_name#</td></tr>
            <tr><td class='info_label'>Status:</td><td class='info_text'>#status#</td></tr>
            <tr style='background-color:##D9E6FB'><td class='info_label'>Type of Field:</td><td class='info_text'>#type_of_field#</td></tr>
            <tr><td class='info_label'>Produces Oil:</td><td class='info_text'>#produces_oil#</td></tr>
            <tr style='background-color:##D9E6FB'><td class='info_label'>Produces Gas:</td><td class='info_text'>#produces_gas#</td></tr>
            <tr>
                <td class='info_label'>Producing Formations:</td>
                <td class='info_text'>
                    <cfloop query="qFormations">
                        #formation_name#<br />
                    </cfloop>
                </td>
            </tr>
            <!---<tr>
                <td class='info_label'>Counties:</td>
                <td class='info_text'>
                    <cfloop query="qCounties">
                        #name#<br />
                    </cfloop>
                </td>
            </tr>--->
        </table>
        <p>
        <b>Links:</b>
        <ul>
            <li><a href="http://chasm.kgs.ku.edu/apex/oil.ogf4.IDProdQuery?FieldNumber=#url.kid#" target="_blank">Full KGS Database Entry</a></li>
            <p>
            <li><a href="http://www.kgs.ku.edu/PRS/Ozark/GBubbleMap/GBubbleMap.html?SQL=#url.kid#" target="_blank">View Production Bubble Map</a></li>
        </ul>
    </cfoutput>
</cfif>

<cfif url.get eq "wwc5">
    <cfquery name="qWWC5" datasource="plss">
        select
            w.input_seq_number,
            c.name as county,
            initcap(w.owner_name) as owner_name,
            w.depth_of_completed_well,
            w.static_water_level,
            w.estimeted_yield,
            w.township,
            w.township_direction,
            w.range,
            w.range_direction,
            w.section,
            w.quarter_call_1_largest,
            w.quarter_call_2,
            w.quarter_call_3,
            initcap(s.typewell) as status,
            w.elevation_of_well,
            initcap(u.use_description) as use,
            w.completion_date,
            w.contractor_name as w_contractor,
            c.contractor_name as c_contractor,
            w.dwr_appropriation_number,
            w.monitoring_number
        from
            wwc5.wwc5_99_wells w,
            global.counties c,
            wwc5.well_status_type_rf7 s,
            wwc5.welluse_type u,
            wwc5.contractors c
        where
            w.input_seq_number = #url.seq#
            and
            w.county_code = c.code(+)
            and
            w.type_of_action_code = s.wltwel(+)
            and
            w.water_use_code = u.water_use_code(+)
            and
            w.contractors_license_number = c.contractors_license(+)
    </cfquery>

    <!--- Format location and contractor name: --->
    <cfoutput query="qWWC5">
        <cfset Location = "T" & #township# & #township_direction# & " R" & #range# & #range_direction# & " Sec. " & #section#>
        <cfset Quarters = #quarter_call_3# & " " & #quarter_call_2# & " " & #quarter_call_1_largest#>

        <cfset Contractor = "">
        <cfif c_contractor neq "">
        	<cfset Contractor = c_contractor>
        <cfelseif w_contractor neq "">
        	<cfset Contractor = w_contractor>
        </cfif>
    </cfoutput>

    <!--- Format response text: --->
    <cfoutput query="qWWC5">
        <span class='layer_name'>&nbsp;<strong>WATER WELL (WWC5)</strong></span><br />
        <table cellspacing='0' width='100%'>
            <tr style='background-color:##D9E6FB'><td class='info_label'>County:</td><td class='info_text'>#county#</td></tr>
            <tr><td class='info_label'>Section:</td><td class='info_text'>#Location#</td></tr>
            <tr style='background-color:##D9E6FB'><td class='info_label'>Quarter Section:</td><td class='info_text'>#Quarters#</td></tr>
            <tr><td class='info_label'>Owner:</td><td class='info_text'>#owner_name#</td></tr>
            <tr style='background-color:##D9E6FB'><td class='info_label'>Status:</td><td class='info_text'>#status#</td></tr>
            <tr><td class='info_label'>Depth:</td><td class='info_text'>#depth_of_completed_well# <cfif #depth_of_completed_well# neq "">ft</cfif></td></tr>
           	<tr style='background-color:##D9E6FB'><td class='info_label'>Elevation:</td><td class='info_text'>#elevation_of_well# <cfif #elevation_of_well# neq "">ft</cfif></td></tr>
            <tr><td class='info_label'>Static Water Level:</td><td class='info_text'>#static_water_level# <cfif #static_water_level# neq "">ft</cfif></td></tr>
            <tr style='background-color:##D9E6FB'><td class='info_label'>Estimated Yield:</td><td class='info_text'>#estimeted_yield# <cfif #estimeted_yield# neq "">gpm</cfif></td></tr>
            <tr><td class='info_label'>Well Use:</td><td class='info_text'>#use#</td></tr>
            <tr style='background-color:##D9E6FB'><td class='info_label'>Other ID:</td><td class='info_text'>#monitoring_number#</td></tr>
            <tr><td class='info_label'>Completion Date:</td><td class='info_text'>#DateFormat(completion_date,'mmm-dd-yyyy')#</td></tr>
            <tr style='background-color:##D9E6FB'><td class='info_label'>Driller:</td><td class='info_text'>#Contractor#</td></tr>
            <tr><td class='info_label'>DWR Application Number:</td><td class='info_text'>#dwr_appropriation_number#</td></tr>
            <tr style='background-color:##D9E6FB'><td class='info_label'>KGS Record Number:</td><td class='info_text'>#input_seq_number#</td></tr>
        </table>
        <p>
        <b>Links:</b>
        <ul>
            <li><a href="http://chasm.kgs.ku.edu/apex/wwc5.wwc5d2.well_details?well_id=#url.seq#" target="_blank">Full KGS Database Entry</a></li>
        </ul>
    </cfoutput>
</cfif>

<cfif url.get eq "welluse">
	<cfquery name="qWellUse" datasource="plss">
    	select
        	initcap(use_description) as use
        from
        	wwc5.welluse_type
        where
        	water_use_code = #url.usecode#
    </cfquery>

    <cfoutput query="qWellUse">
    	#use#
    </cfoutput>
</cfif>
</cfprocessingdirective>
