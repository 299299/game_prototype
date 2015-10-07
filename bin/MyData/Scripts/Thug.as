
const String MOVEMENT_GROUP_THUG = "TG_Combat/";

class ThugStandState : RandomAnimationState
{
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
        float blendTime = 0.25f;
        if (lastState !is null)
        {
            if (lastState.nameHash == ATTACK_STATE || lastState.nameHash == TURN_STATE)
                blendTime = 5.0f;
        }
        StartBlendTime(blendTime);
        ownner.AddFlag(FLAGS_REDIRECTED);
        CharacterState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        ownner.RemoveFlag(FLAGS_REDIRECTED);
        CharacterState::Exit(nextState);
    }

    void Update(float dt)
    {
        return;

        float dist = ownner.GetTargetDistance()  - COLLISION_SAFE_DIST;
        if (timeInState > 2.0f)
        {
            float diff = ownner.ComputeAngleDiff();
            diff = Abs(diff);
            if (diff > 15)
            {
                ownner.stateMachine.ChangeState("TurnState");
                return;
            }

            float attackRange = Random(0.5, 6.0);
            if (dist > attackRange)
            {
                // try to move to player
                String nextState = "StepMoveState";
                if (dist >= 7)
                {
                   int index = ownner.RadialSelectAnimation(4);
                   if (index == 0)
                        nextState = "RunState";
                    else
                        nextState = "TurnState";
                }
                ownner.stateMachine.ChangeState(nextState);
                return;
            }
            else
            {
                // try to attack
                int num = gEnemyMgr.GetNumOfEnemyInState(ATTACK_STATE);
                if (num < MAX_NUM_OF_ATTACK)
                {
                    ownner.stateMachine.ChangeState("AttackState");
                    return;
                }
            }
        }

        RandomAnimationState::Update(dt);
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
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Right");
        // long step
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Forward_Long");
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Right_Long");
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Back_Long");
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Right_Long");
    }

    void Update(float dt)
    {
        float dist = ownner.GetTargetDistance() - COLLISION_SAFE_DIST;
        if (dist <= attackRange)
        {
            int num = gEnemyMgr.GetNumOfEnemyInState(ATTACK_STATE);
            if (num >= MAX_NUM_OF_ATTACK)
            {
                ownner.stateMachine.ChangeState("StandState");
            }
            else {
                ownner.stateMachine.ChangeState("AttackState");
            }
        }

        float characterDifference = ownner.ComputeAngleDiff();
        // if the difference is large, then turn 180 degrees
        if (Abs(characterDifference) > FULLTURN_THRESHOLD)
        {
            ownner.stateMachine.ChangeState("TurnState");
            return;
        }

        MultiMotionState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        MultiMotionState::Enter(lastState);
        ownner.AddFlag(FLAGS_REDIRECTED);
        attackRange = Random(0.5, 6.0);
    }

    void Exit(State@ nextState)
    {
        MultiMotionState::Exit(nextState);
        ownner.RemoveFlag(FLAGS_REDIRECTED);
    }
};

class ThugRunState : SingleMotionState
{
    float turnSpeed;
    float attackRange;

    ThugRunState(Character@ c)
    {
        super(c);
        SetName("RunState");
        SetMotion(MOVEMENT_GROUP_THUG + "Run_Forward_Combat");
        turnSpeed = 5.0f;
    }

    void Update(float dt)
    {
        float dist = ownner.GetTargetDistance() - COLLISION_SAFE_DIST;
        if (dist <= attackRange)
        {
            int num = gEnemyMgr.GetNumOfEnemyInState(ATTACK_STATE);
            if (num >= MAX_NUM_OF_ATTACK)
            {
                ownner.stateMachine.ChangeState("StandState");
            }
            else {
                ownner.stateMachine.ChangeState("AttackState");
            }
        }

        float characterDifference = ownner.ComputeAngleDiff();
        ownner.sceneNode.Yaw(characterDifference * turnSpeed * dt);

        // if the difference is large, then turn 180 degrees
        if (Abs(characterDifference) > FULLTURN_THRESHOLD)
        {
            ownner.stateMachine.ChangeState("TurnState");
        }

        SingleMotionState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        SingleMotionState::Enter(lastState);
        attackRange = Random(0.5, 6.0);
        ownner.AddFlag(FLAGS_REDIRECTED);
    }

    void Exit(State@ nextState)
    {
        SingleMotionState::Exit(nextState);
        ownner.RemoveFlag(FLAGS_REDIRECTED);
    }
};

class ThugCounterState : MultiMotionState
{
    ThugCounterState(Character@ c)
    {
        super(c);
        SetName("CounterState");
        // motions.Push(gMotionMgr.FindMotion("TG_BM_Counter/Counter_Arm_Front_01"));
    }

    void Update(float dt)
    {
        MultiMotionState::Update(dt);
    }
};


class ThugAlignState : CharacterAlignState
{
    ThugAlignState(Character@ c)
    {
        super(c);
    }
};

class ThugAttackState : CharacterState
{
    AttackMotion@               currentAttack;
    Array<AttackMotion@>        attacks;
    int                         state;

    ThugAttackState(Character@ c)
    {
        super(c);
        SetName("AttackState");
        AddAttackMotion("Attack_Punch", 23, 16);
        AddAttackMotion("Attack_Punch_01", 23, 16);
        AddAttackMotion("Attack_Punch_02", 23, 16);
        AddAttackMotion("Attack_Kick", 24, 16);
        AddAttackMotion("Attack_Kick_01", 24, 16);
        AddAttackMotion("Attack_Kick_02", 24, 16);
    }

    void AddAttackMotion(const String&in name, int impactFrame, int counterStartFrame)
    {
        attacks.Push(AttackMotion(MOVEMENT_GROUP_THUG + name, impactFrame, counterStartFrame));
    }

    void Update(float dt)
    {
        if (currentAttack is null)
            return;

        Motion@ motion = currentAttack.motion;
        float targetDistance = ownner.GetTargetDistance();
        bool standBy = targetDistance < COLLISION_SAFE_DIST;
        Vector3 oldPosition = ownner.sceneNode.worldPosition;
        float t = ownner.animCtrl.GetTime(motion.animationName);
        if (state == 0)
        {
            if (t >= currentAttack.slowMotionTime.x) {
                state = 1;
                ownner.animCtrl.SetSpeed(motion.animationName, 0.25f);
            }
        }
        else if (state == 1)
        {
            if (t >= currentAttack.slowMotionTime.y) {
                state = 2;
                ownner.animCtrl.SetSpeed(motion.animationName, 1.0f);
                ownner.RemoveFlag(FLAGS_REDIRECTED);
            }
        }

        // TODO ....
        bool finished = motion.Move(dt, ownner.sceneNode, ownner.animCtrl);
        if (standBy) {
            ownner.sceneNode.worldPosition = oldPosition;
        }

        if (finished) {
            ownner.CommonStateFinishedOnGroud();
        }

        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        float targetDistance = ownner.GetTargetDistance() - COLLISION_SAFE_DIST;
        float punchDist = attacks[0].motion.endDistance;
        Print("targetDistance=" + targetDistance + " punchDist=" + punchDist);
        int index = RandomInt(3);
        if (targetDistance > punchDist + 0.25f)
            index += 3; // a kick attack

        @currentAttack = attacks[index];
        state = 0;
        Motion@ motion = currentAttack.motion;
        motion.Start(ownner.sceneNode, ownner.animCtrl);
        ownner.AddFlag(FLAGS_REDIRECTED);

        CharacterState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        @currentAttack = null;
        CharacterState::Exit(nextState);
        ownner.RemoveFlag(FLAGS_REDIRECTED);
    }
};

class ThugHitState : MultiMotionState
{
    ThugHitState(Character@ c)
    {
        super(c);
        SetName("HitState");
        String preFix = "TG_HitReaction/";
        AddMotion(preFix + "Generic_Hit_Reaction");
        AddMotion(preFix + "HitReaction_Back_NoTurn");
        AddMotion(preFix + "HitReaction_Left");
        AddMotion(preFix + "HitReaction_Right");
        AddMotion(preFix + "Push_Reaction");
        AddMotion(preFix + "Push_Reaction_From_Back");
    }

    void Update(float dt)
    {
        MultiMotionState::Update(dt);
    }
};

class ThugTurnState : MultiMotionState
{
    float turnSpeed;

    ThugTurnState(Character@ c)
    {
        super(c);
        SetName("TurnState");
        AddMotion(MOVEMENT_GROUP_THUG + "135_Turn_Right");
        AddMotion(MOVEMENT_GROUP_THUG + "135_Turn_Left");
    }

    void Enter(State@ lastState)
    {
        float diff = ownner.ComputeAngleDiff();
        int index = 0;
        if (diff < 0)
            index = 1;
        ownner.sceneNode.vars[ANIMATION_INDEX] = index;
        turnSpeed = diff / motions[selectIndex].endTime;
        Print("ThugTurnState diff=" + diff + " turnSpeed=" + turnSpeed + " time=" + motions[selectIndex].endTime);
        ownner.AddFlag(FLAGS_REDIRECTED);
        MultiMotionState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        MultiMotionState::Exit(nextState);
        ownner.RemoveFlag(FLAGS_REDIRECTED);
    }

    void Update(float dt)
    {
        Motion@ motion = motions[selectIndex];
        float t = ownner.animCtrl.GetTime(motion.animationName);
        if (t >= motion.endTime)
        {
            ownner.CommonStateFinishedOnGroud();
        }
        ownner.sceneNode.Yaw(turnSpeed * dt);
        CharacterState::Update(dt);
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
        MultiMotionState::Enter(lastState);
    }

    void Update(float dt)
    {
        MultiMotionState::Update(dt);
    }

    int PickIndex()
    {
        return RandomInt(2);
    }
};

class Thug : Enemy
{
    void Start()
    {
        Enemy::Start();
        stateMachine.AddState(ThugStandState(this));
        stateMachine.AddState(ThugCounterState(this));
        stateMachine.AddState(ThugAlignState(this));
        stateMachine.AddState(ThugHitState(this));
        stateMachine.AddState(ThugStepMoveState(this));
        stateMachine.AddState(ThugTurnState(this));
        stateMachine.AddState(ThugRunState(this));
        stateMachine.AddState(ThugRedirectState(this));
        stateMachine.AddState(ThugAttackState(this));
        stateMachine.ChangeState("StandState");
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        Character::DebugDraw(debug);
        float targetAngle = GetTargetAngle();
        float baseLen = 2.0f;
        DebugDrawDirection(debug, sceneNode, targetAngle, Color(1, 1, 0), baseLen);
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

    bool CanBeAttacked()
    {
        return true;
    }

    bool CanBeCountered()
    {
        return true;
    }
};

