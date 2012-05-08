// TODO: mouseovers.
// AUTHOR: <a href="http://twitter.com/jsundram">Jason Sundram</a>

/*BEGIN_DOCSTRING 

<p>
<b>BPM Explorer</b> is based on Paul Lamere's <a href="http://static.echonest.com/bpmexp/bpmexp.html">Echo Nest BPM Explorer</a>. It shows a click plot that shows the deviations in tempo from the average over the course of a song. 
The white line shows the instantaneous bpm, while the green line shows the moving average.
</p>
END_DOCSTRING*/

void setup()
{
    size(get_max_canvas_width(), get_max_canvas_height());
    background(0);
    frameRate(30); // default is 60. If the average track is 120bpm, that's 2 bps, so this is good for a segment rate of up to 15 segments/beat.
}

void mouseClicked()
{
    if (window.current_track)
    {
        var seek = (mouseX / width) * window.current_track.duration;
        if (seek)
            $("#jquery_jplayer").jPlayer( "playHeadTime", seek * 1000); // player wants ms.
    }
}

void mouseMoved() 
{
    // Some kind of hover deal here?
}


float mapX(float x, int width) 
{
    return map(x, 0, window.current_track.duration, 0, width);
}

float minbpm, maxbpm;
float scale = .05;
var TRACK = null;
var curr_height;
var curr_width;
var resized = false;
var all;
var position = 0;
var curr_beat;

float mapY(float y, int height) 
{
    // canvas is upside down.
    return map(y, minbpm * (1-scale), maxbpm * (1+scale), height, 0);
}

void filter(Event[] beats, int which, int size) 
{
     float sum = 0;
     int count = 0;
     for (int i = which - size; i < which + size; i++) 
     {
         if (0 <= i  && i < beats.length - 1) // TODO, why not go all the way to the end? 
         {
             sum += beats[i].bpm;
             count++;
         }
     }
     beats[which].filteredBpm = sum / count;
}

void draw()
{
    if (curr_height != get_max_canvas_height() || curr_width != get_max_canvas_width())
    {
        curr_height = get_max_canvas_height();
        curr_width = get_max_canvas_width();
        resized = true;
        // This size call causes the background to redraw().
        resize(this, curr_width, curr_height, 0);
    }
    
    // No track, no draw.
    if (window.current_track === undefined)
        return;
        
    if (window.current_track != TRACK || resized)
    {
        TRACK = window.current_track;
        
        // beat track
        float tempo = window.current_track.bpm;
        float lastX = mapX(0, width);
        float lastY = mapY(tempo, height);
        beats = window.current_track.beats.slice();
        
        beats[0].bpm = tempo;
        minbpm = beats[0].bpm;
        maxbpm = beats[0].bpm;
        for (int i = 1; i < beats.length; i++)
        {
            beats[i].bpm = 60.0 / (beats[i].start - beats[i-1].start);
            if (maxbpm < beats[i].bpm)
                maxbpm = beats[i].bpm;
            if (minbpm > beats[i].bpm)
                minbpm = beats[i].bpm;
        }
        
        noFill();
        for (int i = 0; i < beats.length; i++)
        {
            stroke(55 + beats[i].confidence * 200);
            
            float x = mapX(beats[i].start, width);
            float y = mapY(beats[i].bpm, height);
            if (0.1 < beats[i].confidence) 
            {
                line(lastX, lastY, x, y);
                lastX = x;
                lastY = y;
            }
        }
        
        // smoothed track
        lastX = mapX(0, width);
        lastY = mapY(tempo, height);
        
        for (int i = 0; i < beats.length; i++)
            filter(beats, i, 5);
        
        for (int i = 0; i < beats.length; i++)
        {
            stroke(100, 255, 120);
            float x = mapX(beats[i].start, width);
            float y = mapY(beats[i].filteredBpm, height);
            if (0.1 < beats[i].confidence) 
            {
                line(lastX, lastY, x, y);
                lastX = x;
                lastY = y;
            }
        }
        
        // draw reference BPM
        {
            float y = mapY(tempo, height);
            stroke(255);
            strokeWeight(0.2);
            line(0, y, lastX, y);
            text("Overall bpm: " + nf(tempo, 3, 1) + ' in ' + nf(window.current_track.meter, 1) + "/4", width - 150, 10);
            
            // put some numbers in there for reference.
            fill(128);
            float minTick = minbpm + 0.5*(tempo - minbpm);
            y = mapY(minTick, height);
            float x = width - 100;
            line(x, y, width, y);
            float textY = y + 10;// below
            text(nf(minTick, 3,1) + " bpm", x, textY);
            
            float maxTick = maxbpm - 0.5*(maxbpm - tempo);
            y = mapY(maxTick, height);
            x = width - 100;
            line(x, y, width, y);
            textY = y - 4; // above
            text(nf(maxTick, 3,1) + " bpm", x, textY);
        }
        all = get();
    }
    
    update();
    resized = false;
}

void update()
{
    
    float x = mapX(window.timestamp, width);
    boolean update_needed = boolean(.9 < (x - position));
    if (update_needed)
    {
        position = x;
        image(all, 0, 0);
        
        // cursor
        fill(100, 255, 120, 96);
        rect(x, 0, 4, height);
    }
    
    beat = get_feature(beats, window.timestamp);
    // info text
    if (update_needed && beat)
    {
        fill(255);
        text("Time: " + nf(beat.start, 3, 1) + " bpm " + nf(beat.bpm, 3, 1) + "  Avg. bpm " + nf(beat.filteredBpm, 3, 1), 40, height - 10);
    }
    
}