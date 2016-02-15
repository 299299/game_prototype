

class SmoothFocus : ScriptObject
{
    float smoothTimeElapsed = 0.001f;
    float smoothFocus = 0.0f;
    float smoothTimeSec = 0.5f;

    float lastFocus = 100.0f;
    float updateTimer = 0.05f;
    float updateTime = 0.0f;

    void PostUpdate(float timeStep)
    {
        if (engine.headless)
            return;

        updateTime += timeStep;
        float targetFocus = GetNearestFocus(GetCamera().farClip);
        smoothFocus = Lerp(smoothFocus, targetFocus, timeStep * 10.0f / smoothTimeSec);
        lastFocus = smoothFocus;
        renderer.viewports[0].renderPath.shaderParameters["SmoothFocus"] = smoothFocus;
    }

    float GetNearestFocus(float zCameraFarClip)
    {
        if (updateTime > updateTimer)
        {
            Camera@ camera = GetCamera();
            updateTime -= updateTimer;

            IntVector2 pos = ui.cursorPosition;
            Ray cameraRay = camera.GetScreenRay(float(pos.x) / graphics.width, float(pos.y) / graphics.height);
            RayQueryResult result = scene.octree.RaycastSingle(cameraRay, RAY_TRIANGLE, zCameraFarClip, DRAWABLE_GEOMETRY);
            return result.drawable !is null ? (camera.node.worldPosition - result.position).length : zCameraFarClip;
        }
        else
        {
            return lastFocus;
        }
    }

    void SetSmoothFocusEnabled(bool b)
    {
        renderer.viewports[0].renderPath.shaderParameters["SmoothFocusEnabled"] = true;
    }

    bool GetSmoothFocusEnabled()
    {
        return renderer.viewports[0].renderPath.shaderParameters["SmoothFocusEnabled"].GetBool();
    }
};