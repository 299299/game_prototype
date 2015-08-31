#include "Scripts/Test/Character.as"

class Enemy : Character
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

class EnemyManager
{
    EnemyManager()
    {
        Print("EnemyManager()");
    }

    ~EnemyManager()
    {
        Print("~EnemyManager()");
    }

    Node@ CreateEnemy()
    {

    }
};