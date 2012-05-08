window.segmentCallbacks = new Array();
window.tatumCallbacks = new Array();
window.beatCallbacks = new Array();
window.barCallbacks = new Array();
window.sectionCallbacks = new Array();
window.fullAnalysisCallbacks = new Array();
window.timestampCallbacks = new Array();
window.viewportSizeChangeCallbacks = new Array();

function clear_callbacks() {
    window.segmentCallbacks = new Array();
    window.tatumCallbacks = new Array();
    window.beatCallbacks = new Array();
    window.barCallbacks = new Array();
    window.sectionCallbacks = new Array();
    window.fullAnalysisCallbacks = new Array();
    window.timestampCallbacks = new Array();
    window.viewportSizeChangeCallbacks = new Array();
}

soundManager.url = '/static/swf/';
soundManager.useHighPerformance = true;
soundManager.useFastPolling = true;
soundManager.autoLoad = true;
soundManager.debugMode = false;
soundManager.flashPollingInterval = 20;
soundManager.html5PollingInterval = 20;
soundManager.preferFlash = false;

$(window).resize(function() {
    if(this.resizeTO) clearTimeout(this.resizeTO);
    this.resizeTO = setTimeout(function() {
        $(this).trigger('resizeEnd');
    }, 500);
});

$(window).bind('resizeEnd', function() {
    //do something, window hasn't changed size in 500ms
    // hopefully the user is done dragging it
    handleResizeCallbacks();
});

function loadAudioFile(file_id) {
    removeAudio();
    var file_url = "/download?file_id="+file_id;
    var s = soundManager.createSound({
      id:file_id,
      url:file_url,
      loops: 999,
      autoLoad: true
    });
    setCurrentSound(s);
}

function setAnalysis(analysis) {
    window.analysis = analysis;
}

function clearAnalysis() {
    return setAnalysis(null);
}
function getCurrentSound() {
    return window.current_sound;
}

function setCurrentSound(sound) {
    window.current_sound = sound;
}
function checkAudio() {
    if ((!getCurrentSound()) || (!getCurrentSound().url)) {
        errorMessage("No Audio! Try uploading an mp3 first")
    }
}

function playAudio() {
    getCurrentSound().play({
        whileplaying: function() {
            handleAllCallbacks(this.position/1000);
         }
    });
}

function pauseAudio() {
    getCurrentSound().pause();
}

function togglePlaying() {
    getCurrentSound().togglePause();
}

function removeAudio() {
    if (getCurrentSound()) {
        getCurrentSound().stop();
        getCurrentSound().unload();
        getCurrentSound().destruct();
    }
}

function skipNext() {
    checkAudio();
    var current = getCurrentSound().position;
    getCurrentSound().setPosition(Math.max(0, current-15000));
}

function skipPrevious() {
    checkAudio();
    var current = getCurrentSound().position;
    var duration = getCurrentSound().duration;
    getCurrentSound().setPosition(Math.min(duration, current+15000));
}
// get_index is a binary search across a list of features
// each feature *must* contain a 'start' and 'duration' key
// luckily all the features in our analyses do.
function findFeature(feature_list, offset) {
    var low = 0;
    var high = feature_list.length - 1;

    while (low <= high)
    {
        var mid = parseInt((low + high) / 2);
        var midVal = feature_list[mid];

        if (midVal['start'] + midVal['duration'] < offset)
            low = mid + 1;
        else if (midVal['start'] > offset)
            high = mid - 1;
        else
            return feature_list[mid]; // found it!
    }
    return null;  // key not found.
}

function getFeatureAt(analysis_feature_key, timestamp) {
    return findFeature(window.analysis[analysis_feature_key], timestamp);
}

// return int viewport width for handling sketch size
function getViewportWidth() {
    return $("#processing-canvas").width();
}

// return int viewport height for handling sketch size
function getViewportHeight() {
    return $("#processing-canvas").height();
}

function handleFeatureCallback(feature, callback_map) {
    // console.log("feature callback!");
    keys = Object.keys(callback_map);
    for (var i = 0; i < keys.length; i++) {
        callback_map[keys[i]](feature);
    }
}

function handleFullAnalysisCallbacks() {
    keys = Object.keys(window.fullAnalysisCallbacks);
    for (var i = 0; i < keys.length; i++) {
        window.fullAnalysisCallbacks[keys[i]](window.analysis);
    }
}

function handleResizeCallbacks() {
    keys = Object.keys(window.viewportSizeChangeCallbacks);
    for (var i = 0; i < keys.length; i++) {
        window.viewportSizeChangeCallbacks[keys[i]](getViewportWidth(), getViewportHeight());
    }
}

function handleAllCallbacks(timestamp) {
    if (!window.analysis) {
        return false;
    }
    // segment
    if (Object.keys(window.segmentCallbacks).length) {
        handleFeatureCallback(getFeatureAt('segments', timestamp), window.segmentCallbacks);
    }
    // tatum
    if (Object.keys(window.tatumCallbacks).length) {
        handleFeatureCallback(getFeatureAt('tatums', timestamp), window.tatumCallbacks);
    }
    // beat
    if (Object.keys(window.beatCallbacks).length) {
        handleFeatureCallback(getFeatureAt('beats', timestamp), window.beatCallbacks);
    }
    // bar
    if (Object.keys(window.barCallbacks).length) {
        handleFeatureCallback(getFeatureAt('bars', timestamp), window.barCallbacks);
    }
    // section
    if (Object.keys(window.sectionCallbacks).length) {
        handleFeatureCallback(getFeatureAt('sections', timestamp), window.sectionCallbacks);
    }
    // timestamp
    if (Object.keys(window.timestampCallbacks).length) {
        handleFeatureCallback(timestamp, window.timestampCallbacks);
    }

}

function registerGenericCallback(callback, callbackList) {
    if (!callbackList[callback.name]) {
        callbackList[callback.name] = callback;
        return true;
    } else {
        return false;
    }
}

function deregisterGenericCallback(callback, callbackList) {
    return (delete callbackList[callback.name]);
}


// ======================================
// = PROCESSING TO JAVASCRIPT INTERFACE =
// ======================================

// return the full analysis object for summary type viz
function registerFullAnalysisCallback(cb) {
    var r = registerGenericCallback(cb, window.fullAnalysisCallbacks);
    handleFullAnalysisCallbacks();
    return r;
}
function deregisterFullAnalysisCallback(cb) {
    return deregisterGenericCallback(cb, window.fullAnalysisCallbacks);
}

// resize
function registerViewportSizeChangeCallback(cb) {
    var r = registerGenericCallback(cb, window.viewportSizeChangeCallbacks);
    handleResizeCallbacks();
    return r;
}
function deregisterViewportSizeChangeCallback(cb) {
    return deregisterGenericCallback(cb, window.viewportSizeChangeCallbacks);
}

// segment
function registerSegmentCallback(cb) {
    return registerGenericCallback(cb, window.segmentCallbacks);
}
function deregisterSegmentCallback(cb) {
    return deregisterGenericCallback(cb, window.segmentCallbacks);
}

// tatum
function registerTatumCallback(cb) {
    return registerGenericCallback(cb, window.tatumCallbacks);
}
function deregisterTatumCallback(cb) {
    return deregisterGenericCallback(cb, window.tatumCallbacks);
}

// beat
function registerBeatCallback(cb) {
    return registerGenericCallback(cb, window.beatCallbacks);
}
function deregisterBeatCallback(cb) {
    return deregisterGenericCallback(cb, window.beatCallbacks);
}

// bar
function registerBarCallback(cb) {
    return registerGenericCallback(cb, window.barCallbacks);
}
function deregisterBarCallback(cb) {
    return deregisterGenericCallback(cb, window.barCallbacks);
}

// section
function registerSectionCallback(cb) {
    return registerGenericCallback(cb, window.sectionCallbacks);
}
function deregisterSectionCallback(cb) {
    return deregisterGenericCallback(cb, window.sectionCallbacks);
}

// timestamp
function registerTimestampCallback(cb) {
    return registerGenericCallback(cb, window.timestampCallbacks);
}
function deregisterTimestampCallback(cb) {
    return deregisterGenericCallback(cb, window.timestampCallbacks);
}

