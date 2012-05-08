// AUTHOR: williams.tyler@gmail.com

/*BEGIN_DOCSTRING 

<p>
[Based on Mouse-Motion to Frequency - By F1LT3R 
<br>
http://groups.google.com/group/processingjs
<br>
Respect.]
</p>
<br>
<p>
A poor example of an equalizer, <b>Equaline</b> looks at the pitches of each segment.
</p>
END_DOCSTRING*/

void setup(){
	size(get_max_canvas_width(), get_max_canvas_height());
	strokeWeight(1);
	stroke(255);
	noFill();
	enable_segments();
}

// Generic Looping Variables
int n, i;

// Controls the morph speed of the curve
int rate=50;

// Set Last Mouse X & Y for dist check
int lastMouseX, lastMouseY;
int distX, distY, lastDistXY;

// Set sample rate and buffer arrays
int sampleRate = 12, sampleLoc = 0;
int lastSampleRate = sampleRate;
int[] distXY = new int[sampleRate];
int[] nextDistXY = new int[sampleRate];

int offset = height/2;

// Fill original target buffer
for (i=0; i < sampleRate; i++) { 
  distXY[i] = height/2;
} 

void draw(){
    resize(this, get_max_canvas_width(), get_max_canvas_height(), 0);

	// Set background color to to amplitude of sampleLoc     
	//background(255,255,255, 100);
	background(0, 0, 0, 255);
	
	// Loop through samples
	for (i=0; i < sampleRate; i++){      
	  if (window.segment) {
		nextDistXY[i] = window.segment.pitches[i]*height;
	  } else {
		nextDistXY[i] = 0;
	  }
	
	  colorDelay = (255/sampleRate) * distXY[i];
	
	  // Morph old curve into new curve
	  if (nextDistXY[i] < distXY[i]) {    
	      distXY[i] = distXY[i] - ((distXY[i] - nextDistXY[i]) / rate);
	  } else if (nextDistXY[i] > distXY[i]){
	      distXY[i] = distXY[i] + ((nextDistXY[i] - distXY[i]) / rate);
	  }
	}
	
	// Draw curve
	noFill();
	stroke(0,255,0);
	strokeWeight(5);
	beginShape();
	curveVertex( (width/(sampleRate-1))*0, height/2 - distXY[0] + offset );
	for (n=0; n < sampleRate; n++){    
	  curveVertex( (width/(sampleRate-1))*n, height/2 - distXY[n] + offset );    
	}
	curveVertex( (width/(sampleRate-1))*n-1, height/2 - distXY[n-1] + offset );
	endShape();
}
