

class ProcSky : ScriptObject
{
    /// Atmospheric parameters.
    Vector3 Kr = Vector3(0.18867780436772762, 0.4978442963618773, 0.6616065586417131); // Absorption profile of air.
    float rayleighBrightness = 3.3f;
    float mieBrightness = 0.1f;
    float spotBrightness = 50.0f;
    float scatterStrength = 0.028f;
    float rayleighStrength = 0.139f;
    float mieStrength = 0.264f;
    float rayleighCollectionPower = 0.81f;
    float mieCollectionPower = 0.39f;
    float mieDistribution = 0.63f;

    /// Render size of each face.
    int renderSize = 256;
    /// FOV used to initialize the default camera. Can adjust for Skybox seams.
    float renderFOV = 89.5f;
    /// Fixed rotations for each cube face.
    Array<Matrix3> faceRotations;

    bool dirty = true;

    Skybox@ skybox;

    ProcSky()
    {
        faceRotations.Resize(FACE_NEGATIVE_Z+1);
        faceRotations[FACE_POSITIVE_X] = Matrix3(0,0,1,  0,1,0, -1,0,0);
        faceRotations[FACE_NEGATIVE_X] = Matrix3(0,0,-1, 0,1,0,  1,0,0);
        faceRotations[FACE_POSITIVE_Y] = Matrix3(1,0,0,  0,0,1,  0,-1,0);
        faceRotations[FACE_NEGATIVE_Y] = Matrix3(1,0,0,  0,0,-1, 0,1,0);
        faceRotations[FACE_POSITIVE_Z] = Matrix3(1,0,0,  0,1,0,  0,0,1);
        faceRotations[FACE_NEGATIVE_Z] = Matrix3(-1,0,0, 0,1,0,  0,0,-1);
    }

    void Start()
    {
        skybox = node.GetComponent("Skybox");
        if (skybox is null)
        {
            skybox = node.CreateComponent("Skybox");
            skybox.model = cache.GetResource("Model", "Models/Box.mdl");
            skybox.material = cache.GetResource("Material", "Materials/Skybox.xml");
        }

        SetRenderSize(renderSize);

        Vector3 lightDir(0, 1, 0);
        Matrix4 invProj = GetCamera().GetProjection(false).Inverse();

        // Add custom quad commands to render path.
        for (int i = 0; i < FACE_NEGATIVE_Z+1; ++i) {
            RenderPathCommand cmd;
            cmd.tag = "ProcSky";
            cmd.type = CMD_QUAD;
            cmd.sortMode = SORT_BACKTOFRONT;
            cmd.pass = "base";
            cmd.SetOutput(0, "DiffProcSky", CubeMapFace(i));
            cmd.vertexShaderName = "ProcSky";
            cmd.pixelShaderName = "ProcSky";
            cmd.shaderParameters["Kr"] = Variant(Kr);
            cmd.shaderParameters["RayleighBrightness"] = rayleighBrightness;
            cmd.shaderParameters["MieBrightness"] = mieBrightness;
            cmd.shaderParameters["SpotBrightness"] = spotBrightness;
            cmd.shaderParameters["ScatterStrength"] = scatterStrength;
            cmd.shaderParameters["RayleighStrength"] = rayleighStrength;
            cmd.shaderParameters["MieStrength"] = mieStrength;
            cmd.shaderParameters["RayleighCollectionPower"] = rayleighCollectionPower;
            cmd.shaderParameters["MieCollectionPower"] = mieCollectionPower;
            cmd.shaderParameters["MieDistribution"] = mieDistribution;
            cmd.shaderParameters["LightDir"] = Variant(lightDir);
            cmd.shaderParameters["InvProj"] = Variant(invProj);
            cmd.shaderParameters["InvViewRot"] = Variant(faceRotations[i]);
            cmd.enabled = true;
            renderer.viewports[0].renderPath.AddCommand(cmd);
        }

        Update(0.0f);
    }

    void Update(float dt)
    {
        if (!dirty)
            return;
        dirty = false;

        if (engine.headless)
            return;

        RenderPath@ path = renderer.viewports[0].renderPath;
        path.shaderParameters["Kr"] = Variant(Kr);
        path.shaderParameters["RayleighBrightness"] = rayleighBrightness;
        path.shaderParameters["MieBrightness"] = mieBrightness;
        path.shaderParameters["SpotBrightness"] = spotBrightness;
        path.shaderParameters["ScatterStrength"] = scatterStrength;
        path.shaderParameters["RayleighStrength"] = rayleighStrength;
        path.shaderParameters["MieStrength"] = mieStrength;
        path.shaderParameters["RayleighCollectionPower"] = rayleighCollectionPower;
        path.shaderParameters["MieCollectionPower"] = mieCollectionPower;
        path.shaderParameters["MieDistribution"] = mieDistribution;
        path.shaderParameters["InvProj"] = Variant(GetCamera().GetProjection(false).Inverse());
    }

    void SetRenderSize(int size)
    {
        TextureCube@ skyboxTexCube = TextureCube();
        skyboxTexCube.name = "DiffProcSky";
        skyboxTexCube.filterMode = FILTER_BILINEAR;
        skyboxTexCube.addressMode[COORD_U] = ADDRESS_CLAMP;
        skyboxTexCube.addressMode[COORD_V] = ADDRESS_CLAMP;
        skyboxTexCube.addressMode[COORD_W] = ADDRESS_CLAMP;
        cache.AddManualResource(skyboxTexCube);
        skyboxTexCube.SetSize(size, GetRGBAFormat(), TEXTURE_RENDERTARGET);
        skybox.materials[0].textures[TU_DIFFUSE] = skyboxTexCube;
        renderSize = size;
    }
}