
Array<String> cachedFolders;
bool searched = false;
bool inited = false;

void InitExt()
{
    if (editorScene !is null)
    {
        editorScene.RegisterVar("prefab");
    }
    else
    {
        inited = false;
    }
}

void UpdateExt(float dt)
{
    if (!inited)
    {
        InitExt();
        inited = true;
    }

    if (input.keyPress['J'] || input.keyPress['j'])
    {
        SaveSelectedPrefab();
    }
    else if (input.keyPress['K'] || input.keyPress['k'])
    {
        ReloadSceneByPrefab();
    }
}

String GetNodePrefab(Node@ _node)
{
    if (_node.vars.Contains("prefab"))
    {
        return _node.vars["prefab"].GetString();
    }
    return FindPrefabByName(_node.name);
}

String FindPrefabByName(const String&in name)
{
    if (!searched)
    {
        cachedFolders = fileSystem.ScanDir("MyData/Objects", "*", SCAN_DIRS, true);
        searched = true;
    }

    for (uint i=0; i<cachedFolders.length; ++i)
    {
        String fileName = "MyData/Objects/" + cachedFolders[i] + "/" + name + ".xml";
        if (fileSystem.FileExists(fileName))
        {
            return fileName;
        }
    }
    return "";
}

void SaveSelectedPrefab()
{
    if (editNode is null)
        return;

    String fileName = GetNodePrefab(editNode);
    if (!fileName.empty)
    {
        Print("SaveSelectedPrefab " + editNode.name + " found " + fileName);
        SaveNode(fileName);
    }
}

void ReloadSceneByPrefab()
{
    if (editorScene is null)
        return;

    Array<Node@> nodes;
    Array<String> objects;
    for (uint i=0; i<editorScene.numChildren; ++i)
    {
        Node@ _node = editorScene.children[i];
        String objectFile = GetNodePrefab(_node);
        if (objectFile.empty)
            continue;

        nodes.Push(_node);
        objects.Push(objectFile);
    }

    for (uint i=0; i<nodes.length; ++i)
    {
        Node@ oldNode = nodes[i];
        Print("Reloading prefab " + oldNode.name);
        Node@ newNode = LoadNode(objects[i]);
        newNode.position = oldNode.position;
        newNode.rotation = oldNode.rotation;
        newNode.scale = oldNode.scale;
        oldNode.Remove();
    }

    UpdateWindowTitle();
    DisableInspectorLock();
    UpdateHierarchyItem(editorScene, true);
    CollapseHierarchy();
    ClearEditActions();
}

