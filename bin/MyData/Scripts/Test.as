#include "Scripts/Utilities/Sample.as"
#include "Facial.as"

FacialBoneManager@ g_facial_mgr = FacialBoneManager();

void Start()
{
    SampleStart();
    CreateScene();
    CreateUI();
    SetupViewport();
    SampleInitMouseMode(MM_RELATIVE);
    SubscribeToEvents();
}

void CreateScene()
{
    scene_ = Scene();
    scene_.LoadXML(cache.GetFile("Scenes/Head.xml"));
    cameraNode = scene_.CreateChild("Camera");
    cameraNode.CreateComponent("Camera");
    cameraNode.position = Vector3(0.0f, 0.55f, -1.5f);
    g_facial_mgr.Init(scene_);
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
    y += h;
    CreateSlider(10, y, 500, 30, "left_eye_open");
    y += h;
    CreateSlider(10, y, 500, 30, "right_eye_open");
    y += h;
    Slider@ s = CreateSlider(10, y, 500, 30, "left_eye_ball");
    s.value = 0.5;
    y += h;
    @s = CreateSlider(10, y, 500, 30, "right_eye_ball");
    s.value = 0.5;
    y += h;
    @s = CreateSlider(10, y, 500, 30, "yaw");
    s.range = 360.0;
    y += h;
    @s = CreateSlider(10, y, 500, 30, "pitch");
    s.range = 360.0;
    y += h;
    @s = CreateSlider(10, y, 500, 30, "roll");
    s.range = 360.0;
    y += h;
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
    Text@ sliderText = ui.root.GetChild(e.name + "_text", true);

    int index = -1;

    if (e.name == "mouse_open")
    {
        index = kFacial_MouseOpenness;
    }
    else if (e.name == "left_eye_open")
    {
        index = kFacial_EyeOpenness_Left;
    }
    else if (e.name == "right_eye_open")
    {
        index = kFacial_EyeOpenness_Right;
    }
    else if (e.name == "left_eye_ball")
    {
        index = kFacial_EyePositionLeft_Left;
    }
    else if (e.name == "right_eye_ball")
    {
        index = kFacial_EyePositionLeft_Right;
    }
    else if (e.name == "yaw")
    {
        g_facial_mgr.yaw = value;
    }
    else if (e.name == "pitch")
    {
        g_facial_mgr.pitch = value;
    }
    else if (e.name == "roll")
    {
        g_facial_mgr.roll = value;
    }

    if (index >= 0)
    {
        g_facial_mgr.facial_attributes[index] = value;
    }

    sliderText.text = e.name + " : " + value;
}

void SetupViewport()
{
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
    float timeStep = eventData["TimeStep"].GetFloat();
    MoveCamera(timeStep);
    UpdateFace(timeStep);
}

void MoveCamera(float timeStep)
{
    input.mouseVisible = input.mouseMode != MM_RELATIVE;
    bool mouseDown = input.mouseButtonDown[MOUSEB_RIGHT];

    input.mouseGrabbed = mouseDown;
    ui.cursor.visible = !mouseDown;

    if (ui.focusElement !is null)
        return;

    const float MOVE_SPEED = 2.5f;
    const float MOUSE_SENSITIVITY = 0.1f;

    if (!ui.cursor.visible)
    {
        IntVector2 mouseMove = input.mouseMove;
        yaw += MOUSE_SENSITIVITY * mouseMove.x;
        pitch += MOUSE_SENSITIVITY * mouseMove.y;
        pitch = Clamp(pitch, -90.0f, 90.0f);
        cameraNode.rotation = Quaternion(pitch, yaw, 0.0f);
    }

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

void UpdateFace(float timeStep)
{
    Text@ text = ui.root.GetChild("Info");
    text.text = " camera pos: " + cameraNode.worldPosition.ToString();
    g_facial_mgr.Update(timeStep);
}

// Create XML patch instructions for screen joystick layout specific to this sample app
String patchInstructions = "";