#ifndef SC_BRIDGE_GLSL
#define SC_BRIDGE_GLSL

// SC ENABLE FLAGS (manual override, Iris cannot auto-detect)
#define USE_SC 1
#define USE_SC_CLOUDS 0

//--------------------------------------------------
// FULL CLOUDS FEATURE SET (SimpleClouds active)
//--------------------------------------------------
#if USE_SC_CLOUDS

    //--------------------------------------------------
    // Uniforms (guaranteed declared exactly once)
    //--------------------------------------------------
    #ifndef SC_UNIFORMS_DECLARED
        #define SC_UNIFORMS_DECLARED
        uniform vec4  sc_State;                 // Visibility, Thickness, Storminess, SmoothStorm
        uniform vec4  sc_Type;                  // Cloud-type weighting
        uniform float sc_CloudShadowFactor;
        uniform sampler2D sc_CloudLayerTex;
        uniform vec2  sc_CloudShadowTexSize;
        uniform float sc_CloudShadowWorldSpan;
        uniform vec2  sc_CloudShadowOriginXZ;
        uniform vec2  sc_CloudShadowScrollXZ;
        uniform float sc_CloudHeight;
    #endif

    #ifndef CLOUD_SHADOW_QUALITY_MODE
        #define CLOUD_SHADOW_QUALITY_MODE 2
    #endif

    //--------------------------------------------------
    // Safe SC State fetch
    //--------------------------------------------------
    vec4 Get_SC_StateSafe() {
        vec4 state = sc_State;
        float avail = smoothstep(0.0001, 0.0005, dot(state, vec4(1.0)));
        return mix(vec4(0.0), state, avail);
    }

    float Get_SC_VisibilityFactor()        { return Get_SC_StateSafe().x; }
    float Get_SC_ThicknessRaw()            { return Get_SC_StateSafe().y; }
    float Get_SC_StorminessValue()         { return Get_SC_StateSafe().z; }
    float Get_SC_SmoothStorminessValue()   { return Get_SC_StateSafe().w; }

    //--------------------------------------------------
    // Storm + thickness
    //--------------------------------------------------
    float Get_SC_StormDarkness() {
        float a = Get_SC_StorminessValue();
        float b = Get_SC_SmoothStorminessValue();
        return clamp(mix(a, b, 0.6), 0.0, 1.0);
    }

    float scStormDark = Get_SC_StormDarkness();

    float Get_SC_ThicknessScale() {
        return mix(0.5, 1.5, Get_SC_ThicknessRaw());
    }

    //--------------------------------------------------
    // Cloud type mask
    //--------------------------------------------------
    vec4 Get_SC_TypeMask() {
        vec4 m = clamp(sc_Type, 0.0, 1.0);
        float s = m.x + m.y + m.z + m.w;
        return (s <= 0.0001) ? vec4(1.0, 0.0, 0.0, 0.0) : m / s;
    }

    float Apply_SC_TypeShading(float shadingValue) {
        float shading = clamp(shadingValue, 0.0, 2.0);
        vec4 mask = Get_SC_TypeMask();
        vec4 variants = vec4(
            pow(shading, 0.70),
            shading,
            pow(shading, 1.10),
            pow(shading, 1.35)
        );
        return dot(mask, variants);
    }

    //--------------------------------------------------
    // Procedural fallback shadow strength
    //--------------------------------------------------
    float Get_SC_ShadowStrength() {
        float thick = Get_SC_ThicknessRaw();
        float storm = Get_SC_StormDarkness();
        float coverage = clamp(thick * 0.65 + storm * 0.45, 0.0, 1.0);
        float shadow = smoothstep(0.25, 0.85, coverage);
        return shadow * 0.85;
    }

    int Get_SC_CloudShadowMode() {
        return clamp(CLOUD_SHADOW_QUALITY_MODE, 0, 2);
    }

    //--------------------------------------------------
    // Actual cloud mask texture (from OFSC)
    //--------------------------------------------------
    bool SC_HasCloudLayerTexture() {
        ivec2 t = textureSize(sc_CloudLayerTex, 0);
        return (t.x > 0 && t.y > 0 && sc_CloudShadowWorldSpan > 0.0001);
    }

    vec2 Get_SC_CloudLayerUV(vec3 worldPos) {
        vec2 worldXZ = worldPos.xz;
        return (worldXZ - sc_CloudShadowOriginXZ) / sc_CloudShadowWorldSpan;
    }

    float Sample_SC_CloudLayerShadow(vec3 worldPos) {
        if (!SC_HasCloudLayerTexture()) return -1.0;

        vec2 uv = Get_SC_CloudLayerUV(worldPos);
        if (any(lessThan(uv, vec2(0.0))) || any(greaterThan(uv, vec2(1.0)))) {
            return 0.0;
        }

        float c = texture2D(sc_CloudLayerTex, uv).r;
        return clamp(c, 0.0, 1.0);
    }

    vec3 Get_SC_ShadowSamplePos(vec3 worldPos, vec3 lightDirWorld) {
        if (lightDirWorld.y <= 0.01 || sc_CloudHeight <= worldPos.y) {
            return worldPos;
        }

        float distanceToCloudLayer = sc_CloudHeight - worldPos.y;
        float travel = min(distanceToCloudLayer / lightDirWorld.y, sc_CloudShadowWorldSpan * 0.75);
        return worldPos + lightDirWorld * travel;
    }

    //--------------------------------------------------
    // Combined shadow result
    //--------------------------------------------------
    float Get_SC_FinalShadow(vec3 worldPos) {
        int mode = Get_SC_CloudShadowMode();

        if (mode == 2) {
            float s = Sample_SC_CloudLayerShadow(worldPos);

            if (s >= 0.0) {
                float cloudDark = smoothstep(0.08, 0.72, s) * 0.82;
                return cloudDark;
            }

            mode = 1;
        }

        if (mode == 0) {
            if (sc_CloudShadowFactor > 0.0) {
                return clamp(sc_CloudShadowFactor, 0.0, 1.0);
            }
        }

        return Get_SC_ShadowStrength();
    }

    float Get_SC_FinalShadowProjected(vec3 worldPos, vec3 lightDirWorld) {
        if (lightDirWorld.y <= 0.01) {
            return 0.0;
        }
        return Get_SC_FinalShadow(Get_SC_ShadowSamplePos(worldPos, lightDirWorld));
    }

    float Get_SC_FinalShadow() {
        #ifdef cameraPosition
            return Get_SC_FinalShadow(cameraPosition);
        #else
            return 0.0;
        #endif
    }

//--------------------------------------------------
// SC DISABLED -> Full valid stub API
//--------------------------------------------------
#else

    #define Get_SC_VisibilityFactor()        0.0
    #define Get_SC_ThicknessRaw()            0.0
    #define Get_SC_StorminessValue()         0.0
    #define Get_SC_SmoothStorminessValue()   0.0

    float Get_SC_StormDarkness()             { return 0.0; }
    float Get_SC_ThicknessScale()            { return 1.0; }
    float Apply_SC_TypeShading(float x)      { return x; }

    float scStormDark = 0.0;

    float Get_SC_ShadowStrength()            { return 0.0; }
    int   Get_SC_CloudShadowMode()           { return 0; }

    bool SC_HasCloudLayerTexture()           { return false; }
    vec2 Get_SC_CloudLayerUV(vec3 worldPos)  { return vec2(0.0); }
    float Sample_SC_CloudLayerShadow(vec3 worldPos) { return -1.0; }
    vec3 Get_SC_ShadowSamplePos(vec3 worldPos, vec3 lightDirWorld) { return worldPos; }

    float Get_SC_FinalShadow(vec3 worldPos)  { return 0.0; }
    float Get_SC_FinalShadowProjected(vec3 worldPos, vec3 lightDirWorld) { return 0.0; }
    float Get_SC_FinalShadow()               { return 0.0; }

#endif

#endif // SC_BRIDGE_GLSL
