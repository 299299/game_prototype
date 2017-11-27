
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
            if (!player_walk)
            {
                // ownner.ChangeState("RunState");
                int index = ownner.RadialSelectAnimation(4);
                ownner.GetNode().vars[ANIMATION_INDEX] = 0;

                if (index != 2)
                    ownner.ChangeState("RunState");
                else
                    ownner.ChangeState("StandToRunState");
            }
            else
            {
                int index = ownner.RadialSelectAnimation(4);
                ownner.GetNode().vars[ANIMATION_INDEX] = index -1;

                Print("Stand->Move|Turn index=" + index + " hold-frames=" + gInput.GetLeftAxisHoldingFrames() + " hold-time=" + gInput.GetLeftAxisHoldingTime());

                if (index == 0)
                    ownner.ChangeState("WalkState");
                else
                    ownner.ChangeState("StandToWalkState");
            }

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

class PlayerTurnState : MultiMotionState
{
    float       turnSpeed;
    float       targetRotation;

    PlayerTurnState(Character@ c)
    {
        super(c);
        SetName("TurnState");
        flags = FLAGS_ATTACK;
        animSpeed = 1.5f;
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
        alignTime /= animSpeed;
        turnSpeed = diff / alignTime;
        combatReady = true;
        LogPrint(this.name + " motionTargetAngle=" + motionTargetAngle + " targetRotation=" + targetRotation + " diff=" + diff + " turnSpeed=" + turnSpeed + " start-Rotation=" + ownner.motion_startRotation);
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
        // if the difference is large, then turn 180 degrees
        if ( (Abs(characterDifference) > FULLTURN_THRESHOLD) && gInput.IsLeftStickStationary() )
        {
            LogPrint(this.name + " turn 180!!");
            OnTurn180();
            return;
        }

        if (gInput.IsLeftStickStationary())
        {
            Node@ _node = ownner.GetNode();
            _node.Yaw(characterDifference * turnSpeed * dt);
            //if (Abs(characterDifference * turnSpeed * dt) > 0)
            //    Print("Yaw=" + (characterDifference * turnSpeed * dt));
        }


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

class PlayerStandToRunState : PlayerTurnState
{
    PlayerStandToRunState(Character@ c)
    {
        super(c);
        SetName("StandToRunState");
        flags = FLAGS_ATTACK | FLAGS_MOVING;
    }
};

class PlayerRunState : PlayerMoveForwardState
{
    PlayerRunState(Character@ c)
    {
        super(c);
        SetName("RunState");
        turnSpeed = 15.0f;
    }

    void Enter(State@ lastState)
    {
        if (lastState !is null)
        {
            if (lastState.name == "StandToRunState" || lastState.name == "RunTurn180State")
                blendTime = 0.1f;
            else
                blendTime = 0.2f;
        }

        SingleMotionState::Enter(lastState);
        ownner.SetTarget(null);
        combatReady = true;
    }

    void OnStop()
    {
        ownner.ChangeState("StandState");
    }

    void OnTurn180()
    {
        ownner.GetNode().vars[ANIMATION_INDEX] = 0;
        ownner.ChangeState("RunTurn180State");
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
        // Print("node.rotation=" + ownner.GetNode().worldRotation.eulerAngles.y);
        PlayerMoveForwardState::Update(dt);
    }
};

class PlayerRunTurn180State : PlayerTurnState
{
    PlayerRunTurn180State(Character@ c)
    {
        super(c);
        SetName("RunTurn180State");
    }
}
