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
};

class LoadingState : State
{
    int state;

    LoadingState()
    {
        SetName("LoadingState");
    }

    void Enter(State@ lastState)
    {
        State::Enter(lastState);
        state = LOADING_MOTIONS;
        gMotionMgr.Start();
    }

    void Exit(State@ nextState)
    {
        State::Exit(nextState);
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
        }
        else if (state == LOADING_OTHER)
        {
            gGame.ChangeState("TestGameState");
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

class TestGameState : GameState
{
    TestGameState()
    {
        SetName("TestGameState");
    }

    void Enter(State@ lastState)
    {
        State::Enter(lastState);
        CreateScene();
        SetupViewport();
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