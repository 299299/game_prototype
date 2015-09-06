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
    float           yawPerSec;

    float           alignTime;
    float           curTime;
    String          nextState;

    CharacterAlignState(Node@ n, Character@ c)
    {
        super(n, c);
        name = "AlignState";
        alignTime = 0.5f;
    }

    void Enter(State@ lastState)
    {
        curTime = 0;

        float curYaw = characterNode.worldRotation.eulerAngles.y;
        float diff = targetYaw - curYaw;
        float absDiff = Abs(diff);
        if (absDiff > 180) {
            diff = 360 - absDiff;
            if (curYaw > targetYaw)
                diff = -diff;
        }
        yawPerSec = diff / alignTime;
        Print("curYaw=" + String(curYaw) + " targetYaw=" + String(targetYaw) + " yaw per second = " + String(yawPerSec));
    }

    void Update(float dt)
    {
        curTime += dt;
        if (curTime >= alignTime) {
            Print("FINISHED Align!!!");
            characterNode.worldPosition = targetPosition;
            characterNode.worldRotation = Quaternion(0, targetYaw, 0);
            ownner.stateMachine.ChangeState(nextState);
            return;
        }

        float lerpValue = curTime / alignTime;
        Vector3 curPos = characterNode.worldPosition;
        characterNode.worldPosition = curPos.Lerp(targetPosition, lerpValue);

        float yawEd = yawPerSec * dt;
        characterNode.Yaw(yawEd);

        Print("Character align status at " + String(curTime) +
            " t=" + characterNode.worldPosition.ToString() +
            " r=" + String(characterNode.worldRotation.eulerAngles.y) +
            " dyaw=" + String(yawEd));
    }
};

class Character : GameObject
{
    Character()
    {
        Print("Character()");
    }

    ~Character()
    {
        Print("~Character()");
    }

    void Start()
    {

    }

    void Update(float dt)
    {
        GameObject::Update(dt);
    }

    void LineUpdateWithObject(Node@ lineUpWith, const String&in nextState, float yawAdjust, float distance, float t)
    {
        float targetYaw = lineUpWith.worldRotation.eulerAngles.y + yawAdjust;
        Quaternion targetRotation(0, targetYaw, 0);
        Vector3 targetPosition = lineUpWith.worldPosition + targetRotation * Vector3(0, 0, distance);
        CharacterAlignState@ state = cast<CharacterAlignState@>(stateMachine.FindState("AlignState"));
        if (state is null)
            return;

        Print("LineUpdateWithObject targetPosition=" + targetPosition.ToString() + " targetYaw=" + String(targetYaw));
        state.targetPosition = targetPosition;
        state.targetYaw = targetYaw;
        state.alignTime = t;
        state.nextState = nextState;
        stateMachine.ChangeState("AlignState");
    }
};