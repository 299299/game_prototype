#include "Scripts/Utilities/Sample.as"
// ------------------------------------------------
#include "Scripts/AssetProcess.as"
#include "Scripts/Motion.as"
#include "Scripts/Input.as"
#include "Scripts/FSM.as"

Node@ characterNode;

void Start()
{
    cache.autoReloadResources = true;
    if (!engine.headless)
        SampleStart();
    CreateScene();
    if (!engine.headless) {
        CreateInstructions();
        SetupViewport();
        SetupUI();
    }
    SubscribeToEvents();
}

void Stop()
{

}

void CreateScene()
{
    scene_ = Scene();

    scene_.LoadXML(cache.GetFile("Scenes/1.xml"));

    cameraNode = scene_.CreateChild("Camera");
    Camera@ cam = cameraNode.CreateComponent("Camera");
    // cam.fillMode = FILL_WIREFRAME;

    // Set an initial position for the camera scene node above the plane
    cameraNode.position = Vector3(0.0f, 10.0f, -10.0f);
    pitch = 45;
}

void CreateInstructions()
{
    Text@ instructionText = ui.root.CreateChild("Text", "instruction");
    instructionText.SetFont(cache.GetResource("Font", "Fonts/UbuntuMono-R.ttf"), 12);
    instructionText.horizontalAlignment = HA_LEFT;
    instructionText.verticalAlignment = VA_TOP;
    instructionText.SetPosition(0, 0);
    instructionText.color = Color(0, 1, 0);
    SetLogoVisible(false);
}

void SetupViewport()
{
    Viewport@ viewport = Viewport(scene_, cameraNode.GetComponent("Camera"));
    renderer.viewports[0] = viewport;

    //if (GetPlatform() == "Linux")
    //    graphics.windowPosition = IntVector2(0, 800);
}

void MoveCamera(float timeStep)
{
    if (ui.focusElement !is null)
        return;

    const float MOVE_SPEED = 20.0f;
    const float MOUSE_SENSITIVITY = 0.1f;

    IntVector2 mouseMove = input.mouseMove;
    yaw += MOUSE_SENSITIVITY * mouseMove.x;
    pitch += MOUSE_SENSITIVITY * mouseMove.y;
    pitch = Clamp(pitch, -90.0f, 90.0f);

    cameraNode.rotation = Quaternion(pitch, yaw, 0.0f);

    if (input.keyDown['W'])
        cameraNode.Translate(Vector3(0.0f, 0.0f, 1.0f) * MOVE_SPEED * timeStep);
    if (input.keyDown['S'])
        cameraNode.Translate(Vector3(0.0f, 0.0f, -1.0f) * MOVE_SPEED * timeStep);
    if (input.keyDown['A'])
        cameraNode.Translate(Vector3(-1.0f, 0.0f, 0.0f) * MOVE_SPEED * timeStep);
    if (input.keyDown['D'])
        cameraNode.Translate(Vector3(1.0f, 0.0f, 0.0f) * MOVE_SPEED * timeStep);
}

void SubscribeToEvents()
{
    SubscribeToEvent("Update", "HandleUpdate");
    SubscribeToEvent("SceneUpdate", "HandleSceneUpdate");
    SubscribeToEvent("PostRenderUpdate", "HandlePostRenderUpdate");
}

void HandleUpdate(StringHash eventType, VariantMap& eventData)
{
    float timeStep = eventData["TimeStep"].GetFloat();
    MoveCamera(timeStep);
}

void HandlePostRenderUpdate(StringHash eventType, VariantMap& eventData)
{
    DebugRenderer@ debug = scene_.debugRenderer;
}

void SetupUI()
{

}

String patchInstructions = "";