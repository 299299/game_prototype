
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
        ownner.SetVelocity(Vector3(0,0,0));
        MultiAnimationState::Enter(lastState);
    }

    void Update(float dt)
    {
        if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
        {
            int index = ownner.RadialSelectAnimation(4);
            ownner.GetNode().vars[ANIMATION_INDEX] = index -1;

            Print("Stand->Move|Turn index=" + index + " hold-frames=" + gInput.GetLeftAxisHoldingFrames() + " hold-time=" + gInput.GetLeftAxisHoldingTime());

            if (index == 0)
                ownner.ChangeState(gInput.IsRunHolding() ? "RunState" : "WalkState");
            else
                ownner.ChangeState(gInput.IsRunHolding() ? "StandToRunState" : "StandToWalkState");
            //ownner.ChangeState("TurnState");

            return;
        }

        if (ownner.CheckFalling())
            return;

        if (ownner.CheckDocking())
            return;

        if (timeInState > 0.25f && gInput.IsCrouchDown())
            ownner.ChangeState("CrouchState");

        MultiAnimationState::Update(dt);
    }

    int PickIndex()
    {
        return RandomInt(animations.length);
    }
};

class PlayerMoveForwardState : SingleMotionState
{
    float turnSpeed = 5.0f;
    float dockDist = 3.0f;

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
            Print(this.name + " turn 180!!");
            OnTurn180();
            return;
        }

        if (gInput.IsLeftStickInDeadZone() && gInput.HasLeftStickBeenStationary(0.1f))
        {
            OnStop();
            return;
        }

        if (ownner.CheckFalling())
            return;
        if (ownner.CheckDocking(dockDist))
            return;

        SingleMotionState::Update(dt);
    }
};

class PlayerWalkState : PlayerMoveForwardState
{
    int runHoldingFrames = 0;

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
        if (gInput.IsCrouchDown())
        {
            ownner.ChangeState("CrouchMoveState");
            return;
        }

        if (gInput.IsRunHolding())
            runHoldingFrames ++;
        else
            runHoldingFrames = 0;

        if (runHoldingFrames > 4)
        {
            ownner.ChangeState("RunState");
            return;
        }

        PlayerMoveForwardState::Update(dt);
    }
};

class PlayerRunState : PlayerMoveForwardState
{
    int walkHoldingFrames = 0;
    int maxWalkHoldFrames = 4;

    PlayerRunState(Character@ c)
    {
        super(c);
        SetName("RunState");
        turnSpeed = 7.5f;
        dockDist = 6.0f;
        flags |= FLAGS_RUN;
    }

    void OnStop()
    {
        ownner.ChangeState("RunToStandState");
    }

    void OnTurn180()
    {
        ownner.ChangeState("RunTurn180State");
    }

    void Update(float dt)
    {
        if (!gInput.IsRunHolding())
            walkHoldingFrames ++;
        else
            walkHoldingFrames = 0;

        if (walkHoldingFrames > maxWalkHoldFrames)
        {
            ownner.ChangeState("WalkState");
            return;
        }

        PlayerMoveForwardState::Update(dt);
    }
};