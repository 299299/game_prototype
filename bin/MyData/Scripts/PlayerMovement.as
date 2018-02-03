
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
        ownner.SetVelocity(Vector3::ZERO);
        MultiAnimationState::Enter(lastState);
    }

    void Update(float dt)
    {
        if (!gInput.IsLeftStickInDeadZone() && gInput.HasLeftStickBeenStationary(0.05f))
        {
            if (!player_walk)
            {
                if (locomotion_turn)
                {
                    int index = ownner.RadialSelectAnimation(4);
                    ownner.GetNode().vars[ANIMATION_INDEX] = 0;

                    if (index != 2)
                        ownner.ChangeState("RunState");
                    else
                        ownner.ChangeState("StandToRunState");
                }
                else
                    ownner.ChangeState("RunState");
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
        animSpeed = 2.0f;
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
        if (locomotion_turn && (Abs(characterDifference) > FULLTURN_THRESHOLD) && gInput.IsLeftStickStationary() )
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
        turnSpeed = 7.5f;
        animSpeed = 1.25f;
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

class PlayerDockAlignState : MultiMotionState
{
    int             motionFlagAfterAlign = 0;
    int             motionFlagBeforeAlign = kMotion_ALL;

    float           turnSpeed;

    Vector3         motionPositon;
    Vector3         targetPosition;

    float           motionRotation;
    float           targetRotation;

    float           dockInTargetBound = 0.25f;
    bool            debug = false;

    PlayerDockAlignState(Character@ c)
    {
        super(c);
    }

    void Update(float dt)
    {
        ownner.motion_deltaRotation += turnSpeed*dt;
        MultiMotionState::Update(dt);
    }

    void OnMotionAlignTimeOut()
    {
        turnSpeed = 0;
        ownner.motion_velocity = Vector3(0, 0, 0);

        Motion@ m = motions[selectIndex];
        if (motionFlagAfterAlign != 0 && !m.dockAlignBoneName.empty)
        {
            motionRotation = m.GetFutureRotation(ownner, m.endTime);
            motionPositon = m.GetFuturePosition(ownner, m.endTime);

            targetRotation = PickDockOutRotation();
            targetPosition = PickDockOutTarget();

            float t = m.endTime - m.dockAlignTime;
            Vector3 diff = (targetPosition - motionPositon) / t;
            Vector3 v(0, 0, 0);
            if (motionFlagAfterAlign & kMotion_X != 0)
                v.x = diff.x;
            if (motionFlagAfterAlign & kMotion_Y != 0)
                v.y = diff.y;
            if (motionFlagAfterAlign & kMotion_Z != 0)
                v.z = diff.z;
            ownner.motion_velocity = v;

            if (motionFlagAfterAlign & kMotion_R != 0)
                turnSpeed = AngleDiff(targetRotation - motionRotation) / t;

            Print(this.name + " animation:" + m.name + " OnMotionAlignTimeOut vel=" + v.ToString() + " turnSpeed=" + turnSpeed);
        }

        if (debug)
            ownner.SetSceneTimeScale(0.0);
    }

    Vector3 PickDockOutTarget()
    {
        return Vector3();
        //return ownner.dockLine.Project(ownner.GetNode().worldPosition);
    }

    Vector3 PickDockInTarget()
    {
        /*Line@ l = ownner.dockLine;
        Motion@ m = motions[selectIndex];
        float t = m.GetDockAlignTime();
        Vector3 v = m.GetDockAlignPositionAtTime(ownner, ownner.GetCharacterAngle(), t);
        v = l.Project(v);
        v = l.FixProjectPosition(v, dockInTargetBound);
        if (dockInCheckThinWall && l.HasFlag(LINE_THIN_WALL))
        {
            Vector3 dir = Quaternion(0, targetRotation, 0) * Vector3(0, 0, -1);
            float dist = Min(l.size.x, l.size.z) / 2;
            v += dir.Normalized() * dist;
        }
        return v;*/
        return Vector3();
    }

    float PickDockInRotation()
    {
        /*Vector3 v = ownner.GetNode().worldPosition;
        Vector3 proj = ownner.dockLine.Project(v);
        Vector3 dir = proj - v;
        float r = Atan2(dir.x, dir.z);
        if (!ownner.dockLine.IsAngleValid(r))
            r = AngleDiff(r + 180);
        return r;*/
        return 0;
    }

    float PickDockOutRotation()
    {
        return PickDockInRotation();
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        debug.AddCross(targetPosition, 0.5f, BLUE, false);
        debug.AddCross(motionPositon, 0.5f, RED, false);
        Motion@ m = motions[selectIndex];
        if (m !is null)
        {
            Vector3 v = m.dockAlignBoneName.empty ? ownner.GetNode().worldPosition : ownner.GetNode().GetChild(m.dockAlignBoneName, true).worldPosition;
            debug.AddLine(v, targetPosition, Color(0.25, 0.75, 0.75), false);
        }

        DebugDrawDirection(debug, targetPosition, targetRotation, BLUE, 2.0f);
        DebugDrawDirection(debug, targetPosition, motionRotation, RED, 2.0f);

        MultiMotionState::DebugDraw(debug);
    }

    void Enter(State@ lastState)
    {
        if (debug)
            ownner.SetSceneTimeScale(0);

        turnSpeed = 0;

        MultiMotionState::Enter(lastState);
        Motion@ m = motions[selectIndex];

        float t = m.GetDockAlignTime();
        motionRotation = ownner.GetCharacterAngle(); //m.GetFutureRotation(ownner, t);
        targetRotation = (motionFlagBeforeAlign & kMotion_R != 0) ? PickDockInRotation() : motionRotation;

        turnSpeed = AngleDiff(targetRotation - motionRotation) / t;
        motionPositon = m.GetDockAlignPositionAtTime(ownner, targetRotation, t);
        targetPosition = PickDockInTarget();

        Vector3 vel = (targetPosition - motionPositon) / t;
        Vector3 filterV = Vector3(0, 0, 0);

        if (motionFlagBeforeAlign & kMotion_X != 0)
            filterV.x = vel.x;
        if (motionFlagBeforeAlign & kMotion_Y != 0)
            filterV.y = vel.y;
        if (motionFlagBeforeAlign & kMotion_Z != 0)
            filterV.z = vel.z;

        ownner.motion_velocity = filterV;
        Print(this.name + " animation:" + m.name + " vel=" + ownner.motion_velocity.ToString() + " turnSpeed=" + turnSpeed);
    }

    void Exit(State@ nextState)
    {
        if (debug)
            ownner.SetSceneTimeScale(0);
        MultiMotionState::Exit(nextState);
    }
};
