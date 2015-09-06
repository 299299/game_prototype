#include "Scripts/Test/GameObject.as"
#include "Scripts/Test/Motion.as"



class CharacterState : State
{
    Character@                  ownner;

    CharacterState(Character@ c)
    {
        @ownner = c;
    }

    ~CharacterState()
    {
        @ownner = null;
    }
};

class MultiMotionState : CharacterState
{
    Array<Motion@> motions;
    int selectIndex;

    MultiMotionState(Character@ c)
    {
        super(c);
        selectIndex = 0;
    }

    void Update(float dt)
    {
        if (motions[selectIndex].Move(dt, ownner.sceneNode, ownner.animCtrl))
            ownner.stateMachine.ChangeState("StandState");
    }

    void Enter(State@ lastState)
    {
        selectIndex = PickIndex();
        motions[selectIndex].Start(ownner.sceneNode, ownner.animCtrl);
        Print(name + " pick " + motions[selectIndex].name);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        motions[selectIndex].DebugDraw(debug, ownner.sceneNode);
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

    uint            alignNodeId;

    CharacterAlignState(Character@ c)
    {
        super(c);
        name = "AlignState";
        alignTime = 0.5f;
    }

    void Enter(State@ lastState)
    {
        curTime = 0;

        float curYaw = ownner.sceneNode.worldRotation.eulerAngles.y;
        float diff = targetYaw - curYaw;
        diff = angleDiff(diff);

        targetPosition.y = ownner.sceneNode.worldPosition.y;

        yawPerSec = diff / alignTime;
        Print("curYaw=" + String(curYaw) + " targetYaw=" + String(targetYaw) + " yaw per second = " + String(yawPerSec));
    }

    void Update(float dt)
    {
        Node@ sceneNode = ownner.sceneNode;

        curTime += dt;
        if (curTime >= alignTime) {
            Print("FINISHED Align!!!");
            ownner.sceneNode.worldPosition = targetPosition;
            ownner.sceneNode.worldRotation = Quaternion(0, targetYaw, 0);
            ownner.stateMachine.ChangeState(nextState);

            VariantMap eventData;
            eventData["ALIGN"] = alignNodeId;
            eventData["ME"] = sceneNode.id;
            SendEvent("ALIGN_FINISED", eventData);

            return;
        }

        float lerpValue = curTime / alignTime;
        Vector3 curPos = sceneNode.worldPosition;
        sceneNode.worldPosition = curPos.Lerp(targetPosition, lerpValue);

        float yawEd = yawPerSec * dt;
        sceneNode.Yaw(yawEd);

        Print("Character align status at " + String(curTime) +
            " t=" + sceneNode.worldPosition.ToString() +
            " r=" + String(sceneNode.worldRotation.eulerAngles.y) +
            " dyaw=" + String(yawEd));
    }
};

class Character : GameObject
{
    Node@                   sceneNode;
    AnimationController@    animCtrl;

    Character()
    {
        Print("Character()");
    }

    ~Character()
    {
        Print("~Character()");
        @this.sceneNode = null;
    }

    void Start()
    {
        @this.sceneNode = node;
        animCtrl = sceneNode.GetComponent("AnimationController");
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
        state.alignNodeId = lineUpWith.id;
        stateMachine.ChangeState("AlignState");
    }
};

// clamps an angle to the rangle of [-2PI, 2PI]
float angleDiff( float diff )
{
    if (diff > 180)
        diff -= 360;
    if (diff < -180)
        diff += 360;
    return diff;
}

