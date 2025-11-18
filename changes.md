# Complementary Reimagined – SimpleClouds Integration Log

## Latest update (SimpleClouds blending request)
- Added `/shaders/lib/util/sc_bridge.glsl` to centralize the `sc_simpleCloudState` and `sc_simpleCloudType` uniform handling plus helper functions (visibility, thickness, storm factors, type-based shading curves).
- Updated the volumetric cloud stack (`/shaders/lib/atmospherics/clouds/mainClouds.glsl`, `reimaginedClouds.glsl`, `unboundClouds.glsl`) to scale density/opacity, sampling thickness, distance falloff, and shading with the SimpleClouds fade/density/storm inputs while keeping Complementary’s native logic.
- Fed the SimpleClouds modifiers through the shared color pipelines (`/shaders/lib/colors/cloudColors.glsl`, `lightAndAmbientColors.glsl`, `skyColors.glsl`) plus `/shaders/lib/atmospherics/sky.glsl` so sky brightness and weather coloration now darken/tint with storminess rather than being overridden.
- Reworked the `lightAndAmbientColors.glsl` adjustments so the storm/thickness multipliers are folded into the vector declarations instead of using global-scope `*=` statements, keeping Iris’s AST parser happy while preserving the intended visual change.

## Future notes
- Add the next request summary here so this log tracks every manual edit applied on top of upstream Complementary.
