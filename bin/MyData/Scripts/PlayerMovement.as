
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

        if (ownner.ActionCheck(true, true, true))
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

class PlayerEvadeState : SingleMotionState
{
    PlayerEvadeState(Character@ c)
    {
        super(c);
        SetName("EvadeState");
    }
};

class PlayerTurnState : MultiMotionState
{
    float       turnSpeed;
    float       targetRotation;
    float       dockDist = -1;

    PlayerTurnState(Character@ c)
    {
        super(c);
        SetName("TurnState");
        flags = FLAGS_ATTACK;
    }

    void Update(float dt)
    {
        if (dockDist > 0 && timeInState > 0.2f)
        {
            if (ownner.CheckDocking(dockDist))
                return;
        }
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
        Print(this.name + " motionTargetAngle=" + String(motionTargetAngle) + " targetRotation=" + targetRotation + " diff=" + diff + " turnSpeed=" + turnSpeed);
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
        dockDist = 3.0f;
    }
};

class PlayerStandToRunState : PlayerTurnState
{
    PlayerStandToRunState(Character@ c)
    {
        super(c);
        SetName("StandToRunState");
        flags = FLAGS_ATTACK | FLAGS_MOVING;
        dockDist = 6.0f;
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
        if (ownner.ActionCheck(true, true, true))
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
    float     targetAngle;
    float     yawPerSec;

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
        float alignTime = motion.endTime;
        float rotation = motion.GetFutureRotation(ownner, alignTime);
        yawPerSec = AngleDiff(targetAngle - rotation) / alignTime;
    }

    void Update(float dt)
    {
        ownner.motion_deltaRotation += yawPerSec * dt;
        SingleMotionState::Update(dt);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        SingleMotionState::DebugDraw(debug);
        DebugDrawDirection(debug, ownner.GetNode().worldPosition, targetAngle, Color(0.75f, 0.5f, 0.45f), 2.0f);
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
        ownner.SetHeight(CHARACTER_CROUCH_HEIGHT);
        SingleAnimationState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        SingleAnimationState::Exit(nextState);
        ownner.SetHeight(CHARACTER_HEIGHT);
    }

    void Update(float dt)
    {
        if (timeInState > 0.25f && !gInput.IsCrouchDown())
        {
            ownner.ChangeState("StandState");
            return;
        }
        if (ownner.CheckFalling())
            return;
        if (ownner.CheckDocking())
            return;

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
        dockDist = 3;
    }

    void Enter(State@ lastState)
    {
        PlayerTurnState::Enter(lastState);
        ownner.SetHeight(CHARACTER_CROUCH_HEIGHT);
    }

    void Exit(State@ nextState)
    {
        PlayerTurnState::Exit(nextState);
        ownner.SetHeight(CHARACTER_HEIGHT);
    }
};

class PlayerCrouchMoveState : PlayerMoveForwardState
{
    PlayerCrouchMoveState(Character@ c)
    {
        super(c);
        SetName("CrouchMoveState");
        turnSpeed = 2.0f;
    }

    void OnTurn180()
    {
        ownner.GetNode().vars[ANIMATION_INDEX] = 1;
        ownner.ChangeState("CrouchTurnState");
    }

    void OnStop()
    {
        ownner.ChangeState("CrouchState");
    }

    void Enter(State@ lastState)
    {
        PlayerMoveForwardState::Enter(lastState);
        ownner.SetHeight(CHARACTER_CROUCH_HEIGHT);
    }

    void Exit(State@ nextState)
    {
        PlayerMoveForwardState::Exit(nextState);
        ownner.SetHeight(CHARACTER_HEIGHT);
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

class PlayerCoverState : SingleAnimationState
{
    int    state;
    float  alignTime = 0.25f;
    float  yawPerSec;
    float  startYaw;
    float  dockDirection;
    Vector3 dockPosition;
    float  yawAdjustSpeed = 15.0f;

    PlayerCoverState(Character@ c)
    {
        super(c);
        SetName("CoverState");
        looped = true;
        blendTime = alignTime;
    }

    void Enter(State@ lastState)
    {
        ownner.SetVelocity(Vector3(0, 0, 0));

        Line@ l = ownner.dockLine;
        Vector3 proj = l.Project(ownner.GetNode().worldPosition);
        dockPosition = proj;

        if (!lastState.name.StartsWith("Cover"))
        {
            alignTime = 0.4f;

            float to_start = (proj - l.ray.origin).lengthSquared;
            float to_end = (proj - l.end).lengthSquared;
            float min_dist_sqr = COLLISION_RADIUS * COLLISION_RADIUS;
            int head = l.GetHead(ownner.GetNode().worldRotation);

            Vector3 dir;
            if (head == 1)
            {
                dir = l.ray.origin - l.end;
                if (to_start < min_dist_sqr)
                    dockPosition = l.ray.origin - dir.Normalized() * COLLISION_RADIUS;
                else if (to_end < min_dist_sqr)
                    dockPosition = l.end + dir.Normalized() * COLLISION_RADIUS;
            }
            else
            {
                dir = l.end - l.ray.origin;
                if (to_start < min_dist_sqr)
                    dockPosition = l.ray.origin + dir.Normalized() * COLLISION_RADIUS;
                else if (to_end < min_dist_sqr)
                   dockPosition = l.end - dir.Normalized() * COLLISION_RADIUS;
            }
            dockDirection = Atan2(dir.x, dir.z);
        }
        else
        {
            alignTime = 0.1f;
            dockDirection = l.GetHeadDirection(ownner.GetNode().worldRotation);
        }

        dockPosition.y = ownner.GetNode().worldPosition.y;
        Vector3 diff = dockPosition - ownner.GetNode().worldPosition;
        ownner.SetVelocity(diff / alignTime);
        startYaw = AngleDiff(ownner.GetNode().worldRotation.eulerAngles.y);
        yawPerSec = AngleDiff(dockDirection - startYaw) / alignTime;
        state = 0;

        SingleAnimationState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        SingleAnimationState::Exit(nextState);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        debug.AddCross(dockPosition, 0.5f, RED, false);
        DebugDrawDirection(debug, dockPosition, dockDirection, YELLOW, 2.0f);
    }

    void Update(float dt)
    {
        if (state == 0)
        {
            if (timeInState >= alignTime)
            {
                state = 1;
                ownner.SetVelocity(Vector3(0, 0, 0));
            }

            startYaw += yawPerSec * dt;
            ownner.GetNode().worldRotation = Quaternion(0, startYaw, 0);
        }
        else if (state == 1)
        {
            if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
            {
                float characterDifference = ownner.ComputeAngleDiff();
                if ( (Abs(characterDifference) > 135) && gInput.IsLeftStickStationary() )
                {
                    ownner.ChangeState("CoverTransitionState");
                    return;
                }
                else
                {
                    float faceDiff = ownner.dockLine.GetProjectFacingDir(ownner.GetNode().worldPosition, ownner.GetTargetAngle());
                    Print("CoverState faceDiff=" + faceDiff);
                    if (faceDiff > 145)
                        ownner.ChangeState("WalkState");
                    else if (faceDiff > 45)
                        ownner.ChangeState("CoverRunState");
                }
            }

            float curAngle = ownner.GetCharacterAngle();
            float diff = AngleDiff(dockDirection - curAngle);
            ownner.GetNode().Yaw(diff * yawAdjustSpeed * dt);
        }
        SingleAnimationState::Update(dt);
    }
};


class PlayerCoverRunState : SingleMotionState
{
    Vector3 dockPosition;

    PlayerCoverRunState(Character@ c)
    {
        super(c);
        SetName("CoverRunState");
        flags = FLAGS_MOVING;
    }

    void Update(float dt)
    {
        Vector3 proj = ownner.dockLine.Project(ownner.GetNode().worldPosition);
        dockPosition = proj;
        dockPosition.y = ownner.GetNode().worldPosition.y;

        if (!ownner.dockLine.IsProjectPositionInLine(proj))
        {
            ownner.CommonStateFinishedOnGroud();
            return;
        }
        if (gInput.IsLeftStickInDeadZone() && gInput.HasLeftStickBeenStationary(0.1f))
        {
            ownner.ChangeState("CoverState");
            return;
        }

        float characterDifference = ownner.ComputeAngleDiff();
        if ( (Abs(characterDifference) > 135) && gInput.IsLeftStickStationary() )
        {
            ownner.ChangeState("CoverTransitionState");
            return;
        }
        else
        {
            float faceDiff = ownner.dockLine.GetProjectFacingDir(ownner.GetNode().worldPosition, ownner.GetTargetAngle());
            if (faceDiff > 145)
                ownner.ChangeState("WalkState");
        }

        SingleMotionState::Update(dt);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        debug.AddCross(dockPosition, 0.5f, RED, false);
    }
};

class PlayerCoverTransitionState : SingleMotionState
{
    float yawPerSec;

    PlayerCoverTransitionState(Character@ c)
    {
        super(c);
        SetName("CoverTransitionState");
    }

    void Update(float dt)
    {
        ownner.motion_deltaRotation += yawPerSec * dt;
        SingleMotionState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        SingleMotionState::Enter(lastState);

        float curAngle = ownner.GetNode().worldRotation.eulerAngles.y;
        float targetAngle = AngleDiff(curAngle + 180);
        float alignTime = motion.endTime;
        float motionAngle = motion.GetFutureRotation(ownner, alignTime);
        yawPerSec = AngleDiff(targetAngle - motionAngle) / alignTime;
    }

    void OnMotionFinished()
    {
        ownner.ChangeState("CoverState");
    }
};

class PlayerDockAlignState : MultiMotionState
{
    Array<Vector3>  targetOffsets;
    int             motionFlagAfterAlign = 0;
    int             motionFlagBeforeAlign = kMotion_ALL;
    float           alignTime = 0.1f;

    float           turnSpeed;

    Vector3         motionPositon;
    Vector3         targetPosition;

    int             dockBlendingMethod;
    float           motionRotation;
    float           targetRotation;
    float           climbBaseHeight;
    float           dockInTargetBound = 0.25f;

    bool            dockInCheckThinWall = true;

    bool            debug = false;

    PlayerDockAlignState(Character@ c)
    {
        super(c);
        physicsType = 0;
    }

    void Update(float dt)
    {
        ownner.motion_deltaRotation += turnSpeed*dt;
        MultiMotionState::Update(dt);
    }

    void OnMotionAlignTimeOut()
    {
        if (dockBlendingMethod > 0)
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
    }

    int PickTargetMotionByHeight(State@ lastState, int numOfStandAnimations = 3)
    {
        if (lastState.nameHash == ALIGN_STATE)
            return 0;

        int index = 0, startIndex = 0;
        if (lastState.nameHash == RUN_STATE)
            startIndex = numOfStandAnimations;

        alignTime = (lastState.nameHash != RUN_STATE) ? 0.2f : 0.1f;

        float curHeight = ownner.GetNode().worldPosition.y;
        float lineHeight = ownner.dockLine.end.y;
        float minHeightDiff = 9999;

        for (int i=0; i<numOfStandAnimations; ++i)
        {
            Motion@ m = motions[startIndex + i];
            float motionHeight = curHeight + m.maxHeight + climbBaseHeight;
            float curHeightDiff = Abs(lineHeight - motionHeight);
            Print(this.name + " "  + m.name + " maxHeight=" + m.maxHeight + " heightDiff=" + curHeightDiff);
            if (curHeightDiff < minHeightDiff)
            {
                minHeightDiff = curHeightDiff;
                index = startIndex + i;
            }
        }

        ownner.GetNode().vars[ANIMATION_INDEX] = index;
        return index;
    }

    Vector3 PickDockOutTarget()
    {
        return ownner.dockLine.Project(ownner.GetNode().worldPosition);
    }

    Vector3 PickDockInTarget()
    {
        Line@ l = ownner.dockLine;
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
        return v;
    }

    float PickDockInRotation()
    {
        Vector3 v = ownner.GetNode().worldPosition;
        Vector3 proj = ownner.dockLine.Project(v);
        Vector3 dir = proj - v;
        float r = Atan2(dir.x, dir.z);
        if (!ownner.dockLine.IsAngleValid(r))
            r = AngleDiff(r + 180);
        return r;
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

        if (dockBlendingMethod == 1)
        {
            MultiMotionState::Enter(lastState);
            Motion@ m = motions[selectIndex];
            targetPosition = ownner.dockLine.Project(ownner.GetNode().worldPosition);

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
        else
        {
            if (lastState.nameHash == ALIGN_STATE)
            {
                MultiMotionState::Enter(lastState);

                if (motionFlagAfterAlign != 0)
                {
                    Motion@ motion = motions[selectIndex];
                    Vector3 targetPos = ownner.dockLine.Project(ownner.GetNode().worldPosition);
                    float t = motion.endTime;
                    Vector3 motionPos = motion.GetFuturePosition(ownner, t);
                    Vector3 diff = targetPos - motionPos;
                    diff /= t;
                    Vector3 v(0, 0, 0);
                    if (motionFlagAfterAlign & kMotion_X != 0)
                        v.x = diff.x;
                    if (motionFlagAfterAlign & kMotion_Y != 0)
                        v.y = diff.y;
                    if (motionFlagAfterAlign & kMotion_Z != 0)
                        v.z = diff.z;
                    ownner.motion_velocity = v;
                    Print(this.name + " animation:" + motion.name + " after align vel=" + v.ToString());
                }
            }
            else
            {
                selectIndex = PickIndex();
                Vector3 myPos = ownner.GetNode().worldPosition;
                Vector3 proj = ownner.dockLine.Project(myPos);
                proj.y = myPos.y;
                Vector3 dir = proj - myPos;
                float targetAngle = Atan2(dir.x, dir.z);
                Vector3 targetPos = proj + Quaternion(0, targetAngle, 0) * targetOffsets[selectIndex];

                // Run-Case
                if (selectIndex >= 3)
                {
                    float len_diff = (targetPos - myPos).length;
                    Print("state:" + this.name + " selectIndex=" + selectIndex + " len_diff=" + len_diff);
                    if (len_diff > 3)
                        selectIndex -= 3;
                    targetPos = proj + Quaternion(0, targetAngle, 0) * targetOffsets[selectIndex];
                    ownner.GetNode().vars[ANIMATION_INDEX] = selectIndex;
                }

                CharacterAlignState@ s = cast<CharacterAlignState>(ownner.FindState(ALIGN_STATE));
                String alignAnim = "";
                // walk
                if (selectIndex == 0)
                    alignAnim = ownner.walkAlignAnimation;
                s.Start(this.nameHash, targetPos,  targetAngle, alignTime, 0, alignAnim);

                ownner.ChangeStateQueue(ALIGN_STATE);
            }
        }
    }

    void Exit(State@ nextState)
    {
        if (debug)
            ownner.SetSceneTimeScale(0);
        MultiMotionState::Exit(nextState);
    }
};

class PlayerClimbOverState : PlayerDockAlignState
{
    Vector3     groundPos;
    Vector3     down128Pos;
    Vector3     startPos;

    Line@       downLine;

    PlayerClimbOverState(Character@ c)
    {
        super(c);
        SetName("ClimbOverState");
        dockBlendingMethod = 1;
        dockInCheckThinWall = false;
    }

    void Enter(State@ lastState)
    {
        int index = 0;
        if (downLine is null)
        {
            motionFlagAfterAlign = 0;
            index = PickTargetMotionByHeight(lastState, 2);
            if (index == 0 || index == 2)
            {
                Vector3 myPos = ownner.GetNode().worldPosition;
                Motion@ m = motions[index];
                Vector4 motionOut = m.GetKey(m.endTime);
                Vector3 proj = ownner.dockLine.Project(myPos);
                Vector3 dir = proj - myPos;
                float targetRotation = Atan2(dir.x, dir.z);
                Vector3 futurePos = Quaternion(0, targetRotation, 0) * Vector3(0, 0, 2.0f) + proj;
                futurePos.y = myPos.y;
                Player@ p = cast<Player>(ownner);
                groundPos = p.sensor.GetGround(futurePos);
                float height = Abs(groundPos.y - myPos.y);
                if (height < 1.5f)
                {
                    if (index == 0)
                        index = 4;
                    else
                        index = 5;
                    motionFlagAfterAlign = kMotion_Y;
                }
            }
        }
        else
        {
            index = 6;
            if (downLine.HasFlag(LINE_SHORT_WALL))
                index += 1;
            motionFlagAfterAlign = kMotion_XYZ;
            startPos = downLine.Project(ownner.GetNode().worldPosition);
        }

        Print(this.name + " animation index=" + index);
        ownner.GetNode().vars[ANIMATION_INDEX] = index;
        PlayerDockAlignState::Enter(lastState);
    }

    Vector3 PickDockOutTarget()
    {
        return (selectIndex >= 6) ? down128Pos : groundPos;
    }

    float PickDockOutRotation()
    {
        if (downLine is null)
            return PlayerDockAlignState::PickDockOutRotation();
        Vector3 v = ownner.GetNode().worldPosition;
        Vector3 proj = downLine.Project(v);
        Vector3 dir = v - proj;
        dir.y = 0;
        return Atan2(dir.x, dir.z);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        PlayerDockAlignState::DebugDraw(debug);
        debug.AddCross(groundPos, 0.5f, BLUE, false);
        debug.AddCross(down128Pos, 0.5f, Color(1, 0, 1), false);
    }

    void OnMotionFinished()
    {
        if (selectIndex == 4 || selectIndex == 5)
            PlayerDockAlignState::OnMotionFinished();
        else if (selectIndex == 6)
            ownner.ChangeState("HangIdleState");
        else if (selectIndex == 7)
            ownner.ChangeState("DangleIdleState");
        else
            ownner.ChangeState("FallState");
    }

    void OnMotionAlignTimeOut()
    {
        if (downLine !is null && selectIndex >= 6)
        {
            Vector3 offset;
            if (selectIndex == 6)
                offset = Vector3(0, -3.7, 1.45);
            else
                offset = Vector3(0, -3.7, 1.8);
            down128Pos = startPos + Quaternion(0, targetRotation, 0) * offset;
            ownner.AssignDockLine(downLine);
        }
        PlayerDockAlignState::OnMotionAlignTimeOut();
    }
};

class PlayerClimbUpState : PlayerDockAlignState
{
    PlayerClimbUpState(Character@ c)
    {
        super(c);
        SetName("ClimbUpState");
        motionFlagAfterAlign = kMotion_Y;
        dockBlendingMethod = 1;
    }

    void Enter(State@ lastState)
    {
        PickTargetMotionByHeight(lastState);
        PlayerDockAlignState::Enter(lastState);
    }
};

class PlayerHangUpState : PlayerDockAlignState
{
    PlayerHangUpState(Character@ c)
    {
        super(c);
        SetName("HangUpState");
        climbBaseHeight = 3.0f;
        dockBlendingMethod = 1;
    }

    void Enter(State@ lastState)
    {
        PickTargetMotionByHeight(lastState, 2);
        PlayerDockAlignState::Enter(lastState);
    }

    void OnMotionFinished()
    {
        ownner.ChangeState("HangIdleState");
    }
};

class PlayerHangIdleState : MultiMotionState
{
    String idleAnim;
    StringHash overStateName = StringHash("HangOverState");
    StringHash moveStateName = StringHash("HangMoveState");

    float moveToLinePtDist = 1.5f;
    float turnSpeed = 0.0f;
    float alignTime = 0.2f;
    float inputCheckTime = 0.2f;

    float motionRotation;
    float targetRotation;

    Vector3 targetPosition;
    Vector3 motionPositon;

    int   state;

    PlayerHangIdleState(Character@ c)
    {
        super(c);
        SetName("HangIdleState");
        physicsType = 0;
    }

    void OnMotionFinished()
    {
        if (!idleAnim.empty)
            ownner.PlayAnimation(idleAnim, LAYER_MOVE, true, 0.0f, startTime, animSpeed);

        ownner.motion_velocity = Vector3(0, 0, 0);
        turnSpeed = 0.0f;
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
        ownner.SetVelocity(Vector3(0,0,0));
        state = 0;

        int curAnimationIndex = ownner.GetNode().vars[ANIMATION_INDEX].GetInt();
        int index = 0;

        bool fromMove = lastState.name == "HangMoveState" || lastState.name == "DangleMoveState";
        blendTime = fromMove ? 0.0f : 0.3f;
        if (fromMove)
            index = (curAnimationIndex <= 2) ? 0 : 1;
        else
            index = RandomInt(2) == 0 ? 0 : 1;

        ownner.GetNode().vars[ANIMATION_INDEX] = index;
        MultiMotionState::Enter(lastState);

        Motion@ m = motions[index];
        alignTime = m.dockAlignTime;
        inputCheckTime = fromMove ? 0.0f : 0.2f;

        motionRotation = ownner.GetCharacterAngle();
        targetRotation = ownner.dockLine.GetTargetRotation(ownner.GetNode().worldPosition);
        turnSpeed = AngleDiff(targetRotation - motionRotation) / alignTime;

        motionPositon = m.GetDockAlignPositionAtTime(ownner, targetRotation, alignTime);
        targetPosition = ownner.dockLine.Project(motionPositon);

        ownner.motion_velocity = fromMove ? Vector3(0, 0, 0) : (targetPosition - motionPositon) / alignTime;
    }

    bool CheckFootBlocking()
    {
        if (ownner.dockLine.HasFlag(LINE_SHORT_WALL))
        {
            ownner.ChangeState("DangleIdleState");
            return true;
        }
        return false;
    }

    void Update(float dt)
    {
        CheckFootBlocking();

        if (state == 0)
        {
            ownner.motion_deltaRotation += turnSpeed * dt;

            if (timeInState >= alignTime)
            {
                ownner.GetNode().worldRotation = Quaternion(0, targetRotation, 0);
                state = 1;
            }
        }

        if (timeInState > inputCheckTime)
        {
            if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
            {
                int index = ownner.RadialSelectAnimation(4); //DirectionMapToIndex(gInput.GetLeftAxisAngle(), 4);
                if (index == 0)
                    VerticalMove();
                else if (index == 2)
                    ownner.ChangeState("FallState");
                else
                    HorizontalMove(index == 3);
            }
        }

        MultiMotionState::Update(dt);
    }

    bool VerticalMove()
    {
        Player@ p = cast<Player>(ownner);
        Line@ oldLine = ownner.dockLine;
        p.ClimbUpRaycasts(oldLine);

        bool hitUp = p.results[0].body !is null;
        bool hitForward = p.results[1].body !is null;
        bool hitDown = p.results[2].body !is null;

        int animIndex = 0;
        bool changeToOverState = false;

        Print(this.name + " VerticalMove hit1=" + hitUp + " hitForward=" + hitForward + " hitDown=" + hitDown);

        if (hitUp)
            return false;

        if (hitForward)
        {
            // hit a front wall
            Array<Line@>@ lines = gLineWorld.cacheLines;
            lines.Clear();

            gLineWorld.CollectLinesByNode(p.results[1].body.node, lines);
            if (lines.empty)
                return false;

            Print(this.name + " hit front wall lines.num=" + lines.length);
            Line@ bestLine = null;
            float maxDistSQR = 4.0f * 4.0f;
            float minHeightDiff = 1.0f;
            float maxHeightDiff = 4.5f;
            Vector3 comparePot = oldLine.Project(ownner.GetNode().worldPosition);

            for (uint i=0; i<lines.length; ++i)
            {
                Line@ l = lines[i];

                if (l is oldLine)
                    continue;

                if (!l.TestAngleDiff(oldLine, 0) && !l.TestAngleDiff(oldLine, 180))
                    continue;

                float dh = l.end.y - oldLine.end.y;
                if (dh < minHeightDiff || dh > maxHeightDiff)
                    continue;

                Vector3 tmpV = l.Project(comparePot);
                tmpV.y = comparePot.y;
                float distSQR = (tmpV - comparePot).lengthSquared;
                Print(this.name + " hit front wall distSQR=" + distSQR);
                if (distSQR < maxDistSQR)
                {
                    @bestLine = l;
                    maxDistSQR = distSQR;
                }
            }

            if (bestLine is null)
            {
                Print(this.name + " hit front wall no best line!!");
                @oldLine = null;
                return false;
            }

            animIndex = 1;
            changeToOverState = true;
            ownner.AssignDockLine(bestLine);
        }
        else
        {
            // no front wall
            if (hitDown)
            {
                // hit gournd
                float hitGroundH = p.results[2].position.y;
                float lineToGround = oldLine.end.y - hitGroundH;

                if (lineToGround < (0 + HEIGHT_128) / 2)
                {
                    // if gound is not low just stand and run
                    animIndex = 0;
                }
                else if (lineToGround < (HEIGHT_128 + HEIGHT_256) / 2)
                {
                    // if gound is lower not than 4.5 we can perform a over jump
                    animIndex = 2;
                }
                else
                {
                    // if gound is lower enough just jump and fall
                    animIndex = 3;
                }

                changeToOverState = true;
            }
            else
            {
                // dont hit gournd
                animIndex = 3;
                changeToOverState = true;
            }
        }

        if (changeToOverState)
        {
            Print(this.name + " Climb over animIndex=" + animIndex);
            ownner.GetNode().vars[ANIMATION_INDEX] = animIndex;

            PlayerHangOverState@ s = cast<PlayerHangOverState>(ownner.FindState(overStateName));
            s.groundPos = p.results[2].position;
            ownner.ChangeState(overStateName);
            return true;
        }
        return false;
    }

    PlayerHangMoveState@ GetMoveState(Line@ l)
    {
        if (l.HasFlag(LINE_SHORT_WALL))
            return cast<PlayerHangMoveState>(ownner.FindState("DangleMoveState"));
        else
            return cast<PlayerHangMoveState>(ownner.FindState("HangMoveState"));
        // return cast<PlayerHangMoveState>(ownner.FindState(moveStateName));
    }

    bool TryToMoveToLinePoint(bool left)
    {
        Node@ n = ownner.GetNode();
        Vector3 myPos = n.worldPosition;
        Vector3 towardDir = left ? Vector3(-1, 0, 0) : Vector3(1, 0, 0);
        towardDir = n.worldRotation * towardDir;
        Vector3 linePt = ownner.dockLine.GetLinePoint(towardDir);
        String handName = left ? L_HAND : R_HAND;
        Vector3 handPos = n.GetChild(handName, true).worldPosition;
        handPos = ownner.dockLine.Project(handPos);

        float distSQR = (handPos - linePt).lengthSquared;
        Print("TryToMoveToLinePoint distSQR=" + distSQR);

        if (distSQR < moveToLinePtDist * moveToLinePtDist)
            return false;

        GetMoveState(ownner.dockLine).MoveToLinePoint(left);
        return true;
    }

    bool HorizontalMove(bool left)
    {
        PlayerHangMoveState@ s = GetMoveState(ownner.dockLine);
        Player@ p = cast<Player>(ownner);

        Line @oldLine = ownner.dockLine;

        int index = left ? 0 : s.numOfAnimations;
        Motion@ m = s.motions[index];
        Vector4 motionOut = m.GetKey(m.endTime);
        Node@ n = ownner.GetNode();
        Vector3 myPos = n.worldPosition;
        Vector3 proj = oldLine.Project(myPos);
        Vector3 dir = proj - myPos;
        Quaternion q(0, Atan2(dir.x, dir.z), 0);

        Vector3 towardDir = left ? Vector3(-1, 0, 0) : Vector3(1, 0, 0);
        towardDir = q * towardDir;
        towardDir.y = 0;
        Vector3 linePt = oldLine.GetLinePoint(towardDir);

        Vector3 futurePos = q * Vector3(motionOut.x, motionOut.y, motionOut.z) + myPos;
        Vector3 futureProj = oldLine.Project(futurePos);
        bool outOfLine = !oldLine.IsProjectPositionInLine(futureProj, 0.5f);
        Ray ray;
        ray.Define(myPos, towardDir);
        float dist = (futureProj - proj).length + 1.0f;
        bool blocked = ownner.GetScene().physicsWorld.RaycastSingle(ray, dist, COLLISION_LAYER_LANDSCAPE).body !is null;
        Print("Move left=" + left + " outOfLine=" + outOfLine + " blocked=" + blocked);

        if (outOfLine || blocked)
        {
            int convexIndex = 1;
            Line@ l = p.FindCrossLine(left, convexIndex);
            if (l !is null)
            {
                GetMoveState(l).CrossMove(l, left, convexIndex);
                return true;
            }
        }

        if (blocked)
            return false;

        if (outOfLine)
        {
            // test if we are a little bit futher to the linePt
            if (TryToMoveToLinePoint(left))
                return true;

            float distErrSQR = 0;
            Line@ l = p.FindParalleLine(left, distErrSQR);
            if (l !is null)
            {
                GetMoveState(l).ParalleJumpMove(l, left);
                return true;
            }
            return false;
        }

        GetMoveState(ownner.dockLine).NormalMove(left);
        return true;
    }
};

enum HangMoveType
{
    HANG_NORMAL,
    HANG_CONVEX,
    HANG_CONCAVE,
    HANG_JUMP,
};

class PlayerHangMoveState : PlayerDockAlignState
{
    Line@           oldLine;
    int             numOfAnimations = 3;
    int             type = 0;

    PlayerHangMoveState(Character@ ownner)
    {
        super(ownner);
        SetName("HangMoveState");
        dockBlendingMethod = 1;
        //debug = true;
    }

    void Enter(State@ lastState)
    {
        motionFlagBeforeAlign = (type == HANG_CONVEX || type == HANG_CONCAVE) ? kMotion_XYZ : kMotion_ALL;
        motionFlagAfterAlign = (type == HANG_CONVEX || type == HANG_CONCAVE) ? kMotion_ALL : kMotion_None;
        debug = (type == HANG_CONVEX || type == HANG_CONCAVE) ? true : false;

        PlayerDockAlignState::Enter(lastState);
        Print(this.name + " enter type = " + type);
    }

    void Exit(State@ nextState)
    {
        @oldLine = null;
        PlayerDockAlignState::Exit(nextState);
    }

    void CrossMove(Line@ line, bool left, int convexIndex)
    {
        Print(this.name + " CrossMove");

        @oldLine = ownner.dockLine;
        ownner.AssignDockLine(line);

        int index = left ? 0 : numOfAnimations;
        index += convexIndex;
        dockBlendingMethod = 1;
        type = (convexIndex == 1) ? HANG_CONVEX : HANG_CONCAVE;
        ownner.GetNode().vars[ANIMATION_INDEX] = index;
        dockInTargetBound = 1.5f;
        ownner.ChangeState(this.nameHash);
    }

    void ParalleJumpMove(Line@ line, bool left)
    {
        Print(this.name + " ParalleJumpMove");

        @oldLine = ownner.dockLine;
        ownner.AssignDockLine(line);

        int index = left ? 0 : numOfAnimations;
        dockBlendingMethod = 1;
        dockInTargetBound = 1.5f;

        type = HANG_JUMP;

        ownner.GetNode().vars[ANIMATION_INDEX] = index;
        ownner.ChangeState(this.nameHash);
    }

    void MoveToLinePoint(bool left)
    {
        Print(this.name + " MoveToLinePoint");

        @oldLine = null;
        type = HANG_NORMAL;
        dockBlendingMethod = 1;
        dockInTargetBound = 0.1f;
        ownner.GetNode().vars[ANIMATION_INDEX] = left ? 0 : numOfAnimations;
        ownner.ChangeState(this.nameHash);
    }

    void NormalMove(bool left)
    {
        dockBlendingMethod = 1;
        @oldLine = null;
        type = HANG_NORMAL;
        dockInTargetBound = 0.1;
        ownner.GetNode().vars[ANIMATION_INDEX] = left ? 0 : numOfAnimations;
        ownner.ChangeState(this.nameHash);
    }

    void OnMotionFinished()
    {
        ownner.ChangeState("HangIdleState");
    }

    Vector3 PickDockInTarget()
    {
        Line@ l = ownner.dockLine;
        Vector3 v = l.Project(motionPositon);
        v = l.FixProjectPosition(v, dockInTargetBound);
        if (l.HasFlag(LINE_THIN_WALL))
        {
            Player@ p = cast<Player>(ownner);
            Vector3 dir;
            bool convex = selectIndex % 2 != 0;
            if (type == HANG_CONCAVE || type == HANG_CONVEX)
                dir = convex ? (p.points[2] - p.points[3]) : (p.points[0] - p.points[1]);
            else
                dir = Quaternion(0, targetRotation, 0) * Vector3(0, 0, -1);
            dir.y = 0;
            float dist = Min(l.size.x, l.size.z) / 2;
            v += dir.Normalized() * dist;
        }
        return v;
    }

    Vector3 PickDockOutTarget()
    {
        return ownner.dockLine.Project(motionPositon) + Quaternion(0, targetRotation, 0) * Vector3(0, -3.6, -1.45);
    }
};

class PlayerHangOverState : PlayerDockAlignState
{
    Vector3    groundPos;

    PlayerHangOverState(Character@ ownner)
    {
        super(ownner);
        SetName("HangOverState");
        physicsType = 0;
        dockBlendingMethod = 1;
    }

    Vector3 PickDockOutTarget()
    {
        if (selectIndex <= 2)
            return groundPos;
        else
            return PlayerDockAlignState::PickDockOutTarget();
    }

    void Enter(State@ lastState)
    {
        PlayerDockAlignState::Enter(lastState);
        motionFlagAfterAlign = (selectIndex <= 2) ? int(kMotion_Y) : 0;
    }

    void OnMotionFinished()
    {
        if (selectIndex > 2)
            ownner.ChangeState("FallState");
        else
            PlayerDockAlignState::OnMotionFinished();
    }
};

class PlayerDangleIdleState : PlayerHangIdleState
{
    PlayerDangleIdleState(Character@ c)
    {
        super(c);
        SetName("DangleIdleState");
        overStateName = StringHash("DangleOverState");
        moveStateName = StringHash("DangleMoveState");
    }

    bool CheckFootBlocking()
    {
        if (!ownner.dockLine.HasFlag(LINE_SHORT_WALL))
        {
            ownner.ChangeState("HangIdleState");
            return true;
        }
        return false;
    }
};

class PlayerDangleOverState : PlayerHangOverState
{
    PlayerDangleOverState(Character@ ownner)
    {
        super(ownner);
        SetName("DangleOverState");
    }
};

class PlayerDangleMoveState : PlayerHangMoveState
{
    PlayerDangleMoveState(Character@ ownner)
    {
        super(ownner);
        SetName("DangleMoveState");
    }

    void OnMotionFinished()
    {
        ownner.ChangeState("DangleIdleState");
    }
};

class PlayerClimbDownState : PlayerDockAlignState
{
    PlayerClimbDownState(Character@ c)
    {
        super(c);
        SetName("ClimbDownState");
        dockBlendingMethod = 1;
        motionFlagBeforeAlign = kMotion_ALL;
    }

    float PickDockInRotation()
    {
        return ownner.dockLine.GetTargetRotation(ownner.GetNode().worldPosition);
    }

    void Enter(State@ lastState)
    {
        ownner.GetNode().vars[ANIMATION_INDEX] = ownner.dockLine.HasFlag(LINE_SHORT_WALL) ? 1 : 0;
        PlayerDockAlignState::Enter(lastState);
    }

    void OnMotionFinished()
    {
        if (selectIndex == 0)
            ownner.ChangeState("HangIdleState");
        else
            ownner.ChangeState("DangleIdleState");
    }
};
