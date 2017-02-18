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

    float y = 50; float h = 60;
    CreateSlider(10, y, 500, 30, "mouse_open");
    CreateSlider(10, y + h, 500, 30, "left_eye_open");
    CreateSlider(10, y + 2*h, 500, 30, "right_eye_open");
}

Slider@ CreateSlider(int x, int y, int xSize, int ySize, const String& text)
{
    Font@ font = cache.GetResource("Font", "Fonts/Anonymous Pro.ttf");

    Text@ sliderText = ui.root.CreateChild("Text");
    sliderText.SetPosition(x, y);
    sliderText.SetFont(font, 15);
    sliderText.text = text;
    sliderText.name = text + "_text";

    Slider@ slider = ui.root.CreateChild("Slider");
    slider.SetStyleAuto();
    slider.SetPosition(x, y + 20);
    slider.SetSize(xSize, ySize);
    slider.range = 1.0f;
    slider.name = text;

    SubscribeToEvent(slider, "SliderChanged", "HandleSliderChanged");

    return slider;
}

void HandleSliderChanged(StringHash eventType, VariantMap& eventData)
{
    UIElement@ e = eventData["Element"].GetPtr();
    float value = eventData["Value"].GetFloat();
    Node@ face_node = scene_.GetChild("Head", true);
    AnimationController@ ac = face_node.GetComponent("AnimationController");
    Text@ sliderText = ui.root.GetChild(e.name + "_text", true);

    if (e.name == "mouse_open")
    {
        ac.Play(facial_animations[0], 0, false, 0);
        ac.SetWeight(facial_animations[0], value);
        sliderText.text = sliderText.name + " : " + value;
    }
    else if (e.name == "left_eye_open")
    {
        ac.Play(facial_animations[1], 0, false, 0);
        ac.SetWeight(facial_animations[1], value);
        sliderText.text = sliderText.name + " : " + value;
    }
    else if (e.name == "right_eye_open")
    {
        ac.Play(facial_animations[2], 0, false, 0);
        ac.SetWeight(facial_animations[2], value);
        sliderText.text = sliderText.name + " : " + value;
    }
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
    SubscribeToEvent("SceneUpdate", "HandleSceneUpdate_1");
}

void HandleSceneUpdate_1(StringHash eventType, VariantMap& eventData)
{
    // Move the camera by touch, if the camera node is initialized by descendant sample class
    if (touchEnabled && cameraNode !is null)
    {
        for (uint i = 0; i < input.numTouches; ++i)
        {
            TouchState@ state = input.touches[i];
            if (state.touchedElement is null && ui.focusElement is null) // Touch on empty space
            {
                if (state.delta.x !=0 || state.delta.y !=0)
                {
                    Camera@ camera = cameraNode.GetComponent("Camera");
                    if (camera is null)
                        return;

                    yaw += TOUCH_SENSITIVITY * camera.fov / graphics.height * state.delta.x;
                    pitch += TOUCH_SENSITIVITY * camera.fov / graphics.height * state.delta.y;

                    // Construct new orientation for the camera scene node from yaw and pitch; roll is fixed to zero
                    // cameraNode.rotation = Quaternion(pitch, yaw, 0.0f);
                }
                else
                {
                    // Move the cursor to the touch position
                    Cursor@ cursor = ui.cursor;
                    if (cursor !is null && cursor.visible)
                        cursor.position = state.position;
                }
            }
        }
    }
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
    const float MOVE_SPEED = 2.5f;
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

void UpdateFace(float timeStep)
{
    Text@ text = ui.root.GetChild("Info");
    text.text = " camera pos: " + cameraNode.worldPosition.ToString();
}

// Create XML patch instructions for screen joystick layout specific to this sample app
String patchInstructions = "";