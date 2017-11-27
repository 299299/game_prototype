
class PlayerStandState : MultiAnimationState
{
    PlayerStandState(Character@ c)
    {
        super(c);
        SetName("StandState");
        flags = FLAGS_ATTACK;
        looped = true;
    }

    void Enter(State@ lastState)
    {
        ownner.SetTarget(null);
        MultiAnimationState::Enter(lastState);
    }

    void Update(float dt)
    {
        if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
        {
            // ownner.ChangeState("RunState");

            int index = ownner.RadialSelectAnimation(4);
            ownner.GetNode().vars[ANIMATION_INDEX] = index -1;

            Print("Stand->Move|Turn index=" + index + " hold-frames=" + gInput.GetLeftAxisHoldingFrames() + " hold-time=" + gInput.GetLeftAxisHoldingTime());

            if (index == 0)
                ownner.ChangeState("WalkState");
            else
                ownner.ChangeState("StandToWalkState");

            return;
        }

        if (ownner.ActionCheck())
            return;

        MultiAnimationState::Update(dt);
    }

    int PickIndex()
    {
        return RandomInt(animations.length);
    }
};

class PlayerEvadeState : MultiMotionState
{
    PlayerEvadeState(Character@ c)
    {
        super(c);
        SetName("EvadeState");
    }

    void Enter(State@ lastState)
    {
        ownner.GetNode().vars[ANIMATION_INDEX] = ownner.RadialSelectAnimation(4);
        MultiMotionState::Enter(lastState);
    }
};

class PlayerRunState : SingleMotionState
{
    float turnSpeed = 15.0f;

    PlayerRunState(Character@ c)
    {
        super(c);
        SetName("RunState");
        flags = FLAGS_ATTACK | FLAGS_MOVING;
    }

    void Enter(State@ lastState)
    {
        SingleMotionState::Enter(lastState);
        ownner.SetTarget(null);
        combatReady = true;
    }

    void OnStop()
    {
        ownner.ChangeState("StandState");
    }

    void Update(float dt)
    {
        float characterDifference = ownner.ComputeAngleDiff();
        Node@ _node = ownner.GetNode();
        _node.Yaw(characterDifference * turnSpeed * dt);

        if (gInput.IsLeftStickInDeadZone() && gInput.HasLeftStickBeenStationary(0.1f))
        {
            OnStop();
            return;
        }

        if (ownner.ActionCheck())
            return;

        SingleMotionState::Update(dt);
    }
};

class PlayerTurnState : MultiMotionState
{
    float       turnSpeed;
    float       targetRotation;

    PlayerTurnState(Character@ c)
    {
        super(c);
        SetName("TurnState");
        flags = FLAGS_ATTACK;
    }

    void Update(float dt)
    {
        ownner.motion_deltaRotation += turnSpeed * dt;
        MultiMotionState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        ownner.SetTarget(null);
        CaculateTargetRotation();
        MultiMotionState::Enter(lastState);
        Motion@ motion = motions[selectIndex];
        float alignTime = motion.endTime;
        float motionTargetAngle = motion.GetFutureRotation(ownner, alignTime);
        float diff = AngleDiff(targetRotation - motionTargetAngle);
        turnSpeed = diff / alignTime;
        combatReady = true;
        LogPrint(this.name + " motionTargetAngle=" + String(motionTargetAngle) + " targetRotation=" + targetRotation + " diff=" + diff + " turnSpeed=" + turnSpeed);
    }

    void OnMotionFinished()
    {
        ownner.GetNode().worldRotation = Quaternion(0, targetRotation, 0);
        MultiMotionState::OnMotionFinished();
    }

    void CaculateTargetRotation()
    {
        targetRotation = ownner.GetTargetAngle();
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        DebugDrawDirection(debug, ownner.GetNode().worldPosition, targetRotation, YELLOW, 2.0f);
        MultiMotionState::DebugDraw(debug);
    }
};

class PlayerStandToWalkState : PlayerTurnState
{
    PlayerStandToWalkState(Character@ c)
    {
        super(c);
        SetName("StandToWalkState");
        flags = FLAGS_ATTACK | FLAGS_MOVING;
    }
};

class PlayerMoveForwardState : SingleMotionState
{
    float turnSpeed = 5.0f;

    PlayerMoveForwardState(Character@ c)
    {
        super(c);
        flags = FLAGS_ATTACK | FLAGS_MOVING;
    }

    void Enter(State@ lastState)
    {
        SingleMotionState::Enter(lastState);
        ownner.SetTarget(null);
        combatReady = true;
    }

    void OnStop()
    {
    }

    void OnTurn180()
    {
    }

    void Update(float dt)
    {
        float characterDifference = ownner.ComputeAngleDiff();
        Node@ _node = ownner.GetNode();
        _node.Yaw(characterDifference * turnSpeed * dt);
        // if the difference is large, then turn 180 degrees
        if ( (Abs(characterDifference) > FULLTURN_THRESHOLD) && gInput.IsLeftStickStationary() )
        {
            LogPrint(this.name + " turn 180!!");
            OnTurn180();
            return;
        }

        if (gInput.IsLeftStickInDeadZone() && gInput.HasLeftStickBeenStationary(0.1f))
        {
            OnStop();
            return;
        }

        SingleMotionState::Update(dt);
    }
};

class PlayerWalkState : PlayerMoveForwardState
{
    PlayerWalkState(Character@ c)
    {
        super(c);
        SetName("WalkState");
        turnSpeed = 5.0f;
    }

    void OnStop()
    {
        ownner.ChangeState("StandState");
    }

    void OnTurn180()
    {
        ownner.GetNode().vars[ANIMATION_INDEX] = 1;
        ownner.ChangeState("StandToWalkState");
    }

    void Update(float dt)
    {
        PlayerMoveForwardState::Update(dt);
    }
};
