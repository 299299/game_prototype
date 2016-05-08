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

    void Enter(State@ lastState)
    {
        startTime = (lastState.name == "StandToWalkState") ? 14 * SEC_PER_FRAME : 0;
        PlayerMoveForwardState::Enter(lastState);
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

class Batman : Player
{
    Batman()
    {
        super();
        walkAlignAnimation = GetAnimationName("BM_Movement/Walk");
    }

    void AddStates()
    {
        stateMachine.AddState(MaxStandState(this));
        stateMachine.AddState(MaxWalkState(this));
        stateMachine.AddState(MaxRunState(this));
        stateMachine.AddStates(MaxFallState(this));
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

