#version 120
uniform sampler2D iChannel0;
uniform sampler2D iBackdrop;

void main()
{
	vec4 back = texture2D(iBackdrop, gl_FragCoord.xy);
    vec4 mask = texture2D(iChannel0, gl_TexCoord[0].xy);

	back.rgb += mask.rgb;

	gl_FragColor = back * gl_Color;
}