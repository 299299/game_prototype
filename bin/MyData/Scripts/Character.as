
const float FULLTURN_THRESHOLD = 125;
const float COLLISION_RADIUS = 1.5f;
const float COLLISION_SAFE_DIST = COLLISION_RADIUS * 2;
const float START_TO_ATTACK_DIST = 6;

const int MAX_NUM_OF_ATTACK = 2;

const StringHash ATTACK_STATE("AttackState");
const StringHash REDIRECT_STATE("RedirectState");
const StringHash TURN_STATE("TurnState");
const StringHash COUNTER_STATE("CounterState");
const StringHash ANIMATION_INDEX("AnimationIndex");
const StringHash ATTACK_TYPE("AttackType");
const StringHash TIME_SCALE("TimeScale");
const StringHash DATA("Data");
const StringHash NAME("Name");

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

    void OnAnimationTrigger(AnimationState@ animState, const StringHash&in data)
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
        CharacterState::Update(dt);
    }

    void FixedUpdate(float dt)
    {
        if (motion.Move(ownner, dt))
            ownner.CommonStateFinishedOnGroud();

        CharacterState::FixedUpdate(dt);
    }

    void Enter(State@ lastState)
    {
        motion.Start(ownner);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        motion.DebugDraw(debug, ownner.sceneNode);
    }

    void SetMotion(const String&in name)
    {
        Motion@ m = gMotionMgr.FindMotion(name);
        if (m is null)
            return;
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
        CharacterState::Update(dt);
    }

    void FixedUpdate(float dt)
    {
        if (motions[selectIndex].Move(ownner, dt))
            ownner.CommonStateFinishedOnGroud();

        CharacterState::FixedUpdate(dt);
    }

    void Enter(State@ lastState)
    {
        selectIndex = PickIndex();
        Print(name + " pick " + motions[selectIndex].animationName);
        motions[selectIndex].Start(ownner);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        motions[selectIndex].DebugDraw(debug, ownner.sceneNode);
    }

    int PickIndex()
    {
        return ownner.sceneNode.vars[ANIMATION_INDEX].GetInt();
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
            return;
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

    void FixedUpdate(float dt)
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
        ownner.MoveTo(curPos.Lerp(targetPosition, lerpValue), dt);

        float yawEd = yawPerSec * dt;
        sceneNode.Yaw(yawEd);

        Print("Character align status at " + String(curTime) +
            " t=" + sceneNode.worldPosition.ToString() +
            " r=" + String(sceneNode.worldRotation.eulerAngles.y) +
            " dyaw=" + String(yawEd));

        CharacterState::FixedUpdate(dt);
    }

    void Update(float dt)
    {
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
            testMotion.Start(ownner);
        else
            ownner.PlayAnimation(animationName);
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
        CharacterState::Update(dt);
    }

    void FixedUpdate(float dt)
    {
        bool finished = false;
        if (testMotion !is null)
        {
             finished = testMotion.Move(ownner, dt);

            if (testMotion.looped && timeInState > 2.0f)
                finished = true;
        }
        else
            finished = ownner.animCtrl.IsAtEnd(animationName);

        if (finished) {
            ownner.CommonStateFinishedOnGroud();
        }

        CharacterState::FixedUpdate(dt);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        if (testMotion !is null)
            testMotion.DebugDraw(debug, ownner.sceneNode);
    }

    String GetDebugText()
    {
        String r = CharacterState::GetDebugText();
        r += "\nanimation=" + animationName;
        return r;
    }
};

class CharacterCounterState : CharacterState
{
    Array<Motion@>      frontArmMotions;
    Array<Motion@>      frontLegMotions;
    Array<Motion@>      backArmMotions;
    Array<Motion@>      backLegMotions;
    Motion@             currentMotion;
    int                 state; // sub state

    CharacterCounterState(Character@ c)
    {
        super(c);
        SetName("CounterState");
    }

    void Exit(State@ nextState)
    {
        CharacterState::Exit(nextState);
        @currentMotion = null;
        state = 0;
    }

    void AddCounterMotions(const String&in preFix)
    {
        // Front Arm
        frontArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Front_Weak_02"));
        frontArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Front_Weak_03"));
        frontArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Front_Weak_04"));
        frontArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Front_01"));
        frontArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Front_02"));
        frontArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Front_03"));
        frontArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Front_04"));
        frontArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Front_05"));
        frontArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Front_06"));
        frontArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Front_07"));
        frontArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Front_08"));
        frontArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Front_09"));
        frontArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Front_10"));
        frontArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Front_13"));
        frontArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Front_14"));
        // Front Leg
        frontLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Front_Weak"));
        frontLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Front_Weak_01"));
        frontLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Front_Weak_02"));
        frontLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Front_01"));
        frontLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Front_02"));
        frontLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Front_03"));
        frontLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Front_04"));
        frontLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Front_05"));
        frontLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Front_06"));
        frontLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Front_07"));
        frontLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Front_08"));
        frontLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Front_09"));
        frontLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Back_Weak_03"));
        // Back Arm
        backArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Back_Weak_01"));
        backArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Back_Weak_02"));
        backArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Back_Weak_03"));
        backArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Back_01"));
        backArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Back_02"));
        backArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Back_03"));
        backArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Back_05"));
        backArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Back_06"));
        // Back Leg
        backLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Back_Weak_01"));
        backLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Back_01"));
        backLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Back_02"));
        backLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Back_03"));
        backLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Back_04"));
        backLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Back_05"));
    }

    void StartCounterMotion()
    {
        Print(ownner.GetName() + " start counter motion " + currentMotion.animationName);
        currentMotion.Start(ownner);
        state = 1;
    }

    Motion@ GetCounterMotion(int index, bool isArm, bool isBack)
    {
        if (isBack)
        {
            return isArm ? backArmMotions[index] : backLegMotions[index];
        }
        else
        {
            return isArm ? frontArmMotions[index] : frontLegMotions[index];
        }
    }

    void DumpCounterMotions(const Array<Motion@>&in motions)
    {
        for (uint i=0; i<motions.length; ++i)
        {
            Motion@ motion = motions[i];
            String other_name = motion.name.Replaced("BM_TG_Counter", "TG_BM_Counter");
            Motion@ other_motion = gMotionMgr.FindMotion(other_name);
            Vector3 startDiff = other_motion.startFromOrigin - motion.startFromOrigin;
            Print("couter-motion " + motion.name + " diff-len=" + startDiff.length);
        }
    }

    void Dump()
    {
        DumpCounterMotions(frontArmMotions);
        DumpCounterMotions(backArmMotions);
        DumpCounterMotions(frontLegMotions);
        DumpCounterMotions(backLegMotions);
    }
};

class CharacterRagdollState : CharacterState
{
    CharacterRagdollState(Character@ c)
    {
        super(c);
        SetName("RagdollState");
    }

    void FixedUpdate(float dt)
    {
        int state = ownner.sceneNode.vars[RAGDOLL_STATE].GetInt();
        if (state == RAGDOLL_NONE && timeInState > 2.0f)
        {
            ownner.stateMachine.ChangeState("GetUpState");
        }
    }
};

class CharacterGetUpState : CharacterState
{
    Array<String>               animations;
    int                         index;

    CharacterGetUpState(Character@ c)
    {
        super(c);
        SetName("GetUpState");
    }

    void Enter(State@ lastState)
    {
        index = 0;
        ownner.PlayAnimation(animations[index], LAYER_MOVE, false, 1.0f);
        CharacterState::Enter(lastState);
    }

    void Update(float dt)
    {
        if (ownner.animCtrl.IsAtEnd(animations[index]))
            ownner.CommonStateFinishedOnGroud();

        CharacterState::Update(dt);
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
    RigidBody@              body;

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
        body = sceneNode.GetComponent("RigidBody");

        hipsNode = renderNode.GetChild("Bip01_Pelvis", true);
        handNode_L = renderNode.GetChild("Bip01_L_Hand", true);
        handNode_R = renderNode.GetChild("Bip01_R_Hand", true);
        footNode_L = renderNode.GetChild("Bip01_L_Foot", true);
        footNode_R = renderNode.GetChild("Bip01_R_Foot", true);

        // Subscribe to animation triggers, which are sent by the AnimatedModel's node (same as our node)
        SubscribeToEvent(renderNode, "AnimationTrigger", "HandleAnimationTrigger");

        startPosition = node.worldPosition;
        startRotation = node.worldRotation;
        sceneNode.vars[TIME_SCALE] = 1.0f;
    }

    void Start()
    {
        uint startTime = time.systemTime;
        ObjectStart();
        Print(sceneNode.name + " ObjectStart time-cost=" + String(time.systemTime - startTime) + " ms");
    }

    void DelayedStart()
    {

    }

    void Stop()
    {
        Print("Character::Stop " + sceneNode.name);
        @stateMachine = null;
        @sceneNode = null;
        @animCtrl = null;
        @animModel = null;
        @body = null;
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

    void SetTimeScale(float scale)
    {
        // Print(GetName() + " SetTimeScale=" + scale);
        GameObject::SetTimeScale(scale);
        uint num = animModel.numAnimationStates;
        for (uint i=0; i<num; ++i)
        {
            AnimationState@ state = animModel.GetAnimationState(i);
            Print("SetSpeed " + state.animation.name + " scale " + scale);
            animCtrl.SetSpeed(state.animation.name, scale);
        }
        sceneNode.vars[TIME_SCALE] = scale;
    }

    void PlayAnimation(const String&in animName, uint layer = LAYER_MOVE, bool loop = false, float blendTime = 0.1f, float startTime = 0.0f, float speed = 1.0f)
    {
        Print(GetName() + " PlayAnimation " + animName + " loop=" + loop + " blendTime=" + blendTime + " startTime=" + startTime + " speed=" + speed);
        AnimationController@ ctrl = animCtrl;
        ctrl.StopLayer(layer, blendTime);
        ctrl.PlayExclusive(animName, layer, loop, blendTime);
        ctrl.SetTime(animName, startTime);
        ctrl.SetSpeed(animName, speed * timeScale);
    }

    String GetDebugText()
    {
        String debugText = "========================================================================\n";
        debugText += stateMachine.GetDebugText();
        debugText += "name:" + sceneNode.name + " pos:" + sceneNode.worldPosition.ToString() + " hips-pos:" + hipsNode.worldPosition.ToString() + "\n";
        uint num = animModel.numAnimationStates;
        if (num > 0)
        {
            debugText += "Debug-Animations:\n";
            for (uint i=0; i<num ; ++i)
            {
                AnimationState@ state = animModel.GetAnimationState(i);
                debugText +=  state.animation.name + " time=" + String(state.time) + " weight=" + String(state.weight) + "\n";
            }
        }
        return debugText;
    }

    bool IsPhysical()
    {
        if (body is null)
            return false;
        return body.enabled;
    }

    void MoveTo(const Vector3&in position, float dt)
    {
        if (!IsPhysical())
        {
            sceneNode.worldPosition = position;
        }
        else
        {
            Vector3 diff = position - sceneNode.worldPosition;
            Vector3 velocity = diff / dt;
            // Print("MoveNode vel=" + velocity.ToString() + " t1=" + tWorld.ToString() + " t2=" + _node.worldPosition.ToString() + " dt=" + dt);
            body.linearVelocity = velocity;
        }
    }

    void SetVelocity(const Vector3&in velocity)
    {
        if (IsPhysical()) {
            body.linearVelocity = velocity;
        }
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

    bool CanBeRedirected()
    {
        return true;
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        GameObject::DebugDraw(debug);
        //debug.AddNode(sceneNode, 0.5f, false);
        //debug.AddNode(sceneNode.GetChild("Bip01", true), 0.25f, false);
        debug.AddCircle(sceneNode.worldPosition, Vector3(0, 1, 0), COLLISION_RADIUS, Color(1, 1, 0), 32, false);
        DebugDrawDirection(debug, sceneNode, sceneNode.worldRotation, Color(0, 0, 1), COLLISION_RADIUS);
        debug.AddLine(hipsNode.worldPosition, sceneNode.worldPosition, Color(0,1,1), false);

        //Sphere sp;
        //sp.Define(sceneNode.GetChild("Bip01", true).worldPosition, COLLISION_RADIUS);
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
        AnimationState@ state = animModel.animationStates[eventData[NAME].GetString()];
        if (state is null)
            return;

        CharacterState@ cs = cast<CharacterState@>(stateMachine.currentState);
        if (cs !is null)
            cs.OnAnimationTrigger(state, eventData[DATA].GetStringHash());
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

    String GetName()
    {
        return sceneNode.name;
    }

    float GetFootFrontDiff()
    {
        Vector3 fwd_dir = sceneNode.worldRotation * Vector3(0, 0, 1);
        Vector3 pt_lf = footNode_L.worldPosition - sceneNode.worldPosition;
        Vector3 pt_rf = footNode_R.worldPosition - sceneNode.worldPosition;
        float dot_lf = pt_lf.DotProduct(fwd_dir);
        float dot_rf = pt_rf.DotProduct(fwd_dir);
        Print(sceneNode.name + " dot_lf=" + dot_lf + " dot_rf=" + dot_rf + " diff=" + (dot_lf - dot_rf));
        return dot_lf - dot_rf;
    }

    void FillAnimationWithCurrentPose(Animation@ anim)
    {
        Array<String> boneNames =
        {
            "Bip01_$AssimpFbx$_Translation",
            "Bip01_$AssimpFbx$_Rotation",
            "Bip01_$AssimpFbx$_Scaling",
            "Bip01_Pelvis",
            "Bip01_Spine",
            "Bip01_Spine1",
            "Bip01_Spine2",
            "Bip01_Spine3",
            "Bip01_Neck",
            "Bip01_Head",
            "Bip01_L_Thigh",
            "Bip01_L_Calf",
            "Bip01_L_Foot",
            "Bip01_R_Thigh",
            "Bip01_R_Calf",
            "Bip01_R_Foot"
            "Bip01_L_Clavicle",
            "Bip01_L_UpperArm",
            "Bip01_L_Forearm",
            "Bip01_L_Hand",
            "Bip01_R_Clavicle",
            "Bip01_R_UpperArm",
            "Bip01_R_Forearm",
            "Bip01_R_Hand",
        };

        anim.RemoveAllTracks();
        for (uint i=0; i<boneNames.length; ++i)
        {
            Node@ n = renderNode.GetChild(boneNames[i], true);
            AnimationTrack@ track = anim.CreateTrack(boneNames[i]);
            track.channelMask = CHANNEL_POSITION | CHANNEL_ROTATION;
            AnimationKeyFrame kf;
            kf.time = 0.0f;
            kf.position = n.position;
            kf.rotation = n.rotation;
            track.AddKeyFrame(kf);
        }
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
