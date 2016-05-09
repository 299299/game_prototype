// ==============================================
//
//    Player Pawn and Controller Class
//
// ==============================================


class PlayerStandState : MultiAnimationState
{
    PlayerStandState(Character@ c)
    {
        super(c);
        SetName("StandState");
        looped = true;
    }

    void Enter(State@ lastState)
    {
        ownner.SetVelocity(Vector3(0,0,0));
        MultiAnimationState::Enter(lastState);
    }

    void Update(float dt)
    {
        if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
        {
            ownner.ChangeState(gInput.IsRunHolding() ? "RunState" : "WalkState");
            return;
        }

        if (ownner.CheckFalling())
            return;

        MultiAnimationState::Update(dt);
    }

    int PickIndex()
    {
        return RandomInt(animations.length);
    }
};

class PlayerMoveForwardState : SingleAnimationState
{
    Vector3 velocity = Vector3(0, 0, 3.0f);
    float turnSpeed = 5.0f;

    PlayerMoveForwardState(Character@ c)
    {
        super(c);
        flags = FLAGS_MOVING;
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

        if (ownner.CheckFalling())
            return;

        ownner.SetVelocity(ownner.GetNode().worldRotation * velocity);

        SingleAnimationState::Update(dt);
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

    void Update(float dt)
    {
        if (gInput.IsRunHolding())
        {
            ownner.ChangeState("RunState");
            return;
        }

        PlayerMoveForwardState::Update(dt);
    }
};

class PlayerRunState : PlayerMoveForwardState
{
    PlayerRunState(Character@ c)
    {
        super(c);
        SetName("RunState");
        turnSpeed = 7.5f;
        flags |= FLAGS_RUN;
    }

    void Update(float dt)
    {
        if (!gInput.IsRunHolding())
        {
            ownner.ChangeState("WalkState");
            return;
        }

        PlayerMoveForwardState::Update(dt);
    }
};

class PlayerFallState : SingleAnimationState
{
    PlayerFallState(Character@ c)
    {
        super(c);
        SetName("FallState");
    }

    void Update(float dt)
    {
        Player@ p = cast<Player@>(ownner);
        if (p.sensor.grounded)
        {
            ownner.ChangeState("StandState");
            return;
        }
        SingleAnimationState::Update(dt);
    }

    void OnMotionFinished()
    {
    }
};

class Player : Character
{
    bool                              applyGravity = true;

    void ObjectStart()
    {
        Character::ObjectStart();

        side = 1;
        @sensor = PhysicsSensor(sceneNode);

        AddStates();
        ChangeState("StandState");
    }

    void AddStates()
    {
    }


    void CommonStateFinishedOnGroud()
    {
        if (CheckFalling())
            return;

        if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
            ChangeState(gInput.IsRunHolding() ? "RunState" : "WalkState");
        else
            ChangeState("StandState");
    }

    float GetTargetAngle()
    {
        return gInput.GetLeftAxisAngle() + gCameraMgr.GetCameraAngle();
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        Character::DebugDraw(debug);
        // debug.AddCircle(sceneNode.worldPosition, Vector3(0, 1, 0), COLLISION_RADIUS, YELLOW, 32, false);
        // sensor.DebugDraw(debug);
        debug.AddNode(sceneNode.GetChild(TranslateBoneName, true), 0.5f, false);
    }

    void Update(float dt)
    {
        sensor.Update(dt);
        Character::Update(dt);
    }

    void SetVelocity(const Vector3&in vel)
    {
        if (!sensor.grounded && applyGravity)
            Character::SetVelocity(vel + Vector3(0, -9.8f, 0));
        else
            Character::SetVelocity(vel);
    }

    bool CheckFalling()
    {
        if (!sensor.grounded && sensor.inAirHeight > 1.5f && sensor.inAirFrames > 2 && applyGravity)
        {
            ChangeState("FallState");
            return true;
        }
        return false;
    }
};
