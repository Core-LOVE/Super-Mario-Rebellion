#version 120
uniform sampler2D iChannel0;
uniform float time;

// void main(){
// 	vec2 uv = gl_TexCoord[0].xy;
    
//     uv += cos(time*vec2(6.0, 7.0) + uv*10.0)*0.05;
    
// 	gl_FragColor = texture2D(iChannel0, uv);
// }

float wobble(float p, float amplitude, float frequence, float speed)
{
    return amplitude * sin(p * frequence + time * speed);
}

vec2 zoom(vec2 uv, float amt)
{
    return 0.5 + ((uv - 0.5) * amt);	
}

void main()
{
	float a = 0.025;
	float f = 15.0;
	float s = 8.0;
 
    vec2 uv = gl_TexCoord[0].xy;
    
    uv.x += wobble(uv.y, a, f, s);
    uv.y += wobble(uv.x, a, f, s);
    
    uv = zoom(uv, 1.0 - a*3.);
	
    gl_FragColor = texture2D(iChannel0, uv);
}