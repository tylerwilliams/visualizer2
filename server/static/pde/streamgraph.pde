// Lee Byron and Martin Wattenberg's StreamGraph, used to show chroma.
//TODO: Zoom? Bug with Settings?
// AUTHOR: <a href="http://twitter.com/jsundram">Jason Sundram</a>

/*BEGIN_DOCSTRING 

<p>
<b>Streamgraph</b> uses <a href="http://runningwithdata.tumblr.com/post/566345323/streamgraph-js">Streamgraph.js</a> to present pitch data throughout the song. 
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

var SETTINGS = []; 
var ALL_SETTINGS = {};
var SETTINGS_RECTS = [];
var LastFmColors = null;
void setup()
{
    size(get_max_canvas_width(), get_max_canvas_height());
    background(0);
    frameRate(30);
    smooth(); // this doesn't do anything in processing v0.6, but it will in v0.8.
    SETTINGS["Sort"] = "LateOnset";
    SETTINGS["Layout"] = "Stream";
    SETTINGS["ColorPicker"] = "NiceRandom";
    SETTINGS["Curve"] = "Curved";
    SETTINGS.start = 0;
    SETTINGS.end = -1;
    SETTINGS.data_length = -1;
    
    
    ALL_SETTINGS["Sort"] = ["None", "LateOnset", "Volatility", "InverseVolatility"];
    ALL_SETTINGS["Layout"] = ["MinimizedWiggle", "Stack", "Stream", "ThemeRiver"];
    ALL_SETTINGS["ColorPicker"] = ["LastFm", "NiceRandom", "Pitch", "Random"];
    ALL_SETTINGS["Curve"] = ["Curved", "Jagged"]; // hack isGraphCurved into the settings.
    
    
    LastFmColors = loadImage('layers', 'jpg');
}

var TRACK = null;
var TRACK_START;
var TRACK_END;
var OLD_SCRUB = null;
// global variables used only in draw() aren't all caps.
var track_changed = false;

var curr_height;
var curr_width;
var resized = false;
var all;


function get_setting(name)
{
    value = SETTINGS[name];
    f = value + name;
    return eval(f);
}

function is_current(name, value)
{
    return SETTINGS[name] == value;
}

var SETTINGS_RECT = null;
                    
int offset_to_seconds(x_offset)
{
    return TRACK_START + (x_offset / width) * (TRACK_END - TRACK_START);
}

void mouseClicked()
{
    // console.log('Click', mouseX, mouseY);
    if (SETTINGS_RECT && SETTINGS_RECT.contains(mouseX, mouseY))
    {
        // check all the settings to see which one got the click
        for (k in ALL_SETTINGS)
        {
            if (!ALL_SETTINGS.hasOwnProperty(k))
                continue;
            
            for (var i = 0; i < ALL_SETTINGS[k].length; i++)
            {
                if (SETTINGS_RECTS[k][ALL_SETTINGS[k][i]].contains(mouseX, mouseY))
                {
                    // console.log("Changed settings", k, SETTINGS[k], ' to ', ALL_SETTINGS[k][i]);
                    SETTINGS[k] = ALL_SETTINGS[k][i];
                    resized = true;
                    break;
                }
            }
        }
    }
    else if (window.current_track)
    {
        // Since we're drawing from L to R with no border, math is simple.
        var seek = offset_to_seconds(mouseX);
        $("#jquery_jplayer").jPlayer( "playHeadTime", seek * 1000); // player wants ms.
    }
}

function CurvedCurve() { return true;}
function JaggedCurve() { return false;}


function PitchColorPicker(layers)
{
    pushStyle();
    colorMode(RGB, 255);
    // Rainbow. This is way too much color.
    color[] PITCH_COLORS = new Array(#2fff00, #a0ff00, #ffe300, #ff5a00, #ff0000, #ff0000, #a70000, #6200b5, #4300f2, #0000ff, #0084ff, #00ffd8);
    var color_map = {};
    for (var i = 0; i < PITCH_COLORS.length; i++)
        color_map[PITCH_NAMES[i]] = PITCH_COLORS[i];
    
    for (var i = 0; i < layers.length; i++)
    {
        color c = color_map[layers[i].name];
        layers[i].rgb = [red(c), green(c), blue(c)];
    }
    popStyle();
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
        
        var legend_bottom = 20;
        drawZoom(legend_bottom);
        
        if (track_changed || resized)
        {
            var settings_top = height - 20; 
            SETTINGS_RECT = new Rect(0, settings_top, width, 20);
            
            // draw streamgraph
            var pitches = [];
            for (var i = 0; i < TRACK.segments.length; i++)
            {
                pitches[i] = [];
                for (var j = 0; j < TRACK.segments[i].pitches.length; j++)
                    pitches[i][j] = TRACK.segments[i].pitches[j];
            }
            
            pitch_data = new DataSource(pitches, PITCH_NAMES);
            layers = pitch_data.make(PITCH_NAMES.length, TRACK.segments.length);
            if (SETTINGS.end == -1)
            {
                SETTINGS.end = pitches.length;
                SETTINGS.data_length = pitches.length;
            }
            
            layer_sort = get_setting('Sort');
            layers = layer_sort(layers);
            layer_layout = get_setting('Layout');
            layer_layout(layers);
            color_picker = get_setting('ColorPicker');
            color_picker(layers, LastFmColors); // TODO: Not great to pass LastFmColors all the time.
            curve = get_setting('Curve');
            
            // Just because we have all this space, doesn't mean we should use it all.
            // The graphs tend to look better when they are wider than they are long.
            var h = width / 4;
            if (settings_top - legend_bottom < h)
                h = settings_top - legend_bottom;
            var space = ((settings_top - legend_bottom) - h) / 2;
            scaleLayers(layers, legend_bottom + space, settings_top - space);
            drawLayers(layers, curve());
            drawLegend(new Rect(0, 0, width, legend_bottom), layers);
            
            drawSettings(SETTINGS_RECT);
            // save buffer -- would like to do this asynchronously
            all = get();
            legend_bottom += 10; // zoom rect
            scrubber = new Rect(0, legend_bottom, width, settings_top - legend_bottom);
        }
        
        drawScrubber(TRACK, scrubber);
        
    }
    
    resized = false; // after we've made it through a draw loop, we've resized.
}

void drawZoom(int top)
{
    var s, w;
    if (startX)
    {
        s = min(startX, mouseX);
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

void drawSettings(r)
{
    var left = r.left;
    var num_types = 0;
    var total = 0;
    for (k in ALL_SETTINGS)
    {
        if (!ALL_SETTINGS.hasOwnProperty(k))
            continue;
        total += ALL_SETTINGS[k].length;
        num_types += 1;
    }
    
    var w = (r.width - 10 * (num_types - 1)) / total;
    var th = r.height * .75;
    var tb = r.bottom() - th;
    
    pushStyle();
    textFont("Arial", th);
    
    for (k in ALL_SETTINGS)
    {
        if (!ALL_SETTINGS.hasOwnProperty(k))
            continue;
        
        pushStyle();
        noFill();
        stroke(128);
        strokeWeight(1);
        rect(left, r.top, w * ALL_SETTINGS[k].length, r.height);
        popStyle();
        
        SETTINGS_RECTS[k] = [];
        for (var i = 0; i < ALL_SETTINGS[k].length; i++)
        {   
            if (is_current(k, ALL_SETTINGS[k][i]))
                fill(255);
            else
                fill(128);
            text(ALL_SETTINGS[k][i], left, tb, w, th);
            
            SETTINGS_RECTS[k][ALL_SETTINGS[k][i]] = new Rect(left, r.top, w, r.height);
            left += w;
        }
        left += 10;
    }
    popStyle();
}

color get_color(layer)
{
    if (layer.hasOwnProperty('hsb'))
        return layer.hsb
    
    // assume some variety of rgb
    if (typeof(layer.rgb) == 'number')
        return [red(layer.rgb), green(layer.rgb), blue(layer.rgb)];
    
    if (4 < layer.rgb.length) // rgba (image.pixels returns this)
    {
        c = rgbaToInt(layer.rgb);
        return [red(c), green(c), blue(c)];
    }
    
    return layer.rgb;
}
void drawLegend(Rect r, Layers[] layers)
{
    pushStyle();

    var left = r.left;
    var w = r.width / layers.length;
    var rw = .3 * w; // rect
    var tw = .6 * w; // text
    var sw = w - rw - tw; // space
    textFont("Arial", r.height);
    
    for (var i = 0; i < layers.length; i++)
    {
        var layer = layers[i];
        // set fill color of layer
        c = get_color(layer); // color triplet [r, g, b] or  [h, s, b]
        if (layer.hasOwnProperty('hsb'))
            colorMode(HSB, 1.0);
        else 
            colorMode(RGB, 255);
        
        fill(c[0], c[1], c[2]);
        
        rect(left, r.top, rw, r.height);
        left += rw + sw;
        
        text(layer.name, left, r.top, tw, r.height);
        left += tw;
    }
    popStyle();
}

void drawLayers(Layers[] layers, boolean isGraphCurved)
{
    int n = layers.length;
    int start;
    int end;
    int lastIndex = SETTINGS.end - 1;
    int lastLayer = n - 1;
    int pxl;
    
    background(0);
    pushStyle();
    noStroke();
    
    // Generate graph.
    for (int i = 0; i < n; i++) 
    {
        layer = layers[i];
        start = max(SETTINGS.start, layer.onset - 1);
        end   = min(lastIndex, layer.end);
        pxl   = i == lastLayer ? 0 : 1;
        
        // Set fill color of layer
        c = get_color(layer); // color triplet [r, g, b] or  [h, s, b]
        if (layer.hasOwnProperty('hsb'))
            colorMode(HSB, 1.0);
        else 
            colorMode(RGB, 255);
        
        fill(c[0], c[1], c[2]);
        
        // Draw shape
        beginShape();
        
        // Draw top edge, left to right
        graphVertex(start, layer.yTop, isGraphCurved, i == lastLayer);
        for (int j = start; j <= end; j++)
            graphVertex(j, layer.yTop, isGraphCurved, i == lastLayer);
        
        graphVertex(end, layer.yTop, isGraphCurved, i == lastLayer);
        
        // Draw bottom edge, right to left
        graphVertex(end, layer.yBottom, isGraphCurved, false);
        for (int j = end; j >= start; j--)
            graphVertex(j, layer.yBottom, isGraphCurved, false);
        
        graphVertex(start, layer.yBottom, isGraphCurved, false);
        
        endShape(CLOSE);
    }
    
    popStyle();
}

void graphVertex(int point, float[] source, boolean curve, boolean pxl)
{
    float x = map(point, SETTINGS.start, SETTINGS.end-1, 0, width);
    float y = source[point] - (pxl ? 1 : 0);
    if (curve)
        curveVertex(x, y);
    else
        vertex(x, y);
}

void scaleLayers(Layer[] layers, int screenTop, int screenBottom) 
{
    // Figure out max and min values of layers.
    float lmin = layers[0].yTop[0];
    float lmax = layers[0].yBottom[0];
    for (int i = SETTINGS.start; i < SETTINGS.end; i++)
    {
        for (int j = 0; j < layers.length; j++)
        {
            lmin = min(lmin, layers[j].yTop[i]);
            lmax = max(lmax, layers[j].yBottom[i]);
        }
    }
    
    float scale = (screenBottom - screenTop) / (lmax - lmin);
    for (int i = SETTINGS.start; i < SETTINGS.end; i++) 
    {
        for (int j = 0; j < layers.length; j++) 
        {
            layers[j].yTop[i] = map(layers[j].yTop[i], lmin, lmax, screenTop, screenBottom);
            layers[j].yBottom[i] = map(layers[j].yBottom[i], lmin, lmax, screenTop, screenBottom);
        }
    }
}

/* NOT GENERIC*/
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


void drawScrubber(t, r)
{
    pushStyle();
    
    if (window.timestamp < TRACK_START || TRACK_END < window.timestamp)
        return;
    frac = (window.timestamp - TRACK_START) / (TRACK_END - TRACK_START);
    
    float x = r.left + frac * r.width;
    if (x != OLD_SCRUB)
    {
        OLD_SCRUB = x;
        
        image(all, 0, 0);
        // drawDragRect(false);
        
        fill(204, 102, 0, 95); // orangey
        rect(x, r.top, 4, r.height); // 4 => knob width
        
        stroke(255);
        fill(255);
        textFont("Arial", 10);
        text(formatTime(window.timestamp) + " / " + formatTime(t.duration), x + 8, r.bottom());
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
        SETTINGS.start = 0;
        SETTINGS.end = -1;
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
        var x1 = min(mouseX, startX);
        var x2 = max(mouseX, startX);
        
        // Figure out where to zoom.
        var s = Math.floor(SETTINGS.start + (x1 / width) * (SETTINGS.end - SETTINGS.start));
        var e = Math.ceil(SETTINGS.start + (x2 / width) * (SETTINGS.end - SETTINGS.start));
        if (3 < e - s)
        {
            SETTINGS.start = s; 
            SETTINGS.end = e;
            TRACK_START = TRACK.duration * (SETTINGS.start / SETTINGS.data_length);
            TRACK_END = TRACK.duration * (SETTINGS.end / SETTINGS.data_length);
            resized = true;
        }
        // there's a point beyond which we will not zoom. 
    }
    DRAGGED = false;
    startX = null;
}