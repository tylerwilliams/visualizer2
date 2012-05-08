var droplets = [];
int num_drops = 0;
var S = null;
var segment = null;
var curr_height;
var curr_width;

interface JavaScript {
	boolean registerSegmentCallback(Object o);
	boolean deregisterSegmentCallback(Object o);
	boolean registerTatumCallback(Object o);
	boolean deregisterTatumCallback(Object o);
	boolean registerBeatCallback(Object o);
	boolean deregisterBeatCallback(Object o);
	boolean registerBarCallback(Object o);
	boolean deregisterBarCallback(Object o);
	boolean registerSectionCallback(Object o);
	boolean deregisterSectionCallback(Object o);
	boolean registerFullAnalysisCallback(Object o);
	boolean deregisterFullAnalysisCallback(Object o);
	boolean registerTimestampCallback(Object o);
	boolean deregisterTimestampCallback(Object o);
	boolean registerViewportSizeChangeCallback(Object o);
	boolean deregisterViewportSizeChangeCallback(Object o);	
}

JavaScript javascript = null;
boolean didRegister = false;

void setJavaScript(JavaScript js) { 
	javascript = js; 
}

void setup()
{
    size(640, 480);
    background(0);
    frameRate(30);
}

void handleResize(int new_width, int new_height) {
    size(new_width, new_height);
    curr_width = new_width;
    curr_height = new_height;
}

void handleSegment(Object new_segment) {
  segment = new_segment;
}

void draw()
{
    if (javascript != null) {
		if (!didRegister) {
		  javascript.registerSegmentCallback(handleSegment);
		  javascript.registerViewportSizeChangeCallback(handleResize);
          didRegister = true;
		}
	}

    background(0);
    fill(0, 6);
    rect(0, 0, curr_width, curr_height);
    noStroke();
    
    for (int i = 0; i < num_drops; i++)
    {
        if (droplets[i] != null)
        {
            if (droplets[i].update()) {
                droplets[i].draw();
            } else {
                droplets[i] = null;
            }
        }
    }
    if (segment && (segment != S) && (segment['confidence'] > .500))
    {
        S = segment;
        var t = S['timbre'];
        droplets[num_drops] = new Droplet(random(curr_width), random(curr_height), S['duration'], S['loudness_max'], t[0], t[1], t[2]);
        num_drops += 1;
    }
}

class Droplet
{
    int x, y, alpha;
    float mysize;
    float duration;
    int r, g, b;
    
    Droplet(int xin, int yin, float dur, float loud, int red, int grn, int blu)
    {
        x = xin;
        y = yin;
        alpha = 255;
        mysize = -5 * loud;
        duration = dur;
        r = red;
        g = grn;
        b = blu;
    }
    
    boolean update()
    {
        y += 1;
        float fr = frameRate;
        float dec = 255 / (fr * duration);
        alpha -= (dec/10);
        mysize += .5;
        return y <= height && 0 <= alpha;
    }
    
    void draw()
    {
        // fill(0, 60, 100+random(0,100), alpha);
        fill(r, g, b, alpha);
        ellipse(x, y, mysize, mysize);
    }
}