/*
    FadeOverlay helper function
*/

enum FadeOP
{
    FADE_NONE,
    FADE_IN,
    FADE_OUT,
};

class FadeOverlay
{
    BorderImage@        fullscreenUI;
    float               alpha;
    float               curTime;
    float               totalTime;
    int                 curOp = FADE_NONE;
    String              textureFile = "Data/Textures/Fade.png";

    void Init()
    {
        if(ui is null || ui.root is null)
            return;
        fullscreenUI = BorderImage("FullScreenImage");
        fullscreenUI.visible = false;
        fullscreenUI.priority = -9999;
        Texture2D@ overlayTexture = cache.GetResource("Texture2D",textureFile);
        fullscreenUI.texture = overlayTexture;
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
        }
        return false;
    }

    void Show(float ap)
    {
        alpha = ap;
        SetUIAlpha();
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