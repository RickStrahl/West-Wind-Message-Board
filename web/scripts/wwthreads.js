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

        $("#Search-Button").click(function() {
            $(".message-search-box").toggle();
        });

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

        initializeTOC();
        return false;
    }

    function loadTopicAjax(href) {
        var hrefPassed = true;
        if (typeof href != "string") {
            hrefPassed = false;
            var $el = $(this);
            var threadId = $el.data("id");
            href = "Thread" + threadId + ".wwt";
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
            } else
                return;

            wwthreads.highlightCode();
            CreateHeaderLinks();
        });
        return false;  // don't allow click              
    };
    function initializeTOC() {
        return;

        // if running in frames mode link to target frame and change mode
        if (window.parent.frames["wwhelp_right"]) {
            $(".toc li a").each(function () {
                var $a = $(this);
                $a.attr("target", "wwhelp_right");
                var a = $a[0];
                a.href = a.href + "?mode=1";
            });
            $("ul.toc").css("font-size", "1em");
        }

        // Handle clicks on + and -
        $("#toc").on("click", "li>i.fa", function () {
            expandTopic($(this).find("~a").prop("id"));
        });

        expandTopic('index');

        var page = getUrlEncodedKey("page");
        if (page) {
            page = page.replace(/.htm/i, "");
            expandParents(page);
        }
        if (!page) {
            page = window.location.href.extract("/_", ".htm");
            if (page)
                expandParents("_" + page);
        }

        var topic = getUrlEncodedKey("topic");
        if (topic) {
            var id = findIdByTopic();
            if (id) {
                var link = document.getElementById(id);
                var id = link.id;
                expandTopic(id);
                expandParents(id);
            }
        }

        function searchFilterFunc(target) {
            target.each(function () {
                var $a = $(this).find(">a");
                if ($a.length > 0) {
                    var url = $a.attr('href');
                    if (!url.startsWith("file:") && !url.startsWith("http")) {
                        expandParents(url.replace(/.htm/i, ""), true);
                    }
                }
            });
        }

        $("#SearchBox").searchFilter({
            targetSelector: ".toc li",
            charCount: 3,
            onSelected: debounce(searchFilterFunc, 200)
        });
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
