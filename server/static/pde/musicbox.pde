// modelled after Anita Lillie's music box visualizer.
//      http://flyingpudding.com/projects/viz_music/#video
// AUTHOR: <a href="http://twitter.com/jsundram">Jason Sundram</a>

/*BEGIN_DOCSTRING 

<p>
<b>Musicbox</b> is based on Anita Lillie's <a href="http://flyingpudding.com/projects/viz_music/#video">Visualizing Music project</a>. 
It shows 12 boxes for each segment, corresponding to each of the 12 chroma buckets. The boxes are colored by timbre, and brightened by loudness. The length of each box corresponds to the segment length.
</p>
END_DOCSTRING*/
void setup()
{
    size(get_max_canvas_width(), get_max_canvas_height());
    background(0);
    frameRate(30); // default is 60. If the average track is 120bpm, that's 2 bps, so this is good for a segment rate of up to 15 segments/beat.
}

var track = null;
// WINDOW is number of seconds of audio that will be represented on the screen.
// TODO: consider adjusting dynamically to represent the average segment as a square or something like that?
var WINDOW = 15; 

void draw()
{
    resize(this, get_max_canvas_width(), get_max_canvas_height(), 0);
    
    bounds = new Rect(30, 0, width, height);
    // Global
    if (window.current_track && window.current_track != track )
        track = window.current_track;
    
    if (track)
        drawChromagram(bounds);
    
    // draw center line
    pushStyle();
    stroke(255);
    strokeWeight(7);
    var middle = (bounds.left + bounds.width) / 2;
    line(middle, bounds.top, middle, bounds.top + bounds.height);
    popStyle();
    
    if (track)
        drawPitchLabels(bounds);
}

void drawPitchLabels(bounds)
{
    pushStyle();
    textAlign(CENTER, CENTER);
    fill(255, 255);
    int k = track.key;
    float pitch_height = bounds.height / 12;
    float top = bounds.height - (pitch_height / 2);
    for (int i = 0; i < 12; i++)
    {
        if (track.mode == "minor")
            text(PITCH_NAMES[k].toLowerCase(), 0, top);
        else
            text(PITCH_NAMES[k], 0, top);
        
        top -= pitch_height;
        k = (k + 1) % 12;
    }
    popStyle();
}
void drawChromagram(boundingRect)
{
    pushStyle();
    var current_index = get_index(track.segments, window.timestamp);
    var begin_index   = get_index(track.segments, window.timestamp - WINDOW/2);
    var end_index     = get_index(track.segments, window.timestamp + WINDOW/2);
    if (begin_index == -1 && current_index != 0)
        begin_index = 0;
    
    if (track.duration < window.timestamp + WINDOW/2)
        end_index = track.segments.length - 1;
    
    var mid = (boundingRect.left + boundingRect.width) / 2;
    mid -= (window.timestamp - track.segments[current_index].start) * boundingRect.width / WINDOW;
    var left = mid; 
    float h = boundingRect.height / 12;
    
    // second half    
    for (int j = current_index; j < end_index; j++)
    {
        Segment current = track.segments[j];
        
        var w = (boundingRect.width * current.duration) / WINDOW;
        drawSegment(current, new Rect(left, boundingRect.top, w, h), j == current_index);
        left += w;
    }

    // first half
    if (begin_index != -1)
    {
        left = mid;
        for (int j = current_index-1; j >= begin_index; j--)
        {
            Segment current = track.segments[j];
            var w = (boundingRect.width * current.duration) / WINDOW;
            left -= w;
            drawSegment(current, new Rect(left, boundingRect.top, w, h), false);
        }
    }
    popStyle();
}

void drawSegment(seg, segBound, highlight)
{
    pushStyle();
    int k = (track.key + 11) % 12;
    
    // subtract off the min and divide by the width to fill [0, 1]
    pitches = seg.pitches.slice();
    var pmin = min(pitches);
    var pmax = max(pitches);
    var pwidth = pmax - pmin;
    if (pwidth < .001)
        pwidth = .1; // avoid dividing by 0
    
    // brighten/dim if stuff is loud.
    loudness_bias = map(loudness_factor(seg.loudness), loudness_factor(track.min_loudness), loudness_factor(track.max_loudness), .1, 2);
    strokeWeight(highlight ? 2 : 1);
    for (int c = 0; c < 12; c++)
    {
        r = map(seg.timbre[1], track.timbreMin[1], track.timbreMax[1], 0, 255);
        g = map(seg.timbre[2], track.timbreMin[2], track.timbreMax[2], 0, 255);
        b = map(seg.timbre[3], track.timbreMin[3], track.timbreMax[3], 0, 255);
        
        float chroma = loudness_bias * (seg.pitches[k] - pmin) / pwidth; // now in range 0, 2
        
        if (highlight)
        {
            noFill();
            stroke(r, g, b, chroma*127);
        }    
        else
        {
            fill(r, g, b, chroma * 127);
            stroke(0, 0);
        }
        rect(segBound.left, segBound.top + c * segBound.height, segBound.width, segBound.height);
        
        k = ((k - 1) + 12) % 12;
    }
    popStyle();
}

