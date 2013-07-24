$.fn.show_info = function(block){
    this.hover(
	function(){ block.show(); },
        function(){ block.hide(); }
    );        
};
