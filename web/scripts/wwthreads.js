window.wwthreads = null;

(function (undefined) {
    // exportable interface
    wwthreads = {
        initializeLayout: initializeLayout,
        highlightCode: null, // in aceConfig.js
        sortAscending: true,   // for reverseMessageOrder
        loadMessages: loadMessageListAjax,

        // this object is saved in localstorage
        userData: {
            lastAccess: new Date(),
            lastMessageText: null,
            threadMessages: null,
            savedTime: new Date().getTime() - 310000,
            sortAscending: true,
            save: function userData_save() {                
                wwthreads.userData.savedTime = new Date().getTime();
                if (localStorage)
                    localStorage.setItem("wwt_userdata", JSON.stringify(wwthreads.userData));
            },
            load: function userData_load() {
                if (!localStorage)
                    return;                
                var data = localStorage.getItem("wwt_userdata");
                if (data) {
                    try {
                        data = JSON.parseWithDate(data);
                        $.extend(wwthreads.userData, data);
                    }
                    catch (ex) { localStorage.removeItem("wwt_userdata") };
                }
            },
            getThreadMessages: function userData_getMessages() {
                // stale after 5 minutes
                if (wwthreads.userData.savedTime < new Date().getTime() - 300000)
                    return null;
                return wwthreads.userData.threadMessages;
            }
        }        
    }

    function initializeLayout() {
        wwthreads.userData.load();

        // for old IE versions work around no FlexBox
        if (navigator.userAgent.indexOf("MSIE 9") > -1 ||
	        navigator.userAgent.indexOf("MSIE 8") > -1 ||
	        navigator.userAgent.indexOf("MSIE 7") > -1)
            $(document.body).addClass("old-ie");


        loadMessageListAjax();

        /* Event Handler hookups */
        
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

        // handle AJAX loading of topics when clicking on topic in list       
        $("#MessageList").on("click", ".message-item,.message-item >a", loadTopicAjax);

        // handle Message List refresh
        $(document.body).on("click", "#Refresh-Button", function() {
            loadMessageListAjax(true)
                .then(function() {
                        toastr.success("Thread listing updated.");
                    },
                    function() {
                        toastr.error("Updating of the thread listing failed.");
                    });
        });

        // Search button clicks
        $(document.body).on("click","#Search-Button,#Search-Button-Close",function() {
            $(".message-search-box").toggle();
        });                
        $(".sidebar-left").on("click", "#Search-Button-Submit", messageSearchQuery);
        $(".sidebar-left").on("click", "#Search-Button-Clear", clearSearchQuery);

        // handle sorting of thread messages in a thread
        $(".main-content").on("click", "#ReverseMessageOrder", reverseMessageOrder);

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

    function loadMessageListAjax(forceReload) {        
        // check for rl=1 query string which forces reload of thread list        
        if (getUrlEncodedKey("rl", location.search))
            forceReload = true;            

        var html = null;
        if (!forceReload)
            html = wwthreads.userData.getThreadMessages();

        if (!html) {            
            var forum = getUrlEncodedKey("forum", location.search);
            var url = "ThreadList.wwt" +
                      (forum ? "?forum=" + forum : "");

            // load with AJAX
            return $.get(url, function(html) {
                wwthreads.userData.lastAccess = new Date();
                wwthreads.userData.threadMessages = html;
                wwthreads.userData.save();

                loadMessageList(html);
            });
        } else
            loadMessageList(html); // load from cached list
    }
    function loadMessageList(html) {        
        var $tocContent = $("<div>" + getBodyFromHtmlDocument(html) + "</div>").find(".message-list-container");
        var htmlToWrite = $tocContent.html();

        $("#MessageList").html($tocContent.html(htmlToWrite));

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

                wwthreads.sortAscending = true;

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

    function reverseMessageOrder() {
        wwthreads.sortAscending = !wwthreads.sortAscending;

        var $msgList = $(".message-list-item");

        $msgList.sort(function (a, b) {
            var sort = a.getAttribute('data-sort') * 1;
            var sort2 = b.getAttribute('data-sort') * 1;

            console.log(sort, sort2);

            var mult = 1;
            if (!wwthreads.sortAscending)
                mult = -1

            if (sort > sort2)
                return 1 * mult;
            if (sort < sort2)
                return -1 * mult;

            return 0;
        });

        $msgList.detach().appendTo("#ThreadMessageList");

        toastr.clear();
        toastr.success("Message order has been reversed to " +
                        (wwthreads.sortAscending ? "ascending" : "descending"),
                        "Thread Message Order");
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