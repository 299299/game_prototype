
class PlayerStandState : CharacterState
{
    Array<String>   animations;

    PlayerStandState(Character@ c)
    {
        super(c);
        SetName("StandState");
        flags = FLAGS_ATTACK;
    }

    void Enter(State@ lastState)
    {
        ownner.SetTarget(null);
        ownner.PlayAnimation(animations[RandomInt(animations.length)], LAYER_MOVE, true, 0.2f, 0.0f, animSpeed);
        ownner.SetVelocity(Vector3(0,0,0));

        CharacterState::Enter(lastState);
    }

    void Update(float dt)
    {
        if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
        {
            int index = ownner.RadialSelectAnimation(4);
            ownner.GetNode().vars[ANIMATION_INDEX] = index -1;

            Print("Stand->Move|Turn hold-frames=" + gInput.GetLeftAxisHoldingFrames() + " hold-time=" + gInput.GetLeftAxisHoldingTime());

            if (index == 0)
                ownner.ChangeState(gInput.IsRunHolding() ? "RunState" : "WalkState");
            else
                ownner.ChangeState("TurnState");
        }

        ownner.ActionCheck(true, true, true, true);

        if (gInput.IsCrouchDown())
            ownner.ChangeState("CrouchState");

        CharacterState::Update(dt);
    }
};

class PlayerEvadeState : MultiMotionState
{
    PlayerEvadeState(Character@ c)
    {
        super(c);
        SetName("EvadeState");
    }
};

class PlayerTurnState : MultiMotionState
{
    float turnSpeed;

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
        MultiMotionState::Enter(lastState);
        Motion@ motion = motions[selectIndex];
        Vector4 endKey = motion.GetKey(motion.endTime);
        float motionTargetAngle = ownner.motion_startRotation + endKey.w;
        float targetAngle = ownner.GetTargetAngle();
        float diff = AngleDiff(targetAngle - motionTargetAngle);
        turnSpeed = diff / motion.endTime;
        combatReady = true;
        Print("motionTargetAngle=" + String(motionTargetAngle) + " targetAngle=" + String(targetAngle) + " diff=" + String(diff) + " turnSpeed=" + String(turnSpeed));
    }
};

class PlayerWalkState : SingleMotionState
{
    float turnSpeed = 5.0f;
    int runHoldingFrames = 0;

    PlayerWalkState(Character@ c)
    {
        super(c);
        SetName("WalkState");
        flags = FLAGS_ATTACK | FLAGS_MOVING;
    }

    void Update(float dt)
    {
        float characterDifference = ownner.ComputeAngleDiff();
        Node@ _node = ownner.GetNode();
        _node.Yaw(characterDifference * turnSpeed * dt);
        motion.Move(ownner, dt);
        // if the difference is large, then turn 180 degrees
        if ( (Abs(characterDifference) > FULLTURN_THRESHOLD) && gInput.IsLeftStickStationary() )
        {
            _node.vars[ANIMATION_INDEX] = 1;
            ownner.ChangeState("TurnState");
            return;
        }
        if (gInput.IsLeftStickInDeadZone() && gInput.HasLeftStickBeenStationary(0.1f))
        {
            ownner.ChangeState("StandState");
            return;
        }
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


        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        SingleMotionState::Enter(lastState);
        ownner.SetTarget(null);
        combatReady = true;
    }
};

class PlayerRunState : SingleMotionState
{
    float turnSpeed = 7.5f;
    int walkHoldingFrames = 0;
    int maxWalkHoldFrames = 4;

    PlayerRunState(Character@ c)
    {
        super(c);
        SetName("RunState");
        flags = FLAGS_ATTACK | FLAGS_MOVING;
    }

    void Update(float dt)
    {
        float characterDifference = ownner.ComputeAngleDiff();
        Node@ _node = ownner.GetNode();
        _node.Yaw(characterDifference * turnSpeed * dt);
        motion.Move(ownner, dt);
        // if the difference is large, then turn 180 degrees
        if ( (Abs(characterDifference) > FULLTURN_THRESHOLD) && gInput.IsLeftStickStationary() )
        {
            ownner.ChangeState("RunTurn180State");
            return;
        }
        if (gInput.IsLeftStickInDeadZone() && gInput.HasLeftStickBeenStationary(0.1f))
        {
            ownner.ChangeState("RunToStandState");
            return;
        }
        if (gInput.IsCrouchDown())
        {
            ownner.ChangeState("SlideInState");
            return;
        }

        if (!gInput.IsRunHolding())
            walkHoldingFrames ++;
        else
            walkHoldingFrames = 0;

        if (walkHoldingFrames > maxWalkHoldFrames)
        {
            ownner.ChangeState("WalkState");
            return;
        }

        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        SingleMotionState::Enter(lastState);
        ownner.SetTarget(null);
        combatReady = true;
    }
};

class PlayerRunToStandState : SingleMotionState
{
    PlayerRunToStandState(Character@ c)
    {
        super(c);
        SetName("RunToStandState");
        flags = FLAGS_ATTACK | FLAGS_MOVING;
    }
};

class PlayerRunTurn180State : SingleMotionState
{
    PlayerRunTurn180State(Character@ c)
    {
        super(c);
        SetName("RunTurn180State");
        flags = FLAGS_ATTACK | FLAGS_MOVING;
    }
};


class PlayerSlideInState : SingleMotionState
{
    int state = 0;
    float slideTimer = 1.0f;
    Vector3 idleVelocity = Vector3(0, 0, 10);

    PlayerSlideInState(Character@ c)
    {
        super(c);
        SetName("SlideInState");
        flags = FLAGS_ATTACK | FLAGS_MOVING;
    }

    void OnMotionFinished()
    {
        state = 1;
        timeInState = 0.0f;
    }

    void Update(float dt)
    {
        if (state == 0)
        {
            SingleMotionState::Update(dt);
        }
        else if (state == 1)
        {
            if (timeInState >= slideTimer)
            {
                int index = 0;
                if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary() && gInput.IsRunHolding())
                {
                    index = 1;
                }
                ownner.GetNode().vars[ANIMATION_INDEX] = index;
                ownner.ChangeState("SlideOutState");
                return;
            }
            if (collision_type == 0)
            {
                Vector3 oldPos = ownner.GetNode().worldPosition;
                oldPos += (ownner.GetNode().worldRotation * idleVelocity * dt);
                ownner.MoveTo(oldPos, dt);
            }
            else
                ownner.SetVelocity(ownner.GetNode().worldRotation * idleVelocity);

            CharacterState::Update(dt);
        }
    }

    void Enter(State@ lastState)
    {
        SingleMotionState::Enter(lastState);
        if (collision_type == 1)
        {
            CollisionShape@ shape = ownner.GetNode().GetComponent("CollisionShape");
            if (shape !is null)
            {
                float height = CHARACTER_HEIGHT/2;
                shape.size = Vector3(COLLISION_RADIUS * 2, height, 0);
                shape.SetTransform(Vector3(0.0f, height/2, 0.0f), Quaternion());
            }
        }
    }

    void Exit(State@ nextState)
    {
        SingleMotionState::Exit(nextState);
        if (collision_type == 1)
        {
            CollisionShape@ shape = ownner.GetNode().GetComponent("CollisionShape");
            if (shape !is null)
            {
                float height = CHARACTER_HEIGHT;
                shape.size = Vector3(COLLISION_RADIUS * 2, height, 0);
                shape.SetTransform(Vector3(0.0f, height/2, 0.0f), Quaternion());
            }
        }
    }
};

class PlayerSlideOutState : MultiMotionState
{
    PlayerSlideOutState(Character@ c)
    {
        super(c);
        SetName("SlideOutState");
        flags = FLAGS_ATTACK | FLAGS_MOVING;
    }

    void OnMotionFinished()
    {
        if (selectIndex == 1)
        {
            ownner.ChangeState("RunState");
            return;
        }
        MultiMotionState::OnMotionFinished();
    }
};

class PlayerCrouchState : SingleAnimationState
{
    PlayerCrouchState(Character@ c)
    {
        super(c);
        SetName("CrouchState");
        flags = FLAGS_ATTACK;
        looped = true;
    }

    void Enter(State@ lastState)
    {
        ownner.SetTarget(null);
        ownner.SetVelocity(Vector3(0,0,0));
        SingleAnimationState::Enter(lastState);
    }

    void Update(float dt)
    {
        if (!gInput.IsCrouchDown())
        {
            ownner.ChangeState("StandState");
            return;
        }

        if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
        {
            int index = ownner.RadialSelectAnimation(4);
            ownner.GetNode().vars[ANIMATION_INDEX] = index -1;

            Print("Crouch->Move|Turn hold-frames=" + gInput.GetLeftAxisHoldingFrames() + " hold-time=" + gInput.GetLeftAxisHoldingTime());

            if (index == 0)
                ownner.ChangeState("CrouchMoveState");
            else
                ownner.ChangeState("CrouchTurnState");
        }

        SingleAnimationState::Update(dt);
    }
};


class PlayerCrouchMoveState : SingleMotionState
{
    float turnSpeed = 2.0f;
    PlayerCrouchMoveState(Character@ c)
    {
        super(c);
        SetName("CrouchMoveState");
        flags = FLAGS_ATTACK | FLAGS_MOVING;
    }

    void Update(float dt)
    {
        float characterDifference = ownner.ComputeAngleDiff();
        Node@ _node = ownner.GetNode();
        _node.Yaw(characterDifference * turnSpeed * dt);
        motion.Move(ownner, dt);
        // if the difference is large, then turn 180 degrees
        if ( (Abs(characterDifference) > FULLTURN_THRESHOLD) && gInput.IsLeftStickStationary() )
        {
            _node.vars[ANIMATION_INDEX] = 1;
            ownner.ChangeState("CrouchTurnState");
            return;
        }

        if (gInput.IsLeftStickInDeadZone() && gInput.HasLeftStickBeenStationary(0.1f))
        {
            ownner.ChangeState("CrouchState");
            return;
        }

        if (!gInput.IsCrouchDown())
        {
            ownner.ChangeState("WalkState");
            return;
        }

        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        SingleMotionState::Enter(lastState);
        ownner.SetTarget(null);
        combatReady = true;
    }
};
