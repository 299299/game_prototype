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

    void OnPlayerDead()
    {

    }

    void OnEnemyKilled(Character@ enemy)
    {

    }

    void OnSceneLoadFinished(Scene@ _scene)
    {

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
            Print("============================== Motion Loading start ==============================");
            if (gMotionMgr.Update(dt))
            {
                gMotionMgr.Finish();
                ChangeSubState(LOADING_RESOURCES);
            }
            Print("============================== Motion Loading end ==============================");

            Text@ text = ui.root.GetChild("loading_text");
            if (text !is null)
                text.text = "Loading Motions, loaded = " + gMotionMgr.processedMotions;
        }
        else if (state == LOADING_RESOURCES)
        {
            Text@ text = ui.root.GetChild("loading_text");
            if (text !is null)
                text.text = "Loading game scene ressources";
        }
        else if (state == LOADING_FINISHED)
        {
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
            if (_scene is gameScene)
            {
                Print("Scene Loading Finished");
                ChangeSubState(LOADING_FINISHED);
            }
        }
    }
};

enum GameSubState
{
    GAME_FADING,
    GAME_RUNNING,
    GAME_FAILED,
    GAME_RESTARTING,
};

class TestGameState : GameState
{
    FadeOverlay@ fade;
    int          state;

    TestGameState()
    {
        SetName("TestGameState");
        @fade = FadeOverlay();
        fade.Init();
    }

    ~TestGameState()
    {
        @fade = null;
    }

    void Enter(State@ lastState)
    {
        State::Enter(lastState);
        state = GAME_FADING;
        if (!engine.headless)
        {
            fade.Show(1.0f);
            fade.StartFadeIn(2.0f);
            gInput.m_freeze = true;
        }
        CreateScene();
        if (!engine.headless)
        {
            Viewport@ viewport = Viewport(script.defaultScene, gCameraMgr.GetCamera());
            renderer.viewports[0] = viewport;
            graphics.windowTitle = "Test";

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
        else
            ChangeSubState(GAME_RUNNING);
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
        else if (state == GAME_FAILED)
        {
            if (gInput.IsAttackPressed() || gInput.IsEvadePressed())
                Restart();
        }
        else if (state == GAME_RESTARTING)
        {
            if (fade.Update(dt))
                ChangeSubState(GAME_RUNNING);
        }
        GameState::Update(dt);
    }

    void ChangeSubState(int newState)
    {
        if (state == newState)
            return;

        Print("TestGameState ChangeSubState from " + state + " to " + newState);
        state = newState;
        timeInState = 0.0f;

        if (newState == GAME_RUNNING)
        {
            Player@ player = GetPlayer();
            if (player !is null)
            {
                player.RemoveFlag(FLAGS_INVINCIBLE);
            }
            gInput.m_freeze = false;
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
        audio.listener = cameraNode.CreateComponent("SoundListener");

        Node@ characterNode = scene_.GetChild(PLAYER_NAME, true);
        // audio.listener = characterNode.CreateComponent("SoundListener");
        characterNode.CreateScriptObject(scriptFile, "Player");
        characterNode.CreateScriptObject(scriptFile, "Ragdoll");

        Node@ thugNode = scene_.GetChild("thug", true);
        thugNode.CreateScriptObject(scriptFile, "Thug");
        thugNode.CreateScriptObject(scriptFile, "Ragdoll");

        Node@ thugNode2 = scene_.GetChild("thug2", true);
        thugNode2.CreateScriptObject(scriptFile, "Thug");
        thugNode2.CreateScriptObject(scriptFile, "Ragdoll");

        Vector3 v_pos = characterNode.worldPosition;
        cameraNode.position = Vector3(v_pos.x, 10.0f, -10);
        cameraNode.LookAt(Vector3(v_pos.x, 4, 0));

        gCameraMgr.Start(cameraNode);
        //gCameraMgr.SetCameraController("Debug");
        gCameraMgr.SetCameraController("ThirdPerson");

        //DumpSkeletonNames(characterNode);
        Print("CreateScene() --> total time-cost " + (time.systemTime - t) + " ms");
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

    void Restart()
    {
        fade.Show(1.0f);
        fade.StartFadeIn(2.0f);
        Player@ player = GetPlayer();
        if (player !is null)
        {
            player.Reset();
            player.AddFlag(FLAGS_INVINCIBLE);
        }
        ChangeSubState(GAME_RESTARTING);
        ShowMessage("", false);
        gInput.m_freeze = true;
    }

    void OnPlayerDead()
    {
        Print("OnPlayerDead!!!!!!!!");
        ChangeSubState(GAME_FAILED);
        ShowMessage("You Died! Press Stride or Jump to restart!", true);
    }

    void OnEnemyKilled(Character@ enemy)
    {

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

    void OnPlayerDead()
    {
        if (gameState !is null)
            gameState.OnPlayerDead();
    }

    void OnEnemyKilled(Character@ enemy)
    {
        if (gameState !is null)
            gameState.OnEnemyKilled(enemy);
    }

    void OnSceneLoadFinished(Scene@ _scene)
    {
        if (gameState !is null)
            gameState.OnSceneLoadFinished(_scene);
    }
};


GameFSM@ gGame = GameFSM();