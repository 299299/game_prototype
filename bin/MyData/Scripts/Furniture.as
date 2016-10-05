// ==============================================
//
//    Furniture Base Class
//
// ==============================================

class FurnitureInteractivingState : Interactable_InteractivingState
{
    FurnitureInteractivingState(Interactable@ i)
    {
        super(i);
    }

    void Update(float dt)
    {
        if (timeInState > 1)
        {
            ownner.ChangeState("IdleState");
            return;
        }

        Interactable_InteractivingState::Update(dt);
    }
};

Material@ CreateRefectMaterial(Camera@ cam, int w, int h)
{
    // Create a renderable texture (1024x768, RGB format), enable bilinear filtering on it
    Texture2D@ renderTexture = Texture2D();
    renderTexture.SetSize(w, h, GetRGBFormat(), TEXTURE_RENDERTARGET);
    renderTexture.filterMode = FILTER_BILINEAR;

    // Create a new material from scratch, use the diffuse unlit technique, assign the render texture
    // as its diffuse texture, then assign the material to the screen plane object
    Material@ renderMaterial = Material();
    renderMaterial.SetTechnique(0, cache.GetResource("Technique", "Techniques/DiffUnlit.xml"));
    renderMaterial.textures[TU_DIFFUSE] = renderTexture;
    // Since the screen material is on top of the box model and may Z-fight, use negative depth bias
    // to push it forward (particularly necessary on mobiles with possibly less Z resolution)
    renderMaterial.depthBias = BiasParameters(-0.001, 0.0);

    // Get the texture's RenderSurface object (exists when the texture has been created in rendertarget mode)
    // and define the viewport for rendering the second scene, similarly as how backbuffer viewports are defined
    // to the Renderer subsystem. By default the texture viewport will be updated when the texture is visible
    // in the main view
    RenderSurface@ surface = renderTexture.renderSurface;
    Viewport@ rttViewport = Viewport(cam.node.scene, cam);
    surface.viewports[0] = rttViewport;

    return renderMaterial;
}

class Furniture : Interactable
{
    void ObjectStart()
    {
        Interactable::ObjectStart();

        type = kInteract_Funiture;
        collectText = FilterName(sceneNode.name);
        interactText = collectText + "  ....";
    }

    void CreatePhysics()
    {
        RigidBody@ body = sceneNode.CreateComponent("RigidBody");
        body.collisionLayer = COLLISION_LAYER_PROP;
        body.collisionMask = COLLISION_LAYER_LANDSCAPE | COLLISION_LAYER_CHARACTER | COLLISION_LAYER_RAGDOLL | COLLISION_LAYER_RAYCAST | COLLISION_LAYER_PROP;
        CollisionShape@ shape = sceneNode.CreateComponent("CollisionShape");
        shape.SetBox(size, GetOffset());
    }

    void AddStates()
    {
        Interactable::AddStates();
        stateMachine.AddState(FurnitureInteractivingState(this));
    }
}

class Mirror : Furniture
{
    void ObjectStart()
    {
        Furniture::ObjectStart();

        Node@ camNode = sceneNode.CreateChild("Reflect_Cam_Node");
        camNode.position = Vector3(0, size.y/4*3, -0.25);
        camNode.rotation = Quaternion(-6.1, 180, 0);

        Camera@ cam = camNode.CreateComponent("Camera");
        cam.farClip = 100;
        cam.viewOverrideFlags = VO_DISABLE_OCCLUSION | VO_DISABLE_SHADOWS;

        Material@ m = CreateRefectMaterial(cam, 256, 256);
        Node@ mirrorNode = sceneNode.CreateChild("Mirro_Box_Node");
        mirrorNode.position = Vector3(0, 3.46257, -0.279159);
        mirrorNode.rotation = Quaternion(-6.1, 180, 0);
        mirrorNode.scale = Vector3(1.08, 2.45, 0.01);
        StaticModel@ boxModel = mirrorNode.CreateComponent("StaticModel");
        boxModel.model = cache.GetResource("Model", "Models/Box.mdl");
        boxModel.material = m;
    }

    void DebugDraw(DebugRenderer@ debug)
    {
        Furniture::DebugDraw(debug);

        Node@ camNode = sceneNode.GetChild("Reflect_Cam_Node", false);
        debug.AddNode(camNode, 0.5f, false);

        Camera@ cam = camNode.GetComponent("Camera");
        Polyhedron p;
        p.Define(cam.frustum);
        debug.AddPolyhedron(p, GREEN, false);
    }
}
