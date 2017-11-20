// ==============================================
//
//    GameState Class for Game Manager
//
// ==============================================

bool reflection = false;

class GameState : State
{
    void OnCharacterKilled(Character@ killer, Character@ dead)
    {
    }

    void OnSceneLoadFinished(Scene@ _scene)
    {
    }

    void OnAsyncLoadProgress(Scene@ _scene, float progress, int loadedNodes, int totalNodes, int loadedResources, int totalResources)
    {
    }

    void OnPlayerStatusUpdate(Player@ player)
    {
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
                LogPrint("============================== Motion Loading start ==============================");

            if (gMotionMgr.Update(dt))
            {
                gMotionMgr.Finish();
                ChangeSubState(LOADING_FINISHED);
                if (text !is null)
                    text.text = "Loading Scene Resources";
            }

            if (d_log)
                LogPrint("============================== Motion Loading end ==============================");
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

        LogPrint("LoadingState ChangeSubState from " + state + " to " + newState);
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
            LogPrint("Scene Loading Finished");
            ChangeSubState(LOADING_MOTIONS);
        }
    }

    void OnAsyncLoadProgress(Scene@ _scene, float progress, int loadedNodes, int totalNodes, int loadedResources, int totalResources)
    {
        Text@ text = ui.root.GetChild("loading_text");
        if (text !is null)
            text.text = "Loading scene ressources progress=" + progress + " resources:" + loadedResources + "/" + totalResources;
    }
};

enum GameSubState
{
    GAME_FADING,
    GAME_RUNNING,
    GAME_FAIL,
    GAME_RESTARTING,
    GAME_PAUSE,
    GAME_WIN,
};

class TestGameState : GameState
{
    Scene@              gameScene;
    TextMenu@           pauseMenu;
    BorderImage@        fullscreenUI;

    int                 state = -1;
    int                 pauseState = -1;
    int                 maxKilled = 5;

    float               fadeTime;
    float               fadeInDuration = 1.0f;
    float               restartDuration = 5.0f;

    bool                postInited = false;

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
        CreateScene();
        CreateViewPort();
        CreateUI();
        PostCreate();
        ChangeSubState(GAME_FADING);
    }

    void PostCreate()
    {
        if (reflection)
        {
            Node@ floorNode = gameScene.GetChild("floor", true);
            StaticModel@ floor = floorNode.GetComponent("StaticModel");
            String matName = "Materials/FloorPlane.xml";
            floor.material = cache.GetResource("Material", matName);
            // Set a different viewmask on the water plane to be able to hide it from the reflection camera
            floor.viewMask = 0x80000000;

            Camera@ camera = GetCamera();
            // Create a mathematical plane to represent the water in calculations
            Plane waterPlane = Plane(floorNode.worldRotation * Vector3(0.0f, 1.0f, 0.0f), floorNode.worldPosition);
            // Create a downward biased plane for reflection view clipping. Biasing is necessary to avoid too aggressive clipping
            Plane waterClipPlane = Plane(floorNode.worldRotation * Vector3(0.0f, 1.0f, 0.0f), floorNode.worldPosition - Vector3(0.0f, 0.1f, 0.0f));

            // Create camera for water reflection
            // It will have the same farclip and position as the main viewport camera, but uses a reflection plane to modify
            // its position when rendering
            Node@ reflectionCameraNode = camera.node.CreateChild("reflection");
            Camera@ reflectionCamera = reflectionCameraNode.CreateComponent("Camera");
            reflectionCamera.farClip = 750.0;
            reflectionCamera.viewMask = 0x7fffffff; // Hide objects with only bit 31 in the viewmask (the water plane)
            reflectionCamera.autoAspectRatio = false;
            reflectionCamera.useReflection = true;
            reflectionCamera.reflectionPlane = waterPlane;
            reflectionCamera.useClipping = true; // Enable clipping of geometry behind water plane
            reflectionCamera.clipPlane = waterClipPlane;
            // The water reflection texture is rectangular. Set reflection camera aspect ratio to match
            reflectionCamera.aspectRatio = float(graphics.width) / float(graphics.height);
            // View override flags could be used to optimize reflection rendering. For example disable shadows
            reflectionCamera.viewOverrideFlags = VO_DISABLE_SHADOWS | VO_DISABLE_OCCLUSION | VO_LOW_MATERIAL_QUALITY;

            // Create a texture and setup viewport for water reflection. Assign the reflection texture to the diffuse
            // texture unit of the water material
            int texSize = 1024;
            Texture2D@ renderTexture = Texture2D();
            renderTexture.SetSize(texSize, texSize, GetRGBFormat(), TEXTURE_RENDERTARGET);
            renderTexture.filterMode = FILTER_BILINEAR;
            RenderSurface@ surface = renderTexture.renderSurface;
            Viewport@ rttViewport = Viewport(gameScene, reflectionCamera);
            surface.viewports[0] = rttViewport;
            Material@ waterMat = cache.GetResource("Material", matName);
            waterMat.textures[TU_DIFFUSE] = renderTexture;
        }

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

        Text@ statusText = ui.root.CreateChild("Text", "status");
        statusText.SetFont(cache.GetResource("Font", UI_FONT), UI_FONT_SIZE);
        statusText.SetAlignment(HA_LEFT, VA_TOP);
        statusText.SetPosition(0, 0);
        statusText.color = Color(1, 1, 0);
        statusText.visible = true;
        OnPlayerStatusUpdate(GetPlayer());
    }

    void Exit(State@ nextState)
    {
        State::Exit(nextState);
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

        case GAME_RESTARTING:
            {
                EnemyManager@ em = GetEnemyMgr();
                if (fullscreenUI.opacity > 0.95f && em.enemyList.empty)
                {
                    em.CreateEnemies();
                }

                float t = fullscreenUI.GetAttributeAnimationTime("Opacity");
                if (t + 0.05f >= fadeTime)
                {
                    fullscreenUI.visible = false;
                    ChangeSubState(GAME_RUNNING);
                }
            }
            break;

        case GAME_FAIL:
        case GAME_WIN:
            {
                if (timeInState > 5.0 && gInput.IsTouching())
                {
                    ChangeSubState(GAME_RESTARTING);
                    ShowMessage("", false);
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
        LogPrint("TestGameState ChangeSubState from " + oldState + " to " + newState);
        state = newState;
        timeInState = 0.0f;

        script.defaultScene.updateEnabled = !(newState == GAME_PAUSE);
        fullscreenUI.SetAttributeAnimationSpeed("Opacity", newState == GAME_PAUSE ? 0.0f : 1.0f);

        if (newState == GAME_PAUSE)
            pauseMenu.Add();
        else
            pauseMenu.Remove();

        Player@ player = GetPlayer();
        EnemyManager@ em = GetEnemyMgr();

        gInput.ShowHideUI(false);

        switch (newState)
        {
        case GAME_RUNNING:
            {
                if (player !is null)
                    player.RemoveFlag(FLAGS_INVINCIBLE);

                freezeInput = false;
                gCameraMgr.SetCameraController("LookAt");
                gInput.ShowHideUI(true);
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
                if (player !is null)
                    player.AddFlag(FLAGS_INVINCIBLE);
            }
            break;

        case GAME_RESTARTING:
            {
                if (oldState != GAME_PAUSE)
                {
                    ValueAnimation@ alphaAnimation = ValueAnimation();
                    alphaAnimation.SetKeyFrame(0.0f, Variant(0.0f));
                    alphaAnimation.SetKeyFrame(restartDuration/2, Variant(1.0f));
                    alphaAnimation.SetKeyFrame(restartDuration, Variant(0.0f));
                    fadeTime = restartDuration;
                    fullscreenUI.opacity = 0.0f;
                    fullscreenUI.visible = true;
                    fullscreenUI.SetAttributeAnimation("Opacity", alphaAnimation, WM_ONCE);
                }

                freezeInput = true;
                if (em !is null)
                    em.RemoveAll();

                if (player !is null)
                {
                    player.Reset();
                    player.AddFlag(FLAGS_INVINCIBLE);
                }
            }
            break;

        case GAME_PAUSE:
            {
                // ....
            }
            break;

        case GAME_WIN:
            {
                ShowMessage("You Win! Press Stride to restart!", true);
                if (player !is null)
                    player.SetTarget(null);
            }
            break;

        case GAME_FAIL:
            {
                ShowMessage("You Died! Press Stride to restart!", true);
                if (player !is null)
                    player.SetTarget(null);
            }
            break;
        }
    }

    void CreateViewPort()
    {
        Viewport@ viewport = Viewport(script.defaultScene, gCameraMgr.GetCamera());
        renderer.viewports[0] = viewport;
        RenderPath@ renderpath = viewport.renderPath.Clone();
        if (render_features & RF_HDR != 0)
        {
            renderer.hdrRendering = true;
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
            // renderpath.Append(cache.GetResource("XMLFile","PostProcess/ColorCorrection.xml"));
        }
        if (render_features & RF_AA != 0)
            renderpath.Append(cache.GetResource("XMLFile", "PostProcess/FXAA2.xml"));
        viewport.renderPath = renderpath;
    }

    void CreateScene()
    {
        uint t = time.systemTime;
        Scene@ scene_ = Scene();
        script.defaultScene = scene_;
        scene_.LoadXML(cache.GetFile("Scenes/1.xml"));
        LogPrint("loading-scene XML --> time-cost " + (time.systemTime - t) + " ms");

        EnemyManager@ em = cast<EnemyManager>(scene_.CreateScriptObject(scriptFile, "EnemyManager"));

        Node@ cameraNode = scene_.CreateChild(CAMERA_NAME);
        Camera@ cam = cameraNode.CreateComponent("Camera");
        cam.fov = BASE_FOV;
        cameraId = cameraNode.id;

        Node@ floor = scene_.GetChild("floor", true);
        StaticModel@ model = floor.GetComponent("StaticModel");
        // WORLD_HALF_SIZE = model.boundingBox.halfSize * floor.worldScale;

        if (!scene_.HasComponent("DynamicNavigationMesh"))
        {
            LogPrint("Building DynamicNavigationMesh!");
            // Create a DynamicNavigationMesh component to the scene root
            DynamicNavigationMesh@ navMesh = scene_.CreateComponent("DynamicNavigationMesh");
            // Set small tiles to show navigation mesh streaming
            navMesh.tileSize = 64;
            // Enable drawing debug geometry for obstacles and off-mesh connections
            navMesh.drawObstacles = true;
            navMesh.drawOffMeshConnections = true;
            // Set the agent height large enough to exclude the layers under boxes
            navMesh.agentHeight = 5.0;
            // Set nav mesh cell height to minimum (allows agents to be grounded)
            // Create a Navigable component to the scene root. This tags all of the geometry in the scene as being part of the
            // navigation mesh. By default this is recursive, but the recursion could be turned off from Navigable
            floor.CreateComponent("Navigable");
            // Add padding to the navigation mesh in Y-direction so that we can add objects on top of the tallest boxes
            // in the scene and still update the mesh correctly
            // navMesh.padding = Vector3(0.0f, 10.0f, 0.0f);
            // Now build the navigation geometry. This will take some time. Note that the navigation mesh will prefer to use
            // physics geometry from the scene nodes, as it often is simpler, but if it can not find any (like in this example)
            // it will use renderable geometry instead
            navMesh.Build();
        }

        CrowdManager@ crowdManager = scene_.GetComponent("CrowdManager");
        if (crowdManager is null)
            crowdManager = scene_.CreateComponent("CrowdManager");
        CrowdObstacleAvoidanceParams params = crowdManager.GetObstacleAvoidanceParams(0);
        // Set the params to "High (66)" setting
        params.velBias = 0.5f;
        params.adaptiveDivs = 7;
        params.adaptiveRings = 3;
        params.adaptiveDepth = 3;
        crowdManager.SetObstacleAvoidanceParams(0, params);

        Node@ tmpPlayerNode = scene_.GetChild("player", true);
        Vector3 playerPos;
        Quaternion playerRot;
        if (tmpPlayerNode !is null)
        {
            playerPos = tmpPlayerNode.worldPosition;
            playerRot = tmpPlayerNode.worldRotation;
            if (collision_type == 0)
                playerPos.y = 0;
            tmpPlayerNode.Remove();
        }

        Node@ playerNode = CreateCharacter("player", "bruce_w", "Bruce", playerPos, playerRot);
        playerNode.AddTag(PLAYER_TAG);
        audio.listener = playerNode.GetChild(HEAD, true).CreateComponent("SoundListener");
        playerId = playerNode.id;

        // preprocess current scene
        Array<uint> nodes_to_remove;
        int enemyNum = 0;
        for (uint i=0; i<scene_.numChildren; ++i)
        {
            Node@ _node = scene_.children[i];
            LogPrint("_node.name=" + _node.name);
            if (_node.name.StartsWith("thug"))
            {
                nodes_to_remove.Push(_node.id);
                if (test_enemy_num_override > 0 && enemyNum >= test_enemy_num_override)
                    continue;
                Vector3 v = _node.worldPosition;
                v.y = 0;
                em.enemyResetPositions.Push(v);
                em.enemyResetRotations.Push(_node.worldRotation);
                ++enemyNum;
            }
            else if (_node.name.StartsWith("preload_"))
                nodes_to_remove.Push(_node.id);
            else if (_node.name.StartsWith("light"))
            {
                Light@ light = _node.GetComponent("Light");
                if (render_features & RF_SHADOWS == 0)
                    light.castShadows = false;
                light.shadowBias = BiasParameters(0.00025f, 0.5f);
                light.shadowCascade = CascadeParameters(10.0f, 50.0f, 200.0f, 0.0f, 0.8f);
            }
        }

        for (uint i=0; i<nodes_to_remove.length; ++i)
            scene_.GetNode(nodes_to_remove[i]).Remove();

        em.CreateEnemies();

        maxKilled = em.enemyResetRotations.length;

        Vector3 v_pos = playerNode.worldPosition;
        cameraNode.position = Vector3(v_pos.x, 10.0f, -10);
        cameraNode.LookAt(Vector3(v_pos.x, 4, 0));

        gCameraMgr.Start(cameraNode);
        //gCameraMgr.SetCameraController("Debug");
        gCameraMgr.SetCameraController("LookAt");

        gameScene = scene_;

        Node@ lightNode = scene_.GetChild("light");
        if (lightNode !is null)
        {
            Follow@ f = cast<Follow>(lightNode.CreateScriptObject(scriptFile, "Follow"));
            f.toFollow = playerId;
            f.offset = Vector3(0, 10, 0);
        }

        //DumpSkeletonNames(playerNode);
        LogPrint("CreateScene() --> total time-cost " + (time.systemTime - t) + " ms WORLD_SIZE=" + (WORLD_HALF_SIZE * 2).ToString());
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

    void OnCharacterKilled(Character@ killer, Character@ dead)
    {
        if (dead.side == 1)
        {
            LogPrint("OnPlayerDead!!!!!!!!");
            ChangeSubState(GAME_FAIL);
        }

        if (killer !is null)
        {
            if (killer.side == 1)
            {
                Player@ player = cast<Player>(killer);
                if (player !is null)
                {
                    if (player.killed >= maxKilled)
                    {
                        LogPrint("WIN!!!!!!!!");
                        ChangeSubState(GAME_WIN);
                    }
                }
            }
        }
    }

    void OnPlayerStatusUpdate(Player@ player)
    {
        if (player is null)
            return;
        Text@ statusText = ui.root.GetChild("status", true);
        if (statusText !is null)
        {
            statusText.text = "HP: " + player.health + " COMBO: " + player.combo + " KILLED:" + player.killed;
        }

        // ApplyBGMScale(gameScene.timeScale *  GetPlayer().timeScale);
    }

    void OnSceneTimeScaleUpdated(Scene@ scene, float newScale)
    {
        if (gameScene !is scene)
            return;
        // ApplyBGMScale(newScale *  GetPlayer().timeScale);
    }

    void ApplyBGMScale(float scale)
    {
        if (musicNode is null)
            return;
        LogPrint("Game::ApplyBGMScale " + scale);
        SoundSource@ s = musicNode.GetComponent("SoundSource");
        if (s is null)
            return;
        s.frequency = BGM_BASE_FREQ * scale;
    }

    String GetDebugText()
    {
        return  " name=" + name + " timeInState=" + timeInState + " state=" + state + " pauseState=" + pauseState + "\n";
    }

    void postInit()
    {
        if (render_features & RF_HDR != 0)
            renderer.viewports[0].renderPath.shaderParameters["AutoExposureAdaptRate"] = 0.6f;
    }
};

class GameFSM : FSM
{
    GameState@ gameState;

    GameFSM()
    {
        LogPrint("GameFSM()");
    }

    ~GameFSM()
    {
        LogPrint("~GameFSM()");
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

    void OnCharacterKilled(Character@ killer, Character@ dead)
    {
        if (gameState !is null)
            gameState.OnCharacterKilled(killer, dead);
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

    void OnPlayerStatusUpdate(Player@ player)
    {
        if (gameState !is null)
            gameState.OnPlayerStatusUpdate(player);
    }

    void OnSceneTimeScaleUpdated(Scene@ scene, float newScale)
    {
        if (gameState !is null)
            gameState.OnSceneTimeScaleUpdated(scene, newScale);
    }
};


GameFSM@ gGame = GameFSM();