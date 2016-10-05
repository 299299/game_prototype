// ==================================================================
//
//    Batch Process Asset Script for automatic pipeline
//
// ==================================================================］
#include "Scripts/Constants.as"

const String OUT_DIR = "MyData/";
const String ASSET_DIR = "Asset/";
const Array<String> MODEL_ARGS = {"-t", "-na", "-cm", "-ct", "-ns", "-nt", "-nm", "-mb", "75", "-np"};//"-l",
const Array<String> ANIMATION_ARGS = {"-nm", "-nt", "-mb", "75", "-np"};
String exportFolder;
Scene@ processScene;
Array<String> materials;
Array<String> materialFilteredNames1;
Array<String> materialFilteredNames2;
Array<String> textures;
bool forceCompile = false;

String FilterName1(const String&in name)
{
    Array<String> splits = name.ToLower().Split('_');
    if (splits.length < 3)
        return "";
    String ret = splits[2];
    ret.Replace("_Alpha", "");

    //Print("Filter1 from " + name + " to " + ret);
    return ret;
}

String FilterName2(const String&in name)
{
    if (name.length < 4)
        return name;
    String ret = name;
    if (ret[ret.length-1] == 'A' || ret[ret.length-1] == 'B' ||
        ret[ret.length-1] == 'C' || ret[ret.length-1] == 'D')
    {
        ret = ret.Substring(0, ret.length-1);
    }
    if (ret[ret.length-1] == '1' || ret[ret.length-1] == '2' ||
        ret[ret.length-1] == '3' || ret[ret.length-1] == '4' ||
        ret[ret.length-1] == '5' || ret[ret.length-1] == '6' ||
        ret[ret.length-1] == '7' || ret[ret.length-1] == '8' ||
        ret[ret.length-1] == '9' || ret[ret.length-1] == '0')
    {
        ret = ret.Substring(0, ret.length-1);
    }
    if (ret[ret.length-1] == '1' || ret[ret.length-1] == '2' ||
        ret[ret.length-1] == '3' || ret[ret.length-1] == '4' ||
        ret[ret.length-1] == '5' || ret[ret.length-1] == '6' ||
        ret[ret.length-1] == '7' || ret[ret.length-1] == '8' ||
        ret[ret.length-1] == '9' || ret[ret.length-1] == '0')
    {
        ret = ret.Substring(0, ret.length-1);
    }

    //Print("Filter2 from " + name + " to " + ret);
    return ret;
}

String FindMaterial(const String&in name)
{
    for (uint i=0; i<materialFilteredNames1.length; ++i)
    {
        if (materialFilteredNames1[i].StartsWith(name))
            return materials[i];
        if (name.StartsWith(materialFilteredNames1[i]))
            return materials[i];
    }

    String inName = FilterName2(name);
    for (uint i=0; i<materialFilteredNames2.length; ++i)
    {
        if (materialFilteredNames2[i].StartsWith(inName))
            return materials[i];
        if (inName.StartsWith(materialFilteredNames2[i]))
            return materials[i];
    }

    return "";
}

void PreProcess()
{
    Array<String>@ arguments = GetArguments();
    for (uint i=0; i<arguments.length; ++i)
    {
        if (arguments[i] == "-f")
            exportFolder = arguments[i + 1];
        else if (arguments[i] == "-b")
            forceCompile = true;
    }

    Print("exportFolder=" + exportFolder);
    fileSystem.CreateDir(OUT_DIR + "Models");
    fileSystem.CreateDir(OUT_DIR + "Animations");
    fileSystem.CreateDir(OUT_DIR + "Objects");
    processScene = Scene();
    processScene.CreateComponent("Octree");
}

String DoProcess(const String&in inName, const String&in outName, const String&in command, const Array<String>&in args)
{
    if (!exportFolder.empty)
    {
        if (!inName.Contains(exportFolder))
            return "";
    }

    String iname = inName; //"Asset/" + folderName + name;
    String oname = outName; //OUT_DIR + folderName + GetFileName(name) + ".mdl";

    if (fileSystem.FileExists(oname) && !forceCompile)
    {
        // Print(oname + " exist ...");
        return oname;
    }

    uint pos = oname.FindLast('/');
    String outFolder = oname.Substring(0, pos);
    fileSystem.CreateDir(outFolder);

    bool is_windows = GetPlatform() == "Windows";
    if (is_windows) {
        iname.Replace("/", "\\");
        oname.Replace("/", "\\");
    }

    Array<String> runArgs;
    runArgs.Push(command);
    runArgs.Push("\"" + iname + "\"");
    runArgs.Push("\"" + oname + "\"");
    for (uint i=0; i<args.length; ++i)
        runArgs.Push(args[i]);

    int ret = fileSystem.SystemRun(fileSystem.programDir + "tool/AssetImporter", runArgs);
    if (ret != 0)
        Print("DoProcess " + inName + " ret=" + ret);

    return oname;
}

void ProcessModels()
{
    Array<String> models = fileSystem.ScanDir(ASSET_DIR + "Models", "*.*", SCAN_FILES, true);
    for (uint i=0; i<models.length; ++i)
    {
        // Print("Found a model " + models[i]);
        String model = models[i];
        uint pos = model.FindLast('.');
        DoProcess(ASSET_DIR + "Models/" + model, OUT_DIR + "Models/" + model.Substring(0, pos) + ".mdl", "model", MODEL_ARGS);
    }
}

void ProcessAnimations()
{
    Array<String> animations = fileSystem.ScanDir(ASSET_DIR + "Animations", "*.*", SCAN_FILES, true);
    for (uint i=0; i<animations.length; ++i)
    {
        // Print("Found a animation " + animations[i]);
        String anim = animations[i];
        uint pos = anim.FindLast('.');
        if (fileSystem.FileExists(OUT_DIR + "Animations/" + anim.Substring(0, pos) + "_Take 001.ani") && !forceCompile)
        {
            continue;
        }
        DoProcess(ASSET_DIR + "Animations/" + anim, OUT_DIR + "Animations/" + anim.Substring(0, pos) + ".mdl", "anim", ANIMATION_ARGS);
    }
}

void ProcessObjects()
{
    Print("ProcessObjects finding all materials start");
    Array<String> materialFiles = fileSystem.ScanDir(OUT_DIR + "Materials", "*.xml", SCAN_FILES, true);
    for (uint i=0; i<materialFiles.length; ++i)
    {
        // Print("Add Material " + materialFiles[i]);
        String fileName = GetFileName(materialFiles[i]).ToLower();
        materials.Push(materialFiles[i]);
        materialFilteredNames1.Push(FilterName1(fileName));
        materialFilteredNames2.Push(materialFilteredNames1[i]);
    }
    Print("ProcessObjects finding all materials end");

    Array<String> objects = fileSystem.ScanDir(ASSET_DIR + "Objects", "*.FBX", SCAN_FILES, true);
    int numObjectsMissingMaterials = 0;
    for (uint i=0; i<objects.length; ++i)
    {
        String object = objects[i];
        uint pos = object.FindLast('.');
        String outMdlName = DoProcess(ASSET_DIR + "Objects/" + object, OUT_DIR + "Models/" + object.Substring(0, pos) + ".mdl", "model", MODEL_ARGS);
        if (outMdlName.empty)
            continue;

        String outFolder = OUT_DIR + "Objects/";
        String oname = outFolder + object;
        String objectFile = oname.Substring(0, oname.FindLast('/'));
        String objectName = GetFileName(object);
        objectFile += "/" + objectName + ".xml";

        if (fileSystem.FileExists(objectFile) && !forceCompile)
        {
            continue;
        }

        String subFolder = object.Substring(0, object.FindLast('/') + 1);
        String objectFolder = "MyData/Objects/" + subFolder;
        String assetFolder = ASSET_DIR + "Objects/" + subFolder;
        // Print("ObjectFile: " + objectFile + " objectName: " + objectName + " subFolder: " + subFolder);
        fileSystem.CreateDir(objectFolder);

        Node@ node = processScene.CreateChild(objectName);
        int index = outMdlName.Find('/') + 1;
        String modelName = outMdlName.Substring(index, outMdlName.length - index);
        Model@ model = cache.GetResource("Model", modelName);
        if (model is null)
        {
            Print("model " + modelName + " load failed!!");
            return;
        }

        String matName = objectName;
        String m = FindMaterial(FilterName1(matName));
        bool hasBone = false;

        if (m == "")
        {
            Print("Warning, objectFile=" + objectFile + " no material find!!");
            ++numObjectsMissingMaterials;
        }

        if (model.skeleton.numBones > 0)
        {
            Node@ renderNode = node.CreateChild("RenderNode");
            AnimatedModel@ am = renderNode.CreateComponent("AnimatedModel");
            renderNode.CreateComponent("AnimationController");
            renderNode.worldRotation = Quaternion(0, 180, 0);
            am.model = model;
            am.castShadows = true;
            if (m != "")
                am.material =  cache.GetResource("Material", "Materials/" + m);
            hasBone = true;
        }
        else
        {
            StaticModel@ sm = node.CreateComponent("StaticModel");
            sm.model = model;
            sm.castShadows = true;
            if (m != "")
                sm.material =  cache.GetResource("Material", "Materials/" + m);
        }

        /*
        bool createPhysics = false;
        Array<String> physics_sub_folders = {
            "OB_Engines", "OB_Engines02", "OB_Furnitures", "OB_Furnitures02", "OB_UrbanFurnitures",
            "EN_Doors", "OB_Rubbish", "OB_Foods", "OB_Accessories", "EN_Walls", "EN_Grounds", "EN_Ceilings"
        };

        for (uint i=0; i<physics_sub_folders.length; ++i)
        {
            if (subFolder == "LIS/" + physics_sub_folders[i] + "/")
                createPhysics = true;
        }

        if (createPhysics)
        {
            RigidBody@ body = node.CreateComponent("RigidBody");
            body.collisionLayer = COLLISION_LAYER_PROP;
            body.collisionMask = COLLISION_LAYER_LANDSCAPE | COLLISION_LAYER_CHARACTER | COLLISION_LAYER_RAGDOLL | COLLISION_LAYER_RAYCAST | COLLISION_LAYER_PROP;
            CollisionShape@ shape = node.CreateComponent("CollisionShape");

            Vector3 offset = Vector3(0, model.boundingBox.halfSize.y, 0);
            if (subFolder == "LIS/EN_Doors/")
            {
                offset = Vector3(hasBone ? -model.boundingBox.halfSize.x : model.boundingBox.halfSize.x, model.boundingBox.halfSize.y, 0);
            }

            shape.SetBox(model.boundingBox.size, offset);
        }
        */

        File outFile(objectFile, FILE_WRITE);
        node.SaveXML(outFile);
    }

    Print("Total objects num=" + objects.length + " missing material object num=" + numObjectsMissingMaterials);
}

Texture@ FindTexture(const String&in texFolder, const String&in name)
{
    Texture@ tex = cache.GetResource("Texture2D", texFolder + name + ".tga");
    if (tex is null)
    {
        for (uint i=0; i<textures.length; ++i)
        {
            if (textures[i].Contains(name, false))
            {
                tex = cache.GetResource("Texture2D", "BIG_Textures/" + textures[i]);
                break;
            }
        }
    }
    return tex;
}

void ProcessMaterial(const String&in matTxt, const String&in outMatFile, const String& texFolder)
{
    if (!exportFolder.empty)
    {
        if (!matTxt.Contains(exportFolder))
        {
            return;
        }
    }

    File file;
    if (!file.Open(matTxt, FILE_READ))
    {
        Print("not found " + matTxt);
        return;
    }

    String diffuse, normal, spec, emissive;
    while (!file.eof)
    {
        String line = file.ReadLine();
        if (!line.empty)
        {
            //Print(line);

            if (line.StartsWith("Diffuse="))
            {
                diffuse = line;
                diffuse.Replace("Diffuse=", "");
            }
            else if (line.StartsWith("Normal="))
            {
                normal = line;
                normal.Replace("Normal=", "");
            }
            else if (line.StartsWith("Specular="))
            {
                spec = line;
                spec.Replace("Specular=", "");
            }
            else if (line.StartsWith("Emissive="))
            {
                emissive = line;
                emissive.Replace("Emissive=", "");
            }
        }
    }

    String tech = "Techniques/Diff";
    if (!diffuse.empty && !normal.empty && !spec.empty && !emissive.empty)
        tech = "Techniques/DiffNormalSpecEmissive";
    else if (!diffuse.empty && !normal.empty && !spec.empty)
        tech = "Techniques/DiffNormalSpec";
    else if (!diffuse.empty && !normal.empty)
        tech = "Techniques/DiffNormal";

    String name = GetFileName(matTxt);
    if (name.StartsWith("MT_Nat"))
        tech += "Alpha";

    Material@ m = Material();
    m.SetTechnique(0, cache.GetResource("Technique", tech + ".xml"));
    m.name = name;

    if (!diffuse.empty)
    {
        m.textures[TU_DIFFUSE] = FindTexture(texFolder, diffuse);
    }
    if (!normal.empty)
    {
        m.textures[TU_NORMAL] = FindTexture(texFolder, normal);
    }
    if (!spec.empty)
    {
        m.textures[TU_SPECULAR] = FindTexture(texFolder, spec);
    }
    if (!emissive.empty)
    {
        m.textures[TU_EMISSIVE] = FindTexture(texFolder, emissive);
    }

    Variant diffColor = Vector4(1, 1, 1, 1);
    m.shaderParameters["MatDiffColor"] = diffColor;

    String outFolder = outMatFile.Substring(0, outMatFile.FindLast('/'));
    fileSystem.CreateDir(outFolder);

    File saveFile(outMatFile, FILE_WRITE);
    m.Save(saveFile);
}

void ProcessMatFiles()
{
    textures = fileSystem.ScanDir(OUT_DIR + "BIG_Textures", "*.tga", SCAN_FILES, true);

    Array<String> matFiles = fileSystem.ScanDir(ASSET_DIR + "Objects", "*.mat", SCAN_FILES, true);
    for (uint i=0; i<matFiles.length; ++i)
    {
        String matFile = matFiles[i];
        //Print("Found a mat file " + matFile);

        String outFolder = OUT_DIR + "Materials/";
        String temp = matFile.Substring(0, matFile.FindLast('/'));
        uint index = temp.FindLast("/") + 1;
        temp = temp.Substring(index, temp.length - index);

        String matName = GetFileName(matFile);
        String outMatFile = outFolder + "LIS/" + temp + "/" + matName + ".xml";
        if (fileSystem.FileExists(outMatFile) && !forceCompile)
        {
            continue;
        }

        String texFolder = "BIG_Textures/" + temp + "/";
        // Print("MatFile: " + matFile + " matName: " + matName + " texFolder: " + texFolder + " outMatFile: " + outMatFile);
        ProcessMaterial(ASSET_DIR + "Objects/" + matFile, outMatFile, texFolder);
    }
}

void PostProcess()
{
    if (processScene !is null)
        processScene.Remove();
    @processScene = null;
}

void Start()
{
    Print("*************************************************************************");
    Print("Start Processing .....");
    Print("*************************************************************************");
    uint startTime = time.systemTime;
    PreProcess();
    ProcessModels();
    ProcessAnimations();
    ProcessMatFiles();
    ProcessObjects();
    PostProcess();
    engine.Exit();
    uint timeSec = (time.systemTime - startTime) / 1000;
    if (timeSec > 60)
        ErrorDialog("BATCH PROCESS", "Time cost = " + String(float(timeSec)/60.0f) + " min.");
    else
        Print("BATCH PROCESS  Time cost = " + timeSec + " sec.");
    Print("*************************************************************************");
    Print("*************************************************************************");
}