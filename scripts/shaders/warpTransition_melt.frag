// I mostly made this for fun :v
// Modified by KateBulka

#version 120
#define MAX_SCREENWIDTH 800
// Please change MAX_SCREENWIDTH if you are changing screen width

uniform int screenWidth = 800;
uniform sampler2D iChannel0;
uniform float yOffsets[MAX_SCREENWIDTH-1];

#include "shaders/logic.glsl"

void main()
{
	vec2 xy = gl_TexCoord[0].xy;
	int offsetIndex = int(xy.x*float(screenWidth));

	xy.y = xy.y - yOffsets[offsetIndex];

	vec4 c = texture2D(iChannel0,xy);

	c.rgba = mix(c.rgba,vec4(0),lt(xy.y,0));
	
	gl_FragColor = c*gl_Color;
}