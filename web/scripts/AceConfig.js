(function () {
    // These settings control how code is rendered in help files
    var editorSettings = {
        // visualstudio, twilight,mono_industrial,xcode,textmate
        // full list: https://docs.c9.io/v1.0/docs/syntax-highlighting-themes
        //theme: "visualstudio,twilight,monokai_industrial,github,textmate,xcode",
        theme: "twilight",
        showLineNumbers: false,
        fontSize: 14,
        tabSpaces: 4,
        wrapText: false
    };


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

    function highlightCode() {        
        // attach ace to formatted code controls if they are loaded and visible
        $("pre[lang]").each(function () {
            var $el = $(this);
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

    $(document).ready(highlightCode);
})();