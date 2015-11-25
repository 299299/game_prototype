// ==============================================
//
//    GameState Class for Game Manager
//
// ==============================================


class GameState : State
{
    void PostRenderUpdate()
    {

    }

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
                engine.Exit();
            else
                console.visible = false;
        }
    }
};

enum LoadSubState
{
    LOADING_MOTIONS,
    LOADING_RESOURCES,
    LOADING_FINISHED,
};

class LoadingState : GameState
{
    int                 state;
    int                 numLoadedResources = 0;
    Scene@              gameScene;

    LoadingState()
    {
        SetName("LoadingState");
    }

    ~LoadingState()
    {

    }

    void CreateLoadingUI()
    {
        CreateLogo();
        Text@ text = ui.root.CreateChild("Text", "loading_text");
        text.SetFont(cache.GetResource("Font", "Fonts/UbuntuMono-R.ttf"), 14);
        text.horizontalAlignment = HA_CENTER;
        text.verticalAlignment = VA_CENTER;
        text.SetPosition(0, 0);
        text.color = Color(0, 1, 0);
        text.textEffect = TE_STROKE;
    }

    void Enter(State@ lastState)
    {
        State::Enter(lastState);
        if (!engine.headless)
            CreateLoadingUI();
        state = LOADING_MOTIONS;
        gMotionMgr.Start();
    }

    void Exit(State@ nextState)
    {
        State::Exit(nextState);
        SetLogoVisible(false);
        Text@ text = ui.root.GetChild("loading_text");
        if (text !is null)
            text.Remove();
    }

    void Update(float dt)
    {
        if (state == LOADING_MOTIONS)
        {
            Text@ text = ui.root.GetChild("loading_text");
            if (text !is null)
                text.text = "Loading Motions, loaded = " + gMotionMgr.processedMotions;

            Print("============================== Motion Loading start ==============================");
            if (gMotionMgr.Update(dt))
            {
                gMotionMgr.Finish();
                ChangeSubState(LOADING_RESOURCES);
                if (text !is null)
                    text.text = "Loading Scene Resources";
            }
            Print("============================== Motion Loading end ==============================");
        }
        else if (state == LOADING_RESOURCES)
        {

        }
        else if (state == LOADING_FINISHED)
        {
            if (gameScene !is null)
                gameScene.Remove();
            gameScene = null;
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
            gameScene = Scene();
            gameScene.LoadAsyncXML(cache.GetFile("Scenes/1.xml"), LOAD_RESOURCES_ONLY);
        }
    }

    void OnSceneLoadFinished(Scene@ _scene)
    {
        if (state == LOADING_RESOURCES)
        {
            Print("Scene Loading Finished");
            ChangeSubState(LOADING_FINISHED);
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
    Array<Vector3>      enemyResetPositions;
    Array<Quaternion>   enemyResetRotations;

    FadeOverlay@        fade;
    TextMenu@           pauseMenu;
    int                 state = -1;
    int                 lastState = -1;
    int                 maxKilled = 5;

    TestGameState()
    {
        SetName("TestGameState");
        @fade = FadeOverlay();
        @pauseMenu = TextMenu("Fonts/UbuntuMono-R.ttf", 30);
        pauseMenu.texts.Push("RESUME");
        pauseMenu.texts.Push("EXIT");
        fade.Init();
    }

    ~TestGameState()
    {
        @fade = null;
        @pauseMenu = null;
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
            int height = graphics.height / 22;
            if (height > 64)
                height = 64;
            Text@ messageText = ui.root.CreateChild("Text", "message");
            messageText.SetFont(cache.GetResource("Font", "Fonts/UbuntuMono-R.ttf"), 12);
            messageText.SetAlignment(HA_CENTER, VA_CENTER);
            messageText.SetPosition(0, -height * 2);
            messageText.color = Color(1, 0, 0);
            messageText.visible = false;
        }
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
            if (gInput.IsAttackPressed() || gInput.IsEvadePressed())
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
                ChangeSubState(GAME_RUNNING);
            else if (selection == 1)
                engine.Exit();
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
        if (newState == GAME_RUNNING)
        {
            Player@ player = GetPlayer();
            if (player !is null)
            {
                player.RemoveFlag(FLAGS_INVINCIBLE);
            }
            gInput.m_freeze = false;
            script.defaultScene.updateEnabled = true;

            VariantMap data;
            data[NAME] = CHANGE_STATE;
            data[VALUE] = StringHash("ThirdPerson");
            SendEvent("CameraEvent", data);
        }
        else if (newState == GAME_FADING || newState == GAME_RESTARTING)
        {
            fade.Show(1.0f);
            fade.StartFadeIn(2.0f);
            gInput.m_freeze = true;
            Player@ player = GetPlayer();
            if (newState == GAME_RESTARTING)
            {
                EnemyManager@ em = GetEnemyMgr();
                if (em !is null)
                    em.RemoveAll();

                if (player !is null)
                    player.Reset();

                ResetEnemies();
            }

            if (player !is null)
                player.AddFlag(FLAGS_INVINCIBLE);
        }
        else if (newState == GAME_PAUSE)
        {
            // gInput.m_freeze = true;
            script.defaultScene.updateEnabled = false;
            pauseMenu.Add();
        }
        else if (newState == GAME_WIN)
        {
            ShowMessage("You Win! Press Stride or Evade to restart!", true);
        }
        else if (newState == GAME_FAIL)
        {
            ShowMessage("You Died! Press Stride or Evade to restart!", true);
        }
    }

    void CreateViewPort()
    {
        Viewport@ viewport = Viewport(script.defaultScene, gCameraMgr.GetCamera());
        renderer.viewports[0] = viewport;
        graphics.windowTitle = "Test";
        if (bHdr)
        {
            RenderPath@ renderpath = viewport.renderPath.Clone();
            renderpath.Load(cache.GetResource("XMLFile","RenderPaths/ForwardHWDepth.xml"));
            renderpath.Append(cache.GetResource("XMLFile","PostProcess/AutoExposure.xml"));
            renderpath.Append(cache.GetResource("XMLFile","PostProcess/BloomHDR.xml"));
            viewport.renderPath = renderpath;
        }
    }

    void CreateScene()
    {
        uint t = time.systemTime;
        Scene@ scene_ = Scene();
        script.defaultScene = scene_;
        scene_.LoadXML(cache.GetFile("Scenes/1.xml"));
        Print("loading-scene XML --> time-cost " + (time.systemTime - t) + " ms");

        scene_.CreateScriptObject(scriptFile, "EnemyManager");

        Node@ cameraNode = scene_.CreateChild(CAMERA_NAME);
        Camera@ cam = cameraNode.CreateComponent("Camera");
        // audio.listener = cameraNode.CreateComponent("SoundListener");

        Node@ characterNode = scene_.GetChild(PLAYER_NAME, true);
        audio.listener = characterNode.GetChild("Bip01_Head", true).CreateComponent("SoundListener");

        characterNode.CreateScriptObject(scriptFile, "Player");
        characterNode.CreateScriptObject(scriptFile, "Ragdoll");

        for (uint i=0; i<scene_.numChildren; ++i)
        {
            Node@ _node = scene_.children[i];
            if (_node.name.StartsWith("thug"))
            {
                _node.CreateScriptObject(scriptFile, "Thug");
                _node.CreateScriptObject(scriptFile, "Ragdoll");
                enemyResetPositions.Push(_node.worldPosition);
                enemyResetRotations.Push(_node.worldRotation);
            }
        }

        maxKilled = enemyResetRotations.length;

        Vector3 v_pos = characterNode.worldPosition;
        cameraNode.position = Vector3(v_pos.x, 10.0f, -10);
        cameraNode.LookAt(Vector3(v_pos.x, 4, 0));

        gCameraMgr.Start(cameraNode);
        //gCameraMgr.SetCameraController("Debug");
        gCameraMgr.SetCameraController("ThirdPerson");

        Node@ floor = scene_.GetChild("floor", true);
        StaticModel@ model = floor.GetComponent("StaticModel");
        WORLD_HALF_SIZE = model.boundingBox.halfSize * floor.worldScale;
        WORLD_SIZE = WORLD_HALF_SIZE * 2;

        //DumpSkeletonNames(characterNode);
        Print("CreateScene() --> total time-cost " + (time.systemTime - t) + " ms WORLD_SIZE=" + WORLD_SIZE.ToString());
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

    void ResetEnemies()
    {
        EnemyManager@ em = GetEnemyMgr();
        for (uint i=0; i<enemyResetPositions.length; ++i)
        {
            em.CreateEnemy(enemyResetPositions[i], enemyResetRotations[i], "Thug");
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

    void ChangeState(const StringHash&in nameHash)
    {
        FSM::ChangeState(nameHash);
        @gameState = cast<GameState>(currentState);
    }

    void PostRenderUpdate()
    {
        if (gameState !is null)
            gameState.PostRenderUpdate();
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
};


GameFSM@ gGame = GameFSM();