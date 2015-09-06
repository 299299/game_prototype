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

class CharacterAlignState : CharacterState
{
    Vector3         targetPosition;
    float           targetYaw;

    float           syncTime;
    float           curTime;
    String          nextState;

    CharacterAlignState(Node@ n, Character@ c)
    {
        super(n, c);
        name = "AlignState";
        syncTime = 0.5f;
    }

    void Enter(State@ lastState)
    {
        curTime = 0;
    }

    void Update(float dt)
    {
        curTime += dt;
        if (curTime >= syncTime) {
            Print("FINISHED Align!!!");
            characterNode.worldPosition = targetPosition;
            characterNode.worldRotation = Quaternion(0, targetYaw, 0);
            ownner.stateMachine.ChangeState(nextState);
            return;
        }

        Vector3 curPos = node.worldPosition;
        node.worldPosition = curPos.Lerp(targetPosition, curTime);
        float curYaw = node.worldRotation.eulerAngles.y;
        float yaw = Lerp(curYaw, targetYaw, curTime);
        node.worldRotation = Quaternion(0, yaw, 0);
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