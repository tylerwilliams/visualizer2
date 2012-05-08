// based on TJ's matlab plots.
// TODO: zoom stacking?

// AUTHOR: <a href="http://twitter.com/jsundram">Jason Sundram</a>

/*BEGIN_DOCSTRING 

The <b>diagnostic</b> visualizer was used by The Echo Nest audio team while developing <a href="http://developer.echonest.com/news/2009/10/analysis-version-3-now-default/">the new analyzer</a>.
<p><br>
<p>
It shows (from top to bottom):
<ol>
<li>Timbre, colored by mapping dimensions 2-4 into the RGB color space.</li>
<li>Pitch, colored by the wavelength of light corresponding to the frequency of each pitch (e.g. A = 440).</li>
<li>Loudness. Thickness represents the difference between the start and max loudness for each segment.</li>
<li>Meter.  Blue dots are bars, Red dots are beats, and white dots are tatums. The curves represent the corresponding confidences.</li>
</ol>
</p>
<p>
<br>
Special Features:
<ol>
<li>Zoom. Drag to select a section to zoom in on. Press Escape to zoom out.</li>
<li>Scrub. Click anyplace on the visualizer to hear the music at that point.</li>
</ol>
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
}

Rect.prototype.draw = function(fill_color, fill_alpha)
{
    pushStyle();
    fill(fill_color, fill_alpha);
    rect(this.left, this.top, this.width, this.height);//pjs function
    popStyle();
}

// copied from shitty.pjs. gotta share code better.
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


var TRACK = null;
var TRACK_START;
var TRACK_END;
// global variables used only in draw() aren't all caps.
var track_changed = false;

var curr_height;
var curr_width;
var resized = false;
var all;
var old_scrub = null;

var startX = null;
var startY = null;

// Zoom and Seek
void keyPressed()
{
    if (TRACK && key == ESC)
    {
        //console.log('got ESC');
        if (TRACK_START != 0 || TRACK_END != TRACK.duration)
        {
            TRACK_START = 0;
            TRACK_END = TRACK.duration;
            resized = true;
        }
    }
}
void mousePressed()
{
    //console.log('Press', mouseX, mouseY);
    startX = mouseX;
    startY = mouseY;
}
DRAGGED = false;

int offset_to_seconds(x_offset)
{
    return map(x_offset, 0, width, TRACK_START, TRACK_END);
}

void drawDragRect(erase)
{
    if (!DRAGGED)
        return;
    pushStyle();
    if (erase)
        image(all, 0, 0);
    fill(255, 96);
    rectMode(CORNERS);
    rect(startX, 0, mouseX, height);
    s = offset_to_seconds(startX);
    e = offset_to_seconds(mouseX);
    text(formatTime(s), startX + 8, 10);
    text(formatTime(e), mouseX + 8, 10);
    popStyle();
}

void mouseDragged()
{
    DRAGGED = true;
    drawDragRect(true);
}

void mouseReleased()
{
    //console.log('Release', mouseX, mouseY);
    if (DRAGGED)
    {
        // console.log('Dragged from', startX, startY, ' to ', mouseX, mouseY);
        x1 = min(mouseX, startX);
        x2 = max(mouseX, startX);
        new_start = offset_to_seconds(x1);
        new_end   = offset_to_seconds(x2);
        //console.log(new_start, new_end);
        if ( 1 < new_end - new_start)
        {
            TRACK_START = new_start;
            TRACK_END = new_end;
            resized = true;
        }
        else
            image(all, 0, 0);
    }
    DRAGGED = false;
    startX = null;
    startY = null;
}
void mouseClicked()
{
    // console.log('Click', mouseX, mouseY);
    if (window.current_track)
    {
        // Since we're drawing from L to R with no border, math is simple.
        var seek = offset_to_seconds(mouseX);
        $("#jquery_jplayer").jPlayer( "playHeadTime", seek * 1000); // player wants ms.
    }
}

void draw()
{
    if (curr_height != get_max_canvas_height() || curr_width != get_max_canvas_width())
    {
        curr_height = get_max_canvas_height();
        curr_width = get_max_canvas_width();
        resized = true;
        resize(this, curr_width, curr_height, 0);
    }
    
    if (window.current_track)
    {
        track_changed = (TRACK != window.current_track);
        if (track_changed)
        {
            TRACK = window.current_track;
            TRACK_START = 0;
            TRACK_END = TRACK.duration;
        }
        
        if (track_changed || resized)
        {
            background(0);
            scrubber_height = 10;
            // *3 because of meta, scrubber, and space between timbre and pitch
            var h = (height - scrubber_height * 3) / 4;
            
            meta = new Rect(0, 0, width, scrubber_height);
            drawTrackLevel(TRACK, meta);
            
            scrubber = new Rect(0, meta.bottom(), width, scrubber_height);
                        
            timbre = new Rect(0, scrubber.bottom(), width, h);
            drawTimbre(TRACK, timbre);
            
            pitch = new Rect(0, timbre.bottom() + scrubber_height, width, h);
            drawPitch(TRACK, pitch);
            
            loudness = new Rect(0, pitch.bottom(), width, h);
            drawLoudness(TRACK, loudness);
            
            meter = new Rect(0, loudness.bottom(), width, h);
            drawMeter(TRACK, meter);
            
            all = get();
        }    
        
        drawScrubber(TRACK, scrubber);
    }
    
    resized = false; // after we've made it through a draw loop, we've resized.
}

void drawTrackLevel(t, r)
{
    pushStyle();
    fill(255);
    // TODO: add more confidences.
    textFont("Arial", 10);
    text(nf(t.bpm, 3, 1) + " bpm in " + nf(t.meter, 1) + "/4.", r.right()-160, r.bottom());
    text(PITCH_NAMES[t.key] + "  "  + t.mode + " (" + nf(t.mode_confidence, 1, 2) + ")", r.right() - 80, r.bottom());
    popStyle();
}

void drawScrubber(t, r)
{
    pushStyle();
    
    if (window.timestamp < TRACK_START || TRACK_END < window.timestamp)
    {
        r.draw(0, 255); // blank us out
        return;
    }
    
    var x = map(window.timestamp, TRACK_START, TRACK_END, r.left, r.right());
    if (x != old_scrub)
    {
        m = millis();
        old_scrub = x;
        
        image(all, 0, 0);
        // set(0, 0, all); // fast, but doesn't work ...
        /*
        pg = createGraphics(4, height);
        pg.beginDraw();
        pg.background(0, 0);
        pg.fill(204, 102, 0, 95);
        pg.rect(0, r.top, 4, height); // 4 => knob width
        pg.endDraw();
        image(pg, x, 0);
        */
        drawDragRect(false);
        
        fill(204, 102, 0, 95);
        rect(x, r.top, 4, height); // 4 => knob width
        
        stroke(255);
        fill(255);
        textFont("Arial", 10);
        text(formatTime(window.timestamp) + " / " + formatTime(t.duration), x + 8, r.bottom());
        
        //r.draw(0, 255); // blank us out. Could just erase previous?
        // fill(PITCH_COLORS[(t.key + 7) % 12], 255);
        // rect(x, r.top, 4, r.height); // 4 => knob width
        // console.log('took ', millis() - m, ' ms to update screen');
    }
    // else console.log('skipping scrubber update');
    
    popStyle();
    
    // TODO: might be nice to have the offset displayed, too?
}

void drawTimbre(t, r)
{
    pushStyle();
    var curr = r.left;
    float w = 0;
    int h = r.height / 12;
    
    for (int i = 0; i < t.segments.length; i++)
    {
        Segment current = t.segments[i];
        if (current.start < TRACK_START || TRACK_END < current.end())
            continue;
        float w = r.width * current.duration / (TRACK_END - TRACK_START);
        
        R = map(current.timbre[1], t.timbreMin[1], t.timbreMax[1], 0, 255);
        G = map(current.timbre[2], t.timbreMin[2], t.timbreMax[2], 0, 255);
        B = map(current.timbre[3], t.timbreMin[3], t.timbreMax[3], 0, 255);
        
        for (int j = 0; j < 12; j++)
        {
            float timbre = map(current.timbre[j], t.timbreMin[j], t.timbreMax[j], 0, 255);
            fill(R, G, B, timbre);
            rect(curr, r.top + j*h, w, h);
        }
        
        curr += w;
    }
    popStyle();
}

color[] PITCH_COLORS = new Array(#2fff00, #a0ff00, #ffe300, #ff5a00, #ff0000, #ff0000, #a70000, #6200b5, #4300f2, #0000ff, #0084ff, #00ffd8);
void drawPitch(t, r)
{
    pushStyle();
    var curr = r.left;
    float w = 0;
    int h = r.height / 12;
    
    for (int i = 0; i < t.segments.length; i++)
    {
        Segment current = t.segments[i];
        if (current.start < TRACK_START || TRACK_END < current.end())
            continue;
        float w = r.width * current.duration / (TRACK_END - TRACK_START);
        
        var pmin = min(current.pitches);
        var pwidth = max(current.pitches) - pmin;
        if (pwidth < .001)
            pwidth = .1; // avoid dividing by 0
        
        int k = (t.key + 11) % 12;
        for (int c = 0; c < 12; c++)
        {
            float chroma = (current.pitches[k] - pmin) / pwidth; // now in range 0, 1
            fill(PITCH_COLORS[k], chroma * 255);
            rect(curr, r.bottom() - (c+1)*h, w, h);
            
            k = ((k - 1) + 12) % 12;
        }
        
        curr += w;
    }
    popStyle();
}

void plot(l, r, x_min, x_max, f)
{
    pushStyle();
    fill(f); 
    y_max = 1; // calculating this scales everything together, which is not what we want.
    
    for (int i = 0; i < l.length; i++)
    {
        m = l[i];
        if (m.start < x_min || x_max < m.end())
            continue;
        
        s = m.start;
        d = m.duration / 4; // Perhaps you are wondering about the /4. Me too.
        c = m.confidence;
        
        pt_x = map(s, x_min, x_max, r.left, r.right());
        pt_y = map(d, 0, y_max, r.bottom(), r.top); 
        pt_c = map(c, 0, 1, r.bottom(), r.top); 
        
        rect(pt_x, pt_y, 4, 4); // place a marker
        
        if (i != 0)
        {
            stroke(f, 94);
            line(last_x, last_c, pt_x, pt_c);
        }
        last_x = pt_x;
        last_c = pt_c;
    }
    
    popStyle();
}

void drawMeter(t, r)
{
    if (true)
        plot(t.tatums, r, TRACK_START, TRACK_END, color(255));
    if (true)
        plot(t.beats, r, TRACK_START, TRACK_END, color(255, 0, 0));
    if (t.meter != 1) // if track.meter == 1, bars == beats.
        plot(t.bars, r, TRACK_START, TRACK_END, color(0, 0, 255));
    
    pushStyle();
    fill(128, 94); 
    for (int i = 0; i < t.sections.length; i++)
    {
        m = t.sections[i];
        
        if (m.start < TRACK_START || TRACK_END < m.start)
            continue;
        
        var pt_x = map(m.start, TRACK_START, TRACK_END, r.left, r.right());
        var thickness = map(m.confidence, 0, 1, 2, 8);
        
        rect(pt_x - thickness / 2, r.top, thickness, r.height);
    }
    
    popStyle();
}

// params: t (track), r (bounding rect)
void drawLoudness(t, r)
{
    pushStyle();
    fill(204, 102, 0, 255); // orange
    // draw loudness
    beginShape();
    int min_loudness = -60;
    int max_loudness = 0; // T had 20; do we really need that?
    // max_loudness
    for (int i = 0; i < t.segments.length; i++)
    {
        seg = t.segments[i];
        if (seg.start < TRACK_START || TRACK_END < seg.end())
            continue;
        
        x = seg.start + seg.start_max;
        y = seg.dbMax;
        
        pt_x = map(x, TRACK_START, TRACK_END, r.left, r.right());
        pt_y = map(y, min_loudness, max_loudness, r.bottom(), r.top);
        vertex(pt_x, pt_y);
        
        // timbre = seg.timbre[0] - 60; // plot this at x_max?
    }
    // deal with loudness_end
    if (t.segments[i-1].loudness_end <= TRACK_END)
    {
        pt_x = r.right();
        pt_y = map(t.segments[i-1].loudness_end, min_loudness, max_loudness, r.bottom(), r.top);
        vertex(pt_x, pt_y);
    }
    // loudness_start
    for (int i = t.segments.length-1; i >= 0; i--)
    {
        seg = t.segments[i];
        if (seg.start < TRACK_START || TRACK_END < seg.end())
            continue;
        
        x = seg.start;
        y = seg.dbStart;
        
        pt_x = map(x, TRACK_START, TRACK_END, r.left, r.right());
        pt_y = map(y, min_loudness, max_loudness, r.bottom(), r.top);
        vertex(pt_x, pt_y);
    }
    endShape(CLOSE);
    
    // timbre0? Plot gets kind of busy with this on it.
    fill(0, 0, 0);
    for (int i = 0; i < t.segments.length; i++)
    {
        seg = t.segments[i];
        if (seg.start < TRACK_START || TRACK_END < seg.end())
            continue;
        
        x = seg.start + seg.start_max;
        y = seg.timbre[0] - 60; // plot this at x_max?
        
        pt_x = map(x, TRACK_START, TRACK_END, r.left, r.right());
        pt_y = map(y, min_loudness, max_loudness, r.bottom(), r.top);
        //rect(pt_x, pt_y, 1, 1);
    }
    
    stroke(255);
    loud = map(t.overall_loudness, min_loudness, max_loudness, r.bottom(), r.top);
    fin = r.left;
    if (TRACK_START < t.end_of_fade_in && t.end_of_fade_in < TRACK_END)
        fin = map(t.end_of_fade_in, TRACK_START, TRACK_END, r.left, r.right());
    
    fout = r.right();
    if (TRACK_START < t.start_of_fade_out && t.start_of_fade_out < TRACK_END)
        fout = map(t.start_of_fade_out, TRACK_START, TRACK_END, r.left, r.right());
    
    line(fin, loud, fout, loud);        // loudness
    line(fin, r.bottom(), fin, loud);   // fadein
    line(fout, r.bottom(), fout, loud); // fadeou
    
    fill(255);
    
    textFont("Arial", 12);
    text("loudness = " + nf(t.overall_loudness, 2, 1) + "dB", r.left + 10, loud - 10);
    popStyle();
}