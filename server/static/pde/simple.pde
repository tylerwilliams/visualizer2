float spin = 0.0; 
float diameter = 84.0; 
float angle;

float angle_rot; 
int rad_points = 90;

void setup() {
	size(window.innerWidth, window.innerHeight-110);
	noStroke();
	smooth();
	X = width / 2;  
	Y = height / 2;  
	nX = X;  
	nY = Y;
}

void draw() { 
	size(window.innerWidth, window.innerHeight-110);

	background(153);
	translate(130, 65);
	fill(255);
	ellipse(0, 0, 16, 16);
	angle_rot = 0;
	fill(51);

	for(int i=0; i<5; i++) {
		pushMatrix();
		rotate(angle_rot + -45);
		ellipse(-116, 0, diameter, diameter);
		popMatrix();
		angle_rot += PI*2/5;
  	}

  	diameter = 34 * sin(angle) + 168;
  	angle += 0.02;
  	if (angle > TWO_PI) { 
		angle = 0; 
	}
}

void myshit() {
	radius = radius + sin( frameCount / 4 );
	
	// Track circle to new destination
	X+=(nX-X)/delay;
	Y+=(nY-Y)/delay;
	
	// Fill canvas grey
	background( 100 );
	
	// Set fill-color to blue
	fill( 0, 121, 184 );
	
	// Set stroke-color white
	stroke(255); 
	
	// Draw circle
	ellipse( X, Y, radius, radius );
}