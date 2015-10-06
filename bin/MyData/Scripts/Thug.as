
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
    }

    void Update(float dt)
    {
        if (timeInState > 4.0f) {
            float diff = ownner.ComputeAngleDiff();
            diff = Abs(diff);
            if (diff > 15)
                ownner.stateMachine.ChangeState("TurnState");
        }

        RandomAnimationState::Update(dt);
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
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Right");
        // long step
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Forward_Long");
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Right_Long");
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Back_Long");
        AddMotion(MOVEMENT_GROUP_THUG + "Step_Right_Long");
    }

    void Update(float dt)
    {
        MultiMotionState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        MultiMotionState::Enter(lastState);
    }

    int PickIndex()
    {
        return ownner.sceneNode.vars["AnimationIndex"].GetInt();
    }
};

class ThugRunState : SingleMotionState
{
    ThugRunState(Character@ c)
    {
        super(c);
        SetName("RunState");
        SetMotion(MOVEMENT_GROUP_THUG + "Run_Forward_Combat");
    }

    void Update(float dt)
    {
        SingleMotionState::Update(dt);
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

    int PickIndex()
    {
        return ownner.sceneNode.vars["CounterIndex"].GetInt();
    }
};


class ThugAlignState : CharacterAlignState
{
    ThugAlignState(Character@ c)
    {
        super(c);
    }
};

class ThugAttackState : MultiMotionState
{
    ThugAttackState(Character@ c)
    {
        super(c);
        SetName("AttackState");
        String preFix = "TG_Combat/";
        AddMotion(preFix + "Attack_Kick");
        AddMotion(preFix + "Attack_Kick_01");
        AddMotion(preFix + "Attack_Kick_02");
        AddMotion(preFix + "Attack_Punch");
        AddMotion(preFix + "Attack_Punch_01");
        AddMotion(preFix + "Attack_Punch_02");
    }

    void Update(float dt)
    {
        MultiMotionState::Update(dt);
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
        ownner.sceneNode.vars["AnimationIndex"] = index;
        MultiMotionState::Enter(lastState);
        turnSpeed = diff / motions[selectIndex].endTime;
        Print("ThugTurnState diff=" + diff + " turnSpeed=" + turnSpeed + " time=" + motions[selectIndex].endTime);
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
        stateMachine.ChangeState("StandState");
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        Character::DebugDraw(debug);
        float targetAngle = GetTargetAngle();
        float baseLen = 2.0f;
        DebugDrawDirection(debug, sceneNode, targetAngle, Color(1, 1, 0), baseLen);
    }
};

