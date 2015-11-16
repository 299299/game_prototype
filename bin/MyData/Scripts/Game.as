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
            SetupViewport();
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
            {
                ChangeSubState(GAME_RUNNING);
                gInput.m_freeze = false;
            }
        }
        GameState::Update(dt);
    }

    void ChangeSubState(int newState)
    {
        if (state == newState)
            return;

        Print("TestGameState ChangeSubState from " + state + " to " + newState);
        state = newState;
    }

    void OnPlayerDead()
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

    void OnSceneLoadFinished(Scene@ _scene)
    {
        if (gameState !is null)
            gameState.OnSceneLoadFinished(_scene);
    }
};


GameFSM@ gGame = GameFSM();