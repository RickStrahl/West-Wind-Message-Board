/// <reference path="wwhelp_editorsettings.js"/>

// NOTE: All method and property names have to be LOWER CASE!
//       in order for FoxPro to be able to access them here.
var te = window.textEditor = {
    fox: null, // FoxPro COM object
    editor: null, // Ace Editor instance
    settings: editorSettings,
    lastError: null,
    dic: null,
    aff: null,
    initialize: function() {
        // attach ace to formatted code controls if they are loaded and visible
        var $el = $("#Editor");  // pre[lang]
        try {
            var codeLang = $el.attr('lang');
            var aceEditorRequest = ace.edit($el[0]);
            te.editor = aceEditorRequest;
            te.configureAceEditor(aceEditorRequest, editorSettings);
            aceEditorRequest.getSession().setMode("ace/mode/" + codeLang);
        } catch (ex) {
            if (typeof console !== "undefined")
                console.log("Failed to bind syntax: " + codeLang + " - " + ex.message);
        }

        te.editor.focus();


        if (editorSettings.enableSpellChecking)
            setTimeout(spellcheck.enable, 1000);

    },
    configureAceEditor: function(editor, editorSettings) {

        if (!editor)
            editor = te.editor;
        if (!editorSettings)
            editorSettings = te.settings;

        var session = editor.getSession();

        editor.setReadOnly(false);
        editor.setHighlightActiveLine(false);
        editor.setShowPrintMargin(editorSettings.showPrintMargin);

        editor.setTheme("ace/theme/" + editorSettings.theme);
        editor.setFontSize(editorSettings.fontSize);
        editor.renderer.setShowGutter(editorSettings.showLineNumbers);
        session.setTabSize(editorSettings.tabSpaces);

        session.setNewLineMode("windows");

        // disable keys in editor so we can handle them here
        // Alt-k - HREF dialog
        editor.commands.bindKeys({
            "alt-k": null,
            "ctrl-b": function () { $("#btnBold").triggerHandler("click"); },
            "ctrl-i": function () { $("#btnItalic").triggerHandler("click"); },
            "ctrl-k": function () { $("#btnHref").triggerHandler("click"); },
            "alt-c": function () { $("#btnCode").triggerHandler("click"); },
            "alt-i": function () { $("#btnImage").triggerHandler("click"); },
            "alt-2": function () { $("#btnH2").triggerHandler("click"); },
            "alt-3": function () { $("#btnH3").triggerHandler("click"); },
            "alt-4": function () { $("#btnH4").triggerHandler("click"); },
            "alt-5": function () { $("#btnH5").triggerHandler("click"); }                        
        });

        

        editor.renderer.setPadding(15);
        editor.renderer.setScrollMargin(5, 5, 0, 0); // top,bottom,left,right

        //te.editor.getSession().setMode("ace/mode/markdown" + lang);   

        // fill entire view
        te.editor.setOptions({
            maxLines: 0,
            minLines: 0
            //wrapBehavioursEnabled: editorSettings.wrapText
        });

        // allow editor to soft wrap text
        session.setUseWrapMode(editorSettings.wrapText);
        session.setOption("indentedSoftWrap", false);

        //session.setWrapLimitRange();        

        // let the fox app know that we've lost focus
        editor.on("blur", function(e) {
            var value = te.getvalue();
            console.log(value);
            $("#Message").val(value);
            console.log($("#Message").val());
        });

        $("pre[lang]").on("keydown", function keyDownHandler(e) {
            if (!te.fox)
                return null;

            // Ctrl keys are not passed to VFP so we explicitly
            // pass the key to FoxPro to let it handle ctrl-key combos
            if (e.ctrlKey && e.keyCode != 17) {
                var key = String.fromCharCode(e.keyCode);
                if (te.fox.textbox.ctrlkeyfired(key) === true) {
                    e.preventDefault();
                    e.stopPropagation();
                    return false;
                }
            }

            return editor;
        });
    },
    initializeeditor: function() {    	
    	te.configureAceEditor(null,null);
    },
    status: function status(msg) {
        alert(msg);
    },
    getvalue: function (ignored) {
        var text = te.editor.getSession().getValue();
        return text.toString();
    },
    setvalue: function (text, pos) {
        if (!pos)
            pos = -1;  // first line
        
        te.editor.setValue(text, pos);
        te.editor.getSession().setUndoManager(new ace.UndoManager());

        setTimeout(function () {
            te.editor.resize(true);  //force a redraw
        }, 30);
    },
    refresh: function (ignored) {
        te.editor.resize(true);  //force a redraw
    },
    setfont: function (size, fontFace, weight) {
        if (size)
            te.editor.setFontSize(size);
        if (fontFace)
            te.editor.setOption('fontFamily', fontFace);
        if (weight)
            te.editor.setOption('fontWeight', weight);
    },
    setselection: function (text) {    
        var range = te.editor.getSelectionRange();
        te.editor.getSession().replace(range, text);
    },
    setselposition: function(index,count) {    	
    	var doc = te.editor.getSession().getDocument();
        var lines = doc.getAllLines();

    	 var offsetToPos = function( offset ) {
            var row = 0, col = 0;
            var pos = 0;
            while ( row < lines.length && pos + lines[row].length < offset) {
                pos += lines[row].length;
                pos++; // for the newline
                row++;
            }
            col = offset - pos;
            return {row: row, column: col};
        };             
		var start = offsetToPos( index );
        var end = offsetToPos( index + count );

    	var sel = te.editor.getSelection();
    	var range = sel.getRange();
    	range.setStart(start);
    	range.setEnd(end);
    	sel.setSelectionRange( range );
    },
    getselection: function (ignored) {
        return te.editor.getSelectedText();
    },
    gotfocus: function (ignored) {
        te.setfocus();
    },
    setfocus: function (ignored) {
        te.editor.resize(true);

        setTimeout(function () {
            te.editor.focus();
            setTimeout(function () {
                te.editor.focus();
            }, 400);
        }, 50);
    },
    // forces Ace to lose focus
    losefocus: function(ignored) {
        $("#losefocus").focus();
    },
    setlanguage: function (lang) {
        if (!lang)
            lang = "text";
        if (lang == "vfp")
            lang = "foxpro";
        if (lang == "c#")
            lang = "csharp";
        if (lang == "c++")
            lang == "c_cpp"

        te.editor.getSession().setMode("ace/mode/" + lang);
    },
    enablespellchecking: function(disable) {
        if (!disable)
            spellcheck.enable();
        else
            spellcheck.disable();
    },
    isspellcheckingenabled: function(ignored) {
        return editorSettings.enableSpellChecking;
    },
    checkSpelling: function (word) {        
        if (!word || !editorSettings.enableSpellChecking)
            return true;

        // use typo
        if (spellcheck.dictionary) {            
            var isOk = spellcheck.dictionary.check(word);            
            return isOk;
        }

        // use COM object        
        return te.fox.textbox.checkSpelling(word,editorSettings.dictionary);
    },
    suggestSpelling: function (word, maxCount) {
        if (!editorSettings.enableSpellChecking)
            return null;

        // use typo
        if (spellcheck.dictionary)
            return spellcheck.dictionary.suggest(word);

        // use COM object
        var words = te.fox.textbox.suggestspelling(word,editorSettings.dictionary);        
        words = words.split(',');        
        if (words.length > maxCount)
            words = words.slice(0, maxCount);

        return words;
    },
    addWordSpelling: function (word) {        
        te.fox.textbox.addwordspelling(word, editorSettings.dictionary);
    },
    onblur: function () {
        fox.textbox.lostfocus();
    }
}


$(document).ready(function () {
    te.initialize();
});


window.onerror = function windowError(message, filename, lineno, colno, error) {    
    var msg = "";
    if (message)
        msg = message;
    if (filename)
        msg += ", " + filename;
    if (lineno)
        msg += " (" + lineno + "," + colno + ")";

    // show error messages in a little pop overwindow
    if (editorSettings.isDebug)
        status(msg);

    console.log(msg);

    if(textEditor)
        textEditor.lastError = msg; 

    // don't let errors trigger browser window
    return true;
}

// window.ondrop = function(event) {
//   alert('dropped');

//   var lines = event.dataTransfer.getData("text/uri-list").split("\n");
//   for (var i = lines.length - 1; i >= 0; i--) {
//   	line = lines[i];
//     if (line.startsWith("#"))
//       continue;

//   	alert(line);
//   }

//   event.preventDefault();
// }
// window.ondragover = function(event) {
// 	event.preventDefault();
// 	return false;
// }


// This function is global and called by the parent
// to pass in the form object and pass back the text
// editor instance that allows the parent to make
// calls into this component
function initializeinterop(helpBuilderForm, textbox) {
    te.fox = {};
    te.fox.helpBuilderForm = helpBuilderForm;    
    te.fox.textbox = textbox;    
    return window.textEditor;
}


function status(msg) {
    var $el = $("#message");
    if (!msg)
        $el.hide();
    else {
        var dt = new Date();
        $el.text(dt.getHours() + ":" + dt.getMinutes() + ":" +
            dt.getSeconds() + "." + dt.getMilliseconds() +
            ": " + msg);
        $el.show();
    }
}
