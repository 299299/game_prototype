

void UpdateEditorHack(float dt)
{
	if (input.keyPress[KEY_1])
	{
		// print current information
		for (uint i = 0; i < editNodes.length; ++i)
		{
			Node@ _n = editNodes[i];
			Print(_n.name + " world-pos=" + _n.worldPosition.ToString() + " world-rot=" + _n.worldRotation.eulerAngles.ToString());
		}
	}
	else if (input.keyPress[KEY_2])
	{
		AnimationState@ animState = testAnimState.Get();
		if (animState !is null)
			animState.AddTime(-1.0f/30.0f);
	}
	else if (input.keyPress[KEY_3])
	{
		AnimationState@ animState = testAnimState.Get();
		if (animState !is null)
			animState.AddTime(1.0f/30.0f);
	}
}