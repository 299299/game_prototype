
const String thugMovementGroup = "TG_Combat/";

class ThugStandState : RandomAnimationState
{
    ThugStandState(Character@ c)
    {
        super(c);
        name = "StandState";
        animations.Push(GetAnimationName(thugMovementGroup + "Stand_Idle_Additive_01"));
        animations.Push(GetAnimationName(thugMovementGroup + "Stand_Idle_Additive_02"));
        animations.Push(GetAnimationName(thugMovementGroup + "Stand_Idle_Additive_03"));
        animations.Push(GetAnimationName(thugMovementGroup + "Stand_Idle_Additive_04"));
    }

    void Enter(State@ lastState)
    {
        float blendTime = 0.25f;
        if (lastState !is null)
        {
            if (lastState.name == "AttackState" || lastState.name == "TurnState")
                blendTime = 2.5f;
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
        name = "StepMoveState";
        // short step
        motions.Push(gMotionMgr.FindMotion(thugMovementGroup + "Step_Forward"));
        motions.Push(gMotionMgr.FindMotion(thugMovementGroup + "Step_Right"));
        motions.Push(gMotionMgr.FindMotion(thugMovementGroup + "Step_Back"));
        motions.Push(gMotionMgr.FindMotion(thugMovementGroup + "Step_Right"));
        // long step
        motions.Push(gMotionMgr.FindMotion(thugMovementGroup + "Step_Forward_Long"));
        motions.Push(gMotionMgr.FindMotion(thugMovementGroup + "Step_Right_Long"));
        motions.Push(gMotionMgr.FindMotion(thugMovementGroup + "Step_Back_Long"));
        motions.Push(gMotionMgr.FindMotion(thugMovementGroup + "Step_Right_Long"));
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

class ThugRunState : CharacterState
{
    Motion@ motion;

    ThugRunState(Character@ c)
    {
        super(c);
        name = "RunState";
        @motion = gMotionMgr.FindMotion(thugMovementGroup + "Run_Forward_Combat");
    }

    void Update(float dt)
    {
        motion.Move(dt, ownner.sceneNode, ownner.animCtrl);
        CharacterState::Update(dt);
    }
};

class ThugCounterState : MultiMotionState
{
    ThugCounterState(Character@ c)
    {
        super(c);
        name = "CounterState";
        // motions.Push(gMotionMgr.FindMotion("TG_BM_Counter/Counter_Arm_Front_01"));
    }

    void Update(float dt)
    {
        if (motions[selectIndex].Move(dt, ownner.sceneNode, ownner.animCtrl))
            ownner.stateMachine.ChangeState("StandState");

        CharacterState::Update(dt);
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
        name = "CounterState";
    }

    void Update(float dt)
    {
        if (motions[selectIndex].Move(dt, ownner.sceneNode, ownner.animCtrl))
            ownner.stateMachine.ChangeState("StandState");

        CharacterState::Update(dt);
    }

    int PickIndex()
    {
        return ownner.sceneNode.vars["AttackIndex"].GetInt();
    }
};

class ThugHitState : MultiMotionState
{
    ThugHitState(Character@ c)
    {
        super(c);
        name = "CounterState";
    }

    void Update(float dt)
    {
        if (motions[selectIndex].Move(dt, ownner.sceneNode, ownner.animCtrl))
            ownner.stateMachine.ChangeState("StandState");

        CharacterState::Update(dt);
    }

    int PickIndex()
    {
        return ownner.sceneNode.vars["Hit"].GetInt();
    }
};

class ThugTurnState : MultiMotionState
{
    float turnSpeed;

    ThugTurnState(Character@ c)
    {
        super(c);
        name = "TurnState";
        motions.Push(gMotionMgr.FindMotion(thugMovementGroup + "135_Turn_Right"));
        motions.Push(gMotionMgr.FindMotion(thugMovementGroup + "135_Turn_Left"));
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
        Print("ThugTurnState diff=" + String(diff) + " turnSpeed=" + String(turnSpeed) + " time=" + String(motions[selectIndex].endTime));
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
        stateMachine.ChangeState("StandState");
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        Character::DebugDraw(debug);
        float targetAngle = GetTargetAngle();
        float baseLen = 2.0f;
        DebugDrawDirection(debug, sceneNode, targetAngle, Color(1, 1, 0), baseLen);
    }

    void CommonStateFinishedOnGroud()
    {
        stateMachine.ChangeState("StandState");
    }
};

