// ==============================================
//
//    Camera Controller Logic Class
//
// ==============================================
const StringHash TARGET_POSITION("TargetPosition");
const StringHash TARGET_ROTATION("TargetRotation");
const StringHash TARGET_CONTROLLER("TargetController");
const StringHash TARGET_FOV("TargetFOV");

const float BASE_FOV = 45.0f;
const float CAMERA_RADIUS = 0.1f;

class CameraController
{
    StringHash nameHash;
    Node@      cameraNode;
    Camera@    camera;

    CameraController(Node@ n, const String&in name)
    {
        cameraNode = n;
        camera = cameraNode.GetComponent("Camera");
        nameHash = StringHash(name);
    }

    void Update(float dt)
    {

    }

    void OnCameraEvent(VariantMap& eventData)
    {

    }

    void Enter()
    {
        renderer.viewports[0].camera = camera;
    }

    void Exit()
    {

    }

    void UpdateView(const Vector3&in position, const Vector3& lookat, float blend)
    {
        Vector3 cameraPos = cameraNode.worldPosition;
        Vector3 vPos = position;

        Vector3 diff = position - cameraPos;
        Vector3 pos = cameraPos + diff * blend;
        Vector3 target = gCameraMgr.cameraTarget;
        diff = lookat - target;
        target += diff * blend;

        cameraNode.worldPosition = pos;
        cameraNode.LookAt(target);
        gCameraMgr.cameraTarget = target;
    }

    String GetDebugText()
    {
        return "camera fov=" + camera.fov + " position=" + cameraNode.worldPosition.ToString() + "\n";
    }

    void Reset()
    {

    }

    void DebugDraw(DebugRenderer@ debug)
    {
        /*
        float w = float(graphics.width);
        float h = float(graphics.height);
        float w1 = w;
        float h1 = h;
        float gap = 1.0f;
        w -= gap * 2;
        h -= gap * 2;
        // draw horizontal lines
        float depth = 25.0f;
        Color c(0, 1, 0);
        float y = gap;
        float step = h/3;
        for (int i=0; i<4; ++i)
        {
            debug.AddLine(camera.ScreenToWorldPoint(Vector3(gap/w1, y/h1, depth)), camera.ScreenToWorldPoint(Vector3((w + gap)/w1, y/h1, depth)), c, false);
            y += step;
        }
        // draw vertical lines
        float x = gap;
        step = w/3;
        for (int i=0; i<4; ++i)
        {
            debug.AddLine(camera.ScreenToWorldPoint(Vector3(x/w1, gap/h1, depth)), camera.ScreenToWorldPoint(Vector3(x/w1, (h + gap)/h1, depth)), c, false);
            x += step;
        }
        */
    }
};


class DebugFPSCameraController: CameraController
{
    float       yaw;
    float       pitch;

    DebugFPSCameraController(Node@ n, const String&in name)
    {
        super(n, name);
    }

    void Enter()
    {
        yaw = cameraNode.worldRotation.eulerAngles.y;
        pitch = cameraNode.worldRotation.eulerAngles.x;
        CameraController::Enter();
    }

    void Update(float dt)
    {
        if (ui.focusElement !is null)
            return;

        const float MOVE_SPEED = 20.0f;
        const float MOUSE_SENSITIVITY = 0.1f;

        float speed = MOVE_SPEED;
        if (input.keyDown[KEY_LSHIFT])
            speed *= 2;

        IntVector2 mouseMove = input.mouseMove;
        yaw += MOUSE_SENSITIVITY * mouseMove.x;
        pitch += MOUSE_SENSITIVITY * mouseMove.y;
        pitch = Clamp(pitch, -90.0f, 90.0f);

        cameraNode.rotation = Quaternion(pitch, yaw, 0.0f);

        if (input.keyDown[KEY_UP])
            cameraNode.Translate(Vector3(0.0f, 0.0f, 1.0f) * speed * dt);
        if (input.keyDown[KEY_DOWN])
            cameraNode.Translate(Vector3(0.0f, 0.0f, -1.0f) * speed * dt);
        if (input.keyDown[KEY_LEFT])
            cameraNode.Translate(Vector3(-1.0f, 0.0f, 0.0f) * speed * dt);
        if (input.keyDown[KEY_RIGHT])
            cameraNode.Translate(Vector3(1.0f, 0.0f, 0.0f) * speed * dt);
    }
};

class ThirdPersonCameraController : CameraController
{
    float   cameraSpeed = 7.5f;
    float   cameraDistance = 7.5f;
    float   targetCameraDistance = 4;
    float   cameraDistSpeed = 5.0f;
    Vector3 targetOffset = Vector3(0.65, 3.75, 0);

    ThirdPersonCameraController(Node@ n, const String&in name)
    {
        super(n, name);
    }

    void Update(float dt)
    {
        targetCameraDistance = GetPlayer().HasFlag(FLAGS_RUN) ? 5 : 4;
        cameraDistance += (targetCameraDistance - cameraDistance) * dt * cameraDistSpeed;

        Vector3 from, to;
        CaculateView(from, to);

        CollisionShape@ shape = cameraNode.GetComponent("CollisionShape");
        Quaternion r = Quaternion();
        PhysicsRaycastResult result = cameraNode.scene.physicsWorld.ConvexCast(shape, to, r, from, r, COLLISION_LAYER_LANDSCAPE);
        if (result.body !is null)
        {
            from = result.position + result.normal * CAMERA_RADIUS;
        }

        UpdateView(from, to, dt * cameraSpeed);
    }

    void CaculateView(Vector3&out from, Vector3&out to)
    {
        Vector3 target_pos = GetPlayer().GetNode().worldPosition;
        Vector3 offset = cameraNode.worldRotation * targetOffset;
        target_pos += offset;

        Vector3 v = gInput.GetRightAxis();
        float pitch = v.y;
        float yaw = v.x;

        if (gCameraMgr.debugCameraController !is null)
        {
            yaw = GetPlayer().GetCharacterAngle();
        }
        else
        {
            pitch = Clamp(pitch, -20.0f, 35.0f);
            gInput.m_rightStickY = pitch;
        }

        Quaternion q(pitch, yaw, 0);
        from = q * Vector3(0, 0, -cameraDistance) + target_pos;
        to = target_pos;
    }

    String GetDebugText()
    {
        return "camera fov=" + camera.fov + " position=" + cameraNode.worldPosition.ToString()  + " distance=" + cameraDistance + " targetOffset=" + targetOffset.ToString() + "\n";
    }

    void Reset()
    {
        //Player@ p = GetPlayer();
        //Vector3 offset = p.GetNode().worldRotation * targetOffset;
        //Vector3 target_pos = p.GetNode().worldPosition + offset;
        //Vector3 dir = target_pos - cameraNode.worldPosition;
        //cameraNode.LookAt(target_pos);
        //cameraDistance = dir.length;
        //Vector3 angles = cameraNode.worldRotation.eulerAngles;
        //gInput.m_rightStickY = angles.x;
        //gInput.m_rightStickX = angles.y;
        //gInput.m_rightStickMagnitude = gInput.m_rightStickX * gInput.m_rightStickX + gInput.m_rightStickY * gInput.m_rightStickY;
        //Print("Camera Reset cameraDistance=" + cameraDistance + " angles=" + angles.ToString());
    }

    void Enter()
    {
        Reset();
        CameraController::Enter();
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        //debug.AddCross(gCameraMgr.cameraTarget, 0.1, RED, true);
        //debug.AddCross(cameraNode.worldPosition, 0.1, BLUE, true);

        debug.AddSphere(Sphere(gCameraMgr.cameraTarget, CAMERA_RADIUS), RED, true);
        debug.AddSphere(Sphere(cameraNode.worldPosition, CAMERA_RADIUS), BLUE, true);
    }
};

class TransitionCameraController : CameraController
{
    Vector3     targetPosition;
    Quaternion  targetRotation;
    StringHash  targetController;
    float       duration;
    float       curTime;

    TransitionCameraController(Node@ n, const String&in name)
    {
        super(n, name);
    }

    void Update(float dt)
    {
        curTime += dt;
        Vector3 curPos = cameraNode.worldPosition;
        Quaternion curRot = cameraNode.worldRotation;
        cameraNode.worldPosition = curPos.Lerp(targetPosition, curTime/dt);
        cameraNode.worldRotation = curRot.Slerp(targetRotation, curTime/dt);
        if (curTime >= dt)
            gCameraMgr.SetCameraController(targetController);
    }

    void Enter()
    {
        curTime = 0.0f;
        CameraController::Enter();
    }

    void OnCameraEvent(VariantMap& eventData)
    {
        if (!eventData.Contains(DURATION))
            return;
        duration = eventData[DURATION].GetFloat();
        targetPosition = eventData[TARGET_POSITION].GetVector3();
        targetRotation = eventData[TARGET_ROTATION].GetQuaternion();
        targetController = eventData[TARGET_CONTROLLER].GetStringHash();
    }
};

class AnimationCameraController : CameraController
{
    uint nodeId = M_MAX_UNSIGNED;
    int playingIndex = 0;
    String animation;
    float cameraSpeed = 5.0f;

    AnimationCameraController(Node@ n, const String&in name)
    {
        super(n, name);
    }

    void Enter()
    {
        CreateAnimationNode();
        CameraController::Enter();
    }

    void Update(float dt)
    {
        Player@ p = GetPlayer();
        if (p is null)
            return;

        Node@ _node = script.defaultScene.GetNode(nodeId);
        Node@ n = _node.GetChild("Camera_ROOT", true);
        Vector3 v = GetTarget();
        UpdateView(n.worldPosition, v, cameraSpeed*dt);

        AnimationController@ ac = _node.GetComponent("AnimationController");
        if (ac.IsAtEnd(animation))
        {
            // finished.
            // todo.
            gCameraMgr.SetCameraController("ThirdPerson");
        }
    }

    Vector3 GetTarget()
    {
        Player@ p = GetPlayer();
        if (p is null)
            return Vector3(0, 0, 0);
        Vector3 v = p.GetNode().worldPosition;
        v.y += CHARACTER_HEIGHT;
        return v;
    }

    Node@ CreateAnimationNode()
    {
        if (nodeId == M_MAX_UNSIGNED)
        {
            Node@ _node = script.defaultScene.CreateChild("AnimatedCamera");
            nodeId = _node.id;

            AnimatedModel@ model = _node.CreateComponent("AnimatedModel");
            AnimationController@ ac = _node.CreateComponent("AnimationController");
            model.model = cache.GetResource("Model", "Models/Camera_Rig.mdl");
            model.updateInvisible = true;
            model.viewMask = 0;
            return _node;
        }
        else
            return script.defaultScene.GetNode(nodeId);
    }

    void PlayCamAnimation(const String&in animName)
    {
        animation = animName;
        script.defaultScene.GetNode(nodeId).worldPosition = GetTarget();
        PlayAnimation(CreateAnimationNode().GetComponent("AnimationController"), animName, LAYER_MOVE, false, 0.1f, 0.0f, 1.0f);
    }

    void OnCameraEvent(VariantMap& eventData)
    {
        if (!eventData.Contains(ANIMATION))
            return;
        PlayCamAnimation(eventData[ANIMATION].GetString());
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        Node@ _node = script.defaultScene.GetNode(nodeId);
        Node@ n = _node.GetChild("Camera_ROOT", true);
        debug.AddNode(_node, 0.5f, false);
        debug.AddNode(n, 0.5f, false);
    }
};

class CameraManager
{
    Array<CameraController@>    cameraControllers;
    CameraController@           currentController;
    Node@                       cameraNode;
    Vector3                     cameraTarget;

    Node@                       debugCameraNode;
    CameraController@           debugCameraController;

    CameraController@ FindCameraController(const StringHash&in nameHash)
    {
        for (uint i=0; i<cameraControllers.length; ++i)
        {
            if (cameraControllers[i].nameHash == nameHash)
                return cameraControllers[i];
        }
        log.Error("FindCamera Could not find " + nameHash.ToString());
        return null;
    }

    void SetCameraController(const String&in name)
    {
        SetCameraController(StringHash(name));
    }

    void SetCameraController(StringHash nameHash)
    {
        CameraController@ cc = FindCameraController(nameHash);
        if (currentController is cc)
            return;

        if (currentController !is null)
            currentController.Exit();
        @currentController = cc;
        if (currentController !is null)
            currentController.Enter();
    }

    void Start(Scene@ scene_)
    {
        cameraNode = scene_.CreateChild(CAMERA_NAME);
        Camera@ cam = cameraNode.CreateComponent("Camera");
        cam.fov = BASE_FOV;
        cameraNode.worldPosition = Vector3(0, 10, -5);

        cameraControllers.Clear();
        cameraControllers.Push(ThirdPersonCameraController(cameraNode, "ThirdPerson"));
        cameraControllers.Push(TransitionCameraController(cameraNode, "Transition"));
        cameraControllers.Push(AnimationCameraController(cameraNode, "Animation"));

        CollisionShape@ cameraSphere = cameraNode.CreateComponent("CollisionShape");
        cameraSphere.SetSphere(CAMERA_RADIUS);

        debugCameraNode = scene_.CreateChild(CAMERA_NAME + "_Debug");
        debugCameraNode.CreateComponent("Camera");
        debugCameraNode.worldPosition = cameraNode.worldPosition;
        cameraControllers.Push(DebugFPSCameraController(debugCameraNode, "Debug"));
    }

    void Stop()
    {
        cameraNode.Remove();
        @cameraNode = null;
        debugCameraNode.Remove();
        @debugCameraNode = null;
        cameraControllers.Clear();
    }

    void Update(float dt)
    {
        if (currentController !is null)
            currentController.Update(dt);
        if (debugCameraController !is null)
            debugCameraController.Update(dt);
    }

    Node@ GetCameraNode()
    {
        return (debugCameraController is null) ? cameraNode : debugCameraNode;
    }

    Camera@ GetCamera()
    {
        return GetCameraNode().GetComponent("Camera");
    }

    Vector3 GetCameraForwardDirection()
    {
        return GetCameraNode().worldRotation * Vector3(0, 0, 1);
    }

    float GetCameraAngle()
    {
        Vector3 dir = GetCameraForwardDirection();
        return Atan2(dir.x, dir.z);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        if (currentController !is null)
            currentController.DebugDraw(debug);
        if (debugCameraController !is null)
            debugCameraController.DebugDraw(debug);
    }

    void OnCameraEvent(VariantMap& eventData)
    {
        StringHash name = eventData[NAME].GetStringHash();
        if (name == CHANGE_STATE)
            SetCameraController(eventData[VALUE].GetStringHash());

        if (currentController !is null)
            currentController.OnCameraEvent(eventData);
    }

    void CheckCameraAnimation(const String&in anim)
    {
        VariantMap eventData;
        eventData[NAME] = CHANGE_STATE;
        eventData[VALUE] = StringHash("Animation");
        eventData[ANIMATION] = anim;
        Print("Play cam animation =" + anim);

        OnCameraEvent(eventData);
    }

    String GetDebugText()
    {
        String ret = (currentController !is null) ? currentController.GetDebugText() : "";
        if (debugCameraController !is null)
            ret += "Debug: " + debugCameraController.GetDebugText();
        return ret;
    }

    void SetDebugCamera(bool bFlag)
    {
        if (bFlag)
        {
            @debugCameraController = FindCameraController(StringHash("Debug"));
            if (debugCameraController !is null)
            {
                if (currentController !is null)
                {
                    // debugCameraController.cameraNode.worldPosition = currentController.cameraNode.worldPosition;
                    debugCameraController.cameraNode.LookAt(cameraTarget);
                }
                debugCameraController.Enter();
            }
        }
        else
        {
            if (debugCameraController !is null)
            {
                debugCameraController.Exit();
                @debugCameraController = null;
            }

            if (currentController !is null)
            {
                currentController.Enter();
            }
        }
    }
};

CameraManager@ gCameraMgr = CameraManager();