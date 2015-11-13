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
};

enum LoadSubState
{
    LOADING_MOTIONS,
    LOADING_OTHER,
    LOADING_FADE,
};

class LoadingState : State
{
    int state;

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
                ChangeSubState(LOADING_OTHER);
            }
            Print("============================== Motion Loading end ==============================");

            Text@ text = ui.root.GetChild("loading_text");
            if (text !is null)
                text.text = "Loading Motions, loaded = " + gMotionMgr.processedMotions;
        }
        else if (state == LOADING_OTHER)
        {
            gGame.ChangeState("TestGameState");
        }
        else if (state == LOADING_FADE)
        {

        }
    }

    void ChangeSubState(int newState)
    {
        if (state == newState)
            return;

        Print("LoadingState ChangeSubState from " + state + " to " + newState);
        state = newState;
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
};

class PlayingState : GameState
{
    PlayingState()
    {
        SetName("PlayingState");
    }

    void Enter(State@ lastState)
    {
        State::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        State::Exit(nextState);
    }

    void Update(float dt)
    {
        GameState::Update(dt);
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
        AddState(PlayingState());
    }

    void ChangeState(const StringHash&in nameHash)
    {
        FSM::ChangeState(nameHash);
        @gameState = cast<GameState@>(currentState);
    }

    void PostRenderUpdate()
    {
        if (gameState !is null)
            gameState.PostRenderUpdate();
    }
};

GameFSM@ gGame = GameFSM();