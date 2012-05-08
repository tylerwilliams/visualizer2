// TODO:
//  change loudness that beat markers use to be scaled relative to piece's loudness.
//  know the length of the measure when laying out beat markers.
//  color chromagram with timbre, a la musicbox?
//  figure out how to load fonts, etc, so can use chroma_height for height of pitches in segments.
//  Fadein, fadeout with alpha?

// AUTHOR: <a href="http://twitter.com/jsundram">Jason Sundram</a>

/*BEGIN_DOCSTRING 
<b>Comprehensive</b> shows you almost every single piece of data present in the Echo Nest analysis of your track. 
<p><br>
<p>
<ol>
<li>On the left, each box shows chroma strength for each of the 12 pitches the analyzer detects. These are organized starting from the pitch which is the overall key of the song. (So if the song is in G major, the bottom pitch is G).</li>
<li>At the top, we see an overview of loudness for the whole track, split up by sections. Each section is colored by its key.</li>
<li>Beneath the loudness, we can see an overview of the chroma for the whole track. </li>
<li>On the right, boxes stack up with each beat in every bar.</li>
<li>Beneath that, 4 circles correspond to RGB triplets for each of the 12 timbre coefficients.</li>
<li>In the center, an oval represents segment loudness. Its thickness is the difference between max and start loudness. It is colored by timbre.</li>
</ol>
</p>
<br>
<p>
Features:
1) Scrub. Click anyplace in the loudness indicator (bar at the top) to hear the music at that point.
</p>

END_DOCSTRING*/

void setup()
{
    size(get_max_canvas_width(), get_max_canvas_height());
    background(0);
    // frameRate. default is 60. If the average track is 120bpm, that's 2 bps, 
    // so this is good for a segment rate of up to 15 segments/beat.
    frameRate(30); 
    enable_segments();
    enable_beats();
    enable_bars();
    fontA = loadFont("Verdana");
    textFont(fontA, 10);
}

Rect.prototype.paint = function(fill_color, fill_alpha)
{
    pushStyle();
    fill(fill_color, fill_alpha);
    rect(this.left, this.top, this.width, this.height);//pjs function
    popStyle();
}

void mouseClicked()
{
    if (window.current_track)
    {
        var seek = window.current_track.time_from_point(mouseX, mouseY);
        console.log("Seeking to", seek);
        if (seek)
            $("#jquery_jplayer").jPlayer( "playHeadTime", seek * 1000); // player wants ms.
    }
}

// map frequency (as wavelength of light to rgb using dan bruton's algorithm)
var PITCH_COLORS = new Array(#2fff00, #a0ff00, #ffe300, #ff5a00, #ff0000, #ff0000, #a70000, #6200b5, #4300f2, #0000ff, #0084ff, #00ffd8);


var BORDER = 10;
var RIGHT_MARGIN = 100;
var SQ_HEIGHT; // side of pitch square, updated in draw()

// Rects
var SCRUBBER;
var CHROMA_BAR;
var CENTRAL_SQUARE;
var TIMBRE_BALLS;
var METER_AREA;
var METER_TEXT;
var METADATA;
/*

Screen layout:
----------------------------------------|
|   |   scrubber bar + chromagram       |
|   |___________________________________|
| C |                              |    |
| H |                              |me- |
| R |           central            |ter |
| O |           square             |    |
| M |                              |    |
| A |                              ---- |
________________________________________|

*/

var TRACK = null;
// global variables used only in draw() aren't all caps.
var track_changed = false;
var curr_beat = null;
var curr_beats = null;

var curr_height;
var curr_width;
var resized = false;


void setupGeometry()
{
    var SCRUBBER_HEIGHT = 25;
    var CHROMAGRAM_HEIGHT = 12 * BORDER / 2;
    var TIMBRE_BALL_COUNT = 4; 
    var TIMBRE_BALL_DIAMETER = (RIGHT_MARGIN - (TIMBRE_BALL_COUNT + 1) * BORDER / 2 - BORDER) / TIMBRE_BALL_COUNT;
    
    SQ_HEIGHT = (height - (13 * BORDER)) / 12;
    var LEFT = SQ_HEIGHT + 2 * BORDER;
    
    SCRUBBER = new Rect(LEFT + 2*SCRUBBER_HEIGHT, BORDER, 
                width - RIGHT_MARGIN - LEFT - 2*SCRUBBER_HEIGHT - SCRUBBER_HEIGHT, SCRUBBER_HEIGHT);
    CHROMA_BAR = new Rect(0, 0, LEFT, height);
    CHROMA_LABELS = new Rect(LEFT, 0, 2*SCRUBBER_HEIGHT, height);
    CENTRAL_SQUARE = new Rect(  CHROMA_LABELS.right(), 
                                SCRUBBER.bottom() + CHROMAGRAM_HEIGHT,
                                SCRUBBER.width, 
                                height - SCRUBBER.bottom() - CHROMAGRAM_HEIGHT);
    
    TIMBRE_BALLS = new Rect(width - RIGHT_MARGIN, height - TIMBRE_BALL_DIAMETER - BORDER, 
                            RIGHT_MARGIN - BORDER, TIMBRE_BALL_DIAMETER);
    
    METER_AREA = new Rect(  width - RIGHT_MARGIN,
                            SCRUBBER.bottom() + CHROMAGRAM_HEIGHT, 
                            RIGHT_MARGIN - BORDER, 
                            height - TIMBRE_BALL_DIAMETER - 2*BORDER - SCRUBBER_HEIGHT - CHROMAGRAM_HEIGHT-2);
    METER_TEXT = new Rect(METER_AREA.left - 40, METER_AREA.top, 40, METER_AREA.height);
    METADATA = new Rect(METER_AREA.left, 0, width - METER_AREA.left, BORDER + SCRUBBER.height + CHROMAGRAM_HEIGHT);
}

void draw()
{
    if (curr_height != get_max_canvas_height() || curr_width != get_max_canvas_width())
    {
        curr_height = get_max_canvas_height();
        curr_width = get_max_canvas_width();
        resized = true;
        
        resize(this, curr_width, curr_height, 0);
        setupGeometry();
    }
    
    
    if (window.current_track)
    {
        if (TRACK != window.current_track)
        {
            track_changed = true;
            TRACK = window.current_track;
            curr_tatums = [];
            curr_beats = [];
        }
        else
            track_changed = false;
        
        if (track_changed || resized)
            window.current_track.paint(width, height);
        
        window.current_track.update(window.timestamp);
    }
    
    // ERASE BG for meter:
    METER_AREA.paint(0, 255);
    METER_TEXT.paint(0, 255);
    
    // Instantaneous
    if (window.segment)
        window.segment.paint(width, height);
    
    // Metrical
    if (window.beat && window.beat != curr_beat)
    {
        curr_beat = window.beat;
        curr_beats.push(curr_beat);
    }
    
    if (window.bar)
    {
        // Make sure curr_beats is good to go.
        var temp = [];
        for (int i = 0; i < curr_beats.length; i++)
            if (curr_beats[i].startsWithin(window.bar))
                temp.push(curr_beats[i])
        curr_beats = temp.slice();
    }
    
    pushStyle();
    if (TRACK)
    {
        METER_AREA.paint(0, 255);
        
        rectMode(CENTER);
        fill(PITCH_COLORS[TRACK.key], 196); 
        var spacing = (METER_AREA.height - 2*BORDER) / (TRACK.meter + 1);
        var top = METER_AREA.bottom() - BORDER;
        var columns = ceil(curr_beats.length / TRACK.meter);
        
        lf = loudness_factor; // brevity
        
        for (int i = 0; i < curr_beats.length; i++)
        {
            if (i % TRACK.meter == 0)
                top = METER_AREA.bottom() - BORDER;
            top -= spacing;
            var column = floor(i/TRACK.meter); // 0-based
            var radius = min(spacing - BORDER, METER_AREA.width / columns);
            var left = METER_AREA.left + column * radius;
            
            var current = curr_beats[i];
            current.computeOverallLoudness(TRACK.segments); // need to do this before accessing current.loudness
            loudness_bias = map(lf(current.loudness), lf(TRACK.min_loudness), lf(TRACK.max_loudness), 0, 255);
            //console.log(loudness_bias, current.loudness, TRACK.min_loudness, TRACK.max_loudness);
            fill(PITCH_COLORS[TRACK.key], loudness_bias); 
            rect(left + radius/2, top, radius, radius);
            //text(formatTime(curr_beats[i].start), METER_TEXT.left, top + 2, 20, 4);
        }
    }
    popStyle();
    resized = false; // after we've made it through a draw loop, we've resized.
}


// Not sure if this function is of general use.
Rect.prototype.mapX = function(x) { return x - this.left; };

TrackInfo.prototype.update = function(timestamp)
{

    drawSections(); // don't actually need to draw all of them, but I am lazy!
    
    // Highlight the current segment
    pushStyle();
    
    fill(PITCH_COLORS[(this.key + 7) % 12], 96);
    
    frac = timestamp / this.duration;
    if (1 <= frac)
        frac = 0; // If it's finished, return to the start.
    
    float x = SCRUBBER.left + frac * SCRUBBER.width;
    rect(x, SCRUBBER.top, 4, SCRUBBER.height); // 4 => knob width
    popStyle();
    
    // Metadata (includes currently playing time, so needs an update)
    pushStyle();
    METADATA.paint(0, 255);
    stroke(255);
    textAlign(LEFT, CENTER);
    var text_height = SCRUBBER.height/2;
    text(this.bpm + ' bpm in ' + nf(this.meter, 1) + "/4", METADATA.left, METADATA.top + text_height);
    text(formatTime(timestamp) + " / " + formatTime(this.duration), METADATA.left, METADATA.top + 2*text_height);
    
    popStyle();
};


TrackInfo.prototype.time_from_point = function(x, y)
{

    if (SCRUBBER.contains(x,y))
    {
        offset = SCRUBBER.mapX(x);
        seekto = (offset / SCRUBBER.width) * this.duration;
        return seekto;
    }
    else
        return null;
};

function formatTime(seconds)
{
    // nf() sucks balls; calling it with 0 gives 'undefined'.
    // add a small number (less than the precision we display)
    // in order to get the zeros we expect and deserve.
    var x = 0.01 + seconds; 
    var s = x % 60;
    var m = (x - s) / 60;
    return nf(m, 2) + ":" + nf(s, 2, 1);
}

void drawChromagram()
{
    pushStyle();
    var curr = SCRUBBER.left;
    float w = 0;
    
    // lf = loudness_factor; // brevity
    for (int j = 0; j < TRACK.segments.length; j++)
    {
        Segment current = TRACK.segments[j];
        // loudness_bias = map(lf(current.loudness), lf(TRACK.min_loudness), lf(TRACK.max_loudness), .1, 2);
        float w = SCRUBBER.width * current.duration / TRACK.duration;
        var pmin = min(current.pitches);
        var pwidth = max(current.pitches) - pmin;
        if (pwidth < .001)
            pwidth = .1; // avoid dividing by 0
        
        int k = (TRACK.key + 11) % 12;
        for (int c = 0; c < 12; c++)
        {
            // float chroma = loudness_bias * (current.pitches[k] - pmin) / pwidth; // now in range 0, 2
            float chroma = (current.pitches[k] - pmin) / pwidth; // now in range 0, 1
            fill(PITCH_COLORS[k], chroma * 255);
            rect(curr, SCRUBBER.bottom() + c*BORDER/2, w, BORDER/2);
            
            k = ((k - 1) + 12) % 12;
        }
        
        curr += w;
    }
    popStyle();
}


void drawSections()
{
    pushStyle();

    var curr = SCRUBBER.left;
    int start_point = 0;
    // First, erase background.
    SCRUBBER.paint(0, 255);
    
    // ok, now draw.
    var min_loudness = loudness_factor(TRACK.min_loudness);
    var max_loudness = loudness_factor(TRACK.max_loudness);
    for (int i = 0; i < TRACK.sections.length; i++)
    {
        var s = TRACK.sections[i];
        fill(PITCH_COLORS[s.key]);
        beginShape();
        vertex(curr, SCRUBBER.bottom());
        
        float w = 0;
        float h = 0;
        for (int j = start_point; j < TRACK.segments.length; j++)
        {
            Segment current = TRACK.segments[j];
            h = map(loudness_factor(current.loudness), min_loudness, max_loudness, SCRUBBER.height/5, SCRUBBER.height);
            vertex(curr, SCRUBBER.bottom() - h); 
            
            float frac = current.duration / TRACK.duration;
            w = frac * SCRUBBER.width;
            
            if (s.contains(current))
            {
                curr += w;
            }
            else
            {
                start_point = j+1;
                break;
            }
        }
        vertex(curr, SCRUBBER.bottom());
        endShape(CLOSE);
        
        // Fill in the section boundary.
        if (curr + w < SCRUBBER.right())
        {
            if (window.segment && current.start == window.segment.start)
            {
                fill(255, 255); // go a little crazy when we hit the section boundary.
                rect(curr, BORDER + (SCRUBBER.height - h), w, h);
            }
            else
            {
                fill(PITCH_COLORS[s.key], 128);
                rect(curr, BORDER + (SCRUBBER.height - h), w, h);
            }
        }
        curr += w;
    }
    popStyle();
}

TrackInfo.prototype.paint = function(width, height)
{
    pushStyle();
    
    fill(255);
    
    drawSections();
    drawChromagram();
    
    popStyle();
};


Segment.prototype.timbre_color = function()
{
    // first timbral coeff is just loudness or something, right?
    r = map(this.timbre[1], this._track.timbreMin[1], this._track.timbreMax[1], 0, 255);
    g = map(this.timbre[2], this._track.timbreMin[2], this._track.timbreMax[2], 0, 255);
    b = map(this.timbre[3], this._track.timbreMin[3], this._track.timbreMax[3], 0, 255);
    return color(r, g, b, 224);
};

Segment.prototype.paint = function()
{
    pushStyle();
    // ERASE BACKGROUND
    CHROMA_BAR.paint(0, 255);
    CHROMA_LABELS.paint(0, 255);
    CENTRAL_SQUARE.paint(0, 255);
    TIMBRE_BALLS.paint(0, 255);
    
    // CHROMA:
    var top = CHROMA_BAR.bottom() - BORDER - SQ_HEIGHT; 
    stroke(255, 255, 255, 128);
    strokeWeight(BORDER / 10);
    
    var pmin = min(this.pitches);
    var pmax = max(this.pitches);
    var pwidth = pmax - pmin;
    if (pwidth < .001)
        pwidth = .1; // avoid dividing by 0
    
    textAlign(CENTER, CENTER);
    int k = this._track.key;
    for (int i = 0; i < this.pitches.length; i++)
    {
        var p = (this.pitches[k] - pmin) / pwidth;
        stroke(PITCH_COLORS[k], 255);
        fill(PITCH_COLORS[k], p * 255);//fill(p * 255, p * 255);
        rect(BORDER, top, SQ_HEIGHT, SQ_HEIGHT);
        
        fill(255, 255);
        if (this._track.mode == "minor")
            text(PITCH_NAMES[k].toLowerCase(), CHROMA_LABELS.left, top + SQ_HEIGHT/2);
        else
            text(PITCH_NAMES[k], CHROMA_LABELS.left, top + SQ_HEIGHT/2);
        
        top -= SQ_HEIGHT + BORDER;
        k = (k + 1) % 12;
    }
    popStyle();
    
    pushStyle();
    // CENTRAL ELLIPSE: loudness, colored by timbre. 
    noFill();
    stroke(this.timbre_color()); 
    strokeWeight(5 + 3*(this.dbMax - this.dbStart)); // in px
    
    ellipseMode(CENTER);
    var lx = CENTRAL_SQUARE.left + CENTRAL_SQUARE.width / 2;
    var ly = CENTRAL_SQUARE.top + CENTRAL_SQUARE.height / 2;
    ellipse(lx, ly, this.dbmf*CENTRAL_SQUARE.width, this.dbsf*CENTRAL_SQUARE.height);
    popStyle();
    
    pushStyle();
    // TIMBRE BALLS: convert timbre (12 dims) to 4 rgb triplets.
    ellipseMode(CORNER);
    noStroke();
    var tleft = TIMBRE_BALLS.left + BORDER/2;
    var twidth = TIMBRE_BALLS.height + BORDER/2;
    for (int i = 0; i < this.timbre.length / 3; i++)
    {
        r = map(this.timbre[3*i+0], this._track.timbreMin[i+0], this._track.timbreMax[i+0], 0, 255);
        g = map(this.timbre[3*i+1], this._track.timbreMin[i+1], this._track.timbreMax[i+1], 0, 255);
        b = map(this.timbre[3*i+2], this._track.timbreMin[i+2], this._track.timbreMax[i+2], 0, 255);
        fill(color(r, g, b, 196));
        ellipse(tleft + i * twidth, TIMBRE_BALLS.top, TIMBRE_BALLS.height, TIMBRE_BALLS.height);
    }
    popStyle();
};
