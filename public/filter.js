// This code provides the filtering for the package selector
//
// There are a lot of packages and a simple search can take a while to
// complete which causes issues with incremental searching. This
// approach is re-entrant when a new keystroke is made. It makes use
// of setTimeout() to schedule A number of packages are processed in a
// chunk

// Usage: var pkgFilter = new Filter($("#packagelist > tr"));
//    pkgFilter.gettext = function(el) {return $(el).find("td:first").text(); }
//    pkgFilter.on_active = function() {$("#search_active").show(); }
//    pkgFilter.on_inactive = function() {$("#search_active").hide(); }
//    pkgFilter.on_empty = function() {$("#no_results").show(); }
//    pkgFilter.hide_action = false; // show list as elements are hidden

function Filter(list){
    this.list = list;
    this.len = list.length;
    this.stopped = true;
    this.N = 200; // how many to hide/show at a time
    this.hide_action = true; // hide() all list before show()ing matches
}

Filter.prototype.run = function(element) {
    // stop any timeout based iterator
    this.stop = true;
    var el=element;
    // come back later if not stopped
    while (this.stopped == false) {
	var thiz=this;
	setTimeout(function(){thiz.run(el);}, 0.01);
	return;
    }
    this.value = $(element).val();
    if (this.value == "") {
	if (this.on_empty) { this.on_empty(); } // callback for idle display
    } else {
	var thiz=this;
	setTimeout(function(){thiz.start();},0);
    }
}

Filter.prototype.start = function() {
    console.log("start");
    this.stop = false;
    this.count = 0;
    this.nextn = this.N;
    if (this.on_active) { this.on_active(); } // callback for display
    var thiz=this;
    if (this.hide_action) { this.hide_all(); } // hide all before showing matches
    setTimeout(function(){thiz.do_next_chunk();},0);
    this.stopped = false;
}

// Processes the next N items
Filter.prototype.do_next_chunk = function() {
    for (; (this.count<this.len) && (this.count < this.nextn); this.count++) {
        var item=this.list[this.count];
        var show=true;
        var text=this.gettext(item);
	var thiz=this;
        $.each(this.value.split(" "),
	       function() {
		   if (text.search(this) < 0) {
		       show=false;
		   }
               });
        if (show) {
	    $(item).show();
	} else {
	    $(item).hide();
	}
    }
    if (this.count >= this.len || this.stop) {
	// done
	this.stopped = true;
	if (this.stop == false) {
	    if (this.on_inactive) { this.on_inactive(); } // callback for display
	}
    } else {
	this.nextn += this.N
	var thiz=this;
	setTimeout(function(){thiz.do_next_chunk();}, 0);
    }
}

// This is used to hide all list items before beginning a search
// It is very fast even with >4000 items so doesn't need tricks
Filter.prototype.hide_all = function() {
    for (var i=0; i<this.len; i++) {
	$(this.list[i]).hide();
    }
}
