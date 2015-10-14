
class GameState : State
{
    void OnKeyDown(int key)
    {

    }

    void OnMouseMove(int x, int y)
    {

    }

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

    void OnKeyDown(int key)
    {
        GameState::OnKeyDown(key);
    }

    void OnMouseMove(int x, int y)
    {
        GameState::OnMouseMove(x, y);
    }
};

class GameFSM : FSM
{
    GameState@ gameState;

    void Start()
    {

    }

    void ChangeState(const StringHash&in nameHash)
    {
        FSM::ChangeState(nameHash);
        gameState = cast<GameState@>(currentState);
    }

    void OnKeyDown(int key)
    {
        if (gameState !is null)
            gameState.OnKeyDown(key);
    }

    void OnMouseMove(int x, int y)
    {
        if (gameState !is null)
            gameState.OnMouseMove(x, y);
    }

    void PostRenderUpdate()
    {
        if (gameState !is null)
            gameState.PostRenderUpdate();
    }
};

GameFSM@ gGame = GameFSM();