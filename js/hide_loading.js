
var hideLoading = function() {
	var hide = function() {
        dojo.fadeOut({
            node: "loading",
            duration: 700,
            onEnd: function () {
                dojo.style("loading", "display", "none");
            }
        }).play();
		
		// Resize/reposition the map after the loading div is removed:
		setTimeout(resizeMap, 2000);
		
		// Display cross-section tools:
		setTimeout(function () {
            dojo.style("xsectiontools", "visibility", "visible");
        }, 1000);
    };
    setTimeout(hide, 400);
}