#property description Makes the image warbly

void main(void) {
    vec2 newPt = uv - 0.5;

    float bins = iIntensity * 10.;

    vec2 newPtInt = floor(newPt * bins);
    vec2 newPtFrac = fract(newPt * bins);
    newPtFrac = newPtFrac * 2. - 1.;

    vec2 displacement = pow(abs(newPtFrac), vec2(1. + 2. * iIntensity)) * sign(newPtFrac);
    newPt = (newPtInt + 0.5 * displacement + 0.5) / bins;

    fragColor = texture(iInput, newPt + 0.5);
}
