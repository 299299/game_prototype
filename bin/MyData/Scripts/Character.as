// ==============================================
//
//    Character Base Class
//
// ==============================================

const float FULLTURN_THRESHOLD = 125;
const float COLLISION_RADIUS = 1.5f;
const float COLLISION_SAFE_DIST = COLLISION_RADIUS * 1.8f;
const float CHARACTER_HEIGHT = 5.0f;
const float SPHERE_CAST_RADIUS = 0.25f;

const int MAX_NUM_OF_ATTACK = 3;
const int MAX_NUM_OF_MOVING = 3;
const int MAX_NUM_OF_NEAR = 4;
const int MAX_NUM_OF_RUN_ATTACK = 3;

const int INITIAL_HEALTH = 100;
const int NUM_ZONE_DIRECTIONS = 8;

const StringHash ATTACK_STATE("AttackState");
const StringHash TURN_STATE("TurnState");
const StringHash HIT_STATE("HitState");
const StringHash STAND_STATE("StandState");
const StringHash ALIGN_STATE("AlignState");
const StringHash RUN_TO_TARGET_STATE("RunToTargetState");

const StringHash ANIMATION_INDEX("AnimationIndex");
const StringHash ATTACK_TYPE("AttackType");
const StringHash TIME_SCALE("TimeScale");
const StringHash DATA("Data");
const StringHash NAME("Name");
const StringHash ANIMATION("Animation");
const StringHash STATE("State");
const StringHash VALUE("Value");
const StringHash COUNTER_CHECK("CounterCheck");
const StringHash ATTACK_CHECK("AttackCheck");
const StringHash BONE("Bone");
const StringHash NODE("Node");
const StringHash COMBAT_SOUND("CombatSound");
const StringHash COMBAT_SOUND_LARGE("CombatSoundLarge");
const StringHash PARTICLE("Particle");
const StringHash DURATION("Duration");
const StringHash READY_TO_FIGHT("ReadyToFight");
const StringHash FOOT_STEP("FootStep");
const StringHash CHANGE_STATE("ChangeState");
const StringHash IMPACT("Impact");
const StringHash SOUND("Sound");
const StringHash TARGET("Target");

const String PLAYER_TAG("Tag_Player");
const String ENEMY_TAG("Tag_Enemy");

Vector3 WORLD_HALF_SIZE(1000, 0, 1000);

int num_of_sounds = 37;
int num_of_big_sounds = 6;

class CharacterState : State
{
    Character@                  ownner;
    uint                        flags = 0;
    float                       animSpeed = 1.0f;
    float                       blendTime = 0.2f;
    float                       startTime = 0.0f;

    bool                        combatReady = false;
    bool                        firstUpdate = true;

    int                         lastPhysicsType = 0;
    int                         physicsType = -1;

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
        StringHash name = eventData[NAME].GetStringHash();
        if (name == RAGDOLL_START)
            ownner.ChangeState("RagdollState");
        else if (name == COMBAT_SOUND)
            OnCombatSound(eventData[VALUE].GetString(), false);
        else if (name == COMBAT_SOUND_LARGE)
            OnCombatSound(eventData[VALUE].GetString(), true);
        else if (name == PARTICLE)
            OnCombatParticle(eventData[VALUE].GetString(), eventData[PARTICLE].GetString());
        else if (name == FOOT_STEP)
        {
            if (animState !is null && animState.weight > 0.5f)
                OnFootStep(eventData[VALUE].GetString());
        }
        else if (name == SOUND)
            ownner.PlaySound(eventData[VALUE].GetString());
        else if (name == CHANGE_STATE)
            ownner.ChangeState(eventData[VALUE].GetStringHash());
        else if (name == IMPACT)
        {
            combatReady = true;
        }
        else if (name == READY_TO_FIGHT)
        {
            combatReady = true;
        }
    }

    void OnFootStep(const String&in boneName)
    {
        Node@ boneNode = ownner.GetNode().GetChild(boneName, true);
        if (boneNode !is null)
            return;
        Vector3 pos = boneNode.worldPosition;
        pos.y = 0.1f;
        ownner.SpawnParticleEffect(pos, "Particle/SnowExplosionFade.xml", 2, 2.5f);
    }

    void OnCombatSound(const String& boneName, bool large)
    {
        ownner.PlayRandomSound(large ? 1 : 0);

        Node@ boneNode = ownner.renderNode.GetChild(boneName, true);
        if (boneNode !is null)
            ownner.SpawnParticleEffect(boneNode.worldPosition, "Particle/SnowExplosionFade.xml", 5, 5.0f);
    }

    void OnCombatParticle(const String& boneName, const String& particleName)
    {
        Node@ boneNode = ownner.renderNode.GetChild(boneName, true);
        if (boneNode !is null)
            ownner.SpawnParticleEffect(boneNode.worldPosition,
                particleName.empty ? "Particle/SnowExplosionFade.xml" : particleName, 5, 5.0f);
    }

    float GetThreatScore()
    {
        return 0.0f;
    }

    void Enter(State@ lastState)
    {
        if (flags > 0)
            ownner.AddFlag(flags);
        State::Enter(lastState);
        combatReady = false;
        firstUpdate = true;

        if (physicsType >= 0)
        {
            lastPhysicsType = ownner.physicsType;
            ownner.SetPhysicsType(physicsType);
        }
    }

    void Exit(State@ nextState)
    {
        if (flags > 0)
            ownner.RemoveFlag(flags);
        State::Exit(nextState);
        if (physicsType >= 0)
            ownner.SetPhysicsType(lastPhysicsType);
    }

    void Update(float dt)
    {
        if (combatReady)
        {
            if (!ownner.IsInAir())
            {
                if (ownner.ActionCheck())
                    return;
            }
        }
        State::Update(dt);
        firstUpdate = false;
    }
};

class SingleAnimationState : CharacterState
{
    String animation;
    bool looped = false;
    float stateTime = -1;

    SingleAnimationState(Character@ c)
    {
        super(c);
    }

    void Update(float dt)
    {
        bool finished = false;
        if (looped)
        {
            if (stateTime > 0 && timeInState > stateTime)
                finished = true;
        }
        else
        {
            if (animSpeed < 0)
            {
                finished = ownner.animCtrl.GetTime(animation) < 0.0001f;
            }
            else
                finished = ownner.animCtrl.IsAtEnd(animation);
        }

        if (finished)
            OnMotionFinished();

        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        ownner.PlayAnimation(animation, LAYER_MOVE, looped, blendTime, startTime, animSpeed);
        CharacterState::Enter(lastState);
    }

    void OnMotionFinished()
    {
        ownner.CommonStateFinishedOnGroud();
    }

    void SetMotion(const String&in name)
    {
        animation = GetAnimationName(name);
    }
};


class SingleMotionState : CharacterState
{
    Motion@ motion;

    SingleMotionState(Character@ c)
    {
        super(c);
    }

    ~SingleMotionState()
    {
        @motion = null;
    }

    void Update(float dt)
    {
        if (motion.Move(ownner, dt) == 1)
            OnMotionFinished();
        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        motion.Start(ownner, startTime, blendTime, animSpeed);
        CharacterState::Enter(lastState);
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

    void OnMotionFinished()
    {
        // LogPrint(ownner.GetName() + " state:" + name + " finshed motion:" + motion.animationName);
        ownner.CommonStateFinishedOnGroud();
    }
};

class MultiAnimationState : CharacterState
{
    Array<String> animations;
    bool looped = false;
    float stateTime = -1;
    int selectIndex;

    MultiAnimationState(Character@ c)
    {
        super(c);
    }

    void Update(float dt)
    {
        bool finished = false;
        if (looped)
        {
            if (stateTime > 0 && timeInState > stateTime)
                finished = true;
        }
        else
        {
            if (animSpeed < 0)
            {
                finished = ownner.animCtrl.GetTime(animations[selectIndex]) < 0.0001f;
            }
            else
                finished = ownner.animCtrl.IsAtEnd(animations[selectIndex]);
        }

        if (finished)
            OnMotionFinished();

        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        selectIndex = PickIndex();
        ownner.PlayAnimation(animations[selectIndex], LAYER_MOVE, looped, blendTime, startTime, animSpeed);
        CharacterState::Enter(lastState);
    }

    void OnMotionFinished()
    {
        ownner.CommonStateFinishedOnGroud();
    }

    void AddMotion(const String&in name)
    {
        animations.Push(GetAnimationName(name));
    }

    int PickIndex()
    {
        return ownner.GetNode().vars[ANIMATION_INDEX].GetInt();
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

    ~MultiMotionState()
    {
        motions.Clear();
    }

    void Update(float dt)
    {
        int ret = motions[selectIndex].Move(ownner, dt);
        if (ret == 1)
            OnMotionFinished();
        else if (ret == 2)
            OnMotionAlignTimeOut();
        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        Start();
        CharacterState::Enter(lastState);
    }

    void Start()
    {
        selectIndex = PickIndex();
        if (selectIndex >= int(motions.length))
        {
            LogPrint("ERROR: a large animation index=" + selectIndex + " name:" + ownner.GetName());
            selectIndex = 0;
        }

        if (d_log)
            LogPrint(ownner.GetName() + " state=" + name + " pick " + motions[selectIndex].animationName);
        motions[selectIndex].Start(ownner, startTime, blendTime, animSpeed);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        motions[selectIndex].DebugDraw(debug, ownner);
    }

    int PickIndex()
    {
        return ownner.GetNode().vars[ANIMATION_INDEX].GetInt();
    }

    String GetDebugText()
    {
        return " name=" + name + " timeInState=" + timeInState + " current motion=" + motions[selectIndex].animationName + "\n";
    }

    void AddMotion(const String&in name)
    {
        Motion@ motion = gMotionMgr.FindMotion(name);
        if (motion is null)
            return;
        motions.Push(motion);
    }

    void OnMotionFinished()
    {
        // LogPrint(ownner.GetName() + " state:" + name + " finshed motion:" + motions[selectIndex].animationName);
        ownner.CommonStateFinishedOnGroud();
    }

    void OnMotionAlignTimeOut()
    {
    }
};

class AnimationTestState : CharacterState
{
    Array<Motion@>  testMotions;
    Array<String>   testAnimations;
    int             currentIndex;
    bool            allFinished;

    AnimationTestState(Character@ c)
    {
        super(c);
        SetName("AnimationTestState");
        physicsType = 0;
    }

    ~AnimationTestState()
    {
        testMotions.Clear();
    }

    void Enter(State@ lastState)
    {
        SendAnimationTriger(ownner.renderNode, RAGDOLL_STOP);
        currentIndex = 0;
        allFinished = false;
        Start();
        CharacterState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        if (nextState !is this)
            testMotions.Clear();
        CharacterState::Exit(nextState);
    }

    void Process(Array<String> animations)
    {
        testAnimations.Clear();
        testMotions.Clear();
        testAnimations.Resize(animations.length);
        testMotions.Resize(animations.length);
        for (uint i=0; i<animations.length; ++i)
        {
            testAnimations[i] = animations[i];
            @testMotions[i] = gMotionMgr.FindMotion(animations[i]);
        }
    }

    void Start()
    {
        Motion@ motion = testMotions[currentIndex];
        blendTime = (currentIndex == 0) ? 0.2f : 0.0f;
        if (motion !is null)
        {
            motion.Start(ownner, startTime, blendTime, animSpeed);
            if (ownner.side == 1)
                gCameraMgr.CheckCameraAnimation(motion.name);
        }
        else
        {
            ownner.PlayAnimation(testAnimations[currentIndex], LAYER_MOVE, false, blendTime, startTime, animSpeed);
            if (ownner.side == 1)
                gCameraMgr.CheckCameraAnimation(testAnimations[currentIndex]);
        }
    }

    void Update(float dt)
    {
        if (allFinished)
        {
            if (input.keyDown[KEY_RETURN])
                ownner.CommonStateFinishedOnGroud();
            return;
        }

        bool finished = false;
        Motion@ motion = testMotions[currentIndex];
        if (motion !is null)
        {
            if (!motion.dockAlignBoneName.empty)
            {
                float t = ownner.animCtrl.GetTime(motion.animationName);
                if (t < motion.dockAlignTime && (t + dt) > motion.dockAlignTime)
                {
                    // ownner.SetSceneTimeScale(0.0f);
                }
            }

            finished = motion.Move(ownner, dt) == 1;
            if (motion.looped && timeInState > 2.0f)
                finished = true;
        }
        else
        {
            if (animSpeed < 0)
            {
                finished = ownner.animCtrl.GetTime(testAnimations[currentIndex]) < 0.0001f;
            }
            else
                finished = ownner.animCtrl.IsAtEnd(testAnimations[currentIndex]);
        }

        if (finished) {
            LogPrint("AnimationTestState finished, currentIndex=" + currentIndex);
            currentIndex ++;
            if (currentIndex >= int(testAnimations.length))
            {
                //ownner.CommonStateFinishedOnGroud();
                allFinished = true;
            }
            else
                Start();
        }

        CharacterState::Update(dt);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        if (currentIndex >= int(testMotions.length))
            return;
        Motion@ motion = testMotions[currentIndex];
        if (motion !is null)
            motion.DebugDraw(debug, ownner);
    }

    String GetDebugText()
    {
        if (currentIndex >= int(testAnimations.length))
            return CharacterState::GetDebugText();
        return " name=" + this.name + " timeInState=" + timeInState + " animation=" + testAnimations[currentIndex] + "\n";
    }

    bool CanReEntered()
    {
        return true;
    }
};

enum CounterSubState
{
    COUNTER_NONE,
    COUNTER_WAITING,
    COUNTER_ANIMATING,
};

class CharacterCounterState : CharacterState
{
    Array<Motion@>      doubleCounterMotions;
    Array<Motion@>      tripleCounterMotions;

    Array<Motion@>      frontArmMotions;
    Array<Motion@>      frontLegMotions;
    Array<Motion@>      backArmMotions;
    Array<Motion@>      backLegMotions;

    Motion@             currentMotion;
    int                 state; // sub state
    int                 type;
    int                 index;

    float               alignTime = 0.2f;
    Vector3             movePerSec;
    float               yawPerSec;
    Vector3             targetPosition;
    float               targetRotation;

    CharacterCounterState(Character@ c)
    {
        super(c);
        SetName("CounterState");
    }

    void Enter(State@ lastState)
    {
        if (lastState.nameHash != ALIGN_STATE)
            state = COUNTER_NONE;
        CharacterState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        CharacterState::Exit(nextState);
        if (nextState.nameHash != ALIGN_STATE)
        {
            @currentMotion = null;
            state = COUNTER_NONE;
        }
    }

    void StartCounterMotion()
    {
        if (currentMotion is null)
            return;
        LogPrint(ownner.GetName() + " start counter motion " + currentMotion.animationName);
        ChangeSubState(COUNTER_ANIMATING);
        currentMotion.Start(ownner);
    }

    int GetCounterDirection(int attackType, bool isBack)
    {
        if (attackType == ATTACK_PUNCH)
            return isBack ? 1 : 0;
        else
            return isBack ? 3 : 2;
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
            Vector3 startDiff = other_motion.GetStartPos() - motion.GetStartPos();
            LogPrint("couter-motion " + motion.name + " diff-len=" + startDiff.length);
        }
    }

    void Update(float dt)
    {
        if (state == COUNTER_ANIMATING)
        {
             if (currentMotion.Move(ownner, dt) == 1)
             {
                ownner.CommonStateFinishedOnGroud();
                return;
             }
        }
        CharacterState::Update(dt);
    }

    void ChangeSubState(int newState)
    {
        if (state == newState)
            return;

        LogPrint(ownner.GetName() + " CounterState ChangeSubState from " + state + " to " + newState);
        state = newState;
    }

    void Dump()
    {
        DumpCounterMotions(frontArmMotions);
        DumpCounterMotions(backArmMotions);
        DumpCounterMotions(frontLegMotions);
        DumpCounterMotions(backLegMotions);
    }

    void AddMultiCounterMotions(const String&in preFix, bool isPlayer)
    {
        if (isPlayer)
        {
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsA"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsB"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsD"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsE"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsF"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsG"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_2ThugsH"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_3ThugsA"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_3ThugsB"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_3ThugsC"));
        }
        else
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
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_3ThugsA_01"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_3ThugsA_02"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_3ThugsA_03"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_3ThugsB_01"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_3ThugsB_02"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_3ThugsB_03"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_3ThugsC_01"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_3ThugsC_02"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix + "Double_Counter_3ThugsC_03"));
        }
    }

    void AddCW_Counter_Animations(const String&in preFix, const String& preFix1, bool isPlayer)
    {
        // Front Arm
        frontArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Front_Weak_01"));
        frontArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Front_Weak_02"));
        for(int i=1; i<=5; ++i)
            frontArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Front_0" + i));
        // Front Leg
        frontLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Front_Weak_01"));
        frontLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Front_Weak_02"));
        frontLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Front_01"));
        frontLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Front_03"));
        frontLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Front_04"));
        // Back Arm
        backArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Back_Weak_01"));
        backArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Back_Weak_02"));
        for(int i=1; i<=3; ++i)
            backArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Back_0" + i));

        // Back Leg
        backLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Back_Weak_01"));
        backLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Back_Weak_02"));
        backLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Back_01"));
        backLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Back_02"));

        if (isPlayer)
        {
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsA"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsB"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsC"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsD"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsE"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsF"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsG"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsH"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_3ThugsA"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_3ThugsB"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_3ThugsC"));
        }
        else
        {
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsA_01"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsA_02"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsB_01"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsB_02"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsC_01"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsC_02"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsD_01"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsD_02"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsE_01"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsE_02"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsF_01"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsF_02"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsG_01"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsG_02"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsH_01"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsH_02"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_3ThugsA_01"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_3ThugsA_02"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_3ThugsA_03"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_3ThugsB_01"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_3ThugsB_02"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_3ThugsB_03"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_3ThugsC_01"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_3ThugsC_02"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_3ThugsC_03"));
        }
    }

    void AddBW_Counter_Animations(const String&in preFix, const String& preFix1, bool isPlayer)
    {
        // Front Arm
        frontArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Front_Weak_02"));
        for(int i=1; i<=9; ++i)
            frontArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Front_0" + i));
        frontArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Front_10"));
        // Front Leg
        frontLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Front_Weak"));
        for(int i=1; i<=6; ++i)
            frontLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Front_0" + i));
        // Back Arm
        backArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Back_Weak_01"));
        for(int i=1; i<=4; ++i)
            frontArmMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Arm_Back_0" + i));
        // Back Leg
        backLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Back_Weak_01"));
        backLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Back_01"));
        backLegMotions.Push(gMotionMgr.FindMotion(preFix + "Counter_Leg_Back_02"));

        if (isPlayer)
        {
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsA"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsB"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsD"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsE"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsF"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsG"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsH"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_3ThugsB"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_3ThugsC"));
        }
        else
        {
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsA_01"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsA_02"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsB_01"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsB_02"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsD_01"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsD_02"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsE_01"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsE_02"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsF_01"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsF_02"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsG_01"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsG_02"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsH_01"));
            doubleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_2ThugsH_02"));

            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_3ThugsB_01"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_3ThugsB_02"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_3ThugsB_03"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_3ThugsC_01"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_3ThugsC_02"));
            tripleCounterMotions.Push(gMotionMgr.FindMotion(preFix1 + "Double_Counter_3ThugsC_03"));
        }
    }


    void SetTargetTransform(const Vector3&in pos, float rot)
    {
        Vector3 pos1 = ownner.GetNode().worldPosition;
        targetPosition = pos;
        targetPosition.y = pos1.y;
        targetRotation = rot;
    }

    void StartAligning()
    {
        CharacterAlignState@ state = cast<CharacterAlignState>(ownner.FindState(ALIGN_STATE));
        state.Start(this.nameHash, targetPosition, targetRotation, alignTime, 0, ownner.walkAlignAnimation);
        ownner.ChangeStateQueue(ALIGN_STATE);
    }

    String GetDebugText()
    {
        return "current motion=" + currentMotion.animationName;
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        debug.AddCross(targetPosition, 1.0f, RED, false);
        DebugDrawDirection(debug, ownner.GetNode().worldPosition, targetRotation, YELLOW);
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
            int ragdoll_state = ownner.GetNode().vars[RAGDOLL_STATE].GetInt();
            if (ragdoll_state == RAGDOLL_NONE)
            {
                if (ownner.health > 0)
                {
                    ownner.PlayCurrentPose();
                    ownner.ChangeState("GetUpState");
                }
                else
                {
                    ownner.ChangeState("DeadState");
                }
            }
        }
        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        CharacterState::Enter(lastState);
        ownner.SetPhysics(false);
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
        if (selectIndex >= int(motions.length))
        {
            LogPrint("ERROR: a large animation index=" + selectIndex + " name:" + ownner.GetName());
            selectIndex = 0;
        }

        Motion@ motion = motions[selectIndex];
        //if (blend_to_anim)
        //    ragdollToAnimTime = 0.2f;
        ownner.PlayAnimation(motion.animationName, LAYER_MOVE, false, ragdollToAnimTime, 0.0f, 0.0f);
        CharacterState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        MultiMotionState::Exit(nextState);
        ownner.animModel.updateInvisible = true;
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
            if (motion.Move(ownner, dt) == 1)
            {
                ownner.CommonStateFinishedOnGroud();
                return;
            }
        }

        CharacterState::Update(dt);
    }
};

class CharacterAlignState : CharacterState
{
    StringHash  nextStateName;
    String      alignAnimation;
    Vector3     targetPosition;
    float       targetRotation;
    Vector3     movePerSec;
    float       rotatePerSec;
    float       alignTime = 0.2f;

    CharacterAlignState(Character@ c)
    {
        super(c);
        SetName("AlignState");
    }

    void Start(StringHash nextState, const Vector3&in tPos, float tRot, float duration, int physicsType = 0, const String&in anim = "")
    {
        LogPrint("CharacterAlign--start duration=" + duration);
        nextStateName = nextState;
        targetPosition = tPos;
        targetRotation = tRot;
        alignTime = duration;
        alignAnimation = anim;
        ownner.SetPhysicsType(physicsType);

        Vector3 curPos = ownner.GetNode().worldPosition;
        float curAngle = ownner.GetCharacterAngle();
        movePerSec = (tPos - curPos) / duration;
        rotatePerSec = AngleDiff(tRot - curAngle) / duration;

        if (anim != "")
        {
            LogPrint("align-animation : " + anim);
            ownner.PlayAnimation(anim, LAYER_MOVE, true);
        }
    }

    void Update(float dt)
    {
        if (ownner.physicsType == 0)
            ownner.MoveTo(ownner.GetNode().worldPosition + movePerSec * dt, dt);
        else
            ownner.SetVelocity(movePerSec);
        ownner.GetNode().Yaw(rotatePerSec * dt);
        CharacterState::Update(dt);
        if (timeInState >= alignTime)
            OnAlignTimeOut();
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        DebugDrawDirection(debug, ownner.GetNode().worldPosition, targetRotation, RED, 2.0f);
        debug.AddCross(targetPosition, 0.5f, YELLOW, false);
    }

    void OnAlignTimeOut()
    {
        LogPrint(ownner.GetName() + " On_Align_Finished-- at: " + time.systemTime);
        ownner.Transform(targetPosition, Quaternion(0, targetRotation, 0));
        ownner.ChangeState(nextStateName);
    }
};

class Character : GameObject
{
    FSM@    stateMachine = FSM();

    Character@              target;

    Node@                   sceneNode;
    Node@                   renderNode;

    AnimationController@    animCtrl;
    AnimatedModel@          animModel;
    CrowdAgent@             agent;

    Vector3                 startPosition;
    Quaternion              startRotation;

    Animation@              ragdollPoseAnim;

    int                     health = INITIAL_HEALTH;

    float                   attackRadius = 0.15f;
    int                     attackDamage = 10;

    RigidBody@              body;

    int                     physicsType;

    String                  lastAnimation;
    String                  walkAlignAnimation;

    PhysicsSensor@          sensor;

    // ==============================================
    //   DYNAMIC VALUES For Motion
    // ==============================================
    Vector3                 motion_startPosition;
    float                   motion_startRotation;

    float                   motion_deltaRotation;
    Vector3                 motion_deltaPosition;
    Vector3                 motion_velocity;

    bool                    motion_translateEnabled = true;
    bool                    motion_rotateEnabled = true;

    void ObjectStart()
    {
        sceneNode = node;
        renderNode = sceneNode.GetChild("RenderNode", false);
        animCtrl = renderNode.GetComponent("AnimationController");
        animModel = renderNode.GetComponent("AnimatedModel");

        startPosition = sceneNode.worldPosition;
        startRotation = sceneNode.worldRotation;
        sceneNode.vars[TIME_SCALE] = 1.0f;

        String name = sceneNode.name + "_Ragdoll_Pose";
        ragdollPoseAnim = cache.GetResource("Animation", name);
        if (ragdollPoseAnim is null)
        {
            // LogPrint("Creating animation for ragdoll pose " + name);
            ragdollPoseAnim = Animation();
            ragdollPoseAnim.name = name;
            ragdollPoseAnim.animationName = name;
            cache.AddManualResource(ragdollPoseAnim);
        }

        if (collision_type == 1)
        {
            body = sceneNode.CreateComponent("RigidBody");
            body.collisionLayer = COLLISION_LAYER_CHARACTER;
            body.collisionMask = COLLISION_LAYER_LANDSCAPE | COLLISION_LAYER_PROP;
            body.mass = 1.0f;
            body.angularFactor = Vector3(0.0f, 0.0f, 0.0f);
            body.collisionEventMode = COLLISION_ALWAYS;
            CollisionShape@ shape = sceneNode.CreateComponent("CollisionShape");
            shape.SetCapsule(COLLISION_RADIUS*2, CHARACTER_HEIGHT, Vector3(0.0f, CHARACTER_HEIGHT/2, 0.0f));
            physicsType = 1;
            SetGravity(Vector3(0, -20, 0));
        }

        if (bigHeadMode)
        {
            renderNode.position = Vector3(0, 0.3f, 0);
        }

        SetHealth(INITIAL_HEALTH);
        SubscribeToEvent(renderNode, "AnimationTrigger", "HandleAnimationTrigger");

        if (one_shot_kill)
            attackDamage = 9999;
    }

    void Start()
    {
        //LogPrint("============================== begin Object Start ==============================");
        uint startTime = time.systemTime;
        ObjectStart();
        LogPrint(sceneNode.name + " ObjectStart time-cost=" + String(time.systemTime - startTime) + " ms");
        //LogPrint("============================== end Object Start ==============================");
    }

    void Stop()
    {
        LogPrint("Character::Stop " + sceneNode.name);
        @stateMachine = null;
        @sceneNode = null;
        @animCtrl = null;
        @animModel = null;
        @target = null;
        @agent = null;
    }

    void Remove()
    {
        Stop();
        GameObject::Remove();
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
            if (d_log)
                LogPrint("SetSpeed " + state.animation.name + " scale " + scale);
            animCtrl.SetSpeed(state.animation.name, scale);
        }
        if (body !is null)
            body.linearVelocity = body.linearVelocity * scale;

        sceneNode.vars[TIME_SCALE] = scale;
    }

    void PlayAnimation(const String&in animName, uint layer = LAYER_MOVE, bool loop = false, float blendTime = 0.1f, float startTime = 0.0f, float speed = 1.0f)
    {
        if (d_log)
            LogPrint(GetName() + " PlayAnimation " + animName + " loop=" + loop + " blendTime=" + blendTime + " startTime=" + startTime + " speed=" + speed);

        if (layer == LAYER_MOVE && lastAnimation == animName && loop)
            return;

        lastAnimation = animName;
        AnimationController@ ctrl = animCtrl;
        ctrl.StopLayer(layer, blendTime);
        ctrl.PlayExclusive(animName, layer, loop, blendTime);
        ctrl.SetSpeed(animName, speed * timeScale);
        ctrl.SetTime(animName, (speed < 0) ? ctrl.GetLength(animName) : startTime);
    }

    String GetDebugText()
    {
        String debugText = stateMachine.GetDebugText();
        debugText += "name:" + sceneNode.name + " pos:" + sceneNode.worldPosition.ToString() + " timeScale:" + timeScale + " health:" + health + "\n";
        if (animModel.numAnimationStates > 0)
        {
            debugText += "Debug-Animations:\n";
            for (uint i=0; i<animModel.numAnimationStates; ++i)
            {
                AnimationState@ state = animModel.GetAnimationState(i);
                if (state.weight > 0.0f && state.enabled)
                    debugText +=  state.animation.name + " time=" + String(state.time) + " weight=" + String(state.weight) + "\n";
            }
        }
        return debugText;
    }

    void SetVelocity(const Vector3&in vel)
    {
        // LogPrint("body.linearVelocity = " + vel.ToString());
        if (body !is null)
            body.linearVelocity = vel;
    }

    Vector3 GetVelocity()
    {
        return body !is null ? body.linearVelocity : Vector3(0, 0, 0);
    }

    void MoveTo(const Vector3& position, float dt)
    {
        sceneNode.worldPosition = FilterPosition(position);
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
        ChangeState("RedirectState");
        return false;
    }

    bool Distract()
    {
        return false;
    }

    void CommonStateFinishedOnGroud()
    {
        ChangeState("StandState");
    }

    void Reset()
    {
        flags = FLAGS_ATTACK;
        sceneNode.worldPosition = startPosition;
        sceneNode.worldRotation = startRotation;
        SetHealth(INITIAL_HEALTH);
        SetTimeScale(1.0f);
        ChangeState("StandState");
    }

    void SetHealth(int h)
    {
        health = h;
    }

    bool CanBeAttacked()
    {
        if (HasFlag(FLAGS_INVINCIBLE))
            return false;
        return HasFlag(FLAGS_ATTACK);
    }

    bool CanBeCountered()
    {
        return HasFlag(FLAGS_COUNTER);
    }

    bool CanAttack()
    {
        return false;
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        stateMachine.DebugDraw(debug);
        debug.AddNode(sceneNode, 1.5f, false);
    }

    void TestAnimation(const Array<String>&in animations)
    {
        AnimationTestState@ state = cast<AnimationTestState>(stateMachine.FindState("AnimationTestState"));
        if (state is null)
            return;
        state.Process(animations);
        ChangeState("AnimationTestState");
    }

    void TestAnimation(const String&in animation)
    {
        Array<String> animations = { animation };
        TestAnimation(animations);
    }


    float GetTargetAngle()
    {
        return target !is null ? GetTargetAngle(target.GetNode()) : 0.0f;
    }

    float GetTargetDistance()
    {
        return target !is null ? GetTargetDistance(target.GetNode()) : 0.0f;
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
        return GetTargetAngle(_node.worldPosition);
    }

    float GetTargetDistance(Node@ _node)
    {
        return GetTargetDistance(_node.worldPosition);
    }

    float ComputeAngleDiff(Node@ _node)
    {
        return AngleDiff(GetTargetAngle(_node) - GetCharacterAngle());
    }

    float GetTargetAngle(Vector3 targetPos)
    {
        Vector3 diff = targetPos - sceneNode.worldPosition;
        return Atan2(diff.x, diff.z);
    }

    float GetTargetDistance(Vector3 targetPos)
    {
        Vector3 diff = targetPos - sceneNode.worldPosition;
        return diff.length;
    }

    float ComputeAngleDiff(Vector3 targetPos)
    {
        return AngleDiff(GetTargetAngle(targetPos) - GetCharacterAngle());
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
        Vector3 fwd_dir = renderNode.worldRotation * Vector3(0, 0, 1);
        Vector3 pt_lf = renderNode.GetChild("Bip01_L_Foot").worldPosition - renderNode.worldPosition;
        Vector3 pt_rf = renderNode.GetChild("Bip01_R_Foot").worldPosition - renderNode.worldPosition;
        float dot_lf = pt_lf.DotProduct(fwd_dir);
        float dot_rf = pt_rf.DotProduct(fwd_dir);
        LogPrint(sceneNode.name + " dot_lf=" + dot_lf + " dot_rf=" + dot_rf + " diff=" + (dot_lf - dot_rf));
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
        ChangeState("HitState");
        return true;
    }

    Node@ GetNode()
    {
        return sceneNode;
    }

    void OnDead()
    {
        LogPrint(GetName() + " OnDead !!!");
        ChangeState("DeadState");
    }

    void MakeMeRagdoll(const Vector3&in velocity = Vector3(0, 0, 0), const Vector3&in position = Vector3(0, 0, 0))
    {
        LogPrint(GetName() + " MakeMeRagdoll -- velocity=" + velocity.ToString() + " position=" + position.ToString());
        VariantMap anim_data;
        anim_data[NAME] = RAGDOLL_START;
        anim_data[VELOCITY] = velocity;
        anim_data[POSITION] = position;
        VariantMap data;
        data[DATA] = anim_data;
        renderNode.SendEvent("AnimationTrigger", data);
    }

    void OnAttackSuccess(Character@ object)
    {

    }

    void OnCounterSuccess()
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

        // LogPrint(GetName() + " SpawnParticleEffect pos=" + position.ToString() + " effectName=" + effectName + " duration=" + duration);

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

    void SetComponentEnabled(const String&in boneName, const String&in componentName, bool bEnable)
    {
        Node@ _node = sceneNode.GetChild(boneName, true);
        if (_node is null)
            return;
        Component@ comp = _node.GetComponent(componentName);
        if (comp is null)
            return;
        comp.enabled = bEnable;
    }

    void SetNodeEnabled(const String&in nodeName, bool bEnable)
    {
        Node@ n = sceneNode.GetChild(nodeName, true);
        if (n !is null)
            n.enabled = bEnable;
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

    bool ChangeState(const String&in name)
    {
        if (d_log)
        {
            String oldStateName = stateMachine.currentState !is null ? stateMachine.currentState.name : "null";
            LogPrint(GetName() + " ChangeState from " + oldStateName + " to " + name);
        }
        bool ret = stateMachine.ChangeState(name);
        State@ s = GetState();
        if (s is null)
            return ret;
        sceneNode.vars[STATE] = s.nameHash;
        return ret;
    }

    bool ChangeState(const StringHash&in nameHash)
    {
        String oldStateName = stateMachine.currentState !is null ? stateMachine.currentState.name : "null";
        bool ret = stateMachine.ChangeState(nameHash);
        String newStateName = stateMachine.currentState !is null ? stateMachine.currentState.name : "null";
        if (d_log)
            LogPrint(GetName() + " ChangedState from " + oldStateName + " to " + newStateName);
        sceneNode.vars[STATE] = GetState().nameHash;
        return ret;
    }

    void ChangeStateQueue(const StringHash&in nameHash)
    {
        stateMachine.ChangeStateQueue(nameHash);
    }

    State@ FindState(const String&in name)
    {
        return stateMachine.FindState(name);
    }

    State@ FindState(const StringHash&in nameHash)
    {
        return stateMachine.FindState(nameHash);
    }

    void FixedUpdate(float timeStep)
    {
        timeStep *= timeScale;

        if (stateMachine !is null)
            stateMachine.FixedUpdate(timeStep);

        CheckDuration(timeStep);
    }

    void Update(float timeStep)
    {
        timeStep *= timeScale;

        if (stateMachine !is null)
            stateMachine.Update(timeStep);
    }

    void CheckCollision()
    {

    }

    void SetTarget(Character@ t)
    {
        if (t is target)
            return;
        @target = t;
        // LogPrint(GetName() + " SetTarget=" + ((t !is null) ? t.GetName() : "null"));
    }

    void SetPhysics(bool b)
    {
        if (body !is null)
            body.enabled = b;
        SetNodeEnabled("Collision", b);
    }

    void PlayRandomSound(int type)
    {
        if (type == 0)
            PlaySound("Sfx/impact_" + (RandomInt(num_of_sounds) + 1) + ".ogg");
        else if (type == 1)
            PlaySound("Sfx/big_" + (RandomInt(num_of_big_sounds) + 1) + ".ogg");
    }

    bool ActionCheck(uint actionFlags = 0xFF)
    {
        return false;
    }

    bool IsVisible()
    {
        return animModel.IsInView(gCameraMgr.GetCamera());
    }

    void CheckAvoidance(float dt)
    {

    }

    void ClearAvoidance()
    {
    }

    bool CheckRagdollHit()
    {
        return false;
    }

    void CheckTargetDistance(Character@ t, float dist)
    {
        if (t is null)
            return;
        if (motion_translateEnabled && GetTargetDistance(t.GetNode()) < dist)
        {
            LogPrint(GetName() + " is too close to " + t.GetName() + " set translateEnabled to false");
            motion_translateEnabled = false;
        }
    }

    bool IsInAir()
    {
        Vector3 lf_pos = renderNode.GetChild(L_FOOT, true).worldPosition;
        Vector3 rf_pos = renderNode.GetChild(R_FOOT, true).worldPosition;
        Vector3 myPos = sceneNode.worldPosition;
        float lf_to_ground = (lf_pos.y - myPos.y);
        float rf_to_graound = (rf_pos.y - myPos.y);
        return lf_to_ground > 1.0f && rf_to_graound > 1.0f;
    }

    void SetHeight(float height)
    {
        CollisionShape@ shape = sceneNode.GetComponent("CollisionShape");
        if (shape !is null)
        {
            shape.size = Vector3(COLLISION_RADIUS * 2, height, 0);
            shape.SetTransform(Vector3(0.0f, height/2, 0.0f), Quaternion());
        }
    }

    void SetPhysicsType(int type)
    {
        if (physicsType == type)
            return;
        physicsType = type;
        if (body !is null)
        {
            body.enabled = (physicsType == 1);
            body.position = sceneNode.worldPosition;
        }
    }

    void SetGravity(const Vector3& gravity)
    {
        if (body !is null)
            body.gravityOverride = gravity;
    }

    Node@ GetTargetSightBlockedNode(const Vector3&in targetPos)
    {
        Vector3 my_mid_pos = sceneNode.worldPosition;
        my_mid_pos.y += CHARACTER_HEIGHT/2;
        Vector3 target_mid_pos = targetPos;
        target_mid_pos.y += CHARACTER_HEIGHT/2;
        Vector3 dir = target_mid_pos - my_mid_pos;
        Vector3 dir_normalized = dir.Normalized();
        float offset = (COLLISION_RADIUS + 0.01f + SPHERE_CAST_RADIUS);
        if (offset < 0)
            return null;
        my_mid_pos += dir_normalized * offset;

        float rayDistance = dir.length - offset;
        Ray sightRay;
        sightRay.origin = my_mid_pos;
        sightRay.direction = dir_normalized;
        PhysicsRaycastResult result = sceneNode.scene.physicsWorld.SphereCast(sightRay, SPHERE_CAST_RADIUS, rayDistance, COLLISION_LAYER_CHARACTER | COLLISION_LAYER_AI);

        /*
        if (drawDebug > 0)
        {
            Vector3 start = my_mid_pos;
            Vector3 end = my_mid_pos + sightRay.direction * rayDistance;
            const float debugTime = 2.5f;
            gDebugMgr.AddSphere(start, SPHERE_CAST_RADIUS, YELLOW, debugTime);
            gDebugMgr.AddSphere(end, SPHERE_CAST_RADIUS, YELLOW, debugTime);
            gDebugMgr.AddLine(start, end, YELLOW, debugTime);
            if (result.body !is null)
                gDebugMgr.AddSphere(result.position, SPHERE_CAST_RADIUS, RED, debugTime);
        }
        */

        if (result.body is null)
            return null;
        Node@ node = result.body.node;
        if (node.scriptObject is null)
            return node.parent;
        return node;
    }

    bool IsDead()
    {
        return (health == 0);
    }

    // ===============================================================================================
    //  EVENT HANDLERS
    // ===============================================================================================
    void HandleAnimationTrigger(StringHash eventType, VariantMap& eventData)
    {
        AnimationState@ state = animModel.animationStates[eventData[NAME].GetString()];
        CharacterState@ cs = cast<CharacterState>(stateMachine.currentState);
        if (cs !is null)
            cs.OnAnimationTrigger(state, eventData[DATA].GetVariantMap());
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

int GetDirectionZone(const Vector3&in from, const Vector3& to, int numDirections, float fromAngle = 0.0f)
{
    Vector3 dir = to - from;
    float angle = Atan2(dir.x, dir.z) - fromAngle;
    return DirectionMapToIndex(AngleDiff(angle), numDirections);
}

Node@ CreateCharacter(const String&in name, const String&in objectName, const String&in scriptClass, const Vector3&in position, const Quaternion& rotation)
{
    XMLFile@ xml = cache.GetResource("XMLFile", "Objects/" + objectName + ".xml");
    Node@ p_node = script.defaultScene.InstantiateXML(xml, position, rotation);
    p_node.name = name;
    p_node.CreateScriptObject(scriptFile, scriptClass);
    p_node.CreateScriptObject(scriptFile, "Ragdoll");
    p_node.CreateScriptObject(scriptFile, "HeadIndicator");
    return p_node;
}