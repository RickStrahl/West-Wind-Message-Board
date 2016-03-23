$(document).ready(function () {
    var edResize = debounce(resizeEditor, 100);
    //resizeEditor();
    //$(window).resize(edResize);
    function resizeEditor() {
        $("#Editor").height(window.innerHeight - 500);
    }
    window.textEditor.setvalue($("#Message").val(), -1);
    setupUpload();
});


$(".edit-toolbar a").click(handleMenuButtons);

function handleMenuButtons(id) {
    var $btn = $(this);
    var id = null;
    if (typeof id !== "string")
        id = $btn.prop("id");

    var selectedText = textEditor.getselection();

    if (id === "btnBold")
        textEditor.setselection("**" + selectedText + "**");
    else if (id == "btnItalic")
        textEditor.setselection("*" + selectedText + "*");
    else if (id == "btnH2")
        textEditor.setselection("## " + selectedText);
    else if (id == "btnH3")
        textEditor.setselection("### " + selectedText);
    else if (id == "btnH4")
        textEditor.setselection("#### " + selectedText);
    else if (id == "btnH5")
        textEditor.setselection("##### " + selectedText);
    else if (id == "btnList") {

    }
    else if (id == "btnHref") {

        $("#HrefLinkText").val(selectedText);
        if (selectedText.indexOf("http") > -1)
            $("#HrefLink").val(selectedText);
        $("#HrefDialog").modal();
        $("#btnPasteHref").click(function () {
            var text = $("#HrefLinkText").val();
            var link = $("#HrefLink").val();
            var a = "<a href='" + link + "' target='wwthreadsexternal'>" + text + "</a>";
            textEditor.setselection(a);
        });
    }
    else if (id == "btnImage") {
        $("#ImageDialog").modal();
    }
    else if (id == "btnCode") {
        $("#CodeSnippet").val(selectedText);
        $("#CodeDialog").modal();
        $("#btnPasteCode").click(function () {
            var code = $("#CodeSnippet").val();
            var lang = $("#CodeLanguage").val();
            var codeblock = "```" + lang + "\r\n" +
                code + "\r\n" +
                "```";

            textEditor.setselection(codeblock);
        });
    }

}

function setupUpload() {
    // *** Ajax upload
    // Catch the file selection
    var files = null;
    showStatus({ autoClose: false });
    
    $("#ajaxUpload").change(function (event) {        
        files = event.target.files;

        // no further DOM processing
        event.stopPropagation();
        event.preventDefault();

        uploadFiles({
            id: "ImageUpload",
            uploadUrl: "ImageUpload.wwt",
            success: function uploadSuccess(imageUrl, textStatus, jqXHR) {                
                toastr.success("Upload completed...", 3000);
                
                if (imageUrl) 
                    textEditor.setselection("![](" + imageUrl + ")");

                $("#ImageModel").modal("hide");
            },
            error: function uploadError(jqXHR, textStatus, errorThrown) {                
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