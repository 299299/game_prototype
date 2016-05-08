// ==============================================
//
//    Player Pawn and Controller Class
//
// ==============================================

class Player : Character
{
    bool                              applyGravity = true;

    void ObjectStart()
    {
        Character::ObjectStart();

        side = 1;
        @sensor = PhysicsSensor(sceneNode);

        Node@ tailNode = sceneNode.CreateChild("TailNode");
        ParticleEmitter@ emitter = tailNode.CreateComponent("ParticleEmitter");
        emitter.effect = cache.GetResource("ParticleEffect", "Particle/Tail.xml");
        tailNode.enabled = false;

        AddStates();
        ChangeState("StandState");
    }

    void AddStates()
    {
    }


    void CommonStateFinishedOnGroud()
    {
        if (health <= 0)
            return;

        if (CheckFalling())
            return;

        bool bCrouch = gInput.IsCrouchDown();
        if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
        {
            int index = RadialSelectAnimation(4);
            sceneNode.vars[ANIMATION_INDEX] = index -1;
            Print("CommonStateFinishedOnGroud crouch=" + bCrouch + "To->Move|Turn hold-frames=" + gInput.GetLeftAxisHoldingFrames() + " hold-time=" + gInput.GetLeftAxisHoldingTime());
            if (index != 0)
            {
                if (bCrouch)
                {
                    if (ChangeState("CrouchTurnState"))
                        return;
                }
                else
                {
                    if (ChangeState(gInput.IsRunHolding() ? "StandToRunState" : "StandToWalkState"))
                        return;
                }
            }

            if (bCrouch)
                ChangeState("CrouchState");
            else
                ChangeState(gInput.IsRunHolding() ? "RunState" : "WalkState");
        }
        else
            ChangeState(bCrouch ? "CrouchState" : "StandState");
    }

    float GetTargetAngle()
    {
        return gInput.GetLeftAxisAngle() + gCameraMgr.GetCameraAngle();
    }

    void SetTarget(Character@ t)
    {
        if (target is t)
            return;
        if (target !is null)
            target.RemoveFlag(FLAGS_NO_MOVE);
        Character::SetTarget(t);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        Character::DebugDraw(debug);
        // debug.AddCircle(sceneNode.worldPosition, Vector3(0, 1, 0), COLLISION_RADIUS, YELLOW, 32, false);
        // sensor.DebugDraw(debug);
        debug.AddNode(sceneNode.GetChild(TranslateBoneName, true), 0.5f, false);

        if (points.length > 1)
        {
            for (uint i=0; i<points.length-1; ++i)
            {
                debug.AddLine(points[i], points[i+1], Color(0.5, 0.45, 0.75), false);
            }

            for (uint i=0; i<results.length; ++i)
            {
                if (results[i].body !is null)
                    debug.AddCross(results[i].position, 0.25f, Color(0.1f, 0.7f, 0.25f), false);
            }
        }

        debug.AddBoundingBox(box, Color(0.25, 0.75, 0.25), false);
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

    void ShowInputAction(const String&in message, bool bShow)
    {
        Text@ text = ui.root.GetChild("input", true);
        if (text !is null)
        {
            text.visible = bShow;
            text.text = message;
        }
    }
};
