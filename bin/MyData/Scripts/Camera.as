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

    String GetDebugText()
    {
        return "camera fov=" + camera.fov + " position=" + cameraNode.worldPosition.ToString() + "\n";
    }

    void Reset()
    {

    }

    void DebugDraw(DebugRenderer@ debug)
    {
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
        if (input.keyDown[KEY_LSHIFT] || input.keyDown[KEY_RSHIFT])
            speed *= 4;

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

    void Enter()
    {
        input.mouseMode = MM_RELATIVE;
    }

    void Exit()
    {
        input.mouseMode = MM_FREE;
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
            gCameraMgr.SetCameraController("LookAt");
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

        LogPrint("DeathCamera sideAngle="+sideAngle);
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
            gCameraMgr.SetCameraController("LookAt");
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

class LookAtCameraController: CameraController
{
    Vector3 offset = Vector3(0.0, 25.0, -15.0);
    float cameraSpeed = 4.5;

    LookAtCameraController(Node@ n, const String&in name)
    {
        super(n, name);
    }

    void Update(float dt)
    {
        Player@ p = GetPlayer();
        if (p is null)
            return;
        Node@ _node = p.GetNode();

        Vector3 camera_pos = offset + _node.worldPosition;
        Vector3 target_pos = _node.worldPosition;
        UpdateView(camera_pos, target_pos, dt * cameraSpeed);
    }
};

class CameraManager
{
    Array<CameraController@>    cameraControllers;
    CameraController@           currentController;
    Node@                       cameraNode;
    Vector3                     cameraTarget;
    Array<StringHash>           cameraAnimations;

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

    void Start(Node@ n)
    {
        cameraNode = n;
        cameraControllers.Push(DebugFPSCameraController(n, "Debug"));
        cameraControllers.Push(TransitionCameraController(n, "Transition"));
        cameraControllers.Push(DeathCameraController(n, "Death"));
        cameraControllers.Push(AnimationCameraController(n, "Animation"));
        cameraControllers.Push(LookAtCameraController(n, "LookAt"));

        /*
        cameraAnimations.Push(StringHash("Counter_Arm_Back_05"));
        cameraAnimations.Push(StringHash("Counter_Arm_Back_06"));
        cameraAnimations.Push(StringHash("Counter_Arm_Front_07"));
        cameraAnimations.Push(StringHash("Counter_Arm_Front_09"));
        cameraAnimations.Push(StringHash("Counter_Arm_Front_13"));
        cameraAnimations.Push(StringHash("Counter_Arm_Front_14"));
        cameraAnimations.Push(StringHash("Counter_Leg_Back_04"));
        cameraAnimations.Push(StringHash("Counter_Leg_Front_07"));
        cameraAnimations.Push(StringHash("Double_Counter_2ThugsA"));
        cameraAnimations.Push(StringHash("Double_Counter_2ThugsB"));
        cameraAnimations.Push(StringHash("Double_Counter_2ThugsG"));
        cameraAnimations.Push(StringHash("Double_Counter_2ThugsH"));
        cameraAnimations.Push(StringHash("Double_Counter_3ThugsB"));
        */
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

    void CheckCameraAnimation(const String&in anim)
    {
        uint pos = anim.FindLast('/');
        String name = anim.Substring(pos + 1);
        //LogPrint("CheckCameraAnimation, name=" + name);
        StringHash nameHash(name);
        int k = -1;
        for (uint i=0; i<cameraAnimations.length; ++i)
        {
            if (nameHash == cameraAnimations[i])
            {
                k = int(i);
                break;
            }
        }

        if (k < 0)
            return;

        String camAnim = GetAnimationName("BM_Combat_Cameras/" + name);
        VariantMap eventData;
        eventData[NAME] = CHANGE_STATE;
        eventData[VALUE] = StringHash("Animation");
        eventData[ANIMATION] = camAnim;
        LogPrint("camAnim=" + camAnim);

        OnCameraEvent(eventData);
    }

    String GetDebugText()
    {
        return (currentController !is null) ? currentController.GetDebugText() : "";
    }
};

CameraManager@ gCameraMgr = CameraManager();