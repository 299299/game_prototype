// ==============================================
//
//    All Dummy Scripts but never used
//
// ==============================================

class PlayerDistractState : SingleMotionState
{
    PlayerDistractState(Character@ c)
    {
        super(c);
        SetName("DistractState");
        SetMotion("BM_Attack/CapeDistract_Close_Forward");
        flags = FLAGS_ATTACK;
    }

    void Enter(State@ lastState)
    {
        float targetRotation = ownner.GetTargetAngle();
        ownner.GetNode().worldRotation = Quaternion(0, targetRotation, 0);
        SingleMotionState::Enter(lastState);
    }

    void OnAnimationTrigger(AnimationState@ animState, const VariantMap&in eventData)
    {
        StringHash name = eventData[NAME].GetStringHash();
        if (name == IMPACT)
        {
            ownner.PlaySound("Sfx/swing.ogg");

            Player@ p = cast<Player>(ownner);
            Array<Enemy@> enemies;
            p.CommonCollectEnemies(enemies, MAX_DISTRACT_DIR, MAX_DISTRACT_DIST, FLAGS_ATTACK);

            combatReady = true;

            for (uint i=0; i<enemies.length; ++i)
                enemies[i].Distract();

            return;
        }
        CharacterState::OnAnimationTrigger(animState, eventData);
    }
};

class PlayerBeatDownStartState : CharacterState
{
    Motion@     motion;

    float       alignTime = 0.2f;
    int         state = 0;
    Vector3     movePerSec;
    Vector3     targetPosition;

    PlayerBeatDownStartState(Character@ c)
    {
        super(c);
        SetName("BeatDownStartState");
        flags = FLAGS_ATTACK;
        @motion = gMotionMgr.FindMotion("BM_Combat/Into_Takedown");
    }

    void Enter(State@ lastState)
    {
        Character@ target = ownner.target;
        float angle = ownner.GetTargetAngle();
        ownner.GetNode().worldRotation = Quaternion(0, angle, 0);

        target.RequestDoNotMove();

        alignTime = 0.2f;
        Vector3 myPos = ownner.GetNode().worldPosition;
        Vector3 enemyPos = target.GetNode().worldPosition;

        float dist = COLLISION_RADIUS*2 + motion.endDistance;
        targetPosition = enemyPos + ownner.GetNode().worldRotation * Vector3(0, 0, -dist);
        movePerSec = ( targetPosition - myPos ) / alignTime;
        movePerSec.y = 0;

        state = 0;

        CharacterState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        CharacterState::Exit(nextState);
        if (ownner.target !is null)
            ownner.target.RemoveFlag(FLAGS_NO_MOVE);
    }

    void Update(float dt)
    {
        if (state == 0)
        {
            ownner.MoveTo(ownner.GetNode().worldPosition + movePerSec * dt, dt);

            if (timeInState >= alignTime)
            {
                state = 1;
                motion.Start(ownner);

                Character@ target = ownner.target;
                float angle = ownner.GetTargetAngle();
                target.GetNode().worldRotation = Quaternion(0, angle + 180, 0);
                target.ChangeState("BeatDownStartState");
            }
        }
        else if (state == 1)
        {
            if (motion.Move(ownner, dt)) {
                ownner.ChangeState("BeatDownHitState");
                return;
            }
        }

        CharacterState::Update(dt);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        if (ownner.target is null)
            return;
        debug.AddLine(ownner.GetNode().worldPosition, ownner.target.GetNode().worldPosition, RED, false);
        debug.AddCross(targetPosition, 1.0f, RED, false);
    }
};

class ThugBeatDownStartState : SingleMotionState
{
    ThugBeatDownStartState(Character@ c)
    {
        super(c);
        SetName("BeatDownStartState");
        SetMotion("TG_BM_Beatdown/Beatdown_Start_01");
        flags = FLAGS_STUN | FLAGS_ATTACK;
    }
};

class ThugDistractState : SingleMotionState
{
    ThugDistractState(Character@ ownner)
    {
        super(ownner);
        SetName("DistractState");
        SetMotion("TG_HitReaction/CapeDistract_Close_Forward");
        flags = FLAGS_STUN | FLAGS_ATTACK;
    }

    void Enter(State@ lastState)
    {
        ownner.GetNode().Yaw(ownner.ComputeAngleDiff());
        SingleMotionState::Enter(lastState);
    }

    void OnMotionFinished()
    {
        Print(ownner.GetName() + " state:" + name + " finshed motion:" + motion.animationName);
        ownner.ChangeState("StunState");
    }
};

Animation@ CreateAnimation(const String&in originAnimationName, const String&in name, int start_frame, int num_of_frames)
{
    Animation@ originAnimation = FindAnimation(originAnimationName);
    if (originAnimation is null)
        return null;
    Animation@ anim = Animation();
    anim.name = GetAnimationName(name);
    anim.animationName = name;
    anim.length = float(num_of_frames) * SEC_PER_FRAME;
    for (uint i=0; i<skeleton.numBones; ++i)
    {
        AnimationTrack@ originTrack = originAnimation.tracks[skeleton.bones[i].name];
        if (originTrack is null)
            continue;
        AnimationTrack@ track = anim.CreateTrack(skeleton.bones[i].name);
        track.channelMask = originTrack.channelMask;
        for (int j=start_frame; j<start_frame+num_of_frames; ++j)
        {
            AnimationKeyFrame kf(originTrack.keyFrames[j]);
            kf.time = float(j-start_frame) * SEC_PER_FRAME;
            track.AddKeyFrame(kf);
        }
    }
    cache.AddManualResource(anim);
    return anim;
}

bool Evade()
{
    // Print("Player::Evade()");

    Enemy@ redirectEnemy = null;
    if (has_redirect)
        @redirectEnemy = PickRedirectEnemy();

    if (redirectEnemy !is null)
    {
        PlayerRedirectState@ s = cast<PlayerRedirectState>(stateMachine.FindState("RedirectState"));
        s.redirectEnemyId = redirectEnemy.GetNode().id;
        ChangeState("RedirectState");
        redirectEnemy.Redirect();
    }
    else
    {
        // if (!gInput.IsLeftStickInDeadZone() && gInput.IsLeftStickStationary())
        {

        }
    }

    return true;
}


class ThugRedirectState : MultiMotionState
{
    ThugRedirectState(Character@ c)
    {
        super(c);
        SetName("RedirectState");
        AddMotion(MOVEMENT_GROUP_THUG + "Redirect_push_back");
        AddMotion(MOVEMENT_GROUP_THUG + "Redirect_Stumble_JK");
    }

    void Enter(State@ lastState)
    {
        selectIndex = PickIndex();
        if (d_log)
            Print(name + " pick " + motions[selectIndex].animationName);
        motions[selectIndex].Start(ownner, 0.0f, 0.5f);
    }

    int PickIndex()
    {
        return RandomInt(2);
    }
};


class PlayerRedirectState : SingleMotionState
{
    uint redirectEnemyId = M_MAX_UNSIGNED;
    PlayerRedirectState(Character@ c)
    {
        super(c);
        SetName("RedirectState");
    }
    void Exit(State@ nextState)
    {
        redirectEnemyId = M_MAX_UNSIGNED;
        SingleMotionState::Exit(nextState);
    }
};

if (key == 'E')
{
    Player@ player = GetPlayer();
    if (player is null)
        return;

    Node@ renderNode = player.GetNode().children[0];
    SendAnimationTriger(renderNode, RAGDOLL_STOP);

    AnimationController@ ctl = renderNode.GetComponent("AnimationController");
    Animation@ anim = Animation();
    String name = "Test_Pose";
    anim.name = name;
    anim.animationName = name;
    FillAnimationWithCurrentPose(anim, renderNode);
    cache.AddManualResource(anim);

    AnimatedModel@ model = renderNode.GetComponent("AnimatedModel");
    AnimationState@ state = model.AddAnimationState(anim);
    state.weight = 1.0f;
    ctl.PlayExclusive(anim.name, LAYER_MOVE, false, 0.0f);

    int ragdoll_direction = player.GetNode().vars[ANIMATION_INDEX].GetInt();
    String name1 = ragdoll_direction == 0 ? "TG_Getup/GetUp_Back" : "TG_Getup/GetUp_Front";
    PlayAnimation(ctl, GetAnimationName(name1), LAYER_MOVE, false, 0.25f, 0.0, 0.0);
}
else if (key == 'F')
{
    Player@ player = GetPlayer();
    if (player is null)
        return;
    Node@ renderNode = player.GetNode().children[0];
    AnimationController@ ctl = renderNode.GetComponent("AnimationController");
    int ragdoll_direction = player.GetNode().vars[ANIMATION_INDEX].GetInt();
    String name1 = ragdoll_direction == 0 ? "TG_Getup/GetUp_Back" : "TG_Getup/GetUp_Front";
    ctl.SetSpeed(GetAnimationName(name1), 1.0);
}

class PlayerSlideIdleState : CharacterState
{
    String animation;
    float slideTimer = 2.0f;

    PlayerSlideIdleState(Character@ c)
    {
        super(c);
        SetName("SlideIdleState");
        flags = FLAGS_ATTACK | FLAGS_MOVING;
    }

    void Enter(State@ lastState)
    {
        ownner.SetTarget(null);
        ownner.PlayAnimation(animation, LAYER_MOVE, true, 0.0f);
        ownner.SetVelocity(Vector3(0,0,0));

        CharacterState::Enter(lastState);
    }
};

class BruceSlideIdleState : PlayerSlideIdleState
{
    BruceSlideIdleState(Character@ c)
    {
        super(c);
        animation = GetAnimationName("BM_Climb/Slide_Floor_Idle");

        Animation@ anim = cache.GetResource("Animation", animation);
        AnimationTrack@ track = anim.CreateTrack(TranslateBoneName);
        AnimationTrack@ track1 = anim.tracks["Bip01_L_Foot"];
        uint n = track1.numKeyFrames;
        track.channelMask = CHANNEL_POSITION;
        for (uint i=0; i<track1.numKeyFrames; ++i)
        {
            AnimationKeyFrame kf;
            kf.time = track1.keyFrames[i].time;
            kf.position = Vector3(0, 0.385f, 0);
            track.AddKeyFrame(kf);
        }
    }
};

class PlayerCrouchToStandState : SingleMotionState
{
    PlayerCrouchToStandState(Character@ c)
    {
        super(c);
        SetName("CrouchToStandState");
        flags = FLAGS_ATTACK;
    }
};

class PlayerStandToCrouchState : SingleMotionState
{
    PlayerStandToCrouchState(Character@ c)
    {
        super(c);
        SetName("StandToCrouchState");
        flags = FLAGS_ATTACK;
    }

    void OnMotionFinished()
    {
        ownner.ChangeState("CrouchState");
    }
};


//DebugDrawDirection(debug, sceneNode, GetTargetAngle(), Color(1,0.5,0), 2.0f);
//debug.AddCircle(sceneNode.worldPosition, Vector3(0, 1, 0), COLLISION_RADIUS, YELLOW, 32, false);
//debug.AddLine(hipsNode.worldPosition, sceneNode.worldPosition, YELLOW, false);
//DebugDrawDirection(debug, sceneNode, sceneNode.worldRotation, BLUE, COLLISION_RADIUS);
/*
Node@ handNode_L = renderNode.GetChild("Bip01_L_Hand", true);
Node@ handNode_R = renderNode.GetChild("Bip01_R_Hand", true);
Node@ footNode_L = renderNode.GetChild("Bip01_L_Foot", true);
Node@ footNode_R = renderNode.GetChild("Bip01_R_Foot", true);
float radius = attackRadius;
Sphere sp;
sp.Define(handNode_L.worldPosition, radius);
debug.AddSphere(sp, Color(0, 1, 0));
sp.Define(handNode_R.worldPosition, radius);
debug.AddSphere(sp, Color(0, 1, 0));
sp.Define(footNode_L.worldPosition, radius);
debug.AddSphere(sp, Color(0, 1, 0));
sp.Define(footNode_R.worldPosition, radius);
debug.AddSphere(sp, Color(0, 1, 0));
*/

String GetAnimationDebugText(Node@ n)
{
    AnimatedModel@ model = n.GetComponent("AnimatedModel");
    if (model is null)
        return "";
    String debugText = "Debug-Animations:\n";
    for (uint i=0; i<model.numAnimationStates ; ++i)
    {
        AnimationState@ state = model.GetAnimationState(i);
        debugText +=  state.animation.name + " time=" + String(state.time) + " weight=" + String(state.weight) + "\n";
    }
    return debugText;
}

void AddDebugMark(DebugRenderer@ debug, const Vector3&in position, const Color&in color, float size=0.15f)
{
    Sphere sp;
    sp.Define(position, size);
    debug.AddSphere(sp, color, false);
}