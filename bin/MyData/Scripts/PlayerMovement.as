
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
        float blendSpeed = 0.2f;
        if (lastState.name == "RunTurn180State")
            blendSpeed = 0.0f;
        motion.Start(ownner, 0.0f, 0.2f, animSpeed);
        ownner.SetTarget(null);
        combatReady = true;
        CharacterState::Enter(lastState);
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
    Vector3   targetPos;
    float     targetAngle;
    float     yawPerSec;
    int       state;
    float     adjustTime = 0.78f;

    PlayerRunTurn180State(Character@ c)
    {
        super(c);
        SetName("RunTurn180State");
        flags = FLAGS_ATTACK | FLAGS_MOVING;
    }

    void Enter(State@ lastState)
    {
        SingleMotionState::Enter(lastState);
        targetAngle = AngleDiff(ownner.GetTargetAngle());
        Vector4 tFinnal = motion.GetKey(motion.endTime);
        Vector4 t1 = motion.GetKey(0.78f);
        float dist = Abs(t1.z - tFinnal.z);
        targetPos = ownner.GetNode().worldPosition + Quaternion(0, targetAngle, 0) * Vector3(0, 0, dist);
    }

    void Exit(State@ nextState)
    {
        SingleMotionState::Exit(nextState);
    }

    void Update(float dt)
    {
        if (state == 0)
        {
            if (timeInState >= 0.75f)
            {
                state = 1;
                ownner.motion_rotateEnabled = false;
                ownner.motion_translateEnabled = false;

                float timeLeft = motion.endTime - timeInState;
                Vector3 diff = targetPos - ownner.GetNode().worldPosition;
                diff.y = 0;
                ownner.SetVelocity(diff / timeLeft);

                float a = ownner.GetCharacterAngle();
                float a_diff = AngleDiff(targetAngle - a);
                yawPerSec = a_diff / timeLeft;
            }
        }
        else if (state == 1)
        {
            ownner.GetNode().worldRotation = Quaternion(0, targetAngle, 0);
        }

        SingleMotionState::Update(dt);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        SingleMotionState::DebugDraw(debug);
        DebugDrawDirection(debug, ownner.GetNode(), targetAngle, Color(0.75f, 0.5f, 0.45f), 2.0f);
        debug.AddCross(targetPos, 0.5f, YELLOW, false);
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
            ownner.SetHeight(CHARACTER_CROUCH_HEIGHT);
    }

    void Exit(State@ nextState)
    {
        SingleMotionState::Exit(nextState);
        if (collision_type == 1)
            ownner.SetHeight(CHARACTER_HEIGHT);
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
        if (collision_type == 1)
            ownner.SetHeight(CHARACTER_CROUCH_HEIGHT);
        SingleAnimationState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        SingleAnimationState::Exit(nextState);
        if (collision_type == 1)
            ownner.SetHeight(CHARACTER_HEIGHT);
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

class PlayerCrouchTurnState : PlayerTurnState
{
    PlayerCrouchTurnState(Character@ c)
    {
        super(c);
        SetName("CrouchTurnState");
    }

    void Enter(State@ lastState)
    {
        PlayerTurnState::Enter(lastState);
        if (collision_type == 1)
            ownner.SetHeight(CHARACTER_CROUCH_HEIGHT);
    }

    void Exit(State@ nextState)
    {
        PlayerTurnState::Exit(nextState);
        if (collision_type == 1)
            ownner.SetHeight(CHARACTER_HEIGHT);
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
        if (collision_type == 1)
            ownner.SetHeight(CHARACTER_CROUCH_HEIGHT);
    }

    void Exit(State@ nextState)
    {
        SingleMotionState::Exit(nextState);
        if (collision_type == 1)
            ownner.SetHeight(CHARACTER_HEIGHT);
    }
};
