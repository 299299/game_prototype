// ==============================================
//
//    Thug Pawn and Controller Class
//
// ==============================================



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
        ownner.ClearAvoidance();
        ownner.SetVelocity(Vector3::ZERO);
        ownner.SetTimeScale(1.0f);
        int r = 3;
        int rand_i = RandomInt(r);
        ownner.GetNode().vars[ATTACK_TYPE] = (rand_i == (r-1)) ? ATTACK_KICK : ATTACK_PUNCH;
        if (d_log)
            LogPrint(ownner.GetName() + " Stand Random AttackType rand_i=" + rand_i + " thinkTime=" + thinkTime);
        MultiAnimationState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        MultiAnimationState::Exit(nextState);
        ownner.animModel.updateInvisible = false;
    }

    void Update(float dt)
    {
         if (DebugPauseAI())
            return;

       if (game_state != GAME_RUNNING)
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
            Print(ownner.GetName() + " no move change to turn state");
            ownner.ChangeState("TurnState");
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
        int num_of_run_to_attack_thugs = em.GetNumOfEnemyHasFlag(FLAGS_RUN_TO_ATTACK);
        bool target_can_be_attacked = ownner.target.CanBeAttacked();
        Node@ blocked_node = ownner.GetTargetSightBlockedNode(ownner.target.GetNode().worldPosition);
        bool can_see_target = (blocked_node == null) || (blocked_node is ownner.target.GetNode());

        LogPrint(ownner.GetName() + " num_near_thugs=" + num_near_thugs +
              " num_of_run_to_attack_thugs=" + num_of_run_to_attack_thugs +
              " target_can_be_attacked=" + target_can_be_attacked +
              " blocked by " + ((blocked_node != null) ? blocked_node.name : "null"));

        if (dist >= AI_FAR_DIST)
        {
            if (RandomInt(2) == 0)
            {
                float range = AI_FAR_DIST;
                if (num_near_thugs < MAX_NUM_OF_NEAR)
                    range = AI_NEAR_DIST;

                Vector3 targetPos = em.FindTargetPosition(cast<Enemy>(ownner), range + COLLISION_SAFE_DIST);
                LogPrint(ownner.GetName() + " far away, tryinng to approach targetPos=" + targetPos.ToString());
                ownner.GetNode().vars[TARGET] = targetPos;
                ownner.ChangeState("RunToTargetState");
                return;
            }
            else
            {
                if (num_of_run_to_attack_thugs < MAX_NUM_OF_RUN_ATTACK && target_can_be_attacked)
                {
                    ownner.ChangeState("RunToAttackState");
                    return;
                }
            }
        }
        else
        {
             if (num_of_run_to_attack_thugs < MAX_NUM_OF_RUN_ATTACK && target_can_be_attacked)
            {
                ownner.ChangeState("RunToAttackState");
                return;
            }
        }

        if (dist <= AI_NEAR_DIST)
        {
            _node.vars[ANIMATION_INDEX] = RandomInt(8);
            ownner.ChangeState("StepMoveState");
        }
        else
        {
            int rand_i = RandomInt(5);
            Print(ownner.GetName() + " rand_i=" + rand_i);
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
                if (can_see_target)
                    _node.vars[ANIMATION_INDEX] = RandomInt(8);
                else
                {
                    int r1 = RandomInt(2);
                    int r2 = RandomInt(2);
                    int index = (r1 == 0) ? 1 : 3;
                    if (r2 == 1)
                        index += 4;
                    index = index % 4;
                    _node.vars[ANIMATION_INDEX] = index;
                }
                ownner.ChangeState("StepMoveState");
            }
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

        /*for (uint i=0; i<moitons.length; ++i)
        {
            Print(motions[i].name + " endDistance=" + motions[i].endDistance);
        }*/
    }

    float GetThreatScore()
    {
        return 0.333f;
    }

    void Enter(State@ lastState)
    {
        int index = PickIndex();
        Motion@ m = motions[index];
        Vector3 futurePos = m.GetFuturePosition(ownner, m.endTime);

        if (!IsDestinationReachable(ownner.GetNode().worldPosition, futurePos))
        {
            int newIndex = index + 2;
            newIndex = newIndex % 8;
            ownner.GetNode().vars[ANIMATION_INDEX] = newIndex;
            LogPrint(ownner.GetName() + " step move out of world, change index=" + index + " to " + newIndex);
        }
        MultiMotionState::Enter(lastState);
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
        if (Abs(characterDifference) > MIN_TURN_ANGLE)
        {
            ownner.GetNode().vars[TARGET] = ownner.target.GetNode().worldPosition;
            ownner.ChangeState("TurnState");
            return;
        }

        if (ownner.ActionCheck())
            return;

        float dist = ownner.GetTargetDistance();
        if (dist < COLLISION_SAFE_DIST)
        {
            ownner.CommonStateFinishedOnGroud();
            return;
        }

        if (timeInState > AI_MAX_STATE_TIME)
        {
            LogPrint(ownner.GetName() + " there is something wrong with this guy in RunToAttackState, break.");
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
        if (distV.length < 0.5f)
        {
            ownner.CommonStateFinishedOnGroud();
            return;
        }

        if (timeInState > AI_MAX_STATE_TIME)
        {
            LogPrint(ownner.GetName() + " there is something wrong with this guy in RunToTargetState, break.");
            ownner.CommonStateFinishedOnGroud();
            return;
        }

        SingleMotionState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        SingleMotionState::Enter(lastState);
        targetPosition = ownner.GetNode().vars[TARGET].GetVector3();
        ownner.agent.targetPosition = targetPosition;
        ownner.aiSyncMode = 1;
        ownner.ClearAvoidance();
    }

    void Exit(State@ nextState)
    {
        SingleMotionState::Exit(nextState);
        ownner.aiSyncMode = 0;
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
        AddDebugMark(debug, targetPosition, RED, 0.25f);
        debug.AddLine(targetPosition, ownner.GetNode().worldPosition, YELLOW, false);
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

        BM_Game_MotionManager@ mgr = cast<BM_Game_MotionManager>(gMotionMgr);
        @frontArmMotions = mgr.thug_counter_arm_front_motions;
        @backArmMotions = mgr.thug_counter_arm_back_motions;
        @frontLegMotions = mgr.thug_counter_leg_front_motions;
        @backLegMotions = mgr.thug_counter_leg_back_motions;
        @doubleMotions = mgr.thug_counter_double_motions;
        @tripleMotions = mgr.thug_counter_triple_motions;
        @environmentMotions = mgr.thug_counter_environment_motions;
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
    Motion@                     currentAttack;
    Array<Motion@>@             attacks;
    float                       turnSpeed = 1.25f;
    bool                        doAttackCheck = false;
    bool                        rotating = false;
    Node@                       attackCheckNode;

    ThugAttackState(Character@ c)
    {
        super(c);
        SetName("AttackState");

        BM_Game_MotionManager@ mgr = cast<BM_Game_MotionManager>(gMotionMgr);
        @attacks = mgr.thug_attack_motions;

        flags = FLAGS_NO_MOVE | FLAGS_HIT_RAGDOLL;
    }

    ~ThugAttackState()
    {
        @attacks = null;
        @currentAttack = null;
    }

    void Update(float dt)
    {
        ownner.CheckTargetDistance(ownner.target);

        float characterDifference = ownner.ComputeAngleDiff();
        if (rotating)
            ownner.motion_deltaRotation += characterDifference * turnSpeed * dt;

        if (doAttackCheck)
            AttackCollisionCheck();

        if (currentAttack.Move(ownner, dt) == 1)
        {
            // Print(ownner.GetName() + " move finished ");
            ownner.ChangeState("StandState");
            return;
        }

        if (!ownner.target.CanBeAttacked())
        {
            // Print(ownner.GetName() + " target has no attack flag ");
            ownner.ChangeState("StandState");
            return;
        }

        CharacterState::Update(dt);
    }

    void FixedUpdate(float dt)
    {
        if (!instant_collision)
        {
            ownner.CheckRagdollHit();
        }
        CharacterState::FixedUpdate(dt);
    }

    void Enter(State@ lastState)
    {
        float dist = ownner.GetTargetDistance() - COLLISION_SAFE_DIST;
        int index = RandomInt(3);
        int attackType = ownner.GetNode().vars[ATTACK_TYPE].GetInt();
        if (attackType == ATTACK_KICK && dist > 0.5f)
        {
            index += 3; // a kick attack
        }
        @currentAttack = attacks[index];
        currentAttack.Start(ownner);
        ownner.AddFlag(FLAGS_ATTACK);
        doAttackCheck = false;
        turnSpeed = (currentAttack.type == ATTACK_PUNCH) ? 2.0f : 0.5f;
        rotating  = true;
        CharacterState::Enter(lastState);
        LogPrint(ownner.GetName() + " attackType=" + attackType + ", Pick attack motion = " + currentAttack.animationName + " dist=" + dist);
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
        if (name == COUNTER_CHECK)
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
                rotating = false;
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
    //float turnAlignTime = 0.2f;
    //float turnSpeed;

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
        //if (timeInState <= turnAlignTime)
        //    ownner.motion_deltaRotation += turnSpeed * dt;

        if (timeInState >= recoverTimer)
            ownner.AddFlag(FLAGS_ATTACK);
        MultiMotionState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        float diff = ownner.ComputeAngleDiff(ownner.target.GetNode());
        //if (diff < 0)
        //    diff += 360;

        int index = 0;
        if (Abs(diff) <= 90)
        {
            index = (diff > 0) ? 0 : 1;
        }
        else
        {
            index = 2 + RandomInt(2);
        }

        float targetAngle = ownner.GetTargetAngle();
        // Vector3 dir = ownner.GetNode().vars[DIRECTION].GetVector3();
        // float targetAngle = Atan2(dir.x, dir.z);
        if (index > 1)
            targetAngle = AngleDiff(targetAngle + 180);
        ownner.sceneNode.vars[ANIMATION_INDEX] = index;

        LogPrint(ownner.GetName() + " HitState angle_diff=" + diff + " Hit motion=" + motions[index].name);

        // turnSpeed = AngleDiff(targetDiff - diff) / turnAlignTime;
        ownner.GetNode().worldRotation = Quaternion(0, targetAngle, 0);

        if (debug_mode == 2)
        {
            DebugPause(true);
            DebugTimeScale(0.1f);
        }

        MultiMotionState::Enter(lastState);
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
        flags = FLAGS_ATTACK | FLAGS_HIT_RAGDOLL;
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

class ThugTauntingState : MultiMotionState
{
    ThugTauntingState(Character@ ownner)
    {
        super(ownner);
        SetName("TauntingState");
        flags = FLAGS_ATTACK | FLAGS_COLLISION_AVOIDENCE | FLAGS_TAUNT;

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
        flags = FLAGS_ATTACK | FLAGS_COLLISION_AVOIDENCE | FLAGS_TAUNT;

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
        stateMachine.AddState(AnimationTestState(this));

        stateMachine.AddState(ThugCounterState(this));
        stateMachine.AddState(ThugHitState(this));
        stateMachine.AddState(ThugAttackState(this));
        stateMachine.AddState(ThugGetUpState(this));
        stateMachine.AddState(ThugDeadState(this));
        stateMachine.AddState(ThugTauntingState(this));
        stateMachine.AddState(ThugTauntIdleState(this));

        ChangeState("StandState");

        attackDamage = one_shot_kill ? 9999 : 20;
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
        if (debug_mode == 6 || debug_mode == 2)
            return false;
        // Print(GetName() + " ActionCheck in state:" + stateMachine.currentState.name);
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
        if (!instant_collision)
        {
            if (KeepDistanceWithCharacters())
                return false;
        }

        int attackType = sceneNode.vars[ATTACK_TYPE].GetInt();
        float attackRange = (attackType == ATTACK_PUNCH) ? 0.25f : 3.78f;
        float angleDiff = ComputeAngleDiff();
        if ((GetTargetDistance() <= (attackRange + COLLISION_SAFE_DIST)) && Abs(angleDiff) < MIN_TURN_ANGLE)
        {
            LogPrint(GetName() + " start to attack angleDiff=" + angleDiff + " attackRange=" + attackRange);
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
        if (KeepDistanceWithPlayer(COLLISION_SAFE_DIST - 0.25f))
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

        sceneNode.vars[DIRECTION] = direction;

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
                Vector3 pos = sceneNode.worldPosition + Vector3(0, 0.1f, 0);
                decal.AddDecal(floorNode.GetComponent("StaticModel"), pos, Quaternion(90, Random(360), 0), size, 1.0f, 1.0f, Vector2(0.0f, 0.0f), Vector2(1.0f, 1.0f), timeToLive);
            }
        }

        Node@ attackNode = attacker.GetNode();
        float force = Random(HIT_RAGDOLL_FORCE * 0.5f, HIT_RAGDOLL_FORCE * 1.0f);
        Vector3 v = direction * Vector3(force, force, force);
        if (health <= 0)
        {
            v *= 1.5f;
            MakeMeRagdoll(v, position);
            OnDead();
        }
        else
        {
            if (weak) {
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

        for (uint i=0; i<g_dir_cache.length; ++i)
            g_dir_cache[i] = 0;

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
            g_dir_cache[dir_map] = g_dir_cache[dir_map] + 1;
            need_to_sep = true;
        }

        if (!need_to_sep)
            return ret;

        g_int_cache.Clear();
        Vector3 targetPos = target.GetNode().worldPosition;
        MultiMotionState@ state = cast<MultiMotionState>(FindState("StepMoveState"));

        for (uint i=0; i<g_dir_cache.length; ++i)
        {
            if (g_dir_cache[i] == 0)
            {
                int candidate1 = int(i); // close step move
                int candidate2 = candidate1 + 4; // far step move
                Motion@ motion1 = state.motions[candidate1];
                Motion@ motion2 = state.motions[candidate2];
                Vector3 v1 = motion1.GetKeyPosition(this, motion1.endTime);
                Vector3 v2 = motion2.GetKeyPosition(this, motion2.endTime);
                Vector3 diff = v1 - targetPos;
                diff.y = 0;
                if (diff.length >= COLLISION_SAFE_DIST)
                    g_int_cache.Push(candidate1);
                else
                {
                    //if (debug_draw_flag > 0)
                    //    gDebugMgr.AddSphere(v1, 0.25f, GREEN, 3.0f);
                }

                diff = v2 - targetPos;
                diff.y = 0;
                if (diff.length >= COLLISION_SAFE_DIST)
                    g_int_cache.Push(candidate2);
                {
                    //if (debug_draw_flag > 0)
                    //    gDebugMgr.AddSphere(v2, 0.25f, GREEN, 3.0f);
                }
            }
        }

        if (d_log)
        {
            LogPrint(GetName() + " GetSperateDirection, dir_0=" + g_dir_cache[0] + " dir_1=" + g_dir_cache[1] + " dir_2=" + g_dir_cache[2] + " dir_3=" + g_dir_cache[3]);
        }

        ret = g_int_cache[RandomInt(g_int_cache.length)];
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

    bool KeepDistanceWithCharacters()
    {
        if (HasFlag(FLAGS_NO_MOVE) || HasFlag(FLAGS_DEAD) || debug_mode == 1 || debug_mode == 3)
            return false;
        int dir = GetSperateDirection();
        if (dir < 0)
            return false;
        if (d_log)
            LogPrint(GetName() + " KeepDistanceWithCharacters dir=" + dir);
        sceneNode.vars[ANIMATION_INDEX] = dir;
        ChangeState("StepMoveState");
        return true;
    }

    bool CheckRagdollHit()
    {
        Array<RigidBody@>@ neighbors = collisionBody.collidingBodies;
        if (neighbors.empty)
            return false;

        for (uint i=0; i<neighbors.length; ++i)
        {
            RigidBody@ rb = neighbors[i];
            if (rb.collisionLayer != COLLISION_LAYER_RAGDOLL)
                continue;
            if (rb.node.name == L_CALF ||
                rb.node.name == R_CALF ||
                rb.node.name == L_ARM ||
                rb.node.name == R_ARM)
                continue;

            float vl = rb.linearVelocity.length;
            Vector3 vel = rb.linearVelocity;
            if (vl > RAGDOLL_HIT_VEL)
            {
                LogPrint(GetName() + " hit ragdoll bone " + rb.node.name + " vel=" + vel.ToString() + " vl=" + vl);
                MakeMeRagdoll(vel * 1.5f, rb.node.worldPosition);
                return true;
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
        KeepDistanceWithCharacters();
    }

    bool Distract()
    {
        ChangeState("DistractState");
        return true;
    }

    void UpdateOnFlagsChanged()
    {
        String matName = HasFlag(FLAGS_ATTACK) ? "Materials/Mt.xml" : "Materials/Mt_Red.xml";
        Material@ m = cache.GetResource("Material", matName);
        animModel.materials[0]= m;
        animModel.materials[1]= m;
        animModel.materials[2]= m;
    }

    bool KeepDistanceWithPlayer(float max_dist = COLLISION_SAFE_DIST)
    {
        if (HasFlag(FLAGS_NO_MOVE) || !HasFlag(FLAGS_COLLISION_AVOIDENCE) || debug_mode == 6)
            return false;
        float dist = GetTargetDistance();
        if (dist >= max_dist)
            return false;
        int index = RadialSelectAnimation(4);
        index += 2;
        index = index % 4;
        if (RandomInt(2) == 1)
            index += 4;

        LogPrint(GetName() + " KeepDistanceWithPlayer index=" + index + " dist=" + dist);
        sceneNode.vars[ANIMATION_INDEX] = index;
        ChangeState("StepMoveState");
        return true;
    }

    void KeepDistanceWithCharacter(Character@ c)
    {
        if (HasFlag(FLAGS_NO_MOVE) || HasFlag(FLAGS_DEAD) || debug_mode == 1 || debug_mode == 3 || debug_mode == 6)
            return;
        int index = RadialSelectAnimation(c.GetNode().worldPosition, 4);
        index += 2;
        index = index % 4;
        if (RandomInt(2) == 1)
            index += 4;

        sceneNode.vars[ANIMATION_INDEX] = index;
        LogPrint(GetName() + " KeepDistanceWithCharacter c=" + c.GetName() + " index=" + index);
        ChangeState("StepMoveState");
    }

    void HitRagdoll(RigidBody@ rb)
    {
        bool bRagdoll = false;
        float vl = rb.linearVelocity.length;
        Vector3 vel = rb.linearVelocity;

        if (rb.collisionLayer == COLLISION_LAYER_RAGDOLL)
        {
            if (rb.node.name == HEAD || rb.node.name == PELVIS)
            {
                if (vl > RAGDOLL_HIT_VEL)
                    bRagdoll = true;
            }
        }
        else if (rb.collisionLayer == COLLISION_LAYER_PROP)
        {
            if (vl > RAGDOLL_HIT_VEL)
                bRagdoll = true;
        }

        if (bRagdoll)
        {
            if (debug_mode == 4)
            {
                DebugPause(true);
            }

            LogPrint(GetName() + " hit ragdoll bone " + rb.node.name + " vel=" + vel.ToString() + " vl=" + vl);
            MakeMeRagdoll(vel * 1.5f, rb.node.worldPosition);
        }
    }
};

void CreateThugCombatMotions()
{
    BM_Game_MotionManager@ mgr = cast<BM_Game_MotionManager>(gMotionMgr);

    String preFix = "TG_Combat/";

    int attackMotionFlag = kMotion_XZ;
    mgr.thug_attack_motions.Push(Global_CreateMotion(preFix + "Attack_Punch", attackMotionFlag, "Bip01_L_Foot", 24));
    mgr.thug_attack_motions.Push(Global_CreateMotion(preFix + "Attack_Punch_01", attackMotionFlag, "Bip01_L_Foot", 24));
    mgr.thug_attack_motions.Push(Global_CreateMotion(preFix + "Attack_Punch_02", attackMotionFlag, "Bip01_L_Foot", 24));
    mgr.thug_attack_motions.Push(Global_CreateMotion(preFix + "Attack_Kick", attackMotionFlag, "Bip01_R_Hand", 23));
    mgr.thug_attack_motions.Push(Global_CreateMotion(preFix + "Attack_Kick_01", attackMotionFlag, "Bip01_R_Hand", 23));
    mgr.thug_attack_motions.Push(Global_CreateMotion(preFix + "Attack_Kick_02", attackMotionFlag, "Bip01_R_Hand", 23));

    preFix = "TG_HitReaction/";
    int hitMotionFlag = kMotion_XZR;
    int hitAllowMotion = kMotion_XZR;
    Global_CreateMotion(preFix + "HitReaction_Left", hitMotionFlag, hitAllowMotion);
    Global_CreateMotion(preFix + "HitReaction_Right", hitMotionFlag, hitAllowMotion);
    Global_CreateMotion(preFix + "HitReaction_Back_NoTurn", hitMotionFlag, hitAllowMotion);
    Global_CreateMotion(preFix + "HitReaction_Back", hitMotionFlag, hitAllowMotion);
    // Global_AddAnimation(preFix + "CapeHitReaction_Idle");

    preFix = "TG_Getup/";
    Global_CreateMotion(preFix + "GetUp_Front", kMotion_XZ);
    Global_CreateMotion(preFix + "GetUp_Back", kMotion_XZ);

    preFix = "TG_BM_Counter/";
    // arm front
    mgr.thug_counter_arm_front_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Arm_Front_01"));
    mgr.thug_counter_arm_front_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Arm_Front_02"));
    mgr.thug_counter_arm_front_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Arm_Front_03"));
    mgr.thug_counter_arm_front_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Arm_Front_04"));
    mgr.thug_counter_arm_front_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Arm_Front_05"));
    mgr.thug_counter_arm_front_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Arm_Front_06"));
    mgr.thug_counter_arm_front_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Arm_Front_07"));
    mgr.thug_counter_arm_front_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Arm_Front_08"));
    mgr.thug_counter_arm_front_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Arm_Front_09"));
    mgr.thug_counter_arm_front_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Arm_Front_10"));
    mgr.thug_counter_arm_front_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Arm_Front_13"));
    mgr.thug_counter_arm_front_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Arm_Front_14"));
    mgr.thug_counter_arm_front_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Arm_Front_Weak_02"));
    mgr.thug_counter_arm_front_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Arm_Front_Weak_03"));
    mgr.thug_counter_arm_front_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Arm_Front_Weak_04"));

    // leg front
    mgr.thug_counter_leg_front_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Leg_Front_01"));
    mgr.thug_counter_leg_front_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Leg_Front_02"));
    mgr.thug_counter_leg_front_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Leg_Front_03"));
    mgr.thug_counter_leg_front_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Leg_Front_04"));
    mgr.thug_counter_leg_front_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Leg_Front_05"));
    mgr.thug_counter_leg_front_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Leg_Front_06"));
    mgr.thug_counter_leg_front_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Leg_Front_07"));
    mgr.thug_counter_leg_front_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Leg_Front_08"));
    mgr.thug_counter_leg_front_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Leg_Front_09"));
    mgr.thug_counter_leg_front_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Leg_Front_Weak_01"));
    mgr.thug_counter_leg_front_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Leg_Front_Weak_02"));
    mgr.thug_counter_leg_front_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Leg_Front_Weak"));

    // arm back
    mgr.thug_counter_arm_back_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Arm_Back_01"));
    mgr.thug_counter_arm_back_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Arm_Back_02"));
    mgr.thug_counter_arm_back_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Arm_Back_03"));
    mgr.thug_counter_arm_back_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Arm_Back_05"));
    mgr.thug_counter_arm_back_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Arm_Back_06"));
    mgr.thug_counter_arm_back_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Arm_Back_Weak_01"));
    mgr.thug_counter_arm_back_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Arm_Back_Weak_02"));
    mgr.thug_counter_arm_back_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Arm_Back_Weak_03"));

    // leg back
    mgr.thug_counter_leg_back_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Leg_Back_01"));
    mgr.thug_counter_leg_back_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Leg_Back_02"));
    mgr.thug_counter_leg_back_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Leg_Back_03"));
    mgr.thug_counter_leg_back_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Leg_Back_04"));
    mgr.thug_counter_leg_back_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Leg_Back_05"));
    mgr.thug_counter_leg_back_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Leg_Back_Weak_01"));
    mgr.thug_counter_leg_back_motions.Push(Global_CreateMotion("TG_BM_Counter/Counter_Leg_Back_Weak_03"));

    // double counter
    mgr.thug_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsA_01"));
    mgr.thug_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsA_02"));
    mgr.thug_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsB_01"));
    mgr.thug_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsB_02"));
    mgr.thug_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsD_01"));
    mgr.thug_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsD_02"));
    mgr.thug_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsE_01"));
    mgr.thug_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsE_02"));
    mgr.thug_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsF_01"));
    mgr.thug_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsF_02"));
    mgr.thug_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsG_01"));
    mgr.thug_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsG_02"));
    mgr.thug_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsH_01"));
    mgr.thug_counter_double_motions.Push(Global_CreateMotion(preFix + "Double_Counter_2ThugsH_02"));

    // triple counter
    mgr.thug_counter_triple_motions.Push(Global_CreateMotion(preFix + "Double_Counter_3ThugsA_01"));
    mgr.thug_counter_triple_motions.Push(Global_CreateMotion(preFix + "Double_Counter_3ThugsA_02"));
    mgr.thug_counter_triple_motions.Push(Global_CreateMotion(preFix + "Double_Counter_3ThugsA_03"));
    mgr.thug_counter_triple_motions.Push(Global_CreateMotion(preFix + "Double_Counter_3ThugsB_01"));
    mgr.thug_counter_triple_motions.Push(Global_CreateMotion(preFix + "Double_Counter_3ThugsB_02"));
    mgr.thug_counter_triple_motions.Push(Global_CreateMotion(preFix + "Double_Counter_3ThugsB_03"));
    mgr.thug_counter_triple_motions.Push(Global_CreateMotion(preFix + "Double_Counter_3ThugsC_01"));
    mgr.thug_counter_triple_motions.Push(Global_CreateMotion(preFix + "Double_Counter_3ThugsC_02"));
    mgr.thug_counter_triple_motions.Push(Global_CreateMotion(preFix + "Double_Counter_3ThugsC_03"));

    // environment counter
    /*thug_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_128_Back_02"));
    thug_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_128_Front_01"));
    thug_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_128_Left_01"));
    thug_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_128_Right_01"));
    thug_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_128_Right_02"));*/
    mgr.thug_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_Wall_Back_02"));
    mgr.thug_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_Wall_Front_01"));
    mgr.thug_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_Wall_Front_02"));
    mgr.thug_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_Wall_Left_02"));
    mgr.thug_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_Wall_Right"));
    mgr.thug_counter_environment_motions.Push(Global_CreateMotion(preFix + "Environment_Counter_Wall_Right_02"));

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
    // AssignMotionRig("Models/swat.mdl");

    String preFix = "TG_Combat/";
    Global_CreateMotion(preFix + "Step_Forward");
    Global_CreateMotion(preFix + "Step_Right");
    Global_CreateMotion(preFix + "Step_Back");
    Global_CreateMotion(preFix + "Step_Left");
    Global_CreateMotion(preFix + "Step_Forward_Long");
    Global_CreateMotion(preFix + "Step_Right_Long");
    Global_CreateMotion(preFix + "Step_Back_Long");
    Global_CreateMotion(preFix + "Step_Left_Long");

    Global_CreateMotion(preFix + "135_Turn_Left", kMotion_XZR, kMotion_R, 32);
    Global_CreateMotion(preFix + "135_Turn_Right", kMotion_XZR, kMotion_R, 32);

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
    AddRagdollTrigger(preFix + "Counter_Arm_Front_14", 48, 60);
    AddAnimationTrigger(preFix + "Counter_Arm_Front_Weak_02", 45, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "Counter_Arm_Front_Weak_03", 100, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "Counter_Arm_Front_Weak_04", 70, READY_TO_FIGHT);

    AddRagdollTrigger(preFix + "Counter_Leg_Back_01", 45, 54);
    AddRagdollTrigger(preFix + "Counter_Leg_Back_02", 50, 60);
    AddRagdollTrigger(preFix + "Counter_Leg_Back_03", -1, 70);
    AddRagdollTrigger(preFix + "Counter_Leg_Back_04", -1, 44);
    AddRagdollTrigger(preFix + "Counter_Leg_Back_05", -1, 40);
    AddAnimationTrigger(preFix + "Counter_Leg_Back_Weak_01", 80, READY_TO_FIGHT);
    AddAnimationTrigger(preFix + "Counter_Leg_Back_Weak_03", 80, READY_TO_FIGHT);

    AddRagdollTrigger(preFix + "Counter_Leg_Front_01", 25, 39);
    AddRagdollTrigger(preFix + "Counter_Leg_Front_02", 25, 54);
    AddRagdollTrigger(preFix + "Counter_Leg_Front_03", 15, 23);
    AddRagdollTrigger(preFix + "Counter_Leg_Front_04", 32, 35);
    AddRagdollTrigger(preFix + "Counter_Leg_Front_05", 38, 42);
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

    AddRagdollTrigger(preFix + "Double_Counter_3ThugsA_01", 20, 32);
    AddRagdollTrigger(preFix + "Double_Counter_3ThugsA_02", 29, 32);
    AddRagdollTrigger(preFix + "Double_Counter_3ThugsA_03", 27, 32);

    AddRagdollTrigger(preFix + "Double_Counter_3ThugsB_01", 25, 33);
    AddRagdollTrigger(preFix + "Double_Counter_3ThugsB_02", 25, 33);
    AddRagdollTrigger(preFix + "Double_Counter_3ThugsB_03", 25, 33);

    AddRagdollTrigger(preFix + "Double_Counter_3ThugsC_01", 35, 41);
    AddRagdollTrigger(preFix + "Double_Counter_3ThugsC_02", 35, 45);
    AddRagdollTrigger(preFix + "Double_Counter_3ThugsC_03", 35, 45);

    AddRagdollTrigger(preFix + "Environment_Counter_Wall_Back_02", -1, 80);
    AddStringAnimationTrigger(preFix + "Environment_Counter_Wall_Back_02", 7, PARTICLE, HEAD);

    AddRagdollTrigger(preFix + "Environment_Counter_Wall_Front_01", -1, 40);
    AddRagdollTrigger(preFix + "Environment_Counter_Wall_Front_02", -1, 50);
    AddRagdollTrigger(preFix + "Environment_Counter_Wall_Left_02", 38, 45);
    AddRagdollTrigger(preFix + "Environment_Counter_Wall_Right", -1, 60);
    AddRagdollTrigger(preFix + "Environment_Counter_Wall_Right_02", -1, 65);

    preFix = "TG_Combat/";
    int frame_fixup = 6;
    // name counter-start counter-end attack-start attack-end attack-bone
    AddComplexAttackTrigger(preFix + "Attack_Kick", 15 - frame_fixup, 24, 24, 27, L_FOOT);
    AddComplexAttackTrigger(preFix + "Attack_Kick_01", 12 - frame_fixup, 24, 24, 27, L_FOOT);
    AddComplexAttackTrigger(preFix + "Attack_Kick_02", 19 - frame_fixup, 24, 24, 27, L_FOOT);
    AddComplexAttackTrigger(preFix + "Attack_Punch", 15 - frame_fixup, 22, 22, 24, R_HAND);
    AddComplexAttackTrigger(preFix + "Attack_Punch_01", 15 - frame_fixup, 23, 23, 24, R_HAND);
    AddComplexAttackTrigger(preFix + "Attack_Punch_02", 15 - frame_fixup, 23, 23, 24, R_HAND);

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

