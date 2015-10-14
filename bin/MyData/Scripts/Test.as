// ------------------------------------------------
#include "Scripts/Game.as"
#include "Scripts/AssetProcess.as"
#include "Scripts/Motion.as"
#include "Scripts/Input.as"
#include "Scripts/FSM.as"
#include "Scripts/Ragdoll.as"
#include "Scripts/Camera.as"
// ------------------------------------------------
#include "Scripts/GameObject.as"
#include "Scripts/Character.as"
#include "Scripts/Enemy.as"
#include "Scripts/Thug.as"
#include "Scripts/Player.as"

Scene@ scene_;
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

    Node@ cameraNode = scene_.CreateChild("Camera");
    Camera@ cam = cameraNode.CreateComponent("Camera");
    // cam.fillMode = FILL_WIREFRAME;

    floorNode = scene_.GetChild("Floor", true);

    characterNode = scene_.GetChild("bruce", true);
    characterNode.Translate(Vector3(5, 0, 0));
    // characterNode.GetChild("RootNode", true).rotation = Quaternion(0, -180, 0);

    cameraNode.position = Vector3(5.0f, 10.0f, -10.0f);
    cameraNode.LookAt(characterNode.worldPosition);

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

    @thug.target = player;

    gCameraMgr.Start(cameraNode);
    gCameraMgr.SetCameraController("Debug");
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
    Viewport@ viewport = Viewport(scene_, gCameraMgr.GetCamera());
    renderer.viewports[0] = viewport;
    graphics.windowTitle = "Test";
    //if (GetPlatform() == "Linux")
    //    graphics.windowPosition = IntVector2(0, 800);
}

void ShootBox(Scene@ _scene)
{
    Node@ cameraNode = gCameraMgr.GetCameraNode();
    Node@ boxNode = _scene.CreateChild("SmallBox");
    boxNode.position = cameraNode.position;
    boxNode.rotation = cameraNode.rotation;
    boxNode.SetScale(1.0);
    StaticModel@ boxObject = boxNode.CreateComponent("StaticModel");
    boxObject.model = cache.GetResource("Model", "Models/Box.mdl");
    boxObject.material = cache.GetResource("Material", "Materials/StoneEnvMapSmall.xml");
    boxObject.castShadows = true;
    RigidBody@ body = boxNode.CreateComponent("RigidBody");
    body.mass = 0.25f;
    body.friction = 0.75f;
    body.collisionLayer = (1 << COLLISION_LAYER_PROP);
    CollisionShape@ shape = boxNode.CreateComponent("CollisionShape");
    shape.SetBox(Vector3(1.0f, 1.0f, 1.0f));
    body.linearVelocity = cameraNode.rotation * Vector3(0.0f, 0.25f, 1.0f) * 10.0f;
}

void ShootSphere(Scene@ _scene)
{
    Node@ cameraNode = gCameraMgr.GetCameraNode();
    Node@ sphereNode = _scene.CreateChild("Sphere");
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
    body.collisionLayer = (1 << COLLISION_LAYER_PROP);
    CollisionShape@ shape = sphereNode.CreateComponent("CollisionShape");
    shape.SetSphere(1.0f);
    body.linearVelocity = cameraNode.rotation * Vector3(0.0f, 0.25f, 1.0f) * 10.0f;
}

void SubscribeToEvents()
{
    SubscribeToEvent("Update", "HandleUpdate");
    SubscribeToEvent("PostRenderUpdate", "HandlePostRenderUpdate");
    SubscribeToEvent("KeyDown", "HandleKeyDown");
    SubscribeToEvent("MouseMove", "HandleMouseMove");
}

void HandleUpdate(StringHash eventType, VariantMap& eventData)
{
    float timeStep = eventData["TimeStep"].GetFloat();

    gInput.Update(timeStep);
    gCameraMgr.Update(timeStep);

    if (input.keyPress[KEY_1])
        ShootSphere(scene_);

    if (input.keyPress[KEY_2])
        ShootBox(scene_);

    if (input.mouseButtonPress[MOUSEB_RIGHT])
    {
        IntVector2 pos = ui.cursorPosition;
        // Check the cursor is visible and there is no UI element in front of the cursor
        if (ui.GetElementAt(pos, true) !is null)
            return;

        Camera@ camera = gCameraMgr.GetCamera();
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
                draggingNode.Remove();
                draggingNode = null;
            }
        }
    }

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
    }

    if (engine.headless)
    {
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
    DebugRenderer@ debug = scene_.debugRenderer;
    gGame.PostRenderUpdate();

    if (!drawDebug)
        return;

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
    gGame.OnKeyDown(key);

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
    int x = eventData["x"].GetInt();
    int y = eventData["y"].GetInt();
    gGame.OnMouseMove(x, y);
    // dragging physics object
    if (draggingNode !is null) {
        Camera@ camera = gCameraMgr.GetCamera();
        draggingNode.worldPosition = camera.ScreenToWorldPoint(Vector3(x / graphics.width, y / graphics.height, dragDistance));
    }
}