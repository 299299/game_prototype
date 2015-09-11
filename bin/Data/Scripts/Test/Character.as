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

    Motion@ GetMotion(int i)
    {
        return null;
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

        CharacterState::Update(dt);
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

    Motion@ GetMotion(int i)
    {
        return motions[i];
    }
};

class CharacterAlignState : CharacterState
{
    Vector3             targetPosition;
    float               targetRotation;
    float               yawPerSec;

    float               alignTime;
    float               curTime;
    String              nextState;

    uint                alignNodeId;

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
        float diff = targetRotation - curYaw;
        diff = angleDiff(diff);

        targetPosition.y = ownner.sceneNode.worldPosition.y;

        yawPerSec = diff / alignTime;
        Print("curYaw=" + String(curYaw) + " targetRotation=" + String(targetRotation) + " yaw per second = " + String(yawPerSec));

        float posDiff = (targetPosition - ownner.sceneNode.worldPosition).length;
        Print("angleDiff=" + String(diff) + " posDiff=" + String(posDiff));

        if (Abs(diff) < 15 && posDiff < 0.5f)
        {
            Print("cut alignTime half");
            alignTime /= 2;
        }
    }

    void Update(float dt)
    {
        Node@ sceneNode = ownner.sceneNode;

        curTime += dt;
        if (curTime >= alignTime) {
            Print("FINISHED Align!!!");
            ownner.sceneNode.worldPosition = targetPosition;
            ownner.sceneNode.worldRotation = Quaternion(0, targetRotation, 0);
            ownner.stateMachine.ChangeState(nextState);

            VariantMap eventData;
            eventData["ALIGN"] = alignNodeId;
            eventData["ME"] = sceneNode.id;
            eventData["NEXT_STATE"] = nextState;
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

        CharacterState::Update(dt);
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
    }

    void Start()
    {
        @sceneNode = node;
        Print("Character::Start " + sceneNode.name);
        animCtrl = sceneNode.GetComponent("AnimationController");
    }

    void Stop()
    {
        Print("Character::Stop " + sceneNode.name);
        @stateMachine = null;
        @sceneNode = null;
        @animCtrl = null;
    }

    void LineUpdateWithObject(Node@ lineUpWith, const String&in nextState, const Vector3&in targetPosition, float targetRotation, float t)
    {
        CharacterAlignState@ state = cast<CharacterAlignState@>(stateMachine.FindState("AlignState"));
        if (state is null)
            return;

        Print("LineUpdateWithObject targetPosition=" + targetPosition.ToString() + " targetRotation=" + String(targetRotation));
        state.targetPosition = targetPosition;
        state.targetRotation = targetRotation;
        state.alignTime = t;
        state.nextState = nextState;
        state.alignNodeId = lineUpWith.id;
        stateMachine.ChangeState("AlignState");
    }

    String GetDebugText()
    {
        return GameObject::GetDebugText() + GetAnimationDebugText(sceneNode);
    }

    void Attack()
    {
    }

    void Counter()
    {
    }

    void Evade()
    {
    }

    void CommonStateFinishedOnGroud()
    {
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


// computes the difference between the characters current heading and the
// heading the user wants them to go in.
float ComputeDifference(Node@ n, float desireAngle)
{
    Vector3 characterDir = n.worldRotation * Vector3(0, 0, 1);
    float characterAngle = Atan2(characterDir.x, characterDir.z);
    return angleDiff(desireAngle - characterAngle);
}

//  divides a circle into numSlices and returns the index (in clockwise order) of the slice which
//  contains the gamepad's angle relative to the camera.
int RadialSelectAnimation(Node@ n, int numDirections, float desireAngle)
{
    Vector3 characterDir = n.worldRotation * Vector3(0, 0, 1);
    float characterAngle = Atan2(characterDir.x, characterDir.z);
    float directionDifference = angleDiff(desireAngle - characterAngle);
    float directionVariable = Floor(directionDifference / (180 / (numDirections / 2)) + 0.5f);

    // since the range of the direction variable is [-3, 3] we need to map negative
    // values to the animation index range in our selector which is [0,7]
    if( directionVariable < 0 )
        directionVariable += numDirections;
    return int(directionVariable);
}

String GetAnimationDebugText(Node@ n)
{
    AnimatedModel@ model = n.GetComponent("AnimatedModel");
    if (model is null)
        return "";
    String debugText = "Debug-Animations:\n";
    for (uint i=0; i<model.numAnimationStates ; ++i)
    {
        AnimationState@ state = model.GetAnimationState(i);
        debugText +=  state.animation.name + " time=" + String(state.time) + " weight=" + String(state.weight) + "\n";
    }
    return debugText;
}