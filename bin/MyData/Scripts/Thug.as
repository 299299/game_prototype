// ==============================================
//
//    Thug Pawn and Controller Class
//
// ==============================================

const String MOVEMENT_GROUP_THUG = "TG_Combat/";
const float MIN_TURN_ANGLE = 30;
float PUNCH_DIST = 0.0f;
float KICK_DIST = 0.0f;
float STEP_MAX_DIST = 0.0f;
float STEP_MIN_DIST = 0.0f;
float KEEP_DIST_WITH_PLAYER = -0.25f;
const int HIT_WAIT_FRAMES = 3;
const float MIN_THINK_TIME = 0.25f;
const float MAX_THINK_TIME = 1.0f;
const float KEEP_DIST_WITHIN_PLAYER = 20.0f;
const float MAX_ATTACK_RANGE = 3.0f;

class ThugStandState : CharacterState
{
    Array<String>   animations;
    float           thinkTime;

    float           checkAvoidanceTimer = 0.0f;
    float           checkAvoidanceTime = 0.1f;
    float           attackRange;

    bool            firstEnter = true;

    ThugStandState(Character@ c)
    {
        super(c);
        SetName("StandState");
        animations.Push(GetAnimationName(MOVEMENT_GROUP_THUG + "Stand_Idle_Additive_01"));
        animations.Push(GetAnimationName(MOVEMENT_GROUP_THUG + "Stand_Idle_Additive_02"));
        animations.Push(GetAnimationName(MOVEMENT_GROUP_THUG + "Stand_Idle_Additive_03"));
        animations.Push(GetAnimationName(MOVEMENT_GROUP_THUG + "Stand_Idle_Additive_04"));
    }

    void Enter(State@ lastState)
    {
        float blendTime = 0.2f;
        /*
        if (lastState !is null)
        {
            if (lastState.nameHash == ATTACK_STATE || lastState.nameHash == TURN_STATE)
                blendTime = 5.0f;
        }
        */
        ownner.PlayAnimation(animations[RandomInt(animations.length)], LAYER_MOVE, true, blendTime);
        ownner.AddFlag(FLAGS_REDIRECTED | FLAGS_ATTACK);
        float min_think_time = MIN_THINK_TIME;
        float max_think_time = MAX_THINK_TIME;
        if (firstEnter)
        {
            min_think_time = 2.0f;
            max_think_time = 3.0f;
            firstEnter = false;
        }
        thinkTime = Random(min_think_time, max_think_time);
        if (d_log)
            Print(ownner.GetName() + " thinkTime=" + thinkTime);
        checkAvoidanceTime = Random(0.1f, 0.2f);
        attackRange = Random(0.0f, MAX_ATTACK_RANGE);
        CharacterState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        ownner.RemoveFlag(FLAGS_REDIRECTED | FLAGS_ATTACK);
        CharacterState::Exit(nextState);
    }

    void Update(float dt)
    {
        //if (engine.headless)
           return;

        if (timeInState > thinkTime)
        {
            OnThinkTimeOut();
            timeInState = 0.0f;
            thinkTime = Random(MIN_THINK_TIME, MAX_THINK_TIME);
        }

        CharacterState::Update(dt);
    }

    void OnThinkTimeOut()
    {
        float diff = Abs(ownner.ComputeAngleDiff());
        if (diff > MIN_TURN_ANGLE)
        {
            // I should always turn to look at player.
            ownner.ChangeState("TurnState");
            return;
        }

        Node@ _node = ownner.GetNode();
        EnemyManager@ em = cast<EnemyManager>(_node.scene.GetScriptObject("EnemyManager"));
        float dist = ownner.GetTargetDistance()  - COLLISION_SAFE_DIST;
        if (ownner.CanAttack() && dist <= attackRange)
        {
            Print("do attack because dist <= " + attackRange);
            if (ownner.Attack())
                return;
        }

        int rand_i = 0;
        int num_of_moving_thugs = em.GetNumOfEnemyHasFlag(FLAGS_MOVING);
        //bool can_i_see_player = !ownner.IsTargetSightBlocked();
        if (num_of_moving_thugs < MAX_NUM_OF_MOVING && !ownner.HasFlag(FLAGS_NO_MOVE))
        {
            // try to move to player
            rand_i = RandomInt(2);
            String nextState = "StepMoveState";
            float run_dist = STEP_MAX_DIST + 0.5f;
            if (dist >= run_dist || rand_i == 1)
                nextState = "RunState";
            else
            {
                ThugStepMoveState@ state = cast<ThugStepMoveState>(ownner.FindState("StepMoveState"));
                int index = state.GetStepMoveIndex();
                Print(ownner.GetName() + " apply animation index for step move in thug stand state: " + index);
                _node.vars[ANIMATION_INDEX] = index;
            }
            ownner.ChangeState(nextState);
        }
        else
        {
            if (dist >= KEEP_DIST_WITHIN_PLAYER)
            {
                ThugStepMoveState@ state = cast<ThugStepMoveState>(ownner.FindState("StepMoveState"));
                int index = state.GetStepMoveIndex();
                Print(ownner.GetName() + " apply animation index for keep with with player in stand state: " + index);
                _node.vars[ANIMATION_INDEX] = index;
                ownner.ChangeState("StepMoveState");
                return;
            }

            rand_i = RandomInt(2);
            if (rand_i == 0)
            {
                int index = RandomInt(4);
                _node.vars[ANIMATION_INDEX] = index;
                Print(ownner.GetName() + " apply animation index for random move in stand state: " + index);
                ownner.ChangeState("StepMoveState");
            }
            else if (rand_i == 1)
            {
                int num_of_combat_idle = em.GetNumOfEnemyInState(COMBAT_IDLE_STATE);
                if (num_of_combat_idle < MAX_NUM_OF_COMBAT_IDLE)
                    ownner.ChangeState("CombatIdleState");
            }
        }

        attackRange = Random(0.0f, MAX_ATTACK_RANGE);
    }

    void FixedUpdate(float dt)
    {
        checkAvoidanceTimer += dt;
        if (checkAvoidanceTimer >= checkAvoidanceTime)
        {
            checkAvoidanceTimer -= checkAvoidanceTime;
            ownner.CheckCollision();
        }
        CharacterState::FixedUpdate(dt);
    }
};

class ThugCombatIdleState : CharacterState
{
    Array<String> animations;
    int index = 0;

    float           checkAvoidanceTimer = 0.0f;
    float           checkAvoidanceTime = 0.1f;

    ThugCombatIdleState(Character@ c)
    {
        super(c);
        SetName("CombatIdleState");
        animations.Push(GetAnimationName(MOVEMENT_GROUP_THUG + "Stand_Idle_Combat_Overlays_01"));
        animations.Push(GetAnimationName(MOVEMENT_GROUP_THUG + "Stand_Idle_Combat_Overlays_02"));
        animations.Push(GetAnimationName(MOVEMENT_GROUP_THUG + "Stand_Idle_Combat_Overlays_03"));
    }

    void Enter(State@ lastState)
    {
        //index = RandomInt(animations.length);
        EnemyManager@ em = GetEnemyMgr();
        for (int i=0; i<3; ++i)
        {
            int flag = (1 << i);
            int b = em.thugCombatIdleFlags & flag;
            if (b == 0)
            {
                index = i;
                break;
            }
        }
        Print("em.thugCombatIdleFlags=" + em.thugCombatIdleFlags + " index=" + index);
        em.thugCombatIdleFlags |= (1 << index);
        ownner.AddFlag(FLAGS_REDIRECTED | FLAGS_ATTACK);
        checkAvoidanceTime = Random(0.1f, 0.2f);
        ownner.PlayAnimation(animations[index], LAYER_MOVE, false);
        CharacterState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        EnemyManager@ em = GetEnemyMgr();
        em.thugCombatIdleFlags &= ~(1 << index);
        ownner.RemoveFlag(FLAGS_REDIRECTED | FLAGS_ATTACK);
        CharacterState::Exit(nextState);
    }

    void Update(float dt)
    {
        float dist = ownner.GetTargetDistance()  - COLLISION_SAFE_DIST;
        if (dist < KEEP_DIST_WITH_PLAYER && !ownner.HasFlag(FLAGS_NO_MOVE))
        {
            ThugStepMoveState@ state = cast<ThugStepMoveState>(ownner.FindState("StepMoveState"));
            int stepIndex = state.GetStepMoveIndex();
            Print(ownner.GetName() + " apply animation index for keep away from player in combat idle state: " + stepIndex);
            ownner.GetNode().vars[ANIMATION_INDEX] = stepIndex;
            ownner.ChangeState("StepMoveState");
            return;
        }

        if (ownner.animCtrl.IsAtEnd(animations[index]))
        {
            ownner.CommonStateFinishedOnGroud();
            return;
        }

        CharacterState::Update(dt);
    }

    void FixedUpdate(float dt)
    {
        checkAvoidanceTimer += dt;
        if (checkAvoidanceTimer >= checkAvoidanceTime)
        {
            checkAvoidanceTimer -= checkAvoidanceTime;
            ownner.CheckCollision();
        }
        CharacterState::FixedUpdate(dt);
    }
};

class ThugStepMoveState : MultiMotionState
{
    float attackRange;

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
    }

    void Update(float dt)
    {
        if (motions[selectIndex].Move(ownner, dt))
        {
            float dist = ownner.GetTargetDistance() - COLLISION_SAFE_DIST;
            bool attack = false;

            if (dist <= attackRange && dist >= -0.5f)
            {
                if (Abs(ownner.ComputeAngleDiff()) < MIN_TURN_ANGLE)
                {
                    if (ownner.Attack())
                        return;
                }
                else
                {
                    ownner.ChangeState("TurnState");
                    return;
                }
            }
            ownner.CommonStateFinishedOnGroud();
            return;
        }

        CharacterState::Update(dt);
    }

    int GetStepMoveIndex()
    {
        int index = 0;
        float dist = ownner.GetTargetDistance() - COLLISION_SAFE_DIST;
        if (dist < KEEP_DIST_WITH_PLAYER)
        {
            index = ownner.RadialSelectAnimation(4);
            index = (index + 2) % 4;
        }
        else
        {
            bool step_long = false;
            if (dist > motions[0].endDistance + 0.25f)
                step_long = true;
            if (step_long)
                index += 3;
        }

        Print("ThugStepMoveState->GetStepMoveIndex()=" + index);
        return index;
    }

    void Enter(State@ lastState)
    {
        attackRange = Random(0.0, MAX_ATTACK_RANGE);
        ownner.AddFlag(FLAGS_REDIRECTED | FLAGS_ATTACK | FLAGS_MOVING);
        MultiMotionState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        ownner.RemoveFlag(FLAGS_REDIRECTED | FLAGS_ATTACK | FLAGS_MOVING);
        MultiMotionState::Exit(nextState);
    }

    int GetThreatScore()
    {
        return 10;
    }
};

class ThugRunState : SingleMotionState
{
    float turnSpeed = 5.0f;
    float attackRange;

    float           checkAvoidanceTimer = 0.0f;
    float           checkAvoidanceTime = 0.1f;

    ThugRunState(Character@ c)
    {
        super(c);
        SetName("RunState");
        SetMotion(MOVEMENT_GROUP_THUG + "Run_Forward_Combat");
    }

    void Update(float dt)
    {
        float characterDifference = ownner.ComputeAngleDiff();
        ownner.GetNode().Yaw(characterDifference * turnSpeed * dt);

        // if the difference is large, then turn 180 degrees
        if (Abs(characterDifference) > FULLTURN_THRESHOLD)
        {
            ownner.ChangeState("TurnState");
            return;
        }

        float dist = ownner.GetTargetDistance() - COLLISION_SAFE_DIST;
        if (dist <= attackRange)
        {
            if (ownner.Attack())
                return;
            ownner.CommonStateFinishedOnGroud();
            return;
        }

        SingleMotionState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        SingleMotionState::Enter(lastState);
        attackRange = Random(0.0, MAX_ATTACK_RANGE);
        checkAvoidanceTime = Random(0.1f, 0.2f);
        ownner.AddFlag(FLAGS_REDIRECTED | FLAGS_ATTACK | FLAGS_MOVING);
    }

    void Exit(State@ nextState)
    {
        SingleMotionState::Exit(nextState);
        ownner.RemoveFlag(FLAGS_REDIRECTED | FLAGS_ATTACK | FLAGS_MOVING);
    }

    void FixedUpdate(float dt)
    {
        checkAvoidanceTimer += dt;
        if (checkAvoidanceTimer >= checkAvoidanceTime)
        {
            checkAvoidanceTimer -= checkAvoidanceTime;
            ownner.CheckCollision();
        }
        CharacterState::FixedUpdate(dt);
    }

    int GetThreatScore()
    {
        return 10;
    }
};

class ThugTurnState : MultiMotionState
{
    float turnSpeed;
    float endTime;

    float           checkAvoidanceTimer = 0.0f;
    float           checkAvoidanceTime = 0.1f;

    ThugTurnState(Character@ c)
    {
        super(c);
        SetName("TurnState");
        AddMotion(MOVEMENT_GROUP_THUG + "135_Turn_Right");
        AddMotion(MOVEMENT_GROUP_THUG + "135_Turn_Left");
    }

    void Update(float dt)
    {
        Motion@ motion = motions[selectIndex];
        float t = ownner.animCtrl.GetTime(motion.animationName);
        float characterDifference = Abs(ownner.ComputeAngleDiff());
        if (t >= endTime || characterDifference < 5)
        {
            ownner.CommonStateFinishedOnGroud();
            return;
        }
        ownner.GetNode().Yaw(turnSpeed * dt);
        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        float diff = ownner.ComputeAngleDiff();
        int index = 0;
        if (diff < 0)
            index = 1;
        ownner.GetNode().vars[ANIMATION_INDEX] = index;
        endTime = motions[index].endTime;
        turnSpeed = diff / endTime;
        Print("ThugTurnState diff=" + diff + " turnSpeed=" + turnSpeed + " time=" + motions[selectIndex].endTime);
        ownner.AddFlag(FLAGS_REDIRECTED | FLAGS_ATTACK);
        checkAvoidanceTime = Random(0.1f, 0.2f);
        MultiMotionState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        MultiMotionState::Exit(nextState);
        ownner.RemoveFlag(FLAGS_REDIRECTED | FLAGS_ATTACK);
    }

    void FixedUpdate(float dt)
    {
        checkAvoidanceTimer += dt;
        if (checkAvoidanceTimer >= checkAvoidanceTime)
        {
            checkAvoidanceTimer -= checkAvoidanceTime;
            ownner.CheckCollision();
        }
        CharacterState::FixedUpdate(dt);
    }
};


class ThugCounterState : CharacterCounterState
{
    ThugCounterState(Character@ c)
    {
        super(c);
        AddCounterMotions("TG_BM_Counter/");
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
    }

    void AddAttackMotion(const String&in name, int impactFrame, int type, const String&in bName)
    {
        attacks.Push(AttackMotion(MOVEMENT_GROUP_THUG + name, impactFrame, type, bName));
    }

    void Update(float dt)
    {
        Motion@ motion = currentAttack.motion;
        float targetDistance = ownner.GetTargetDistance();
        if (ownner.motion_translateEnabled && targetDistance < COLLISION_SAFE_DIST)
            ownner.motion_translateEnabled = false;

        float characterDifference = ownner.ComputeAngleDiff();
        ownner.motion_deltaRotation += characterDifference * turnSpeed * dt;

        if (doAttackCheck)
            AttackCollisionCheck();

        // TODO ....
        bool finished = motion.Move(ownner, dt);
        if (finished)
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

    void Enter(State@ lastState)
    {
        float targetDistance = ownner.GetTargetDistance() - COLLISION_SAFE_DIST;
        float punchDist = attacks[0].motion.endDistance;
        Print("targetDistance=" + targetDistance + " punchDist=" + punchDist);
        int index = RandomInt(3);
        if (targetDistance > punchDist + 1.0f)
            index += 3; // a kick attack
        @currentAttack = attacks[index];
        ownner.GetNode().vars[ATTACK_TYPE] = currentAttack.type;
        Motion@ motion = currentAttack.motion;
        motion.Start(ownner);
        ownner.AddFlag(FLAGS_REDIRECTED | FLAGS_ATTACK);
        doAttackCheck = false;
        CharacterState::Enter(lastState);
        Print("Thug Pick attack motion = " + motion.animationName);
    }

    void Exit(State@ nextState)
    {
        @currentAttack = null;
        ownner.RemoveFlag(FLAGS_REDIRECTED | FLAGS_ATTACK | FLAGS_COUNTER);
        ownner.SetTimeScale(1.0f);
        attackCheckNode = null;
        ShowHint(false);
        CharacterState::Exit(nextState);
    }

    void ShowHint(bool bshow)
    {
        Print("===============================================================");
        Print("Counter Start " + bshow);
        Print("===============================================================");
        ownner.SetHintText("!!!!!!!!!!", bshow);
    }

    void OnAnimationTrigger(AnimationState@ animState, const VariantMap&in eventData)
    {
        CharacterState::OnAnimationTrigger(animState, eventData);
        StringHash name = eventData[NAME].GetStringHash();
        if (name == TIME_SCALE)
        {
            float scale = eventData[VALUE].GetFloat();
            ownner.SetTimeScale(scale);
        }
        else if (name == COUNTER_CHECK)
        {
            int value = eventData[VALUE].GetInt();
            ShowHint(value == 1);
            if (value == 1)
                ownner.AddFlag(FLAGS_COUNTER);
            else
                ownner.RemoveFlag(FLAGS_COUNTER);
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
                Print("Thug AttackCheck bone=" + attackCheckNode.name);
                AttackCollisionCheck();
            }
        }
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

    int GetThreatScore()
    {
        return 30;
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

        AddMotion(preFix + "Push_Reaction");
        AddMotion(preFix + "Push_Reaction_From_Back");
    }

    void Update(float dt)
    {
        if (timeInState >= recoverTimer)
            ownner.AddFlag(FLAGS_ATTACK | FLAGS_REDIRECTED);
        MultiMotionState::Update(dt);
    }

    void Exit(State@ nextState)
    {
        ownner.RemoveFlag(FLAGS_ATTACK | FLAGS_REDIRECTED);
        MultiMotionState::Exit(nextState);
    }

    bool CanReEntered()
    {
        return timeInState >= recoverTimer;
    }
};

class ThugRedirectState : MultiMotionState
{
    ThugRedirectState(Character@ c)
    {
        super(c);
        SetName("RedirectState");
        AddMotion(MOVEMENT_GROUP_THUG + "Redirect_push_back");
        AddMotion(MOVEMENT_GROUP_THUG + "Redirect_Stumble_JK");
    }

    void Enter(State@ lastState)
    {
        selectIndex = PickIndex();
        if (d_log)
            Print(name + " pick " + motions[selectIndex].animationName);
        motions[selectIndex].Start(ownner, 0.0f, 0.5f);
    }

    int PickIndex()
    {
        return RandomInt(2);
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
        CharacterGetUpState::OnAnimationTrigger(animState, eventData);
        StringHash name = eventData[NAME].GetStringHash();
        if (name == READY_TO_FIGHT)
            ownner.AddFlag(FLAGS_ATTACK | FLAGS_REDIRECTED);
    }

    void Enter(State@ lastState)
    {
        CharacterGetUpState::Enter(lastState);
        ownner.SetNodeEnabled("Collision", true);
    }

    void Exit(State@ nextState)
    {
        ownner.RemoveFlag(FLAGS_ATTACK | FLAGS_REDIRECTED);
        CharacterGetUpState::Exit(nextState);
    }
};

class ThugDeadState : CharacterState
{
    ThugDeadState(Character@ c)
    {
        super(c);
        SetName("DeadState");
    }

    void Enter(State@ lastState)
    {
        Print(ownner.GetName() + " Entering ThugDeadState");
        ownner.MakeMeRagdoll(1);
        ownner.duration = 5.0f;
        CharacterState::Enter(lastState);
    }
};

class ThugBeatDownStartState : SingleMotionState
{
    ThugBeatDownStartState(Character@ c)
    {
        super(c);
        SetName("BeatDownStart");
        SetMotion("TG_BM_Beatdown/Beatdown_Start_01");
    }
};

class ThugBeatDownEndState : MultiMotionState
{
    ThugBeatDownEndState(Character@ c)
    {
        super(c);
        SetName("BeatDownEnd");
        String preFix = "TG_BM_Beatdown/";
        AddMotion(preFix + "Beatdown_Strike_End_01");
        AddMotion(preFix + "Beatdown_Strike_End_02");
        AddMotion(preFix + "Beatdown_Strike_End_03");
        AddMotion(preFix + "Beatdown_Strike_End_04");
    }
};

class ThugBeatDownHitState : MultiMotionState
{
    ThugBeatDownHitState(Character@ c)
    {
        super(c);
        SetName("BeatDownHit");
        String preFix = "TG_BM_Beatdown/";
        AddMotion(preFix + "Beatdown_HitReaction_01");
        AddMotion(preFix + "Beatdown_HitReaction_02");
        AddMotion(preFix + "Beatdown_HitReaction_03");
        AddMotion(preFix + "Beatdown_HitReaction_04");
        AddMotion(preFix + "Beatdown_HitReaction_05");
        AddMotion(preFix + "Beatdown_HitReaction_06");
    }

    bool CanReEntered()
    {
        return true;
    }
};

class Thug : Enemy
{
    void ObjectStart()
    {
        Enemy::ObjectStart();
        stateMachine.AddState(ThugStandState(this));
        uint t = time.systemTime;
        stateMachine.AddState(ThugCounterState(this));
        Print("ThugCounterState time-cost=" + (time.systemTime - t) + " ms");

        stateMachine.AddState(ThugHitState(this));
        stateMachine.AddState(ThugStepMoveState(this));
        stateMachine.AddState(ThugTurnState(this));
        stateMachine.AddState(ThugRunState(this));
        if (has_redirect)
            stateMachine.AddState(ThugRedirectState(this));
        stateMachine.AddState(ThugAttackState(this));
        stateMachine.AddState(CharacterRagdollState(this));
        stateMachine.AddState(ThugGetUpState(this));
        stateMachine.AddState(ThugDeadState(this));
        stateMachine.AddState(ThugCombatIdleState(this));
        stateMachine.AddState(ThugBeatDownStartState(this));
        stateMachine.AddState(ThugBeatDownHitState(this));
        stateMachine.AddState(ThugBeatDownEndState(this));
        stateMachine.ChangeState("StandState");

        Motion@ kickMotion = gMotionMgr.FindMotion("TG_Combat/Attack_Kick");
        KICK_DIST = kickMotion.endDistance;
        Motion@ punchMotion = gMotionMgr.FindMotion("TG_Combat/Attack_Punch");
        PUNCH_DIST = punchMotion.endDistance;
        Motion@ stepMotion = gMotionMgr.FindMotion("TG_Combat/Step_Forward_Long");
        STEP_MAX_DIST = stepMotion.endDistance;
        @stepMotion = gMotionMgr.FindMotion("TG_Combat/Step_Forward");
        STEP_MIN_DIST = stepMotion.endDistance;
        Print("Thug kick-dist=" + KICK_DIST + " punch-dist=" + String(PUNCH_DIST) + " step-fwd-long-dis=" + STEP_MAX_DIST);

        /*
        Node@ hintNode = sceneNode.GetChild("HintNode", true);
        if (hintNode !is null)
        {
            Text3D@ text3d = hintNode.GetComponent("Text3D");
            text3d.text = GetName();
            text3d.enabled = true;
        }
        */

        //attackDamage = 50;
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        Character::DebugDraw(debug);
    }

    bool CanAttack()
    {
        EnemyManager@ em = cast<EnemyManager>(sceneNode.scene.GetScriptObject("EnemyManager"));
        if (em is null)
            return false;
        int num = em.GetNumOfEnemyInState(ATTACK_STATE);
        if (num >= MAX_NUM_OF_ATTACK)
            return false;
        if (!target.CanBeAttacked())
            return false;
        return true;
    }

    bool Attack()
    {
        if (!CanAttack())
            return false;
        if (KeepDistanceWithEnemy())
            return false;
        stateMachine.ChangeState("AttackState");
        return true;
    }

    bool Redirect()
    {
        stateMachine.ChangeState("RedirectState");
        return true;
    }

    void CommonStateFinishedOnGroud()
    {
        stateMachine.ChangeState("StandState");
    }

    bool OnDamage(GameObject@ attacker, const Vector3&in position, const Vector3&in direction, int damage, bool weak = false)
    {
        if (!CanBeAttacked())
        {
            if (d_log)
                Print("OnDamage failed because I can no be attacked " + GetName());
            return false;
        }

        health -= damage;
        if (health <= 0)
        {
            OnDead();
            health = 0;
        }
        else
        {
            Node@ attackNode = attacker.GetNode();
            float diff = ComputeAngleDiff(attackNode);
            if (weak) {
                int index = 0;
                if (diff < 0)
                    index = 1;
                if (Abs(diff) > 135)
                    index = 2 + RandomInt(2);
                sceneNode.vars[ANIMATION_INDEX] = index;
                stateMachine.ChangeState("HitState");
            }
            else {
                Vector3 v = direction * -1;
                v.y = 0;
                v.Normalize();
                v *= 7.5f;
                MakeMeRagdoll(0, true, v);
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
            stateMachine.ChangeState("StandState");
            return;
        }

        if (nameHash == HIT_STATE)
        {
            // I dont know how to do ...
            // special case
            motion_translateEnabled = false;
        }
    }

    int GetSperateDirection(int& outDir)
    {
        Node@ _node = sceneNode.GetChild("Collision");
        if (_node is null)
            return 0;

        RigidBody@ body = _node.GetComponent("RigidBody");
        if (body is null)
            return 0;

        int len = 0;
        Vector3 myPos = sceneNode.worldPosition;
        Array<RigidBody@>@ neighbors = body.collidingBodies;
        float totalAngle = 0;

        for (uint i=0; i<neighbors.length; ++i)
        {
            Node@ n_node = neighbors[i].node.parent;
            if (n_node is null)
                continue;

            //Print("neighbors[" + i + "] = " + n_node.name);

            Character@ object = cast<Character>(n_node.scriptObject);
            if (object is null)
                continue;

            if (object.HasFlag(FLAGS_MOVING))
                continue;

            ++len;

            float angle = ComputeAngleDiff(object.sceneNode);
            if (angle < 0)
                angle += 180;
            else
                angle = 180 - angle;

            //Print("neighbors angle=" + angle);
            totalAngle += angle;
        }

        if (len == 0)
            return 0;

        outDir = DirectionMapToIndex(totalAngle / len, 4);

        if (d_log)
            Print("GetSperateDirection() totalAngle=" + totalAngle + " outDir=" + outDir + " len=" + len);

        return len;
    }

    void FixedUpdate(float dt)
    {
        Enemy::FixedUpdate(dt);
    }

    bool KeepDistanceWithEnemy()
    {
        if (HasFlag(FLAGS_NO_MOVE))
            return false;
        int dir = -1;
        if (GetSperateDirection(dir) == 0)
            return false;
        Print(GetName() + " CollisionAvoidance index=" + dir);

        ThugStepMoveState@ state = cast<ThugStepMoveState>(FindState("StepMoveState"));
        Motion@ motion = state.motions[dir];
        Vector4 motionOut = motion.GetKey(motion.endTime);
        Vector3 endPos = sceneNode.worldRotation * Vector3(motionOut.x, motionOut.y, motionOut.z) + sceneNode.worldPosition;
        Vector3 diff = endPos - target.sceneNode.worldPosition;
        diff.y = 0;
        if((diff.length - COLLISION_SAFE_DIST) < -0.25f)
        {
            Print("can not avoid collision because player is in front of me.");
            return false;
        }

        sceneNode.vars[ANIMATION_INDEX] = dir;
        ChangeState("StepMoveState");
        return true;
    }

    bool KeepDistanceWithPlayer()
    {
        float dist = GetTargetDistance() - COLLISION_SAFE_DIST;
        if (dist < KEEP_DIST_WITH_PLAYER && !HasFlag(FLAGS_NO_MOVE))
        {
            ThugStepMoveState@ state = cast<ThugStepMoveState>(FindState("StepMoveState"));
            int index = state.GetStepMoveIndex();
            Print(GetName() + " KeepDistanceWithPlayer index=" + index);
            sceneNode.vars[ANIMATION_INDEX] = index;
            ChangeState("StepMoveState");
            return true;
        }
        return false;
    }

    void CheckCollision()
    {
        if (KeepDistanceWithPlayer())
            return;
        KeepDistanceWithEnemy();
    }
};

