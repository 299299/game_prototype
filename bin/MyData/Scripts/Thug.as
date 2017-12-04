// ==============================================
//
//    Thug Pawn and Controller Class
//
// ==============================================

// --- CONST
const String MOVEMENT_GROUP_THUG = "TG_Combat/";
const float MIN_TURN_ANGLE = 30;
const float MIN_THINK_TIME = 0.25f;
const float MAX_THINK_TIME = 1.0f;
const float MAX_ATTACK_RANGE = 3.0f;
const Vector3 HIT_RAGDOLL_FORCE(25.0f, 10.0f, 0.0f);

const float AI_FAR_DIST = 15.0f;
const float AI_NEAR_DIST = 7.5f;

// -- NON CONST
float PUNCH_DIST = 0.0f;
float KICK_DIST = 0.0f;
float STEP_MAX_DIST = 0.0f;
float STEP_MIN_DIST = 0.0f;
float KEEP_DIST_WITH_PLAYER = COLLISION_SAFE_DIST + 0.05f;

Array<Motion@> thug_counter_arm_front_motions;
Array<Motion@> thug_counter_arm_back_motions;
Array<Motion@> thug_counter_leg_front_motions;
Array<Motion@> thug_counter_leg_back_motions;
Array<Motion@> thug_counter_double_motions;
Array<Motion@> thug_counter_triple_motions;

class ThugStandState : MultiAnimationState
{
    float           thinkTime;

    ThugStandState(Character@ c)
    {
        super(c);
        SetName("StandState");
        for (uint i=1; i<=4; ++i)
            AddMotion(MOVEMENT_GROUP_THUG + "Stand_Idle_Additive_0" + i);
        flags = FLAGS_ATTACK | FLAGS_COLLISION_AVOIDENCE | FLAGS_HIT_RAGDOLL;
        looped = true;
    }

    void Enter(State@ lastState)
    {
        thinkTime = Random(MIN_THINK_TIME, MAX_THINK_TIME);
        if (d_log)
            LogPrint(ownner.GetName() + " thinkTime=" + thinkTime);
        ownner.ClearAvoidance();
        MultiAnimationState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        MultiAnimationState::Exit(nextState);
        ownner.animModel.updateInvisible = false;
    }

    void Update(float dt)
    {
        if (freeze_ai != 0)
           return;

        if (timeInState > thinkTime)
        {
            OnThinkTimeOut();
            timeInState = 0.0f;
            thinkTime = Random(MIN_THINK_TIME, MAX_THINK_TIME);
        }

        MultiAnimationState::Update(dt);
    }

    void OnThinkTimeOut()
    {
        if (d_log)
            LogPrint(ownner.GetName() + " OnThinkTimeOut think-time=" + thinkTime);

        if (ownner.target.HasFlag(FLAGS_DEAD))
        {
            int rand_i = RandomInt(2);
            if (rand_i == 0)
            {
                ownner.ChangeState("TauntingState");
            }
            else if (rand_i == 1)
            {
                ownner.ChangeState("TauntIdleState");
            }
            return;
        }

        float characterDifference = ownner.ComputeAngleDiff();
        if (Abs(characterDifference) > MIN_TURN_ANGLE)
        {
            ownner.GetNode().vars[TARGET] = ownner.target.GetNode().worldPosition;
            ownner.ChangeState("TurnState");
            return;
        }

        if (ownner.HasFlag(FLAGS_NO_MOVE))
        {
            ownner.ChangeState("TauntIdleState");
            return;
        }

        if (ownner.ActionCheck())
        {
            // Print(ownner.GetName() + " ActionCheck success !!");
            return;
        }

        Node@ _node = ownner.GetNode();
        EnemyManager@ em = GetEnemyMgr();
        float dist = ownner.GetTargetDistance();
        int num_near_thugs = em.GetNumOfEnemyWithinDistance(AI_NEAR_DIST);

        if (dist >= AI_FAR_DIST)
        {
            float range = AI_FAR_DIST;
            if (num_near_thugs < MAX_NUM_OF_NEAR)
                range = AI_NEAR_DIST;

            Vector3 v = em.FindGoodTargetPosition(cast<Enemy>(ownner), range + COLLISION_SAFE_DIST - 1.0f);
            // bool can_i_see_target = (ownner.GetTargetSightBlockedNode(v) is null);
            LogPrint(ownner.GetName() + " far away, tryinng to approach v=" + v.ToString());
            // if (can_i_see_target)
            {
                ownner.GetNode().vars[TARGET] = v;
                ownner.ChangeState("RunToTargetState");
            }
            return;
        }

        int num_of_run_to_attack_thugs = em.GetNumOfEnemyHasFlag(FLAGS_RUN_TO_ATTACK);
        Node@ target_sight_node = ownner.GetTargetSightBlockedNode(ownner.target.GetNode().worldPosition);
        bool can_i_see_target = (target_sight_node is null) || (target_sight_node is ownner.target.GetNode());
        // Print(ownner.GetName() + " num_of_run_to_attack_thugs=" + num_of_run_to_attack_thugs + " can_i_see_target=" + can_i_see_target);
        if (can_i_see_target && num_of_run_to_attack_thugs < MAX_NUM_OF_RUN_ATTACK && ownner.target.HasFlag(FLAGS_ATTACK))
        {
            ownner.ChangeState("RunToAttackState");
            return;
        }

        int rand_i = RandomInt(3);
        // Print(ownner.GetName() + " rand_i=" + rand_i);
        if (rand_i == 0)
        {
            ownner.ChangeState("TauntingState");
        }
        else if (rand_i == 1)
        {
            ownner.ChangeState("TauntIdleState");
        }
        else
        {
            _node.vars[ANIMATION_INDEX] = RandomInt(8);
            ownner.ChangeState("StepMoveState");
        }

        return;
    }

    void FixedUpdate(float dt)
    {
        ownner.CheckAvoidance(dt);
        MultiAnimationState::FixedUpdate(dt);
    }

    int PickIndex()
    {
        return RandomInt(animations.length);
    }
};

class ThugStepMoveState : MultiMotionState
{
    ThugStepMoveState(Character@ c)
    {
        super(c);
        SetName("StepMoveState");
        // short step
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Forward");
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Right");
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Back");
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Left");
        // long step
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Forward_Long");
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Right_Long");
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Back_Long");
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Left_Long");
        flags = FLAGS_ATTACK | FLAGS_MOVING | FLAGS_KEEP_DIST | FLAGS_HIT_RAGDOLL;

        if (STEP_MAX_DIST == 0.0f)
        {
            STEP_MIN_DIST = motions[0].endDistance;
            STEP_MAX_DIST = motions[4].endDistance;
            LogPrint("Thug min-step-dist=" + STEP_MIN_DIST + " max-step-dist=" + STEP_MAX_DIST);
        }
    }

    float GetThreatScore()
    {
        return 0.333f;
    }
};

class ThugRunToAttackState : SingleMotionState
{
    float turnSpeed = 5.0f;

    ThugRunToAttackState(Character@ c)
    {
        super(c);
        SetName("RunToAttackState");
        SetMotion(MOVEMENT_GROUP_THUG + "Run_Forward_Combat");
        flags = FLAGS_ATTACK | FLAGS_MOVING | FLAGS_RUN_TO_ATTACK | FLAGS_HIT_RAGDOLL | FLAGS_COLLISION_AVOIDENCE;
    }

    void Update(float dt)
    {
        float characterDifference = ownner.ComputeAngleDiff();
        ownner.GetNode().Yaw(characterDifference * turnSpeed * dt);

        // if the difference is large, then turn 180 degrees
        if (Abs(characterDifference) > FULLTURN_THRESHOLD)
        {
            ownner.GetNode().vars[TARGET] = ownner.target.GetNode().worldPosition;
            ownner.ChangeState("TurnState");
            return;
        }

        if (ownner.ActionCheck())
            return;

        float dist = ownner.GetTargetDistance();
        if (dist < KEEP_DIST_WITH_PLAYER)
        {
            ownner.CommonStateFinishedOnGroud();
            return;
        }

        SingleMotionState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        SingleMotionState::Enter(lastState);
        ownner.ClearAvoidance();
    }

    void FixedUpdate(float dt)
    {
        ownner.CheckAvoidance(dt);
        CharacterState::FixedUpdate(dt);
    }

    float GetThreatScore()
    {
        return 0.333f;
    }
};

class ThugRunToTargetState : SingleMotionState
{
    Vector3 targetPosition;
    float turnSpeed = 5.0f;

    ThugRunToTargetState(Character@ c)
    {
        super(c);
        SetName("RunToTargetState");
        SetMotion(MOVEMENT_GROUP_THUG + "Run_Forward_Combat");
        flags = FLAGS_ATTACK | FLAGS_MOVING | FLAGS_COLLISION_AVOIDENCE | FLAGS_HIT_RAGDOLL;
    }

    void Update(float dt)
    {
        float characterDifference = ownner.ComputeAngleDiff(targetPosition);
        ownner.GetNode().Yaw(characterDifference * turnSpeed * dt);
        if (Abs(characterDifference) > FULLTURN_THRESHOLD)
        {
            ownner.GetNode().vars[TARGET] = targetPosition;
            ownner.ChangeState("TurnState");
            return;
        }

        Vector3 distV = targetPosition - ownner.GetNode().worldPosition;
        distV.y = 0;
        if (distV.length < KEEP_DIST_WITH_PLAYER)
        {
            ownner.CommonStateFinishedOnGroud();
            return;
        }

        SingleMotionState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        SingleMotionState::Enter(lastState);
        targetPosition = ownner.GetNode().vars[TARGET].GetVector3();
        cast<Enemy>(ownner).targetZoneToPlayer = GetDirectionZone(ownner.target.GetNode().worldPosition, targetPosition, NUM_ZONE_DIRECTIONS);
        LogPrint(ownner.GetName() + " targetZoneToPlayer=" + cast<Enemy>(ownner).targetZoneToPlayer);
        ownner.ClearAvoidance();
    }

    void Exit(State@ nextState)
    {
        SingleMotionState::Exit(nextState);
        cast<Enemy>(ownner).targetZoneToPlayer = -1;
    }

    void FixedUpdate(float dt)
    {
        ownner.CheckAvoidance(dt);
        CharacterState::FixedUpdate(dt);
    }

    float GetThreatScore()
    {
        return 0.333f;
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        AddDebugMark(debug, targetPosition, Color(1, 0, 0), 1.0);
    }
};

class ThugWalkState : SingleMotionState
{
    ThugWalkState(Character@ c)
    {
        super(c);
        SetName("WalkState");
        SetMotion(MOVEMENT_GROUP_THUG + "Walk_Forward_Combat");
    }
};

class ThugTurnState : MultiAnimationState
{
    Vector3 targetPoint;
    float turnSpeed;
    float endTime;

    ThugTurnState(Character@ c)
    {
        super(c);
        SetName("TurnState");
        AddMotion(MOVEMENT_GROUP_THUG + "135_Turn_Right");
        AddMotion(MOVEMENT_GROUP_THUG + "135_Turn_Left");
        AddMotion(MOVEMENT_GROUP_THUG + "Walk_Forward_Combat");
        flags = FLAGS_ATTACK | FLAGS_COLLISION_AVOIDENCE | FLAGS_HIT_RAGDOLL;
    }

    void Update(float dt)
    {
        float characterDifference = Abs(ownner.ComputeAngleDiff(targetPoint));
        if (timeInState + 0.01f >= endTime || characterDifference < 5)
        {
            ownner.CommonStateFinishedOnGroud();
            return;
        }
        ownner.GetNode().Yaw(turnSpeed * dt);
        MultiAnimationState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        targetPoint = ownner.GetNode().vars[TARGET].GetVector3();
        float diff = ownner.ComputeAngleDiff(targetPoint);
        int index = 0;
        if (diff < 0)
            index = 1;
        if (Abs(diff) <= 90)
            index = 2;
        ownner.GetNode().vars[ANIMATION_INDEX] = index;
        ownner.ClearAvoidance();
        MultiAnimationState::Enter(lastState);
        endTime = ownner.animCtrl.GetLength(animations[selectIndex]);
        if (index == 2)
            endTime = 0.4f;
        turnSpeed = diff / endTime;
        if (d_log)
            LogPrint(ownner.GetName() + " turn speed = " + turnSpeed + " diff=" + diff);
    }

    void FixedUpdate(float dt)
    {
        ownner.CheckAvoidance(dt);
        MultiAnimationState::FixedUpdate(dt);
    }
};


class ThugCounterState : CharacterCounterState
{
    ThugCounterState(Character@ c)
    {
        super(c);
        flags = FLAGS_NO_MOVE;
        alignTime = 0.3f;

        @frontArmMotions = thug_counter_arm_front_motions;
        @backArmMotions = thug_counter_arm_back_motions;
        @frontLegMotions = thug_counter_leg_front_motions;
        @backLegMotions = thug_counter_leg_back_motions;
        @doubleMotions = thug_counter_double_motions;
        @tripleMotions = thug_counter_triple_motions;
    }

    void OnAnimationTrigger(AnimationState@ animState, const VariantMap&in eventData)
    {
        StringHash name = eventData[NAME].GetStringHash();
        if (name == READY_TO_FIGHT)
        {
            ownner.AddFlag(FLAGS_ATTACK);
            return;
        }
        CharacterCounterState::OnAnimationTrigger(animState, eventData);
    }

    void Exit(State@ nextState)
    {
        ownner.RemoveFlag(FLAGS_ATTACK);
        CharacterCounterState::Exit(nextState);
    }
};


class ThugAttackState : CharacterState
{
    AttackMotion@               currentAttack;
    Array<AttackMotion@>        attacks;
    float                       turnSpeed = 1.25f;
    bool                        doAttackCheck = false;
    Node@                       attackCheckNode;

    ThugAttackState(Character@ c)
    {
        super(c);
        SetName("AttackState");
        AddAttackMotion("Attack_Punch", 23, ATTACK_PUNCH, "Bip01_R_Hand");
        AddAttackMotion("Attack_Punch_01", 23, ATTACK_PUNCH, "Bip01_R_Hand");
        AddAttackMotion("Attack_Punch_02", 23, ATTACK_PUNCH, "Bip01_R_Hand");
        AddAttackMotion("Attack_Kick", 24, ATTACK_KICK, "Bip01_L_Foot");
        AddAttackMotion("Attack_Kick_01", 24, ATTACK_KICK, "Bip01_L_Foot");
        AddAttackMotion("Attack_Kick_02", 24, ATTACK_KICK, "Bip01_L_Foot");
        flags = FLAGS_NO_MOVE | FLAGS_HIT_RAGDOLL;

        if (PUNCH_DIST != 0.0f)
        {
            PUNCH_DIST = attacks[0].motion.endDistance;
            KICK_DIST = attacks[3].motion.endDistance;
            LogPrint("Thug kick-dist=" + KICK_DIST + " punch-dist=" + PUNCH_DIST);
        }
    }

    void AddAttackMotion(const String&in name, int impactFrame, int type, const String&in bName)
    {
        attacks.Push(AttackMotion(MOVEMENT_GROUP_THUG + name, impactFrame, type, bName));
    }

    void Update(float dt)
    {
        if (firstUpdate)
        {
            if (cast<Thug>(ownner).KeepDistanceWithEnemy())
                return;
        }

        Motion@ motion = currentAttack.motion;
        ownner.CheckTargetDistance(ownner.target, COLLISION_SAFE_DIST);

        float characterDifference = ownner.ComputeAngleDiff();
        ownner.motion_deltaRotation += characterDifference * turnSpeed * dt;


        if (doAttackCheck)
            AttackCollisionCheck();

        if (motion.Move(ownner, dt) == 1)
        {
            ownner.CommonStateFinishedOnGroud();
            return;
        }

        if (!ownner.target.HasFlag(FLAGS_ATTACK))
        {
            ownner.CommonStateFinishedOnGroud();
            return;
        }

        CharacterState::Update(dt);
    }

    void FixedUpdate(float dt)
    {
        ownner.CheckRagdollHit();
        CharacterState::FixedUpdate(dt);
    }

    void Enter(State@ lastState)
    {
        float targetDistance = ownner.GetTargetDistance() - COLLISION_SAFE_DIST;
        float punchDist = attacks[0].motion.endDistance;
        LogPrint(ownner.GetName() + " targetDistance=" + targetDistance + " punchDist=" + punchDist);
        int index = RandomInt(3);
        if (targetDistance > punchDist + 1.0f)
            index += 3; // a kick attack
        @currentAttack = attacks[index];
        ownner.GetNode().vars[ATTACK_TYPE] = currentAttack.type;
        Motion@ motion = currentAttack.motion;
        motion.Start(ownner);
        ownner.AddFlag(FLAGS_ATTACK);
        doAttackCheck = false;
        turnSpeed = (currentAttack.type == ATTACK_PUNCH) ? 1.25f : 0.25f;
        CharacterState::Enter(lastState);
        LogPrint(ownner.GetName() + " Pick attack motion = " + motion.animationName);
    }

    void Exit(State@ nextState)
    {
        @currentAttack = null;
        ownner.RemoveFlag(FLAGS_ATTACK | FLAGS_COUNTER);
        ownner.SetTimeScale(1.0f);
        attackCheckNode = null;
        ShowAttackIndicator(false);
        CharacterState::Exit(nextState);
    }

    void ShowAttackIndicator(bool bshow)
    {
        HeadIndicator@ indicator = cast<HeadIndicator>(ownner.GetNode().GetScriptObject("HeadIndicator"));
        if (indicator !is null)
            indicator.ChangeState(bshow ? STATE_INDICATOR_ATTACK : STATE_INDICATOR_HIDE);
    }

    void OnAnimationTrigger(AnimationState@ animState, const VariantMap&in eventData)
    {
        StringHash name = eventData[NAME].GetStringHash();
        if (name == TIME_SCALE)
        {
            float scale = eventData[VALUE].GetFloat();
            ownner.SetTimeScale(scale);
            return;
        }
        else if (name == COUNTER_CHECK)
        {
            int value = eventData[VALUE].GetInt();
            ShowAttackIndicator(value == 1);
            if (value == 1)
                ownner.AddFlag(FLAGS_COUNTER);
            else
                ownner.RemoveFlag(FLAGS_COUNTER);
            return;
        }
        else if (name == ATTACK_CHECK)
        {
            int value = eventData[VALUE].GetInt();
            bool bCheck = value == 1;
            if (doAttackCheck == bCheck)
                return;

            doAttackCheck = bCheck;
            if (value == 1)
            {
                attackCheckNode = ownner.GetNode().GetChild(eventData[BONE].GetString(), true);
                LogPrint(ownner.GetName() + " AttackCheck bone=" + attackCheckNode.name);
                AttackCollisionCheck();
            }

            return;
        }

        CharacterState::OnAnimationTrigger(animState, eventData);
        return;
    }

    void AttackCollisionCheck()
    {
        if (attackCheckNode is null) {
            doAttackCheck = false;
            return;
        }

        Character@ target = ownner.target;
        Vector3 position = attackCheckNode.worldPosition;
        Vector3 targetPosition = target.sceneNode.worldPosition;
        Vector3 diff = targetPosition - position;
        diff.y = 0;
        float distance = diff.length;
        if (distance < ownner.attackRadius + COLLISION_RADIUS * 0.8f)
        {
            Vector3 dir = position - targetPosition;
            dir.y = 0;
            dir.Normalize();
            bool b = target.OnDamage(ownner, position, dir, ownner.attackDamage);
            if (!b)
                return;

            if (currentAttack.type == ATTACK_PUNCH)
            {
                ownner.PlaySound("Sfx/impact_10.ogg");
            }
            else
            {
                ownner.PlaySound("Sfx/impact_13.ogg");
            }
            ownner.OnAttackSuccess(target);
        }
    }

    float GetThreatScore()
    {
        return 0.75f;
    }

};

class ThugHitState : MultiMotionState
{
    float recoverTimer = 3 * SEC_PER_FRAME;

    ThugHitState(Character@ c)
    {
        super(c);
        SetName("HitState");
        String preFix = "TG_HitReaction/";
        AddMotion(preFix + "HitReaction_Right");
        AddMotion(preFix + "HitReaction_Left");
        AddMotion(preFix + "HitReaction_Back_NoTurn");
        AddMotion(preFix + "HitReaction_Back");
    }

    void Update(float dt)
    {
        if (timeInState >= recoverTimer)
            ownner.AddFlag(FLAGS_ATTACK);
        MultiMotionState::Update(dt);
    }

    void Exit(State@ nextState)
    {
        ownner.RemoveFlag(FLAGS_ATTACK);
        MultiMotionState::Exit(nextState);
    }

    bool CanReEntered()
    {
        return timeInState >= recoverTimer;
    }
};

class ThugGetUpState : CharacterGetUpState
{
    ThugGetUpState(Character@ c)
    {
        super(c);
        String prefix = "TG_Getup/";
        AddMotion(prefix + "GetUp_Back");
        AddMotion(prefix + "GetUp_Front");
    }

    void OnAnimationTrigger(AnimationState@ animState, const VariantMap&in eventData)
    {
        StringHash name = eventData[NAME].GetStringHash();
        if (name == READY_TO_FIGHT)
        {
            ownner.AddFlag(FLAGS_ATTACK);
            return;
        }
        CharacterGetUpState::OnAnimationTrigger(animState, eventData);
    }

    void Enter(State@ lastState)
    {
        CharacterGetUpState::Enter(lastState);
        ownner.SetPhysics(true);
    }

    void Exit(State@ nextState)
    {
        ownner.RemoveFlag(FLAGS_ATTACK);
        CharacterGetUpState::Exit(nextState);
    }
};

class ThugDeadState : CharacterState
{
    float  duration = 5.0f;

    ThugDeadState(Character@ c)
    {
        super(c);
        SetName("DeadState");
        flags = FLAGS_DEAD | FLAGS_NO_MOVE;
    }

    void Enter(State@ lastState)
    {
        LogPrint(ownner.GetName() + " Entering ThugDeadState");
        ownner.SetPhysics(false);
        CharacterState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        LogPrint(ownner.GetName() + " Exit ThugDeadState");
        if (nextState !is null)
            LogPrint(ownner.GetName() + " Exit ThugDeadState nextState is " + nextState.name);
        CharacterState::Exit(nextState);
    }

    void Update(float dt)
    {
        duration -= dt;
        if (duration <= 0)
        {
            if (!ownner.IsVisible())
                ownner.duration = 0;
            else
                duration = 0;
        }
    }
};

class ThugBeatDownHitState : MultiMotionState
{
    ThugBeatDownHitState(Character@ c)
    {
        super(c);
        SetName("BeatDownHitState");
        String preFix = "TG_BM_Beatdown/";
        for (uint i=1; i<=6; ++i)
            AddMotion(preFix + "Beatdown_HitReaction_0" + i);

        flags = FLAGS_STUN | FLAGS_ATTACK;
    }

    bool CanReEntered()
    {
        return true;
    }

    float GetThreatScore()
    {
        return 0.9f;
    }

    void OnMotionFinished()
    {
        // LogPrint(ownner.GetName() + " state:" + name + " finshed motion:" + motions[selectIndex].animationName);
        ownner.ChangeState("StunState");
    }
};

class ThugBeatDownEndState : MultiMotionState
{
    ThugBeatDownEndState(Character@ c)
    {
        super(c);
        SetName("BeatDownEndState");
        String preFix = "TG_BM_Beatdown/";
        for (uint i=1; i<=4; ++i)
            AddMotion(preFix + "Beatdown_Strike_End_0" + i);
        flags = FLAGS_ATTACK;
    }

    void Enter(State@ lastState)
    {
        ownner.SetHealth(0);
        MultiMotionState::Enter(lastState);
    }
};


class ThugStunState : SingleAnimationState
{
    ThugStunState(Character@ ownner)
    {
        super(ownner);
        SetName("StunState");
        flags = FLAGS_STUN | FLAGS_ATTACK;
        SetMotion("TG_HitReaction/CapeHitReaction_Idle");
        looped = true;
        stateTime = 5.0f;
    }
};

class ThugTauntingState : MultiMotionState
{
    ThugTauntingState(Character@ ownner)
    {
        super(ownner);
        SetName("TauntingState");
        flags = FLAGS_ATTACK | FLAGS_COLLISION_AVOIDENCE;

        for (uint i=1; i<=5; ++i)
            AddMotion(MOVEMENT_GROUP_THUG + "Taunting_0" + i);
    }

    int PickIndex()
    {
        return RandomInt(motions.length);
    }

    void Enter(State@ lastState)
    {
        MultiMotionState::Enter(lastState);
        ownner.ClearAvoidance();
    }

    void FixedUpdate(float dt)
    {
        ownner.CheckAvoidance(dt);
        MultiMotionState::FixedUpdate(dt);
    }
};

class ThugTauntIdleState : MultiAnimationState
{
    ThugTauntIdleState(Character@ ownner)
    {
        super(ownner);
        SetName("TauntIdleState");
        flags = FLAGS_ATTACK | FLAGS_COLLISION_AVOIDENCE;

        for (uint i=1; i<=6; ++i)
            AddMotion(MOVEMENT_GROUP_THUG + "Taunt_Idle_0" + i);
        for (uint i=1; i<=3; ++i)
            AddMotion(MOVEMENT_GROUP_THUG + "Stand_Idle_Combat_Overlays_0" + i);
    }

    int PickIndex()
    {
        return RandomInt(animations.length);
    }

    void Enter(State@ lastState)
    {
        MultiAnimationState::Enter(lastState);
        ownner.ClearAvoidance();
    }

    void FixedUpdate(float dt)
    {
        ownner.CheckAvoidance(dt);
        MultiAnimationState::FixedUpdate(dt);
    }
};

class Thug : Enemy
{
    float           checkAvoidanceTimer = 0.0f;
    float           checkAvoidanceTime = 0.1f;

    void ObjectStart()
    {
        Enemy::ObjectStart();
        stateMachine.AddState(ThugStandState(this));
        stateMachine.AddState(ThugStepMoveState(this));
        stateMachine.AddState(ThugTurnState(this));
        stateMachine.AddState(ThugRunToAttackState(this));
        stateMachine.AddState(ThugRunToTargetState(this));
        stateMachine.AddState(ThugWalkState(this));
        stateMachine.AddState(CharacterRagdollState(this));
        stateMachine.AddState(CharacterAlignState(this));
        stateMachine.AddState(AnimationTestState(this));

        stateMachine.AddState(ThugCounterState(this));
        stateMachine.AddState(ThugHitState(this));
        stateMachine.AddState(ThugAttackState(this));
        stateMachine.AddState(ThugGetUpState(this));
        stateMachine.AddState(ThugDeadState(this));
        stateMachine.AddState(ThugBeatDownHitState(this));
        stateMachine.AddState(ThugBeatDownEndState(this));
        stateMachine.AddState(ThugStunState(this));
        stateMachine.AddState(ThugTauntingState(this));
        stateMachine.AddState(ThugTauntIdleState(this));

        ChangeState("StandState");

        attackDamage = one_shot_kill ? 9999 : 20;

        walkAlignAnimation = GetAnimationName(MOVEMENT_GROUP_THUG + "Walk_Forward_Combat");

        UpdateZone();
        LogPrint(GetName() + " start, zoneToPlayer = " + zoneToPlayer);
    }

    void Stop()
    {
        @collisionBody = null;
        Enemy::Stop();
    }

    bool CanAttack()
    {
        EnemyManager@ em = GetEnemyMgr();
        if (em is null)
            return false;
        int num = em.GetNumOfEnemyAttackValid();
        if (num >= MAX_NUM_OF_ATTACK)
            return false;
        if (!target.CanBeAttacked())
            return false;
        return true;
    }

    bool ActionCheck(uint actionFlags = 0xFF)
    {
        if (actionFlags & FLAGS_ATTACK != 0)
        {
            return Attack();
        }
        return false;
    }

    bool Attack()
    {
        if (!CanAttack())
            return false;
        if (KeepDistanceWithEnemy())
            return false;

        float attackRange = Random(0.0, MAX_ATTACK_RANGE);
        if ((GetTargetDistance() <= (attackRange + COLLISION_SAFE_DIST)) && Abs(ComputeAngleDiff()) < MIN_TURN_ANGLE)
        {
            ChangeState("AttackState");
            return true;
        }
        return false;
    }

    bool Redirect()
    {
        ChangeState("RedirectState");
        return true;
    }

    void CommonStateFinishedOnGroud()
    {
        if (ActionCheck())
            return;
        ChangeState("StandState");
    }

    bool OnDamage(GameObject@ attacker, const Vector3&in position, const Vector3&in direction, int damage, bool weak = false)
    {
        if (!CanBeAttacked())
        {
            LogPrint("OnDamage failed because I can no be attacked " + GetName());
            return false;
        }

        LogPrint(GetName() + " OnDamage: pos=" + position.ToString() + " dir=" + direction.ToString() + " damage=" + damage + " weak=" + weak);
        health -= damage;
        health = Max(0, health);
        SetHealth(health);

        int r = RandomInt(4);
        // if (r > 1)
        {
            Node@ floorNode = GetScene().GetChild("floor", true);
            if (floorNode !is null)
            {
                DecalSet@ decal = floorNode.GetComponent("DecalSet");
                if (decal is null)
                {
                    decal = floorNode.CreateComponent("DecalSet");
                    decal.material = cache.GetResource("Material", "Materials/Blood_Splat.xml");
                    decal.castShadows = false;
                    decal.viewMask = 0x7fffffff;
                    //decal.material = cache.GetResource("Material", "Materials/UrhoDecalAlpha.xml");
                }
                // LogPrint("Creating decal");
                float size = Random(1.5f, 3.5f);
                float timeToLive = 5.0f;
                Vector3 pos = sceneNode.worldPosition + Vector3(0, 0, 0);
                decal.AddDecal(floorNode.GetComponent("StaticModel"), pos, Quaternion(90, Random(360), 0), size, 1.0f, 1.0f, Vector2(0.0f, 0.0f), Vector2(1.0f, 1.0f), timeToLive);
            }
        }

        Node@ attackNode = attacker.GetNode();

        Vector3 v = direction * -1;
        v.y = 1.0f;
        v.Normalize();
        v *= GetRagdollForce();

        if (health <= 0)
        {
            v *= 1.5f;
            MakeMeRagdoll(v, position);
            OnDead();
        }
        else
        {
            float diff = ComputeAngleDiff(attackNode);
            if (weak) {
                int index = 0;
                if (diff < 0)
                    index = 1;
                if (Abs(diff) > 135)
                    index = 2 + RandomInt(2);
                sceneNode.vars[ANIMATION_INDEX] = index;
                ChangeState("HitState");
            }
            else {
                MakeMeRagdoll(v, position);
            }
        }
        return true;
    }

    void RequestDoNotMove()
    {
        Character::RequestDoNotMove();
        StringHash nameHash = stateMachine.currentState.nameHash;
        if (HasFlag(FLAGS_MOVING))
        {
            ChangeState("StandState");
            return;
        }

        if (nameHash == HIT_STATE)
        {
            // I dont know how to do ...
            // special case
            motion_translateEnabled = false;
        }
    }

    int GetSperateDirection()
    {
        int ret = -1;
        Array<RigidBody@>@ neighbors = collisionBody.collidingBodies;
        if (neighbors.empty)
            return ret;

        Vector3 myPos = sceneNode.worldPosition;
        float myAngle = GetCharacterAngle();

        for (uint i=0; i<dirCache.length; ++i)
            dirCache[i] = 0;

        bool need_to_sep = false;
        for (uint i=0; i<neighbors.length; ++i)
        {
            Node@ n_node = neighbors[i].node.parent;
            if (n_node is null)
                continue;

            // LogPrint(_node.name + " neighbors[" + i + "] = " + n_node.name);
            Character@ object = cast<Character>(n_node.scriptObject);
            if (object is null)
                continue;

            if (object.HasFlag(FLAGS_KEEP_DIST))
                continue;

            int dir_map = GetDirectionZone(myPos, object.GetNode().worldPosition, 4, myAngle);
            dirCache[dir_map] = dirCache[dir_map] + 1;
            need_to_sep = true;
        }

        if (!need_to_sep)
            return ret;

        gIntCache.Clear();
        Vector3 targetPos = target.GetNode().worldPosition;
        MultiMotionState@ state = cast<MultiMotionState>(FindState("StepMoveState"));

        for (uint i=0; i<dirCache.length; ++i)
        {
            if (dirCache[i] == 0)
            {
                int candidate1 = int(i); // close step move
                int candidate2 = candidate1 + 4; // far step move
                Motion@ motion1 = state.motions[candidate1];
                Motion@ motion2 = state.motions[candidate2];
                Vector3 v1 = motion1.GetKeyPosition(this, motion1.endTime);
                Vector3 v2 = motion2.GetKeyPosition(this, motion2.endTime);
                Vector3 diff = v1 - targetPos;
                diff.y = 0;
                if (diff.length >= KEEP_DIST_WITH_PLAYER)
                    gIntCache.Push(candidate1);
                else
                {
                    //if (drawDebug > 0)
                    //    gDebugMgr.AddSphere(v1, 0.25f, GREEN, 3.0f);
                }

                diff = v2 - targetPos;
                diff.y = 0;
                if (diff.length >= KEEP_DIST_WITH_PLAYER)
                    gIntCache.Push(candidate2);
                {
                    //if (drawDebug > 0)
                    //    gDebugMgr.AddSphere(v2, 0.25f, GREEN, 3.0f);
                }
            }
        }

        if (d_log)
        {
            LogPrint(GetName() + " GetSperateDirection, dir_0=" + dirCache[0] + " dir_1=" + dirCache[1] + " dir_2=" + dirCache[2] + " dir_3=" + dirCache[3]);
        }

        ret = gIntCache[RandomInt(gIntCache.length)];
        return ret;
    }

    void CheckAvoidance(float dt)
    {
        checkAvoidanceTimer += dt;
        if (checkAvoidanceTimer >= checkAvoidanceTime)
        {
            checkAvoidanceTimer -= checkAvoidanceTime;
            CheckCollision();
        }
    }

    void ClearAvoidance()
    {
        checkAvoidanceTimer = 0.0;
        checkAvoidanceTime = Random(0.05f, 0.1f);
    }

    bool KeepDistanceWithEnemy()
    {
        if (HasFlag(FLAGS_NO_MOVE) || HasFlag(FLAGS_DEAD))
            return false;
        int dir = GetSperateDirection();
        if (dir < 0)
            return false;
        if (d_log)
            LogPrint(GetName() + " KeepDistanceWithEnemy dir=" + dir);
        sceneNode.vars[ANIMATION_INDEX] = dir;
        ChangeState("StepMoveState");
        return true;
    }

    bool CheckRagdollHit()
    {
        Array<RigidBody@>@ neighbors = collisionBody.collidingBodies;
        if (neighbors.empty)
            return false;

        bool bHit = false;
        for (uint i=0; i<neighbors.length; ++i)
        {
            RigidBody@ rb = neighbors[i];
            if (rb.collisionLayer != COLLISION_LAYER_RAGDOLL)
                continue;
            if (rb.node.name != PELVIS)
                continue;

            float vl = rb.linearVelocity.length;
            Vector3 vel = rb.linearVelocity;
            if (vl > 5.0f)
            {
                bHit = true;
                LogPrint(GetName() + " hit ragdoll bone " + rb.node.name + " vel=" + vel.ToString() + " vl=" + vl);
                // sceneNode.scene.timeScale = 0.0f;
                MakeMeRagdoll(vel * 1.5f, rb.node.worldPosition);
                return bHit;
            }
        }

        return false;
    }

    void CheckCollision()
    {
        if (instant_collision)
            return;
        if (CheckRagdollHit())
            return;
        if (KeepDistanceWithPlayer())
            return;
        KeepDistanceWithEnemy();
    }

    bool Distract()
    {
        ChangeState("DistractState");
        return true;
    }

    void UpdateOnFlagsChanged()
    {
        /*
            Materials/Thug_Leg.xml,
            Materials/Thug_Torso.xml,
            Materials/Thug_Hat.xml,
            Materials/Thug_Head.xml,
            Materials/Thug_Body.xml
        */
        if (HasFlag(FLAGS_ATTACK))
        {
            animModel.materials[0]= cache.GetResource("Material", "Materials/Thug_Leg.xml");
            animModel.materials[1]= cache.GetResource("Material", "Materials/Thug_Torso.xml");
            animModel.materials[2]= cache.GetResource("Material", "Materials/Thug_Hat.xml");
        }
        else
        {
            animModel.materials[0]= cache.GetResource("Material", "Materials/Thug_Leg_1.xml");
            animModel.materials[1]= cache.GetResource("Material", "Materials/Thug_Torso_1.xml");
            animModel.materials[2]= cache.GetResource("Material", "Materials/Thug_Hat_1.xml");
        }
    }

    bool KeepDistanceWithPlayer(float max_dist = KEEP_DIST_WITH_PLAYER)
    {
        if (HasFlag(FLAGS_NO_MOVE) || HasFlag(FLAGS_DEAD))
            return false;
        float dist = GetTargetDistance();
        if (dist >= max_dist)
            return false;
        int index = RadialSelectAnimation(4);
        index += 2;
        index = index % 4;
        if (RandomInt(2) == 1)
            index += 4;

        // LogPrint(GetName() + " KeepDistanceWithPlayer index=" + index + " dist=" + dist);
        sceneNode.vars[ANIMATION_INDEX] = index;
        ChangeState("StepMoveState");
        return true;
    }

    void KeepDistanceWithCharacter(Character@ c)
    {
        int index = RadialSelectAnimation(c.GetNode().worldPosition, 4);
        //if (RandomInt(2) == 1)
        //    index += 3;
        //else
        //   index += 1;
        index += 2;
        index = index % 4;
        if (RandomInt(2) == 1)
            index += 4;

        sceneNode.vars[ANIMATION_INDEX] = index;
        ChangeState("StepMoveState");
    }

    void HitRagdoll(RigidBody@ rb)
    {
        bool bRagdoll = false;
        float vl = rb.linearVelocity.length;
        Vector3 vel = rb.linearVelocity;

        if (rb.collisionLayer == COLLISION_LAYER_RAGDOLL)
        {
            if (rb.node.name == PELVIS && vl > 5.0f)
                bRagdoll = true;
        }
        else if (rb.collisionLayer == COLLISION_LAYER_PROP)
        {
            if (vl > 10.0f)
                bRagdoll = true;
        }

        if (bRagdoll)
        {
            LogPrint(GetName() + " hit ragdoll bone " + rb.node.name + " vel=" + vel.ToString() + " vl=" + vl);
            MakeMeRagdoll(vel * 1.5f, rb.node.worldPosition);
        }
    }
};

Vector3 GetRagdollForce()
{
    float x = Random(HIT_RAGDOLL_FORCE.x*0.75f, HIT_RAGDOLL_FORCE.x*1.25f);
    float y = Random(HIT_RAGDOLL_FORCE.y*0.75f, HIT_RAGDOLL_FORCE.y*1.25f);
    return Vector3(x, y, x);
}

void CreateThugCombatMotions()
{
    String preFix = "TG_Combat/";

    Global_CreateMotion(preFix + "Attack_Kick");
    Global_CreateMotion(preFix + "Attack_Kick_01");
    Global_CreateMotion(preFix + "Attack_Kick_02");
    Global_CreateMotion(preFix + "Attack_Punch");
    Global_CreateMotion(preFix + "Attack_Punch_01");
    Global_CreateMotion(preFix + "Attack_Punch_02");

    preFix = "TG_HitReaction/";
    Global_CreateMotion(preFix + "HitReaction_Left");
    Global_CreateMotion(preFix + "HitReaction_Right");
    Global_CreateMotion(preFix + "HitReaction_Back_NoTurn");
    Global_CreateMotion(preFix + "HitReaction_Back");
    Global_AddAnimation(preFix + "CapeHitReaction_Idle");

    preFix = "TG_Getup/";
    Global_CreateMotion(preFix + "GetUp_Front", kMotion_XZ);
    Global_CreateMotion(preFix + "GetUp_Back", kMotion_XZ);

    preFix = "TG_BM_Counter/";
    Array<Motion@> counter_motions;
    Global_CreateMotion_InFolder(preFix, "Double_Counter_", counter_motions);
    const String arm_front_prefx = preFix + "Counter_Arm_Front";
    const String leg_front_prefx = preFix + "Counter_Leg_Front";
    const String arm_back_prefx = preFix + "Counter_Arm_Back";
    const String leg_back_prefx = preFix + "Counter_Leg_Back";
    for (uint i=0; i<counter_motions.length; ++i)
    {
        Motion@ m = counter_motions[i];
        if (m.name.StartsWith(arm_front_prefx))
            thug_counter_arm_front_motions.Push(m);
        else if (m.name.StartsWith(leg_front_prefx))
            thug_counter_leg_front_motions.Push(m);
        else if (m.name.StartsWith(arm_back_prefx))
            thug_counter_arm_back_motions.Push(m);
        else if (m.name.StartsWith(leg_back_prefx))
            thug_counter_leg_back_motions.Push(m);
    }
    thug_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsA_01"));
    thug_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsA_02"));
    thug_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsB_01", kMotion_XZR, kMotion_XZR, -1, false, -90));
    thug_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsB_02", kMotion_XZR, kMotion_XZR, -1, false, 90));
    thug_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsD_01"));
    thug_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsD_02"));
    thug_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsE_01"));
    thug_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsE_02"));
    thug_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsF_01"));
    thug_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsF_02"));
    thug_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsG_01"));
    thug_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsG_02", kMotion_XZR, kMotion_XZR, -1, false, 90));
    thug_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsH_01"));
    thug_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsH_02", kMotion_XZR, kMotion_XZR, -1, false, 90));
    thug_counter_triple_motions.Push(Global_CreateMotion(preFix + "Double_Counter_3ThugsB_01"));
    thug_counter_triple_motions.Push(Global_CreateMotion(preFix + "Double_Counter_3ThugsB_02", kMotion_XZR, kMotion_XZR, -1, false, 90));
    thug_counter_triple_motions.Push(Global_CreateMotion(preFix + "Double_Counter_3ThugsB_03"));
    thug_counter_triple_motions.Push(Global_CreateMotion(preFix + "Double_Counter_3ThugsC_01"));
    thug_counter_triple_motions.Push(Global_CreateMotion(preFix + "Double_Counter_3ThugsC_02", kMotion_XZR, kMotion_XZR, -1, false, 90));
    thug_counter_triple_motions.Push(Global_CreateMotion(preFix + "Double_Counter_3ThugsC_03"));

    preFix = "TG_BM_Beatdown/";
    for (uint i=1; i<=6; ++i)
        Global_CreateMotion(preFix + "Beatdown_HitReaction_0" + i);

    for (uint i=1; i<=4; ++i)
        Global_CreateMotion(preFix + "Beatdown_Strike_End_0" + i);

    preFix = "TG_Combat/";
    for (uint i=1; i<=4; ++i)
        Global_AddAnimation(preFix + "Stand_Idle_Additive_0" + i);

    for (uint i=1; i<=5; ++i)
        Global_CreateMotion(preFix + "Taunting_0" + i);

    for (uint i=1; i<=6; ++i)
        Global_AddAnimation(preFix + "Taunt_Idle_0" + i);
    for (uint i=1; i<=3; ++i)
        Global_AddAnimation(preFix + "Stand_Idle_Combat_Overlays_0" + i);
}

void CreateThugMotions()
{
    AssignMotionRig("Models/thug.mdl");

    String preFix = "TG_Combat/";
    Global_CreateMotion(preFix + "Step_Forward");
    Global_CreateMotion(preFix + "Step_Right");
    Global_CreateMotion(preFix + "Step_Back");
    Global_CreateMotion(preFix + "Step_Left");
    Global_CreateMotion(preFix + "Step_Forward_Long");
    Global_CreateMotion(preFix + "Step_Right_Long");
    Global_CreateMotion(preFix + "Step_Back_Long");
    Global_CreateMotion(preFix + "Step_Left_Long");

    Global_CreateMotion(preFix + "135_Turn_Left", kMotion_Turn, kMotion_R, 32);
    Global_CreateMotion(preFix + "135_Turn_Right", kMotion_Turn, kMotion_R, 32);

    Global_CreateMotion(preFix + "Run_Forward_Combat", kMotion_XZR, kMotion_Z, -1, true);
    Global_CreateMotion(preFix + "Walk_Forward_Combat", kMotion_XZR, kMotion_Z, -1, true);

    CreateThugCombatMotions();
}

void AddThugCombatAnimationTriggers()
{
    String preFix = "TG_BM_Counter/";
    AddRagdollTrigger(preFix + "Counter_Arm_Back_01", 35, 40);
    AddRagdollTrigger(preFix + "Counter_Arm_Back_02", -1, 46);
    AddRagdollTrigger(preFix + "Counter_Arm_Back_03", 32, 34);
    AddRagdollTrigger(preFix + "Counter_Arm_Back_05", 30, 45);
    AddRagdollTrigger(preFix + "Counter_Arm_Back_06", 62, 70);
    AddAnimationTrigger(preFix + "Counter_Arm_Back_Weak_01", 54, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "Counter_Arm_Back_Weak_02", 54, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "Counter_Arm_Back_Weak_03", 90, READY_TO_FIGHT);

    AddRagdollTrigger(preFix + "Counter_Arm_Front_01", -1, 34);
    AddRagdollTrigger(preFix + "Counter_Arm_Front_02", 38, 45);
    AddRagdollTrigger(preFix + "Counter_Arm_Front_03", 34, 40);
    AddRagdollTrigger(preFix + "Counter_Arm_Front_04", 33, 39);
    AddRagdollTrigger(preFix + "Counter_Arm_Front_05", -1, 43);
    AddRagdollTrigger(preFix + "Counter_Arm_Front_06", 40, 42);
    AddRagdollTrigger(preFix + "Counter_Arm_Front_07", 20, 25);
    AddRagdollTrigger(preFix + "Counter_Arm_Front_08", 29, 32);
    AddRagdollTrigger(preFix + "Counter_Arm_Front_09", 35, 40);
    AddRagdollTrigger(preFix + "Counter_Arm_Front_10", 20, 32);
    AddRagdollTrigger(preFix + "Counter_Arm_Front_13", 40, 60);
    AddRagdollTrigger(preFix + "Counter_Arm_Front_14", 50, 70);
    AddAnimationTrigger(preFix + "Counter_Arm_Front_Weak_02", 45, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "Counter_Arm_Front_Weak_03", 100, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "Counter_Arm_Front_Weak_04", 70, READY_TO_FIGHT);

    AddRagdollTrigger(preFix + "Counter_Leg_Back_01", 45, 54);
    AddRagdollTrigger(preFix + "Counter_Leg_Back_02", 50, 60);
    AddRagdollTrigger(preFix + "Counter_Leg_Back_03", -1, 70);
    AddRagdollTrigger(preFix + "Counter_Leg_Back_04", 50, 60);
    AddAnimationTrigger(preFix + "Counter_Leg_Back_Weak_01", 52, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "Counter_Leg_Back_Weak_03", 80, READY_TO_FIGHT);

    AddRagdollTrigger(preFix + "Counter_Leg_Front_01", 25, 39);
    AddRagdollTrigger(preFix + "Counter_Leg_Front_02", 25, 54);
    AddRagdollTrigger(preFix + "Counter_Leg_Front_03", 15, 23);
    AddRagdollTrigger(preFix + "Counter_Leg_Front_04", 32, 35);
    AddRagdollTrigger(preFix + "Counter_Leg_Front_05", 55, 65);
    AddRagdollTrigger(preFix + "Counter_Leg_Front_06", -1, 32);
    AddRagdollTrigger(preFix + "Counter_Leg_Front_07", 40, 60);
    AddRagdollTrigger(preFix + "Counter_Leg_Front_08", 20, 40);
    AddAnimationTrigger(preFix + "Counter_Leg_Front_Weak", 52, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "Counter_Leg_Front_Weak_01", 65, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "Counter_Leg_Front_Weak_02", 60, READY_TO_FIGHT);

    AddRagdollTrigger(preFix + "Double_Counter_2ThugsA_01", -1, 99);
    AddRagdollTrigger(preFix + "Double_Counter_2ThugsA_02", -1, 99);

    AddRagdollTrigger(preFix + "Double_Counter_2ThugsB_01", -1, 62);
    AddRagdollTrigger(preFix + "Double_Counter_2ThugsB_02", -1, 50);

    AddRagdollTrigger(preFix + "Double_Counter_2ThugsD_01", 30, 44);
    AddRagdollTrigger(preFix + "Double_Counter_2ThugsD_02", 30, 44);

    AddRagdollTrigger(preFix + "Double_Counter_2ThugsE_01", 38, 46);
    AddRagdollTrigger(preFix + "Double_Counter_2ThugsE_02", 38, 42);

    AddRagdollTrigger(preFix + "Double_Counter_2ThugsF_01", 25, 30);
    AddRagdollTrigger(preFix + "Double_Counter_2ThugsF_02", 18, 25);

    AddRagdollTrigger(preFix + "Double_Counter_2ThugsG_01", 22, 28);
    AddRagdollTrigger(preFix + "Double_Counter_2ThugsG_02", 22, 28);

    AddRagdollTrigger(preFix + "Double_Counter_2ThugsH_01", -1, 62);
    AddRagdollTrigger(preFix + "Double_Counter_2ThugsH_02", -1, 62);

    AddRagdollTrigger(preFix + "Double_Counter_3ThugsB_01", 25, 33);
    AddRagdollTrigger(preFix + "Double_Counter_3ThugsB_02", 25, 33);
    AddRagdollTrigger(preFix + "Double_Counter_3ThugsB_03", 25, 33);

    AddRagdollTrigger(preFix + "Double_Counter_3ThugsC_01", 35, 41);
    AddRagdollTrigger(preFix + "Double_Counter_3ThugsC_02", 35, 45);
    AddRagdollTrigger(preFix + "Double_Counter_3ThugsC_03", 35, 45);

    preFix = "TG_Combat/";
    int frame_fixup = 6;
    // name counter-start counter-end attack-start attack-end attack-bone
    AddComplexAttackTrigger(preFix + "Attack_Kick", 15 - frame_fixup, 24, 24, 27, "Bip01_L_Foot");
    AddComplexAttackTrigger(preFix + "Attack_Kick_01", 12 - frame_fixup, 24, 24, 27, "Bip01_L_Foot");
    AddComplexAttackTrigger(preFix + "Attack_Kick_02", 19 - frame_fixup, 24, 24, 27, "Bip01_L_Foot");
    AddComplexAttackTrigger(preFix + "Attack_Punch", 15 - frame_fixup, 22, 22, 24, "Bip01_R_Hand");
    AddComplexAttackTrigger(preFix + "Attack_Punch_01", 15 - frame_fixup, 23, 23, 24, "Bip01_R_Hand");
    AddComplexAttackTrigger(preFix + "Attack_Punch_02", 15 - frame_fixup, 23, 23, 24, "Bip01_R_Hand");

    preFix = "TG_Getup/";
    AddAnimationTrigger(preFix + "GetUp_Front", 44, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "GetUp_Back", 68, READY_TO_FIGHT);
}

void AddThugAnimationTriggers()
{
    String preFix = "TG_Combat/";

    AddStringAnimationTrigger(preFix + "Run_Forward_Combat", 2, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger(preFix + "Run_Forward_Combat", 13, FOOT_STEP, R_FOOT);

    AddStringAnimationTrigger(preFix + "Step_Back", 15, FOOT_STEP, R_FOOT);
    AddStringAnimationTrigger(preFix + "Step_Back_Long", 9, FOOT_STEP, R_FOOT);
    AddStringAnimationTrigger(preFix + "Step_Back_Long", 19, FOOT_STEP, L_FOOT);

    AddStringAnimationTrigger(preFix + "Step_Forward", 12, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger(preFix + "Step_Forward_Long", 10, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger(preFix + "Step_Forward_Long", 22, FOOT_STEP, R_FOOT);

    AddStringAnimationTrigger(preFix + "Step_Left", 11, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger(preFix + "Step_Left_Long", 8, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger(preFix + "Step_Left_Long", 22, FOOT_STEP, R_FOOT);

    AddStringAnimationTrigger(preFix + "Step_Right", 11, FOOT_STEP, R_FOOT);
    AddStringAnimationTrigger(preFix + "Step_Right_Long", 15, FOOT_STEP, R_FOOT);
    AddStringAnimationTrigger(preFix + "Step_Right_Long", 28, FOOT_STEP, L_FOOT);

    AddStringAnimationTrigger(preFix + "135_Turn_Left", 8, FOOT_STEP, R_FOOT);
    AddStringAnimationTrigger(preFix + "135_Turn_Left", 20, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger(preFix + "135_Turn_Left", 31, FOOT_STEP, R_FOOT);

    AddStringAnimationTrigger(preFix + "135_Turn_Right", 11, FOOT_STEP, R_FOOT);
    AddStringAnimationTrigger(preFix + "135_Turn_Right", 24, FOOT_STEP, L_FOOT);
    AddStringAnimationTrigger(preFix + "135_Turn_Right", 39, FOOT_STEP, R_FOOT);

    AddThugCombatAnimationTriggers();
}

