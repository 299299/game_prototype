
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
    Text@ text;

    HeadIndicator()
    {
        textures.Push(null);
        textures.Push(cache.GetResource("Texture2D", "Textures/counter.png"));
    }

    void Start()
    {
        sprite = ui.root.CreateChild("Sprite", "Indicator_" + node.name);
        sprite.blendMode = BLEND_REPLACE;
        text = ui.root.CreateChild("Text", "NameText_" + node.name);
        text.SetFont(cache.GetResource("Font", DEBUG_FONT), DEBUG_FONT_SIZE);
        text.color = YELLOW;
        text.text = node.name;
        ChangeState(0);
    }

    void DelayedStart()
    {
        headNodeId = node.GetChild(HEAD, true).id;
    }

    void Stop()
    {
        sprite.Remove();
        text.Remove();
        @sprite = null;
        @text = null;
        textures.Clear();
    }

    void Update(float dt)
    {
        Node@ headNode = node.scene.GetNode(headNodeId);
        if (headNode is null)
            return;
        Vector3 pos = headNode.worldPosition + offset;
        Vector2 pos_2d = GetCamera().WorldToScreenPoint(pos);
        sprite.position = Vector2(pos_2d.x * graphics.width, pos_2d.y * graphics.height);
        text.SetPosition(sprite.position.x, sprite.position.y);
        text.visible = debug_draw_flag > 0;
    }

    void ChangeState(int newState)
    {
        if (state == newState)
            return;

        state = newState;

        sprite.visible = (newState != STATE_INDICATOR_HIDE);
        sprite.texture = textures[newState];
        sprite.size = IntVector2(96, 96);
        sprite.hotSpot = IntVector2(sprite.size.x/2, sprite.size.y/2);
    }
}