// see if chernoff's faces will work with segment data
// it works for financial data, apparently: http://anniespinster.wikidot.com/chernoff-faces-project
// Feature mapping:
// Use loudness for size of mouth.
// smile/frown for minor/major
// eyebrows -- harmonic expectation, maybe? (key of segment compared to key of section?)
// Nose?
// Eyes?
// Head Shape?
// transitions
// AUTHOR: <a href="http://twitter.com/jsundram">Jason Sundram</a>

/*BEGIN_DOCSTRING 

<p>
<b>Chernoff</b> takes its name from the idea of <a href="http://en.wikipedia.org/wiki/Chernoff_face">Chernoff Faces</a>. Chernoff faces are the projection of multivariate data onto the human face, taking advantage of the fact that people are exceedingly good at detecting small facial variations. However, the <b>Chernoff</b> visualizer currently only responds to changes in loudness.
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
}

var curr_height;
var curr_width;
var rFace = null;
var resized = false;
var TRACK = null;
var SEGMENT = null;

Rect.prototype.paint = function(fill_color, fill_alpha)
{
    pushStyle();
    noStroke();
    fill(fill_color, fill_alpha);
    rect(this.left, this.top, this.width, this.height);//pjs function
    popStyle();
};

void draw()
{
    if (curr_height != get_max_canvas_height() || curr_width != get_max_canvas_width())
    {
        curr_height = get_max_canvas_height();
        curr_width = get_max_canvas_width();
        resized = true;
        // This size call causes the background to redraw().
        resize(window.p, curr_width, curr_height, 0);
        rFace = new Rect(0,0, curr_width, curr_height);
    }
    
    if (TRACK != window.current_track)
        TRACK = window.current_track
    
    // TODO: only paint here
    if (SEGMENT != window.segment)
    {
        SEGMENT = window.segment; 
        make_face(SEGMENT, rFace);
    }
    
    resized = false; // after we've made it through a draw loop, we've resized.
}

void make_face(segment, r)
{
    r.paint(0, 255);
    noFill();
    stroke(255, 255);
    int weight = 4;
    strokeWeight(weight);
    
    // bounding ellipse = face
    int xc = r.left + (r.width / 2);
    int yc = r.top + (r.height / 2);
    diameter = min(r.width, r.height) - 2*weight;
    ellipseMode(CENTER);
    ellipse(xc, yc, diameter, diameter);
    
    // nose
    int nose_width = diameter / 10; 
    int nose_height = diameter / 4;
    int nose_top = yc - nose_height/2;
    int nose_bottom = yc + nose_height/2;
    triangle(xc, nose_top, xc - nose_width/2, nose_bottom, xc + nose_width/2, nose_bottom);
    // WTF, triangle doesn't close, but it looks fine.
    
    // eyes
    int eye_middle_height = nose_top - diameter / 10;
    int eye_width = diameter / 4;
    int eye_height = eye_width / 2;
    ellipse(xc - diameter/4, eye_middle_height, eye_width, eye_height);
    ellipse(xc + diameter/4, eye_middle_height, eye_width, eye_height);
    fill();
    int pupil_diameter = eye_height / 8;
    ellipse(xc - diameter/4, eye_middle_height, pupil_diameter, pupil_diameter);
    ellipse(xc + diameter/4, eye_middle_height, pupil_diameter, pupil_diameter);
    noFill();
    ellipse(xc - diameter/4, eye_middle_height, eye_height-2, eye_height-2);
    ellipse(xc + diameter/4, eye_middle_height, eye_height-2, eye_height-2);
    
    
    // eyebrows
    bezier( xc - 6 * diameter/16, eye_middle_height - eye_width / 3,
            xc - 4 * diameter/16, eye_middle_height - eye_width / 2, 
            xc - 2 * diameter/16, eye_middle_height - eye_width / 2,
            xc - 1 * diameter/16, eye_middle_height - eye_width / 3);
    
    bezier( xc + 6 * diameter/16, eye_middle_height - eye_width / 3,
            xc + 4 * diameter/16, eye_middle_height - eye_width / 2, 
            xc + 2 * diameter/16, eye_middle_height - eye_width / 2,
            xc + 1 * diameter/16, eye_middle_height - eye_width / 3);
    
    // mouth top
    dbmf = segment == null ? 1 : segment.dbmf;
    
    float mouth_factor = map(dbmf, 0, 1, .25, 3); // dbm
    
    // console.log(segment, dbmf, mouth_factor);
    int mouth_top = nose_bottom + diameter / 10;
    int mouth_width = mouth_factor * .5 * diameter / 2;
    int mouth_turn = mouth_factor * diameter / 40; //?
    bezier( xc - mouth_width / 2, mouth_top + mouth_turn, 
            xc - mouth_width / 4, mouth_top,
            xc + mouth_width / 4, mouth_top,
            xc + mouth_width / 2, mouth_top + mouth_turn);
    
    // mouth bottom
    bezier( xc - mouth_width / 2, mouth_top + mouth_turn, 
            xc - mouth_width / 4, mouth_top + 4*mouth_turn,
            xc + mouth_width / 4, mouth_top + 4*mouth_turn,
                xc + mouth_width / 2, mouth_top + mouth_turn);
}