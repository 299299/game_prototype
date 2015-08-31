#include "Scripts/Test/GameObject.as"
#include "Scripts/Test/Motion.as"

class CharacterState : State
{
    Node@                       characterNode;
    Character@                  ownner;
    AnimationController@        ctrl;

    CharacterState(Node@ n, Character@ c)
    {
        characterNode = n;
        @ownner = c;
        ctrl = characterNode.GetComponent("AnimationController");
    }

    ~CharacterState()
    {
        @characterNode = null;
        @ownner = null;
    }
};

class MultiMotionState : CharacterState
{
    Array<Motion@> motions;
    int selectIndex;

    MultiMotionState(Node@ n, Character@ c)
    {
        super(n, c);
        selectIndex = 0;
    }

    void Update(float dt)
    {

    }

    void Enter(State@ lastState)
    {
        selectIndex = PickIndex();
        motions[selectIndex].Start(characterNode, ctrl);
        Print(name + " pick " + motions[selectIndex].name);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        motions[selectIndex].DebugDraw(debug, characterNode);
    }

    int PickIndex()
    {
        return 0;
    }
};

class Character : GameObject
{
    Character()
    {
        Print("Character()");
        @stateMachine = FSM();
    }

    ~Character()
    {
        Print("~Character()");
    }

    void Start()
    {

    }

    void Stop()
    {
        @stateMachine = null;
    }

    void Update(float dt)
    {
        GameObject::Update(dt);
    }
};