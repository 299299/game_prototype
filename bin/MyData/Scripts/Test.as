// ------------------------------------------------
#include "Scripts/AssetProcess.as"
#include "Scripts/Motion.as"
#include "Scripts/Input.as"
#include "Scripts/FSM.as"
#include "Scripts/Ragdoll.as"
// ------------------------------------------------
#include "Scripts/GameObject.as"
#include "Scripts/Character.as"
#include "Scripts/Enemy.as"
#include "Scripts/Thug.as"
#include "Scripts/Player.as"

Scene@ scene_;
Node@ cameraNode; // Camera scene node
float yaw = 0.0f; // Camera yaw angle
float pitch = 0.0f; // Camera pitch angle
bool drawDebug = true;

float dragDistance = 0.0f;
Node@ draggingNode;

const String GAME_SCRIPT = "Scripts/Test.as";
Node@ characterNode;
Node@ thugNode;
Node@ floorNode;


Player@ player;
Thug@ thug;
bool slowMotion = false;
bool pauseGame = false;
int globalState = 0;
float globalTime = 0;

void Start()
{
    cache.autoReloadResources = true;
    gMotionMgr.Start();

    if (!engine.headless)
    {
        SetWindowTitleAndIcon();
        CreateConsoleAndDebugHud();
    }

    CreateScene();

    if (!engine.headless) {
        CreateUI();
        SetupViewport();
    }

    SubscribeToEvents();
}

void Stop()
{
    gMotionMgr.Stop();
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

    floorNode = scene_.GetChild("Floor", true);

    characterNode = scene_.GetChild("bruce", true);
    characterNode.Translate(Vector3(5, 0, 0));
    // characterNode.GetChild("RootNode", true).rotation = Quaternion(0, -180, 0);

    @player = cast<Player>(characterNode.CreateScriptObject(GAME_SCRIPT, "Player"));
    if (player is null) {
        Print("player is null!!");
        engine.Exit();
        return;
    }

    thugNode = scene_.GetChild("thug", true);
    @thug = cast<Thug>(thugNode.CreateScriptObject(GAME_SCRIPT, "Thug"));
    if (thug is null) {
        Print("thug is null!!");
        engine.Exit();
        return;
    }

    Node@ jack = scene_.GetChild("jack", true);
    jack.CreateScriptObject(GAME_SCRIPT, "Ragdoll");

    @thug.target = player;

    Vector3 pos = cameraNode.worldPosition;
    Vector3 playerPos = characterNode.worldPosition;
    pos.x = playerPos.x;
    pos.z = playerPos.z;
    pos.z -= 5;
    cameraNode.worldPosition = pos;
}

void SetWindowTitleAndIcon()
{
    Image@ icon = cache.GetResource("Image", "Textures/UrhoIcon.png");
    graphics.windowIcon = icon;
    graphics.windowTitle = "Test";
}

void CreateConsoleAndDebugHud()
{
    // Get default style
    XMLFile@ xmlFile = cache.GetResource("XMLFile", "UI/DefaultStyle.xml");
    if (xmlFile is null)
        return;

    // Create console
    Console@ console = engine.CreateConsole();
    console.defaultStyle = xmlFile;
    console.background.opacity = 0.8f;

    // Create debug HUD
    DebugHud@ debugHud = engine.CreateDebugHud();
    debugHud.defaultStyle = xmlFile;
}

void CreateUI()
{
    // Create a Cursor UI element because we want to be able to hide and show it at will. When hidden, the mouse cursor will
    // control the camera, and when visible, it will point the raycast target
    //XMLFile@ style = cache.GetResource("XMLFile", "UI/DefaultStyle.xml");
    //Cursor@ cursor = Cursor();
    //cursor.SetStyleAuto(style);
    //ui.cursor = cursor;
    // Set starting position of the cursor at the rendering window center
    //cursor.SetPosition(graphics.width / 2, graphics.height / 2);
    input.SetMouseVisible(true);

    Text@ instructionText = ui.root.CreateChild("Text", "instruction");
    instructionText.SetFont(cache.GetResource("Font", "Fonts/UbuntuMono-R.ttf"), 12);
    instructionText.horizontalAlignment = HA_LEFT;
    instructionText.verticalAlignment = VA_TOP;
    instructionText.SetPosition(0, 0);
    instructionText.color = Color(0, 1, 0);

    Text@ debugText = ui.root.CreateChild("Text", "debug");
    debugText.SetFont(cache.GetResource("Font", "Fonts/UbuntuMono-R.ttf"), 16);
    debugText.horizontalAlignment = HA_CENTER;
    debugText.verticalAlignment = VA_CENTER;
    debugText.color = Color(1, 0, 0);
    debugText.text = "FUCK";
    debugText.visible = false;
}

void SetupViewport()
{
    Viewport@ viewport = Viewport(scene_, cameraNode.GetComponent("Camera"));
    renderer.viewports[0] = viewport;

    graphics.windowTitle = "Test";
    //if (GetPlatform() == "Linux")
    //    graphics.windowPosition = IntVector2(0, 800);
}

void ShootBox()
{
    // Create a smaller box at camera position
    Node@ boxNode = scene_.CreateChild("SmallBox");
    boxNode.position = cameraNode.position;
    boxNode.rotation = cameraNode.rotation;
    boxNode.SetScale(1.0);
    StaticModel@ boxObject = boxNode.CreateComponent("StaticModel");
    boxObject.model = cache.GetResource("Model", "Models/Box.mdl");
    boxObject.material = cache.GetResource("Material", "Materials/StoneEnvMapSmall.xml");
    boxObject.castShadows = true;

    // Create physics components, use a smaller mass also
    RigidBody@ body = boxNode.CreateComponent("RigidBody");
    body.mass = 0.25f;
    body.friction = 0.75f;
    CollisionShape@ shape = boxNode.CreateComponent("CollisionShape");
    shape.SetBox(Vector3(1.0f, 1.0f, 1.0f));

    const float OBJECT_VELOCITY = 10.0f;

    // Set initial velocity for the RigidBody based on camera forward vector. Add also a slight up component
    // to overcome gravity better
    body.linearVelocity = cameraNode.rotation * Vector3(0.0f, 0.25f, 1.0f) * OBJECT_VELOCITY;
}

void ShootSphere()
{
    Node@ sphereNode = scene_.CreateChild("Sphere");
    sphereNode.position = cameraNode.position;
    sphereNode.rotation = cameraNode.rotation;
    sphereNode.SetScale(1.0);
    StaticModel@ boxObject = sphereNode.CreateComponent("StaticModel");
    boxObject.model = cache.GetResource("Model", "Models/Sphere.mdl");
    boxObject.material = cache.GetResource("Material", "Materials/StoneSmall.xml");
    boxObject.castShadows = true;

    RigidBody@ body = sphereNode.CreateComponent("RigidBody");
    body.mass = 1.0f;
    body.rollingFriction = 0.15f;
    CollisionShape@ shape = sphereNode.CreateComponent("CollisionShape");
    shape.SetSphere(1.0f);

    const float OBJECT_VELOCITY = 10.0f;

    // Set initial velocity for the RigidBody based on camera forward vector. Add also a slight up component
    // to overcome gravity better
    body.linearVelocity = cameraNode.rotation * Vector3(0.0f, 0.25f, 1.0f) * OBJECT_VELOCITY;
}

void MoveCamera(float timeStep)
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

    if (input.keyDown['W'])
        cameraNode.Translate(Vector3(0.0f, 0.0f, 1.0f) * speed * timeStep);
    if (input.keyDown['S'])
        cameraNode.Translate(Vector3(0.0f, 0.0f, -1.0f) * speed * timeStep);
    if (input.keyDown['A'])
        cameraNode.Translate(Vector3(-1.0f, 0.0f, 0.0f) * speed * timeStep);
    if (input.keyDown['D'])
        cameraNode.Translate(Vector3(1.0f, 0.0f, 0.0f) * speed * timeStep);

    if (input.keyPress[KEY_1])
        ShootSphere();

    if (input.keyPress[KEY_2])
        ShootBox();

    if (input.mouseButtonPress[MOUSEB_RIGHT])
    {
        IntVector2 pos = ui.cursorPosition;
        // Check the cursor is visible and there is no UI element in front of the cursor
        if (ui.GetElementAt(pos, true) !is null)
            return;

        Camera@ camera = cameraNode.GetComponent("Camera");
        Ray cameraRay = camera.GetScreenRay(float(pos.x) / graphics.width, float(pos.y) / graphics.height);
        float rayDistance = 100.0f;
        PhysicsRaycastResult result = scene_.physicsWorld.RaycastSingle(cameraRay, rayDistance, 3);
        if (result.body !is null)
        {
            Print("RaycastSingle Hit " + result.body.node.name + " distance=" + result.distance);
            draggingNode = scene_.CreateChild("DraggingNode");
            RigidBody@ body = draggingNode.CreateComponent("RigidBody");
            CollisionShape@ shape = draggingNode.CreateComponent("CollisionShape");
            shape.SetSphere(0.1f);
            Constraint@ constraint = draggingNode.CreateComponent("Constraint");
            constraint.constraintType = CONSTRAINT_POINT;
            constraint.disableCollision = true;
            constraint.otherBody = result.body;
            dragDistance = result.distance;
            draggingNode.worldPosition = result.position;
        }
    }
    else {
        if (!input.mouseButtonDown[MOUSEB_RIGHT]) {
            if (draggingNode !is null) {
                draggingNode.RemoveAllComponents();
                draggingNode = null;
            }
        }
    }
}

void SubscribeToEvents()
{
    SubscribeToEvent("Update", "HandleUpdate");
    SubscribeToEvent("SceneUpdate", "HandleSceneUpdate");
    SubscribeToEvent("PostRenderUpdate", "HandlePostRenderUpdate");
    SubscribeToEvent("KeyDown", "HandleKeyDown");
    SubscribeToEvent("MouseMove", "HandleMouseMove");
}

void HandleUpdate(StringHash eventType, VariantMap& eventData)
{
    float timeStep = eventData["TimeStep"].GetFloat();

    MoveCamera(timeStep);

    gInput.Update(timeStep);

    if (input.keyPress['T'])
    {
        slowMotion = !slowMotion;
        scene_.timeScale = slowMotion ? 0.05f : 1.0f;
    }

    if (input.keyPress['R'])
    {
        pauseGame = !pauseGame;
        float speed = slowMotion ? 0.1f : 1.0f;
        scene_.timeScale = pauseGame ? 0 : speed;
    }

    if (input.keyPress['E'])
    {
        String testName = "BM_TG_Counter/Counter_Leg_Back_Weak_03";
        //String testName = "TG_HitReaction/Push_Reaction";
        //String testName = "TG_BM_Counter/Counter_Arm_Front_01";
        player.TestAnimation(testName);
    }

    if (input.keyPress['F']) {
        scene_.timeScale = 1.0f;
    }

    String debugText = gInput.GetDebugText();
    if (player !is null)
    {
        debugText += player.GetDebugText();
        debugText += thug.GetDebugText();

        /*
        Vector3 fwd = Vector3(0, 0, 1);
        Vector3 camDir = cameraNode.worldRotation * fwd;
        float cameraAngle = Atan2(camDir.x, camDir.z);
        Vector3 characterDir = characterNode.worldRotation * fwd;
        float characterAngle = Atan2(characterDir.x, characterDir.z);

        //Print("cameraAngle=" + String(cameraAngle) + " characterAngle=" + String(characterAngle) + " inputAngle=" + String(gInput.m_leftStickAngle));
        float diff = computeDifference();
        // debugText = "DIFF=" + String(diff) + " SEL=" + String(RadialSelectAnimation(4)) + " m=" + String(gInput.m_leftStickMagnitude) + " l=" + String(gInput.m_leftStickHoldTime);
        */
    }

    if (engine.headless)
    {
        //if (!debugText.empty)
        //    Print(debugText);

        globalTime += timeStep;

         if (globalTime > 0.5)
        {
            if (player !is null && globalState != 1)
            {
                globalState = 1;
                String testName = "BM_Attack/Attack_Close_Forward_02";
                player.TestAnimation(testName);
            }
        }

        if (globalTime > 5)
        {
            if (globalState == 999)
            {
                @player = null;
                @thug = null;
                characterNode.RemoveAllComponents();
                thugNode.RemoveAllComponents();
                @gEnemyMgr = null;
                gMotionMgr.Stop();
                globalState = 2;
            }
        }

        if (globalTime > 3.0)
        {
            // engine.Exit();
        }
    }
    else
    {
        Text@ text = ui.root.GetChild("instruction", true);
        text.text = debugText;
    }
}

void HandlePostRenderUpdate(StringHash eventType, VariantMap& eventData)
{
    if (!drawDebug)
        return;
    DebugRenderer@ debug = scene_.debugRenderer;
    debug.AddNode(scene_, 1.0f, false);
    if (player !is null)
        player.DebugDraw(debug);
    if (thug !is null)
        thug.DebugDraw(debug);
    scene_.physicsWorld.DrawDebugGeometry(true);
}

void HandleKeyDown(StringHash eventType, VariantMap& eventData)
{
    int key = eventData["Key"].GetInt();

    // Close console (if open) or exit when ESC is pressed
    if (key == KEY_ESC)
    {
        if (!console.visible)
            engine.Exit();
        else
            console.visible = false;
    }
    else if (key == KEY_F1)
        drawDebug = !drawDebug;
    else if (key == KEY_F2)
        debugHud.ToggleAll();
    else if (key == KEY_F3)
        console.Toggle();

}

void HandleMouseMove(StringHash eventType, VariantMap& eventData)
{
    // dragging physics object
    if (draggingNode !is null) {
        float x = eventData["x"].GetInt();
        float y = eventData["y"].GetInt();
        Camera@ camera = cameraNode.GetComponent("Camera");
        draggingNode.worldPosition = camera.ScreenToWorldPoint(Vector3(x / graphics.width, y / graphics.height, dragDistance));
    }
}

void HandleSceneUpdate(StringHash eventType, VariantMap& eventData)
{
}