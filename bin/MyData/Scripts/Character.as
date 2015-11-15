// ==============================================
//
//    Character Base Class
//
// ==============================================

const float FULLTURN_THRESHOLD = 125;
const float COLLISION_RADIUS = 1.5f;
const float COLLISION_SAFE_DIST = COLLISION_RADIUS * 1.75;
const float START_TO_ATTACK_DIST = 6;

const int MAX_NUM_OF_ATTACK = 2;
const int INITIAL_HEALTH = 100;

const StringHash ATTACK_STATE("AttackState");
const StringHash REDIRECT_STATE("RedirectState");
const StringHash TURN_STATE("TurnState");
const StringHash COUNTER_STATE("CounterState");
const StringHash GETUP_STATE("GetUpState");
const StringHash STEPMOVE_STATE("StepMoveState");
const StringHash RUN_STATE("RunState");
const StringHash HIT_STATE("HitState");
const StringHash COMBAT_IDLE_STATE("CombatIdleState");

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
const StringHash RADIUS("Radius");
const StringHash IN_AIR("InAir");
const StringHash COMBAT_SOUND("CombatSound");
const StringHash PARTICLE("Particle");
const StringHash DURATION("Duration");
const StringHash READY_TO_FIGHT("ReadyToFight");
const StringHash FOOT_STEP("FootStep");

const String L_HAND = "Bip01_L_Hand";
const String R_HAND = "Bip01_R_Hand";
const String L_FOOT = "Bip01_L_Foot";
const String R_FOOT = "Bip01_R_Foot";
const String L_ARM = "Bip01_L_Forearm";
const String R_ARM = "Bip01_R_Forearm";
const String L_CALF = "Bip01_L_Calf";
const String R_CALF = "Bip01_R_Calf";

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
        StringHash name = eventData[NAME].GetStringHash();
        if (name == RAGDOLL_START)
            ownner.ChangeState("RagdollState");
        else if (name == COMBAT_SOUND)
            OnCombatSound(eventData[VALUE].GetString());
        else if (name == FOOT_STEP)
        {
            if (animState !is null && animState.weight > 0.5f)
            {
                String boneName = eventData[VALUE].GetString();
                Node@ boneNode = ownner.sceneNode.GetChild(boneName, true);
                if (boneNode !is null)
                    OnFootStep(boneNode);
            }
        }
        else if (name == PARTICLE)
        {

        }
    }

    void OnFootStep(Node@ boneNode)
    {
        Vector3 pos = boneNode.worldPosition;
        pos.y = 0.1f;
        ownner.SpawnParticleEffect(pos, "Particle/SnowExplosionFade.xml", 2, 2.5f);
    }

    void OnCombatSound(const String& boneName)
    {
        int comb_type = GetAttackType(boneName);
        if (comb_type == ATTACK_PUNCH)
        {
            int i = RandomInt(6) + 1;
            ownner.PlaySound("Sfx/punch_0" + i + ".ogg");
        }
        else
        {
            int i = RandomInt(6) + 1;
            ownner.PlaySound("Sfx/kick_0" + i + ".ogg");
        }

        Node@ boneNode = ownner.sceneNode.GetChild(boneName, true);
        if (boneNode !is null)
            ownner.SpawnParticleEffect(boneNode.worldPosition, "Particle/SnowExplosionFade.xml", 5, 5.0f);
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
        motion.DebugDraw(debug, ownner);
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
        Print(ownner.GetName() + " state=" + name + " pick " + motions[selectIndex].animationName);
        motions[selectIndex].Start(ownner);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        motions[selectIndex].DebugDraw(debug, ownner);
    }

    int PickIndex()
    {
        return ownner.sceneNode.vars[ANIMATION_INDEX].GetInt();
    }

    String GetDebugText()
    {
        return " name=" + name + " timeInState=" + String(timeInState) + "current motion=" + motions[selectIndex].animationName + "\n";
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
            testMotion.DebugDraw(debug, ownner);
    }

    String GetDebugText()
    {
        return " name=" + name + " timeInState=" + String(timeInState) + " animation=" + animationName + "\n";
    }

    bool CanReEntered()
    {
        return true;
    }
};

enum CounterSubState
{
    COUNTER_NONE,
    COUNTER_ALIGNING,
    COUNTER_WAITING,
    COUNTER_ANIMATING,
};

class CharacterCounterState : CharacterState
{
    Array<Motion@>      doubleCounterMotions;
    Array<Motion@>      frontArmMotions;
    Array<Motion@>      frontLegMotions;
    Array<Motion@>      backArmMotions;
    Array<Motion@>      backLegMotions;
    Motion@             currentMotion;
    int                 state; // sub state

    float               alignTime = 0.2f;
    Vector3             movePerSec;
    float               yawPerSec;
    Vector3             targetPosition;

    CharacterCounterState(Character@ c)
    {
        super(c);
        SetName("CounterState");
    }

    void Enter(State@ lastState)
    {
        state = COUNTER_NONE;
    }

    void Exit(State@ nextState)
    {
        CharacterState::Exit(nextState);
        @currentMotion = null;
        state = COUNTER_NONE;
    }

    void AddDoubleCounterMotions(const String&in preFix, bool is_two)
    {
        if (is_two)
        {
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsA_01"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsA_02"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsB_01"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsB_02"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsD_01"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsD_02"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsE_01"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsE_02"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsF_01"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsF_02"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsG_01"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsG_02"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsH_01"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsH_02"));
        }
        else
        {
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsA"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsB"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsD"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsE"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsF"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsG"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsH"));
        }
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
        ChangeSubState(COUNTER_ANIMATING);
        currentMotion.Start(ownner);
    }

    Array<Motion@>@ GetCounterMotions(int attackType, bool isBack)
    {
        if (isBack)
            return attackType == ATTACK_PUNCH ? backArmMotions : backLegMotions;
        else
            return attackType == ATTACK_PUNCH ? frontArmMotions : frontLegMotions;
    }

    void DumpCounterMotions(Array<Motion@>@ motions)
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

    void Update(float dt)
    {
        // Print(ownner.GetName() + " state=" + state);
        if (state == COUNTER_ALIGNING)
        {
            ownner.sceneNode.Yaw(yawPerSec * dt);
            ownner.MoveTo(ownner.sceneNode.worldPosition + movePerSec * dt, dt);
            if (timeInState >= alignTime)
                OnAlignTimeOut();
        }
        else if (state== COUNTER_ANIMATING)
        {
             if (currentMotion.Move(ownner, dt))
             {
                ownner.CommonStateFinishedOnGroud();
                return;
             }
        }
        CharacterState::Update(dt);
    }

    void OnAlignTimeOut()
    {

    }

    void ChangeSubState(int newState)
    {
        if (state == newState)
            return;

        Print(ownner.GetName() + " CounterState ChangeSubState from " + state + " to " + newState);
        state = newState;
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
    FSM@    stateMachine = FSM();

    Character@              target;

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

    float                   attackRadius = 0.5f;
    int                     attackDamage = 10;

    Vector3                 targetPosition;
    bool                    targetPositionApplied = false;

    bool                    hintTextSet = false;

    // ==============================================
    //   DYNAMIC VALUES For Motion
    // ==============================================
    Vector3                 motion_startPosition;
    float                   motion_startRotation;

    float                   motion_deltaRotation;
    Vector3                 motion_deltaPosition;

    bool                    motion_translateEnabled = true;
    bool                    motion_rotateEnabled = true;

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

        Node@ hintNode = sceneNode.CreateChild("HintNode");
        hintNode.position = Vector3(0, 5, 0);
        Text3D@ text = hintNode.CreateComponent("Text3D");
        uint t_ = time.systemTime;
        text.SetFont("Fonts/UbuntuMono-R.ttf", 30);
        Print("11111 time-cost=" + (time.systemTime - t_) + " ms");
        text.SetAlignment(HA_CENTER, VA_CENTER);
        text.color = Color(1, 0, 0);
        text.textAlignment = HA_CENTER;
        text.text = sceneNode.name;
        text.faceCameraMode = FC_LOOKAT_XYZ;

        targetPositionApplied = false;
    }

    void Start()
    {
        Print("============================== begin Object Start ==============================");
        uint startTime = time.systemTime;
        ObjectStart();
        Print(sceneNode.name + " ObjectStart time-cost=" + String(time.systemTime - startTime) + " ms");
        Print("============================== end Object Start ==============================");
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
        @target = null;
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

    String GetHintText()
    {
        return "";
    }

    void MoveTo(const Vector3&in position, float dt)
    {
        // (sceneNode.name == "player")
        //    Print("MoveTo " + position.ToString());
        sceneNode.worldPosition = position;
        //targetPosition = position;
        //targetPositionApplied = true;
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

    bool CanAttack()
    {
        return false;
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        stateMachine.DebugDraw(debug);
        //debug.AddNode(sceneNode, 0.5f, false);
        //debug.AddNode(sceneNode.GetChild("Bip01", true), 0.25f, false);
        debug.AddCircle(sceneNode.worldPosition, Vector3(0, 1, 0), COLLISION_RADIUS, Color(1, 1, 0), 32, false);
        debug.AddLine(hipsNode.worldPosition, sceneNode.worldPosition, Color(0,1,1), false);
        DebugDrawDirection(debug, sceneNode, sceneNode.worldRotation, Color(0, 0, 1), COLLISION_RADIUS);

        //Sphere sp;
        //sp.Define(sceneNode.GetChild("Bip01", true).worldPosition, COLLISION_RADIUS);
        //debug.AddSphere(sp, Color(0, 1, 0));
        //debug.AddSkeleton(animModel.skeleton, Color(0,0,1), false);

        /*float radius = attackRadius;
        Sphere sp;
        sp.Define(handNode_L.worldPosition, radius);
        debug.AddSphere(sp, Color(0, 1, 0));
        sp.Define(handNode_R.worldPosition, radius);
        debug.AddSphere(sp, Color(0, 1, 0));
        sp.Define(footNode_L.worldPosition, radius);
        debug.AddSphere(sp, Color(0, 1, 0));
        sp.Define(footNode_R.worldPosition, radius);
        debug.AddSphere(sp, Color(0, 1, 0));
        */
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

    float GetTargetAngle(Node@ _node)
    {
        Vector3 targetPos = _node.worldPosition;
        Vector3 myPos = sceneNode.worldPosition;
        Vector3 diff = targetPos - myPos;
        return Atan2(diff.x, diff.z);
    }

    float GetTargetDistance(Node@ _node)
    {
        Vector3 targetPos = _node.worldPosition;
        Vector3 myPos = sceneNode.worldPosition;
        Vector3 diff = targetPos - myPos;
        return diff.length;
    }

    float ComputeAngleDiff(Node@ _node)
    {
        return AngleDiff(GetTargetAngle(_node) - GetCharacterAngle());
    }

    int RadialSelectAnimation(Node@ _node, int numDirections)
    {
        return DirectionMapToIndex(ComputeAngleDiff(_node), numDirections);
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

    bool OnDamage(GameObject@ attacker, const Vector3&in position, const Vector3&in direction, int damage, bool weak = false)
    {
        stateMachine.ChangeState("HitState");
        return true;
    }

    Node@ GetNode()
    {
        return sceneNode;
    }

    void OnDead()
    {
        stateMachine.ChangeState("DeadState");
    }

    void MakeMeRagdoll(int stickToDynamic = 0)
    {
        SendAnimationTriger(renderNode, RAGDOLL_START, stickToDynamic);
    }

    void SetHintText(const String&in text, bool bSet)
    {
        Node@ hintNode = sceneNode.GetChild("HintNode", false);
        Text3D@ text3d = hintNode.GetComponent("Text3D");
        text3d.text = text;
        hintTextSet = bSet;
    }

    void OnAttackSuccess()
    {

    }

    void RequestDoNotMove()
    {
        AddFlag(FLAGS_NO_MOVE);
    }

    Node@ SpawnParticleEffect(const Vector3&in position, const String&in effectName, float duration, float scale = 1.0f)
    {
        Node@ newNode = sceneNode.scene.CreateChild("Effect");
        newNode.position = position;
        newNode.scale = Vector3(scale, scale, scale);

        // Create the particle emitter
        ParticleEmitter@ emitter = newNode.CreateComponent("ParticleEmitter");
        emitter.effect = cache.GetResource("ParticleEffect", effectName);

        // Create a GameObject for managing the effect lifetime. This is always local, so for server-controlled effects it
        // exists only on the server
        GameObject@ object = cast<GameObject>(newNode.CreateScriptObject(scriptFile, "GameObject", LOCAL));
        object.duration = duration;

        // Print(GetName() + " SpawnParticleEffect pos=" + position.ToString() + " effectName=" + effectName + " duration=" + duration);

        return newNode;
    }

    Node@ SpawnSound(const Vector3&in position, const String&in soundName, float duration)
    {
        Node@ newNode = sceneNode.scene.CreateChild();
        newNode.position = position;

        // Create the sound source
        SoundSource3D@ source = newNode.CreateComponent("SoundSource3D");
        Sound@ sound = cache.GetResource("Sound", soundName);
        source.SetDistanceAttenuation(200, 5000, 1);
        source.Play(sound);

        // Create a GameObject for managing the sound lifetime
        GameObject@ object = cast<GameObject>(newNode.CreateScriptObject(scriptFile, "GameObject", LOCAL));
        object.duration = duration;

        return newNode;
    }

    void EnableComponent(const String&in boneName, const String&in componentName, bool bEnable)
    {
        Node@ _node = sceneNode.GetChild(boneName, true);
        if (_node is null)
            return;
        Component@ comp = _node.GetComponent(componentName);
        if (comp is null)
            return;
        comp.enabled = bEnable;
    }

    State@ GetState()
    {
        return stateMachine.currentState;
    }

    bool IsInState(const String&in name)
    {
        return IsInState(StringHash(name));
    }

    bool IsInState(const StringHash&in nameHash)
    {
        State@ state = stateMachine.currentState;
        if (state is null)
            return false;
        return state.nameHash == nameHash;
    }

    void ChangeState(const String&in name)
    {
        stateMachine.ChangeState(name);
    }

    State@ FindState(const String&in name)
    {
        return stateMachine.FindState(name);
    }

    void FixedUpdate(float dt)
    {
        dt *= timeScale;
        stateMachine.FixedUpdate(dt);

        if (!hintTextSet)
        {
            Node@ hintNode = sceneNode.GetChild("HintNode", false);
            if (hintNode !is null)
            {
                Vector3 pos = hipsNode.worldPosition;
                hintNode.worldPosition = Vector3(pos.x, pos.y + 3, pos.z);

                Text3D@ text = hintNode.GetComponent("Text3D");
                if (text !is null)
                {
                    text.text = GetHintText();
                }
            }
        }

        // Disappear when duration expired
        if (duration >= 0)
        {
            duration -= dt;
            if (duration <= 0)
                node.Remove();
        }
    }

    void Update(float dt)
    {
        dt *= timeScale;
        targetPositionApplied = false;
        stateMachine.Update(dt);

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
