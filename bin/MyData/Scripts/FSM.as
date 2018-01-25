// ==============================================
//
//    State & State Machine Base Class
//
// ==============================================

class State
{
    String name;
    StringHash nameHash;

    float timeInState;

    State()
    {
        //LogPrint("State()");
    }

    ~State()
    {
        //LogPrint("~State() " + String(name));
    }

    void Enter(State@ lastState)
    {
        timeInState = 0;
    }

    void Exit(State@ nextState)
    {
        timeInState = 0;
    }

    void Update(float dt)
    {
        timeInState += dt;
    }

    void FixedUpdate(float dt)
    {

    }

    void DebugDraw(DebugRenderer@ debug)
    {

    }

    String GetDebugText()
    {
        return " name=" + name + " timeInState=" + String(timeInState);
    }

    void SetName(const String&in s)
    {
        name = s;
        nameHash = StringHash(s);
    }

    bool CanReEntered()
    {
        return false;
    }
};


class FSM
{
    Array<State@>           states;
    State@                  currentState;
    String                  queueState;

    FSM()
    {
    }

    ~FSM()
    {
        //LogPrint("~FSM() ");
        @currentState = null;
        states.Clear();
    }

    void AddState(State@ state)
    {
        states.Push(state);
    }

    State@ FindState(const String&in name)
    {
        return FindState(StringHash(name));
    }

    State@ FindState(const StringHash&in nameHash)
    {
        for (uint i=0; i<states.length; ++i)
        {
            if (states[i].nameHash == nameHash)
                return states[i];
        }
        return null;
    }

    bool ChangeState(const String&in name)
    {
        State@ newState = FindState(StringHash(name));

        if (newState is null)
        {
            LogPrint("new-state not found " + name);
            return false;
        }

        if (currentState is newState) {
            // LogPrint("same state !!!");
            if (!currentState.CanReEntered())
                return false;
            currentState.Exit(newState);
            currentState.Enter(newState);
        }

        State@ oldState = currentState;
        if (oldState !is null)
            oldState.Exit(newState);

        if (newState !is null)
            newState.Enter(oldState);

        @currentState = @newState;

        String oldStateName = "null";
        if (oldState !is null)
            oldStateName = oldState.name;

        String newStateName = "null";
        if (newState !is null)
            newStateName = newState.name;

        if (d_log)
            LogPrint("FSM Change State " + oldStateName + " -> " + newStateName);

        return true;
    }

    void ChangeStateQueue(const String&in name)
    {
        queueState = name;
    }

    void Update(float dt)
    {
        if (currentState !is null)
            currentState.Update(dt);

        if (!queueState.empty)
        {
            ChangeState(queueState);
            queueState.Clear();
        }
    }

    void FixedUpdate(float dt)
    {
        if (currentState !is null)
            currentState.FixedUpdate(dt);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        if (currentState !is null)
            currentState.DebugDraw(debug);
    }

    String GetDebugText()
    {
        String ret = "current-state: ";
        if (currentState !is null)
            ret += currentState.GetDebugText() + "\n";
        else
            ret += "null\n";
        return ret;
    }

    String GetCurrentStateName()
    {
        return (currentState is null) ? "null" : currentState.name;
    }
};