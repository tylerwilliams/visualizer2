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

void setup(){
    size(640, 480);
	strokeWeight(1);
	stroke(255);
	noFill();
	frameRate(30);
}

// Generic Looping Variables
int n, i;

// Controls the morph speed of the curve
int rate=20;

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

void handleResize(int new_width, int new_height) {
    size(new_width, new_height);
    curr_width = new_width;
    curr_height = new_height;
}

void handleSegment(Object new_segment) {
    if (segment != new_segment) {
        segment = new_segment;        
    }
}


void draw(){
    if (javascript != null) {
		if (!didRegister) {
		  javascript.registerSegmentCallback(handleSegment);
		  javascript.registerViewportSizeChangeCallback(handleResize);
          didRegister = true;
		}
	}
	// Set background color to to amplitude of sampleLoc     
	//background(255,255,255, 100);
	background(0, 0, 0, 255);
	
	// Loop through samples
	for (i=0; i < sampleRate; i++){      
	  if (segment) {
		nextDistXY[i] = segment.pitches[i]*height;
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
