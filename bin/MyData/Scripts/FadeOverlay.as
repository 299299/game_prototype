/*
    FadeOverlay helper function
*/

enum FadeOP
{
    FADE_NONE,
    FADE_IN,
    FADE_OUT,
    FADE_OUT_AUTO,
};

class FadeOverlay
{
    String              textureFile = "Data/Textures/Fade.png";
    BorderImage@        fullscreenUI;
    float               alpha;
    float               curTime;
    float               totalTime;
    int                 curOp = FADE_NONE;
    float               fadeInTime;

    void Init()
    {
        if(ui is null || ui.root is null)
            return;
        if (engine.headless)
            return;
        fullscreenUI = BorderImage("FullScreenImage");
        fullscreenUI.visible = false;
        fullscreenUI.priority = -9999;
        fullscreenUI.texture = cache.GetResource("Texture2D",textureFile);
        fullscreenUI.SetFullImageRect();
        ui.root.AddChild(fullscreenUI);
    }

    bool Update(float dt)
    {
        switch(curOp)
        {
        case FADE_IN:
            return UpdateFadeIn(dt);
        case FADE_OUT:
            return UpdateFadeOut(dt);
        case FADE_OUT_AUTO:
            {
                if (UpdateFadeOut(dt))
                    StartFadeIn(fadeInTime);
                return false;
            }
        }
        return false;
    }

    void Show(float ap)
    {
        alpha = ap;
        SetUIAlpha();
        if (fullscreenUI !is null)
            fullscreenUI.visible = true;
    }

    void StartFadeIn(float duration)
    {
        ResizeUI();

        alpha = 1.0;
        SetUIAlpha();
        totalTime = duration;
        curTime = duration;
        curOp = FADE_IN;
        if(fullscreenUI is null)
            return;
        fullscreenUI.visible = true;
    }

    void StartFadeOut(float duration)
    {
        ResizeUI();

        alpha = 0.0;
        SetUIAlpha();
        totalTime = duration;
        curTime = 0;
        curOp = FADE_OUT;
        if(fullscreenUI is null)
            return;
        fullscreenUI.visible = true;
    }

    void StartFade(float fadeOutDuration, float fadeInDuration)
    {
        StartFadeOut(fadeOutDuration);
        curOp = FADE_OUT_AUTO;
        fadeInTime = fadeInDuration;
    }

    void ResizeUI()
    {
        if(fullscreenUI is null)
            return;
        fullscreenUI.position = IntVector2(0,0);
        fullscreenUI.SetFixedSize(graphics.width, graphics.height);
    }

    bool UpdateFadeIn(float dt)
    {
        ResizeUI();
        SetUIAlpha();

        curTime -= dt;
        alpha = curTime / totalTime;

        if(curTime <= 0)
        {
            curOp = FADE_NONE;
            return true;
        }
        return false;
    }

    bool UpdateFadeOut(float dt)
    {
        ResizeUI();
        SetUIAlpha();

        curTime += dt;
        alpha = curTime / totalTime;
        if(curTime >= totalTime)
        {
            curOp = FADE_NONE;
            fullscreenUI.visible = true;
            return true;
        }
        return false;
    }

    void SetUIAlpha()
    {
        if(fullscreenUI is null)
            return;
        fullscreenUI.opacity = alpha;
    }
};