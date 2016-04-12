(function () {
    // These settings control how code is rendered in help files (wwhelp_editorsettings.js)
    var editorSettings = window.editorSettings;
    wwthreads.highlightCode = highlightCode;

    function configureAceEditor(editor, editorSettings) {
        var session = editor.getSession();

        editor.setReadOnly(true);
        editor.setHighlightActiveLine(false);
        editor.setShowPrintMargin(false);        

        editor.setTheme("ace/theme/" + editorSettings.theme);
        editor.setFontSize(editorSettings.fontSize);
        editor.renderer.setShowGutter(editorSettings.showLineNumbers);
        session.setTabSize(editorSettings.tabSpaces);
        editor.renderer.setPadding(10);
    
        session.setNewLineMode("windows");
    
        // fill entire view
        editor.setOptions({
            maxLines: Infinity,
            minLines: 1
        });

        session.setUseWrapMode(editorSettings.wrapText);
        session.setOption("indentedSoftWrap", false);
	
        editor.renderer.setScrollMargin(5, 20, 10, 10);
        return editor;
    }

    function highlightCode(sel) {
        if (!sel)
            sel = "pre[lang]";

        // attach ace to formatted code controls if they are loaded and visible
        $("pre[lang]").each(function () {            
            var $el = $(this);
            
            // don't set up the WriteMessage Editor
            if ($el[0].id == "Editor")
                return;

            try {
                var lang = $el.attr('lang');
                var aceEditorRequest = ace.edit($el[0]);
                configureAceEditor(aceEditorRequest, editorSettings);
                aceEditorRequest.getSession().setMode("ace/mode/" + lang);
            } catch (ex) {
                if (typeof console !== "undefined")
                    console.log("Failed to bind syntax: " + lang + " - " + ex.message);
            }
        });
    }

    setTimeout(highlightCode,100);
})();