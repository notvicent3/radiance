// Cyan diagonal stripes

void main(void) {
    gl_FragColor = texture2D(iFrame, uv);

    vec2 normCoord = (uv - 0.5) * aspectCorrection;

    float t = normCoord.x * 3.0 + normCoord.y * 3.0;
    float y = smoothstep(0.2, 0.7, abs(mod(t - 3. * iIntensityIntegral, 2.) - 1.));
    float g = smoothstep(0.5, 0.9, abs(mod(1. + t - 3. * iIntensityIntegral, 2.) - 1.));

    vec4 c = vec4(0., 1., 1., y);
    c = composite(c, vec4(0., 0., 1., g * smoothstep(0.5, 0.8, iIntensity)));

    c *= smoothstep(0., 0.1, iIntensity);
    c = clamp(c, 0., 1.);
    gl_FragColor = composite(gl_FragColor, c);
}
