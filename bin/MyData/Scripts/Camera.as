// ==============================================
//
//    Camera Controller Logic Class
//
// ==============================================

class CameraController
{
    CameraController(Node@ n, const String&in name)
    {
        cameraNode = n;
        camera = cameraNode.GetComponent("Camera");
        nameHash = StringHash(name);
    }

    void Update(float dt)
    {

    }

    StringHash nameHash;
    Node@      cameraNode;
    Camera@    camera;
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
};

class ThirdPersonCameraController : CameraController
{
    Vector3 cameraTargert;
    float   cameraSpeed = 2.5f;
    float   cameraHeight = 5.5f;
    float   cameraDistance = 20.0f;

    ThirdPersonCameraController(Node@ n, const String&in name)
    {
        super(n, name);
    }

    void Update(float dt)
    {
        Node@ _node = cameraNode.scene.GetChild("player");
        if (_node is null)
            return;

        Vector3 target_pos = _node.worldPosition;
        target_pos.y += cameraHeight;

        float pitch = gInput.m_rightStickY;
        float yaw = gInput.m_rightStickX;
        pitch = Clamp(pitch, -20.0f, 60.0f);

        Quaternion q(pitch, yaw, 0);
        Vector3 pos = q * Vector3(0, 0, -cameraDistance) + target_pos;

        Vector3 cameraPos = cameraNode.worldPosition;
        cameraPos = cameraPos.Lerp(pos, dt * cameraSpeed);
        cameraNode.worldPosition = cameraPos;

        cameraTargert = cameraTargert.Lerp(target_pos, dt * cameraSpeed);
        cameraNode.LookAt(cameraTargert);
    }
};

class CameraManager
{
    Array<CameraController@>    cameraControllers;
    CameraController@           currentController;
    Node@                       cameraNode;

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
        CameraController@ cc = FindCameraController(StringHash(name));
        if (cc is null)
            return;
        @currentController = cc;
    }

    void Start(Node@ n)
    {
        cameraNode = n;
        cameraControllers.Push(DebugFPSCameraController(n, "Debug"));
        cameraControllers.Push(ThirdPersonCameraController(n, "ThirdPerson"));
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
        Vector3 dir = GetCameraForwardDirection();
        return Atan2(dir.x, dir.z);
    }
};

CameraManager@ gCameraMgr = CameraManager();