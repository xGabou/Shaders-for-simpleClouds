#include "/lib/util/simpleCloudsBridge.glsl"

float scCloudThickness = GetSimpleCloudThicknessRaw();
float scCloudStormDark = GetSimpleCloudStormDarkness();
float scThicknessAmbient = mix(0.85, 1.2, scCloudThickness);
float scThicknessLight = mix(0.9, 1.3, scCloudThickness);
vec3 scStormTint = mix(vec3(1.0), vec3(0.65, 0.7, 0.78), scCloudStormDark);
float scStormDim = mix(1.0, 0.55, scCloudStormDark);

vec3 cloudRainColor = mix(nightMiddleSkyColor, dayMiddleSkyColor, sunFactor) * scStormTint;
vec3 cloudAmbientColor = mix(ambientColor * (sunVisibility2 * (0.55 + 0.1 * noonFactor) + 0.35), cloudRainColor * 0.5, rainFactor);
vec3 cloudLightColor   = mix(lightColor * (0.9 + 0.2 * noonFactor), cloudRainColor * 0.25, noonFactor * rainFactor);

cloudAmbientColor *= scThicknessAmbient * mix(1.0, 0.65, scCloudStormDark);
cloudLightColor   *= scThicknessLight * scStormDim;
