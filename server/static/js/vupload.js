$(function () {
  $('#fileupload').fileupload({
    acceptFileTypes: "mp3",
    autoUpload: true,
    dataType: 'json',
    done: function (e, data) {
      loadAudioFile(data.result.file_id);
      var elapsed = 0;
      var interval = 1000;
      var estimatedDuration = 45*1000; // approx upload time here, usually ~15-30 seconds
      updateAnalyzeProgess = function () {
        elapsed += interval;
        var intPercentDone = ((elapsed/estimatedDuration)*100);
        intPercentDone = Math.min(intPercentDone, 90); // never fake progress pass 90%
        analyzeProgress(intPercentDone.toFixed(0)+'%');
      };
      analyzeProgressTimer = window.setInterval(updateAnalyzeProgess, interval);

      $.ajax({
        type: 'POST',
        url: '/analyze',
        data: {file_id:data.result.file_id},
        dataType: 'json',
        success: function (data, textStatus, jqXHR) {
          analyzeProgress("100%");
          window.clearInterval(analyzeProgressTimer);
          setAnalysis(data.analysis);
          playAudio();
          handleFullAnalysisCallbacks();
        },
        error: function (jqXHR, textStatus, errorThrown) {
          window.clearInterval(analyzeProgressTimer);
          analyzeProgress("0%");
          uploadProgress("0%");
          clearAnalysis();
          removeAudio();
          errorMessage("Your file could not be analyzed. Please try another file!")
        }
      });
    },
    fileuploadfail: function (e, data) {
      analyzeProgress("0%");
      uploadProgress("0%");
      clearAnalysis();
      errorMessage("Your file could not be uploaded. Please try another file!")
    }
  });
});

$('#fileupload').bind('fileuploadstart', function () {
  window.analysis = null;
  analyzeProgress("0%");
  uploadProgress("0%");

  var widget = $(this),
      interval = 50,
      total = 0,
      loaded = 0,
      loadedBefore = 0,
      progressTimer,
      progressHandler = function (e, data) {
          loaded = data.loaded;
          total = data.total;
      },
      stopHandler = function () {
        uploadProgress("100%");
        widget.unbind('fileuploadprogressall', progressHandler);
        widget.unbind('fileuploadstop', stopHandler);
        window.clearInterval(progressTimer);
      },
      formatPercentage = function (floatValue) {
        val = (floatValue * 100).toFixed(0) + '%';
        return val;
      },
      updateProgressElement = function (loaded, total, bps) {
        uploadProgress(
                formatPercentage(loaded / total)
        );
      },
      intervalHandler = function () {
          var diff = loaded - loadedBefore;
          if (!diff) {
              return;
          }
          loadedBefore = loaded;
          updateProgressElement(
              loaded,
              total,
              diff * (1000 / interval)
          );
      };
  widget.bind('fileuploadprogressall', progressHandler);
  widget.bind('fileuploadstop', stopHandler);
  progressTimer = window.setInterval(intervalHandler, interval);
});
