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
        //Print("State()");
    }

    ~State()
    {
        //Print("~State() " + String(name));
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
        return " name=" + name + " timeInState=" + String(timeInState) + "\n";
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
    StringHash              queueState;

    FSM()
    {
        //Print("FSM()");
    }

    ~FSM()
    {
        /*
        if (currentState !is null)
            Print("~FSM() currentState=" + currentState.name);
        else
            Print("~FSM()");
        */
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

    bool ChangeState(const StringHash&in nameHash)
    {
        State@ newState = FindState(nameHash);

        if (newState is null)
        {
            Print("new-state not found " + nameHash.ToString());
            return false;
        }

        if (currentState is newState) {
            // Print("same state !!!");
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
            Print("FSM Change State " + oldStateName + " -> " + newStateName);

        return true;
    }

    bool ChangeState(const String&in name)
    {
        return ChangeState(StringHash(name));
    }

    void ChangeStateQueue(const StringHash&in name)
    {
        queueState = name;
    }

    void Update(float dt)
    {
        if (currentState !is null)
            currentState.Update(dt);

        if (queueState != 0)
        {
            ChangeState(queueState);
            queueState = 0;
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
            ret += currentState.GetDebugText();
        else
            ret += "null\n";
        return ret;
    }
};