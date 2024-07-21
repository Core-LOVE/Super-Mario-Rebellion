#version 120
uniform sampler2D iChannel0;

uniform float waterY = -120608.0;

#include "shaders/logic.glsl"

void main()
{
	vec4 c = texture2D(iChannel0, gl_TexCoord[0].xy);

	c *= lt(gl_FragCoord.y,waterY);
	
	gl_FragColor = c * gl_Color;
}