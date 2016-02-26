// ==============================================
//
//    GameState Class for Game Manager
//
// ==============================================


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

    void OnKeyDown(int key)
    {
        if (key == KEY_ESC)
        {
             if (!console.visible)
                OnESC();
            else
                console.visible = false;
        }
    }

    void OnPlayerStatusUpdate(Player@ player)
    {

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
        Print("LoadingState()");
    }

    ~LoadingState()
    {
        Print("~LoadingState()");
        preloadScene = null;
    }

    void CreateLoadingUI()
    {
        Texture2D@ logoTexture = cache.GetResource("Texture2D", "Textures/ulogo.jpg");
        if (logoTexture !is null)
        {
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
        }

        Text@ text = ui.root.CreateChild("Text", "loading_text");
        text.SetFont(cache.GetResource("Font", UI_FONT), UI_FONT_SIZE);
        text.SetAlignment(HA_LEFT, VA_BOTTOM);
        text.SetPosition(2, 0);
        text.color = Color(1, 1, 1);
        text.textEffect = TE_STROKE;
        text.AddTag("TAG_LOADING");

        Texture2D@ loadingTexture = cache.GetResource("Texture2D", "Textures/Loading.tga");
        if (loadingTexture !is  null)
        {
            Sprite@ loadingSprite = ui.root.CreateChild("Sprite", "loading_bg");
            loadingSprite.texture = loadingTexture;
            int textureWidth = loadingTexture.width;
            int textureHeight = loadingTexture.height;
            loadingSprite.SetSize(textureWidth, textureHeight);
            loadingSprite.SetPosition(graphics.width/2 - textureWidth/2, graphics.height/2 - textureHeight/2);
            loadingSprite.priority = -100;
            loadingSprite.AddTag("TAG_LOADING");
        }
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
            preloadScene.LoadAsyncXML(cache.GetFile("Scenes/1.xml"), LOAD_RESOURCES_ONLY);
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
    GAME_FAIL,
    GAME_RESTARTING,
    GAME_PAUSE,
    GAME_WIN,
};

class TestGameState : GameState
{
    Scene@              gameScene;

    FadeOverlay@        fade;
    TextMenu@           pauseMenu;
    int                 state = -1;
    int                 lastState = -1;
    int                 maxKilled = 5;

    bool                postInited = false;

    TestGameState()
    {
        SetName("TestGameState");
        Print("TestGameState()");
        @fade = FadeOverlay();
        @pauseMenu = TextMenu(UI_FONT, UI_FONT_SIZE);
        pauseMenu.texts.Push("RESUME");
        pauseMenu.texts.Push("EXIT");
        fade.Init();
    }

    ~TestGameState()
    {
        @fade = null;
        @pauseMenu = null;
        gameScene = null;
        Print("~TestGameState()");
    }

    void Enter(State@ lastState)
    {
        state = -1;
        State::Enter(lastState);
        ChangeSubState(GAME_FADING);
        CreateScene();
        if (!engine.headless)
        {
            CreateViewPort();
            CreateUI();
        }
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
        if (state == GAME_FADING)
        {
            if (fade.Update(dt))
                ChangeSubState(GAME_RUNNING);
        }
        else if (state == GAME_FAIL || state == GAME_WIN)
        {
            if (gInput.IsAttackPressed())
            {
                ChangeSubState(GAME_RESTARTING);
                ShowMessage("", false);
            }
        }
        else if (state == GAME_RESTARTING)
        {
            if (fade.Update(dt))
                ChangeSubState(GAME_RUNNING);
        }
        else if (state == GAME_PAUSE)
        {
            int selection = pauseMenu.Update(dt);
            if (selection == 0)
                ChangeSubState(lastState);
            else if (selection == 1)
                engine.Exit();
        }
        else if (state == GAME_RUNNING) {
            if (!postInited) {
                if (timeInState > 2.0f) {
                    postInit();
                    postInited = true;
                }
            }
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

        if (oldState == GAME_PAUSE)
            script.defaultScene.updateEnabled = true;

        pauseMenu.Remove();

        Player@ player = GetPlayer();

        if (newState == GAME_RUNNING)
        {
            if (player !is null)
                player.RemoveFlag(FLAGS_INVINCIBLE);

            freezeInput = false;
            script.defaultScene.updateEnabled = true;

            VariantMap data;
            data[NAME] = CHANGE_STATE;
            data[VALUE] = StringHash("ThirdPerson");
            SendEvent("CameraEvent", data);
        }
        else if (newState == GAME_FADING || newState == GAME_RESTARTING)
        {
            if (oldState != GAME_PAUSE)
            {
                fade.Show(1.0f);
                fade.StartFadeIn(2.0f);
            }

            freezeInput = true;
            if (newState == GAME_RESTARTING)
            {
                EnemyManager@ em = GetEnemyMgr();
                if (em !is null)
                {
                    em.RemoveAll();
                    em.CreateEnemies();
                }

                if (player !is null)
                    player.Reset();
            }

            if (player !is null)
                player.AddFlag(FLAGS_INVINCIBLE);
        }
        else if (newState == GAME_PAUSE)
        {
            script.defaultScene.updateEnabled = false;
            pauseMenu.Add();
        }
        else if (newState == GAME_WIN)
        {
            ShowMessage("You Win! Press Stride to restart!", true);
            if (player !is null)
                player.SetTarget(null);
        }
        else if (newState == GAME_FAIL)
        {
            ShowMessage("You Died! Press Stride to restart!", true);
            if (player !is null)
                player.SetTarget(null);
        }
    }

    void CreateViewPort()
    {
        Viewport@ viewport = Viewport(script.defaultScene, gCameraMgr.GetCamera());
        renderer.viewports[0] = viewport;
        RenderPath@ renderpath = viewport.renderPath.Clone();
        if (render_features & RF_HDR != 0)
        {
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
        viewport.renderPath = renderpath;
        SetColorGrading(colorGradingIndex);
    }

    void CreateScene()
    {
        uint t = time.systemTime;
        Scene@ scene_ = Scene();
        script.defaultScene = scene_;
        scene_.LoadXML(cache.GetFile("Scenes/1.xml"));
        Print("loading-scene XML --> time-cost " + (time.systemTime - t) + " ms");

        EnemyManager@ em = cast<EnemyManager>(scene_.CreateScriptObject(scriptFile, "EnemyManager"));

        Node@ cameraNode = scene_.CreateChild(CAMERA_NAME);
        Camera@ cam = cameraNode.CreateComponent("Camera");
        cam.fov = BASE_FOV;
        cameraId = cameraNode.id;

        // audio.listener = cameraNode.CreateComponent("SoundListener");

        Node@ tmpPlayerNode = scene_.GetChild("player", true);
        Vector3 playerPos;
        Quaternion playerRot;
        if (tmpPlayerNode !is null)
        {
            playerPos = tmpPlayerNode.worldPosition;
            playerRot = tmpPlayerNode.worldRotation;
            playerPos.y = 0;
            tmpPlayerNode.Remove();
        }

        Node@ playerNode;
        if (playerType == 0)
            playerNode = CreateCharacter("player", "bruce_w", "Bruce", playerPos, playerRot);
        else if (playerType == 1)
            playerNode = CreateCharacter("player", "catwoman", "Catwoman", playerPos, playerRot);

        audio.listener = playerNode.GetChild(HEAD, true).CreateComponent("SoundListener");
        playerId = playerNode.id;

        // preprocess current scene
        Array<uint> nodes_to_remove;
        int enemyNum = 0;
        for (uint i=0; i<scene_.numChildren; ++i)
        {
            Node@ _node = scene_.children[i];
            Print("_node.name=" + _node.name);
            if (_node.name.StartsWith("thug"))
            {
                nodes_to_remove.Push(_node.id);
                if (enemyNum >= test_enemy_num_override)
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
        gCameraMgr.SetCameraController("ThirdPerson");

        Node@ floor = scene_.GetChild("floor", true);
        StaticModel@ model = floor.GetComponent("StaticModel");
        // WORLD_HALF_SIZE = model.boundingBox.halfSize * floor.worldScale;

        gameScene = scene_;

        //DumpSkeletonNames(playerNode);
        Print("CreateScene() --> total time-cost " + (time.systemTime - t) + " ms WORLD_SIZE=" + (WORLD_HALF_SIZE * 2).ToString());
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
            Print("OnPlayerDead!!!!!!!!");
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
                        Print("WIN!!!!!!!!");
                        ChangeSubState(GAME_WIN);
                    }
                }
            }
        }
    }

    void OnKeyDown(int key)
    {
        if (key == KEY_ESC)
        {
            int oldState = state;
            if (oldState == GAME_PAUSE)
                ChangeSubState(lastState);
            else
            {
                ChangeSubState(GAME_PAUSE);
                lastState = oldState;
            }
            return;
        }

        GameState::OnKeyDown(key);
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
        Print("Game::ApplyBGMScale " + scale);
        SoundSource@ s = musicNode.GetComponent("SoundSource");
        if (s is null)
            return;
        s.frequency = BGM_BASE_FREQ * scale;
    }

    String GetDebugText()
    {
        return  " name=" + name + " timeInState=" + timeInState + " state=" + state + " lastState=" + lastState + "\n";
    }

    void postInit()
    {
        if (bHdr && graphics !is null)
            renderer.viewports[0].renderPath.shaderParameters["AutoExposureAdaptRate"] = 0.6f;
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

    void OnKeyDown(int key)
    {
        if (gameState !is null)
            gameState.OnKeyDown(key);
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