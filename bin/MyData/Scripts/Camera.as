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

    void DebugDraw(DebugRenderer@ debug)
    {

    }

    void OnCameraEvent(VariantMap& eventData)
    {

    }

    void Enter()
    {

    }

    void Exit()
    {

    }

    bool IsDebugCamera()
    {
        return false;
    }

    void UpdateView(const Vector3&in position, const Vector3& lookat, float blend)
    {
        Vector3 cameraPos = cameraNode.worldPosition;
        Vector3 diff = position - cameraPos;
        cameraNode.worldPosition = cameraPos + diff * blend;
        Vector3 target = gCameraMgr.cameraTarget;
        diff = lookat - target;
        target += diff * blend;
        cameraNode.LookAt(target);
        gCameraMgr.cameraTarget = target;
    }
};


class DebugFPSCameraController: CameraController
{
    float       yaw;
    float       pitch;

    DebugFPSCameraController(Node@ n, const String&in name)
    {
        super(n, name);
        yaw = n.worldRotation.eulerAngles.y;
        pitch = n.worldRotation.eulerAngles.x;
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

    bool IsDebugCamera()
    {
        return true;
    }
};

class ThirdPersonCameraController : CameraController
{
    float   cameraSpeed = 4.5f;
    float   cameraHeight = 3.0f;
    float   cameraDistance = 18.0f;
    float   cameraDistSpeed = 200.0f;
    float   cameraAutoDistance = 20.0f;
    float   targetFov = BASE_FOV;
    float   fovSpeed = 1.5f;

    ThirdPersonCameraController(Node@ n, const String&in name)
    {
        super(n, name);
        Vector3 v = cameraNode.worldPosition;
        v.y += cameraHeight;
        gCameraMgr.cameraTarget = v;
    }

    void Update(float dt)
    {
        Player@ p = GetPlayer();
        if (p is null)
            return;
        Node@ _node = p.GetNode();

        bool blockView = false;
        Vector3 target_pos = _node.worldPosition;
        if (p.target !is null)
        {
            if (!p.target.IsVisible())
            {
                //target_pos += p.target.GetNode().worldPosition;
                //target_pos /= 2.0f;
                //cameraAutoDistance += cameraDistSpeed * dt;
                //blockView = true;
            }
        }

        target_pos.y += cameraHeight;

        float pitch = gInput.m_rightStickY;
        float yaw = gInput.m_rightStickX;
        pitch = Clamp(pitch, -10.0f, 60.0f);

        float dist = cameraDistance;
        //if (blockView)
        //    dist = cameraAutoDistance;

        Quaternion q(pitch, yaw, 0);
        Vector3 pos = q * Vector3(0, 0, -dist) + target_pos;
        UpdateView(pos, target_pos, dt * cameraSpeed);

        cameraDistance += float(input.mouseMoveWheel) * dt * -cameraDistSpeed;

        float diff = targetFov - camera.fov;
        camera.fov += diff * dt * fovSpeed;
    }

    void OnCameraEvent(VariantMap& eventData)
    {
        if (!eventData.Contains(TARGET_FOV))
            return;
        targetFov = eventData[TARGET_FOV].GetFloat();
    }

    void Enter()
    {
        targetFov = BASE_FOV;
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

class DeathCameraController : CameraController
{
    uint    nodeId = M_MAX_UNSIGNED;
    float   cameraSpeed = 3.5f;
    float   cameraDist = 12.5f;
    float   cameraHeight = 0.5f;
    float   sideAngle = 0.0;
    float   timeInState = 0.0f;

    DeathCameraController(Node@ n, const String&in name)
    {
        super(n, name);
    }

    void Exit()
    {
        nodeId = M_MAX_UNSIGNED;
        timeInState = 0;
    }

    void Update(float dt)
    {
        timeInState += dt;
        Node@ _node = cameraNode.scene.GetNode(nodeId);
        if (_node is null || timeInState > 7.5f)
        {
            gCameraMgr.SetCameraController("ThirdPerson");
            return;
        }
        Node@ playerNode = GetPlayer().GetNode();

        Vector3 dir = _node.worldPosition - playerNode.worldPosition;
        float angle = Atan2(dir.x, dir.z) + sideAngle;

        Vector3 v1(Sin(angle) * cameraDist, cameraHeight, Cos(angle) * cameraDist);
        v1 += _node.worldPosition;
        Vector3 v2 = _node.worldPosition + playerNode.worldPosition;
        v2 /= 2;
        v2.y += CHARACTER_HEIGHT;
        UpdateView(v1, v2, dt * cameraSpeed);
    }

    void OnCameraEvent(VariantMap& eventData)
    {
        if (!eventData.Contains(NODE))
            return;
        nodeId = eventData[NODE].GetUInt();
        Node@ _node = cameraNode.scene.GetNode(nodeId);
        if (_node is null)
        {
            gCameraMgr.SetCameraController("ThirdPerson");
            return;
        }
        Node@ playerNode = GetPlayer().GetNode();
        Vector3 dir = _node.worldPosition - playerNode.worldPosition;
        float angle = Atan2(dir.x, dir.z);
        float angle_1 = AngleDiff(angle - 90);
        float angle_2 = AngleDiff(angle + 90);
        float cur_angle = gCameraMgr.GetCameraAngle();
        if (Abs(cur_angle - angle_1) > Abs(cur_angle - angle_2))
            sideAngle = -90.0f;
        else
            sideAngle = +90.0f;

        Print("DeathCamera sideAngle="+sideAngle);
    }
};

class AnimationCameraController : CameraController
{
    Array<String> animations;
    uint nodeId = M_MAX_UNSIGNED;
    int playingIndex = 0;

    AnimationCameraController(Node@ n, const String&in name)
    {
        super(n, name);
    }

    void Enter()
    {
    }

    void Update(float dt)
    {
        Node@ _node = script.defaultScene.GetNode(nodeId);
        AnimationController@ ac = _node.GetComponent("AnimationController");
        if (ac.IsAtEnd(animations[playingIndex]))
        {
            // finished.
            // todo.
            gCameraMgr.SetCameraController("ThirdPerson");
        }
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
            return _node;
        }
        else
            return script.defaultScene.GetNode(nodeId);
    }

    void PlayCamAnimation(const String&in animName)
    {
        PlayAnimation(CreateAnimationNode().GetComponent("AnimationController"), animName);
    }

    void OnCameraEvent(VariantMap& eventData)
    {
        if (!eventData.Contains(ANIMATION))
            return;
        PlayCamAnimation(animations[eventData[ANIMATION].GetInt()]);
    }
};

class CameraManager
{
    Array<CameraController@>    cameraControllers;
    CameraController@           currentController;
    Node@                       cameraNode;
    Vector3                     cameraTarget;

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

        Print("SetCameraController -- " + nameHash.ToString());

        if (currentController !is null)
            currentController.Exit();
        @currentController = cc;
        if (currentController !is null)
            currentController.Enter();
    }

    void Start(Node@ n)
    {
        cameraNode = n;
        cameraControllers.Push(DebugFPSCameraController(n, "Debug"));
        cameraControllers.Push(ThirdPersonCameraController(n, "ThirdPerson"));
        cameraControllers.Push(TransitionCameraController(n, "Transition"));
        cameraControllers.Push(DeathCameraController(n, "Death"));
        cameraControllers.Push(AnimationCameraController(n, "Animation"));
    }

    void Stop()
    {
        @cameraNode = null;
        cameraControllers.Clear();
    }

    void Update(float dt)
    {
        if (currentController !is null)
            currentController.Update(dt);
    }

    Node@ GetCameraNode()
    {
        return cameraNode;
    }

    Camera@ GetCamera()
    {
        if (cameraNode is null)
            return null;
        return cameraNode.GetComponent("Camera");
    }

    Vector3 GetCameraForwardDirection()
    {
        return cameraNode.worldRotation * Vector3(0, 0, 1);
    }

    float GetCameraAngle()
    {
        if (currentController !is null)
        {
            if (currentController.IsDebugCamera())
                return 0;
        }

        Vector3 dir = GetCameraForwardDirection();
        return Atan2(dir.x, dir.z);
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        //debug.AddCross(cameraTarget, 1.0f, RED, false);
        if (currentController !is null)
            currentController.DebugDraw(debug);
    }

    void OnCameraEvent(VariantMap& eventData)
    {
        StringHash name = eventData[NAME].GetStringHash();
        if (name == CHANGE_STATE)
            SetCameraController(eventData[VALUE].GetStringHash());

        if (currentController !is null)
            currentController.OnCameraEvent(eventData);
    }
};

CameraManager@ gCameraMgr = CameraManager();