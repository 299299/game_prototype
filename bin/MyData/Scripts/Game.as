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

class TestGameState : GameState
{
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

    }

    void ChangeState(const StringHash&in nameHash)
    {
        FSM::ChangeState(nameHash);
        gameState = cast<GameState@>(currentState);
    }

    void PostRenderUpdate()
    {
        if (gameState !is null)
            gameState.PostRenderUpdate();
    }
};

GameFSM@ gGame = GameFSM();