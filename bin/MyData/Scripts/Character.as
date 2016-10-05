// ==============================================
//
//    Character Base Class
//
// ==============================================

const float COLLISION_RADIUS = 0.75f;
const float CHARACTER_HEIGHT = 4.5f;

const StringHash TURN_STATE("TurnState");
const StringHash RUN_STATE("RunState");
const StringHash STAND_STATE("StandState");
const StringHash ALIGN_STATE("AlignState");

const StringHash ANIMATION_INDEX("AnimationIndex");
const StringHash TIME_SCALE("TimeScale");
const StringHash DATA("Data");
const StringHash NAME("Name");
const StringHash ANIMATION("Animation");
const StringHash STATE("State");
const StringHash VALUE("Value");
const StringHash BONE("Bone");
const StringHash NODE("Node");
const StringHash PARTICLE("Particle");
const StringHash DURATION("Duration");
const StringHash FOOT_STEP("FootStep");
const StringHash CHANGE_STATE("ChangeState");
const StringHash SOUND("Sound");
const StringHash RANGE("Range");
const StringHash TAG("Tag");

class CharacterState : State
{
    Character@                  ownner;
    int                         flags;
    float                       animSpeed = 1.0f;
    float                       blendTime = 0.2f;
    float                       startTime = 0.0f;

    bool                        firstUpdate = true;

    int                         lastPhysicsType = 0;
    int                         physicsType = -1;

    CharacterState(Character@ c)
    {
        @ownner = c;
    }

    ~CharacterState()
    {
        @ownner = null;
    }

    void OnAnimationTrigger(AnimationState@ animState, const VariantMap&in eventData)
    {
        StringHash name = eventData[NAME].GetStringHash();
        if (name == PARTICLE)
            OnParticle(eventData[VALUE].GetString(), eventData[PARTICLE].GetString());
        else if (name == FOOT_STEP)
        {
            if (animState !is null && animState.weight > 0.5f)
                OnFootStep(eventData[VALUE].GetString());
        }
        else if (name == SOUND)
            ownner.PlaySound(eventData[VALUE].GetString());
        else if (name == CHANGE_STATE)
            ownner.ChangeState(eventData[VALUE].GetStringHash());
    }

    void OnFootStep(const String&in boneName)
    {
        Node@ boneNode = ownner.GetNode().GetChild(boneName, true);
        if (boneNode !is null)
            return;
        Vector3 pos = boneNode.worldPosition;
        pos.y = 0.1f;
        ownner.SpawnParticleEffect(pos, "Particle/SnowExplosionFade.xml", 2, 2.5f);
    }

    void OnParticle(const String& boneName, const String& particleName)
    {
        Node@ boneNode = ownner.renderNode.GetChild(boneName, true);
        if (boneNode !is null)
            ownner.SpawnParticleEffect(boneNode.worldPosition,
                particleName.empty ? "Particle/SnowExplosionFade.xml" : particleName, 5, 5.0f);
    }

    void Enter(State@ lastState)
    {
        if (flags >= 0)
            ownner.AddFlag(flags);
        State::Enter(lastState);
        firstUpdate = true;

        if (physicsType >= 0)
        {
            lastPhysicsType = ownner.physicsType;
            ownner.SetPhysicsType(physicsType);
        }
    }

    void Exit(State@ nextState)
    {
        if (flags >= 0)
            ownner.RemoveFlag(flags);
        State::Exit(nextState);
        if (physicsType >= 0)
            ownner.SetPhysicsType(lastPhysicsType);
    }

    void Update(float dt)
    {
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
        // Print(ownner.GetName() + " state:" + name + " finshed motion:" + motion.animationName);
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
            Print("ERROR: a large animation index=" + selectIndex + " name:" + ownner.GetName());
            selectIndex = 0;
        }

        if (d_log)
            Print(ownner.GetName() + " state=" + name + " pick " + motions[selectIndex].animationName);
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
        // Print(ownner.GetName() + " state:" + name + " finshed motion:" + motions[selectIndex].animationName);
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
        physicsType = 0;
    }

    void Enter(State@ lastState)
    {
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
        }
    }

    void Start()
    {
        Motion@ motion = testMotions[currentIndex];
        blendTime = (currentIndex == 0) ? 0.2f : 0.0f;
        if (motion !is null)
            motion.Start(ownner, startTime, blendTime, animSpeed);
        else
            ownner.PlayAnimation(testAnimations[currentIndex], LAYER_MOVE, false, blendTime, startTime, animSpeed);
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

            finished = motion.Move(ownner, dt) == 1;
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

        if (finished) {
            Print("AnimationTestState finished, currentIndex=" + currentIndex);
            currentIndex ++;
            if (currentIndex >= int(testAnimations.length))
            {
                //ownner.CommonStateFinishedOnGroud();
                allFinished = true;
            }
            else
                Start();
        }

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
};

class CharacterAlignState : CharacterState
{
    StringHash  nextStateName;
    String      alignAnimation;
    Vector3     targetPosition;
    float       targetRotation;
    Vector3     movePerSec;
    float       rotatePerSec;
    float       alignTime = 0.2f;

    CharacterAlignState(Character@ c)
    {
        super(c);
        SetName("AlignState");
    }

    void Start(StringHash nextState, const Vector3&in tPos, float tRot, float duration, int physicsType = 0, const String&in anim = "")
    {
        Print("CharacterAlign--start duration=" + duration);
        nextStateName = nextState;
        targetPosition = tPos;
        targetRotation = tRot;
        alignTime = duration;
        alignAnimation = anim;
        ownner.SetPhysicsType(physicsType);

        Vector3 curPos = ownner.GetNode().worldPosition;
        float curAngle = ownner.GetCharacterAngle();
        movePerSec = (tPos - curPos) / duration;
        rotatePerSec = AngleDiff(tRot - curAngle) / duration;

        if (anim != "")
        {
            Print("align-animation : " + anim);
            ownner.PlayAnimation(anim, LAYER_MOVE, true);
        }
    }

    void Update(float dt)
    {
        if (ownner.physicsType == 0)
            ownner.MoveTo(ownner.GetNode().worldPosition + movePerSec * dt, dt);
        else
            ownner.SetVelocity(movePerSec);
        ownner.GetNode().Yaw(rotatePerSec * dt);
        CharacterState::Update(dt);
        if (timeInState >= alignTime)
            OnAlignTimeOut();
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        DebugDrawDirection(debug, ownner.GetNode().worldPosition, targetRotation, RED, 2.0f);
        debug.AddCross(targetPosition, 0.5f, YELLOW, false);
    }

    void OnAlignTimeOut()
    {
        Print(ownner.GetName() + " On_Align_Finished-- at: " + time.systemTime);
        ownner.Transform(targetPosition, Quaternion(0, targetRotation, 0));
        ownner.ChangeState(nextStateName);
    }
};

class Character : GameObject
{
    FSM@                    stateMachine = FSM();

    Character@              target;

    Node@                   renderNode;

    AnimationController@    animCtrl;
    AnimatedModel@          animModel;

    Vector3                 startPosition;
    Quaternion              startRotation;

    RigidBody@              body;

    int                     physicsType;

    String                  lastAnimation;

    PhysicsSensor@          sensor;

    // ==============================================
    //   DYNAMIC VALUES For Motion
    // ==============================================
    Vector3                 motion_startPosition;
    float                   motion_startRotation;

    float                   motion_deltaRotation;
    Vector3                 motion_deltaPosition;
    Vector3                 motion_velocity;

    bool                    motion_translateEnabled = true;
    bool                    motion_rotateEnabled = true;

    void ObjectStart()
    {
        uint startTime = time.systemTime;

        GameObject::ObjectStart();

        renderNode = sceneNode.GetChild("RenderNode", false);
        animCtrl = renderNode.GetComponent("AnimationController");
        animModel = renderNode.GetComponent("AnimatedModel");

        startPosition = sceneNode.worldPosition;
        startRotation = sceneNode.worldRotation;
        sceneNode.vars[TIME_SCALE] = 1.0f;

        body = sceneNode.CreateComponent("RigidBody");
        body.collisionLayer = COLLISION_LAYER_CHARACTER;
        body.collisionMask = COLLISION_LAYER_LANDSCAPE | COLLISION_LAYER_PROP;
        body.mass = 1.0f;
        body.angularFactor = Vector3(0.0f, 0.0f, 0.0f);
        body.collisionEventMode = COLLISION_ALWAYS;
        CollisionShape@ shape = sceneNode.CreateComponent("CollisionShape");
        shape.SetCapsule(COLLISION_RADIUS*2, CHARACTER_HEIGHT, Vector3(0.0f, CHARACTER_HEIGHT/2, 0.0f));
        physicsType = 1;
        SetGravity(Vector3(0, -20, 0));

        SubscribeToEvent(renderNode, "AnimationTrigger", "HandleAnimationTrigger");

        Print(sceneNode.name + " ObjectStart time-cost=" + String(time.systemTime - startTime) + " ms");
    }

    void Stop()
    {
        Print("Character::Stop " + sceneNode.name);
        @stateMachine = null;
        @animCtrl = null;
        @animModel = null;
        @target = null;
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
                Print("SetSpeed " + state.animation.name + " scale " + scale);
            animCtrl.SetSpeed(state.animation.name, scale);
        }
        if (body !is null)
            body.linearVelocity = body.linearVelocity * scale;

        sceneNode.vars[TIME_SCALE] = scale;
    }

    void PlayAnimation(const String&in animName, uint layer = LAYER_MOVE, bool loop = false, float blendTime = 0.2f, float startTime = 0.0f, float speed = 1.0f)
    {
        if (d_log)
            Print(GetName() + " PlayAnimation " + animName + " loop=" + loop + " blendTime=" + blendTime + " startTime=" + startTime + " speed=" + speed);

        if (layer == LAYER_MOVE && lastAnimation == animName && loop)
            return;

        AnimationController@ ctrl = animCtrl;
        // ctrl.Stop(lastAnimation, blendTime);
        ctrl.PlayExclusive(animName, layer, loop, blendTime);
        ctrl.SetSpeed(animName, speed * timeScale);
        ctrl.SetTime(animName, (speed < 0) ? ctrl.GetLength(animName) : startTime);
        lastAnimation = animName;
    }

    String GetDebugText()
    {
        if (sceneNode is null)
            return "";

        String debugText = stateMachine.GetDebugText();
        debugText += "name:" + sceneNode.name + " pos:" + sceneNode.worldPosition.ToString() + " timeScale:" + timeScale + "\n";
        if (animModel.numAnimationStates > 0)
        {
            debugText += "Debug-Animations:\n";
            for (uint i=0; i<animModel.numAnimationStates; ++i)
            {
                AnimationState@ state = animModel.GetAnimationState(i);
                if (animCtrl.IsPlaying(state.animation.name))
                    debugText +=  state.animation.name + " time=" + String(state.time) + " weight=" + String(state.weight) + "\n";
            }
        }
        return debugText;
    }

    void SetVelocity(const Vector3&in vel)
    {
        // Print("body.linearVelocity = " + vel.ToString());
        if (body !is null)
            body.linearVelocity = vel;
    }

    Vector3 GetVelocity()
    {
        return body !is null ? body.linearVelocity : Vector3(0, 0, 0);
    }

    void MoveTo(const Vector3& position, float dt)
    {
        sceneNode.worldPosition = position;
    }

    void CommonStateFinishedOnGroud()
    {
        ChangeState("StandState");
    }

    void Reset()
    {
        flags = 0;
        sceneNode.worldPosition = startPosition;
        sceneNode.worldRotation = startRotation;
        SetTimeScale(1.0f);
        ChangeState("StandState");
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        stateMachine.DebugDraw(debug);
        debug.AddNode(sceneNode, 0.5f, false);
    }

    void TestAnimation(const Array<String>&in animations)
    {
        AnimationTestState@ state = cast<AnimationTestState>(stateMachine.FindState("AnimationTestState"));
        if (state is null)
        {
            Print("Can not find animation test state");
            return;
        }
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
        Vector3 targetPos = _node.worldPosition;
        Vector3 myPos = sceneNode.worldPosition;
        Vector3 diff = targetPos - myPos;
        return Atan2(diff.x, diff.z);
    }

    float GetTargetDistance(Node@ _node)
    {
        Vector3 targetPos = _node.worldPosition;
        Vector3 myPos = sceneNode.worldPosition;
        Vector3 diff = targetPos - myPos;
        return diff.length;
    }

    float ComputeAngleDiff(Node@ _node)
    {
        return AngleDiff(GetTargetAngle(_node) - GetCharacterAngle());
    }

    int RadialSelectAnimation(Node@ _node, int numDirections)
    {
        return DirectionMapToIndex(ComputeAngleDiff(_node), numDirections);
    }

    float GetCharacterAngle()
    {
        Vector3 characterDir = sceneNode.worldRotation * Vector3(0, 0, 1);
        return Atan2(characterDir.x, characterDir.z);
    }

    String GetName()
    {
        return sceneNode.name;
    }

    Node@ GetNode()
    {
        return sceneNode;
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

        // Print(GetName() + " SpawnParticleEffect pos=" + position.ToString() + " effectName=" + effectName + " duration=" + duration);

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

    void SetNodeEnabled(const String&in nodeName, bool bEnable)
    {
        Node@ n = sceneNode.GetChild(nodeName, true);
        if (n !is null)
            n.enabled = bEnable;
    }

    State@ GetState()
    {
        return stateMachine.currentState;
    }

    bool IsInState(const String&in name)
    {
        return IsInState(StringHash(name));
    }

    bool IsInState(const StringHash&in nameHash)
    {
        State@ state = stateMachine.currentState;
        if (state is null)
            return false;
        return state.nameHash == nameHash;
    }

    bool ChangeState(const String&in name)
    {
        if (d_log)
        {
            String oldStateName = stateMachine.currentState !is null ? stateMachine.currentState.name : "null";
            Print(GetName() + " ChangeState from " + oldStateName + " to " + name);
        }
        bool ret = stateMachine.ChangeState(name);
        State@ s = GetState();
        if (s is null)
            return ret;
        sceneNode.vars[STATE] = s.nameHash;
        return ret;
    }

    bool ChangeState(const StringHash&in nameHash)
    {
        String oldStateName = stateMachine.currentState !is null ? stateMachine.currentState.name : "null";
        bool ret = stateMachine.ChangeState(nameHash);
        String newStateName = stateMachine.currentState !is null ? stateMachine.currentState.name : "null";
        if (d_log)
            Print(GetName() + " ChangedState from " + oldStateName + " to " + newStateName);
        sceneNode.vars[STATE] = GetState().nameHash;
        return ret;
    }

    void ChangeStateQueue(const StringHash&in nameHash)
    {
        stateMachine.ChangeStateQueue(nameHash);
    }

    State@ FindState(const String&in name)
    {
        return stateMachine.FindState(name);
    }

    State@ FindState(const StringHash&in nameHash)
    {
        return stateMachine.FindState(nameHash);
    }

    void FixedUpdate(float timeStep)
    {
        timeStep *= timeScale;

        if (stateMachine !is null)
            stateMachine.FixedUpdate(timeStep);

        CheckDuration(timeStep);
    }

    void Update(float timeStep)
    {
        timeStep *= timeScale;

        if (stateMachine !is null)
            stateMachine.Update(timeStep);
    }

    bool IsTargetSightBlocked()
    {
        return false;
    }

    void CheckCollision()
    {

    }

    void SetPhysics(bool b)
    {
        if (body !is null)
            body.enabled = b;
        SetNodeEnabled("Collision", b);
    }

    bool IsVisible()
    {
        return animModel.IsInView(gCameraMgr.GetCamera());
    }

    bool IsInAir()
    {
        Vector3 lf_pos = renderNode.GetChild(L_FOOT, true).worldPosition;
        Vector3 rf_pos = renderNode.GetChild(R_FOOT, true).worldPosition;
        Vector3 myPos = sceneNode.worldPosition;
        float lf_to_ground = (lf_pos.y - myPos.y);
        float rf_to_graound = (rf_pos.y - myPos.y);
        return lf_to_ground > 1.0f && rf_to_graound > 1.0f;
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

    bool CheckFalling()
    {
        return false;
    }

    void SetPhysicsType(int type)
    {
        if (physicsType == type)
            return;
        physicsType = type;
        if (body !is null)
        {
            body.enabled = (physicsType == 1);
            body.position = sceneNode.worldPosition;
        }
    }

    void SetGravity(const Vector3& gravity)
    {
        if (body !is null)
            body.gravityOverride = gravity;
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

float FaceAngleDiff(Node@ thisNode, Node@ targetNode)
{
    Vector3 posDiff = targetNode.worldPosition - thisNode.worldPosition;
    Vector3 thisDir = thisNode.worldRotation * Vector3(0, 0, 1);
    float thisAngle = Atan2(thisDir.x, thisDir.z);
    float targetAngle = Atan2(posDiff.x, posDiff.y);
    return AngleDiff(targetAngle - thisAngle);
}

Node@ CreateCharacter(const String&in name, const String&in objectFile, const String&in scriptClass, const Vector3&in position, const Quaternion& rotation)
{
    XMLFile@ xml = cache.GetResource("XMLFile", "Objects/" + objectFile);
    Node@ p_node = script.defaultScene.InstantiateXML(xml, position, rotation);
    p_node.name = name;
    p_node.CreateScriptObject(scriptFile, scriptClass);
    return p_node;
}