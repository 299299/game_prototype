#include "Scripts/Utilities/Sample.as"
#include "Facial.as"

FacialBoneManager@ g_facial_mgr = FacialBoneManager();
Array<String> facial_animations;

void Start()
{
    SampleStart();
    CreateScene();
    CreateUI();
    SetupViewport();
    SampleInitMouseMode(MM_RELATIVE);
    SubscribeToEvents();

    LoadAnimations();
}

void CreateScene()
{
    scene_ = Scene();

    // Load scene content prepared in the editor (XML format). GetFile() returns an open file from the resource system
    // which scene.LoadXML() will read
    scene_.LoadXML(cache.GetFile("Scenes/Head.xml"));

    // Create the camera (not included in the scene file)
    cameraNode = scene_.CreateChild("Camera");
    cameraNode.CreateComponent("Camera");

    // Set an initial position for the camera scene node above the plane
    cameraNode.position = Vector3(0.0f, 0.5f, -0.5f);

    g_facial_mgr.LoadNode(scene_.GetChild("Head", true));
}

void CreateUI()
{
    XMLFile@ style = cache.GetResource("XMLFile", "UI/DefaultStyle.xml");
    ui.root.defaultStyle = style;

    Cursor@ cursor = Cursor();
    cursor.SetStyleAuto();
    ui.cursor = cursor;
    cursor.SetPosition(graphics.width / 2, graphics.height / 2);

    Text@ infoText = Text();
    infoText.name = "Info";
    infoText.text = "Hello World from Urho3D!";
    infoText.SetFont(cache.GetResource("Font", "Fonts/Anonymous Pro.ttf"), 20);
    infoText.color = Color(0.0f, 1.0f, 0.0f);
    infoText.horizontalAlignment = HA_LEFT;
    infoText.verticalAlignment = VA_TOP;
    ui.root.AddChild(infoText);
}

void SetupViewport()
{
    // Set up a viewport to the Renderer subsystem so that the 3D scene can be seen
    Viewport@ viewport = Viewport(scene_, cameraNode.GetComponent("Camera"));
    renderer.viewports[0] = viewport;
}

void SubscribeToEvents()
{
    SubscribeToEvent("Update", "HandleUpdate");
    SubscribeToEvent("PostRenderUpdate", "HandlePostRenderUpdate");
}

void HandleUpdate(StringHash eventType, VariantMap& eventData)
{
    // Take the frame time step, which is stored as a float
    float timeStep = eventData["TimeStep"].GetFloat();
    // Move the camera, scale movement with time step
    MoveCamera(timeStep);
    UpdateFace(timeStep);
}

void MoveCamera(float timeStep)
{
    input.mouseVisible = input.mouseMode != MM_RELATIVE;
    bool mouseDown = input.mouseButtonDown[MOUSEB_RIGHT];

    // Override the MM_RELATIVE mouse grabbed settings, to allow interaction with UI
    input.mouseGrabbed = mouseDown;

    // Right mouse button controls mouse cursor visibility: hide when pressed
    ui.cursor.visible = !mouseDown;

    // Do not move if the UI has a focused element
    if (ui.focusElement !is null)
        return;

    // Movement speed as world units per second
    const float MOVE_SPEED = 5.0f;
    // Mouse sensitivity as degrees per pixel
    const float MOUSE_SENSITIVITY = 0.1f;

    // Use this frame's mouse motion to adjust camera node yaw and pitch. Clamp the pitch between -90 and 90 degrees
    // Only move the camera when the cursor is hidden
    if (!ui.cursor.visible)
    {
        IntVector2 mouseMove = input.mouseMove;
        yaw += MOUSE_SENSITIVITY * mouseMove.x;
        pitch += MOUSE_SENSITIVITY * mouseMove.y;
        pitch = Clamp(pitch, -90.0f, 90.0f);

        // Construct new orientation for the camera scene node from yaw and pitch. Roll is fixed to zero
        cameraNode.rotation = Quaternion(pitch, yaw, 0.0f);
    }

    // Read WASD keys and move the camera scene node to the corresponding direction if they are pressed
    if (input.keyDown[KEY_W])
        cameraNode.Translate(Vector3(0.0f, 0.0f, 1.0f) * MOVE_SPEED * timeStep);
    if (input.keyDown[KEY_S])
        cameraNode.Translate(Vector3(0.0f, 0.0f, -1.0f) * MOVE_SPEED * timeStep);
    if (input.keyDown[KEY_A])
        cameraNode.Translate(Vector3(-1.0f, 0.0f, 0.0f) * MOVE_SPEED * timeStep);
    if (input.keyDown[KEY_D])
        cameraNode.Translate(Vector3(1.0f, 0.0f, 0.0f) * MOVE_SPEED * timeStep);
}

void HandlePostRenderUpdate()
{
    DebugRenderer@ debug = scene_.debugRenderer;
    g_facial_mgr.DebugDraw(debug);
}

void LoadFacialBones()
{

}

void LoadAnimations()
{
    Node@ face_node = scene_.GetChild("Head", true);
    Array<String> jawBones = GetChildNodeNames(face_node.GetChild("FcFX_Jaw", true));
    Array<String> mouseBones;
    for (uint i=0; i<jawBones.length; ++i)
        mouseBones.Push(jawBones[i]);
    Array<String> boneNames = GetChildNodeNames(face_node);
    Array<String> leftEyeBones;
    Array<String> rightEyeBones;
    for (uint i=0; i<boneNames.length; ++i)
    {
        if (boneNames[i].EndsWith("_L"))
        {
            leftEyeBones.Push(boneNames[i]);
        }
        if (boneNames[i].EndsWith("_R"))
        {
            rightEyeBones.Push(boneNames[i]);
        }
    }

    facial_animations.Push(CreatePoseAnimation("Models/head_mouse_open.mdl", mouseBones, scene_).name);
    facial_animations.Push(CreatePoseAnimation("Models/head_eye_close_L.mdl", leftEyeBones, scene_).name);
    facial_animations.Push(CreatePoseAnimation("Models/head_eye_close_R.mdl", rightEyeBones, scene_).name);


    AnimationController@ ac = face_node.GetComponent("AnimationController");
    for (uint i=0; i<facial_animations.length; ++i)
    {
        ac.Play(facial_animations[i], 0, false, 0);
        ac.SetWeight(facial_animations[i], 0);
    }
}

Array<float> weights= { 0, 0, 0};
Array<float> speeds = { 1.0, 1.0, 1.0};

void UpdateSpeedAndWeight(float timeStep, int i, AnimationController@ ac)
{
    weights[i] += timeStep * speeds[i];
    if (weights[i] < 0)
    {
        weights[i] = 0;
        speeds[i] *= -1;
    }
    else if (weights[i] > 1.0)
    {
        weights[i] = 1.0;
        speeds[i] *= -1;
    }

    ac.Play(facial_animations[i], 0, false, 0);
    ac.SetWeight(facial_animations[i], weights[i]);
}

void UpdateFace(float timeStep)
{
    Text@ text = ui.root.GetChild("Info");
    text.text = " camera pos: " + cameraNode.worldPosition.ToString();

    Node@ face_node = scene_.GetChild("Head", true);
    AnimationController@ ac = face_node.GetComponent("AnimationController");
    if (input.keyDown[KEY_T])
    {
        UpdateSpeedAndWeight(timeStep, 0, ac);
    }
    if (input.keyDown[KEY_G])
    {
        UpdateSpeedAndWeight(timeStep, 1, ac);
    }
    if (input.keyDown[KEY_B])
    {
        UpdateSpeedAndWeight(timeStep, 2, ac);
    }
}

// Create XML patch instructions for screen joystick layout specific to this sample app
String patchInstructions = "";