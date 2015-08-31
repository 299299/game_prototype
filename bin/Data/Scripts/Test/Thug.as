#include "Scripts/Test/Enemy.as"


class Thug : Enemy
{
    void Start()
    {

    }

    void Update(float dt)
    {
        Character::Update(dt);
    }

    void DebugDraw(DebugRenderer@ debug)
    {

    }
};
