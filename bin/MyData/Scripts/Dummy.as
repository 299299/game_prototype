// ==============================================
//
//    All Dummy Scripts but never used
//
// ==============================================

const StringHash ALIGN_STATE("AlignState");
const StringHash RUN_TO_TARGET_STATE("RunToTargetState");

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

int DetectWallBlockingFoot(float dist = 1.5f)
{
    int ret = 0;
    Node@ footLeft = sceneNode.GetChild(L_FOOT, true);
    Node@ foootRight = sceneNode.GetChild(R_FOOT, true);
    PhysicsWorld@ world = sceneNode.scene.physicsWorld;

    Vector3 dir = sceneNode.worldRotation * Vector3(0, 0, 1);
    Ray ray;
    ray.Define(footLeft.worldPosition, dir);
    PhysicsRaycastResult result = world.RaycastSingle(ray, dist, COLLISION_LAYER_LANDSCAPE);
    if (result.body !is null)
        ret ++;
    ray.Define(foootRight.worldPosition, dir);
    result = world.RaycastSingle(ray, dist, COLLISION_LAYER_LANDSCAPE);
    if (result.body !is null)
        ret ++;
    return ret;
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
        ownner.SetVelocity(Vector3::ZERO);

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


void DoubleCounter()
{
    Array<Motion@>@ motions = doubleMotions;
    float min_error_sqr = 9999;
    int s1 = -1, s2 = -2;
    int bestIndex = -1;
    Enemy@ e1 = counterEnemies[0];
    Enemy@ e2 = counterEnemies[1];
    Vector3 myPos = ownner.GetNode().worldPosition;
    Vector3 dir1 = (e1.GetNode().worldPosition - myPos);
    Vector3 dir2 = (e2.GetNode().worldPosition - myPos);
    float angle = dir1.Angle(dir2);
    Print("angle=" + angle);

    for (uint i=0; i<motions.length; ++i)
    {
        float error_sum_sqr = TestDoubleCounterMotions(i);
        if (error_sum_sqr < min_error_sqr)
        {
            s1 = cast<CharacterCounterState>(e1.GetState()).index;
            s2 = cast<CharacterCounterState>(e2.GetState()).index;
            min_error_sqr = error_sum_sqr;
            bestIndex = i;
        }
    }

    if (s1 < 0)
    {
        e1.CommonStateFinishedOnGroud();
        counterEnemies.Erase(0);
    }
    if (s2 < 0 && counterEnemies.length > 1)
    {
        e2.CommonStateFinishedOnGroud();
        counterEnemies.Erase(1);
    }

    if (bestIndex >= 0 && counterEnemies.length == 2)
    {
        TestDoubleCounterMotions(bestIndex);
    }

    StartAnimating();
}

void TripleCounter()
{
    Array<Motion@>@ motions = tripleMotions;
    float min_error_sqr = 9999;
    int s1 = -1, s2 = -1, s3 = -1;
    int bestIndex = -1;
    Enemy@ e1 = counterEnemies[0];
    Enemy@ e2 = counterEnemies[1];
    Enemy@ e3 = counterEnemies[2];

    for (uint i=0; i<motions.length; ++i)
    {
        float error_sum_sqr = TestTrippleCounterMotions(i);
        if (error_sum_sqr < min_error_sqr)
        {
            s1 = cast<CharacterCounterState>(e1.GetState()).index;
            s2 = cast<CharacterCounterState>(e2.GetState()).index;
            s3 = cast<CharacterCounterState>(e3.GetState()).index;
            min_error_sqr = error_sum_sqr;
            bestIndex = i;
        }
    }

    if (s1 < 0)
    {
        e1.CommonStateFinishedOnGroud();
        counterEnemies.Erase(0);
    }
    if (s2 < 0)
    {
        e2.CommonStateFinishedOnGroud();
        counterEnemies.Erase(1);
    }
    if (s3 < 0 && counterEnemies.length > 1)
    {
        e3.CommonStateFinishedOnGroud();
        counterEnemies.Erase(2);
    }

    if (bestIndex >= 0 && counterEnemies.length == 3)
    {
        TestTrippleCounterMotions(bestIndex);
    }

    StartAnimating();
}

float TestDoubleCounterMotions(int i)
{
    for (uint k=0; k<counterEnemies.length; ++k)
        cast<CharacterCounterState>(counterEnemies[k].GetState()).index = -1;

    CharacterCounterState@ s = cast<CharacterCounterState>(counterEnemies[0].GetState());
    Array<Motion@>@ motions = doubleMotions;
    Array<Motion@>@ enemy_motions = s.doubleMotions;
    @currentMotion = motions[i];
    Motion@ m1 = enemy_motions[i * 2 + 0];
    float err1 = ChooseBestIndices(m1, 0);
    Motion@ m2 = enemy_motions[i * 2 + 1];
    float err2 = ChooseBestIndices(m2, 1);
    return err1 + err2;
}

void StartAnimating()
{
    StartCounterMotion();
    gCameraMgr.CheckCameraAnimation(currentMotion.name);
    for (uint i=0; i<counterEnemies.length; ++i)
    {
        State@ state = counterEnemies[i].GetState();
        CharacterCounterState@ s = cast<CharacterCounterState>(state);
        s.StartAligning();
    }
}

void DoubleCounter()
{
    Node@ myNode = ownner.GetNode();
    float min_error_sqr = 9999;
    int bestIndex = -1;
    Enemy@ e1 = counterEnemies[0];
    Enemy@ e2 = counterEnemies[1];
    Node@ eNode1 = e1.GetNode();
    Node@ eNode2 = e2.GetNode();
    Vector3 myPos = ownner.GetNode().worldPosition;
    float myAngle = ownner.GetCharacterAngle();
    float eAngle1 = e1.GetCharacterAngle();
    float eAngle2 = e2.GetCharacterAngle();
    float eAngle1ToMyAngle = AngleDiff(eAngle1 - myAngle);
    float eAngle2ToMyAngle = AngleDiff(eAngle2 - myAngle);
    Print("myAngle=" + myAngle + " eAngle1=" + eAngle1 + " eAngle2=" + eAngle2 +
          " eAngle1ToMyAngle=" + eAngle1ToMyAngle + " eAngle2ToMyAngle=" + eAngle2ToMyAngle);
    CharacterCounterState@ s1 = cast<CharacterCounterState>(e1.GetState());
    CharacterCounterState@ s2 = cast<CharacterCounterState>(e2.GetState());
    Motion@ eMotion1, eMotion2;
    int who_is_reference = -1;
    g_int_cache.Clear();

    for (uint i=0; i<doubleMotions.length; ++i)
    {
        Motion@ playerMotion = doubleMotions[i];
        int index1 = i*2 + 0;
        int index2 = i*2 + 1;
        Motion@ motion1 = s1.doubleMotions[index1];
        Motion@ motion2 = s1.doubleMotions[index2];
        float motion1ToPlayerMotionAngle = (motion1.GetStartRot() - playerMotion.GetStartRot());
        float motion2ToPlayerMotionAngle = (motion2.GetStartRot() - playerMotion.GetStartRot());
        Print(playerMotion.name + " motion1ToPlayerMotionAngle=" + motion1ToPlayerMotionAngle + " motion2ToPlayerMotionAngle=" + motion2ToPlayerMotionAngle);

        float dAngle1 = Abs(AngleDiff(motion1ToPlayerMotionAngle - eAngle1ToMyAngle));
        float dAngle2 = Abs(AngleDiff(motion2ToPlayerMotionAngle - eAngle1ToMyAngle));
        if (dAngle1 < dAngle2)
        {
            @eMotion1 = motion1;
            @eMotion2 = motion2;
            g_int_cache.Push(index1);
            g_int_cache.Push(index2);
        }
        else
        {
            @eMotion1 = motion2;
            @eMotion2 = motion1;
            g_int_cache.Push(index2);
            g_int_cache.Push(index1);
        }

        // e1 as reference
        float err_player = GetTargetTransformErrorSqr(myNode, eNode1, playerMotion, eMotion1);
        float err_e = GetTargetTransformErrorSqr(eNode2, eNode1, eMotion2, eMotion1);
        float err_sum = err_player + err_e;
        if (err_sum < min_error_sqr)
        {
            bestIndex = i;
            who_is_reference = 0;
            min_error_sqr = err_sum;
        }

        // e2 as reference
        err_player = GetTargetTransformErrorSqr(myNode, eNode2, playerMotion, eMotion2);
        err_e = GetTargetTransformErrorSqr(eNode1, eNode2, eMotion1, eMotion2);
        err_sum = err_player + err_e;
        if (err_sum < min_error_sqr)
        {
            bestIndex = i;
            who_is_reference = 1;
            min_error_sqr = err_sum;
        }
    }

    Print("DoubleCounter bestIndex=" + bestIndex);

    if (bestIndex >= 0)
    {
        Node@ referenceNode = (who_is_reference == 0) ? eNode1 : eNode2;
        Node@ alignNode = (who_is_reference == 0) ? eNode2 : eNode1;
        CharacterCounterState@ referenceState = (who_is_reference == 0) ? s1 : s2;
        CharacterCounterState@ alignState = (who_is_reference == 0) ? s2 : s1;

        @currentMotion = doubleMotions[bestIndex];
        @s1.currentMotion = s1.doubleMotions[g_int_cache[bestIndex*2 + 0]];
        @s2.currentMotion = s1.doubleMotions[g_int_cache[bestIndex*2 + 1]];
        SetTargetTransform(GetTargetTransform(referenceNode, currentMotion, referenceState.currentMotion));
        StartAligning();
        referenceState.StartCounterMotion();
        alignState.SetTargetTransform(GetTargetTransform(referenceNode, alignState.currentMotion, referenceState.currentMotion));
        alignState.StartAligning();
    }
    else
    {
        counterEnemies.Erase(0);
    }
}

void StartAnimating()
{
    StartCounterMotion();
    gCameraMgr.CheckCameraAnimation(currentMotion.name);
    for (uint i=0; i<counterEnemies.length; ++i)
    {
        State@ state = counterEnemies[i].GetState();
        CharacterCounterState@ s = cast<CharacterCounterState>(state);
        s.StartAligning();
    }
}

float ChooseBestIndices(Motion@ alignMotion, int index)
{
    Vector4 v4 = GetTargetTransform(ownner.GetNode(), alignMotion, currentMotion);
    Vector3 v3 = Vector3(v4.x, 0.0f, v4.z);

    float minDistSQR = 999999;
    int possed = -1;

    for (uint i=0; i<counterEnemies.length; ++i)
    {
        Enemy@ e = counterEnemies[i];
        CharacterCounterState@ s = cast<CharacterCounterState>(e.GetState());

        if (s.index >= 0)
            continue;

        Vector3 ePos = e.GetNode().worldPosition;
        Vector3 diff = v3 - ePos;
        diff.y = 0;

        float disSQR = diff.lengthSquared;
        if (disSQR < minDistSQR)
        {
            minDistSQR = disSQR;
            possed = i;
        }
    }

    Enemy@ e = counterEnemies[possed];
    if (minDistSQR > GOOD_COUNTER_DIST * GOOD_COUNTER_DIST)
    {
        LogPrint(alignMotion.name + " too far, minDistSQR=" + minDistSQR);
        return 9999;
    }

    CharacterCounterState@ s = cast<CharacterCounterState>(e.GetState());
    @s.currentMotion = alignMotion;
    s.index = possed;
    s.SetTargetTransform(Vector3(v4.x, e.GetNode().worldPosition.y, v4.z), v4.w);
    return minDistSQR;
}

float TestTrippleCounterMotions(int i)
{
    for (uint k=0; k<counterEnemies.length; ++k)
        cast<CharacterCounterState>(counterEnemies[k].GetState()).index = -1;

    CharacterCounterState@ s = cast<CharacterCounterState>(counterEnemies[0].GetState());
    Array<Motion@>@ motions = tripleMotions;
    Array<Motion@>@ enemy_motions = s.tripleMotions;
    @currentMotion = motions[i];
    Motion@ m1 = enemy_motions[i * 3 + 0];
    float err1 = ChooseBestIndices(m1, 0);
    Motion@ m2 = enemy_motions[i * 3 + 1];
    float err2 = ChooseBestIndices(m2, 1);
    Motion@ m3 = enemy_motions[i * 3 + 2];
    float err3 = ChooseBestIndices(m3, 2);
    return err1 + err2 + err3;
}

// bruce counter
preFix = "BM_TG_Counter/";
Array<Motion@> counter_motions;
Array<String> prefixToIgnore = {"Double_Counter_", "Environment_Counter_"};
Global_CreateMotion_InFolder(preFix, prefixToIgnore, counter_motions);
const String arm_front_prefx = preFix + "Counter_Arm_Front";
const String leg_front_prefx = preFix + "Counter_Leg_Front";
const String arm_back_prefx = preFix + "Counter_Arm_Back";
const String leg_back_prefx = preFix + "Counter_Leg_Back";
for (uint i=0; i<counter_motions.length; ++i)
{
    Motion@ m = counter_motions[i];
    if (m.name.StartsWith(arm_front_prefx))
        bruce_counter_arm_front_motions.Push(m);
    else if (m.name.StartsWith(leg_front_prefx))
        bruce_counter_leg_front_motions.Push(m);
    else if (m.name.StartsWith(arm_back_prefx))
        bruce_counter_arm_back_motions.Push(m);
    else if (m.name.StartsWith(leg_back_prefx))
        bruce_counter_leg_back_motions.Push(m);
}

// thug counter
preFix = "TG_BM_Counter/";
Array<Motion@> counter_motions;
Array<String> prefixToIgnore = {"Double_Counter_", "Environment_Counter_"};
Global_CreateMotion_InFolder(preFix, prefixToIgnore, counter_motions);
const String arm_front_prefx = preFix + "Counter_Arm_Front";
const String leg_front_prefx = preFix + "Counter_Leg_Front";
const String arm_back_prefx = preFix + "Counter_Arm_Back";
const String leg_back_prefx = preFix + "Counter_Leg_Back";
for (uint i=0; i<counter_motions.length; ++i)
{
    Motion@ m = counter_motions[i];
    if (m.name.StartsWith(arm_front_prefx))
        thug_counter_arm_front_motions.Push(m);
    else if (m.name.StartsWith(leg_front_prefx))
        thug_counter_leg_front_motions.Push(m);
    else if (m.name.StartsWith(arm_back_prefx))
        thug_counter_arm_back_motions.Push(m);
    else if (m.name.StartsWith(leg_back_prefx))
        thug_counter_leg_back_motions.Push(m);
}

class ThugStunState : SingleAnimationState
{
    ThugStunState(Character@ ownner)
    {
        super(ownner);
        SetName("StunState");
        flags = FLAGS_STUN | FLAGS_ATTACK;
        SetMotion("TG_HitReaction/CapeHitReaction_Idle");
        looped = true;
        stateTime = 5.0f;
    }
};

class BruceRunTurn180State : PlayerRunTurn180State
{
    BruceRunTurn180State(Character@ c)
    {
        super(c);
        AddMotion("BM_Movement/Run_Right_Passing_To_Run_Right_180");
    }
};


// --------- BEAT

class ThugBeatDownHitState : MultiMotionState
{
    ThugBeatDownHitState(Character@ c)
    {
        super(c);
        SetName("BeatDownHitState");
        String preFix = "TG_BM_Beatdown/";
        for (uint i=1; i<=6; ++i)
            AddMotion(preFix + "Beatdown_HitReaction_0" + i);

        flags = FLAGS_STUN | FLAGS_ATTACK;
    }

    bool CanReEntered()
    {
        return true;
    }

    float GetThreatScore()
    {
        return 0.9f;
    }

    void OnMotionFinished()
    {
        // LogPrint(ownner.GetName() + " state:" + name + " finshed motion:" + motions[selectIndex].animationName);
        ownner.ChangeState("StunState");
    }
};

class ThugBeatDownEndState : MultiMotionState
{
    ThugBeatDownEndState(Character@ c)
    {
        super(c);
        SetName("BeatDownEndState");
        String preFix = "TG_BM_Beatdown/";
        for (uint i=1; i<=4; ++i)
            AddMotion(preFix + "Beatdown_Strike_End_0" + i);
        flags = FLAGS_ATTACK;
    }

    void Enter(State@ lastState)
    {
        ownner.SetHealth(0);
        MultiMotionState::Enter(lastState);
    }
};

class BruceBeatDownEndState : PlayerBeatDownEndState
{
    BruceBeatDownEndState(Character@ c)
    {
        super(c);
        String preFix = "BM_TG_Beatdown/";
        AddMotion(preFix + "Beatdown_Strike_End_01");
        AddMotion(preFix + "Beatdown_Strike_End_02");
        AddMotion(preFix + "Beatdown_Strike_End_03");
        AddMotion(preFix + "Beatdown_Strike_End_04");
    }
};

class BruceBeatDownHitState : PlayerBeatDownHitState
{
    BruceBeatDownHitState(Character@ c)
    {
        super(c);
        String preFix = "BM_Attack/";
        AddMotion(preFix + "Beatdown_Test_01");
        AddMotion(preFix + "Beatdown_Test_02");
        AddMotion(preFix + "Beatdown_Test_03");
        AddMotion(preFix + "Beatdown_Test_04");
        AddMotion(preFix + "Beatdown_Test_05");
        AddMotion(preFix + "Beatdown_Test_06");
    }

    bool IsTransitionNeeded(float curDist)
    {
        return curDist > BRUCE_TRANSITION_DIST + 0.5f;
    }
};

class PlayerBeatDownHitState : MultiMotionState
{
    int beatIndex = 0;
    int beatNum = 0;
    int maxBeatNum = 15;
    int minBeatNum = 7;
    int beatTotal = 0;
    bool attackPressed = false;

    Vector3 targetPosition;
    float targetRotation;

    PlayerBeatDownHitState(Character@ c)
    {
        super(c);
        SetName("BeatDownHitState");
        flags = FLAGS_ATTACK;
    }

    bool CanReEntered()
    {
        return true;
    }

    bool IsTransitionNeeded(float curDist)
    {
        return false;
    }

    void Update(float dt)
    {
        // LogPrint("PlayerBeatDownHitState::Update() " + dt);
        Character@ target = ownner.target;
        if (target is null)
        {
            ownner.CommonStateFinishedOnGroud();
            return;
        }

        if (gInput.IsInputActioned(kInputAttack))
            attackPressed = true;

        if (combatReady && attackPressed)
        {
            ++ beatIndex;
            ++ beatNum;
            beatIndex = beatIndex % motions.length;
            ownner.ChangeState("BeatDownHitState");
            return;
        }

        if (gInput.IsInputActioned(kInputCounter))
        {
            ownner.Counter();
            return;
        }

        MultiMotionState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        float curDist = ownner.GetTargetDistance();
        if (IsTransitionNeeded(curDist - COLLISION_SAFE_DIST))
        {
            ownner.ChangeStateQueue("TransitionState");
            PlayerTransitionState@ s = cast<PlayerTransitionState>(ownner.FindState(StringHash("TransitionState")));
            s.nextStateName = this.name;
            return;
        }

        attackPressed = false;
        if (lastState !is this)
        {
            beatNum = 0;
            beatTotal = RandomInt(minBeatNum, maxBeatNum);
        }
        int index = beatIndex;

        Character@ target = ownner.target;
        MultiMotionState@ s = cast<MultiMotionState>(ownner.target.FindState("BeatDownHitState"));
        Motion@ m1 = motions[index];
        Motion@ m2 = s.motions[index];

        Vector3 myPos = ownner.GetNode().worldPosition;
        if (lastState !is this && lastState.nameHash != ALIGN_STATE)
        {
            Vector3 dir = myPos - target.GetNode().worldPosition;
            float e_targetRotation = Atan2(dir.x, dir.z);
            target.GetNode().worldRotation = Quaternion(0, e_targetRotation, 0);
        }

        Vector4 t = GetTargetTransform(target.GetNode(), m1, m2);
        targetRotation = t.w;
        targetPosition = Vector3(t.x, myPos.y, t.z);
        if (lastState !is this && lastState.nameHash != ALIGN_STATE)
        {
            CharacterAlignState@ state = cast<CharacterAlignState>(ownner.FindState(ALIGN_STATE));
            state.Start(this.name, targetPosition, targetRotation, 0.1f);
            ownner.ChangeStateQueue("AlignState");
        }
        else
        {
            ownner.GetNode().worldRotation = Quaternion(0, targetRotation, 0);
            ownner.GetNode().worldPosition = targetPosition;
            target.GetNode().vars[ANIMATION_INDEX] = index;
            motions[index].Start(ownner);
            selectIndex = index;
            target.ChangeState("BeatDownHitState");
        }

        CharacterState::Enter(lastState);
    }

    void OnAnimationTrigger(AnimationState@ animState, const VariantMap&in eventData)
    {
        StringHash name = eventData[NAME].GetStringHash();
        if (name == IMPACT)
        {
            // LogPrint("BeatDownHitState On Impact");
            combatReady = true;
            Node@ boneNode = ownner.GetNode().GetChild(eventData[VALUE].GetString(), true);
            Vector3 position = ownner.GetNode().worldPosition;
            if (boneNode !is null)
                position = boneNode.worldPosition;
            ownner.SpawnParticleEffect(position, "Particle/SnowExplosionFade.xml", 5, 10.0f);
            ownner.SpawnParticleEffect(position, "Particle/HitSpark.xml", 0.5f, 0.4f);
            ownner.PlayRandomSound(0);

            ownner.OnAttackSuccess(ownner.target);

            if (beatNum >= beatTotal)
                ownner.ChangeState("BeatDownEndState");
            return;
        }
        CharacterState::OnAnimationTrigger(animState, eventData);
    }

    int PickIndex()
    {
        return beatIndex;
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        AddDebugMark(debug, targetPosition, TARGET_COLOR);
        DebugDrawDirection(debug, ownner.GetNode().worldPosition, targetRotation, YELLOW);
    }

    String GetDebugText()
    {
        return CharacterState::GetDebugText() +
        " current motion=" + motions[selectIndex].animationName +
        " combatReady=" + combatReady + " attackPressed=" + attackPressed;
    }
};

class PlayerBeatDownEndState : MultiMotionState
{
    PlayerBeatDownEndState(Character@ c)
    {
        super(c);
        SetName("BeatDownEndState");
    }

    void Enter(State@ lastState)
    {
        selectIndex = PickIndex();
        if (selectIndex >= int(motions.length))
        {
            LogPrint("ERROR: a large animation index=" + selectIndex + " name:" + ownner.GetName());
            selectIndex = 0;
        }

        if (cast<Player>(ownner).CheckLastKill())
            ownner.SetSceneTimeScale(LAST_KILL_SPEED);

        Character@ target = ownner.target;
        if (target !is null)
        {
            Motion@ m1 = motions[selectIndex];
            ThugBeatDownEndState@ state = cast<ThugBeatDownEndState>(target.FindState("BeatDownEndState"));
            Motion@ m2 = state.motions[selectIndex];
            Vector4 t = GetTargetTransform(target.GetNode(), m1, m2);
            ownner.Transform(Vector3(t.x, ownner.GetNode().worldPosition.y, t.z), Quaternion(0, t.w, 0));
            target.GetNode().vars[ANIMATION_INDEX] = selectIndex;
            target.ChangeState("BeatDownEndState");
        }

        if (d_log)
            LogPrint(ownner.GetName() + " state=" + name + " pick " + motions[selectIndex].animationName);
        motions[selectIndex].Start(ownner);

        CharacterState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        LogPrint("BeatDownEndState Exit!!");
        ownner.SetSceneTimeScale(1.0f);
        MultiMotionState::Exit(nextState);
    }

    int PickIndex()
    {
        return RandomInt(motions.length);
    }

    void OnAnimationTrigger(AnimationState@ animState, const VariantMap&in eventData)
    {
        StringHash name = eventData[NAME].GetStringHash();
        if (name == IMPACT)
        {
            Node@ boneNode = ownner.GetNode().GetChild(eventData[VALUE].GetString(), true);
            Vector3 position = ownner.GetNode().worldPosition;
            if (boneNode !is null)
                position = boneNode.worldPosition;
            ownner.SpawnParticleEffect(position, "Particle/SnowExplosionFade.xml", 5, 10.0f);
            ownner.SpawnParticleEffect(position, "Particle/HitSpark.xml", 0.5f, 0.5f);
            ownner.PlayRandomSound(1);
            combatReady = true;
            Character@ target = ownner.target;
            if (target !is null)
            {
                Vector3 dir = ownner.motion_startPosition - target.GetNode().worldPosition;
                dir.y = 0;
                target.OnDamage(ownner, position, dir, 9999, false);
                ownner.OnAttackSuccess(target);
            }
            return;
        }
        CharacterState::OnAnimationTrigger(animState, eventData);
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
