// ==============================================
//
//    GameState Class for Game Manager
//
// ==============================================

class GameState : State
{
    void OnSceneLoadFinished(Scene@ _scene)
    {
    }

    void OnAsyncLoadProgress(Scene@ _scene, float progress, int loadedNodes, int totalNodes, int loadedResources, int totalResources)
    {
    }

    void OnKeyDown(int key)
    {
        if (key == KEY_ESCAPE)
        {
             if (!console.visible)
                OnESC();
            else
                console.visible = false;
        }
    }

    void OnESC()
    {
        engine.Exit();
    }

    void OnSceneTimeScaleUpdated(Scene@ scene, float newScale)
    {
    }
};

enum LoadSubState
{
    LOADING_RESOURCES,
    LOADING_MOTIONS,
    LOADING_FINISHED,
};

class LoadingState : GameState
{
    int                 state = -1;
    int                 numLoadedResources = 0;
    Scene@              preloadScene;

    LoadingState()
    {
        SetName("LoadingState");
    }

    void CreateLoadingUI()
    {
        float alphaDuration = 1.0f;
        ValueAnimation@ alphaAnimation = ValueAnimation();
        alphaAnimation.SetKeyFrame(0.0f, Variant(0.0f));
        alphaAnimation.SetKeyFrame(alphaDuration, Variant(1.0f));
        alphaAnimation.SetKeyFrame(alphaDuration * 2, Variant(0.0f));

        Texture2D@ logoTexture = cache.GetResource("Texture2D", "Textures/ulogo.jpg");
        Sprite@ logoSprite = ui.root.CreateChild("Sprite", "logo");
        logoSprite.texture = logoTexture;
        int textureWidth = logoTexture.width;
        int textureHeight = logoTexture.height;
        logoSprite.SetScale(256.0f / textureWidth);
        logoSprite.SetSize(textureWidth, textureHeight);
        logoSprite.SetHotSpot(0, textureHeight);
        logoSprite.SetAlignment(HA_LEFT, VA_BOTTOM);
        logoSprite.SetPosition(graphics.width - textureWidth/2, 0);
        logoSprite.opacity = 0.75f;
        logoSprite.priority = -100;
        logoSprite.AddTag("TAG_LOADING");

        Text@ text = ui.root.CreateChild("Text", "loading_text");
        text.SetFont(cache.GetResource("Font", UI_FONT), UI_FONT_SIZE);
        text.SetAlignment(HA_LEFT, VA_BOTTOM);
        text.SetPosition(2, 0);
        text.color = Color(1, 1, 1);
        text.textEffect = TE_STROKE;
        text.AddTag("TAG_LOADING");

        Texture2D@ loadingTexture = cache.GetResource("Texture2D", "Textures/Loading.tga");
        Sprite@ loadingSprite = ui.root.CreateChild("Sprite", "loading_bg");
        loadingSprite.texture = loadingTexture;
        textureWidth = loadingTexture.width;
        textureHeight = loadingTexture.height;
        loadingSprite.SetSize(textureWidth, textureHeight);
        loadingSprite.SetPosition(graphics.width/2 - textureWidth/2, graphics.height/2 - textureHeight/2);
        loadingSprite.priority = -100;
        loadingSprite.opacity = 0.0f;
        loadingSprite.AddTag("TAG_LOADING");
        loadingSprite.SetAttributeAnimation("Opacity", alphaAnimation);
    }

    void Enter(State@ lastState)
    {
        State::Enter(lastState);
        if (!engine.headless)
            CreateLoadingUI();
        ChangeSubState(LOADING_RESOURCES);
    }

    void Exit(State@ nextState)
    {
        State::Exit(nextState);
        Array<UIElement@>@ elements = ui.root.GetChildrenWithTag("TAG_LOADING");
        for (uint i = 0; i < elements.length; ++i)
            elements[i].Remove();
    }

    void Update(float dt)
    {
        if (state == LOADING_RESOURCES)
        {

        }
        else if (state == LOADING_MOTIONS)
        {
            Text@ text = ui.root.GetChild("loading_text");
            if (text !is null)
                text.text = "Loading Motions, loaded = " + gMotionMgr.processedMotions;

            if (d_log)
                Print("============================== Motion Loading start ==============================");

            if (gMotionMgr.Update(dt))
            {
                gMotionMgr.Finish();
                ChangeSubState(LOADING_FINISHED);
                if (text !is null)
                    text.text = "Loading Scene Resources";
            }

            if (d_log)
                Print("============================== Motion Loading end ==============================");
        }
        else if (state == LOADING_FINISHED)
        {
            if (preloadScene !is null)
                preloadScene.Remove();
            preloadScene = null;
            gGame.ChangeState("TestGameState");
        }
    }

    void ChangeSubState(int newState)
    {
        if (state == newState)
            return;

        Print("LoadingState ChangeSubState from " + state + " to " + newState);
        state = newState;

        if (newState == LOADING_RESOURCES)
        {
            preloadScene = Scene();
            preloadScene.LoadAsyncXML(cache.GetFile("Scenes/animation.xml"), LOAD_RESOURCES_ONLY);
        }
        else if (newState == LOADING_MOTIONS)
            gMotionMgr.Start();
    }

    void OnSceneLoadFinished(Scene@ _scene)
    {
        if (state == LOADING_RESOURCES)
        {
            Print("Scene Loading Finished");
            ChangeSubState(LOADING_MOTIONS);
        }
    }

    void OnAsyncLoadProgress(Scene@ _scene, float progress, int loadedNodes, int totalNodes, int loadedResources, int totalResources)
    {
        Text@ text = ui.root.GetChild("loading_text");
        if (text !is null)
            text.text = "Loading scene ressources progress=" + progress + " resources:" + loadedResources + "/" + totalResources;
    }

    void OnESC()
    {
        if (state == LOADING_RESOURCES)
            preloadScene.StopAsyncLoading();
        engine.Exit();
    }
};

enum GameSubState
{
    GAME_FADING,
    GAME_RUNNING,
    GAME_PAUSE,
};

class TestGameState : GameState
{
    Scene@              gameScene;
    TextMenu@           pauseMenu;
    BorderImage@        fullscreenUI;

    int                 state = -1;
    int                 pauseState = -1;

    float               fadeTime;
    float               fadeInDuration = 2.0f;
    float               restartDuration = 5.0f;

    bool                postInited = false;

    Array<uint>         gameObjects;

    TestGameState()
    {
        SetName("TestGameState");
        @pauseMenu = TextMenu(UI_FONT, UI_FONT_SIZE);
        fullscreenUI = BorderImage("FullScreenImage");
        fullscreenUI.visible = false;
        fullscreenUI.priority = -9999;
        fullscreenUI.opacity = 1.0f;
        fullscreenUI.texture = cache.GetResource("Texture2D", "Textures/fade.png");
        fullscreenUI.SetFullImageRect();
        if (!engine.headless)
            fullscreenUI.SetFixedSize(graphics.width, graphics.height);
        ui.root.AddChild(fullscreenUI);
        pauseMenu.texts.Push("RESUME");
        pauseMenu.texts.Push("EXIT");
    }

    ~TestGameState()
    {
        @pauseMenu = null;
        gameScene = null;
        fullscreenUI.Remove();
    }

    void Enter(State@ lastState)
    {
        state = -1;
        State::Enter(lastState);

        if (!engine.headless)
        {
            CreateViewPort();
            CreateUI();
        }

        CreateScene();
        PostCreate();

        ChangeSubState(GAME_FADING);
    }

    void PostCreate()
    {
        Node@ zoneNode = gameScene.GetChild("zone", true);
        Zone@ zone = zoneNode.GetComponent("Zone");
        // zone.heightFog = false;
    }

    void CreateUI()
    {
        int height = graphics.height / 22;
        if (height > 64)
            height = 64;
        Text@ messageText = ui.root.CreateChild("Text", "message");
        messageText.SetFont(cache.GetResource("Font", UI_FONT), UI_FONT_SIZE);
        messageText.SetAlignment(HA_CENTER, VA_CENTER);
        messageText.SetPosition(0, -height * 2 + 100);
        messageText.color = Color(1, 0, 0);
        messageText.visible = false;
    }

    void Update(float dt)
    {
        switch (state)
        {
        case GAME_FADING:
            {
                float t = fullscreenUI.GetAttributeAnimationTime("Opacity");
                if (t + 0.05f >= fadeTime)
                {
                    fullscreenUI.visible = false;
                    ChangeSubState(GAME_RUNNING);
                }
            }
            break;

        case GAME_PAUSE:
            {
                int selection = pauseMenu.Update(dt);
                if (selection == 0)
                    ChangeSubState(pauseState);
                else if (selection == 1)
                    engine.Exit();
            }
            break;

        case GAME_RUNNING:
            {
                if (!postInited) {
                    if (timeInState > 2.0f) {
                        postInit();
                        postInited = true;
                    }
                }
            }
            break;
        }
        GameState::Update(dt);
    }

    void ChangeSubState(int newState)
    {
        if (state == newState)
            return;

        int oldState = state;
        Print("TestGameState ChangeSubState from " + oldState + " to " + newState);
        state = newState;
        timeInState = 0.0f;

        script.defaultScene.updateEnabled = !(newState == GAME_PAUSE);
        fullscreenUI.SetAttributeAnimationSpeed("Opacity", newState == GAME_PAUSE ? 0.0f : 1.0f);

        if (newState == GAME_PAUSE)
            pauseMenu.Add();
        else
            pauseMenu.Remove();

        Player@ player = GetPlayer();

        switch (newState)
        {
        case GAME_RUNNING:
            {
                freezeInput = false;
            }
            break;

        case GAME_FADING:
            {
                if (oldState != GAME_PAUSE)
                {
                    ValueAnimation@ alphaAnimation = ValueAnimation();
                    alphaAnimation.SetKeyFrame(0.0f, Variant(1.0f));
                    alphaAnimation.SetKeyFrame(fadeInDuration, Variant(0.0f));
                    fadeTime = fadeInDuration;
                    fullscreenUI.visible = true;
                    fullscreenUI.SetAttributeAnimation("Opacity", alphaAnimation, WM_ONCE);
                }

                freezeInput = true;
            }
            break;

        case GAME_PAUSE:
            {
                // ....
            }
            break;

        }
    }

    void CreateViewPort()
    {
        Viewport@ viewport = Viewport(null, null);
        renderer.viewports[0] = viewport;
        RenderPath@ renderpath = viewport.renderPath.Clone();
        if (render_features & RF_HDR != 0)
        {
            // if (reflection)
            //    renderpath.Load(cache.GetResource("XMLFile","RenderPaths/ForwardHWDepth.xml"));
            // else
            renderpath.Load(cache.GetResource("XMLFile","RenderPaths/ForwardDepth.xml"));
            renderpath.Append(cache.GetResource("XMLFile","PostProcess/AutoExposure.xml"));
            renderpath.Append(cache.GetResource("XMLFile","PostProcess/BloomHDR.xml"));
            renderpath.Append(cache.GetResource("XMLFile","PostProcess/Tonemap.xml"));
            renderpath.SetEnabled("TonemapReinhardEq3", false);
            renderpath.SetEnabled("TonemapUncharted2", true);
            renderpath.shaderParameters["TonemapMaxWhite"] = 1.8f;
            renderpath.shaderParameters["TonemapExposureBias"] = 2.5f;
            renderpath.shaderParameters["AutoExposureAdaptRate"] = 2.0f;
            renderpath.shaderParameters["BloomHDRMix"] = Variant(Vector2(0.9f, 0.6f));
        }
        renderpath.Append(cache.GetResource("XMLFile", "PostProcess/FXAA2.xml"));
        renderpath.Append(cache.GetResource("XMLFile","PostProcess/ColorCorrection.xml"));
        renderpath.Append(cache.GetResource("XMLFile", "PostProcess/GammaCorrection.xml"));
        viewport.renderPath = renderpath;
        SetColorGrading(colorGradingIndex);
    }

    void OnNodeLoaded(Node@ node_)
    {
        Print("node.name=" + node_.name);
        if (node_.name == "player")
        {
            Node@ playerNode = CreateCharacter("player_max", "LIS/CH_Max/CH_S_Max01.xml", "Max", node_.worldPosition, node_.worldRotation);
            audio.listener = playerNode.GetChild(HEAD, true).CreateComponent("SoundListener");
            playerId = playerNode.id;
            node_.Remove();
            gameObjects.Push(playerId);
        }
        else if (node_.name.StartsWith("SK_Doors") || node_.name.StartsWith("ST_Doors"))
        {
            node_.CreateScriptObject(scriptFile, "Door");
            gameObjects.Push(node_.id);
        }
        else if (node_.name.StartsWith("light"))
        {
            Light@ light = node_.GetComponent("Light");
            if (render_features & RF_SHADOWS == 0)
                light.castShadows = false;
            light.shadowBias = BiasParameters(0.00025f, 0.5f);
            light.shadowCascade = CascadeParameters(10.0f, 50.0f, 200.0f, 0.0f, 0.8f);
        }
        else if (node_.name.StartsWith("ST_Food") || node_.name.StartsWith("SK_Food"))
        {
            node_.CreateScriptObject(scriptFile, "Food");
            gameObjects.Push(node_.id);
        }
        else if (node_.name.StartsWith("ST_Furn") || node_.name.StartsWith("SK_Furn"))
        {
            node_.CreateScriptObject(scriptFile, node_.name.Contains("Mirror") ? "Mirror" : "Furniture");
            gameObjects.Push(node_.id);
        }
        else if (node_.name.StartsWith("ST_Eng") || node_.name.StartsWith("SK_Eng"))
        {
            node_.CreateScriptObject(scriptFile, "Vehicle");
            gameObjects.Push(node_.id);
        }
        else if (node_.name.StartsWith("ST_Light") || node_.name.StartsWith("SK_Light"))
        {
            node_.CreateScriptObject(scriptFile, "LightSource");
            gameObjects.Push(node_.id);
        }
        else if (node_.name.StartsWith("ST_Rub") || node_.name.StartsWith("SK_Rub"))
        {
            node_.CreateScriptObject(scriptFile, "Rubbish");
            gameObjects.Push(node_.id);
        }
        else if (node_.name.StartsWith("ST_Acc") || node_.name.StartsWith("SK_Acc"))
        {
            node_.CreateScriptObject(scriptFile, "Accessory");
            gameObjects.Push(node_.id);
        }
        /*else if (node_.name.StartsWith("ST_Deco") || node_.name.StartsWith("SK_Deco"))
        {
            node_.CreateScriptObject(scriptFile, "Decoration");
            gameObjects.Push(node_.id);
        }
        else if (node_.name.StartsWith("ST_Nat") || node_.name.StartsWith("SK_Nat"))
        {
            node_.CreateScriptObject(scriptFile, "Nature");
            gameObjects.Push(node_.id);
        }*/
    }

    void OnSceneLoaded(Scene@ scene_)
    {
        uint t = time.systemTime;

        gameObjects.Clear();

        // process current scene
        for (uint i=0; i<scene_.numChildren; ++i)
        {
            OnNodeLoaded(scene_.children[i]);
        }

        gCameraMgr.Start(scene_);
        gCameraMgr.SetCameraController("ThirdPerson");
        gameScene = scene_;

        //DumpSkeletonNames(playerNode);
        renderer.viewports[0].scene = scene_;

        Print("CreateScene() --> total time-cost " + (time.systemTime - t) + " ms.");
    }

    void CreateScene()
    {
        Scene@ scene_ = Scene();
        script.defaultScene = scene_;
        scene_.LoadXML(cache.GetFile("Scenes/2.xml"));
        OnSceneLoaded(scene_);
    }

    void ShowMessage(const String&in msg, bool show)
    {
        Text@ messageText = ui.root.GetChild("message", true);
        if (messageText !is null)
        {
            messageText.text = msg;
            messageText.visible = true;
        }
    }

    void OnKeyDown(int key)
    {
        if (key == KEY_ESCAPE)
        {
            engine.Exit();
            return;

            int oldState = state;
            if (oldState == GAME_PAUSE)
                ChangeSubState(pauseState);
            else
            {
                ChangeSubState(GAME_PAUSE);
                pauseState = oldState;
            }
            return;
        }

        GameState::OnKeyDown(key);
    }

    String GetDebugText()
    {
        return  " name=" + name + " timeInState=" + timeInState + " state=" + state + " pauseState=" + pauseState + "\n";
    }

    void postInit()
    {
        if (bHdr && graphics !is null)
            renderer.viewports[0].renderPath.shaderParameters["AutoExposureAdaptRate"] = 0.6f;
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        for (uint i=0; i<gameObjects.length; ++i)
        {
            Node@ node_ = gameScene.GetNode(gameObjects[i]);
            if (node_ !is null)
            {
                GameObject@ go = cast<GameObject>(node_.scriptObject);
                if (go !is null)
                    go.DebugDraw(debug);
            }
        }
    }
};

class GameFSM : FSM
{
    GameState@ gameState;

    GameFSM()
    {
        Print("GameFSM()");
    }

    ~GameFSM()
    {
        Print("~GameFSM()");
    }

    void Start()
    {
        AddState(LoadingState());
        AddState(TestGameState());
    }

    bool ChangeState(const StringHash&in nameHash)
    {
        bool b = FSM::ChangeState(nameHash);
        if (b)
            @gameState = cast<GameState>(currentState);
        return b;
    }

    void OnSceneLoadFinished(Scene@ _scene)
    {
        if (gameState !is null)
            gameState.OnSceneLoadFinished(_scene);
    }

    void OnAsyncLoadProgress(Scene@ _scene, float progress, int loadedNodes, int totalNodes, int loadedResources, int totalResources)
    {
        if (gameState !is null)
            gameState.OnAsyncLoadProgress(_scene, progress, loadedNodes, totalNodes, loadedResources, totalResources);
    }

    void OnKeyDown(int key)
    {
        if (gameState !is null)
            gameState.OnKeyDown(key);
    }

    void OnSceneTimeScaleUpdated(Scene@ scene, float newScale)
    {
        if (gameState !is null)
            gameState.OnSceneTimeScaleUpdated(scene, newScale);
    }
};


GameFSM@ gGame = GameFSM();