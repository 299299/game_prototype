

class State
{
    String name;

    State()
    {
        Print("State()");
    }

    ~State()
    {
        Print("~State()");
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

    bool opEquals(State &in other){return (name == other.name);}
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
        if (newState is null && currentState is null)
            return;

        if (currentState !is null && newState !is null) {
            if (newState == currentState) {
                Print("Same state = " + name);
                return;
            }
        }

        State@ oldState = currentState;
        if (oldState !is null)
            oldState.Exit(newState);

        if (newState !is null)
            newState.Enter(oldState);

        @currentState = newState;

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
};