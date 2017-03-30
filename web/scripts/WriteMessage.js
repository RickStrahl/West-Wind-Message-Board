$(document).ready(function () {
    var edResize = debounce(resizeEditor, 100, true);
    var $msg = $("#Message");

    function resizeEditor() {
        $msg.height(window.innerHeight - 425);
    }
    
    // button click handlers
    $("#btnPasteHref").click(function () {        
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
        var html = "```" + lang + "\n" +
            code + "\n" +
            "```\n";

        setTimeout(function () {
            setSelection($msg[0], html);
        }, 80);
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
    var markdownFunc = debounce(markdown, 1000,false);
    $("#Message").keyup(function() {
        markdownFunc();
    });    
});


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
    else if (id === "btnQuote") {
        var lines = sel.split('\n');
        sel = "";
        lines.forEach(function (val, i) {
            sel += "> " + val.replace("\r", "").replace("\n","") + "\n";
        });
    } else if (id == "btnList") {
        var lines = sel.split('\n');
        sel = "";
        lines.forEach(function(val, i) {
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

    console.log(nSelStart, nSelEnd);

    var oldText = el.value;

    if (el.setRangeText) {
        document.execCommand("insertText", false, sel);

        // Works but fucks up Undo buffer
        //if (el.setRangeText)
        //    el.setRangeText(sel);
    } else {
        // Internet Explorer doesn't allow pasting into text box
        // so let's replace the whole shebang
        var newText = oldText.substr(0, nSelStart) +
            sel +
            oldText.substr(nSelEnd);
        el.value = newText;
    }

    setTimeout(function() {
            if (selectionPoint > 0) {
                el.selectionStart = selectionPoint;
                el.selectionEnd = selectionPoint;
            } else
                el.selectionStart = el.selectionEnd;
        },20);
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
                    textEditor.setselection("![](" + imageUrl + ")\r\n");
                    textEditor.setfocus();
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

    console.log(markdownText);
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