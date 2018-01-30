// ==============================================
//
//    Character Base Class
//
// ==============================================

class CharacterState : State
{
    Character@                  ownner;
    uint                        flags = 0;
    float                       animSpeed = 1.0f;
    float                       blendTime = 0.2f;
    float                       startTime = 0.0f;

    bool                        combatReady = false;
    bool                        firstUpdate = true;

    int                         physicsType = -1;
    int                         lastPhysicsType = -1;

    CharacterState(Character@ c)
    {
        @ownner = c;
    }

    ~CharacterState()
    {
        @ownner = null;
    }

    // animation events
    void OnAnimationTrigger(AnimationState@ animState, const VariantMap&in eventData)
    {
        StringHash name = eventData[NAME].GetStringHash();
        if (name == RAGDOLL_START)
            ownner.ChangeState("RagdollState");
        else if (name == COMBAT_SOUND)
            OnCombatSound(eventData[VALUE].GetString(), false);
        else if (name == COMBAT_SOUND_LARGE)
            OnCombatSound(eventData[VALUE].GetString(), true);
        else if (name == PARTICLE)
            OnCombatParticle(eventData[VALUE].GetString(), eventData[PARTICLE].GetString());
        else if (name == FOOT_STEP)
        {
            if (animState !is null && animState.weight > 0.5f)
                OnFootStep(eventData[VALUE].GetString());
        }
        else if (name == SOUND)
            ownner.PlaySound(eventData[VALUE].GetString());
        else if (name == CHANGE_STATE)
        {
            Print("Animation Event ChangeState");
            ownner.ChangeState(eventData[VALUE].GetString());
        }
        else if (name == IMPACT)
        {
            combatReady = true;
        }
        else if (name == READY_TO_FIGHT)
        {
            combatReady = true;
        }
        else if (name == TIME_SCALE)
        {
            float scale = eventData[VALUE].GetFloat();
            ownner.SetTimeScale(scale);
        }
    }

    // collision events
    void OnObjectCollision(GameObject@ otherObject, RigidBody@ otherBody, VariantMap& eventData)
    {
        if (otherBody.collisionLayer == COLLISION_LAYER_CHARACTER)
        {
            Character@ c = cast<Character>(otherObject);
            if (ownner.HasFlag(FLAGS_NO_MOVE))
                return;
            if (ownner.HasFlag(FLAGS_COLLISION_AVOIDENCE))
            {
                ownner.KeepDistanceWithCharacter(c);
            }
        }
        else if (otherBody.collisionLayer == COLLISION_LAYER_PROP || otherBody.collisionLayer == COLLISION_LAYER_RAGDOLL)
        {
            if (ownner.HasFlag(FLAGS_HIT_RAGDOLL))
                ownner.HitRagdoll(otherBody);
        }
    }

    // Logic Events
    void OnLogicEvent(VariantMap& eventData)
    {
    }

    // Event implementation
    void OnFootStep(const String&in boneName)
    {
        Node@ boneNode = ownner.GetNode().GetChild(boneName, true);
        if (boneNode !is null)
            return;
        Vector3 pos = boneNode.worldPosition;
        pos.y = 0.1f;
        ownner.SpawnParticleEffect(pos, "Particle/SnowExplosionFade.xml", 2, 2.5f);
    }

    void OnCombatSound(const String& boneName, bool large)
    {
        ownner.PlayRandomSound(large ? 1 : 0);

        Node@ boneNode = ownner.renderNode.GetChild(boneName, true);
        if (boneNode !is null)
            ownner.SpawnParticleEffect(boneNode.worldPosition, "Particle/SnowExplosionFade.xml", 5, 5.0f);

        CameraShake();
    }

    void OnCombatParticle(const String& boneName, const String& particleName)
    {
        Node@ boneNode = ownner.renderNode.GetChild(boneName, true);
        if (boneNode !is null)
            ownner.SpawnParticleEffect(boneNode.worldPosition,
                particleName.empty ? "Particle/SnowExplosionFade.xml" : particleName, 5, 5.0f);
    }

    float GetThreatScore()
    {
        return 0.0f;
    }

    void Enter(State@ lastState)
    {
        if (flags > 0)
            ownner.AddFlag(flags);
        if (physicsType >= 0)
        {
            lastPhysicsType = ownner.physicsType;
            ownner.SetPhysicsType(physicsType);
        }
        combatReady = false;
        firstUpdate = true;
        State::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        if (flags > 0)
            ownner.RemoveFlag(flags);
         if (physicsType >= 0)
            ownner.SetPhysicsType(lastPhysicsType);
        State::Exit(nextState);
    }

    void Update(float dt)
    {
        if (combatReady)
        {
            if (!ownner.IsInAir())
            {
                if (ownner.ActionCheck())
                    return;
            }
        }
        State::Update(dt);
        firstUpdate = false;
    }
};

class SingleAnimationState : CharacterState
{
    String animation;
    bool looped = false;
    float stateTime = -1;

    SingleAnimationState(Character@ c)
    {
        super(c);
    }

    void Update(float dt)
    {
        bool finished = false;
        if (looped)
        {
            if (stateTime > 0 && timeInState > stateTime)
                finished = true;
        }
        else
        {
            if (animSpeed < 0)
            {
                finished = ownner.animCtrl.GetTime(animation) < 0.0001f;
            }
            else
                finished = ownner.animCtrl.IsAtEnd(animation);
        }

        if (finished)
            OnMotionFinished();

        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        ownner.PlayAnimation(animation, LAYER_MOVE, looped, blendTime, startTime, animSpeed);
        CharacterState::Enter(lastState);
    }

    void OnMotionFinished()
    {
        ownner.CommonStateFinishedOnGroud();
    }

    void SetMotion(const String&in name)
    {
        animation = GetAnimationName(name);
    }
};


class SingleMotionState : CharacterState
{
    Motion@ motion;

    SingleMotionState(Character@ c)
    {
        super(c);
    }

    ~SingleMotionState()
    {
        @motion = null;
    }

    void Update(float dt)
    {
        if (motion.Move(ownner, dt) == 1)
            OnMotionFinished();
        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        motion.Start(ownner, startTime, blendTime, animSpeed);
        CharacterState::Enter(lastState);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        motion.DebugDraw(debug, ownner);
    }

    void SetMotion(const String&in name)
    {
        Motion@ m = gMotionMgr.FindMotion(name);
        if (m is null)
            return;
        @motion = m;
    }

    void OnMotionFinished()
    {
        // LogPrint(ownner.GetName() + " state:" + name + " finshed motion:" + motion.animationName);
        ownner.CommonStateFinishedOnGroud();
    }
};

class MultiAnimationState : CharacterState
{
    Array<String> animations;
    bool looped = false;
    float stateTime = -1;
    int selectIndex;

    MultiAnimationState(Character@ c)
    {
        super(c);
    }

    void Update(float dt)
    {
        bool finished = false;
        if (looped)
        {
            if (stateTime > 0 && timeInState > stateTime)
                finished = true;
        }
        else
        {
            if (animSpeed < 0)
            {
                finished = ownner.animCtrl.GetTime(animations[selectIndex]) < 0.0001f;
            }
            else
                finished = ownner.animCtrl.IsAtEnd(animations[selectIndex]);
        }

        if (finished)
            OnMotionFinished();

        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        selectIndex = PickIndex();
        ownner.PlayAnimation(animations[selectIndex], LAYER_MOVE, looped, blendTime, startTime, animSpeed);
        CharacterState::Enter(lastState);
    }

    void OnMotionFinished()
    {
        ownner.CommonStateFinishedOnGroud();
    }

    void AddMotion(const String&in name)
    {
        animations.Push(GetAnimationName(name));
    }

    int PickIndex()
    {
        return ownner.GetNode().vars[ANIMATION_INDEX].GetInt();
    }
};

class MultiMotionState : CharacterState
{
    Array<Motion@> motions;
    int selectIndex;

    MultiMotionState(Character@ c)
    {
        super(c);
    }

    ~MultiMotionState()
    {
        motions.Clear();
    }

    void Update(float dt)
    {
        int ret = motions[selectIndex].Move(ownner, dt);
        if (ret == 1)
            OnMotionFinished();
        else if (ret == 2)
            OnMotionAlignTimeOut();
        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        Start();
        CharacterState::Enter(lastState);
    }

    void Start()
    {
        selectIndex = PickIndex();
        if (selectIndex >= int(motions.length))
        {
            LogPrint("ERROR: a large animation index=" + selectIndex + " name:" + ownner.GetName() + " state:" + name);
            selectIndex = 0;
        }

        if (d_log)
            LogPrint(ownner.GetName() + " state=" + name + " pick " + motions[selectIndex].animationName);
        motions[selectIndex].Start(ownner, startTime, blendTime, animSpeed);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        motions[selectIndex].DebugDraw(debug, ownner);
    }

    int PickIndex()
    {
        return ownner.GetNode().vars[ANIMATION_INDEX].GetInt();
    }

    String GetDebugText()
    {
        return " name=" + name + " timeInState=" + timeInState + " current motion=" + motions[selectIndex].animationName + "\n";
    }

    void AddMotion(const String&in name)
    {
        Motion@ motion = gMotionMgr.FindMotion(name);
        if (motion is null)
            return;
        motions.Push(motion);
    }

    void OnMotionFinished()
    {
        // LogPrint(ownner.GetName() + " state:" + name + " finshed motion:" + motions[selectIndex].animationName);
        ownner.CommonStateFinishedOnGroud();
    }

    void OnMotionAlignTimeOut()
    {
    }
};

class AnimationTestState : CharacterState
{
    Array<Motion@>  testMotions;
    Array<String>   testAnimations;
    int             currentIndex;
    bool            allFinished;

    AnimationTestState(Character@ c)
    {
        super(c);
        SetName("AnimationTestState");
        // physicsType = 0;
    }

    ~AnimationTestState()
    {
        testMotions.Clear();
    }

    void Enter(State@ lastState)
    {
        Ragdoll@ rg = cast<Ragdoll>(ownner.GetNode().GetScriptObject("Ragdoll"));
        if (rg !is null)
            rg.ChangeState(RAGDOLL_NONE);
        currentIndex = 0;
        allFinished = false;
        Start();
        CharacterState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        if (nextState !is this)
            testMotions.Clear();
        CharacterState::Exit(nextState);
    }

    void Process(Array<String> animations)
    {
        testAnimations.Clear();
        testMotions.Clear();
        testAnimations.Resize(animations.length);
        testMotions.Resize(animations.length);
        for (uint i=0; i<animations.length; ++i)
        {
            testAnimations[i] = animations[i];
            @testMotions[i] = gMotionMgr.FindMotion(animations[i]);
            LogHint(ownner.GetName() + " test animation: " + animations[i]);
        }
    }

    void Start()
    {
        Motion@ motion = testMotions[currentIndex];
        blendTime = (currentIndex == 0) ? 0.2f : 0.0f;
        if (motion !is null)
        {
            motion.Start(ownner, startTime, blendTime, animSpeed);
            if (ownner.side == 1)
                gCameraMgr.CheckCameraAnimation(motion.name);
        }
        else
        {
            ownner.PlayAnimation(testAnimations[currentIndex], LAYER_MOVE, false, blendTime, startTime, animSpeed);
            if (ownner.side == 1)
                gCameraMgr.CheckCameraAnimation(testAnimations[currentIndex]);
        }
    }

    void Update(float dt)
    {
        if (allFinished)
        {
            //if (input.keyDown[KEY_RETURN])
                ownner.CommonStateFinishedOnGroud();
            return;
        }

        bool finished = false;
        bool dockAlignTimeOut = false;
        Motion@ motion = testMotions[currentIndex];
        if (motion !is null)
        {
            if (!motion.dockAlignBoneName.empty)
            {
                float t = ownner.animCtrl.GetTime(motion.animationName);
                if (t < motion.dockAlignTime && (t + dt) > motion.dockAlignTime)
                {
                    // ownner.SetSceneTimeScale(0.0f);
                }
            }

            int ret = motion.Move(ownner, dt);
            dockAlignTimeOut = (ret == 2);
            finished = (ret == 1);
            if (motion.looped && timeInState > 2.0f)
                finished = true;
        }
        else
        {
            if (animSpeed < 0)
            {
                finished = ownner.animCtrl.GetTime(testAnimations[currentIndex]) < 0.0001f;
            }
            else
                finished = ownner.animCtrl.IsAtEnd(testAnimations[currentIndex]);
        }

        if (finished)
            OnAnimationFinished();
        if (dockAlignTimeOut)
            OnDockAlignTimeOut();

        CharacterState::Update(dt);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        if (currentIndex >= int(testMotions.length))
            return;
        Motion@ motion = testMotions[currentIndex];
        if (motion !is null)
            motion.DebugDraw(debug, ownner);
    }

    String GetDebugText()
    {
        if (currentIndex >= int(testAnimations.length))
            return CharacterState::GetDebugText();
        return " name=" + this.name + " timeInState=" + timeInState + " animation=" + testAnimations[currentIndex] + "\n";
    }

    bool CanReEntered()
    {
        return true;
    }

    void OnAnimationFinished()
    {
        LogPrint("AnimationTestState finished, currentIndex=" + currentIndex);
        currentIndex ++;
        if (currentIndex >= int(testAnimations.length))
            allFinished = true;
        else
            Start();
    }

    void OnDockAlignTimeOut()
    {
        if (debug_draw_flag > 0)
            DebugPause(true);
    }
};

enum CounterSubState
{
    COUNTER_ALIGN,
    COUNTER_ANIMATING,
};

class CharacterCounterState : CharacterState
{
    Array<Motion@>@     frontArmMotions;
    Array<Motion@>@     frontLegMotions;
    Array<Motion@>@     backArmMotions;
    Array<Motion@>@     backLegMotions;
    Array<Motion@>@     doubleMotions;
    Array<Motion@>@     tripleMotions;
    Array<Motion@>@     environmentMotions;

    Motion@             currentMotion;
    int                 state; // sub state
    int                 index;

    float               alignTime = 0.2f;
    Vector3             movePerSec;
    float               yawPerSec;
    Vector3             targetPosition;
    float               targetRotation;

    CharacterCounterState(Character@ c)
    {
        super(c);
        SetName("CounterState");
    }

    ~CharacterCounterState()
    {
        @frontArmMotions = null;
        @frontLegMotions = null;
        @backArmMotions = null;
        @backLegMotions = null;
        @doubleMotions = null;
        @tripleMotions = null;
    }

    void StartCounterMotion()
    {
        if (currentMotion is null)
            return;
        LogPrint(ownner.GetName() + " start counter motion " + currentMotion.animationName);
        ChangeSubState(COUNTER_ANIMATING);
        currentMotion.Start(ownner);
    }

    void StartAligning()
    {
        if (currentMotion is null)
            return;
        ChangeSubState(COUNTER_ALIGN);
        currentMotion.Start(ownner);

        Vector3 diff = targetPosition - ownner.GetNode().worldPosition;
        diff.y = 0;
        movePerSec = diff / alignTime;

        float angleDiff = AngleDiff(targetRotation - ownner.GetCharacterAngle());
        yawPerSec = angleDiff / alignTime;

        ownner.motion_rotation = targetRotation;

        LogPrint(ownner.GetName() + " start align " + currentMotion.animationName +
                 " diff=" + diff.ToString() + " angleDiff=" + angleDiff);
    }

    int GetCounterDirection(int attackType, bool isBack)
    {
        if (attackType == ATTACK_PUNCH)
            return isBack ? 1 : 0;
        else
            return isBack ? 3 : 2;
    }

    Array<Motion@>@ GetCounterMotions(int attackType, bool isBack)
    {
        if (isBack)
            return attackType == ATTACK_PUNCH ? backArmMotions : backLegMotions;
        else
            return attackType == ATTACK_PUNCH ? frontArmMotions : frontLegMotions;
    }

    void DumpCounterMotions(Array<Motion@>@ motions)
    {
        for (uint i=0; i<motions.length; ++i)
        {
            Motion@ motion = motions[i];
            String other_name = motion.name.Replaced("BM_TG_Counter", "TG_BM_Counter");
            Motion@ other_motion = gMotionMgr.FindMotion(other_name);
            Vector3 startDiff = other_motion.GetStartPos() - motion.GetStartPos();
            LogPrint("couter-motion " + motion.name + " diff-len=" + startDiff.length);
        }
    }

    void Update(float dt)
    {
        if (currentMotion is null)
        {
            LogPrint("Error !!! ");
            DebugPause(true);
            return;
        }

        ownner.motion_velocity = (state == COUNTER_ALIGN) ? movePerSec : Vector3(0, 0, 0);
        if (state == COUNTER_ALIGN)
        {
            ownner.motion_deltaRotation += yawPerSec * dt;
            if (timeInState >= alignTime)
            {
                ChangeSubState(COUNTER_ANIMATING);
            }
        }

        if (currentMotion.Move(ownner, dt) == 1)
         {
            ownner.CommonStateFinishedOnGroud();
            return;
         }
        CharacterState::Update(dt);
    }

    void ChangeSubState(int newState)
    {
        if (state == newState)
            return;

        LogPrint(ownner.GetName() + " CounterState ChangeSubState from " + state + " to " + newState);
        state = newState;
    }

    void Dump()
    {
        DumpCounterMotions(frontArmMotions);
        DumpCounterMotions(backArmMotions);
        DumpCounterMotions(frontLegMotions);
        DumpCounterMotions(backLegMotions);
        DumpCounterMotions(doubleMotions);
        DumpCounterMotions(tripleMotions);
    }

    void SetTargetTransform(const Vector3&in pos, float rot)
    {
        Vector3 pos1 = ownner.GetNode().worldPosition;
        targetPosition = pos;
        targetPosition.y = pos1.y;
        targetRotation = rot;
    }

    void SetTargetTransform(const Vector4& vt)
    {
        SetTargetTransform(Vector3(vt.x, vt.y, vt.z), vt.w);
    }

    String GetDebugText()
    {
        return CharacterState::GetDebugText() + " current motion=" + currentMotion.animationName;
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        if (state == COUNTER_ALIGN)
        {
            DebugDrawDirection(debug, targetPosition, targetRotation, TARGET_COLOR, 2.0f);
            AddDebugMark(debug, targetPosition, TARGET_COLOR);
        }
    }
};

class CharacterRagdollState : CharacterState
{
    CharacterRagdollState(Character@ c)
    {
        super(c);
        SetName("RagdollState");
    }

    void Update(float dt)
    {
        if (timeInState > 0.1f)
        {
            int ragdoll_state = ownner.GetNode().vars[RAGDOLL_STATE].GetInt();
            if (ragdoll_state == RAGDOLL_NONE)
            {
                Vector3 vPos = ownner.GetNode().GetChild(PELVIS, true).worldPosition;
                if (vPos.y < -2.0f)
                {
                    LogPrint(ownner.GetName() + " fell out of world, kill me");
                    ownner.duration = 0;
                }
                else
                {
                    if (ownner.health > 0)
                    {
                        LogPrint(ownner.GetName() + " Finished Ragdoll PlayCurrentPose + getup.");
                        ownner.PlayCurrentPose();
                        ownner.ChangeState("GetUpState");
                    }
                    else
                    {
                        LogPrint(ownner.GetName() + " Finished Ragdoll dead.");
                        ownner.ChangeState("DeadState");
                    }
                }
            }
        }
        CharacterState::Update(dt);
    }

    void Enter(State@ lastState)
    {
        LogPrint(ownner.GetName() + " Enter RagdollState");
        CharacterState::Enter(lastState);
        ownner.SetPhysics(false);
    }

    void Exit(State@ nextState)
    {
        LogPrint(ownner.GetName() + " Exit RagdollState nextState is " + nextState.name);
        CharacterState::Exit(nextState);
    }
};

class CharacterGetUpState : MultiMotionState
{
    int                         state = 0;
    float                       ragdollToAnimTime = 0.0f;

    CharacterGetUpState(Character@ c)
    {
        super(c);
        SetName("GetUpState");
    }

    void Enter(State@ lastState)
    {
        LogPrint(ownner.GetName() + " get up.");

        state = 0;
        selectIndex = PickIndex();
        if (selectIndex >= int(motions.length))
        {
            LogPrint("ERROR: a large animation index=" + selectIndex + " name:" + ownner.GetName() + " state:" + name);
            selectIndex = 0;
        }

        Motion@ motion = motions[selectIndex];
        //if (blend_to_anim)
        //    ragdollToAnimTime = 0.2f;
        ownner.PlayAnimation(motion.animationName, LAYER_MOVE, false, ragdollToAnimTime, 0.0f, 0.0f);
        ownner.SetPhysics(true);
        CharacterState::Enter(lastState);
    }

    void Exit(State@ nextState)
    {
        MultiMotionState::Exit(nextState);
        ownner.animModel.updateInvisible = true;
    }

    void Update(float dt)
    {
        Motion@ motion = motions[selectIndex];
        if (state == 0)
        {
            if (timeInState >= ragdollToAnimTime)
            {
                ownner.animCtrl.SetSpeed(motion.animationName, 1.0f);
                motion.InnerStart(ownner);
                state = 1;
            }
        }
        else
        {
            if (motion.Move(ownner, dt) == 1)
            {
                ownner.CommonStateFinishedOnGroud();
                return;
            }
        }

        CharacterState::Update(dt);
    }
};

class Character : GameObject
{

    // ==============================================
    // AI
    // ==============================================
    CrowdAgent@             agent;
    Node@                   aiNode;
    int                     aiSyncMode;

    // ==============================================
    // LOGIC
    // ==============================================
    Character@              target;
    Vector3                 startPosition;
    Quaternion              startRotation;
    int                     health = INITIAL_HEALTH;
    float                   attackRadius = 0.15f;
    int                     attackDamage = 10;

    // ==============================================
    // ANIMATION
    // ==============================================
    Node@                   renderNode;
    String                  lastAnimation;
    Animation@              ragdollPoseAnim;
    AnimationController@    animCtrl;
    AnimatedModel@          animModel;

    // ==============================================
    // PHYSICS
    // ==============================================
    int                     physicsType;
    PhysicsMover@           mover;
    RigidBody@              collisionBody;

    // ==============================================
    //   DYNAMIC VALUES For Motion
    // ==============================================
    Vector3                 motion_startPosition;
    float                   motion_startRotation;

    float                   motion_deltaRotation;
    Vector3                 motion_deltaPosition;
    Vector3                 motion_velocity;

    float                   motion_rotation;

    bool                    motion_translateEnabled = true;
    bool                    motion_rotateEnabled = true;

    void ObjectStart()
    {
        GameObject::ObjectStart();
        renderNode = sceneNode.GetChild("RenderNode", false);

        // renderNode.scale = Vector3(BONE_SCALE, BONE_SCALE, BONE_SCALE);
        animCtrl = renderNode.GetComponent("AnimationController");
        animModel = renderNode.GetComponent("AnimatedModel");
        renderNode.GetChild(ScaleBoneName, true).scale = Vector3(BONE_SCALE, BONE_SCALE, BONE_SCALE);
        //animModel.skeleton.GetBone(ScaleBoneName).initialScale = Vector3(BONE_SCALE, BONE_SCALE, BONE_SCALE);
        //animModel.skeleton.GetBone(ScaleBoneName).animated = false;

        startPosition = sceneNode.worldPosition;
        startRotation = sceneNode.worldRotation;
        sceneNode.vars[TIME_SCALE] = 1.0f;

        String name = sceneNode.name + "_Ragdoll_Pose";
        ragdollPoseAnim = cache.GetResource("Animation", name);
        if (ragdollPoseAnim is null)
        {
            // LogPrint("Creating animation for ragdoll pose " + name);
            ragdollPoseAnim = Animation();
            ragdollPoseAnim.name = name;
            ragdollPoseAnim.animationName = name;
            cache.AddManualResource(ragdollPoseAnim);
        }

        if (big_head_mode)
        {
            renderNode.position = Vector3(0, 0.3f, 0);
        }

        if (one_shot_kill)
            attackDamage = 9999;

        CollisionShape@ shape = sceneNode.CreateComponent("CollisionShape");
        shape.SetCapsule(COLLISION_RADIUS*2, CHARACTER_HEIGHT, COLLISION_OFFSET);
        RigidBody@ body = sceneNode.CreateComponent("RigidBody");
        body.mass = 1.0f;
        body.angularFactor = Vector3::ZERO;
        body.collisionLayer = COLLISION_LAYER_CHARACTER;
        body.gravityOverride = Vector3(0, -20, 0);
        if (collision_type == 0)
        {
            body.kinematic = true;
            body.trigger = true;
            body.collisionMask = COLLISION_LAYER_CHARACTER | COLLISION_LAYER_RAGDOLL | COLLISION_LAYER_PROP;
            @mover = PhysicsMover(sceneNode);
            physicsType = 0;
        }
        else
        {
            body.collisionMask = COLLISION_LAYER_PROP | COLLISION_LAYER_LANDSCAPE;
            body.gravityOverride = Vector3(0, -20, 0);
            physicsType = 1;
        }
        body.collisionEventMode = COLLISION_ALWAYS;
        collisionBody = body;

        aiNode = sceneNode.scene.CreateChild(sceneNode.name + "_AI");
        agent = aiNode.CreateComponent("CrowdAgent");
        agent.height = CHARACTER_HEIGHT;
        agent.maxSpeed = 11.6f;
        agent.maxAccel = 6.0f;
        agent.updateNodePosition = false;
        agent.radius = COLLISION_RADIUS;

        SubscribeToEvent(sceneNode, "LogicEvent", "HandleLogicEvent");
        SubscribeToEvent(renderNode, "AnimationTrigger", "HandleAnimationTrigger");

        if (instant_collision)
            SubscribeToEvent(sceneNode, "NodeCollision", "HandleNodeCollision");

        animModel.RemoveAllAnimationStates();

        if (debug_mode == 5)
        {
            agent.enabled = false;
            collisionBody.enabled = false;
        }

        Reset();
    }

    void Stop()
    {
        aiNode.Remove();
        @aiNode = null;
        animModel.RemoveAllAnimationStates();
        @animCtrl = null;
        @animModel = null;
        @collisionBody = null;
        @agent = null;
        @target = null;
        @renderNode = null;
        mover.Remove();
        @mover = null;
        GameObject::Stop();
    }

    void Remove()
    {
        Stop();
        GameObject::Remove();
    }

    void SetTimeScale(float scale)
    {
        if (timeScale == scale)
            return;
        GameObject::SetTimeScale(scale);
        uint num = animModel.numAnimationStates;
        for (uint i=0; i<num; ++i)
        {
            AnimationState@ state = animModel.GetAnimationState(i);
            if (d_log)
                LogPrint("SetSpeed " + state.animation.name + " scale " + scale);
            animCtrl.SetSpeed(state.animation.name, scale);
        }

        sceneNode.vars[TIME_SCALE] = scale;
    }

    void PlayAnimation(const String&in animName, uint layer = LAYER_MOVE, bool loop = false, float blendTime = 0.1f, float startTime = 0.0f, float speed = 1.0f)
    {
        if (d_log)
            LogPrint(GetName() + " PlayAnimation " + animName + " loop=" + loop + " blendTime=" + blendTime + " startTime=" + startTime + " speed=" + speed);

        if (layer == LAYER_MOVE && lastAnimation == animName && loop)
            return;

        lastAnimation = animName;
        AnimationController@ ctrl = animCtrl;
        ctrl.StopLayer(layer, blendTime);
        ctrl.PlayExclusive(animName, layer, loop, blendTime);
        ctrl.SetSpeed(animName, speed * timeScale);
        ctrl.SetTime(animName, (speed < 0) ? ctrl.GetLength(animName) : startTime);
    }

    String GetDebugText()
    {
        String debugText = "name:" + sceneNode.name + " pos:" + sceneNode.worldPosition.ToString() + " timeScale:" + timeScale + " health:" + health + "\n";
        debugText += stateMachine.GetDebugText();
        if (animModel.numAnimationStates > 0)
        {
            debugText += "Debug-Animations:\n";
            for (uint i=0; i<animModel.numAnimationStates; ++i)
            {
                AnimationState@ state = animModel.GetAnimationState(i);
                if (state.weight > 0.0f && state.enabled)
                    debugText +=  state.animation.name + " time=" + String(state.time) + " weight=" + String(state.weight) + "\n";
            }
        }
        return debugText;
    }

    void MoveTo(const Vector3& position, float dt)
    {
        if (physicsType == 0)
        {
            if (mover !is null)
                mover.MoveTo(position, dt);
        }
        else
        {
            SetVelocity((position - sceneNode.worldPosition) / dt);
        }
    }

    bool Attack()
    {
        return false;
    }

    bool Counter()
    {
        return false;
    }

    bool Evade()
    {
        return false;
    }

    bool Redirect()
    {
        ChangeState("RedirectState");
        return false;
    }

    bool Distract()
    {
        return false;
    }

    void CommonStateFinishedOnGroud()
    {
        ChangeState("StandState");
    }

    void Reset()
    {
        flags = FLAGS_ATTACK;
        sceneNode.worldPosition = startPosition;
        sceneNode.worldRotation = startRotation;
        aiNode.worldPosition = startPosition;
        aiNode.worldRotation = startRotation;
        SetHealth(INITIAL_HEALTH);
        SetTimeScale(1.0f);
        ChangeState("StandState");
    }

    void SetHealth(int h)
    {
        health = h;
    }

    bool CanBeAttacked()
    {
        if (HasFlag(FLAGS_INVINCIBLE))
            return false;
        return HasFlag(FLAGS_ATTACK);
    }

    bool CanBeCountered()
    {
        return HasFlag(FLAGS_COUNTER);
    }

    bool CanAttack()
    {
        return false;
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        stateMachine.DebugDraw(debug);
        debug.AddNode(sceneNode, 1.0f, false);
        // debug.AddCircle(sceneNode.worldPosition, Vector3(0, 1, 0), COLLISION_RADIUS, Color(0.25f, 0.35f, 0.75f), 32, false);
        if (mover !is null)
            mover.DebugDraw(debug);
    }

    void TestAnimation(const Array<String>&in animations)
    {
        AnimationTestState@ state = cast<AnimationTestState>(stateMachine.FindState("AnimationTestState"));
        if (state is null)
            return;
        state.Process(animations);
        ChangeState("AnimationTestState");
    }

    void TestAnimation(const String&in animation)
    {
        Array<String> animations = { animation };
        TestAnimation(animations);
    }

    float GetTargetAngle()
    {
        return target !is null ? GetTargetAngle(target.GetNode()) : 0.0f;
    }

    float GetTargetDistance()
    {
        return target !is null ? GetTargetDistance(target.GetNode()) : 0.0f;
    }

    float ComputeAngleDiff()
    {
        return AngleDiff(GetTargetAngle() - GetCharacterAngle());
    }

    int RadialSelectAnimation(int numDirections)
    {
        return DirectionMapToIndex(ComputeAngleDiff(), numDirections);
    }

    float GetTargetAngle(Node@ _node)
    {
        return GetTargetAngle(_node.worldPosition);
    }

    float GetTargetDistance(Node@ _node)
    {
        return GetTargetDistance(_node.worldPosition);
    }

    float ComputeAngleDiff(Node@ _node)
    {
        return AngleDiff(GetTargetAngle(_node) - GetCharacterAngle());
    }

    float GetTargetAngle(Vector3 targetPos)
    {
        Vector3 diff = targetPos - sceneNode.worldPosition;
        return Atan2(diff.x, diff.z);
    }

    float GetTargetDistance(Vector3 targetPos)
    {
        Vector3 diff = targetPos - sceneNode.worldPosition;
        return diff.length;
    }

    float ComputeAngleDiff(Vector3 targetPos)
    {
        return AngleDiff(GetTargetAngle(targetPos) - GetCharacterAngle());
    }

    int RadialSelectAnimation(Node@ _node, int numDirections)
    {
        return DirectionMapToIndex(ComputeAngleDiff(_node), numDirections);
    }

    int RadialSelectAnimation(const Vector3& targetPos, int numDirections)
    {
        return DirectionMapToIndex(ComputeAngleDiff(targetPos), numDirections);
    }

    float GetCharacterAngle()
    {
        Vector3 characterDir = sceneNode.worldRotation * Vector3(0, 0, 1);
        return Atan2(characterDir.x, characterDir.z);
    }

    void PlayCurrentPose()
    {
        FillAnimationWithCurrentPose(ragdollPoseAnim, renderNode);
        AnimationState@ state = animModel.AddAnimationState(ragdollPoseAnim);
        state.weight = 1.0f;
        animCtrl.PlayExclusive(ragdollPoseAnim.name, LAYER_MOVE, false, 0.0f);
    }

    bool OnDamage(GameObject@ attacker, const Vector3&in position, const Vector3&in direction, int damage, bool weak = false)
    {
        ChangeState("HitState");
        return true;
    }

    void OnDead()
    {
        LogPrint(GetName() + " OnDead !!!");
        ChangeState("DeadState");
    }

    void MakeMeRagdoll(const Vector3&in velocity = Vector3(0, 0, 0), const Vector3&in position = Vector3(0, 0, 0))
    {
        LogPrint(GetName() + " MakeMeRagdoll -- velocity=" + velocity.ToString() + " position=" + position.ToString());
        VariantMap anim_data;
        anim_data[NAME] = RAGDOLL_START;
        anim_data[VELOCITY] = velocity;
        anim_data[POSITION] = position;
        VariantMap data;
        data[DATA] = anim_data;
        renderNode.SendEvent("AnimationTrigger", data);
    }

    void OnAttackSuccess(Character@ object)
    {
    }

    void OnCounterSuccess()
    {
    }

    void RequestDoNotMove()
    {
        AddFlag(FLAGS_NO_MOVE);
    }

    Node@ SpawnParticleEffect(const Vector3&in position, const String&in effectName, float duration, float scale = 1.0f)
    {
        Node@ newNode = sceneNode.scene.CreateChild("Effect");
        newNode.position = position;
        newNode.scale = Vector3(scale, scale, scale);

        // Create the particle emitter
        ParticleEmitter@ emitter = newNode.CreateComponent("ParticleEmitter");
        emitter.effect = cache.GetResource("ParticleEffect", effectName);

        // Create a GameObject for managing the effect lifetime. This is always local, so for server-controlled effects it
        // exists only on the server
        GameObject@ object = cast<GameObject>(newNode.CreateScriptObject(scriptFile, "GameObject", LOCAL));
        object.duration = duration;

        // LogPrint(GetName() + " SpawnParticleEffect pos=" + position.ToString() + " effectName=" + effectName + " duration=" + duration);

        return newNode;
    }

    Node@ SpawnSound(const Vector3&in position, const String&in soundName, float duration)
    {
        Node@ newNode = sceneNode.scene.CreateChild();
        newNode.position = position;

        // Create the sound source
        SoundSource3D@ source = newNode.CreateComponent("SoundSource3D");
        Sound@ sound = cache.GetResource("Sound", soundName);
        source.SetDistanceAttenuation(200, 5000, 1);
        source.Play(sound);

        // Create a GameObject for managing the sound lifetime
        GameObject@ object = cast<GameObject>(newNode.CreateScriptObject(scriptFile, "GameObject", LOCAL));
        object.duration = duration;

        return newNode;
    }

    void SetTarget(Character@ t)
    {
        if (t is target)
            return;
        @target = t;
        LogPrint(GetName() + " SetTarget=" + ((t !is null) ? t.GetName() : "null"));
    }

    void SetPhysics(bool b)
    {
        collisionBody.enabled = b;
        agent.enabled = b;
    }

    void PlayRandomSound(int type)
    {
        if (type == 0)
            PlaySound("Sfx/impact_" + (RandomInt(num_of_sounds) + 1) + ".ogg");
        else if (type == 1)
            PlaySound("Sfx/big_" + (RandomInt(num_of_big_sounds) + 1) + ".ogg");
    }

    bool ActionCheck(uint actionFlags = 0xFF)
    {
        return false;
    }

    bool IsVisible()
    {
        return animModel.IsInView(gCameraMgr.GetCamera());
    }

    void CheckAvoidance(float dt)
    {
    }

    void ClearAvoidance()
    {
    }

    bool CheckRagdollHit()
    {
        return false;
    }

    void CheckTargetDistance(Character@ t, float dist = KEEP_TARGET_DISTANCE)
    {
        if (t is null)
            return;
        if (motion_translateEnabled && GetTargetDistance(t.GetNode()) < dist)
        {
            if (d_log)
                LogPrint(GetName() + " is too close to " + t.GetName() + " set translateEnabled to false");
            motion_translateEnabled = false;
        }
    }

    bool IsInAir()
    {
        Vector3 lf_pos = renderNode.GetChild(L_FOOT, true).worldPosition;
        Vector3 rf_pos = renderNode.GetChild(R_FOOT, true).worldPosition;
        Vector3 myPos = sceneNode.worldPosition;
        float lf_to_ground = (lf_pos.y - myPos.y);
        float rf_to_graound = (rf_pos.y - myPos.y);
        return lf_to_ground > IN_AIR_FOOT_HEIGHT || rf_to_graound > IN_AIR_FOOT_HEIGHT;
    }

    void SetHeight(float height)
    {
        CollisionShape@ shape = sceneNode.GetComponent("CollisionShape");
        if (shape !is null)
        {
            shape.size = Vector3(COLLISION_RADIUS * 2, height, 0);
            shape.SetTransform(Vector3(0.0f, height/2, 0.0f), Quaternion());
        }
    }

    Node@ GetTargetSightBlockedNode(const Vector3&in targetPos)
    {
        Vector3 my_mid_pos = sceneNode.worldPosition;
        my_mid_pos.y += CHARACTER_HEIGHT/2;
        Vector3 target_mid_pos = targetPos;
        target_mid_pos.y += CHARACTER_HEIGHT/2;
        Vector3 dir = target_mid_pos - my_mid_pos;
        dir.y = 0;
        float l = dir.length;
        Vector3 dir_normalized = dir.Normalized();
        float offset = (COLLISION_RADIUS + 0.1f + SPHERE_CAST_RADIUS);
        my_mid_pos += dir_normalized * offset;
        float rayDistance = l - offset;
        if (rayDistance < 0)
            return null;
        PhysicsRaycastResult result = PhysicsSphereCast(my_mid_pos, dir_normalized, SPHERE_CAST_RADIUS, rayDistance, COLLISION_LAYER_CHARACTER, false);
        if (result.body is null)
            return null;
        Node@ node = result.body.node;
        if (node.scriptObject is null)
            return node.parent;
        return node;
    }

    bool IsDead()
    {
        return (health == 0);
    }

    void KeepDistanceWithCharacter(Character@ c)
    {
    }

    void HitRagdoll(RigidBody@ rb)
    {
    }

    // ===============================================================================================
    //  PHYSICS
    // ===============================================================================================
    void SetPhysicsType(int type)
    {
        if (physicsType == type)
            return;
        physicsType = type;
        if (collisionBody !is null)
        {
            collisionBody.kinematic = (physicsType == 0);
            collisionBody.trigger = (physicsType == 0);
            if (physicsType == 0)
                collisionBody.collisionMask = COLLISION_LAYER_CHARACTER | COLLISION_LAYER_RAGDOLL | COLLISION_LAYER_PROP;
            else
                collisionBody.collisionMask = COLLISION_LAYER_PROP | COLLISION_LAYER_LANDSCAPE;
        }
    }

    void SetVelocity(const Vector3&in vel)
    {
        // Print(GetName() + " SetVelocity = " + vel.ToString());
        if (collisionBody !is null)
            collisionBody.linearVelocity = vel;
    }

    Vector3 GetVelocity()
    {
        return collisionBody!is null ? collisionBody.linearVelocity : Vector3(0, 0, 0);
    }

    // ===============================================================================================
    //  EVENT HANDLERS
    // ===============================================================================================
    void HandleAnimationTrigger(StringHash eventType, VariantMap& eventData)
    {
        AnimationState@ state = animModel.animationStates[eventData[NAME].GetString()];
        CharacterState@ cs = cast<CharacterState>(stateMachine.currentState);
        if (cs !is null)
            cs.OnAnimationTrigger(state, eventData[DATA].GetVariantMap());
    }

    void ObjectCollision(GameObject@ otherObject, RigidBody@ otherBody, VariantMap& eventData)
    {
        CharacterState@ cs = cast<CharacterState>(stateMachine.currentState);
        if (cs !is null)
            cs.OnObjectCollision(otherObject, otherBody, eventData);
    }

    void HandleLogicEvent(StringHash eventType, VariantMap& eventData)
    {
        CharacterState@ cs = cast<CharacterState>(stateMachine.currentState);
        if (cs !is null)
            cs.OnLogicEvent(eventData);
    }

    void Update(float dt)
    {
        // Print("Update dt=" + dt);
        GameObject::Update(dt);

        if (aiSyncMode == 0)
        {
            aiNode.worldPosition = sceneNode.worldPosition;
        }
    }

    void FixedUpdate(float dt)
    {
        // Print("FixedUpdate dt=" + dt);
        if (mover !is null)
            mover.DetectGround();
        GameObject::FixedUpdate(dt);
    }
};

int DirectionMapToIndex(float directionDifference, int numDirections)
{
    float directionVariable = Floor(directionDifference / (180 / (numDirections / 2)) + 0.5f);
    // since the range of the direction variable is [-3, 3] we need to map negative
    // values to the animation index range in our selector which is [0,7]
    if( directionVariable < 0 )
        directionVariable += numDirections;
    return int(directionVariable);
}

int GetDirectionZone(const Vector3&in from, const Vector3& to, int numDirections, float fromAngle = 0.0f)
{
    Vector3 dir = to - from;
    float angle = Atan2(dir.x, dir.z) - fromAngle;
    return DirectionMapToIndex(AngleDiff(angle), numDirections);
}

Node@ CreateCharacter(const String&in name, const String&in objectName, const String&in scriptClass, const Vector3&in position, const Quaternion& rotation)
{
    XMLFile@ xml = cache.GetResource("XMLFile", "Objects/" + objectName + ".xml");
    Node@ p_node = script.defaultScene.InstantiateXML(xml, position, rotation);
    p_node.name = name;
    p_node.CreateScriptObject(scriptFile, scriptClass);
    p_node.CreateScriptObject(scriptFile, "Ragdoll");
    p_node.CreateScriptObject(scriptFile, "HeadIndicator");
    return p_node;
}