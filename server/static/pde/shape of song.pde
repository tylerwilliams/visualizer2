// TODO: 
// 1) Get Zoom working
// 2) Prune properly
// 3) Get longer?

// AUTHOR: <a href="http://twitter.com/jsundram">Jason Sundram</a>

/*BEGIN_DOCSTRING 
<p>
<b>Shape of Song</b> is an attempt to create a visualization like Martin Wattenberg's <a href="http://www.turbulence.org/Works/song/gallery/gallery.html">The Shape of Song</a> using The Echo Nest's analysis information instead of MIDI.
</p>
END_DOCSTRING*/

void setup()
{
    size(get_max_canvas_width(), get_max_canvas_height());
    background(0);
    frameRate(30);
    smooth();
}

var TRACK = null;
var TRACK_START;
var TRACK_END;
var DATA = null;
var curr_height;
var curr_width;
var resized = false;
var BASE = null;
var BASE_HEIGHT = 10;

void draw()
{
    if (curr_height != get_max_canvas_height() || curr_width != get_max_canvas_width())
    {
        curr_height = get_max_canvas_height();
        curr_width = get_max_canvas_width();
        resized = true;
        
        resize(this, curr_width, curr_height, 0);
    }
    
    pushStyle();
    stroke(255);
    noFill();
    //arc(width / 2, height / 2, 100, 100, PI, 0);
    popStyle();
    
    if (window.current_track)
    {
        try
        {
            var track_changed = (TRACK != window.current_track);
            if (track_changed)
            {
                background(0); // blank us out.
                TRACK = window.current_track;
                TRACK_START = 0;
                TRACK_END = TRACK.duration;
                //console.log("Song Machine:", day(), hour() + ":" + minute());
                var seg = new SongMachine(TRACK, 'segments');
                var bea = new SongMachine(TRACK, 'beats');
                var bar = new SongMachine(TRACK, 'bars');
                //var sec = new SongMachine(TRACK, 'sections');
                
                DATA = {};
                DATA['segs'] = seg.candidates;
                DATA['beas'] = bea.candidates;
                DATA['bars'] = bar.candidates;
                //DATA['secs'] = sec.candidates;
            }
            
            if (track_changed || resized)
            {
                BASE = height - BASE_HEIGHT;
                background(0);
                drawTrack();
            }
        }
        catch(e)
        {
            console.log(e);
        }
        drawScrubber();
        //drawZoom(0);
    }
    
    resized = false; // after we've made it through a draw loop, we've resized.
}

void drawTrack()
{
    pushStyle();
    noFill();
    
    //console.log("drawTrack()");
    // location of the ellipse as the center of the shape. width and height parameters specify the radius.
    ellipseMode(RADIUS);
    function drawArc(i, j, member)
    {
        var s1 = TRACK[member][i];
        var s2 = TRACK[member][j];
        if ((TRACK_START < s1.start && s1.start < TRACK_END) || (TRACK_START < s2.start && s2.start < TRACK_END))
        {
            var duration = (TRACK_END - TRACK_START);
            var x1 = seconds_to_offset(s1.start);
            var x2 = seconds_to_offset(s2.start);
            strokeWeight(s1.duration * width / duration);
            
            // draw an arc connecting x1 and x2
            // arc(x, y, width, height, start, stop)
            var radius = (x2 - x1) / 2;
            var midpoint = x1 + radius;
            arc(midpoint, BASE, radius, radius, 0, 180);
        }
    }
    
    
    function plotCandidates(candidates)
    {
        // figure out how to draw arcs
        for (var i = 0; i < candidates.length; i++)
        {
            var m = candidates.length-1; // find the index of the first one that comes after i.
            for (var j = 1; j < candidates[i].length; j++)
            {
                if (i < candidates[i][j] && candidates[i][j] < m)
                    m = candidates[i][j];
            }
            if (m != candidates.length - 1)
                drawArc(i, m, candidates.member);
        }
    }
    
    stroke(128, 64, 128, 128); // pink
    plotCandidates(DATA['segs']);
    
    stroke(0, 64, 128, 128); // blue
    plotCandidates(DATA['beas']);
    
    stroke(0, 128, 64, 64); // green
    plotCandidates(DATA['bars']);
    
    //stroke(0, 64, 128, 128);
    //plotCandidates(DATA['secs']);
    
    popStyle();
}

int offset_to_seconds(x_offset)
{
    return TRACK_START + (x_offset / width) * (TRACK_END - TRACK_START);
}

int seconds_to_offset(s)
{
    return map(s, TRACK_START, TRACK_END, 0, width);
}

void mouseClicked()
{
    if (window.current_track)
    {
        var seek = offset_to_seconds(mouseX);
        $("#jquery_jplayer").jPlayer( "playHeadTime", seek * 1000); // player wants ms.
    }
}

void drawScrubber()
{
    var t = TRACK;
    pushStyle();
    
    if (window.timestamp < TRACK_START || TRACK_END < window.timestamp)
        return;
    
    // draw track bar
    fill(0, 64, 128, 128);
    rect(0, height-10, width, 10);
    
    // draw current segment:
    var i = get_index(TRACK.segments, window.timestamp);
    if (i != -1)
    {
        fill(255, 128);
        OLD_SCRUB = i;
        var start = seconds_to_offset(TRACK.segments[i].start);
        var duration = duration = width * TRACK.segments[i].duration / (TRACK_END - TRACK_START);
        rect(start, BASE, duration, BASE_HEIGHT);
    }
    
    popStyle();
}

/* Zoom stuff */
var startX = null;
var DRAGGED = false;

void keyPressed()
{
    if (key == ESC)
    {
        TRACK_START = 0;
        TRACK_END = TRACK.duration;
        resized = true;
    }
}

void mousePressed()
{
    startX = mouseX;
}

void mouseDragged()
{
    DRAGGED = true;
}

void mouseReleased()
{
    if (DRAGGED)
    {
        var x1 = Math.min(mouseX, startX);
        var x2 = Math.max(mouseX, startX);
        
        // Figure out where to zoom.
        var s = Math.floor(TRACK_START + (x1 / width) * (TRACK_END - TRACK_START));
        var e = Math.ceil(TRACK_START + (x2 / width) * (TRACK_END - TRACK_START));
        if (3 < e - s)
        {
            TRACK_START = s;
            TRACK_END = e;
            resized = true;
        }
    }
    DRAGGED = false;
    startX = null;
}

void drawZoom(int top)
{
    var s, w;
    if (startX)
    {
        s = Math.min(startX, mouseX);
        w = Math.abs(mouseX - startX);
        fill(255);
    }
    else
    {
        s = 0;
        w = width;
        fill(0);
    }
    rect(s, top, w, 10);
}

