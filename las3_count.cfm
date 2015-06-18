
<cfset theWhere = Urldecode(url.where)>

<cfif theWhere neq "">
	<cfset theWhere = Left(theWhere, Len(theWhere) - 4)>
</cfif>

<cfif theWhere neq "">
    <cfquery name="qLAS3Count" datasource="plss">
        select
        	kid
        from
            las3.well_headers
        <cfif theWhere neq "">
       		where
            	#PreserveSingleQuotes(theWhere)#
        </cfif>
    </cfquery>
    
    <cfoutput>
    #qLAS3Count.recordcount#
    </cfoutput>
<cfelse>
	0
</cfif>
