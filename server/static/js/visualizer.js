/// OH YEAH DO THAT NASTY SHIT
/// EAT ME JAVASCRIPT 
window.analysis = null;

if (typeof Object.keys != 'function') {
    Object.keys = function(obj) {
       if (typeof obj != "object" && typeof obj != "function" || obj == null) {
            throw TypeError("Object.keys called on non-object");
       } 
       var keys = [];
       for (var p in obj) obj.hasOwnProperty(p) &&keys.push(p);
       return keys;
    }
}

function analyzeProgress(percentage_string) {
    var parent = $("#analyze-progress-bar").parent();
    if (!parent.hasClass("progress-striped")) {
        parent.addClass("progress-striped")
    }
    $("#analyze-progress-bar").width(percentage_string);
    if (percentage_string.substring(0,3) == "100") {
        parent.removeClass("progress-striped")
    }
}

function uploadProgress(percentage_string) {
    var parent = $("#upload-progress-bar").parent();
    if (!parent.hasClass("progress-striped")) {
        parent.addClass("progress-striped")
    }
    $("#upload-progress-bar").width(percentage_string);
    if (percentage_string.substring(0,3) == "100") {
        parent.removeClass("progress-striped")
    }
}

function successMessage(message_string) {
    // GREEN!
    bootstrap.notify(message_string, {mode: "success"});
}

function infoMessage(message_string) {
    // BLUE!
    bootstrap.notify(message_string, {mode: "info"});
}

function warningMessage(message_string) {
    // YELLOW!
    bootstrap.notify(message_string, {mode: "warning"});
}

function errorMessage(message_string) {
    // RED
    bootstrap.notify(message_string, {mode: "error"});
}

function getProcessingCanvas() {
    return $("#processing-canvas")[0];
}

function loadSketchFromData(sketch_data) {
    // disable std processing console
    Processing.logger = console
    
    // kill callbacks
    clear_callbacks();
    // exit any processing object
    if (window.p) {
        window.p.exit();
    }
    // update our editor div
    setEditorText(sketch_data);
    // try to create new processing object
    window.p = new Processing(getProcessingCanvas(), sketch_data);
    // register handlers for new sketch
    window.p.setJavaScript(this);
}
 
function loadDefaultSketch(sketch_path) {
    $.ajax({
        type: 'GET',
        url: '/static/pde/'+sketch_path,
        data: null,
        dataType: 'html',
        success: function (data, textStatus, jqXHR) {
          loadSketchFromData(data);
        },
        error: function (jqXHR, textStatus, errorThrown) {
          errorMessage("Unable to load "+sketch_path+": "+textStatus);
        }
      });
}

function parseFragID(fragment_identifier) {
    if (fragment_identifier[0] == "#") {
        fragment_identifier = fragment_identifier.slice(1);
    }
    var pairs = fragment_identifier.split("&");
    var map = new Object;
    for (var i = 0; i < pairs.length; i++) {
        var kv = pairs[i].split("=");
        map[kv[0]] = kv[1];
    }
    return map;
}

