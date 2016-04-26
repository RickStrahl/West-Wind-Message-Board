$(document).ready(function () {
    var edResize = debounce(resizeEditor, 100, true);    
    function resizeEditor() {
        $("#Editor").height(window.innerHeight - 425);
    }
    window.textEditor.setvalue($("#Message").val(), -1);    

    // button click handlers
    $("#btnPasteHref").click(function () {
        var text = $("#HrefLinkText").val();
        var link = $("#HrefLink").val();
        //var a = "<a href='" + link + "' target='wwthreadsexternal'>" + text + "</a>";
        var a = "[" + text + "](" + link + ")";

        textEditor.setselection(a);
        textEditor.setfocus();
    });
    $("#HrefDialog").on('shown.bs.modal', function () {        
        $('#HrefLink').focus();
    });

    $("#btnPasteCode").click(function () {
        var code = $("#CodeSnippet").val();
        var lang = $("#CodeLanguage").val();
        var codeblock = "```" + lang + "\r\n" +
            code + "\r\n" +
            "```";

        textEditor.setselection(codeblock);
        textEditor.setfocus();        
    });
    $("#CodeDialog").on('shown.bs.modal', function () {
        $('#CodeLanguage').focus();
    });

    $("#btnImageLink").click(function() {
        var img = $("#ImageLink").val();
        if (!img)
            return;
        var html = "![](" + img + ")";
        textEditor.setselection(html);
        textEditor.setfocus();
    });
    $("#ImageDialog").on('shown.bs.modal', function () {
        $('#ImageLink').focus();
    });

    setupImageUpload();

    // Preview Editor Hookup
    var markdownFunc = debounce(markdown, 800,false);
    $("#Editor").keyup(function() {
        markdownFunc(textEditor.getvalue());
    });
});


$(".edit-toolbar a").click(handleMenuButtons);

function handleMenuButtons(id) {
    var $btn = $(this);
    var id = null, output = "", lines;
    

    if (typeof id !== "string")
        id = $btn.prop("id");

    var selectedText = textEditor.getselection();

    if (id === "btnBold") {
        if (!selectedText)
            return;
        textEditor.setselection("**" + selectedText + "**");
        textEditor.setfocus();
    } else if (id == "btnItalic") {
        if (!selectedText)
            return;
        textEditor.setselection("*" + selectedText + "*");
        textEditor.setfocus();
    } else if (id == "btnQuote") {
        if (!selectedText)
            return;

        lines = selectedText.split('\n');        
        lines.forEach(function (val, i) {            
            output += "> " + val.replace("\r", "") + "\r\n";            
        });
        textEditor.setselection(output);
    } else if (id == "btnList") {
        lines = selectedText.split('\n');
        lines.forEach(function (val, i) {
            output += "* " + val.replace("\r", "") + "\r\n";
        });
        textEditor.setselection(output);
    } else if (id == "btnH2") {
        textEditor.setselection("## " + selectedText);
        textEditor.setfocus();
    } else if (id == "btnH3") {
        textEditor.setselection("### " + selectedText);
        textEditor.setfocus();
    } else if (id == "btnH4") {
        textEditor.setselection("#### " + selectedText);
        textEditor.setfocus();
    } else if (id == "btnH5") {
        textEditor.setselection("##### " + selectedText);
        textEditor.setfocus();
    } else if (id == "btnList") {

    } else if (id == "btnHref") {
        $("#HrefLinkText").val(selectedText);
        if (selectedText.indexOf("http") > -1)
            $("#HrefLink").val(selectedText);
        $("#HrefDialog").modal();

    } else if (id == "btnImage") {
        $("#ImageDialog").modal();        
    } else if (id == "btnCode") {
        $("#CodeSnippet").val(selectedText);
        $("#CodeDialog").modal();
    }

    // force update
    markdown();
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
        var markdownText = te.getvalue();

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