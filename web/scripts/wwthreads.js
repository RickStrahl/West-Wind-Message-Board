window.wwthreads = null;

(function (undefined) {
    // exportable interface
    wwthreads = {
        initializeLayout: initializeLayout,
        highlightCode: null // in aceConfig.js

        //initializeTOC: initializeTOC
    }


    function initializeLayout() {
        // for old IE versions work around no FlexBox
        if (navigator.userAgent.indexOf("MSIE 9") > -1 ||
	        navigator.userAgent.indexOf("MSIE 8") > -1 ||
	        navigator.userAgent.indexOf("MSIE 7") > -1)
            $(document.body).addClass("old-ie");


        $.get("ThreadList.wwt", loadMessageList);

            // sidebar or hamburger click handler
        $(document.body).on("click", "#slide-menu-toggle", toggleSidebar);
        $(document.body).on("dblclick touchend", ".splitter", toggleSidebar);

        $(".sidebar-left").resizable({
            handleSelector: ".splitter",
            resizeHeight: false
        });

        // handle back/forward navigation so URL updates
        window.onpopstate = function (event) {
            if (history.state.URL)
                loadTopicAjax(history.state.URL);
        }

        $(document.body).on("click","#Search-Button,#Search-Button-Close",function() {
            $(".message-search-box").toggle();
        });
        $(document.body).on("click", "#Refresh-Button", function() {
            $.get("ThreadList.wwt", loadMessageList);
        });

        $(".sidebar-left").on("click", "#Search-Button-Submit", messageSearchQuery);
        $(".sidebar-left").on("click", "#Search-Button-Clear", clearSearchQuery);

    }

    var sidebarTappedTwice = false;
    function toggleSidebar(e) {
        
        // handle double tap
        if (e.type === "touchend" && !sidebarTappedTwice) {
            sidebarTappedTwice = true;
            setTimeout(function () { sidebarTappedTwice = false; }, 300);
            return false;
        }
        var $sidebar = $(".sidebar-left");
        var oldTrans = $sidebar.css("transition");
        $sidebar.css("transition", "width 0.5s ease-in-out");
        if ($sidebar.width() < 20) {
            $sidebar.show();
            $sidebar.width(400);
        } else {
            $sidebar.width(0);
        }

        setTimeout(function () { $sidebar.css("transition", oldTrans) }, 700);
        return true;
    }

    function loadMessageList(html) {        
        var $tocContent = $("<div>" + getBodyFromHtmlDocument(html) + "</div>").find(".message-list-container");
        
        $("#MessageList").html($tocContent.html());

        //showSidebar();

        // handle AJAX loading of topics        
        $("#MessageList").on("click", ".message-item,.message-item >a", loadTopicAjax);

        // Collapsible Forum Headers
        $(".forum-list-header").click(function () {            
            var $el = $(this).next();            
            $el.toggle();
            var $span = $(this).find("span");
            if ($span.text() == "+")
                $span.text("-");
            else
                $span.text("+");

        });
        $(".expand-forum").click(function() {
            
            $(this).find("span").text("-");
            $(".forum-list-container").hide();
            $(".forum-list-header").find("span").text("+");
            var $el = $(this).next();
            $el.show(600);
        });

        return false;
    }

    function loadTopicAjax(href) {        

        var hrefPassed = true;
        if (typeof href != "string") {
            hrefPassed = false;
            var $el = $(this);
            var threadId = $el.data("id");
            href = "Thread" + threadId + ".wwt";

            $(".message-item").removeClass("selected");
            $el.addClass("selected");            
        }

        $.get(href, function(html) {
            var $html = $(html);

            var title = html.extract("<title>", "</title>");
            window.document.title = title;


            var $content = $html.find(".main-content");
            if ($content.length > 0) {
                html = $content.html();
                $(".main-content").html(html);

                // update the navigation history/url in addressbar
                if (window.history.pushState && !hrefPassed)
                    window.history.pushState({ title: '', URL: href }, "", href);

                $(".main-content").scrollTop(0);

                if (window.outerWidth < 769)
                    $(".sidebar-left").width(0);                
            } else
                return;

            wwthreads.highlightCode();
            //CreateHeaderLinks();
        });
        return false;  // don't allow click              
    };

    function messageSearchQuery() {
        $.post("ThreadList.wwt", {
            StartDate: $("#StartDate_field").val(),
            EndDate: $("#EndDate_field").val(),
            Forum: $("#Forum").val(),
            Search: $("#Search").val(),
            MsgId: $("MsgId").val()
        }, loadMessageList);
    }

    function clearSearchQuery() {        
        $("#StartDate_field").val(""),
            $("#EndDate_field").val(""),
            $("#Forum").val(""),
            $("#Search").val(""),
            $("MsgId").val("");
        $.post("ThreadList.wwt", loadMessageList);
    }

    function hideSidebar() {
        var $sidebar = $(".sidebar-left");
        var $toggle = $(".sidebar-toggle");
        var $splitter = $(".splitter");
        $sidebar.hide();
        $toggle.hide();
        $splitter.hide();
    }
    function showSidebar() {
        var $sidebar = $(".sidebar-left");
        var $toggle = $(".sidebar-toggle");
        var $splitter = $(".splitter");
        $sidebar.show();
        $toggle.show();
        $splitter.show();
    }
})();
