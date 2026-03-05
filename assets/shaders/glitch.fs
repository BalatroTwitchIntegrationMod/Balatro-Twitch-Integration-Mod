extern float iTime;

float rand(vec2 co)
{
    return fract(sin(dot(co, vec2(17.13,91.7))) * 10000.0);
}

vec4 effect(vec4 c, Image t, vec2 tc, vec2 sc)
{
    vec2 uv = tc;

    float block = 4.0;

    vec2 cell = floor(sc / block);

    float r = rand(cell + floor(iTime * 5.0));

    if (r < 0.25)
    {
        vec2 jump;

        jump.x = rand(cell + iTime) * 0.2;
        jump.y = rand(cell - iTime) * 0.2;

        uv += jump;
    }

    if (r > 0.95)
    {
        uv = vec2(
            rand(sc + iTime),
            rand(sc - iTime)
        );
    }

    uv = clamp(uv, 0.0, 1.0);

    return Texel(t, uv);
}

#ifdef VERTEX
vec4 position(mat4 tp, vec4 vp)
{
    return tp * vp;
}
#endif