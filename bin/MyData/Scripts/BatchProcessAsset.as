// ==================================================================
//
//    Batch Process Asset Script for automatic pipeline
//
// ==================================================================

const String OUT_DIR = "MyData/";
const String ASSET_DIR = "Asset/";
const Array<String> MODEL_ARGS = {"-t", "-na", "-cm", "-ct", "-ns", "-nt", "-nm", "-mb", "75", "-np"};//"-l",
const Array<String> ANIMATION_ARGS = {"-nm", "-nt", "-mb", "75", "-np"};
String exportFolder;
Scene@ processScene;

void PreProcess()
{
    Array<String>@ arguments = GetArguments();
    for (uint i=0; i<arguments.length; ++i)
    {
        if (arguments[i] == "-folder")
            exportFolder = arguments[i + 1];
    }

    Print("exportFolder=" + exportFolder);
    fileSystem.CreateDir(OUT_DIR + "Models");
    fileSystem.CreateDir(OUT_DIR + "Animations");
    fileSystem.CreateDir(OUT_DIR + "Objects");
    processScene = Scene();
}

String DoProcess(const String&in name, const String&in folderName, const String&in command, const Array<String>&in args)
{
    if (!exportFolder.empty)
    {
        if (!name.Contains(exportFolder))
            return "";
    }

    String iname = "Asset/" + folderName + name;
    uint pos = name.FindLast('.');
    String oname = OUT_DIR + folderName + name.Substring(0, pos) + ".mdl";
    pos = oname.FindLast('/');
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

    //for (uint i=0; i<runArgs.length; ++i)
    //    Print("args[" + i +"]=" + runArgs[i]);

    int ret = fileSystem.SystemRun(fileSystem.programDir + "tool/AssetImporter", runArgs);
    if (ret != 0)
        Print("DoProcess " + name + " ret=" + ret);

    return oname;
}

void ProcessModels()
{
    Array<String> models = fileSystem.ScanDir(ASSET_DIR + "Models", "*.*", SCAN_FILES, true);
    for (uint i=0; i<models.length; ++i)
    {
        Print("Found a model " + models[i]);
        DoProcess(models[i], "Models/", "model", MODEL_ARGS);
    }
}

void ProcessAnimations()
{
    Array<String> animations = fileSystem.ScanDir(ASSET_DIR + "Animations", "*.*", SCAN_FILES, true);
    for (uint i=0; i<animations.length; ++i)
    {
        // Print("Found a animation " + animations[i]);
        DoProcess(animations[i], "Animations/", "anim", ANIMATION_ARGS);
    }
}

void ProcessObjects()
{
    Array<String> objects = fileSystem.ScanDir(ASSET_DIR + "Objects", "*.FBX", SCAN_FILES, true);
    for (uint i=0; i<objects.length; ++i)
    {
        String object = objects[i];
        //Print("Found a object " + object);

        String outFolder = OUT_DIR + "Objects/";
        String oname = outFolder + object;
        String objectFile = oname.Substring(0, oname.FindLast('/'));
        String objectName = GetFileName(object);
        objectFile += "/" + objectName + ".xml";

        if (fileSystem.FileExists(objectFile))
        {
            //Print(objectFile + " exist.");
            continue;
        }

        String outMdlName = DoProcess(object, "Objects/", "model", MODEL_ARGS);
        if (outMdlName.empty)
            continue;

        String subFolder = object.Substring(0, object.FindLast('/') + 1);
        String objectResourceFolder = "Objects/" + subFolder;
        String assetFolder = ASSET_DIR + "Objects/" + subFolder;
        Print("ObjectFile: " + objectFile + " objectName: " + objectName + " objectResourceFolder: " + objectResourceFolder);

        Node@ node = processScene.CreateChild(objectName);
        int index = outMdlName.Find('/') + 1;
        String modelName = outMdlName.Substring(index, outMdlName.length - index);
        Model@ model = cache.GetResource("Model", modelName);
        if (model is null)
        {
            Print("model " + modelName + " load failed!!");
            return;
        }

        /*String matFile = outMdlName;
        matFile.Replace(".mdl", ".txt");
        Print("matFile=" + matFile);

        String texFolder = "BIG_Textures/";
        String tmp = objectResourceFolder.Substring(0, objectResourceFolder.length - 1);
        index = tmp.FindLast('/') + 1;
        tmp = tmp.Substring(index, tmp.length - index);
        texFolder += tmp + "/";

        Print("texFolder=" + texFolder);

        Array<String> matList;
        File file;
        if (file.Open(matFile, FILE_READ))
        {
            while (!file.eof)
            {
                String line = file.ReadLine();
                if (!line.empty)
                {
                    Print(line);
                    matList.Push(line);
                }
            }
        }
        */

        if (model.skeleton.numBones > 0)
        {
            Node@ renderNode = node.CreateChild("RenderNode");
            AnimatedModel@ am = renderNode.CreateComponent("AnimatedModel");
            renderNode.worldRotation = Quaternion(0, 180, 0);
            am.model = model;
            am.castShadows = true;

            /*for (uint j=0; j<matList.length; ++j)
            {
                am.materials[j] = cache.GetResource("Material", objectResourceFolder + matList[j]);
            }*/
        }
        else
        {
            StaticModel@ sm = node.CreateComponent("StaticModel");
            sm.model = model;
            sm.castShadows = true;

            /*for (uint i=0; i<matList.length; ++i)
            {
                sm.materials[i] = cache.GetResource("Material", objectResourceFolder + matList[i]);
            }*/
        }

        File outFile(objectFile, FILE_WRITE);
        node.SaveXML(outFile);
    }
}

void ProcessMaterial(const String&in matTxt, const String&in outMatFile, const String& texFolder)
{
    if (!exportFolder.empty)
    {
        if (!matTxt.Contains(exportFolder))
            return;
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
            Print(line);

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

    String tech = "Techniques/Diff.xml";
    if (!diffuse.empty && !normal.empty && !spec.empty && !emissive.empty)
        tech = "Techniques/DiffNormalSpecEmissive.xml";
    else if (!diffuse.empty && !normal.empty && !spec.empty)
        tech = "Techniques/DiffNormalSpec.xml";
    else if (!diffuse.empty && !normal.empty)
        tech = "Techniques/DiffNormal.xml";

    Material@ m = Material();
    m.SetTechnique(0, cache.GetResource("Technique", tech));
    m.name = GetFileName(matTxt);

    if (!diffuse.empty)
    {
        m.textures[TU_DIFFUSE] = cache.GetResource("Texture2D", texFolder + diffuse + ".tga");
        if (m.textures[TU_DIFFUSE] is null)
            m.textures[TU_DIFFUSE] = cache.GetResource("Texture2D", "BIG_Textures/common/" + diffuse + ".tga");
    }
    if (!normal.empty)
    {
        m.textures[TU_NORMAL] = cache.GetResource("Texture2D", texFolder + normal + ".tga");
        if (m.textures[TU_NORMAL] is null)
            m.textures[TU_NORMAL] = cache.GetResource("Texture2D", "BIG_Textures/common/" + normal + ".tga");
    }
    if (!spec.empty)
    {
        m.textures[TU_SPECULAR] = cache.GetResource("Texture2D", texFolder + spec + ".tga");
        if (m.textures[TU_SPECULAR] is null)
            m.textures[TU_SPECULAR] = cache.GetResource("Texture2D", "BIG_Textures/common/" + spec + ".tga");
    }
    if (!emissive.empty)
    {
        m.textures[TU_EMISSIVE] = cache.GetResource("Texture2D", texFolder + emissive + ".tga");
        if (m.textures[TU_EMISSIVE] is null)
            m.textures[TU_EMISSIVE] = cache.GetResource("Texture2D", "BIG_Textures/common/" + emissive + ".tga");
    }

    Variant diffColor = Vector4(1, 1, 1, 1);
    m.shaderParameters["MatDiffColor"] = diffColor;

    File saveFile(outMatFile, FILE_WRITE);
    m.Save(saveFile);
}

void ProcessMatFiles()
{
    Array<String> matFiles = fileSystem.ScanDir(ASSET_DIR + "Objects", "*.mat", SCAN_FILES, true);
    for (uint i=0; i<matFiles.length; ++i)
    {
        String matFile = matFiles[i];
        //Print("Found a mat file " + matFile);

        String outFolder = OUT_DIR + "Objects/";
        String temp = matFile.Substring(0, matFile.FindLast('/'));
        uint index = temp.FindLast("/") + 1;
        temp = temp.Substring(index, temp.length - index);

        String matName = GetFileName(matFile);
        String outMatFile = outFolder + "LIS/" + temp + "/" + matName + ".xml";
        if (fileSystem.FileExists(outMatFile))
        {
            //Print(outMatFile + " exist.");
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
    Print("Start Processing .....");
    uint startTime = time.systemTime;
    PreProcess();
    ProcessModels();
    ProcessObjects();
    ProcessAnimations();
    ProcessMatFiles();
    PostProcess();
    engine.Exit();
    uint timeSec = (time.systemTime - startTime) / 1000;
    if (timeSec > 60)
        ErrorDialog("BATCH PROCESS", "Time cost = " + String(float(timeSec)/60.0f) + " min");
    else
        ErrorDialog("BATCH PROCESS", "Time cost = " + String(timeSec) + " sec");
}