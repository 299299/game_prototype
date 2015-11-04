
const float FULLTURN_THRESHOLD = 125;
const float COLLISION_RADIUS = 1.5f;
const float COLLISION_SAFE_DIST = COLLISION_RADIUS * 1.85;
const float START_TO_ATTACK_DIST = 6;

const int MAX_NUM_OF_ATTACK = 2;
const int INITIAL_HEALTH = 100;

const StringHash ATTACK_STATE("AttackState");
const StringHash REDIRECT_STATE("RedirectState");
const StringHash TURN_STATE("TurnState");
const StringHash COUNTER_STATE("CounterState");
const StringHash GETUP_STATE("GetUpState");
const StringHash ANIMATION_INDEX("AnimationIndex");
const StringHash ATTACK_TYPE("AttackType");
const StringHash TIME_SCALE("TimeScale");
const StringHash DATA("Data");
const StringHash NAME("Name");
const StringHash ANIMATION("Animation");
const StringHash GETUP_INDEX("Getup_Index");
const StringHash SPEED("Speed");
const StringHash STATE("State");
const StringHash VALUE("Value");
const StringHash COUNTER_CHECK("CounterCheck");
const StringHash ATTACK_CHECK("AttackCheck");
const StringHash BONE("Bone");
const StringHash NODE("Node");
const StringHash L_FOOT("Bip01_L_Foot");
const StringHash R_FOOT("Bip01_R_Foot");
const StringHash L_HAND("Bip01_L_Hand");
const StringHash R_HAND("Bip01_R_Hand");
const StringHash RADIUS("Radius");
const StringHash IN_AIR("InAir");

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

    void OnAnimationTrigger(AnimationState@ animState, const VariantMap&in eventData)
    {
        //Print("ownner.name= " + ownner.GetName() + "name=" + eventData[NAME].GetStringHash().ToString() + " name1=" + RAGDOLL_START.ToString());
        if (eventData[NAME].GetStringHash() == RAGDOLL_START) {
            ownner.ChangeState("RagdollState");
        }
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
        if (motion.Move(ownner, dt)) {
            ownner.CommonStateFinishedOnGroud();
            return;
        }
        CharacterState::Update(dt);
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
    }

    void Update(float dt)
    {
        if (motions[selectIndex].Move(ownner, dt)) {
            ownner.CommonStateFinishedOnGroud();
            return;
        }
        CharacterState::Update(dt);
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

    float               alignTime = 0.5f;
    float               curTime;
    String              nextState;

    uint                alignNodeId;

    CharacterAlignState(Character@ c)
    {
        super(c);
        SetName("AlignState");
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
            sceneNode.worldPosition = targetPosition;
            sceneNode.worldRotation = Quaternion(0, targetRotation, 0);
            ownner.ChangeState(nextState);

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
        Print("AnimationTestState::Enter");
        @testMotion = gMotionMgr.FindMotion(animationName);
        if (testMotion !is null)
            testMotion.Start(ownner);
        else
            ownner.PlayAnimation(animationName);
    }

    void Exit(State@ nextState)
    {
        Print("AnimationTestState::Exit");
        @testMotion = null;
        CharacterState::Exit(nextState);
    }

    void Update(float dt)
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
            return;
        }

        CharacterState::Update(dt);
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

    bool CanReEntered()
    {
        return true;
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

    void Update(float dt)
    {
        if (timeInState > 0.1f)
        {
            int ragdoll_state = ownner.sceneNode.vars[RAGDOLL_STATE].GetInt();
            if (ragdoll_state == RAGDOLL_NONE)
            {
                ownner.PlayCurrentPose();
                ownner.ChangeState("GetUpState");
            }
        }
        CharacterState::Update(dt);
    }
};

class CharacterGetUpState : MultiMotionState
{
    int                         state = 0;
    float                       ragdollToAnimTime = 0.0f;

    CharacterGetUpState(Character@ c)
    {
        super(c);
        SetName("GetUpState");
    }

    void Enter(State@ lastState)
    {
        state = 0;
        selectIndex = PickIndex();
        Motion@ motion = motions[selectIndex];
        //if (blend_to_anim)
        //    ragdollToAnimTime = 0.2f;
        ownner.PlayAnimation(motion.animationName, LAYER_MOVE, false, ragdollToAnimTime, 0.0f, 0.0f);
        CharacterState::Enter(lastState);
    }

    void Update(float dt)
    {
        Motion@ motion = motions[selectIndex];
        if (state == 0)
        {
            if (timeInState >= ragdollToAnimTime)
            {
                ownner.animCtrl.SetSpeed(motion.animationName, 1.0f);
                motion.InnerStart(ownner);
                state = 1;
            }
        }
        else
        {
            if (motion.Move(ownner, dt))
            {
                // ownner.sceneNode.scene.timeScale = 0.0f;
                ownner.CommonStateFinishedOnGroud();
                return;
            }
        }

        CharacterState::Update(dt);
    }

    int PickIndex()
    {
        return ownner.sceneNode.vars[GETUP_INDEX].GetInt();
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

    Animation@              ragdollPoseAnim;

    int                     health = INITIAL_HEALTH;

    Node@                   attackCheckNode;
    float                   attackRadius = 0.5f;
    int                     attackDamage = 10;

    Node@                   hintNode;

    Vector3                 targetPosition;
    bool                    targetPositionApplied = false;

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

        startPosition = sceneNode.worldPosition;
        startRotation = sceneNode.worldRotation;
        sceneNode.vars[TIME_SCALE] = 1.0f;

        String name = sceneNode.name + "_Ragdoll_Pose";
        ragdollPoseAnim = cache.GetResource("Animation", name);
        if (ragdollPoseAnim is null)
        {
            Print("Creating animation for ragdoll pose " + name);
            ragdollPoseAnim = Animation();
            ragdollPoseAnim.name = name;
            ragdollPoseAnim.animationName = name;
            cache.AddManualResource(ragdollPoseAnim);
        }

        SubscribeToEvent(renderNode, "AnimationTrigger", "HandleAnimationTrigger");

        attackCheckNode = sceneNode.CreateChild("Attack_Node");
        CollisionShape@ shape = attackCheckNode.CreateComponent("CollisionShape");
        shape.SetSphere(attackRadius);
        RigidBody@ rb = attackCheckNode.CreateComponent("RigidBody");
        rb.trigger = true;
        rb.collisionLayer = COLLISION_LAYER_ATTACK;
        rb.collisionMask = COLLISION_LAYER_CHARACTER | COLLISION_LAYER_RAGDOLL;
        rb.collisionEventMode = COLLISION_ALWAYS;
        rb.enabled = false;

        hintNode = sceneNode.CreateChild("Hint_Node");
        hintNode.position = Vector3(0, 5, 0);
        Text3D@ text = hintNode.CreateComponent("Text3D");
        text.SetFont("Fonts/UbuntuMono-R.ttf", 25);
        text.SetAlignment(HA_CENTER, VA_CENTER);
        text.color = Color(1, 0, 0);
        text.textAlignment = HA_CENTER;
        text.text = sceneNode.name;
        text.faceCameraMode = FC_LOOKAT_XYZ;

        targetPositionApplied = false;
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
        cache.ReleaseResource("Animation", ragdollPoseAnim.name, true);
        ragdollPoseAnim = null;
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
        if (timeScale == scale)
            return;
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
        debugText += "name:" + sceneNode.name + " pos:" + sceneNode.worldPosition.ToString() + " hips-pos:" + hipsNode.worldPosition.ToString() + " health:" + health + "\n";
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

    void Update(float dt)
    {
        targetPositionApplied = false;
        GameObject::Update(dt);

        if (!targetPositionApplied)
            return;

        targetPositionApplied = false;
        Vector3 curPosition = sceneNode.worldPosition;
        Ray ray(curPosition, (targetPosition - curPosition).Normalized());
        float rayLen = COLLISION_RADIUS + 0.5f;
        PhysicsRaycastResult result = sceneNode.scene.physicsWorld.RaycastSingle(ray, rayLen, COLLISION_LAYER_LANDSCAPE);
        if (result.body !is null)
            return;
        sceneNode.worldPosition = targetPosition;
    }

    void MoveTo(const Vector3&in position, float dt)
    {
        // sceneNode.worldPosition = position;
        targetPosition = position;
        targetPositionApplied = true;
    }

    bool Attack()
    {
        return false;
    }

    bool Counter()
    {
        return false;
    }

    bool Evade()
    {
        return false;
    }

    bool Redirect()
    {
        stateMachine.ChangeState("RedirectState");
        return false;
    }

    void CommonStateFinishedOnGroud()
    {
        stateMachine.ChangeState("StandState");
    }

    void Reset()
    {
        sceneNode.worldPosition = startPosition;
        sceneNode.worldRotation = startRotation;
        health = INITIAL_HEALTH;
        SetTimeScale(1.0f);
        targetPositionApplied = false;
        stateMachine.ChangeState("StandState");
    }

    bool CanBeAttacked()
    {
        return HasFlag(FLAGS_ATTACK);
    }

    bool CanBeCountered()
    {
        return HasFlag(FLAGS_COUNTER);
    }

    bool CanBeRedirected()
    {
        return HasFlag(FLAGS_REDIRECTED);
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

        float radius = attackRadius;
        Sphere sp;
        sp.Define(handNode_L.worldPosition, radius);
        debug.AddSphere(sp, Color(0, 1, 0));
        sp.Define(handNode_R.worldPosition, radius);
        debug.AddSphere(sp, Color(0, 1, 0));
        sp.Define(footNode_L.worldPosition, radius);
        debug.AddSphere(sp, Color(0, 1, 0));
        sp.Define(footNode_R.worldPosition, radius);
        debug.AddSphere(sp, Color(0, 1, 0));
    }

    void TestAnimation(const String&in animationName)
    {
        AnimationTestState@ state = cast<AnimationTestState@>(stateMachine.FindState("AnimationTestState"));
        if (state is null)
            return;
        state.animationName = animationName;
        stateMachine.ChangeState("AnimationTestState");
    }

    void HandleAnimationTrigger(StringHash eventType, VariantMap& eventData)
    {
        AnimationState@ state = animModel.animationStates[eventData[NAME].GetString()];
        if (state is null)
            return;

        CharacterState@ cs = cast<CharacterState@>(stateMachine.currentState);
        if (cs !is null)
            cs.OnAnimationTrigger(state, eventData[DATA].GetVariantMap());
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

    void PlayCurrentPose()
    {
        FillAnimationWithCurrentPose(ragdollPoseAnim, renderNode);
        AnimationState@ state = animModel.AddAnimationState(ragdollPoseAnim);
        state.weight = 1.0f;
        animCtrl.PlayExclusive(ragdollPoseAnim.name, LAYER_MOVE, false, 0.0f);
    }

    void OnDamage(GameObject@ attacker, const Vector3&in position, const Vector3&in direction, int damage, bool weak = false)
    {
        stateMachine.ChangeState("HitState");
    }

    Node@ GetNode()
    {
        return sceneNode;
    }

    void EnableAttackCheck(bool bEnable)
    {
        RigidBody@ rb = attackCheckNode.GetComponent("RigidBody");
        rb.enabled = bEnable;
    }

    void OnDead()
    {
        stateMachine.ChangeState("DeadState");
    }

    void MakeMeRagdoll()
    {
        VariantMap data;
        data[DATA] = RAGDOLL_START;
        renderNode.SendEvent("AnimationTrigger", data);
    }

    void SetHintText(const String&in text)
    {
        Text3D@ text3d = hintNode.GetComponent("Text3D");
        text3d.text = text;
    }

    void OnAttackSuccess()
    {

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
