// Static 3D scene example.
// This sample demonstrates:
//     - Creating a 3D scene with static content
//     - Displaying the scene using the Renderer subsystem
//     - Handling keyboard and mouse input to move a freelook camera

#include "Scripts/Utilities/Sample.as"
#include "Scripts/Test/Motion.as"
#include "Scripts/Test/Player.as"
#include "Scripts/Test/Input.as"

Node@ characterNode;
int state = 0;
GameInput@ gInput = GameInput();
Player@ player;
bool slowMotion = true;

void Start()
{
    // Execute the common startup for samples
    if (!engine.headless) {
        SampleStart();
    }

    // Create the scene content
    CreateScene();

    if (!engine.headless) {
        // Create the UI content
        CreateInstructions();

        // Setup the viewport for displaying the scene
        SetupViewport();
    }

    // Hook up to the frame update events
    SubscribeToEvents();
}

void CreateScene()
{
    scene_ = Scene();

    // Load scene content prepared in the editor (XML format). GetFile() returns an open file from the resource system
    // which scene.LoadXML() will read
    scene_.LoadXML(cache.GetFile("Scenes/1.xml"));

    // Create a scene node for the camera, which we will move around
    // The camera will use default settings (1000 far clip distance, 45 degrees FOV, set aspect ratio automatically)
    cameraNode = scene_.CreateChild("Camera");
    cameraNode.CreateComponent("Camera");

    // Set an initial position for the camera scene node above the plane
    cameraNode.position = Vector3(0.0f, 10.0f, -10.0f);
    pitch = 45;

    characterNode = scene_.GetChild("bruce", true);
    @player = cast<Player>(characterNode.CreateScriptObject("Scripts/Test/Test.as", "Player"));
    characterNode.Translate(Vector3(5, 0, 0));

    player.stateMachine.ChangeState("StandToMoveState");
}

void CreateInstructions()
{
    // Construct new Text object, set string to display and font to use
    Text@ instructionText = ui.root.CreateChild("Text", "instruction");
    instructionText.text = "Use WASD keys and mouse to move";
    instructionText.SetFont(cache.GetResource("Font", "Fonts/Anonymous Pro.ttf"), 15);

    // Position the text relative to the screen center
    instructionText.horizontalAlignment = HA_CENTER;
    instructionText.verticalAlignment = VA_CENTER;
    instructionText.SetPosition(0, ui.root.height / 4);
    instructionText.color = Color(1, 0, 0);
}

void SetupViewport()
{
    // Set up a viewport to the Renderer subsystem so that the 3D scene can be seen. We need to define the scene and the camera
    // at minimum. Additionally we could configure the viewport screen size and the rendering path (eg. forward / deferred) to
    // use, but now we just use full screen and default render path configured in the engine command line options
    Viewport@ viewport = Viewport(scene_, cameraNode.GetComponent("Camera"));
    renderer.viewports[0] = viewport;
}

void MoveCamera(float timeStep)
{
    // Do not move if the UI has a focused element (the console)
    if (ui.focusElement !is null)
        return;

    // Movement speed as world units per second
    const float MOVE_SPEED = 20.0f;
    // Mouse sensitivity as degrees per pixel
    const float MOUSE_SENSITIVITY = 0.1f;

    // Use this frame's mouse motion to adjust camera node yaw and pitch. Clamp the pitch between -90 and 90 degrees
    IntVector2 mouseMove = input.mouseMove;
    yaw += MOUSE_SENSITIVITY * mouseMove.x;
    pitch += MOUSE_SENSITIVITY * mouseMove.y;
    pitch = Clamp(pitch, -90.0f, 90.0f);

    // Construct new orientation for the camera scene node from yaw and pitch. Roll is fixed to zero
    cameraNode.rotation = Quaternion(pitch, yaw, 0.0f);

    // Read WASD keys and move the camera scene node to the corresponding direction if they are pressed
    // Use the Translate() function (default local space) to move relative to the node's orientation.
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
    // Subscribe HandleUpdate() function for processing update events
    SubscribeToEvent("Update", "HandleUpdate");

    SubscribeToEvent("SceneUpdate", "HandleSceneUpdate");

    // Subscribe HandlePostRenderUpdate() function for processing the post-render update event, during which we request
    // debug geometry
    if (!engine.headless)
        SubscribeToEvent("PostRenderUpdate", "HandlePostRenderUpdate");
}

float golbal_time = 0;


void HandleUpdate(StringHash eventType, VariantMap& eventData)
{
    // Take the frame time step, which is stored as a float
    float timeStep = eventData["TimeStep"].GetFloat();

    // Move the camera, scale movement with time step
    MoveCamera(timeStep);

    gInput.Update(timeStep);

    if (input.keyPress['T'])
    {
        scene_.timeScale = slowMotion ? 0.05f : 1.0f;
        slowMotion = !slowMotion;
    }

    if (engine.headless)
    {
        golbal_time += timeStep;

        if (golbal_time > 2.0)
        {
            state = 3;
            @player = null;
            characterNode.RemoveAllComponents();
        }

        if (golbal_time > 4.0)
        {
            engine.Exit();
        }
    }
    else
    {
        Vector3 fwd = Vector3(0, 0, 1);
        Vector3 camDir = cameraNode.worldRotation * fwd;
        float cameraAngle = Atan2(camDir.x, camDir.z);
        Vector3 characterDir = characterNode.worldRotation * fwd;
        float characterAngle = Atan2(characterDir.x, characterDir.z);

        //Print("cameraAngle=" + String(cameraAngle) + " characterAngle=" + String(characterAngle) + " inputAngle=" + String(gInput.m_leftStickAngle));
        float diff = computeDifference();
        //Print("diff="+String(diff));
        Text@ text = ui.root.GetChild("instruction", true);
        String debugText = "DIFF=" + String(diff) + " SEL=" + String(RadialSelectAnimation(4)) + " m=" + String(gInput.m_leftStickMagnitude) + " l=" + String(gInput.m_leftStickHoldTime);
        if (player.stateMachine.currentState !is null)
            debugText += "\n" + "current-state=" + player.stateMachine.currentState.name;
        text.text = debugText;
    }
}

void HandlePostRenderUpdate(StringHash eventType, VariantMap& eventData)
{
    DebugRenderer@ debug = scene_.debugRenderer;

    debug.AddNode(scene_, 2.0f, false);
    debug.AddNode(characterNode, 1.0f, false);
    player.DebugDraw(debug);

    Vector3 fwd = Vector3(0, 0, 1);
    Vector3 camDir = cameraNode.worldRotation * fwd;
    float cameraAngle = Atan2(camDir.x, camDir.z);
    Vector3 characterDir = characterNode.worldRotation * fwd;
    float characterAngle = Atan2(characterDir.x, characterDir.z);
    float targetAngle = cameraAngle + gInput.m_leftStickAngle;
    DebugDrawDirection(debug, characterNode, targetAngle, Color(1, 1, 0), 4.0);
    DebugDrawDirection(debug, characterNode, characterAngle, Color(1, 0, 1), 4.0);
}



// Create XML patch instructions for screen joystick layout specific to this sample app
String patchInstructions = "";