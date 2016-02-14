
enum StateIndicator
{
    STATE_INDICATOR_HIDE,
    STATE_INDICATOR_ATTACK,
};


class HeadIndicator : ScriptObject
{
    Vector3 offset = Vector3(0, 1.0f, 0);
    uint headNodeId;
    int state = -1;

    HeadIndicator()
    {

    }

    ~HeadIndicator()
    {

    }

    void DelayedStart()
    {
        headNodeId = node.GetChild(HEAD, true).id;
    }

    void Stop()
    {

    }

    void Update(float dt)
    {
        Vector3 pos = node.scene.GetNode(headNodeId).worldPosition;

    }

    void ChangeState(int newState)
    {
        if (state == newState)
            return;

        state = newState;
    }
}