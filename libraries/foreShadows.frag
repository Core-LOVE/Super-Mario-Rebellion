#version 120
uniform sampler2D iChannel0;

uniform sampler2D backBuffer;
uniform sampler2D middleBuffer;
uniform sampler2D foreBuffer;

uniform vec4 shadowColor;

#include "shaders/logic.glsl"


float colorsArentEqual(vec4 a, vec4 b)
{
	return gt(abs(a.r - b.r) + abs(a.g - b.g) + abs(a.b - b.b),0.0);
}

void main()
{
	vec2 xy = gl_TexCoord[0].xy;

	vec4 b = texture2D(backBuffer,xy);
	vec4 m = texture2D(middleBuffer,xy);
	vec4 f = texture2D(foreBuffer,xy);

	float opacity = and(colorsArentEqual(b,m),colorsArentEqual(m,f));
	
	gl_FragColor = opacity*gl_Color;
}