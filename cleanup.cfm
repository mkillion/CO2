<!--- Delete files in the pdfoutput directory that are more than 1 day old: --->


<cfdirectory action="list" directory="d:/webware/Apache2/htdocs/mk/ags/fields/output" name="qFiles">

<cfif qFiles.recordcount gt 0>
	<cfloop query="qFiles">
		<cfif DateDiff("n",qFiles.DateLastModified,Now()) gt 10>
			<cffile action="delete" file="d:/webware/Apache2/htdocs/mk/ags/fields/output/#qFiles.Name#">
		</cfif>
	</cfloop>
</cfif>
