
const float fullTurnThreashold = 125;
const float collisionRadius = 1.5f;

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

    void OnAnimationTrigger(AnimationState@ animState, Node@ boneNode)
    {

    }
};


class SingleMotionState : CharacterState
{
    Motion@ motion;

    SingleMotionState(Character@ c)
    {
        super(c);
    }

    void Update(float dt)
    {
        if (motion.Move(dt, ownner.sceneNode, ownner.animCtrl))
            ownner.CommonStateFinishedOnGroud();

        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        motion.Start(ownner.sceneNode, ownner.animCtrl);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        motion.DebugDraw(debug, ownner.sceneNode);
    }

    void SetMotion(const String&in name)
    {
        Motion@ m = gMotionMgr.FindMotion(name);
        if (m is null)
        {
            Print(name + " can not find motion " + name);
            return;
        }
        @motion = m;
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
            ownner.CommonStateFinishedOnGroud();

        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        selectIndex = PickIndex();
        motions[selectIndex].Start(ownner.sceneNode, ownner.animCtrl);
        Print(name + " pick " + motions[selectIndex].animationName);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        motions[selectIndex].DebugDraw(debug, ownner.sceneNode);
    }

    int PickIndex()
    {
        return ownner.sceneNode.vars["AnimationIndex"].GetInt();
    }

    Motion@ GetMotion(int i)
    {
        return motions[i];
    }

    String GetDebugText()
    {
        String r = CharacterState::GetDebugText();
        r += "\ncurrent motion=" + motions[selectIndex].animationName;
        return r;
    }

    void AddMotion(const String&in name)
    {
        Motion@ motion = gMotionMgr.FindMotion(name);
        if (motion is null)
        {
            Print(name + " can not find motion " + name);
            return;
        }
        motions.Push(motion);
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
        SetName("AlignState");
        alignTime = 0.5f;
    }

    void Enter(State@ lastState)
    {
        curTime = 0;

        float curYaw = ownner.sceneNode.worldRotation.eulerAngles.y;
        float diff = targetRotation - curYaw;
        diff = AngleDiff(diff);

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

class AnimationTestState : CharacterState
{
    Motion@ testMotion;
    String  animationName;

    AnimationTestState(Character@ c)
    {
        super(c);
        SetName("AnimationTestState");
        @testMotion = null;
    }

    void Enter(State@ lastState)
    {
        if (testMotion !is null)
            testMotion.Start(ownner.sceneNode, ownner.animCtrl);
    }

    void Exit(State@ nextState)
    {
        @testMotion = null;
        CharacterState::Exit(nextState);
    }

    bool SetTestAnimation(const String&in name)
    {
        @testMotion = gMotionMgr.FindMotion(name);
        if (testMotion is null)
            return false;
        animationName = name;
        return true;
    }

    void Update(float dt)
    {
        bool finished = false;
        if (testMotion !is null)
        {
             finished = testMotion.Move(dt, ownner.sceneNode, ownner.animCtrl);
        }
        else
        {

        }

        if (finished) {
            ownner.stateMachine.ChangeState("StandState");
            // ownner.sceneNode.scene.timeScale = 0.0f;
        }

        CharacterState::Update(dt);
    }

    String GetDebugText()
    {
        String r = CharacterState::GetDebugText();
        r += "\nanimation=" + animationName;
        return r;
    }
};

class RandomAnimationState : CharacterState
{
    Array<String>           animations;

    RandomAnimationState(Character@ c)
    {
        super(c);
    }

    void StartBlendTime(float blendTime)
    {
        PlayAnimation(ownner.animCtrl, animations[RandomInt(animations.length)], LAYER_MOVE, true, blendTime, 0.0);
    }
};

class Character : GameObject
{
    Node@                   sceneNode;
    Node@                   renderNode;

    Node@                   hipsNode;
    Node@                   handNode_L;
    Node@                   handNode_R;
    Node@                   footNode_L;
    Node@                   footNode_R;

    AnimationController@    animCtrl;
    AnimatedModel@          animModel;

    Vector3                 startPosition;
    Quaternion              startRotation;

    Character()
    {
        Print("Character()");
    }

    ~Character()
    {
        Print("~Character()");
    }

    void ObjectStart()
    {
        @sceneNode = node;
        Print("NodeStart " + sceneNode.name);
        renderNode = sceneNode.children[0];
        animCtrl = renderNode.GetComponent("AnimationController");
        animModel = renderNode.GetComponent("AnimatedModel");

        hipsNode = renderNode.GetChild("Bip01_Pelvis", true);
        handNode_L = renderNode.GetChild("Bip01_L_Hand", true);
        handNode_R = renderNode.GetChild("Bip01_R_Hand", true);
        footNode_L = renderNode.GetChild("Bip01_L_Foot", true);
        footNode_R = renderNode.GetChild("Bip01_R_Foot", true);

        // Subscribe to animation triggers, which are sent by the AnimatedModel's node (same as our node)
        SubscribeToEvent(renderNode, "AnimationTrigger", "HandleAnimationTrigger");

        startPosition = node.worldPosition;
        startRotation = node.worldRotation;
    }

    void Start()
    {
        ObjectStart();
    }

    void DelayedStart()
    {
        Print("Character::DelayedStart " + sceneNode.name);
    }

    void Stop()
    {
        Print("Character::Stop " + sceneNode.name);
        @stateMachine = null;
        @sceneNode = null;
        @animCtrl = null;
        @animModel = null;
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
        String debugText = "========================================================================\n";
        debugText += stateMachine.GetDebugText();
        debugText += "name:" + sceneNode.name + " pos:" + sceneNode.worldPosition.ToString() + " hips-pos:" + hipsNode.worldPosition.ToString() + "\n";
        if (animModel.numAnimationStates > 0)
        {
            debugText += "Debug-Animations:\n";
            for (uint i=0; i<animModel.numAnimationStates ; ++i)
            {
                AnimationState@ state = animModel.GetAnimationState(i);
                debugText +=  state.animation.name + " time=" + String(state.time) + " weight=" + String(state.weight) + "\n";
            }
        }
        return debugText;
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

    void Redirect()
    {
        stateMachine.ChangeState("RedirectState");
    }

    void CommonStateFinishedOnGroud()
    {
        stateMachine.ChangeState("StandState");
    }

    void Reset()
    {
        sceneNode.worldPosition = startPosition;
        sceneNode.worldRotation = startRotation;
        stateMachine.ChangeState("StandState");
    }

    bool CanBeAttacked()
    {
        return true;
    }

    bool CanBeCountered()
    {
        return true;
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        GameObject::DebugDraw(debug);
        debug.AddNode(sceneNode, 0.5f, false);
        debug.AddNode(sceneNode.GetChild("Bip01", true), 0.25f, false);
        //Sphere sp;
        //sp.Define(sceneNode.GetChild("Bip01", true).worldPosition, collisionRadius);
        //debug.AddSphere(sp, Color(0, 1, 0));
        //debug.AddSkeleton(animModel.skeleton, Color(0,0,1), false);

        /*
        float handRadius = 0.5f;
        Sphere sp;
        sp.Define(handNode_L.worldPosition, handRadius);
        debug.AddSphere(sp, Color(0, 1, 0));
        sp.Define(handNode_R.worldPosition, handRadius);
        debug.AddSphere(sp, Color(0, 1, 0));
        float footRadius = 0.5f;
        sp.Define(footNode_L.worldPosition, footRadius);
        debug.AddSphere(sp, Color(0, 1, 0));
        sp.Define(footNode_R.worldPosition, footRadius);
        debug.AddSphere(sp, Color(0, 1, 0));
        */
        debug.AddLine(hipsNode.worldPosition, sceneNode.worldPosition, Color(1,1,0), false);
    }

    void TestAnimation(const String&in animationName)
    {
        AnimationTestState@ state = cast<AnimationTestState@>(stateMachine.FindState("AnimationTestState"));
        if (!state.SetTestAnimation(animationName))
            return;
        stateMachine.ChangeState("AnimationTestState");
    }

    void HandleAnimationTrigger(StringHash eventType, VariantMap& eventData)
    {
        AnimatedModel@ model = node.GetComponent("AnimatedModel");
        AnimationState@ state = model.animationStates[eventData["Name"].GetString()];
        if (state is null)
            return;

        // If the animation is blended with sufficient weight, instantiate a local particle effect for the footstep.
        // The trigger data (string) tells the bone scenenode to use. Note: called on both client and server
        if (state.weight > 0.5f)
        {
            Node@ bone = node.GetChild(eventData["Data"].GetString(), true);
            CharacterState@ cs = cast<CharacterState@>(stateMachine.currentState);
            if (cs !is null)
            {
                cs.OnAnimationTrigger(state, bone);
            }
        }
    }

    float GetTargetAngle()
    {
        return 0;
    }

    float GetTargetDistance()
    {
        return 0;
    }

    float ComputeAngleDiff()
    {
        return AngleDiff(GetTargetAngle() - GetCharacterAngle());
    }

    int RadialSelectAnimation(int numDirections)
    {
        return DirectionMapToIndex(ComputeAngleDiff(), numDirections);
    }

    float GetTargetAngle(Node@ node)
    {
        Vector3 targetPos = node.worldPosition;
        Vector3 myPos = sceneNode.worldPosition;
        Vector3 diff = targetPos - myPos;
        return Atan2(diff.x, diff.z);
    }

    float GetTargetDistance(Node@ node)
    {
        Vector3 targetPos = node.worldPosition;
        Vector3 myPos = sceneNode.worldPosition;
        Vector3 diff = targetPos - myPos;
        return diff.length;
    }

    float ComputeAngleDiff(Node@ node)
    {
        return AngleDiff(GetTargetAngle(node) - GetCharacterAngle());
    }

    float GetCharacterAngle()
    {
        Vector3 characterDir = sceneNode.worldRotation * Vector3(0, 0, 1);
        return Atan2(characterDir.x, characterDir.z);
    }
};

int DirectionMapToIndex(float directionDifference, int numDirections)
{
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

float FaceAngleDiff(Node@ thisNode, Node@ targetNode)
{
    Vector3 posDiff = targetNode.worldPosition - thisNode.worldPosition;
    Vector3 thisDir = thisNode.worldRotation * Vector3(0, 0, 1);
    float thisAngle = Atan2(thisDir.x, thisDir.z);
    float targetAngle = Atan2(posDiff.x, posDiff.y);
    return AngleDiff(targetAngle - thisAngle);
}
