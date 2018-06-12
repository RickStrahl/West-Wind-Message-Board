$(document).ready(function () {
    var edResize = debounce(resizeEditor, 100, true);
    var $msg = $("#Message");

    function resizeEditor() {
        $msg.height(window.innerHeight - 425);
    }

    // button click handlers
    $("#btnPasteHref").click(function () {
        ;
        var text = $("#HrefLinkText").val();
        var link = $("#HrefLink").val();
        //var a = "<a href='" + link + "' target='wwthreadsexternal'>" + text + "</a>";
        var html = "[" + text + "](" + link + ")";

        setTimeout(function() { 
            setSelection($msg[0], html);
        },80);       
    });

    $("#HrefDialog").on('shown.bs.modal', function () {        
        $('#HrefLink').focus();
    });

    $("#btnPasteCode").click(function () {
        var code = $("#CodeSnippet").val();
        var lang = $("#CodeLanguage").val();

        if (lang === "txt" &&
            confirm("No code syntax selected. Do you want to format your code with a specific syntax?")) {
            $("#CodeLanguage").focus();
            return;
        }
            
        var html = "```" + lang + "\n" +
            code + "\n" +
            "```\n";

        setTimeout(function () {
            setSelection($msg[0], html);
        }, 80);

        $("#CodeDialog").modal('hide');
    });
    $("#CodeDialog").on('shown.bs.modal', function () {
        $('#CodeLanguage').focus();
    });

    $("#btnImageLink").click(function() {
        var img = $("#ImageLink").val();
        if (!img)
            return;
        var html = "![](" + img + ")";

        setTimeout(function () {
            setSelection($msg[0], html);
        }, 80);
        
    });
    $("#ImageDialog").on('shown.bs.modal', function () {
        $('#ImageLink').focus();
    });

    setupImageUpload();

    // Preview Editor Hookup
    var markdownFunc = debounce(markdown, 500,false);
    $msg.keyup(function() {
        markdownFunc();
    });    
});



var mousePos = { x: 0, y: 0 };
window.onmousemove = function (e) {
    mousePos.x = e.clientX;
    mousePos.y = e.clientY;
}

document.onpaste = function (event) {
    var items = (event.clipboardData || event.originalEvent.clipboardData).items;
    //console.log(JSON.stringify(items)); // will give you the mime types
    for (var i in items) {
        var item = items[i];
        if (item.kind === 'file') {
            var blob = item.getAsFile();
            var reader = new FileReader();
            reader.onload = function (event) {
                var opt = {
                    method: "POST",
                    contentType: "raw/data",
                    accepts: "application/json",
                    noPostEncoding: true
                };                
                var http = new HttpClient(opt);
                http.evalResult = true;
                http.send("ImagePasteUpload.wwt",
                    event.target.result,
                    function (url) {
                        console.log("url: " + url);
                        if (!url)
                            toastr.error("Image upload failed.");
                        else {
                            setSelection($("#Message")[0], "![](" + url + ")");
                            toastr.success("Image uploaded...");
                        }
                    },
                    function (error) {
                        toastr.error("Image upload failed.");
                    });
            
                //console.log(event.target.result);
            }; // data url!
            reader.readAsDataURL(blob);
        }
    }
}




function setupImageUpload() {
    // *** Ajax upload
    // Catch the file selection
    var files = null;
    showStatus({ autoClose: false });
    
    $("#ajaxUpload").change(function (event) {        
        files = event.target.files;
        $("#UploadProgress").show();

        // no further DOM processing
        event.stopPropagation();
        event.preventDefault();

        uploadFiles({
            id: "ImageUpload",
            uploadUrl: "ImageUpload.wwt",
            success: function uploadSuccess(imageUrl, textStatus, jqXHR) {                    
                toastr.success("The image has been uploaded and embedded into your message.", "Image Upload completed", 3000);

                $("#UploadProgress").hide();
                $("#ImageDialog").modal("hide");


                if (imageUrl) {
                    setSelection($("#Message")[0], "![](" + imageUrl + ")\r\n");
                    markdown();
                }
            },
            error: function uploadError(jqXHR, textStatus, errorThrown) {                
                $("#UploadProgress").hide();

                var msg = "Unknown error.";
                if (jqXHR.responseText) {
                    try {
                        var err = JSON.parse(jqXHR.responseText);
                        msg = err.message;
                    } catch (ex) {
                    };
                } 

                toastr.error(msg, "Upload failed");

                if (msg == "Unauthorized access") {
                    app.configuration.user.isAuthenticated = false;
                    app.configuration.redirectUrl = $location.url();
                    window.location.href = ("#/login");
                }
            },
            progress: function (e) {                
                showStatus(Math.floor(e.loaded / e.total * 100) + "% uploaded");
            }
        });

    });

    /*
        Generic re-usable Ajax Upload function
    
        Pass in from Change event of file upload control
    
        fileId  -  Id of the file Form vars
                    file results in (file0, file1, file2 etc)
        url     -  Url to upload to
        success -  success handler
                    data object of JSON result data from server
        error   -  error handler
        progress -  progress event (e.total, e.loaded) 
        formVars - [{key: "name", value: "value"}]
    
        { fileId, uploadUrl, success, error, timeout }
    
    */
    function uploadFiles(opt) {
        // Create a formdata object and add the files
        var data = new FormData();
        $.each(files, function (key, value) {
            data.append(opt.id, value);
        });

        if (opt.formVars) {
            opt.formVars.forEach(function (nv) {
                data.append(nv.key, nv.value);
            });
        }


        // return promise
        return $.ajax({
            url: opt.uploadUrl,
            timeout: opt.timeout,
            type: 'POST',
            data: data,
            cache: false,
            dataType: 'json',
            processData: false, // Don't process the files
            contentType: false, // Set content type to false!
            success: opt.success,
            error: opt.error,
            xhr: function () {
                // get the native XmlHttpRequest object
                var xhr = $.ajaxSettings.xhr();
                if (opt.progress) {
                    // set the onprogress event handler
                    xhr.upload.onprogress = opt.progress;
                }
                return xhr;
            }
        });
    }
}

function markdown(markdownText) {
    if (!markdownText)
        markdownText = $("#Message").val();
    
    marked.setOptions({
        renderer: new marked.Renderer(),
        gfm: true,
        tables: false,
        breaks: false,
        pedantic: false,
        sanitize: false,
        smartLists: true,
        smartypants: false
    });
    var md = marked(markdownText);
    md = md.replace(/><code class="lang-/g, ' class="no-container"><code class="lang-"');

    $("#Preview").html("<hr/>" + md + "<hr/>");
    wwthreads.highlightCode("#Preview pre[lang]");

    //<pre><code class="lang-javascript">x++;
    //var next = x + 10;
    //</code></pre>

    // <pre lang="javascript">
}


// handle editor buttons
$(document)
    .on("click",
        ".edit-toolbar>a", toolbarHandler);

function toolbarHandler(id) {

    var msg = document.getElementById("Message");
    msg.focus();
    var text = msg.value;

    var nSelStart = msg.selectionStart;
    var nSelEnd = msg.selectionEnd;

    var sel = text.substring(nSelStart, nSelEnd);

    if (typeof id !== "string")
        id = this.id;

    if (id === "btnBold")
        sel = "**" + sel + "**";
    else if (id === "btnItalic")
        sel = "*" + sel + "*";
    else if (id === "btnInlineCode")
        sel = "`" + sel + "`";
    else if (id === "btnQuote") {
        var lines = sel.split('\n');
        sel = "";
        lines.forEach(function (val, i) {
            sel += "> " + val.replace("\r", "").replace("\n", "") + "\n";
        });
    } else if (id == "btnList") {
        var lines = sel.split('\n');
        sel = "";
        lines.forEach(function (val, i) {
            sel += "* " + val.replace("\r", "") + "\n";
        });
    }
    else if (id === "btnH2") {
        sel = "## " + sel;
    } else if (id === "btnH3") {
        sel = "### " + sel;
    } else if (id === "btnH4") {
        sel = "#### " + sel;
    } else if (id === "btnH5") {
        sel = "###### " + sel;
    }
    else if (id === "btnHref") {
        $("#HrefLinkText").val(sel);
        if (sel.indexOf("http") > -1)
            $("#HrefLink").val(sel);
        $("#HrefDialog").modal();
        return;

    } else if (id === "btnImage") {
        $("#ImageDialog").modal();
        return;
    } else if (id === "btnCode") {
        $("#CodeSnippet").val(sel);
        $("#CodeDialog").modal();
        return;
    }

    setSelection(msg, sel);

    // force update
    markdown();
}

function setSelection(el, sel) {
    el.focus();

    var nSelStart = el.selectionStart;
    var nSelEnd = el.selectionEnd;

    var selectionPoint = nSelStart + sel.length;

    var oldText = el.value;

    // if(document.queryCommandSupported("insertText"))  // doesn't work reliably
    if (navigator.userAgent.indexOf("Safari") > 0)
    // chrome and safari - this works best
        document.execCommand("insertText", false, sel);
    //// Works but fucks up Undo buffer    
    //else if (el.setRangeText)
    //    el.setRangeText(sel);
    else {
        // Internet Explorer doesn't allow pasting into text box
        // so let's replace the whole shebang
        var newText = oldText.substr(0, nSelStart) +
            sel +
            oldText.substr(nSelEnd);
        el.value = newText;
    }

    setTimeout(function () {
        if (selectionPoint > 0) {
            el.selectionStart = selectionPoint;
            el.selectionEnd = selectionPoint;
        } else
            el.selectionStart = el.selectionEnd;
    }, 20);
}


var shortcut = {
    'all_shortcuts': {},//All the shortcuts are stored in this array
    'add': function (shortcut_combination, callback, opt) {
        //Provide a set of default options
        var default_options = {
            'type': 'keydown',
            'propagate': false,
            'disable_in_input': false,
            'target': document,
            'keycode': false
        }
        if (!opt) opt = default_options;
        else {
            for (var dfo in default_options) {
                if (typeof opt[dfo] == 'undefined') opt[dfo] = default_options[dfo];
            }
        }

        var ele = opt.target;
        if (typeof opt.target == 'string') ele = document.getElementById(opt.target);
        var ths = this;
        shortcut_combination = shortcut_combination.toLowerCase();

        //The function to be called at keypress
        var func = function (e) {
            e = e || window.event;

            if (opt['disable_in_input']) { //Don't enable shortcut keys in Input, Textarea fields
                var element;
                if (e.target) element = e.target;
                else if (e.srcElement) element = e.srcElement;
                if (element.nodeType == 3) element = element.parentNode;

                if (element.tagName == 'INPUT' || element.tagName == 'TEXTAREA') return;
            }

            //Find Which key is pressed
            if (e.keyCode) code = e.keyCode;
            else if (e.which) code = e.which;
            var character = String.fromCharCode(code).toLowerCase();

            if (code == 188) character = ","; //If the user presses , when the type is onkeydown
            if (code == 190) character = "."; //If the user presses , when the type is onkeydown

            var keys = shortcut_combination.split("+");
            //Key Pressed - counts the number of valid keypresses - if it is same as the number of keys, the shortcut function is invoked
            var kp = 0;

            //Work around for stupid Shift key bug created by using lowercase - as a result the shift+num combination was broken
            var shift_nums = {
                "`": "~",
                "1": "!",
                "2": "@",
                "3": "#",
                "4": "$",
                "5": "%",
                "6": "^",
                "7": "&",
                "8": "*",
                "9": "(",
                "0": ")",
                "-": "_",
                "=": "+",
                ";": ":",
                "'": "\"",
                ",": "<",
                ".": ">",
                "/": "?",
                "\\": "|"
            }
            //Special Keys - and their codes
            var special_keys = {
                'esc': 27,
                'escape': 27,
                'tab': 9,
                'space': 32,
                'return': 13,
                'enter': 13,
                'backspace': 8,

                'scrolllock': 145,
                'scroll_lock': 145,
                'scroll': 145,
                'capslock': 20,
                'caps_lock': 20,
                'caps': 20,
                'numlock': 144,
                'num_lock': 144,
                'num': 144,

                'pause': 19,
                'break': 19,

                'insert': 45,
                'home': 36,
                'delete': 46,
                'end': 35,

                'pageup': 33,
                'page_up': 33,
                'pu': 33,

                'pagedown': 34,
                'page_down': 34,
                'pd': 34,

                'left': 37,
                'up': 38,
                'right': 39,
                'down': 40,

                'f1': 112,
                'f2': 113,
                'f3': 114,
                'f4': 115,
                'f5': 116,
                'f6': 117,
                'f7': 118,
                'f8': 119,
                'f9': 120,
                'f10': 121,
                'f11': 122,
                'f12': 123
            }

            var modifiers = {
                shift: { wanted: false, pressed: false },
                ctrl: { wanted: false, pressed: false },
                alt: { wanted: false, pressed: false },
                meta: { wanted: false, pressed: false }	//Meta is Mac specific
            };

            if (e.ctrlKey) modifiers.ctrl.pressed = true;
            if (e.shiftKey) modifiers.shift.pressed = true;
            if (e.altKey) modifiers.alt.pressed = true;
            if (e.metaKey) modifiers.meta.pressed = true;

            for (var i = 0; k = keys[i], i < keys.length; i++) {
                //Modifiers
                if (k == 'ctrl' || k == 'control') {
                    kp++;
                    modifiers.ctrl.wanted = true;

                } else if (k == 'shift') {
                    kp++;
                    modifiers.shift.wanted = true;

                } else if (k == 'alt') {
                    kp++;
                    modifiers.alt.wanted = true;
                } else if (k == 'meta') {
                    kp++;
                    modifiers.meta.wanted = true;
                } else if (k.length > 1) { //If it is a special key
                    if (special_keys[k] == code) kp++;

                } else if (opt['keycode']) {
                    if (opt['keycode'] == code) kp++;

                } else { //The special keys did not match
                    if (character == k) kp++;
                    else {
                        if (shift_nums[character] && e.shiftKey) { //Stupid Shift key bug created by using lowercase
                            character = shift_nums[character];
                            if (character == k) kp++;
                        }
                    }
                }
            }

            if (kp == keys.length &&
                modifiers.ctrl.pressed == modifiers.ctrl.wanted &&
                modifiers.shift.pressed == modifiers.shift.wanted &&
                modifiers.alt.pressed == modifiers.alt.wanted &&
                modifiers.meta.pressed == modifiers.meta.wanted) {
                callback(e);

                if (!opt['propagate']) { //Stop the event
                    //e.cancelBubble is supported by IE - this will kill the bubbling process.
                    e.cancelBubble = true;
                    e.returnValue = false;

                    //e.stopPropagation works in Firefox.
                    if (e.stopPropagation) {
                        e.stopPropagation();
                        e.preventDefault();
                    }
                    return false;
                }
            }
        }
        this.all_shortcuts[shortcut_combination] = {
            'callback': func,
            'target': ele,
            'event': opt['type']
        };
        //Attach the function with the event
        if (ele.addEventListener) ele.addEventListener(opt['type'], func, false);
        else if (ele.attachEvent) ele.attachEvent('on' + opt['type'], func);
        else ele['on' + opt['type']] = func;
    },

    //Remove the shortcut - just specify the shortcut and I will remove the binding
    'remove': function (shortcut_combination) {
        shortcut_combination = shortcut_combination.toLowerCase();
        var binding = this.all_shortcuts[shortcut_combination];
        delete (this.all_shortcuts[shortcut_combination])
        if (!binding) return;
        var type = binding['event'];
        var ele = binding['target'];
        var callback = binding['callback'];

        if (ele.detachEvent) ele.detachEvent('on' + type, callback);
        else if (ele.removeEventListener) ele.removeEventListener(type, callback, false);
        else ele['on' + type] = false;
    }
}
shortcut.add("ctrl+b",
    function () {
        toolbarHandler("btnBold");
    });
shortcut.add("ctrl+i",
    function () {
        toolbarHandler("btnItalic");
    });
shortcut.add("alt+c",
    function () {
        toolbarHandler("btnCode");
    });
shortcut.add("ctrl+k",
    function () {
        toolbarHandler("btnHref");
    });
shortcut.add("ctrl+q",
    function () {
        toolbarHandler("btnQuote");
    });
shortcut.add("alt+i",
    function () {        
        toolbarHandler("btnImage");
    });
