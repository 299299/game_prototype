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