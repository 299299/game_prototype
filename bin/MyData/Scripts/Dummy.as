// ==============================================
//
//    All Dummy Scripts but never used
//
// ==============================================

void SetComponentEnabled(const String&in boneName, const String&in componentName, bool bEnable)
{
    Node@ _node = sceneNode.GetChild(boneName, true);
    if (_node is null)
        return;
    Component@ comp = _node.GetComponent(componentName);
    if (comp is null)
        return;
    comp.enabled = bEnable;
}

float GetFootFrontDiff()
{
    Vector3 fwd_dir = renderNode.worldRotation * Vector3(0, 0, 1);
    Vector3 pt_lf = renderNode.GetChild("Bip01_L_Foot").worldPosition - renderNode.worldPosition;
    Vector3 pt_rf = renderNode.GetChild("Bip01_R_Foot").worldPosition - renderNode.worldPosition;
    float dot_lf = pt_lf.DotProduct(fwd_dir);
    float dot_rf = pt_rf.DotProduct(fwd_dir);
    LogPrint(sceneNode.name + " dot_lf=" + dot_lf + " dot_rf=" + dot_rf + " diff=" + (dot_lf - dot_rf));
    return dot_lf - dot_rf;
}

int GetAttackType(const String&in name)
{
    if (name.Contains("Foot") || name.Contains("Calf"))
        return ATTACK_KICK;
    return ATTACK_PUNCH;
}

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
        LogPrint(ownner.GetName() + " state:" + name + " finshed motion:" + motion.animationName);
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
    // LogPrint("Player::Evade()");

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
            LogPrint(name + " pick " + motions[selectIndex].animationName);
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

float FaceAngleDiff(Node@ thisNode, Node@ targetNode)
{
    Vector3 posDiff = targetNode.worldPosition - thisNode.worldPosition;
    Vector3 thisDir = thisNode.worldRotation * Vector3(0, 0, 1);
    float thisAngle = Atan2(thisDir.x, thisDir.z);
    float targetAngle = Atan2(posDiff.x, posDiff.y);
    return AngleDiff(targetAngle - thisAngle);
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

int DetectWallBlockingFoot()
{
    int ret = 0;
    Node@ footLeft = ownner.GetNode().GetChild(L_FOOT, true);
    Node@ foootRight = ownner.GetNode().GetChild(R_FOOT, true);
    PhysicsWorld@ world = ownner.GetScene().physicsWorld;
    Vector3 dir = ownner.GetNode().worldRotation * Vector3(0, 0, 1);
    Ray ray;
    ray.Define(footLeft.worldPosition, dir);
    float dist = 5.0f;
    PhysicsRaycastResult result = world.RaycastSingle(ray, dist, COLLISION_LAYER_LANDSCAPE);
    if (result.body !is null)
        ret ++;
    ray.Define(foootRight.worldPosition, dir);
    result = world.RaycastSingle(ray, dist, COLLISION_LAYER_LANDSCAPE);
    if (result.body !is null)
        ret ++;
    return ret;
}

Enemy@ PickRedirectEnemy()
{
    EnemyManager@ em = cast<EnemyManager>(GetScene().GetScriptObject("EnemyManager"));
    if (em is null)
        return null;

    Enemy@ redirectEnemy = null;
    const float bestRedirectDist = 5;
    const float maxRedirectDist = 7;
    const float maxDirDiff = 45;

    float myDir = GetCharacterAngle();
    float bestDistDiff = 9999;

    for (uint i=0; i<em.enemyList.length; ++i)
    {
        Enemy@ e = em.enemyList[i];
        if (!e.CanBeRedirected()) {
            LogPrint("Enemy " + e.GetName() + " can not be redirected.");
            continue;
        }

        float enemyDir = e.GetCharacterAngle();
        float totalDir = Abs(AngleDiff(myDir - enemyDir));
        float dirDiff = Abs(totalDir - 180);
        LogPrint("Evade-- myDir=" + myDir + " enemyDir=" + enemyDir + " totalDir=" + totalDir + " dirDiff=" + dirDiff);
        if (dirDiff > maxDirDiff)
            continue;

        float dist = GetTargetDistance(e.sceneNode.worldPosition);
        if (dist > maxRedirectDist)
            continue;

        dist = Abs(dist - bestRedirectDist);
        if (dist < bestDistDiff)
        {
            @redirectEnemy = e;
            dist = bestDistDiff;
        }
    }

    return redirectEnemy;
}

if (reflection)
{
    Node@ floorNode = gameScene.GetChild("floor", true);
    StaticModel@ floor = floorNode.GetComponent("StaticModel");
    String matName = "Materials/FloorPlane.xml";
    floor.material = cache.GetResource("Material", matName);
    // Set a different viewmask on the water plane to be able to hide it from the reflection camera
    floor.viewMask = 0x80000000;

    Camera@ camera = GetCamera();
    // Create a mathematical plane to represent the water in calculations
    Plane waterPlane = Plane(floorNode.worldRotation * Vector3(0.0f, 1.0f, 0.0f), floorNode.worldPosition);
    // Create a downward biased plane for reflection view clipping. Biasing is necessary to avoid too aggressive clipping
    Plane waterClipPlane = Plane(floorNode.worldRotation * Vector3(0.0f, 1.0f, 0.0f), floorNode.worldPosition - Vector3(0.0f, 0.1f, 0.0f));

    // Create camera for water reflection
    // It will have the same farclip and position as the main viewport camera, but uses a reflection plane to modify
    // its position when rendering
    Node@ reflectionCameraNode = camera.node.CreateChild("reflection");
    Camera@ reflectionCamera = reflectionCameraNode.CreateComponent("Camera");
    reflectionCamera.farClip = 750.0;
    reflectionCamera.viewMask = 0x7fffffff; // Hide objects with only bit 31 in the viewmask (the water plane)
    reflectionCamera.autoAspectRatio = false;
    reflectionCamera.useReflection = true;
    reflectionCamera.reflectionPlane = waterPlane;
    reflectionCamera.useClipping = true; // Enable clipping of geometry behind water plane
    reflectionCamera.clipPlane = waterClipPlane;
    // The water reflection texture is rectangular. Set reflection camera aspect ratio to match
    reflectionCamera.aspectRatio = float(graphics.width) / float(graphics.height);
    // View override flags could be used to optimize reflection rendering. For example disable shadows
    reflectionCamera.viewOverrideFlags = VO_DISABLE_SHADOWS | VO_DISABLE_OCCLUSION | VO_LOW_MATERIAL_QUALITY;

    // Create a texture and setup viewport for water reflection. Assign the reflection texture to the diffuse
    // texture unit of the water material
    int texSize = 1024;
    Texture2D@ renderTexture = Texture2D();
    renderTexture.SetSize(texSize, texSize, GetRGBFormat(), TEXTURE_RENDERTARGET);
    renderTexture.filterMode = FILTER_BILINEAR;
    RenderSurface@ surface = renderTexture.renderSurface;
    Viewport@ rttViewport = Viewport(gameScene, reflectionCamera);
    surface.viewports[0] = rttViewport;
    Material@ waterMat = cache.GetResource("Material", matName);
    waterMat.textures[TU_DIFFUSE] = renderTexture;
}

/*======================================= CROWD =======================================*/
if (use_agent)
{
    agent = sceneNode.CreateComponent("CrowdAgent");
    agent.height = CHARACTER_HEIGHT;
    agent.maxSpeed = 11.6f;
    agent.maxAccel = 6.0f;
    agent.updateNodePosition = false;
    agent.radius = COLLISION_RADIUS;
}


class ThugCrowdMoveState : SingleAnimationState
{
    Vector3 targetPosition;
    float turnSpeed = 10.0f;
    float attackRange;

    ThugCrowdMoveState(Character@ c)
    {
        super(c);
        flags = FLAGS_ATTACK | FLAGS_MOVING;
        looped = true;
    }

    void Update(float dt)
    {
        Vector3 distV = ownner.GetNode().worldPosition - targetPosition;
        distV.y = 0;
        float dist = distV.length;
        Print(ownner.GetName() + " dist=" + dist);
        if (dist <= COLLISION_SAFE_DIST)
        {
            ownner.ChangeState("StandState");
            return;
        }

        Vector3 velocity = ownner.agent.actualVelocity;
        float speed = velocity.length;
        float speedRatio = speed / ownner.agent.maxSpeed;
        Node@ _node = ownner.GetNode();
        // Face the direction of its velocity but moderate the turning speed based on the speed ratio and timeStep
        _node.worldRotation = _node.worldRotation.Slerp(Quaternion(Vector3::FORWARD, velocity), turnSpeed * dt * speedRatio);
        // Throttle the animation speed based on agent speed ratio (ratio = 1 is full throttle)
        ownner.animCtrl.SetSpeed(animation, speedRatio * 1.5f);

        SingleAnimationState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        SingleAnimationState::Enter(lastState);
        ownner.agent.updateNodePosition = true;
        attackRange = Random(0.2f, MAX_ATTACK_RANGE);
        targetPosition = ownner.target.GetNode().worldPosition;
        ownner.agent.targetPosition = targetPosition;
    }

    void Exit(State@ nextState)
    {
        ownner.agent.updateNodePosition = false;
        //ownner.agent.enabled = false;
        //ownner.agent.enabled = true;
        ownner.agent.ResetTarget();
        SingleAnimationState::Exit(nextState);
    }

    float GetThreatScore()
    {
        return 0.333f;
    }
};

CrowdManager@ crowdManager = scene_.GetComponent("CrowdManager");
if (crowdManager is null)
    crowdManager = scene_.CreateComponent("CrowdManager");
CrowdObstacleAvoidanceParams params = crowdManager.GetObstacleAvoidanceParams(0);
// Set the params to "High (66)" setting
params.velBias = 0.5f;
params.adaptiveDivs = 7;
params.adaptiveRings = 3;
params.adaptiveDepth = 3;
crowdManager.SetObstacleAvoidanceParams(0, params);

void HandleCrowdAgentFailure(StringHash eventType, VariantMap& eventData)
{
    Node@ node = eventData["Node"].GetPtr();
    int state = eventData["CrowdAgentState"].GetInt();

    LogPrint(node.name + " state = " + state);

    // If the agent's state is invalid, likely from spawning on the side of a box, find a point in a larger area
    if (state == CA_STATE_INVALID)
    {
        Scene@ scene_ = script.defaultScene;
        // Get a point on the navmesh using more generous extents
        Vector3 newPos = cast<DynamicNavigationMesh>(scene_.GetComponent("DynamicNavigationMesh")).FindNearestPoint(node.position, Vector3(5.0f,5.0f,5.0f));
        // Set the new node position, CrowdAgent component will automatically reset the state of the agent
        node.worldPosition = newPos;
    }
}

/*======================================= CROWD =======================================*/


// HitState

void FixedUpdate(float dt)
{
    Array<RigidBody@>@ neighbors = cast<Thug>(ownner).collisionBody.collidingBodies;
    for (uint i=0; i<neighbors.length; ++i)
    {
        Node@ n_node = neighbors[i].node.parent;
        if (n_node is null)
            continue;
        Character@ object = cast<Character>(n_node.scriptObject);
        if (object is null)
            continue;
        if (object.HasFlag(FLAGS_MOVING) || object.HasFlag(FLAGS_NO_MOVE))
            continue;

        float dist = ownner.GetTargetDistance(n_node);
        if (dist < 1.0f)
        {
            State@ state = ownner.GetState();
            if (state.nameHash == RUN_TO_TARGET_STATE ||
                state.nameHash == STAND_STATE)
            {
                object.ChangeState("PushBack");
            }
            LogPrint(object.GetName() + " DoPushBack !!");
            object.ChangeState("PushBack");
        }
    }
}

void CommonCollectEnemies(Array<Enemy@>@ enemies, float maxDiffAngle, float maxDiffDist, int flags)
{
    enemies.Clear();

    uint t = time.systemTime;
    Scene@ _scene = GetScene();
    EnemyManager@ em = GetEnemyMgr();
    if (em is null)
        return;

    Vector3 myPos = sceneNode.worldPosition;
    float targetAngle = GetTargetAngle();

    for (uint i=0; i<em.enemyList.length; ++i)
    {
        Enemy@ e = em.enemyList[i];
        if (!e.HasFlag(flags))
            continue;
        Vector3 posDiff = e.GetNode().worldPosition - myPos;
        posDiff.y = 0;
        int score = 0;
        float dist = posDiff.length;
        if (dist > maxDiffDist)
            continue;
        float enemyAngle = Atan2(posDiff.x, posDiff.z);
        float diffAngle = targetAngle - enemyAngle;
        diffAngle = AngleDiff(diffAngle);
        if (Abs(diffAngle) > maxDiffAngle)
            continue;
        enemies.Push(e);
    }

    LogPrint("CommonCollectEnemies() len=" + enemies.length + " time-cost = " + (time.systemTime - t) + " ms");
}

