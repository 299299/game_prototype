
enum StateIndicator
{
    STATE_INDICATOR_HIDE,
    STATE_INDICATOR_ATTACK,
};


class HeadIndicator : ScriptObject
{
    Vector3 offset = Vector3(0, 1.5f, 0);
    uint headNodeId;
    int state = -1;
    Array<Texture2D@> textures;
    Sprite@ sprite;

    HeadIndicator()
    {
        textures.Push(null);
        textures.Push(cache.GetResource("Texture2D", "Textures/counter.tga"));
    }

    void Start()
    {
        sprite = ui.root.CreateChild("Sprite", "Indicator_" + node.name);
        sprite.blendMode = BLEND_ADD;
        ChangeState(0);
    }

    void DelayedStart()
    {
        headNodeId = node.GetChild(HEAD, true).id;
    }

    void Stop()
    {
        sprite.Remove();
    }

    void Update(float dt)
    {
        if (engine.headless)
            return;
        Node@ headNode = node.scene.GetNode(headNodeId);
        if (headNode is null)
            return;
        Vector3 pos = headNode.worldPosition + offset;
        Vector2 pos_2d = GetCamera().WorldToScreenPoint(pos);
        sprite.position = Vector2(pos_2d.x * graphics.width, pos_2d.y * graphics.height);
    }

    void ChangeState(int newState)
    {
        if (state == newState)
            return;

        state = newState;

        sprite.visible = (newState != STATE_INDICATOR_HIDE);
        sprite.texture = textures[newState];
        sprite.size = IntVector2(64, 64);
        sprite.hotSpot = IntVector2(sprite.size.x/2, sprite.size.y/2);
    }
}