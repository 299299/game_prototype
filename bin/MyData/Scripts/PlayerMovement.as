
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
            ownner.ChangeState("RunState");
            return;
        }

        if (ownner.CheckFalling())
            return;

        if (ownner.ActionCheck(true, true, true, true))
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

class PlayerMoveForwardState : SingleMotionState
{
    float turnSpeed = 50.0f;

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

    void Update(float dt)
    {
        float characterDifference = ownner.ComputeAngleDiff();
        Node@ _node = ownner.GetNode();
        _node.Yaw(characterDifference * turnSpeed * dt);

        if (gInput.IsLeftStickInDeadZone() && gInput.HasLeftStickBeenStationary(0.5f))
        {
            OnStop();
            return;
        }

        if (ownner.CheckFalling())
            return;
        if (ownner.ActionCheck(true, true, true, true))
            return;

        SingleMotionState::Update(dt);
    }
};

class PlayerRunState : PlayerMoveForwardState
{
    PlayerRunState(Character@ c)
    {
        super(c);
        SetName("RunState");
        turnSpeed = 7.5f;
    }

    void OnStop()
    {
        ownner.ChangeState("StandState");
    }
};

class PlayerFallState : SingleAnimationState
{
    PlayerFallState(Character@ c)
    {
        super(c);
        SetName("FallState");
        flags = FLAGS_ATTACK;
    }

    void Update(float dt)
    {
        Player@ p = cast<Player@>(ownner);
        if (p.sensor.grounded)
        {
            ownner.ChangeState("LandState");
            return;
        }
        SingleAnimationState::Update(dt);
    }

    void OnMotionFinished()
    {
    }
};

class PlayerLandState : SingleAnimationState
{
    PlayerLandState(Character@ c)
    {
        super(c);
        SetName("LandState");
        flags = FLAGS_ATTACK;
    }

    void Enter(State@ lastState)
    {
        ownner.SetVelocity(Vector3(0, 0, 0));
        SingleAnimationState::Enter(lastState);
    }
};
