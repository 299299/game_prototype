

class State
{
    String name;

    State()
    {
        Print("State()");
    }

    ~State()
    {
        Print("~State() " + String(name));
    }

    void Enter(State@ lastState)
    {

    }

    void Exit(State@ nextState)
    {

    }

    void Update(float dt)
    {

    }

    void DebugDraw(DebugRenderer@ debug)
    {

    }

    String GetDebugText()
    {
        return "";
    }
};


class FSM
{
    Array<State@>   states;
    State@          currentState;

    FSM()
    {
        Print("FSM()");
    }

    ~FSM()
    {
        Print("~FSM()");
        @currentState = null;
        states.Clear();
    }

    void AddState(State@ state)
    {
        states.Push(state);
    }

    State@ FindState(const String&in name)
    {
        for (uint i=0; i<states.length; ++i)
        {
            if (states[i].name == name)
                return states[i];
        }
        return null;
    }

    void ChangeState(const String&in name)
    {
        State@ newState = FindState(name);
        if (currentState is newState)
            return;

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

        Print("FSM Change State " + oldStateName + " -> " + newStateName);
    }

    void Update(float dt)
    {
        if (currentState !is null)
            currentState.Update(dt);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        if (currentState !is null)
            currentState.DebugDraw(debug);
    }

    String GetDebugText()
    {
        String ret = "current-state = ";
        if (currentState !is null)
        {
            ret += currentState.name;
            ret += currentState.GetDebugText();
        }
        else
            ret += "null";
        return ret + "\n";
    }
};