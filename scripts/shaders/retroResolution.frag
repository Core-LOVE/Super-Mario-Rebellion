#version 120
uniform sampler2D iChannel0;
uniform vec2 framebufferSize = vec2(800.0, 600.0);

void main()
{
	int x = int(gl_TexCoord[0].x * framebufferSize.x);
	int y = int(gl_TexCoord[0].y * framebufferSize.y);
	vec2 uv = vec2(gl_TexCoord[0].x - mod(x, 2) / framebufferSize.x, gl_TexCoord[0].y + mod(y + 1, 2) / framebufferSize.y);
	vec4 c = texture2D(iChannel0, uv);
	gl_FragColor = c;
}