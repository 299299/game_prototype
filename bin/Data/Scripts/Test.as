// Static 3D scene example.
// This sample demonstrates:
//     - Creating a 3D scene with static content
//     - Displaying the scene using the Renderer subsystem
//     - Handling keyboard and mouse input to move a freelook camera

#include "Scripts/Utilities/Sample.as"

class ScriptAnimation
{
    void Load(String anim)
    {
        animation = cache.GetResource("Animation", anim);
        String motion_file = "Data/" + GetPath(anim) + GetFileName(anim) + "_motion.xml";

        File@ file = File();
        if (file.Open(motion_file))
        {
            XMLFile@ xml = XMLFile();
            if (xml.Load(file))
            {
                Print(anim + " has motion " + motion_file + "!");

                XMLElement root = xml.GetRoot();
                XMLElement child = root.GetChild();
                int i = 0;

                while (!child.isNull)
                {
                    float t = child.GetFloat("time");
                    Vector3 translation = child.GetVector3("translation");
                    float rotation = child.GetFloat("rotation");
                    Print("frame:" + String(i++) + " time: " + String(t) + " translation: " + translation.ToString() + " rotation: " + String(rotation));
                    motion_times.Push(t);
                    Vector4 v(translation.x, translation.y, translation.z, rotation);
                    motion_keys.Push(v);
                    child = child.GetNext();
                }
            }
        }
    }

    void GetMotion(float t, float dt, bool loop, Vector4& out out_motion)
    {
        if (motion_times.empty)
            return;

        float future_time = t + dt;
        if (future_time > animation.length && loop) {
            Vector4 t1 = Vector4(0,0,0,0);
            Vector4 t2 = Vector4(0,0,0,0);
            GetMotion(t, animation.length - t, false, t1);
            GetMotion(0, t + dt - animation.length, false, t2);
            out_motion = t1 + t2;
        }
        else
        {
            Vector4 k1 = GetKey(t);
            Vector4 k2 = GetKey(future_time);
            out_motion = k2 - k1;
        }
    }

    Vector4 GetKey(float t)
    {
        uint i = uint(t * 30.0f);
        Vector4 k1 = motion_keys[i];
        uint next_i = i + 1;
        if (next_i >= motion_keys.length)
            next_i = motion_keys.length - 1;
        Vector4 k2 = motion_keys[next_i];
        Vector4 ret = k1.Lerp(k2, t*30 - float(i));
        return ret;
    }

    Animation@              animation;
    Array<float>            motion_times;
    Array<Vector4>          motion_keys;
};

Node@ characterNode;
ScriptAnimation@ scriptAnimation;
float totalYaw = 0;
float targetYaw = 90;
float startYaw = 0;
Vector3 startPosition;
Quaternion startRotation;

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

void StartPlayMotion()
{
    totalYaw = 0;
    startPosition = characterNode.worldPosition;
    startRotation = characterNode.worldRotation;
    startYaw = startRotation.eulerAngles.y;

    AnimationController@ ctrl = characterNode.GetComponent("AnimationController");
    ctrl.Play("Animation/1.ani", 0, false);
    ctrl.SetTime("Animation/1.ani", 0);
    ctrl.SetSpeed("Animation/1.ani", 1);
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

    @scriptAnimation = ScriptAnimation();
    scriptAnimation.Load("Animation/1.ani");

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
    {
        StartPlayMotion();
    }
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

void HandleUpdate(StringHash eventType, VariantMap& eventData)
{
    // Take the frame time step, which is stored as a float
    float timeStep = eventData["TimeStep"].GetFloat();

    // Move the camera, scale movement with time step
    MoveCamera(timeStep);

    AnimationController@ ctrl = characterNode.GetComponent("AnimationController");
    float t = ctrl.GetTime("Animation/1.ani");

    if (t >= ctrl.GetLength("Animation/1.ani"))
        return;

    if (t >= 0.74)
    {
        if (ctrl.GetSpeed("Animation/1.ani") > 0)
        {
            float final_yaw = characterNode.worldRotation.eulerAngles.y;
            characterNode.Yaw(targetYaw + startYaw - final_yaw);
            Print("FINISHED!!!!!!!!!!!!!!!!!!!!!!!!!!");
            ctrl.SetSpeed("Animation/1.ani", 0);
            Print("FINAL YAW = " + String(final_yaw));
        }
        return;
    }

    Vector4 motion_out = Vector4(0, 0, 0, 0);
    motion_out = scriptAnimation.GetKey(t);

    Vector3 t_local(motion_out.x, motion_out.y, motion_out.z);
    float yaw = motion_out.w + 22.63 * t;
    characterNode.worldRotation = Quaternion(0, yaw + startYaw, 0);
    characterNode.worldPosition =  startRotation * t_local + startPosition;

    Print("motion=" + motion_out.ToString() + " yaw=" + String(yaw) + " t=" + String(t));
}

void HandlePostRenderUpdate(StringHash eventType, VariantMap& eventData)
{
    DebugRenderer@ debug = scene_.debugRenderer;

    debug.AddNode(scene_, 2.0f, false);
    debug.AddNode(characterNode, 1.0f, false);

    AnimationController@ ctrl = characterNode.GetComponent("AnimationController");
    Vector4 finnal_pos = scriptAnimation.GetKey(ctrl.GetLength("Animation/1.ani"));
    Vector3 t_local(finnal_pos.x, finnal_pos.y, finnal_pos.z);

    debug.AddLine(startRotation * t_local + startPosition, characterNode.worldPosition, Color(0.5f, 0.5f, 0.7f), false);
}

// Create XML patch instructions for screen joystick layout specific to this sample app
String patchInstructions = "";