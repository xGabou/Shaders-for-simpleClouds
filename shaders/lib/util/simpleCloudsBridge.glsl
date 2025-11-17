#ifndef SIMPLE_CLOUDS_BRIDGE_GLSL
    #define SIMPLE_CLOUDS_BRIDGE_GLSL

    #ifndef SIMPLE_CLOUDS_UNIFORMS_DECLARED
        #define SIMPLE_CLOUDS_UNIFORMS_DECLARED
        uniform vec4 simpleCloudsCloudState;
        uniform vec4 simpleCloudsCloudType;
    #endif

    vec4 GetSimpleCloudStateSafe() {
        vec4 state = clamp(simpleCloudsCloudState, vec4(0.0), vec4(1.0));
        float availability = smoothstep(0.0001, 0.0005, dot(state, vec4(1.0)));
        vec4 fallback = vec4(1.0, 1.0, 0.0, 0.0);
        return mix(fallback, state, availability);
    }

    float GetSimpleCloudVisibilityFactor() {
        return GetSimpleCloudStateSafe().x;
    }

    float GetSimpleCloudThicknessRaw() {
        return GetSimpleCloudStateSafe().y;
    }

    float GetSimpleCloudStorminessValue() {
        return GetSimpleCloudStateSafe().z;
    }

    float GetSimpleCloudSmoothStorminessValue() {
        return GetSimpleCloudStateSafe().w;
    }

    float GetSimpleCloudStormDarkness() {
        return clamp(mix(GetSimpleCloudStorminessValue(), GetSimpleCloudSmoothStorminessValue(), 0.6), 0.0, 1.0);
    }

    float GetSimpleCloudThicknessScale() {
        return mix(0.5, 1.5, GetSimpleCloudThicknessRaw());
    }

    vec4 GetSimpleCloudTypeMask() {
        vec4 mask = clamp(simpleCloudsCloudType, 0.0, 1.0);
        float sum = mask.x + mask.y + mask.z + mask.w;
        if (sum <= 0.0001) return vec4(1.0, 0.0, 0.0, 0.0);
        return mask / sum;
    }

    float ApplySimpleCloudTypeShading(float shadingValue) {
        float shading = clamp(shadingValue, 0.0, 2.0);
        vec4 mask = GetSimpleCloudTypeMask();
        vec4 shadedVariants = vec4(
            pow(shading, 0.70),  // flat / layered
            shading,             // puffy
            pow(shading, 1.10),  // towering
            pow(shading, 1.35)   // storm / anvil
        );
        return dot(mask, shadedVariants);
    }

#endif // SIMPLE_CLOUDS_BRIDGE_GLSL
