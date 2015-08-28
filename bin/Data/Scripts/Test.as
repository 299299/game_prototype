// Static 3D scene example.
// This sample demonstrates:
//     - Creating a 3D scene with static content
//     - Displaying the scene using the Renderer subsystem
//     - Handling keyboard and mouse input to move a freelook camera

#include "Scripts/Utilities/Sample.as"
#include "Scripts/Motion.as"

Motion@ motion;
Node@ characterNode;

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

void Stop()
{
    Print("stop");
    @motion = null;
}

void StartPlayMotion()
{
    motion.Start(characterNode);
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

    characterNode = scene_.GetChild("1", true);

    @motion = Motion("Animation/1.ani", 90, 22, false, true);
    StartPlayMotion();
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

    if (input.keyPress['R'])
        StartPlayMotion();
}

void SubscribeToEvents()
{
    // Subscribe HandleUpdate() function for processing update events
    SubscribeToEvent("Update", "HandleUpdate");

    SubscribeToEvent("SceneUpdate", "HandleSceneUpdate");

    // Subscribe HandlePostRenderUpdate() function for processing the post-render update event, during which we request
    // debug geometry
    SubscribeToEvent("PostRenderUpdate", "HandlePostRenderUpdate");
}

float golbal_time = 0;
void HandleUpdate(StringHash eventType, VariantMap& eventData)
{
    // Take the frame time step, which is stored as a float
    float timeStep = eventData["TimeStep"].GetFloat();

    // Move the camera, scale movement with time step
    MoveCamera(timeStep);

    motion.Move(timeStep, characterNode);

    Vector3 dir = characterNode.worldRotation * Vector3(0, 0, 1);
    float a = Atan2(dir.x, dir.z);
    Print("dir="+dir.ToString()+" angle="+String(a));

    golbal_time += timeStep;
    if (golbal_time > 1.0)
    {
        float x = 0;
        float y = 0;
        float angle = Atan2(x, y);
        Print("x="+String(x)+" y="+String(y)+" angle="+String(angle));

        y = 1; x = 0;
        angle = Atan2(x, y);
        Print("x="+String(x)+" y="+String(y)+" angle="+String(angle));

        y = 1; x = 1;
        angle = Atan2(x, y);
        Print("x="+String(x)+" y="+String(y)+" angle="+String(angle));

        y = 0; x = 1;
        angle = Atan2(x, y);
        Print("x="+String(x)+" y="+String(y)+" angle="+String(angle));

        y = -1; x = 1;
        angle = Atan2(x, y);
        Print("x="+String(x)+" y="+String(y)+" angle="+String(angle));

        y = -1; x = 0;
        angle = Atan2(x, y);
        Print("x="+String(x)+" y="+String(y)+" angle="+String(angle));

        y = -1; x = -1;
        angle = Atan2(x, y);
        Print("x="+String(x)+" y="+String(y)+" angle="+String(angle));

        y = 0; x = -1;
        angle = Atan2(x, y);
        Print("x="+String(x)+" y="+String(y)+" angle="+String(angle));

        y = 1; x = -1;
        angle = Atan2(x, y);
        Print("x="+String(x)+" y="+String(y)+" angle="+String(angle));

        // engine.Exit();
        golbal_time -= 1.0f;
        StartPlayMotion();
    }
}

void HandlePostRenderUpdate(StringHash eventType, VariantMap& eventData)
{
    DebugRenderer@ debug = scene_.debugRenderer;

    debug.AddNode(scene_, 2.0f, false);
    debug.AddNode(characterNode, 1.0f, false);

    motion.DebugDraw(debug, characterNode);
}

// Create XML patch instructions for screen joystick layout specific to this sample app
String patchInstructions = "";