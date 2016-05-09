// ==============================================
//
//    Max Class
//
// ==============================================

class MaxStandState : PlayerStandState
{
    MaxStandState(Character@ c)
    {
        super(c);
        AddMotion("BM_Movement/Stand_Idle");
    }
};

class MaxWalkState : PlayerWalkState
{
    MaxWalkState(Character@ c)
    {
        super(c);
        SetMotion("BM_Movement/Walk");
    }
};

class MaxRunState : PlayerRunState
{
    MaxRunState(Character@ c)
    {
        super(c);
        SetMotion("BM_Movement/Run");
    }
};

class MaxFallState : PlayerFallState
{
    MaxFallState(Character@ c)
    {
        super(c);
        SetMotion("BM_Movement/Fall");
    }
};

class Max : Player
{
    Max()
    {
        super();
    }

    void AddStates()
    {
        stateMachine.AddState(MaxStandState(this));
        stateMachine.AddState(MaxWalkState(this));
        stateMachine.AddState(MaxRunState(this));
        stateMachine.AddState(MaxFallState(this));
        stateMachine.AddState(CharacterAlignState(this));
        stateMachine.AddState(AnimationTestState(this));
    }
};

void Create_Max_Motions()
{

}

void Add_Max_AnimationTriggers()
{

}

