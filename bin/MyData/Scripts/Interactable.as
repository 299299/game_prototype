// ==============================================
//
//    Interactable Base Class
//
// ==============================================


class Interactable : GameObject
{
    Node@                   sceneNode;
    Node@                   renderNode;
    Text@                   overlayText;

    void ObjectStart()
    {
        sceneNode = node;
        renderNode = sceneNode.GetChild("RenderNode", false);
        overlayText = ui.root.CreateChild("Text", sceneNode.name + "_Overlay_Text");
        overlayText.SetFont(cache.GetResource("Font", UI_FONT), 15);
        overlayText.visible = false;
        overlayText.text = node.name;
    }

    void ShowOverlay(bool bShow)
    {
        overlayText.visible = bShow;
        if (bShow)
        {
            Vector2 v = gCameraMgr.GetCamera().WorldToScreenPoint(GetOverlayPoint());
            overlayText.position = IntVector2(v.x * graphics.width, v.y * graphics.height);
        }
    }

    Vector3 GetOverlayPoint()
    {
        return sceneNode.worldPosition;
    }

    void DelayedStart()
    {
        ObjectStart();
    }

    void Stop()
    {
        @sceneNode = null;
    }
}